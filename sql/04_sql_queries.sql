-- ============================================================
-- DEFENSE ASSET MANAGEMENT SYSTEM
-- 04_sql_queries.sql — Complex SQL Queries
-- Demonstrates: JOINs, Subqueries, Aggregates, GROUP BY,
--               HAVING, UNION, EXISTS, CASE, ROWNUM
-- ============================================================

-- ============================================================
-- Q1. INNER JOIN — Full weapon inventory with model & manufacturer
-- ============================================================
SELECT w.weapon_id, w.serial_number, wm.model_name, wm.weapon_type,
       wm.caliber, m.company_name AS manufacturer,
       w.current_status, u.unit_name AS current_location,
       w.total_rounds_fired, w.reliability_score
FROM WEAPON w
JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
JOIN MANUFACTURER m  ON wm.manufacturer_id = m.manufacturer_id
JOIN UNIT u          ON w.current_location_id = u.unit_id
ORDER BY w.weapon_id;

-- ============================================================
-- Q2. LEFT JOIN — All weapons with their latest maintenance (if any)
-- ============================================================
SELECT w.weapon_id, w.serial_number, wm.model_name,
       mr.maintenance_id, mr.maintenance_type, mr.scheduled_date,
       mr.completed_date, mr.next_service_due
FROM WEAPON w
JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
LEFT JOIN MAINTENANCE_RECORD mr ON w.weapon_id = mr.weapon_id
    AND mr.scheduled_date = (
        SELECT MAX(mr2.scheduled_date)
        FROM MAINTENANCE_RECORD mr2
        WHERE mr2.weapon_id = w.weapon_id
    )
ORDER BY w.weapon_id;

-- ============================================================
-- Q3. MULTI-TABLE JOIN — Full custody chain with details
-- ============================================================
SELECT ch.custody_id, w.serial_number, wm.model_name,
       c.full_name AS custodian, c.rank,
       u.unit_name, ch.transfer_date,
       auth.full_name AS authorized_by, ch.remarks
FROM CUSTODY_HISTORY ch
JOIN WEAPON w         ON ch.weapon_id = w.weapon_id
JOIN WEAPON_MODEL wm  ON w.model_id = wm.model_id
JOIN CUSTODIAN c      ON ch.custodian_id = c.custodian_id
JOIN UNIT u           ON ch.unit_id = u.unit_id
JOIN CUSTODIAN auth   ON ch.authorized_by = auth.custodian_id
ORDER BY ch.transfer_date DESC;

-- ============================================================
-- Q4. SUBQUERY (WHERE) — Weapons with more rounds fired than average
-- ============================================================
SELECT w.weapon_id, w.serial_number, wm.model_name,
       w.total_rounds_fired, w.reliability_score
FROM WEAPON w
JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
WHERE w.total_rounds_fired > (
    SELECT AVG(total_rounds_fired) FROM WEAPON
)
ORDER BY w.total_rounds_fired DESC;

-- ============================================================
-- Q5. SUBQUERY (FROM) — Top weapon models by avg reliability
-- ============================================================
SELECT model_rank.model_name, model_rank.weapon_type,
       model_rank.avg_reliability, model_rank.weapon_count
FROM (
    SELECT wm.model_name, wm.weapon_type,
           ROUND(AVG(w.reliability_score), 2) AS avg_reliability,
           COUNT(*) AS weapon_count
    FROM WEAPON w
    JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
    GROUP BY wm.model_name, wm.weapon_type
) model_rank
ORDER BY model_rank.avg_reliability DESC;

-- ============================================================
-- Q6. CORRELATED SUBQUERY — Weapons overdue for maintenance
-- ============================================================
SELECT w.weapon_id, w.serial_number, wm.model_name,
       w.current_status,
       (SELECT MAX(mr.next_service_due)
        FROM MAINTENANCE_RECORD mr
        WHERE mr.weapon_id = w.weapon_id) AS last_next_due
FROM WEAPON w
JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
WHERE w.current_status = 'Active'
  AND EXISTS (
      SELECT 1 FROM MAINTENANCE_RECORD mr
      WHERE mr.weapon_id = w.weapon_id
        AND mr.next_service_due < SYSDATE
        AND mr.completed_date IS NOT NULL
  )
ORDER BY w.weapon_id;

-- ============================================================
-- Q7. AGGREGATE + GROUP BY — Weapon count & avg reliability per unit
-- ============================================================
SELECT u.unit_name, u.base_location,
       COUNT(w.weapon_id) AS weapon_count,
       ROUND(AVG(w.reliability_score), 2) AS avg_reliability,
       SUM(w.total_rounds_fired) AS total_rounds
FROM UNIT u
LEFT JOIN WEAPON w ON u.unit_id = w.current_location_id
GROUP BY u.unit_name, u.base_location
ORDER BY weapon_count DESC;

-- ============================================================
-- Q8. AGGREGATE + GROUP BY — Weapons per type
-- ============================================================
SELECT wm.weapon_type,
       COUNT(w.weapon_id) AS total_weapons,
       SUM(CASE WHEN w.current_status = 'Active' THEN 1 ELSE 0 END) AS active,
       SUM(CASE WHEN w.current_status = 'In Maintenance' THEN 1 ELSE 0 END) AS in_maintenance,
       SUM(CASE WHEN w.current_status = 'Decommissioned' THEN 1 ELSE 0 END) AS decommissioned,
       SUM(CASE WHEN w.current_status IN ('In Storage','In Transit') THEN 1 ELSE 0 END) AS other
