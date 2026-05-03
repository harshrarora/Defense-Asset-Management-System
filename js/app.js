// ============================================================
// APP.JS — Navigation, Inventory Table, SQL Showcase, Animations
// ============================================================

document.addEventListener('DOMContentLoaded', () => {
    initMermaid();
    initNavbar();
    initInventory();
    initShowcase();
    initScrollAnimations();
});

// ---- Mermaid Init ----
function initMermaid() {
    mermaid.initialize({
        startOnLoad: true,
        theme: 'dark',
        themeVariables: {
            primaryColor: '#1e3a5f',
            primaryTextColor: '#e2e8f0',
            primaryBorderColor: '#3b82f6',
            lineColor: '#3b82f6',
            secondaryColor: '#0c1220',
            tertiaryColor: '#0f1b2d',
            fontSize: '13px'
        },
        er: { useMaxWidth: true, layoutDirection: 'TB' }
    });
}

// ---- Navbar ----
function initNavbar() {
    const nav = document.getElementById('navbar');
    const toggle = document.getElementById('navToggle');
    const links = document.getElementById('navLinks');

    window.addEventListener('scroll', () => {
        nav.classList.toggle('scrolled', window.scrollY > 50);
    });

    toggle.addEventListener('click', () => links.classList.toggle('open'));

    document.querySelectorAll('.nav-links a').forEach(a => {
        a.addEventListener('click', () => links.classList.remove('open'));
    });

    // Active link on scroll
    const sections = document.querySelectorAll('section[id]');
    window.addEventListener('scroll', () => {
        const scrollY = window.scrollY + 100;
        sections.forEach(sec => {
            const top = sec.offsetTop;
            const h = sec.offsetHeight;
            const id = sec.getAttribute('id');
            const link = document.querySelector(`.nav-links a[href="#${id}"]`);
            if (link) link.classList.toggle('active', scrollY >= top && scrollY < top + h);
        });
    });
}

// ---- Inventory Table ----
let sortCol = 'id', sortAsc = true;

function initInventory() {
    renderInventory();

    document.getElementById('searchInput').addEventListener('input', renderInventory);
    document.getElementById('statusFilter').addEventListener('change', renderInventory);
    document.getElementById('typeFilter').addEventListener('change', renderInventory);

    document.querySelectorAll('#inventoryTable th[data-sort]').forEach(th => {
        th.addEventListener('click', () => {
            const col = th.dataset.sort;
            if (sortCol === col) sortAsc = !sortAsc;
            else { sortCol = col; sortAsc = true; }
            renderInventory();
        });
    });
}

function renderInventory() {
    const search = document.getElementById('searchInput').value.toLowerCase();
    const statusF = document.getElementById('statusFilter').value;
    const typeF = document.getElementById('typeFilter').value;

    let rows = DATA.weapons.map(w => ({
        ...w,
        modelName: getModelName(w.model),
        typeName: getModelType(w.model),
        unitName: getUnitName(w.unit)
    }));

    // Filter
    if (search) rows = rows.filter(r =>
        r.serial.toLowerCase().includes(search) ||
        r.modelName.toLowerCase().includes(search) ||
        r.unitName.toLowerCase().includes(search)
    );
    if (statusF) rows = rows.filter(r => r.status === statusF);
    if (typeF) rows = rows.filter(r => r.typeName === typeF);

    // Sort
    const key = {id:'id',serial:'serial',model:'modelName',type:'typeName',
                 status:'status',unit:'unitName',rounds:'rounds',reliability:'rel'}[sortCol];
    rows.sort((a,b) => {
        let va = a[key], vb = b[key];
        if (typeof va === 'string') { va = va.toLowerCase(); vb = vb.toLowerCase(); }
        if (va < vb) return sortAsc ? -1 : 1;
        if (va > vb) return sortAsc ? 1 : -1;
        return 0;
    });

    const tbody = document.getElementById('inventoryBody');
    tbody.innerHTML = rows.map(r => `<tr>
        <td>${r.id}</td>
        <td style="font-family:var(--font-mono);color:var(--accent-cyan)">${r.serial}</td>
        <td>${r.modelName}</td>
        <td>${r.typeName}</td>
        <td>${statusBadge(r.status)}</td>
        <td>${r.unitName}</td>
        <td style="font-family:var(--font-mono)">${r.rounds.toLocaleString()}</td>
        <td>${reliabilityBar(r.rel)}</td>
    </tr>`).join('');

    document.getElementById('rowCount').textContent = rows.length;
}

