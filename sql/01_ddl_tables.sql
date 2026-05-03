
-- DEFENSE ASSET MANAGEMENT SYSTEM
-- 01_ddl_tables.sql — Table Creation with Constraints

-- DROP EXISTING OBJECTS (for re-runs)


BEGIN EXECUTE IMMEDIATE 'DROP TABLE AUDIT_LOG CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AMMO_COMPATIBILITY CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AMMUNITION_TYPE CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE MAINTENANCE_RECORD CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE CUSTODY_HISTORY CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE WEAPON CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE CUSTODIAN CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE UNIT CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE WEAPON_MODEL CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE MANUFACTURER CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- 1. MANUFACTURER

CREATE TABLE MANUFACTURER (
    manufacturer_id   NUMBER        PRIMARY KEY,
    company_name      VARCHAR2(100) NOT NULL UNIQUE,
    country           VARCHAR2(50)  NOT NULL,
    certification_status VARCHAR2(20) NOT NULL
        CHECK (certification_status IN ('Certified','Suspended','Revoked','Pending'))
);

-- 2. WEAPON_MODEL

CREATE TABLE WEAPON_MODEL (
    model_id          NUMBER        PRIMARY KEY,
    manufacturer_id   NUMBER        NOT NULL,
    model_name        VARCHAR2(100) NOT NULL,
    weapon_type       VARCHAR2(30)  NOT NULL
        CHECK (weapon_type IN ('Assault Rifle','Battle Rifle','Sniper Rifle',
               'Pistol','SMG','LMG','GPMG','Shotgun','Grenade Launcher','DMR')),
    caliber           VARCHAR2(30)  NOT NULL,
    specifications    VARCHAR2(500),
    CONSTRAINT fk_wm_manufacturer FOREIGN KEY (manufacturer_id)
        REFERENCES MANUFACTURER(manufacturer_id)
);

-- 3. UNIT  (commanding_officer_id FK added later via ALTER TABLE)

CREATE TABLE UNIT (
    unit_id               NUMBER        PRIMARY KEY,
    unit_name             VARCHAR2(100) NOT NULL UNIQUE,
    base_location         VARCHAR2(100) NOT NULL,
    commanding_officer_id NUMBER            -- FK added after CUSTODIAN exists
);

-- ============================================================
-- 4. CUSTODIAN
-- ============================================================
CREATE TABLE CUSTODIAN (
    custodian_id    NUMBER        PRIMARY KEY,
    full_name       VARCHAR2(100) NOT NULL,
    rank            VARCHAR2(50)  NOT NULL,
    unit_id         NUMBER        NOT NULL,
    clearance_level NUMBER(1)     NOT NULL
        CHECK (clearance_level BETWEEN 1 AND 5),
    CONSTRAINT fk_cust_unit FOREIGN KEY (unit_id)
        REFERENCES UNIT(unit_id)
);

-- Now add the deferred FK from UNIT → CUSTODIAN
ALTER TABLE UNIT ADD CONSTRAINT fk_unit_commander
    FOREIGN KEY (commanding_officer_id)
    REFERENCES CUSTODIAN(custodian_id);

-- ============================================================
-- 5. WEAPON
-- ============================================================
CREATE TABLE WEAPON (
    weapon_id           NUMBER         PRIMARY KEY,
    model_id            NUMBER         NOT NULL,
    serial_number       VARCHAR2(30)   NOT NULL UNIQUE,
    manufacture_date    DATE           NOT NULL,
    current_status      VARCHAR2(20)   NOT NULL
        CHECK (current_status IN ('Active','In Maintenance','Decommissioned',
               'In Transit','In Storage')),
    current_location_id NUMBER         NOT NULL,
    total_rounds_fired  NUMBER         DEFAULT 0 NOT NULL,
    reliability_score   NUMBER(5,2)    DEFAULT 100.00,
    CONSTRAINT fk_weap_model FOREIGN KEY (model_id)
        REFERENCES WEAPON_MODEL(model_id),
    CONSTRAINT fk_weap_location FOREIGN KEY (current_location_id)
        REFERENCES UNIT(unit_id),
    CONSTRAINT chk_rounds CHECK (total_rounds_fired >= 0),
    CONSTRAINT chk_reliability CHECK (reliability_score BETWEEN 0 AND 100)
);

-- Index on frequently queried columns
CREATE INDEX idx_weapon_status ON WEAPON(current_status);
CREATE INDEX idx_weapon_location ON WEAPON(current_location_id);

