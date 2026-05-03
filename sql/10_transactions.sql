-- ============================================================
-- DEFENSE ASSET MANAGEMENT SYSTEM
-- 10_transactions.sql — Transaction Management Demos
-- Demonstrates: COMMIT, ROLLBACK, SAVEPOINT, SELECT FOR UPDATE,
--               ACID Properties, Exception Handling
-- ============================================================

SET SERVEROUTPUT ON;

-- ============================================================
-- DEMO 1: SUCCESSFUL CUSTODY TRANSFER (COMMIT)
-- A fully valid custody transfer that completes and commits.
-- ============================================================
DECLARE
    v_custody_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== DEMO 1: Successful Custody Transfer ===');

    SELECT custody_seq.NEXTVAL INTO v_custody_id FROM DUAL;

    -- Transfer weapon 24 (SIG P226, In Storage) to Sgt. Rivera at Logistics
    INSERT INTO CUSTODY_HISTORY (custody_id, weapon_id, custodian_id, unit_id,
                                  transfer_date, authorized_by, remarks)
    VALUES (v_custody_id, 24, 14, 5, SYSDATE, 13, 'Activate stored weapon for logistics');

    UPDATE WEAPON SET current_status = 'Active', current_location_id = 5
    WHERE weapon_id = 24;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Transfer committed successfully. Custody ID: ' || v_custody_id);
    DBMS_OUTPUT.PUT_LINE('Weapon 24 now Active at Unit 5 (Logistics)');
END;
/

-- Verify the transfer
SELECT w.weapon_id, w.serial_number, w.current_status, u.unit_name
FROM WEAPON w JOIN UNIT u ON w.current_location_id = u.unit_id
WHERE w.weapon_id = 24;

-- ============================================================
-- DEMO 2: FAILED TRANSFER WITH ROLLBACK
-- Demonstrates ROLLBACK when validation fails.
-- ============================================================
DECLARE
    v_status  WEAPON.current_status%TYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== DEMO 2: Failed Transfer with ROLLBACK ===');

    -- Attempt to transfer decommissioned weapon 7
    SELECT current_status INTO v_status FROM WEAPON WHERE weapon_id = 7;

    DBMS_OUTPUT.PUT_LINE('Weapon 7 status: ' || v_status);

    IF v_status = 'Decommissioned' THEN
        DBMS_OUTPUT.PUT_LINE('VALIDATION FAILED: Cannot transfer decommissioned weapon.');
        DBMS_OUTPUT.PUT_LINE('No changes made — ROLLBACK not needed (no DML executed).');
    ELSE
        -- This block would execute if weapon were transferable
        DBMS_OUTPUT.PUT_LINE('Transfer would proceed here.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Transaction rolled back.');
END;
/

-- ============================================================
-- DEMO 3: SAVEPOINT — Partial Rollback
-- Multi-step operation where one step fails; partial rollback.
-- ============================================================
DECLARE
    v_cust1 NUMBER;
    v_cust2 NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== DEMO 3: SAVEPOINT — Partial Rollback ===');

    -- STEP 1: Schedule maintenance for weapon 2
    SAVEPOINT step1_maintenance;
    SELECT maintenance_seq.NEXTVAL INTO v_cust1 FROM DUAL;
    INSERT INTO MAINTENANCE_RECORD VALUES (v_cust1, 2, DATE '2026-07-01', NULL,
        3, 'Preventive', 'Scheduled gas system check', DATE '2027-01-01');
    DBMS_OUTPUT.PUT_LINE('Step 1: Maintenance scheduled (ID=' || v_cust1 || ') — OK');

    -- STEP 2: Try to update weapon status
    SAVEPOINT step2_status;
    -- Simulate: this update is fine
    UPDATE WEAPON SET current_status = 'Active' WHERE weapon_id = 2;
    DBMS_OUTPUT.PUT_LINE('Step 2: Weapon status confirmed — OK');

    -- STEP 3: Try invalid operation (simulate failure)
    SAVEPOINT step3_invalid;
    BEGIN
        -- Attempt to set negative rounds (will fail CHECK constraint)
        UPDATE WEAPON SET total_rounds_fired = -100 WHERE weapon_id = 2;
        DBMS_OUTPUT.PUT_LINE('Step 3: This should not print.');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Step 3: FAILED — ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('Rolling back to step2_status savepoint...');
            ROLLBACK TO step2_status;
    END;

    -- Steps 1 and 2 are preserved
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Steps 1 & 2 committed. Step 3 rolled back.');
END;
/

