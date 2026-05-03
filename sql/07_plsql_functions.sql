-- ============================================================
-- DEFENSE ASSET MANAGEMENT SYSTEM
-- 07_plsql_functions.sql — PL/SQL Functions
-- ============================================================

SET SERVEROUTPUT ON;

-- ============================================================
-- FUNCTION 1: CALC_RELIABILITY_SCORE
-- Calculates reliability based on rounds fired, maintenance
-- history, and weapon age.
-- ============================================================
CREATE OR REPLACE FUNCTION CALC_RELIABILITY_SCORE (
    p_weapon_id IN NUMBER
) RETURN NUMBER AS
    v_rounds       WEAPON.total_rounds_fired%TYPE;
    v_mfg_date     WEAPON.manufacture_date%TYPE;
    v_age_years    NUMBER;
    v_maint_count  NUMBER;
    v_overdue      NUMBER;
    v_score        NUMBER := 100;
BEGIN
    SELECT total_rounds_fired, manufacture_date
    INTO v_rounds, v_mfg_date
    FROM WEAPON WHERE weapon_id = p_weapon_id;

    v_age_years := ROUND(MONTHS_BETWEEN(SYSDATE, v_mfg_date) / 12, 1);

    -- Count completed maintenance records
    SELECT COUNT(*) INTO v_maint_count
    FROM MAINTENANCE_RECORD
    WHERE weapon_id = p_weapon_id AND completed_date IS NOT NULL;

    -- Count overdue/incomplete maintenance
    SELECT COUNT(*) INTO v_overdue
    FROM MAINTENANCE_RECORD
    WHERE weapon_id = p_weapon_id AND completed_date IS NULL AND scheduled_date < SYSDATE;

    -- Deductions:
    -- -1 point per 5000 rounds fired
    v_score := v_score - FLOOR(v_rounds / 5000);
    -- -0.5 point per year of age
    v_score := v_score - (v_age_years * 0.5);
    -- -5 per overdue maintenance
    v_score := v_score - (v_overdue * 5);
    -- +1 per completed maintenance (max +10)
    v_score := v_score + LEAST(v_maint_count, 10);

    -- Clamp between 0 and 100
    IF v_score > 100 THEN v_score := 100; END IF;
    IF v_score < 0   THEN v_score := 0;   END IF;

    RETURN ROUND(v_score, 2);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN -1; -- Weapon not found
END CALC_RELIABILITY_SCORE;
/

-- ============================================================
-- FUNCTION 2: GET_NEXT_SERVICE_DATE
-- Returns the next maintenance due date for a weapon.
-- ============================================================
CREATE OR REPLACE FUNCTION GET_NEXT_SERVICE_DATE (
    p_weapon_id IN NUMBER
) RETURN DATE AS
    v_next_due  DATE;
BEGIN
    SELECT MAX(next_service_due) INTO v_next_due
    FROM MAINTENANCE_RECORD
    WHERE weapon_id = p_weapon_id;

    IF v_next_due IS NULL THEN
        -- No maintenance record: default to 6 months from manufacture
        SELECT ADD_MONTHS(manufacture_date, 6) INTO v_next_due
        FROM WEAPON WHERE weapon_id = p_weapon_id;
    END IF;

    RETURN v_next_due;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END GET_NEXT_SERVICE_DATE;
/

-- ============================================================
-- FUNCTION 3: CHECK_AMMO_COMPATIBILITY
-- Checks if a given ammo type is compatible with a weapon model.
-- Returns effectiveness rating or 'INCOMPATIBLE'.
-- ============================================================
CREATE OR REPLACE FUNCTION CHECK_AMMO_COMPATIBILITY (
    p_model_id IN NUMBER,
    p_ammo_id  IN NUMBER
) RETURN VARCHAR2 AS
    v_rating   NUMBER;
    v_model    WEAPON_MODEL.model_name%TYPE;
    v_ammo     AMMUNITION_TYPE.ammo_name%TYPE;
    v_expiry   AMMUNITION_TYPE.expiry_date%TYPE;
BEGIN
    SELECT model_name INTO v_model FROM WEAPON_MODEL WHERE model_id = p_model_id;
    SELECT ammo_name, expiry_date INTO v_ammo, v_expiry
    FROM AMMUNITION_TYPE WHERE ammo_id = p_ammo_id;

    -- Check expiry
    IF v_expiry < SYSDATE THEN
        RETURN 'EXPIRED: ' || v_ammo || ' expired on ' || TO_CHAR(v_expiry, 'YYYY-MM-DD');
    END IF;

    -- Check compatibility
    BEGIN
        SELECT effectiveness_rating INTO v_rating
        FROM AMMO_COMPATIBILITY
        WHERE model_id = p_model_id AND ammo_id = p_ammo_id;

        RETURN 'COMPATIBLE: ' || v_model || ' + ' || v_ammo
            || ' (Rating: ' || v_rating || '/10)';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'INCOMPATIBLE: ' || v_ammo || ' is not rated for ' || v_model;
    END;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'ERROR: Model or ammunition not found.';