-- ============================================================
-- 6. CUSTODY_HISTORY
-- ============================================================
CREATE TABLE CUSTODY_HISTORY (
    custody_id      NUMBER   PRIMARY KEY,
    weapon_id       NUMBER   NOT NULL,
    custodian_id    NUMBER   NOT NULL,
    unit_id         NUMBER   NOT NULL,
    transfer_date   DATE     NOT NULL,
    authorized_by   NUMBER   NOT NULL,
    remarks         VARCHAR2(300),
    CONSTRAINT fk_ch_weapon    FOREIGN KEY (weapon_id)    REFERENCES WEAPON(weapon_id),
    CONSTRAINT fk_ch_custodian FOREIGN KEY (custodian_id) REFERENCES CUSTODIAN(custodian_id),
    CONSTRAINT fk_ch_unit      FOREIGN KEY (unit_id)      REFERENCES UNIT(unit_id),
    CONSTRAINT fk_ch_auth      FOREIGN KEY (authorized_by) REFERENCES CUSTODIAN(custodian_id)
);

CREATE INDEX idx_custody_weapon ON CUSTODY_HISTORY(weapon_id);
CREATE INDEX idx_custody_date   ON CUSTODY_HISTORY(transfer_date);

-- ============================================================
-- 7. MAINTENANCE_RECORD
-- ============================================================
CREATE TABLE MAINTENANCE_RECORD (
    maintenance_id    NUMBER        PRIMARY KEY,
    weapon_id         NUMBER        NOT NULL,
    scheduled_date    DATE          NOT NULL,
    completed_date    DATE,
    technician_id     NUMBER        NOT NULL,
    maintenance_type  VARCHAR2(20)  NOT NULL
        CHECK (maintenance_type IN ('Routine','Preventive','Corrective',
               'Emergency','Overhaul')),
    description       VARCHAR2(500),
    next_service_due  DATE,
    CONSTRAINT fk_mr_weapon     FOREIGN KEY (weapon_id)     REFERENCES WEAPON(weapon_id),
    CONSTRAINT fk_mr_technician FOREIGN KEY (technician_id) REFERENCES CUSTODIAN(custodian_id),
    CONSTRAINT chk_maint_dates  CHECK (completed_date IS NULL OR completed_date >= scheduled_date)
);

CREATE INDEX idx_maint_weapon ON MAINTENANCE_RECORD(weapon_id);
CREATE INDEX idx_maint_due    ON MAINTENANCE_RECORD(next_service_due);

-- ============================================================
-- 8. AMMUNITION_TYPE
-- ============================================================
CREATE TABLE AMMUNITION_TYPE (
    ammo_id           NUMBER        PRIMARY KEY,
    caliber           VARCHAR2(30)  NOT NULL,
    ammo_name         VARCHAR2(100) NOT NULL,
    manufacturer_id   NUMBER        NOT NULL,
    stock_quantity    NUMBER        NOT NULL CHECK (stock_quantity >= 0),
    expiry_date       DATE          NOT NULL,
    CONSTRAINT fk_ammo_manufacturer FOREIGN KEY (manufacturer_id)
        REFERENCES MANUFACTURER(manufacturer_id)
);

-- ============================================================
-- 9. AMMO_COMPATIBILITY
-- ============================================================
CREATE TABLE AMMO_COMPATIBILITY (
    compatibility_id    NUMBER       PRIMARY KEY,
    model_id            NUMBER       NOT NULL,
    ammo_id             NUMBER       NOT NULL,
    effectiveness_rating NUMBER(3,1) NOT NULL
        CHECK (effectiveness_rating BETWEEN 0 AND 10),
    CONSTRAINT fk_ac_model FOREIGN KEY (model_id) REFERENCES WEAPON_MODEL(model_id),
    CONSTRAINT fk_ac_ammo  FOREIGN KEY (ammo_id)  REFERENCES AMMUNITION_TYPE(ammo_id),
    CONSTRAINT uq_model_ammo UNIQUE (model_id, ammo_id)
);

-- ============================================================
-- 10. AUDIT_LOG
-- ============================================================
CREATE TABLE AUDIT_LOG (
    log_id          NUMBER         PRIMARY KEY,
    table_name      VARCHAR2(50)   NOT NULL,
    operation_type  VARCHAR2(10)   NOT NULL
        CHECK (operation_type IN ('INSERT','UPDATE','DELETE')),
    record_id       NUMBER,
    old_values      VARCHAR2(1000),
    new_values      VARCHAR2(1000),
    changed_by      VARCHAR2(100)  NOT NULL,
    change_timestamp TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL
);

CREATE INDEX idx_audit_table ON AUDIT_LOG(table_name);
CREATE INDEX idx_audit_time  ON AUDIT_LOG(change_timestamp);

-- ============================================================
PROMPT '>>> All 10 tables created successfully.';
-- ============================================================
