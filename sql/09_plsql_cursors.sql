-- ============================================================
-- DEFENSE ASSET MANAGEMENT SYSTEM
-- 09_plsql_cursors.sql — Cursor-Based Batch Operations
-- ============================================================

SET SERVEROUTPUT ON;

-- ============================================================
-- CURSOR 1: EXPLICIT CURSOR — Overdue Maintenance Report
-- Iterates all weapons with overdue maintenance and prints alerts.
-- ============================================================
DECLARE
    CURSOR c_overdue IS
        SELECT w.weapon_id, w.serial_number, wm.model_name,
               mr.maintenance_type, mr.scheduled_date,
               TRUNC(SYSDATE - mr.scheduled_date) AS days_overdue,
               c.full_name AS technician, u.unit_name
        FROM MAINTENANCE_RECORD mr
        JOIN WEAPON w ON mr.weapon_id = w.weapon_id
        JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
        JOIN CUSTODIAN c ON mr.technician_id = c.custodian_id
        JOIN UNIT u ON w.current_location_id = u.unit_id
        WHERE mr.completed_date IS NULL
          AND mr.scheduled_date < SYSDATE
        ORDER BY mr.scheduled_date;

    v_rec   c_overdue%ROWTYPE;
    v_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('     OVERDUE MAINTENANCE REPORT');
    DBMS_OUTPUT.PUT_LINE('     Generated: ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI'));
    DBMS_OUTPUT.PUT_LINE('============================================');

    OPEN c_overdue;
    LOOP
        FETCH c_overdue INTO v_rec;
        EXIT WHEN c_overdue%NOTFOUND;
        v_count := v_count + 1;
        DBMS_OUTPUT.PUT_LINE(v_count || '. ' || v_rec.serial_number
            || ' (' || v_rec.model_name || ')');
        DBMS_OUTPUT.PUT_LINE('   Type: ' || v_rec.maintenance_type
            || ' | Scheduled: ' || TO_CHAR(v_rec.scheduled_date, 'YYYY-MM-DD')
            || ' | Overdue by: ' || v_rec.days_overdue || ' days');
        DBMS_OUTPUT.PUT_LINE('   Technician: ' || v_rec.technician
            || ' | Location: ' || v_rec.unit_name);
        DBMS_OUTPUT.PUT_LINE('--------------------------------------------');
    END LOOP;
    CLOSE c_overdue;

    DBMS_OUTPUT.PUT_LINE('Total Overdue: ' || v_count || ' weapon(s)');
    DBMS_OUTPUT.PUT_LINE('============================================');
END;
/

-- ============================================================
-- CURSOR 2: PARAMETERIZED CURSOR — Unit Weapons Inventory
-- Lists all weapons for a given unit_id.
-- ============================================================
DECLARE
    CURSOR c_unit_weapons (p_unit_id NUMBER) IS
        SELECT w.weapon_id, w.serial_number, wm.model_name,
               wm.weapon_type, w.current_status, w.reliability_score,
               w.total_rounds_fired
        FROM WEAPON w
        JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
        WHERE w.current_location_id = p_unit_id
        ORDER BY wm.weapon_type, w.serial_number;

    v_unit_name UNIT.unit_name%TYPE;
    v_count     NUMBER := 0;
BEGIN
    -- Report for Unit 1 (1st Infantry Battalion)
    SELECT unit_name INTO v_unit_name FROM UNIT WHERE unit_id = 1;

    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('WEAPONS INVENTORY: ' || v_unit_name);
    DBMS_OUTPUT.PUT_LINE('============================================');

    FOR rec IN c_unit_weapons(1) LOOP
        v_count := v_count + 1;
        DBMS_OUTPUT.PUT_LINE(RPAD(rec.serial_number, 18) || ' | '
            || RPAD(rec.model_name, 16) || ' | '
            || RPAD(rec.weapon_type, 14) || ' | '
            || RPAD(rec.current_status, 15) || ' | Rel: '
            || rec.reliability_score || '%');
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('--------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Total weapons in unit: ' || v_count);
END;
/

