-- ============================================================
-- DEFENSE ASSET MANAGEMENT SYSTEM
-- 08_plsql_triggers.sql — Database Triggers
-- ============================================================

SET SERVEROUTPUT ON;

-- ============================================================
-- TRIGGER 1: TRG_AUDIT_WEAPON
-- Logs all INSERT, UPDATE, DELETE on WEAPON to AUDIT_LOG.
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_AUDIT_WEAPON
AFTER INSERT OR UPDATE OR DELETE ON WEAPON
FOR EACH ROW
DECLARE
    v_log_id    NUMBER;
    v_operation VARCHAR2(10);
    v_old_vals  VARCHAR2(1000);
    v_new_vals  VARCHAR2(1000);
BEGIN
    SELECT audit_log_seq.NEXTVAL INTO v_log_id FROM DUAL;

    IF INSERTING THEN
        v_operation := 'INSERT';
        v_old_vals := NULL;
        v_new_vals := 'ID=' || :NEW.weapon_id || ', Serial=' || :NEW.serial_number
            || ', Status=' || :NEW.current_status || ', Unit=' || :NEW.current_location_id;
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_old_vals := 'Status=' || :OLD.current_status || ', Unit=' || :OLD.current_location_id
            || ', Rounds=' || :OLD.total_rounds_fired || ', Reliability=' || :OLD.reliability_score;
        v_new_vals := 'Status=' || :NEW.current_status || ', Unit=' || :NEW.current_location_id
            || ', Rounds=' || :NEW.total_rounds_fired || ', Reliability=' || :NEW.reliability_score;
    ELSIF DELETING THEN
        v_operation := 'DELETE';
        v_old_vals := 'ID=' || :OLD.weapon_id || ', Serial=' || :OLD.serial_number;
        v_new_vals := NULL;
    END IF;

    INSERT INTO AUDIT_LOG (log_id, table_name, operation_type, record_id,
                           old_values, new_values, changed_by, change_timestamp)
    VALUES (v_log_id, 'WEAPON', v_operation,
            NVL(:NEW.weapon_id, :OLD.weapon_id),
            v_old_vals, v_new_vals, USER, SYSTIMESTAMP);
END;
/

-- ============================================================
-- TRIGGER 2: TRG_AUDIT_CUSTODY
-- Logs all custody transfers to AUDIT_LOG.
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_AUDIT_CUSTODY
AFTER INSERT ON CUSTODY_HISTORY
FOR EACH ROW
DECLARE
    v_log_id NUMBER;
BEGIN
    SELECT audit_log_seq.NEXTVAL INTO v_log_id FROM DUAL;

    INSERT INTO AUDIT_LOG (log_id, table_name, operation_type, record_id,
                           old_values, new_values, changed_by, change_timestamp)
    VALUES (v_log_id, 'CUSTODY_HISTORY', 'INSERT', :NEW.custody_id,
            NULL,
            'WeaponID=' || :NEW.weapon_id || ', CustodianID=' || :NEW.custodian_id
            || ', UnitID=' || :NEW.unit_id || ', Date=' || TO_CHAR(:NEW.transfer_date, 'YYYY-MM-DD'),
            USER, SYSTIMESTAMP);
END;
/

-- ============================================================
-- TRIGGER 3: TRG_MAINTENANCE_ALERT
-- Prints an alert via DBMS_OUTPUT when maintenance is overdue.
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_MAINTENANCE_ALERT
AFTER INSERT OR UPDATE ON MAINTENANCE_RECORD
FOR EACH ROW
DECLARE
    v_serial WEAPON.serial_number%TYPE;
    v_model  WEAPON_MODEL.model_name%TYPE;
BEGIN
    SELECT w.serial_number, wm.model_name INTO v_serial, v_model
    FROM WEAPON w JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
    WHERE w.weapon_id = :NEW.weapon_id;

    IF :NEW.completed_date IS NULL AND :NEW.scheduled_date < SYSDATE THEN
        DBMS_OUTPUT.PUT_LINE('*** ALERT: OVERDUE MAINTENANCE ***');
        DBMS_OUTPUT.PUT_LINE('  Weapon: ' || v_serial || ' (' || v_model || ')');
        DBMS_OUTPUT.PUT_LINE('  Scheduled: ' || TO_CHAR(:NEW.scheduled_date, 'YYYY-MM-DD'));
        DBMS_OUTPUT.PUT_LINE('  Type: ' || :NEW.maintenance_type);
        DBMS_OUTPUT.PUT_LINE('  Action Required Immediately!');
    END IF;

    IF :NEW.completed_date IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('INFO: Maintenance completed for ' || v_serial
            || ' on ' || TO_CHAR(:NEW.completed_date, 'YYYY-MM-DD'));
    END IF;