function statusBadge(s) {
    const cls = {
        'Active':'badge-active','In Maintenance':'badge-maintenance',
        'In Storage':'badge-storage','In Transit':'badge-transit',
        'Decommissioned':'badge-decommissioned'
    }[s] || '';
    return `<span class="badge ${cls}">${s}</span>`;
}

function reliabilityBar(val) {
    let color = '#10b981';
    if (val < 70) color = '#ef4444';
    else if (val < 85) color = '#f59e0b';
    else if (val < 95) color = '#3b82f6';
    return `<div class="reliability-bar">
        <div class="reliability-track"><div class="reliability-fill" style="width:${val}%;background:${color}"></div></div>
        <span class="reliability-val" style="color:${color}">${val}%</span>
    </div>`;
}

// ---- SQL/PL-SQL Showcase ----
function initShowcase() {
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
            btn.classList.add('active');
            document.getElementById('tab-' + btn.dataset.tab).classList.add('active');
        });
    });

    populateShowcase('queriesGrid', showcaseData.queries, 'icon-query', '📊');
    populateShowcase('proceduresGrid', showcaseData.procedures, 'icon-proc', '⚙️');
    populateShowcase('functionsGrid', showcaseData.functions, 'icon-func', '🔣');
    populateShowcase('triggersGrid', showcaseData.triggers, 'icon-trigger', '⚡');
    populateShowcase('cursorsGrid', showcaseData.cursors, 'icon-cursor', '🔄');
    populateShowcase('transactionsGrid', showcaseData.transactions, 'icon-txn', '🔒');
}

function populateShowcase(gridId, items, iconClass, emoji) {
    const grid = document.getElementById(gridId);
    grid.innerHTML = items.map(item => `
        <div class="showcase-card">
            <div class="showcase-card-header">
                <div class="showcase-card-icon ${iconClass}">${emoji}</div>
                <div>
                    <div class="showcase-card-title">${item.title}</div>
                    <div class="showcase-card-desc">${item.desc}</div>
                </div>
            </div>
            <div class="showcase-card-body">
                <pre><code class="language-sql">${escapeHtml(item.code)}</code></pre>
            </div>
        </div>
    `).join('');
    Prism.highlightAllUnder(grid);
}

