
-- DEFENSE ASSET MANAGEMENT SYSTEM
-- 03a_insert_data_part1.sql — Sample Data (Part 1)
-- MANUFACTURER, WEAPON_MODEL, UNIT, CUSTODIAN
-- Run AFTER 01_ddl_tables.sql and 02_sequences.sql

-- MANUFACTURERS (10 rows)

INSERT INTO MANUFACTURER VALUES (1, 'Lockheed Martin', 'USA', 'Certified');
INSERT INTO MANUFACTURER VALUES (2, 'BAE Systems', 'United Kingdom', 'Certified');
INSERT INTO MANUFACTURER VALUES (3, 'Rheinmetall AG', 'Germany', 'Certified');
INSERT INTO MANUFACTURER VALUES (4, 'Thales Group', 'France', 'Certified');
INSERT INTO MANUFACTURER VALUES (5, 'General Dynamics', 'USA', 'Certified');
INSERT INTO MANUFACTURER VALUES (6, 'Heckler and Koch', 'Germany', 'Certified');
INSERT INTO MANUFACTURER VALUES (7, 'FN Herstal', 'Belgium', 'Certified');
INSERT INTO MANUFACTURER VALUES (8, 'Beretta', 'Italy', 'Certified');
INSERT INTO MANUFACTURER VALUES (9, 'SIG Sauer', 'USA', 'Certified');
INSERT INTO MANUFACTURER VALUES (10, 'Kalashnikov Concern', 'Russia', 'Suspended');


-- WEAPON_MODELS (20 rows)

INSERT INTO WEAPON_MODEL VALUES (1, 6, 'HK416', 'Assault Rifle', '5.56x45mm NATO', 'Gas-operated, rotating bolt, 850 rpm');
INSERT INTO WEAPON_MODEL VALUES (2, 5, 'M4A1 Carbine', 'Assault Rifle', '5.56x45mm NATO', 'Gas-operated, direct impingement, 700-950 rpm');
INSERT INTO WEAPON_MODEL VALUES (3, 10, 'AK-103', 'Assault Rifle', '7.62x39mm', 'Gas-operated, rotating bolt, 600 rpm');
INSERT INTO WEAPON_MODEL VALUES (4, 7, 'FN SCAR-H', 'Battle Rifle', '7.62x51mm NATO', 'Gas-operated, short-stroke piston, 625 rpm');
INSERT INTO WEAPON_MODEL VALUES (5, 7, 'M249 SAW', 'LMG', '5.56x45mm NATO', 'Gas-operated, open bolt, 750-1000 rpm');
INSERT INTO WEAPON_MODEL VALUES (6, 7, 'M240B', 'GPMG', '7.62x51mm NATO', 'Gas-operated, open bolt, 650-950 rpm');
INSERT INTO WEAPON_MODEL VALUES (7, 1, 'Barrett M82', 'Sniper Rifle', '12.7x99mm NATO', 'Recoil-operated, semi-auto, 10 rd mag');
INSERT INTO WEAPON_MODEL VALUES (8, 3, 'M24 SWS', 'Sniper Rifle', '7.62x51mm NATO', 'Bolt-action, 5 rd internal mag');
INSERT INTO WEAPON_MODEL VALUES (9, 8, 'Beretta M9', 'Pistol', '9x19mm Parabellum', 'Short recoil, DA/SA, 15 rd mag');
INSERT INTO WEAPON_MODEL VALUES (10, 9, 'SIG P320', 'Pistol', '9x19mm Parabellum', 'Striker-fired, modular, 17 rd mag');
INSERT INTO WEAPON_MODEL VALUES (11, 9, 'SIG P226', 'Pistol', '9x19mm Parabellum', 'Short recoil, DA/SA, 15 rd mag');
INSERT INTO WEAPON_MODEL VALUES (12, 6, 'MP5A3', 'SMG', '9x19mm Parabellum', 'Roller-delayed blowback, 800 rpm');
INSERT INTO WEAPON_MODEL VALUES (13, 6, 'HK MP7', 'SMG', '4.6x30mm', 'Gas-operated, rotating bolt, 950 rpm');
INSERT INTO WEAPON_MODEL VALUES (14, 7, 'FN P90', 'SMG', '5.7x28mm', 'Blowback-operated, 900 rpm, 50 rd mag');
INSERT INTO WEAPON_MODEL VALUES (15, 8, 'Benelli M4', 'Shotgun', '12 Gauge', 'Gas-operated semi-auto, 7 rd tube');
INSERT INTO WEAPON_MODEL VALUES (16, 5, 'Mossberg 590A1', 'Shotgun', '12 Gauge', 'Pump-action, 9 rd tube, mil-spec');
INSERT INTO WEAPON_MODEL VALUES (17, 2, 'L85A2', 'Assault Rifle', '5.56x45mm NATO', 'Gas-operated, bullpup, 610-775 rpm');
INSERT INTO WEAPON_MODEL VALUES (18, 4, 'FAMAS G2', 'Assault Rifle', '5.56x45mm NATO', 'Lever-delayed blowback, bullpup, 1000 rpm');
INSERT INTO WEAPON_MODEL VALUES (19, 3, 'MG3', 'GPMG', '7.62x51mm NATO', 'Recoil-operated, roller-locked, 1200 rpm');
INSERT INTO WEAPON_MODEL VALUES (20, 6, 'HK G36', 'Assault Rifle', '5.56x45mm NATO', 'Gas-operated, rotating bolt, 750 rpm');