-- ============================================================
-- CURSOR 3: CURSOR FOR LOOP — Reliability Report (All Weapons)
-- Generates a reliability summary across all active weapons.
-- ============================================================
DECLARE
    v_total     NUMBER := 0;
    v_combat    NUMBER := 0;
    v_field     NUMBER := 0;
    v_limited   NUMBER := 0;
    v_overhaul  NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('     FLEET RELIABILITY REPORT');
    DBMS_OUTPUT.PUT_LINE('============================================');

    FOR rec IN (
        SELECT w.serial_number, wm.model_name, w.reliability_score,
               w.total_rounds_fired, u.unit_name
        FROM WEAPON w
        JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
        JOIN UNIT u ON w.current_location_id = u.unit_id
        WHERE w.current_status = 'Active'
        ORDER BY w.reliability_score DESC
    ) LOOP
        v_total := v_total + 1;

        IF rec.reliability_score >= 95 THEN
            v_combat := v_combat + 1;
        ELSIF rec.reliability_score >= 85 THEN
            v_field := v_field + 1;
        ELSIF rec.reliability_score >= 70 THEN
            v_limited := v_limited + 1;
        ELSE
            v_overhaul := v_overhaul + 1;
        END IF;

        DBMS_OUTPUT.PUT_LINE(RPAD(rec.serial_number, 18) || ' | '
            || RPAD(rec.model_name, 16) || ' | Rel: '
            || LPAD(rec.reliability_score, 6) || '% | '
            || LPAD(rec.total_rounds_fired, 6) || ' rds | '
            || rec.unit_name);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('SUMMARY:');
    DBMS_OUTPUT.PUT_LINE('  Total Active: ' || v_total);
    DBMS_OUTPUT.PUT_LINE('  Combat Ready (95+): ' || v_combat);
    DBMS_OUTPUT.PUT_LINE('  Field Ready (85-94): ' || v_field);
    DBMS_OUTPUT.PUT_LINE('  Limited Duty (70-84): ' || v_limited);
    DBMS_OUTPUT.PUT_LINE('  Needs Overhaul (<70): ' || v_overhaul);
END;
/

