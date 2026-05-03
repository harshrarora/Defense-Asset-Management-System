
-- DEFENSE ASSET MANAGEMENT SYSTEM
-- 06_plsql_procedures.sql — Stored Procedures


SET SERVEROUTPUT ON;

-- ============================================================
-- PROCEDURE 1: TRANSFER_CUSTODY
-- Performs an atomic custody transfer with full validation.
-- Uses SAVEPOINT and ROLLBACK for transaction safety.
-- ============================================================
CREATE OR REPLACE PROCEDURE TRANSFER_CUSTODY (
    p_weapon_id     IN NUMBER,
    p_new_custodian IN NUMBER,
    p_new_unit      IN NUMBER,
    p_authorized_by IN NUMBER,
    p_remarks       IN VARCHAR2 DEFAULT NULL
) AS
    v_weapon_status   WEAPON.current_status%TYPE;
    v_auth_clearance  CUSTODIAN.clearance_level%TYPE;
    v_cust_clearance  CUSTODIAN.clearance_level%TYPE;
    v_new_custody_id  NUMBER;
    v_weapon_exists   NUMBER;
    v_cust_exists     NUMBER;
    v_unit_exists     NUMBER;
    v_auth_exists     NUMBER;
BEGIN
    SAVEPOINT before_transfer;

    -- Validate weapon exists
    SELECT COUNT(*) INTO v_weapon_exists FROM WEAPON WHERE weapon_id = p_weapon_id;
    IF v_weapon_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Weapon ID ' || p_weapon_id || ' does not exist.');
    END IF;

    -- Check weapon status
    SELECT current_status INTO v_weapon_status FROM WEAPON WHERE weapon_id = p_weapon_id;
    IF v_weapon_status IN ('Decommissioned', 'In Maintenance') THEN
        RAISE_APPLICATION_ERROR(-20002, 'Cannot transfer weapon with status: ' || v_weapon_status);
    END IF;

    -- Validate custodian exists
    SELECT COUNT(*) INTO v_cust_exists FROM CUSTODIAN WHERE custodian_id = p_new_custodian;
    IF v_cust_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Custodian ID ' || p_new_custodian || ' does not exist.');
    END IF;

    -- Validate unit exists
    SELECT COUNT(*) INTO v_unit_exists FROM UNIT WHERE unit_id = p_new_unit;
    IF v_unit_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Unit ID ' || p_new_unit || ' does not exist.');
    END IF;

    -- Validate authorizer exists and has sufficient clearance (level >= 4)
    SELECT COUNT(*) INTO v_auth_exists FROM CUSTODIAN WHERE custodian_id = p_authorized_by;
    IF v_auth_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Authorizer ID ' || p_authorized_by || ' does not exist.');
    END IF;

    SELECT clearance_level INTO v_auth_clearance FROM CUSTODIAN WHERE custodian_id = p_authorized_by;
    IF v_auth_clearance < 4 THEN
        RAISE_APPLICATION_ERROR(-20006, 'Authorizer clearance level insufficient. Requires level 4+.');
    END IF;

    -- Get next custody ID from sequence
    SELECT custody_seq.NEXTVAL INTO v_new_custody_id FROM DUAL;

    -- Insert custody history record
    INSERT INTO CUSTODY_HISTORY (custody_id, weapon_id, custodian_id, unit_id,
                                  transfer_date, authorized_by, remarks)
    VALUES (v_new_custody_id, p_weapon_id, p_new_custodian, p_new_unit,
            SYSDATE, p_authorized_by, p_remarks);

    -- Update weapon location
    UPDATE WEAPON
    SET current_location_id = p_new_unit,
        current_status = 'Active'
    WHERE weapon_id = p_weapon_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Weapon ' || p_weapon_id || ' transferred to Custodian '
        || p_new_custodian || ' at Unit ' || p_new_unit || '. Custody ID: ' || v_new_custody_id);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO before_transfer;
        DBMS_OUTPUT.PUT_LINE('ERROR: Transfer failed — ' || SQLERRM);
        RAISE;
END TRANSFER_CUSTODY;
/