-- UNITS (12 rows) — commanding_officer_id set to NULL initially

INSERT INTO UNIT VALUES (1, '1st Infantry Battalion', 'Fort Bragg', NULL);
INSERT INTO UNIT VALUES (2, '2nd Armored Regiment', 'Fort Knox', NULL);
INSERT INTO UNIT VALUES (3, '3rd Special Forces Group', 'Camp Mackall', NULL);
INSERT INTO UNIT VALUES (4, '4th Artillery Brigade', 'Fort Sill', NULL);
INSERT INTO UNIT VALUES (5, '5th Logistics Support Unit', 'Fort Lee', NULL);
INSERT INTO UNIT VALUES (6, '6th Reconnaissance Squadron', 'Fort Huachuca', NULL);
INSERT INTO UNIT VALUES (7, '7th Marine Battalion', 'Camp Pendleton', NULL);
INSERT INTO UNIT VALUES (8, '8th Airborne Division', 'Fort Campbell', NULL);
INSERT INTO UNIT VALUES (9, '9th Engineering Corps', 'Fort Leonard Wood', NULL);
INSERT INTO UNIT VALUES (10, '10th Signal Regiment', 'Fort Gordon', NULL);
INSERT INTO UNIT VALUES (11, 'Central Armory Depot', 'Aberdeen Proving Ground', NULL);
INSERT INTO UNIT VALUES (12, 'Weapons Training Academy', 'Fort Benning', NULL);


-- CUSTODIANS (30 rows)