function escapeHtml(s) {
    return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

// ---- Showcase Data ----
const showcaseData = {
queries: [
{title:'Multi-Table JOIN — Full Inventory',desc:'Weapon details with model, manufacturer, and unit',code:
`SELECT w.weapon_id, w.serial_number, wm.model_name,
       wm.weapon_type, m.company_name AS manufacturer,
       w.current_status, u.unit_name,
       w.total_rounds_fired, w.reliability_score
FROM WEAPON w
JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
JOIN MANUFACTURER m  ON wm.manufacturer_id = m.manufacturer_id
JOIN UNIT u          ON w.current_location_id = u.unit_id
ORDER BY w.weapon_id;`},
{title:'Correlated Subquery — Overdue Maintenance',desc:'Finds active weapons past their service date',code:
`SELECT w.weapon_id, w.serial_number, wm.model_name
FROM WEAPON w
JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
WHERE w.current_status = 'Active'
  AND EXISTS (
      SELECT 1 FROM MAINTENANCE_RECORD mr
      WHERE mr.weapon_id = w.weapon_id
        AND mr.next_service_due < SYSDATE
        AND mr.completed_date IS NOT NULL
  );`},
{title:'Aggregate + HAVING — Low Reliability Models',desc:'Models with average reliability below 90%',code:
`SELECT wm.model_name, wm.weapon_type,
       COUNT(*) AS weapon_count,
       ROUND(AVG(w.reliability_score), 2) AS avg_reliability
FROM WEAPON w
JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
GROUP BY wm.model_name, wm.weapon_type
HAVING AVG(w.reliability_score) < 90
ORDER BY avg_reliability ASC;`},
{title:'CASE Expression — Readiness Classification',desc:'Classifies weapons into readiness categories',code:
`SELECT w.serial_number, wm.model_name,
       w.reliability_score,
       CASE
         WHEN w.current_status = 'Decommissioned' THEN 'RETIRED'
         WHEN w.reliability_score >= 95 THEN 'COMBAT READY'
         WHEN w.reliability_score >= 85 THEN 'FIELD READY'
         WHEN w.reliability_score >= 70 THEN 'LIMITED DUTY'
         ELSE 'NEEDS OVERHAUL'
       END AS readiness_class
FROM WEAPON w
JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id;`},
{title:'NOT EXISTS — Models Without Compatible Ammo',desc:'Finds weapon models lacking ammo compatibility records',code:
`SELECT wm.model_id, wm.model_name, wm.caliber
FROM WEAPON_MODEL wm
WHERE NOT EXISTS (
    SELECT 1 FROM AMMO_COMPATIBILITY ac
    WHERE ac.model_id = wm.model_id
)
ORDER BY wm.model_name;`},
{title:'UNION — Officers and Technicians',desc:'Combined list of commanding officers and maintenance staff',code:
`SELECT c.full_name, c.rank, 'Commander' AS role
FROM CUSTODIAN c
JOIN UNIT u ON u.commanding_officer_id = c.custodian_id
UNION
SELECT DISTINCT c.full_name, c.rank, 'Technician'
FROM CUSTODIAN c
JOIN MAINTENANCE_RECORD mr ON mr.technician_id = c.custodian_id
ORDER BY role, full_name;`}
],

procedures: [
{title:'TRANSFER_CUSTODY',desc:'Atomic custody transfer with validation, SAVEPOINT & ROLLBACK',code:
`CREATE OR REPLACE PROCEDURE TRANSFER_CUSTODY (
    p_weapon_id IN NUMBER, p_new_custodian IN NUMBER,
    p_new_unit IN NUMBER, p_authorized_by IN NUMBER
) AS
    v_weapon_status WEAPON.current_status%TYPE;
    v_auth_clearance CUSTODIAN.clearance_level%TYPE;
BEGIN
    SAVEPOINT before_transfer;

    SELECT current_status INTO v_weapon_status
    FROM WEAPON WHERE weapon_id = p_weapon_id;

    IF v_weapon_status IN ('Decommissioned','In Maintenance') THEN
        RAISE_APPLICATION_ERROR(-20002,
            'Cannot transfer: status ' || v_weapon_status);
    END IF;

    SELECT clearance_level INTO v_auth_clearance
    FROM CUSTODIAN WHERE custodian_id = p_authorized_by;

    IF v_auth_clearance < 4 THEN
        RAISE_APPLICATION_ERROR(-20006, 'Insufficient clearance');
    END IF;

    INSERT INTO CUSTODY_HISTORY VALUES (
        custody_seq.NEXTVAL, p_weapon_id,
        p_new_custodian, p_new_unit, SYSDATE,
        p_authorized_by, 'Standard transfer');

    UPDATE WEAPON SET current_location_id = p_new_unit,
        current_status = 'Active'
    WHERE weapon_id = p_weapon_id;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO before_transfer;
        RAISE;
END;`},
{title:'DECOMMISSION_WEAPON',desc:'Marks weapon decommissioned and transfers to central depot',code:
`CREATE OR REPLACE PROCEDURE DECOMMISSION_WEAPON (
    p_weapon_id IN NUMBER, p_authorized_by IN NUMBER,
    p_reason IN VARCHAR2
) AS
    v_depot_cust CUSTODIAN.custodian_id%TYPE;
BEGIN
    SAVEPOINT before_decommission;

    SELECT commanding_officer_id INTO v_depot_cust
    FROM UNIT WHERE unit_id = 11; -- Central Depot

    INSERT INTO CUSTODY_HISTORY VALUES (
        custody_seq.NEXTVAL, p_weapon_id, v_depot_cust,
        11, SYSDATE, p_authorized_by,
        'DECOMMISSIONED: ' || p_reason);

    UPDATE WEAPON SET current_status = 'Decommissioned',
        current_location_id = 11
    WHERE weapon_id = p_weapon_id;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO before_decommission;
        RAISE;
END;`},
{title:'BULK_TRANSFER_UNIT',desc:'Transfers ALL active weapons between units using cursor',code:
`CREATE OR REPLACE PROCEDURE BULK_TRANSFER_UNIT (
    p_from_unit IN NUMBER, p_to_unit IN NUMBER,
    p_authorized_by IN NUMBER
) AS
    CURSOR c_weapons IS
        SELECT weapon_id FROM WEAPON
        WHERE current_location_id = p_from_unit
          AND current_status = 'Active';
    v_count NUMBER := 0;
    v_to_cust CUSTODIAN.custodian_id%TYPE;
BEGIN
    SELECT commanding_officer_id INTO v_to_cust
    FROM UNIT WHERE unit_id = p_to_unit;

    FOR rec IN c_weapons LOOP
        INSERT INTO CUSTODY_HISTORY VALUES (
            custody_seq.NEXTVAL, rec.weapon_id,
            v_to_cust, p_to_unit, SYSDATE,
            p_authorized_by, 'Bulk transfer');
        UPDATE WEAPON SET current_location_id = p_to_unit
        WHERE weapon_id = rec.weapon_id;
        v_count := v_count + 1;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE(v_count || ' weapons transferred');
END;`}
],

functions: [
{title:'CALC_RELIABILITY_SCORE',desc:'Computes reliability based on rounds, age, and maintenance',code:
`CREATE OR REPLACE FUNCTION CALC_RELIABILITY_SCORE (
    p_weapon_id IN NUMBER
) RETURN NUMBER AS
    v_rounds NUMBER; v_mfg_date DATE;
    v_age NUMBER; v_maint NUMBER; v_overdue NUMBER;
    v_score NUMBER := 100;
BEGIN
    SELECT total_rounds_fired, manufacture_date
    INTO v_rounds, v_mfg_date
    FROM WEAPON WHERE weapon_id = p_weapon_id;

    v_age := MONTHS_BETWEEN(SYSDATE, v_mfg_date) / 12;

    SELECT COUNT(*) INTO v_maint FROM MAINTENANCE_RECORD
    WHERE weapon_id = p_weapon_id AND completed_date IS NOT NULL;

    SELECT COUNT(*) INTO v_overdue FROM MAINTENANCE_RECORD
    WHERE weapon_id = p_weapon_id
      AND completed_date IS NULL AND scheduled_date < SYSDATE;

    v_score := v_score - FLOOR(v_rounds / 5000)
               - (v_age * 0.5) - (v_overdue * 5)
               + LEAST(v_maint, 10);

    RETURN GREATEST(LEAST(ROUND(v_score, 2), 100), 0);
END;`},
{title:'CHECK_AMMO_COMPATIBILITY',desc:'Validates ammo-model compatibility with expiry check',code:
`CREATE OR REPLACE FUNCTION CHECK_AMMO_COMPATIBILITY (
    p_model_id IN NUMBER, p_ammo_id IN NUMBER
) RETURN VARCHAR2 AS
    v_rating NUMBER; v_expiry DATE;
    v_ammo AMMUNITION_TYPE.ammo_name%TYPE;
BEGIN
    SELECT ammo_name, expiry_date INTO v_ammo, v_expiry
    FROM AMMUNITION_TYPE WHERE ammo_id = p_ammo_id;

    IF v_expiry < SYSDATE THEN
        RETURN 'EXPIRED: ' || v_ammo;
    END IF;

    SELECT effectiveness_rating INTO v_rating
    FROM AMMO_COMPATIBILITY
    WHERE model_id = p_model_id AND ammo_id = p_ammo_id;

    RETURN 'COMPATIBLE (Rating: ' || v_rating || '/10)';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'INCOMPATIBLE';
END;`}
],

triggers: [
{title:'TRG_AUDIT_WEAPON',desc:'Logs all weapon table changes to AUDIT_LOG automatically',code:
`CREATE OR REPLACE TRIGGER TRG_AUDIT_WEAPON
AFTER INSERT OR UPDATE OR DELETE ON WEAPON
FOR EACH ROW
DECLARE
    v_log_id NUMBER; v_op VARCHAR2(10);
BEGIN
    SELECT audit_log_seq.NEXTVAL INTO v_log_id FROM DUAL;

    IF INSERTING THEN v_op := 'INSERT';
    ELSIF UPDATING THEN v_op := 'UPDATE';
    ELSE v_op := 'DELETE'; END IF;

    INSERT INTO AUDIT_LOG (log_id, table_name, operation_type,
        record_id, old_values, new_values, changed_by)
    VALUES (v_log_id, 'WEAPON', v_op,
        NVL(:NEW.weapon_id, :OLD.weapon_id),
        CASE WHEN UPDATING OR DELETING THEN
            'Status=' || :OLD.current_status END,
        CASE WHEN INSERTING OR UPDATING THEN
            'Status=' || :NEW.current_status END,
        USER);
END;`},
{title:'TRG_UPDATE_RELIABILITY',desc:'Auto-recalculates reliability when rounds fired changes',code:
`CREATE OR REPLACE TRIGGER TRG_UPDATE_RELIABILITY
BEFORE UPDATE OF total_rounds_fired ON WEAPON
FOR EACH ROW
DECLARE
    v_score NUMBER; v_age NUMBER;
    v_maint NUMBER; v_overdue NUMBER;
BEGIN
    IF :OLD.total_rounds_fired != :NEW.total_rounds_fired THEN
        v_age := MONTHS_BETWEEN(SYSDATE, :NEW.manufacture_date)/12;

        SELECT COUNT(*) INTO v_maint FROM MAINTENANCE_RECORD
        WHERE weapon_id = :NEW.weapon_id
          AND completed_date IS NOT NULL;

        v_score := 100 - FLOOR(:NEW.total_rounds_fired / 5000)
                   - (v_age * 0.5) + LEAST(v_maint, 10);

        :NEW.reliability_score := GREATEST(LEAST(v_score,100),0);
    END IF;
END;`},
{title:'TRG_WEAPON_STATUS_GUARD',desc:'Prevents reactivation of decommissioned weapons',code:
`CREATE OR REPLACE TRIGGER TRG_WEAPON_STATUS_GUARD
BEFORE UPDATE OF current_status ON WEAPON
FOR EACH ROW
BEGIN
    IF :OLD.current_status = 'Decommissioned'
       AND :NEW.current_status != 'Decommissioned' THEN
        RAISE_APPLICATION_ERROR(-20060,
            'Cannot reactivate decommissioned weapon '
            || :OLD.serial_number);
    END IF;
END;`}
],

cursors: [
{title:'Explicit Cursor — Overdue Maintenance Report',desc:'Iterates overdue records with OPEN/FETCH/CLOSE',code:
`DECLARE
    CURSOR c_overdue IS
        SELECT w.serial_number, wm.model_name,
               mr.maintenance_type, mr.scheduled_date,
               TRUNC(SYSDATE - mr.scheduled_date) AS days_overdue
        FROM MAINTENANCE_RECORD mr
        JOIN WEAPON w ON mr.weapon_id = w.weapon_id
        JOIN WEAPON_MODEL wm ON w.model_id = wm.model_id
        WHERE mr.completed_date IS NULL
          AND mr.scheduled_date < SYSDATE;
    v_rec c_overdue%ROWTYPE;
BEGIN
    OPEN c_overdue;
    LOOP
        FETCH c_overdue INTO v_rec;
        EXIT WHEN c_overdue%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(v_rec.serial_number
            || ' — ' || v_rec.days_overdue || ' days overdue');
    END LOOP;
    CLOSE c_overdue;
END;`},
{title:'Cursor FOR UPDATE — Batch Reliability Update',desc:'Locks rows and recalculates all reliability scores',code:
`DECLARE
    CURSOR c_update IS
        SELECT weapon_id, total_rounds_fired, manufacture_date
        FROM WEAPON WHERE current_status = 'Active'
        FOR UPDATE OF reliability_score;
    v_score NUMBER; v_age NUMBER;
BEGIN
    FOR rec IN c_update LOOP
        v_age := MONTHS_BETWEEN(SYSDATE, rec.manufacture_date)/12;
        v_score := 100 - FLOOR(rec.total_rounds_fired/5000)
                   - (v_age * 0.5);
        UPDATE WEAPON SET reliability_score = ROUND(v_score,2)
        WHERE CURRENT OF c_update;
    END LOOP;
    COMMIT;
END;`},
{title:'BULK COLLECT — Expired Ammo Report',desc:'Processes ammunition records in bulk using collections',code:
`DECLARE
    TYPE ammo_tab IS TABLE OF AMMUNITION_TYPE%ROWTYPE;
    v_list ammo_tab;
BEGIN
    SELECT * BULK COLLECT INTO v_list
    FROM AMMUNITION_TYPE
    WHERE expiry_date < ADD_MONTHS(SYSDATE, 12)
    ORDER BY expiry_date;

    FOR i IN 1..v_list.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(v_list(i).ammo_name
            || ' — Expires: '
            || TO_CHAR(v_list(i).expiry_date, 'YYYY-MM-DD')
            || ' — Stock: ' || v_list(i).stock_quantity);
    END LOOP;
END;`}
],

transactions: [
{title:'SAVEPOINT + Partial ROLLBACK',desc:'Multi-step operation with partial rollback on failure',code:
`DECLARE
    v_maint_id NUMBER;
BEGIN
    -- Step 1: Schedule maintenance
    SAVEPOINT step1_maintenance;
    INSERT INTO MAINTENANCE_RECORD VALUES (
        maintenance_seq.NEXTVAL, 2, DATE '2026-07-01',
        NULL, 3, 'Preventive', 'Gas check', DATE '2027-01-01');
    DBMS_OUTPUT.PUT_LINE('Step 1: OK');

    -- Step 2: Update weapon
    SAVEPOINT step2_status;
    UPDATE WEAPON SET current_status = 'Active' WHERE weapon_id = 2;
    DBMS_OUTPUT.PUT_LINE('Step 2: OK');

    -- Step 3: Fails (CHECK constraint violation)
    SAVEPOINT step3_invalid;
    BEGIN
        UPDATE WEAPON SET total_rounds_fired = -100 WHERE weapon_id = 2;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO step2_status;  -- Only step 3 rolled back
            DBMS_OUTPUT.PUT_LINE('Step 3: ROLLED BACK');
    END;

    COMMIT;  -- Steps 1 & 2 persisted
END;`},
{title:'SELECT ... FOR UPDATE — Row Locking',desc:'Locks weapon row during transfer to prevent concurrent access',code:
`DECLARE
    v_status WEAPON.current_status%TYPE;
BEGIN
    -- Lock the row — other sessions must wait
    SELECT current_status INTO v_status
    FROM WEAPON WHERE weapon_id = 5
    FOR UPDATE;

    IF v_status = 'Active' THEN
        INSERT INTO CUSTODY_HISTORY VALUES (
            custody_seq.NEXTVAL, 5, 6, 2,
            SYSDATE, 4, 'Concurrent-safe transfer');
        DBMS_OUTPUT.PUT_LINE('Transfer complete');
    END IF;

    COMMIT;  -- Lock released
END;`}
]
};

// ---- Scroll Animations ----
function initScrollAnimations() {
    const els = document.querySelectorAll('.glass-card, .schema-card, .chart-card, .showcase-card');
    els.forEach(el => el.classList.add('animate-on-scroll'));

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(e => {
            if (e.isIntersecting) {
                e.target.classList.add('visible');
                observer.unobserve(e.target);
            }
        });
    }, { threshold: 0.1 });

    els.forEach(el => observer.observe(el));
}