-- ============================================================
-- DEMO 4: SELECT ... FOR UPDATE — Row-Level Locking
-- Demonstrates concurrent transfer protection.
-- ============================================================
DECLARE
    v_weapon_id    NUMBER := 5;
    v_status       WEAPON.current_status%TYPE;
    v_location     WEAPON.current_location_id%TYPE;
    v_custody_id   NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== DEMO 4: SELECT ... FOR UPDATE (Row Locking) ===');

    -- Lock the weapon row to prevent concurrent modifications
    SELECT current_status, current_location_id
    INTO v_status, v_location
    FROM WEAPON
    WHERE weapon_id = v_weapon_id
    FOR UPDATE;  -- Row is now locked until COMMIT/ROLLBACK

    DBMS_OUTPUT.PUT_LINE('Row locked for weapon ' || v_weapon_id);
    DBMS_OUTPUT.PUT_LINE('Current status: ' || v_status || ', Location: Unit ' || v_location);

    IF v_status = 'Active' THEN
        -- Perform the transfer while row is locked
        SELECT custody_seq.NEXTVAL INTO v_custody_id FROM DUAL;
        INSERT INTO CUSTODY_HISTORY VALUES (v_custody_id, v_weapon_id, 6, 2,
            SYSDATE, 4, 'Concurrent-safe transfer demo');

        DBMS_OUTPUT.PUT_LINE('Transfer inserted (Custody ID=' || v_custody_id || ')');
        DBMS_OUTPUT.PUT_LINE('No other session can modify this weapon until COMMIT.');
    END IF;

    COMMIT;  -- Releases the lock
    DBMS_OUTPUT.PUT_LINE('Lock released after COMMIT.');
END;
/

-- ============================================================
-- DEMO 5: EXCEPTION HANDLING WITH ROLLBACK
-- Demonstrates robust error handling patterns.
-- ============================================================
DECLARE
    e_invalid_weapon EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_invalid_weapon, -20001);
    v_weapon_id NUMBER := 9999; -- Non-existent
    v_count     NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== DEMO 5: Exception Handling with ROLLBACK ===');

    SAVEPOINT before_operation;

    SELECT COUNT(*) INTO v_count FROM WEAPON WHERE weapon_id = v_weapon_id;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Weapon ' || v_weapon_id || ' does not exist');
    END IF;

EXCEPTION
    WHEN e_invalid_weapon THEN
        ROLLBACK TO before_operation;
        DBMS_OUTPUT.PUT_LINE('CUSTOM EXCEPTION: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Transaction safely rolled back.');

    WHEN NO_DATA_FOUND THEN
        ROLLBACK TO before_operation;
        DBMS_OUTPUT.PUT_LINE('NO_DATA_FOUND: Record not found.');

    WHEN OTHERS THEN
        ROLLBACK TO before_operation;
        DBMS_OUTPUT.PUT_LINE('UNEXPECTED ERROR: ' || SQLCODE || ' — ' || SQLERRM);
END;
/

-- ============================================================
-- DEMO 6: ACID PROPERTIES WALKTHROUGH
-- Commented demonstration of each ACID property.
-- ============================================================
DECLARE
    v_cust_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== DEMO 6: ACID Properties Walkthrough ===');
    DBMS_OUTPUT.PUT_LINE('');

    -- -------------------------------------------------------
    -- ATOMICITY: All or nothing
    -- The custody transfer below has 2 DML statements.
    -- Either BOTH succeed, or NEITHER takes effect.
    -- -------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('1. ATOMICITY (All-or-Nothing):');
    DBMS_OUTPUT.PUT_LINE('   Two DML statements (INSERT + UPDATE) execute as one unit.');

    SAVEPOINT atomicity_demo;
    SELECT custody_seq.NEXTVAL INTO v_cust_id FROM DUAL;

    INSERT INTO CUSTODY_HISTORY VALUES (v_cust_id, 30, 14, 5,
        SYSDATE, 13, 'ACID demo — atomicity test');
    UPDATE WEAPON SET current_location_id = 5 WHERE weapon_id = 30;

    -- If any statement above failed, we'd ROLLBACK TO atomicity_demo
    -- Since both succeeded, we commit as atomic unit
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('   Both operations committed atomically.');

    -- -------------------------------------------------------
    -- CONSISTENCY: Valid state transitions only
    -- -------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('2. CONSISTENCY (Valid States Only):');
    DBMS_OUTPUT.PUT_LINE('   CHECK constraints ensure reliability BETWEEN 0-100.');
    DBMS_OUTPUT.PUT_LINE('   FK constraints prevent orphan records.');
    DBMS_OUTPUT.PUT_LINE('   Triggers enforce business rules (e.g., no reactivation of decomm weapons).');

    -- -------------------------------------------------------
    -- ISOLATION: Concurrent access safety
    -- -------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('3. ISOLATION (Concurrent Access):');
    DBMS_OUTPUT.PUT_LINE('   SELECT...FOR UPDATE locks rows during transfer.');
    DBMS_OUTPUT.PUT_LINE('   Other sessions wait until lock is released by COMMIT/ROLLBACK.');
    DBMS_OUTPUT.PUT_LINE('   Prevents double-transfer of same weapon.');

    -- -------------------------------------------------------
    -- DURABILITY: Permanent after COMMIT
    -- -------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('4. DURABILITY (Permanent After COMMIT):');
    DBMS_OUTPUT.PUT_LINE('   After COMMIT, data persists even if system crashes.');
    DBMS_OUTPUT.PUT_LINE('   Oracle redo logs guarantee write-ahead logging.');
    DBMS_OUTPUT.PUT_LINE('   The custody transfer above is now permanent.');

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== ACID Properties Demonstrated Successfully ===');
END;
/

PROMPT '>>> All 6 transaction management demos executed successfully.';