FROM WEAPON w
JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
GROUP BY wm.weapon_type
ORDER BY total_weapons DESC;

-- ============================================================
-- Q9. HAVING — Models with average reliability below 90
-- ============================================================
SELECT wm.model_name, wm.weapon_type,
       COUNT(w.weapon_id) AS weapon_count,
       ROUND(AVG(w.reliability_score), 2) AS avg_reliability,
       ROUND(AVG(w.total_rounds_fired), 0) AS avg_rounds_fired
FROM WEAPON w
JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
GROUP BY wm.model_name, wm.weapon_type
HAVING AVG(w.reliability_score) < 90
ORDER BY avg_reliability ASC;

-- ============================================================
-- Q10. UNION — Combined list of commanding officers and technicians
-- ============================================================
SELECT c.full_name, c.rank, u.unit_name, 'Commanding Officer' AS role
FROM CUSTODIAN c
JOIN UNIT u ON u.commanding_officer_id = c.custodian_id
UNION
SELECT DISTINCT c.full_name, c.rank, u.unit_name, 'Maintenance Technician' AS role
FROM CUSTODIAN c
JOIN MAINTENANCE_RECORD mr ON mr.technician_id = c.custodian_id
JOIN UNIT u ON c.unit_id = u.unit_id
ORDER BY role, full_name;

-- ============================================================
-- Q11. ROWNUM — Top 10 most-used weapons by rounds fired
-- ============================================================
SELECT * FROM (
    SELECT w.serial_number, wm.model_name, wm.weapon_type,
           w.total_rounds_fired, w.reliability_score,
           u.unit_name
    FROM WEAPON w
    JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
    JOIN UNIT u ON w.current_location_id = u.unit_id
    WHERE w.current_status != 'Decommissioned'
    ORDER BY w.total_rounds_fired DESC
) WHERE ROWNUM <= 10;

-- ============================================================
-- Q12. NOT EXISTS — Weapon models with NO compatible ammunition
-- ============================================================
SELECT wm.model_id, wm.model_name, wm.weapon_type, wm.caliber
FROM WEAPON_MODEL wm
WHERE NOT EXISTS (
    SELECT 1 FROM AMMO_COMPATIBILITY ac
    WHERE ac.model_id = wm.model_id
)
ORDER BY wm.model_name;

-- ============================================================
-- Q13. EXISTS — Custodians who have authorized transfers
-- ============================================================
SELECT c.custodian_id, c.full_name, c.rank, u.unit_name
FROM CUSTODIAN c
JOIN UNIT u ON c.unit_id = u.unit_id
WHERE EXISTS (
    SELECT 1 FROM CUSTODY_HISTORY ch
    WHERE ch.authorized_by = c.custodian_id
)
ORDER BY c.full_name;

-- ============================================================
-- Q14. CASE — Weapon readiness classification
-- ============================================================
SELECT w.serial_number, wm.model_name,
       w.current_status, w.reliability_score,
       CASE
           WHEN w.current_status = 'Decommissioned' THEN 'RETIRED'
           WHEN w.current_status IN ('In Maintenance','In Transit') THEN 'UNAVAILABLE'
           WHEN w.current_status = 'In Storage' THEN 'RESERVE'
           WHEN w.reliability_score >= 95 THEN 'COMBAT READY'
           WHEN w.reliability_score >= 85 THEN 'FIELD READY'
           WHEN w.reliability_score >= 70 THEN 'LIMITED DUTY'
           ELSE 'NEEDS OVERHAUL'
       END AS readiness_class
FROM WEAPON w
JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
ORDER BY w.weapon_id;

-- ============================================================
-- Q15. Ammunition stock report with compatibility count
-- ============================================================
SELECT at.ammo_id, at.ammo_name, at.caliber,
       m.company_name AS manufacturer,
       at.stock_quantity,
       at.expiry_date,
       CASE WHEN at.expiry_date < SYSDATE THEN 'EXPIRED'
            WHEN at.expiry_date < ADD_MONTHS(SYSDATE, 6) THEN 'EXPIRING SOON'
            ELSE 'VALID'
       END AS stock_status,
       (SELECT COUNT(*) FROM AMMO_COMPATIBILITY ac
        WHERE ac.ammo_id = at.ammo_id) AS compatible_models
FROM AMMUNITION_TYPE at
JOIN MANUFACTURER m ON at.manufacturer_id = m.manufacturer_id
ORDER BY at.expiry_date;

-- ============================================================
-- Q16. Maintenance history per weapon with running total
-- ============================================================
SELECT w.serial_number, wm.model_name,
       mr.maintenance_type, mr.scheduled_date, mr.completed_date,
       c.full_name AS technician,
       COUNT(*) OVER (PARTITION BY w.weapon_id ORDER BY mr.scheduled_date) AS maint_count
FROM MAINTENANCE_RECORD mr
JOIN WEAPON w ON mr.weapon_id = w.weapon_id
JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
JOIN CUSTODIAN c ON mr.technician_id = c.custodian_id
ORDER BY w.serial_number, mr.scheduled_date;

PROMPT '>>> All 16 SQL queries executed successfully.';