-- ============================================================
-- PROCEDURE 2: REGISTER_WEAPON
-- Registers a new weapon in the inventory.
-- ============================================================
CREATE OR REPLACE PROCEDURE REGISTER_WEAPON (
    p_model_id        IN NUMBER,
    p_serial_number   IN VARCHAR2,
    p_manufacture_date IN DATE,
    p_location_unit   IN NUMBER
) AS
    v_model_exists  NUMBER;
    v_unit_exists   NUMBER;
    v_serial_exists NUMBER;
    v_new_weapon_id NUMBER;
BEGIN
    -- Validate model
    SELECT COUNT(*) INTO v_model_exists FROM WEAPON_MODEL WHERE model_id = p_model_id;
    IF v_model_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Weapon Model ID ' || p_model_id || ' does not exist.');
    END IF;

    -- Validate unit
    SELECT COUNT(*) INTO v_unit_exists FROM UNIT WHERE unit_id = p_location_unit;
    IF v_unit_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20011, 'Unit ID ' || p_location_unit || ' does not exist.');
    END IF;

    -- Check duplicate serial
    SELECT COUNT(*) INTO v_serial_exists FROM WEAPON WHERE serial_number = p_serial_number;
    IF v_serial_exists > 0 THEN
        RAISE_APPLICATION_ERROR(-20012, 'Serial number ' || p_serial_number || ' already exists.');
    END IF;

    SELECT weapon_seq.NEXTVAL INTO v_new_weapon_id FROM DUAL;

    INSERT INTO WEAPON (weapon_id, model_id, serial_number, manufacture_date,
                        current_status, current_location_id, total_rounds_fired, reliability_score)
    VALUES (v_new_weapon_id, p_model_id, p_serial_number, p_manufacture_date,
            'In Storage', p_location_unit, 0, 100.00);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Weapon registered. ID=' || v_new_weapon_id
        || ', Serial=' || p_serial_number);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: Registration failed — ' || SQLERRM);
        RAISE;
END REGISTER_WEAPON;
/

-- ============================================================
-- PROCEDURE 3: SCHEDULE_MAINTENANCE
-- Schedules a maintenance event for a weapon.
-- ============================================================
CREATE OR REPLACE PROCEDURE SCHEDULE_MAINTENANCE (
    p_weapon_id       IN NUMBER,
    p_scheduled_date  IN DATE,
    p_technician_id   IN NUMBER,
    p_maint_type      IN VARCHAR2,
    p_description     IN VARCHAR2 DEFAULT NULL
) AS
    v_weapon_exists   NUMBER;
    v_tech_exists     NUMBER;
    v_conflict        NUMBER;
    v_new_maint_id    NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_weapon_exists FROM WEAPON WHERE weapon_id = p_weapon_id;
    IF v_weapon_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20020, 'Weapon ID ' || p_weapon_id || ' not found.');
    END IF;

    SELECT COUNT(*) INTO v_tech_exists FROM CUSTODIAN WHERE custodian_id = p_technician_id;
    IF v_tech_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20021, 'Technician ID ' || p_technician_id || ' not found.');
    END IF;

    -- Check for scheduling conflict (same weapon, same date, incomplete)
    SELECT COUNT(*) INTO v_conflict
    FROM MAINTENANCE_RECORD
    WHERE weapon_id = p_weapon_id
      AND scheduled_date = p_scheduled_date
      AND completed_date IS NULL;
    IF v_conflict > 0 THEN
        RAISE_APPLICATION_ERROR(-20022, 'Maintenance already scheduled for this weapon on that date.');
    END IF;

    SELECT maintenance_seq.NEXTVAL INTO v_new_maint_id FROM DUAL;

    INSERT INTO MAINTENANCE_RECORD (maintenance_id, weapon_id, scheduled_date,
                                     completed_date, technician_id, maintenance_type,
                                     description, next_service_due)
    VALUES (v_new_maint_id, p_weapon_id, p_scheduled_date, NULL, p_technician_id,
            p_maint_type, p_description,
            ADD_MONTHS(p_scheduled_date, 6));

    -- Update weapon status if maintenance is today or past
    IF p_scheduled_date <= SYSDATE THEN
        UPDATE WEAPON SET current_status = 'In Maintenance' WHERE weapon_id = p_weapon_id;
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Maintenance scheduled. ID=' || v_new_maint_id);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: Scheduling failed — ' || SQLERRM);
        RAISE;
END SCHEDULE_MAINTENANCE;
/