END CHECK_AMMO_COMPATIBILITY;
/

-- ============================================================
-- FUNCTION 4: GET_WEAPON_STATUS_SUMMARY
-- Returns a formatted status summary string for a weapon.
-- ============================================================
CREATE OR REPLACE FUNCTION GET_WEAPON_STATUS_SUMMARY (
    p_weapon_id IN NUMBER
) RETURN VARCHAR2 AS
    v_serial     WEAPON.serial_number%TYPE;
    v_model      WEAPON_MODEL.model_name%TYPE;
    v_status     WEAPON.current_status%TYPE;
    v_location   UNIT.unit_name%TYPE;
    v_rounds     WEAPON.total_rounds_fired%TYPE;
    v_reliability WEAPON.reliability_score%TYPE;
    v_next_due   DATE;
    v_summary    VARCHAR2(1000);
BEGIN
    SELECT w.serial_number, wm.model_name, w.current_status,
           u.unit_name, w.total_rounds_fired, w.reliability_score
    INTO v_serial, v_model, v_status, v_location, v_rounds, v_reliability
    FROM WEAPON w
    JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
    JOIN UNIT u ON w.current_location_id = u.unit_id
    WHERE w.weapon_id = p_weapon_id;

    v_next_due := GET_NEXT_SERVICE_DATE(p_weapon_id);

    v_summary := '=== WEAPON STATUS ===' || CHR(10)
        || 'Serial: ' || v_serial || CHR(10)
        || 'Model: ' || v_model || CHR(10)
        || 'Status: ' || v_status || CHR(10)
        || 'Location: ' || v_location || CHR(10)
        || 'Rounds Fired: ' || v_rounds || CHR(10)
        || 'Reliability: ' || v_reliability || '%' || CHR(10)
        || 'Next Service: ' || NVL(TO_CHAR(v_next_due, 'YYYY-MM-DD'), 'N/A');

    RETURN v_summary;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'ERROR: Weapon ID ' || p_weapon_id || ' not found.';
END GET_WEAPON_STATUS_SUMMARY;
/

-- ============================================================
-- FUNCTION 5: COUNT_ACTIVE_WEAPONS
-- Returns the count of active weapons in a given unit.
-- ============================================================
CREATE OR REPLACE FUNCTION COUNT_ACTIVE_WEAPONS (
    p_unit_id IN NUMBER
) RETURN NUMBER AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM WEAPON
    WHERE current_location_id = p_unit_id
      AND current_status = 'Active';

    RETURN v_count;
END COUNT_ACTIVE_WEAPONS;
/

-- ============================================================
-- FUNCTION 6: GET_CUSTODY_DURATION
-- Returns the number of days a custodian has held a weapon
-- (from most recent transfer to today or next transfer).
-- ============================================================
CREATE OR REPLACE FUNCTION GET_CUSTODY_DURATION (
    p_weapon_id   IN NUMBER,
    p_custodian_id IN NUMBER
) RETURN NUMBER AS
    v_transfer_date  DATE;
    v_next_transfer  DATE;
    v_days           NUMBER;
BEGIN
    -- Get the most recent transfer TO this custodian for this weapon
    SELECT MAX(transfer_date) INTO v_transfer_date
    FROM CUSTODY_HISTORY
    WHERE weapon_id = p_weapon_id AND custodian_id = p_custodian_id;

    IF v_transfer_date IS NULL THEN
        RETURN -1; -- No custody record found
    END IF;

    -- Check if there's a later transfer (weapon moved away)
    SELECT MIN(transfer_date) INTO v_next_transfer
    FROM CUSTODY_HISTORY
    WHERE weapon_id = p_weapon_id
      AND transfer_date > v_transfer_date;

    IF v_next_transfer IS NOT NULL THEN
        v_days := v_next_transfer - v_transfer_date;
    ELSE
        v_days := SYSDATE - v_transfer_date;
    END IF;

    RETURN ROUND(v_days);
END GET_CUSTODY_DURATION;
/

-- ============================================================
-- TEST CALLS
-- ============================================================
-- Display calculated reliability for weapon 1
SELECT CALC_RELIABILITY_SCORE(1) AS calc_reliability FROM DUAL;

-- Next service date for weapon 3
SELECT GET_NEXT_SERVICE_DATE(3) AS next_service FROM DUAL;

-- Check ammo compatibility
SELECT CHECK_AMMO_COMPATIBILITY(1, 1) AS compat_result FROM DUAL;
SELECT CHECK_AMMO_COMPATIBILITY(1, 5) AS compat_result FROM DUAL;

-- Weapon status summary
SELECT GET_WEAPON_STATUS_SUMMARY(1) AS status_summary FROM DUAL;

-- Active weapon count for Unit 1
SELECT COUNT_ACTIVE_WEAPONS(1) AS active_in_unit1 FROM DUAL;

-- Custody duration
SELECT GET_CUSTODY_DURATION(1, 2) AS days_held FROM DUAL;

PROMPT '>>> All 6 functions created and tested successfully.';