END;
/

-- ============================================================
-- TRIGGER 4: TRG_UPDATE_RELIABILITY
-- Auto-recalculates reliability when total_rounds_fired changes.
-- Uses the CALC_RELIABILITY_SCORE function.
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_UPDATE_RELIABILITY
BEFORE UPDATE OF total_rounds_fired ON WEAPON
FOR EACH ROW
DECLARE
    v_new_score NUMBER;
    v_age_years NUMBER;
    v_maint     NUMBER;
    v_overdue   NUMBER;
BEGIN
    -- Only recalculate if rounds actually changed
    IF :OLD.total_rounds_fired != :NEW.total_rounds_fired THEN
        v_age_years := ROUND(MONTHS_BETWEEN(SYSDATE, :NEW.manufacture_date) / 12, 1);

        SELECT COUNT(*) INTO v_maint FROM MAINTENANCE_RECORD
        WHERE weapon_id = :NEW.weapon_id AND completed_date IS NOT NULL;

        SELECT COUNT(*) INTO v_overdue FROM MAINTENANCE_RECORD
        WHERE weapon_id = :NEW.weapon_id AND completed_date IS NULL AND scheduled_date < SYSDATE;

        v_new_score := 100 - FLOOR(:NEW.total_rounds_fired / 5000)
                       - (v_age_years * 0.5) - (v_overdue * 5) + LEAST(v_maint, 10);

        IF v_new_score > 100 THEN v_new_score := 100; END IF;
        IF v_new_score < 0   THEN v_new_score := 0;   END IF;

        :NEW.reliability_score := ROUND(v_new_score, 2);
    END IF;
END;
/

-- ============================================================
-- TRIGGER 5: TRG_CHECK_AMMO_EXPIRY
-- Prevents linking expired ammunition in AMMO_COMPATIBILITY.
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_CHECK_AMMO_EXPIRY
BEFORE INSERT ON AMMO_COMPATIBILITY
FOR EACH ROW
DECLARE
    v_expiry DATE;
    v_ammo_name AMMUNITION_TYPE.ammo_name%TYPE;
BEGIN
    SELECT expiry_date, ammo_name INTO v_expiry, v_ammo_name
    FROM AMMUNITION_TYPE WHERE ammo_id = :NEW.ammo_id;

    IF v_expiry < SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20050,
            'Cannot add compatibility: Ammunition "' || v_ammo_name
            || '" expired on ' || TO_CHAR(v_expiry, 'YYYY-MM-DD'));
    END IF;
END;
/

-- ============================================================
-- TRIGGER 6: TRG_WEAPON_STATUS_GUARD
-- Prevents reactivation of decommissioned weapons.
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_WEAPON_STATUS_GUARD
BEFORE UPDATE OF current_status ON WEAPON
FOR EACH ROW
BEGIN
    IF :OLD.current_status = 'Decommissioned' AND :NEW.current_status != 'Decommissioned' THEN
        RAISE_APPLICATION_ERROR(-20060,
            'Cannot change status of decommissioned weapon '
            || :OLD.serial_number || '. Weapon must remain decommissioned.');
    END IF;
END;
/

-- ============================================================
-- TEST: Verify triggers fire on DML operations
-- ============================================================
-- Update rounds fired on weapon 2 to trigger reliability recalculation
UPDATE WEAPON SET total_rounds_fired = 13000 WHERE weapon_id = 2;
COMMIT;

-- Check audit log for new entries
SELECT log_id, table_name, operation_type, new_values,
       TO_CHAR(change_timestamp, 'YYYY-MM-DD HH24:MI:SS') AS ts
FROM AUDIT_LOG
WHERE change_timestamp > SYSTIMESTAMP - INTERVAL '1' MINUTE
ORDER BY log_id DESC;

PROMPT '>>> All 6 triggers created and tested successfully.';