-- ============================================================
-- PROCEDURE 4: DECOMMISSION_WEAPON
-- Marks a weapon as decommissioned and transfers to depot.
-- ============================================================
CREATE OR REPLACE PROCEDURE DECOMMISSION_WEAPON (
    p_weapon_id     IN NUMBER,
    p_authorized_by IN NUMBER,
    p_reason        IN VARCHAR2
) AS
    v_status      WEAPON.current_status%TYPE;
    v_depot_id    UNIT.unit_id%TYPE;
    v_depot_cust  CUSTODIAN.custodian_id%TYPE;
    v_custody_id  NUMBER;
BEGIN
    SAVEPOINT before_decommission;

    SELECT current_status INTO v_status FROM WEAPON WHERE weapon_id = p_weapon_id;

    IF v_status = 'Decommissioned' THEN
        RAISE_APPLICATION_ERROR(-20030, 'Weapon is already decommissioned.');
    END IF;

    -- Central Armory Depot = unit_id 11
    v_depot_id := 11;
    SELECT commanding_officer_id INTO v_depot_cust FROM UNIT WHERE unit_id = v_depot_id;

    -- Create custody transfer to depot
    SELECT custody_seq.NEXTVAL INTO v_custody_id FROM DUAL;
    INSERT INTO CUSTODY_HISTORY VALUES (v_custody_id, p_weapon_id, v_depot_cust,
        v_depot_id, SYSDATE, p_authorized_by, 'DECOMMISSIONED: ' || p_reason);

    -- Update weapon status
    UPDATE WEAPON
    SET current_status = 'Decommissioned',
        current_location_id = v_depot_id
    WHERE weapon_id = p_weapon_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Weapon ' || p_weapon_id || ' decommissioned. Reason: ' || p_reason);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO before_decommission;
        DBMS_OUTPUT.PUT_LINE('ERROR: Decommission failed — ' || SQLERRM);
        RAISE;
END DECOMMISSION_WEAPON;
/

-- ============================================================
-- PROCEDURE 5: BULK_TRANSFER_UNIT
-- Transfers ALL active weapons from one unit to another.
-- Uses an explicit cursor internally.
-- ============================================================
CREATE OR REPLACE PROCEDURE BULK_TRANSFER_UNIT (
    p_from_unit     IN NUMBER,
    p_to_unit       IN NUMBER,
    p_authorized_by IN NUMBER
) AS
    CURSOR c_weapons IS
        SELECT weapon_id FROM WEAPON
        WHERE current_location_id = p_from_unit
          AND current_status = 'Active';

    v_count       NUMBER := 0;
    v_to_cust     CUSTODIAN.custodian_id%TYPE;
    v_custody_id  NUMBER;
BEGIN
    SAVEPOINT before_bulk;

    -- Get commanding officer of target unit as receiving custodian
    SELECT commanding_officer_id INTO v_to_cust FROM UNIT WHERE unit_id = p_to_unit;

    FOR rec IN c_weapons LOOP
        SELECT custody_seq.NEXTVAL INTO v_custody_id FROM DUAL;
        INSERT INTO CUSTODY_HISTORY VALUES (v_custody_id, rec.weapon_id, v_to_cust,
            p_to_unit, SYSDATE, p_authorized_by, 'Bulk unit transfer');
        UPDATE WEAPON SET current_location_id = p_to_unit WHERE weapon_id = rec.weapon_id;
        v_count := v_count + 1;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('SUCCESS: ' || v_count || ' weapons transferred from Unit '
        || p_from_unit || ' to Unit ' || p_to_unit);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO before_bulk;
        DBMS_OUTPUT.PUT_LINE('ERROR: Bulk transfer failed — ' || SQLERRM);
        RAISE;
END BULK_TRANSFER_UNIT;
/

-- ============================================================
-- TEST CALLS (uncomment to execute)
-- ============================================================
-- EXEC TRANSFER_CUSTODY(24, 14, 5, 13, 'Reassign stored pistol to logistics');
-- EXEC REGISTER_WEAPON(1, 'HK-2025-TEST1', DATE '2025-03-01', 11);
-- EXEC SCHEDULE_MAINTENANCE(2, DATE '2025-06-01', 3, 'Routine', 'Scheduled barrel inspection');
-- EXEC DECOMMISSION_WEAPON(39, 4, 'Exceeded service life — 38000 rounds');

PROMPT '>>> All 5 stored procedures created successfully.';
