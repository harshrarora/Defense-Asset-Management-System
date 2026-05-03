// ============================================================
// CHARTS.JS — Analytics Dashboard (Chart.js)
// Uses actual data from data.js
// ============================================================

document.addEventListener('DOMContentLoaded', () => {
    Chart.defaults.color = '#94a3b8';
    Chart.defaults.borderColor = 'rgba(59,130,246,0.08)';
    Chart.defaults.font.family = "'Inter', sans-serif";

    createStatusChart();
    createUnitsChart();
    createReliabilityChart();
    createAmmoChart();
});

// ---- Chart 1: Weapons by Status (Doughnut) ----
function createStatusChart() {
    const counts = {};
    DATA.weapons.forEach(w => { counts[w.status] = (counts[w.status] || 0) + 1; });

    const labels = Object.keys(counts);
    const data = Object.values(counts);
    const colors = {
        'Active':'#10b981','In Maintenance':'#f59e0b','In Storage':'#8b5cf6',
        'In Transit':'#06b6d4','Decommissioned':'#ef4444'
    };

    new Chart(document.getElementById('chartStatus'), {
        type: 'doughnut',
        data: {
            labels,
            datasets: [{
                data,
                backgroundColor: labels.map(l => colors[l] || '#64748b'),
                borderColor: 'rgba(6,10,19,0.8)',
                borderWidth: 2,
                hoverOffset: 8
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            cutout: '65%',
            plugins: {
                legend: { position: 'bottom', labels: { padding: 16, usePointStyle: true, pointStyle: 'circle' } }
            }
        }
    });
}

// ---- Chart 2: Weapons per Unit (Bar) ----
function createUnitsChart() {
    const counts = {};
    DATA.weapons.forEach(w => {
        const name = getUnitName(w.unit);
        counts[name] = (counts[name] || 0) + 1;
    });

    // Sort by count descending
    const sorted = Object.entries(counts).sort((a,b) => b[1] - a[1]);
    const labels = sorted.map(e => e[0].replace(/^(\d+\w+\s)/, '').substring(0, 20));
    const data = sorted.map(e => e[1]);

    new Chart(document.getElementById('chartUnits'), {
        type: 'bar',
        data: {
            labels,
            datasets: [{
                label: 'Weapons',
                data,
                backgroundColor: 'rgba(59,130,246,0.6)',
                borderColor: '#3b82f6',
                borderWidth: 1,
                borderRadius: 4,
                barPercentage: 0.7
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            indexAxis: 'y',
            plugins: { legend: { display: false } },
            scales: {
                x: { grid: { color: 'rgba(59,130,246,0.06)' }, ticks: { stepSize: 1 } },
                y: { grid: { display: false }, ticks: { font: { size: 11 } } }
            }
        }
    });
}

// ---- Chart 3: Avg Reliability by Weapon Type (Bar) ----
function createReliabilityChart() {
    const typeData = {};
    DATA.weapons.forEach(w => {
        const t = getModelType(w.model);
        if (!typeData[t]) typeData[t] = { sum: 0, count: 0 };
        typeData[t].sum += w.rel;
        typeData[t].count++;
    });

    const entries = Object.entries(typeData).map(([k,v]) => [k, +(v.sum/v.count).toFixed(1)]);
    entries.sort((a,b) => b[1] - a[1]);

    const labels = entries.map(e => e[0]);
    const data = entries.map(e => e[1]);

    const colors = data.map(v => {
        if (v >= 95) return '#10b981';
        if (v >= 85) return '#3b82f6';
        if (v >= 70) return '#f59e0b';
        return '#ef4444';
    });

    new Chart(document.getElementById('chartReliability'), {
        type: 'bar',
        data: {
            labels,
            datasets: [{
                label: 'Avg Reliability %',
                data,
                backgroundColor: colors.map(c => c + '99'),
                borderColor: colors,
                borderWidth: 1,
                borderRadius: 4,
                barPercentage: 0.6
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: {
                y: { min: 60, max: 100, grid: { color: 'rgba(59,130,246,0.06)' },
                     ticks: { callback: v => v + '%' } },
                x: { grid: { display: false } }
            }
        }
    });
}

// ---- Chart 4: Ammunition Stock Levels (Bar) ----
function createAmmoChart() {
    const labels = DATA.ammo.map(a => a.name);
    const stock = DATA.ammo.map(a => a.stock);

    const now = new Date();
    const colors = DATA.ammo.map(a => {
        const exp = new Date(a.expiry);
        const months = (exp - now) / (1000*60*60*24*30);
        if (months < 0) return '#ef4444';
        if (months < 12) return '#f59e0b';
        return '#10b981';
    });

    new Chart(document.getElementById('chartAmmo'), {
        type: 'bar',
        data: {
            labels,
            datasets: [{
                label: 'Stock Quantity',
                data: stock,
                backgroundColor: colors.map(c => c + '88'),
                borderColor: colors,
                borderWidth: 1,
                borderRadius: 4,
                barPercentage: 0.7
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: {
                    callbacks: {
                        afterLabel: (ctx) => {
                            const a = DATA.ammo[ctx.dataIndex];
                            return 'Caliber: ' + a.caliber + '\nExpiry: ' + a.expiry;
                        }
                    }
                }
            },
            scales: {
                y: { grid: { color: 'rgba(59,130,246,0.06)' },
                     ticks: { callback: v => (v/1000) + 'K' } },
                x: { grid: { display: false }, ticks: { maxRotation: 45, font: { size: 10 } } }
            }
        }
    });
}