INSERT INTO CUSTODIAN VALUES (1, 'Col. James Mitchell', 'Colonel', 1, 5);
INSERT INTO CUSTODIAN VALUES (2, 'Sgt. Robert Chen', 'Sergeant', 1, 2);
INSERT INTO CUSTODIAN VALUES (3, 'Cpl. Maria Santos', 'Corporal', 1, 2);
INSERT INTO CUSTODIAN VALUES (4, 'Col. David Armstrong', 'Colonel', 2, 5);
INSERT INTO CUSTODIAN VALUES (5, 'SFC Ahmed Khan', 'Sergeant First Class', 2, 3);
INSERT INTO CUSTODIAN VALUES (6, 'Pvt. Lisa Thompson', 'Private', 2, 1);
INSERT INTO CUSTODIAN VALUES (7, 'Lt. Col. Viktor Petrov', 'Lieutenant Colonel', 3, 5);
INSERT INTO CUSTODIAN VALUES (8, 'MSG Sarah OBrien', 'Master Sergeant', 3, 4);
INSERT INTO CUSTODIAN VALUES (9, 'Sgt. Wei Zhang', 'Sergeant', 3, 3);
INSERT INTO CUSTODIAN VALUES (10, 'Col. Richard Hayes', 'Colonel', 4, 5);
INSERT INTO CUSTODIAN VALUES (11, 'SSgt. Jennifer Cruz', 'Staff Sergeant', 4, 2);
INSERT INTO CUSTODIAN VALUES (12, 'Spc. Thomas Baker', 'Specialist', 4, 2);
INSERT INTO CUSTODIAN VALUES (13, 'Maj. Natasha Volkov', 'Major', 5, 4);
INSERT INTO CUSTODIAN VALUES (14, 'Sgt. Carlos Rivera', 'Sergeant', 5, 2);
INSERT INTO CUSTODIAN VALUES (15, 'Pvt. Emma Wilson', 'Private', 5, 1);
INSERT INTO CUSTODIAN VALUES (16, 'Lt. Col. James OConnor', 'Lieutenant Colonel', 6, 5);
INSERT INTO CUSTODIAN VALUES (17, 'SSgt. Aisha Patel', 'Staff Sergeant', 6, 3);
INSERT INTO CUSTODIAN VALUES (18, 'Cpl. Derek Frost', 'Corporal', 6, 2);
INSERT INTO CUSTODIAN VALUES (19, 'Col. Michael Torres', 'Colonel', 7, 5);
INSERT INTO CUSTODIAN VALUES (20, 'SFC Rachel Kim', 'Sergeant First Class', 7, 3);
INSERT INTO CUSTODIAN VALUES (21, 'LCpl. Ryan Cooper', 'Lance Corporal', 7, 2);
INSERT INTO CUSTODIAN VALUES (22, 'Col. Andrew Barrett', 'Colonel', 8, 5);
INSERT INTO CUSTODIAN VALUES (23, 'MSG Patrick Sullivan', 'Master Sergeant', 8, 4);
INSERT INTO CUSTODIAN VALUES (24, 'Sgt. Diana Reyes', 'Sergeant', 8, 2);
INSERT INTO CUSTODIAN VALUES (25, 'Maj. Katherine Wright', 'Major', 9, 4);
INSERT INTO CUSTODIAN VALUES (26, 'SSgt. Marcus Johnson', 'Staff Sergeant', 9, 3);
INSERT INTO CUSTODIAN VALUES (27, 'Pvt. Hannah Lee', 'Private', 9, 1);
INSERT INTO CUSTODIAN VALUES (28, 'Col. George Franklin', 'Colonel', 10, 5);
INSERT INTO CUSTODIAN VALUES (29, 'Lt. Col. Samuel Grant', 'Lieutenant Colonel', 12, 5);
INSERT INTO CUSTODIAN VALUES (30, 'Maj. Olivia Marshall', 'Major', 11, 4);

-- ============================================================
-- UPDATE UNIT commanding officers (now that CUSTODIAN rows exist)
-- ============================================================
UPDATE UNIT SET commanding_officer_id = 1  WHERE unit_id = 1;
UPDATE UNIT SET commanding_officer_id = 4  WHERE unit_id = 2;
UPDATE UNIT SET commanding_officer_id = 7  WHERE unit_id = 3;
UPDATE UNIT SET commanding_officer_id = 10 WHERE unit_id = 4;
UPDATE UNIT SET commanding_officer_id = 13 WHERE unit_id = 5;
UPDATE UNIT SET commanding_officer_id = 16 WHERE unit_id = 6;
UPDATE UNIT SET commanding_officer_id = 19 WHERE unit_id = 7;
UPDATE UNIT SET commanding_officer_id = 22 WHERE unit_id = 8;
UPDATE UNIT SET commanding_officer_id = 25 WHERE unit_id = 9;
UPDATE UNIT SET commanding_officer_id = 28 WHERE unit_id = 10;
UPDATE UNIT SET commanding_officer_id = 30 WHERE unit_id = 11;
UPDATE UNIT SET commanding_officer_id = 29 WHERE unit_id = 12;

COMMIT;
PROMPT '>>> Part 1 data inserted: MANUFACTURER(10), WEAPON_MODEL(20), UNIT(12), CUSTODIAN(30)';
