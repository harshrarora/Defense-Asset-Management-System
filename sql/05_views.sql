-- ============================================================
-- DEFENSE ASSET MANAGEMENT SYSTEM
-- 05_views.sql — Role-Based Access Control Views
-- ============================================================

-- Drop existing views for re-runs
BEGIN EXECUTE IMMEDIATE 'DROP VIEW VW_ARMORY_OFFICER'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW VW_UNIT_COMMANDER'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW VW_MAINTENANCE_TECH'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW VW_AUDITOR'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW VW_WEAPON_READINESS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW VW_AMMO_STOCK'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ============================================================
-- VIEW 1: ARMORY OFFICER — Full weapon inventory with all details
-- Full read/write access to inventory, custody, and maintenance
-- ============================================================
CREATE OR REPLACE VIEW VW_ARMORY_OFFICER AS
SELECT w.weapon_id, w.serial_number, wm.model_name, wm.weapon_type,
       wm.caliber, m.company_name AS manufacturer,
       w.manufacture_date, w.current_status, u.unit_name AS location,
       w.total_rounds_fired, w.reliability_score,
       (SELECT c.full_name FROM CUSTODY_HISTORY ch
        JOIN CUSTODIAN c ON ch.custodian_id = c.custodian_id
        WHERE ch.weapon_id = w.weapon_id
          AND ch.transfer_date = (SELECT MAX(ch2.transfer_date)
                                  FROM CUSTODY_HISTORY ch2
                                  WHERE ch2.weapon_id = w.weapon_id)
          AND ROWNUM = 1
       ) AS current_custodian,
       (SELECT mr.next_service_due FROM MAINTENANCE_RECORD mr
        WHERE mr.weapon_id = w.weapon_id
          AND mr.scheduled_date = (SELECT MAX(mr2.scheduled_date)
                                   FROM MAINTENANCE_RECORD mr2
                                   WHERE mr2.weapon_id = w.weapon_id)
          AND ROWNUM = 1
       ) AS next_service_due
FROM WEAPON w
JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
JOIN MANUFACTURER m  ON wm.manufacturer_id = m.manufacturer_id
JOIN UNIT u          ON w.current_location_id = u.unit_id;

-- ============================================================
-- VIEW 2: UNIT COMMANDER — Weapons assigned to a specific unit
-- Parameterized by querying: SELECT * FROM VW_UNIT_COMMANDER WHERE unit_id = ?
-- ============================================================
CREATE OR REPLACE VIEW VW_UNIT_COMMANDER AS
SELECT u.unit_id, u.unit_name, u.base_location,
       w.weapon_id, w.serial_number, wm.model_name,
       wm.weapon_type, w.current_status, w.reliability_score,
       c_cmd.full_name AS commanding_officer,
       (SELECT COUNT(*) FROM WEAPON w2
        WHERE w2.current_location_id = u.unit_id
          AND w2.current_status = 'Active') AS active_weapons_in_unit
FROM UNIT u
JOIN WEAPON w ON w.current_location_id = u.unit_id
JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
LEFT JOIN CUSTODIAN c_cmd ON u.commanding_officer_id = c_cmd.custodian_id;

-- Usage: SELECT * FROM VW_UNIT_COMMANDER WHERE unit_id = 1;

-- ============================================================
-- VIEW 3: MAINTENANCE TECHNICIAN — Maintenance records to work on
-- Shows pending and completed maintenance with weapon details
-- ============================================================
CREATE OR REPLACE VIEW VW_MAINTENANCE_TECH AS
SELECT mr.maintenance_id, w.serial_number, wm.model_name,
       wm.weapon_type, mr.maintenance_type,
       mr.scheduled_date, mr.completed_date,
       CASE WHEN mr.completed_date IS NULL AND mr.scheduled_date < SYSDATE
            THEN 'OVERDUE'
            WHEN mr.completed_date IS NULL
            THEN 'PENDING'
            ELSE 'COMPLETED'
       END AS maint_status,
       mr.description, mr.next_service_due,
       c.full_name AS technician_name, c.custodian_id AS technician_id,
       u.unit_name AS weapon_location
FROM MAINTENANCE_RECORD mr
JOIN WEAPON w ON mr.weapon_id = w.weapon_id
JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
JOIN CUSTODIAN c ON mr.technician_id = c.custodian_id
JOIN UNIT u ON w.current_location_id = u.unit_id;

-- Usage: SELECT * FROM VW_MAINTENANCE_TECH WHERE technician_id = 12;

-- ============================================================
-- VIEW 4: AUDITOR — Read-only audit trail and compliance view
-- ============================================================
CREATE OR REPLACE VIEW VW_AUDITOR AS
SELECT al.log_id, al.table_name, al.operation_type,
       al.record_id, al.old_values, al.new_values,
       al.changed_by, al.change_timestamp,
       TO_CHAR(al.change_timestamp, 'YYYY-MM-DD HH24:MI:SS') AS formatted_time
FROM AUDIT_LOG al
ORDER BY al.change_timestamp DESC;

-- ============================================================
-- VIEW 5: WEAPON READINESS DASHBOARD — Summary for all users
-- ============================================================
CREATE OR REPLACE VIEW VW_WEAPON_READINESS AS
SELECT w.weapon_id, w.serial_number, wm.model_name,
       wm.weapon_type, u.unit_name,
       w.current_status, w.reliability_score,
       CASE
           WHEN w.current_status = 'Decommissioned' THEN 'RETIRED'
           WHEN w.current_status IN ('In Maintenance','In Transit') THEN 'UNAVAILABLE'
           WHEN w.current_status = 'In Storage' THEN 'RESERVE'
           WHEN w.reliability_score >= 95 THEN 'COMBAT READY'
           WHEN w.reliability_score >= 85 THEN 'FIELD READY'
           WHEN w.reliability_score >= 70 THEN 'LIMITED DUTY'
           ELSE 'NEEDS OVERHAUL'
       END AS readiness_class,
       w.total_rounds_fired
FROM WEAPON w
JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
JOIN UNIT u ON w.current_location_id = u.unit_id;

-- ============================================================
-- VIEW 6: AMMO STOCK — Ammunition inventory with compatibility
-- ============================================================
CREATE OR REPLACE VIEW VW_AMMO_STOCK AS
SELECT at.ammo_id, at.ammo_name, at.caliber,
       m.company_name AS manufacturer,
       at.stock_quantity, at.expiry_date,
       CASE
           WHEN at.expiry_date < SYSDATE THEN 'EXPIRED'
           WHEN at.expiry_date < ADD_MONTHS(SYSDATE, 6) THEN 'EXPIRING SOON'
           ELSE 'VALID'
       END AS expiry_status,
       (SELECT COUNT(*) FROM AMMO_COMPATIBILITY ac
        WHERE ac.ammo_id = at.ammo_id) AS compatible_model_count,
       (SELECT LISTAGG(wm.model_name, ', ') WITHIN GROUP (ORDER BY wm.model_name)
        FROM AMMO_COMPATIBILITY ac
        JOIN WEAPON_MODEL wm ON ac.model_id = wm.model_id
        WHERE ac.ammo_id = at.ammo_id) AS compatible_models
FROM AMMUNITION_TYPE at
JOIN MANUFACTURER m ON at.manufacturer_id = m.manufacturer_id;

PROMPT '>>> All 6 role-based views created successfully.';