-- ============================================================
-- CURSOR 4: REF CURSOR — Dynamic Query
-- Accepts a status parameter and returns matching weapons.
-- ============================================================
DECLARE
    TYPE ref_cursor_type IS REF CURSOR;
    c_dynamic   ref_cursor_type;
    v_status    VARCHAR2(20) := 'In Maintenance';
    v_weapon_id WEAPON.weapon_id%TYPE;
    v_serial    WEAPON.serial_number%TYPE;
    v_model     WEAPON_MODEL.model_name%TYPE;
    v_unit      UNIT.unit_name%TYPE;
    v_count     NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('DYNAMIC QUERY: Weapons with status = ''' || v_status || '''');
    DBMS_OUTPUT.PUT_LINE('============================================');

    OPEN c_dynamic FOR
        SELECT w.weapon_id, w.serial_number, wm.model_name, u.unit_name
        FROM WEAPON w
        JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
        JOIN UNIT u ON w.current_location_id = u.unit_id
        WHERE w.current_status = v_status;

    LOOP
        FETCH c_dynamic INTO v_weapon_id, v_serial, v_model, v_unit;
        EXIT WHEN c_dynamic%NOTFOUND;
        v_count := v_count + 1;
        DBMS_OUTPUT.PUT_LINE(v_count || '. ID=' || v_weapon_id
            || ' | ' || v_serial || ' | ' || v_model || ' | ' || v_unit);
    END LOOP;
    CLOSE c_dynamic;

    DBMS_OUTPUT.PUT_LINE('Total: ' || v_count || ' weapon(s)');
END;
/

-- ============================================================
-- CURSOR 5: CURSOR WITH UPDATE — Batch Update Reliability
-- Recalculates reliability scores for ALL active weapons.
-- ============================================================
DECLARE
    CURSOR c_update IS
        SELECT weapon_id, total_rounds_fired, manufacture_date
        FROM WEAPON
        WHERE current_status = 'Active'
        FOR UPDATE OF reliability_score;

    v_score     NUMBER;
    v_age       NUMBER;
    v_maint     NUMBER;
    v_overdue   NUMBER;
    v_count     NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('BATCH RELIABILITY RECALCULATION');
    DBMS_OUTPUT.PUT_LINE('============================================');

    FOR rec IN c_update LOOP
        v_age := ROUND(MONTHS_BETWEEN(SYSDATE, rec.manufacture_date) / 12, 1);

        SELECT COUNT(*) INTO v_maint FROM MAINTENANCE_RECORD
        WHERE weapon_id = rec.weapon_id AND completed_date IS NOT NULL;

        SELECT COUNT(*) INTO v_overdue FROM MAINTENANCE_RECORD
        WHERE weapon_id = rec.weapon_id AND completed_date IS NULL AND scheduled_date < SYSDATE;

        v_score := 100 - FLOOR(rec.total_rounds_fired / 5000)
                   - (v_age * 0.5) - (v_overdue * 5) + LEAST(v_maint, 10);

        IF v_score > 100 THEN v_score := 100; END IF;
        IF v_score < 0   THEN v_score := 0;   END IF;

        UPDATE WEAPON SET reliability_score = ROUND(v_score, 2)
        WHERE CURRENT OF c_update;

        v_count := v_count + 1;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Updated reliability for ' || v_count || ' weapons.');
END;
/

-- ============================================================
-- CURSOR 6: CURSOR WITH BULK COLLECT — Expired Ammo Report
-- Processes ammunition records approaching expiry in bulk.
-- ============================================================
DECLARE
    TYPE ammo_rec_type IS RECORD (
        ammo_id         AMMUNITION_TYPE.ammo_id%TYPE,
        ammo_name       AMMUNITION_TYPE.ammo_name%TYPE,
        caliber         AMMUNITION_TYPE.caliber%TYPE,
        stock_quantity  AMMUNITION_TYPE.stock_quantity%TYPE,
        expiry_date     AMMUNITION_TYPE.expiry_date%TYPE,
        days_remaining  NUMBER
    );
    TYPE ammo_table_type IS TABLE OF ammo_rec_type;

    v_ammo_list ammo_table_type;
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('     AMMUNITION EXPIRY REPORT');
    DBMS_OUTPUT.PUT_LINE('============================================');

    SELECT at.ammo_id, at.ammo_name, at.caliber, at.stock_quantity,
           at.expiry_date, TRUNC(at.expiry_date - SYSDATE)
    BULK COLLECT INTO v_ammo_list
    FROM AMMUNITION_TYPE at
    WHERE at.expiry_date < ADD_MONTHS(SYSDATE, 12)
    ORDER BY at.expiry_date;

    IF v_ammo_list.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No ammunition expiring within 12 months.');
    ELSE
        FOR i IN 1..v_ammo_list.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE(i || '. ' || v_ammo_list(i).ammo_name
                || ' (' || v_ammo_list(i).caliber || ')');
            DBMS_OUTPUT.PUT_LINE('   Stock: ' || v_ammo_list(i).stock_quantity
                || ' | Expires: ' || TO_CHAR(v_ammo_list(i).expiry_date, 'YYYY-MM-DD')
                || ' | Days Remaining: ' || v_ammo_list(i).days_remaining);

            IF v_ammo_list(i).days_remaining < 0 THEN
                DBMS_OUTPUT.PUT_LINE('   *** STATUS: EXPIRED ***');
            ELSIF v_ammo_list(i).days_remaining < 90 THEN
                DBMS_OUTPUT.PUT_LINE('   *** STATUS: CRITICAL — EXPIRING SOON ***');
            ELSE
                DBMS_OUTPUT.PUT_LINE('   STATUS: Approaching expiry');
            END IF;
            DBMS_OUTPUT.PUT_LINE('--------------------------------------------');
        END LOOP;
    END IF;

    DBMS_OUTPUT.PUT_LINE('Total flagged: ' || v_ammo_list.COUNT || ' ammunition type(s)');
END;
/

PROMPT '>>> All 6 cursor-based operations executed successfully.';
