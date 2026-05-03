// ============================================================
// DATA.JS — All 257 rows from the database as JS arrays
// ============================================================

const DATA = {
manufacturers: [
{id:1,name:'Lockheed Martin',country:'USA',status:'Certified'},
{id:2,name:'BAE Systems',country:'United Kingdom',status:'Certified'},
{id:3,name:'Rheinmetall AG',country:'Germany',status:'Certified'},
{id:4,name:'Thales Group',country:'France',status:'Certified'},
{id:5,name:'General Dynamics',country:'USA',status:'Certified'},
{id:6,name:'Heckler and Koch',country:'Germany',status:'Certified'},
{id:7,name:'FN Herstal',country:'Belgium',status:'Certified'},
{id:8,name:'Beretta',country:'Italy',status:'Certified'},
{id:9,name:'SIG Sauer',country:'USA',status:'Certified'},
{id:10,name:'Kalashnikov Concern',country:'Russia',status:'Suspended'}
],

models: [
{id:1,mfr:6,name:'HK416',type:'Assault Rifle',caliber:'5.56x45mm NATO'},
{id:2,mfr:5,name:'M4A1 Carbine',type:'Assault Rifle',caliber:'5.56x45mm NATO'},
{id:3,mfr:10,name:'AK-103',type:'Assault Rifle',caliber:'7.62x39mm'},
{id:4,mfr:7,name:'FN SCAR-H',type:'Battle Rifle',caliber:'7.62x51mm NATO'},
{id:5,mfr:7,name:'M249 SAW',type:'LMG',caliber:'5.56x45mm NATO'},
{id:6,mfr:7,name:'M240B',type:'GPMG',caliber:'7.62x51mm NATO'},
{id:7,mfr:1,name:'Barrett M82',type:'Sniper Rifle',caliber:'12.7x99mm NATO'},
{id:8,mfr:3,name:'M24 SWS',type:'Sniper Rifle',caliber:'7.62x51mm NATO'},
{id:9,mfr:8,name:'Beretta M9',type:'Pistol',caliber:'9x19mm Parabellum'},
{id:10,mfr:9,name:'SIG P320',type:'Pistol',caliber:'9x19mm Parabellum'},
{id:11,mfr:9,name:'SIG P226',type:'Pistol',caliber:'9x19mm Parabellum'},
{id:12,mfr:6,name:'MP5A3',type:'SMG',caliber:'9x19mm Parabellum'},
{id:13,mfr:6,name:'HK MP7',type:'SMG',caliber:'4.6x30mm'},
{id:14,mfr:7,name:'FN P90',type:'SMG',caliber:'5.7x28mm'},
{id:15,mfr:8,name:'Benelli M4',type:'Shotgun',caliber:'12 Gauge'},
{id:16,mfr:5,name:'Mossberg 590A1',type:'Shotgun',caliber:'12 Gauge'},
{id:17,mfr:2,name:'L85A2',type:'Assault Rifle',caliber:'5.56x45mm NATO'},
{id:18,mfr:4,name:'FAMAS G2',type:'Assault Rifle',caliber:'5.56x45mm NATO'},
{id:19,mfr:3,name:'MG3',type:'GPMG',caliber:'7.62x51mm NATO'},
{id:20,mfr:6,name:'HK G36',type:'Assault Rifle',caliber:'5.56x45mm NATO'}
],

units: [
{id:1,name:'1st Infantry Battalion',location:'Fort Bragg'},
{id:2,name:'2nd Armored Regiment',location:'Fort Knox'},
{id:3,name:'3rd Special Forces Group',location:'Camp Mackall'},
{id:4,name:'4th Artillery Brigade',location:'Fort Sill'},
{id:5,name:'5th Logistics Support Unit',location:'Fort Lee'},
{id:6,name:'6th Reconnaissance Squadron',location:'Fort Huachuca'},
{id:7,name:'7th Marine Battalion',location:'Camp Pendleton'},
{id:8,name:'8th Airborne Division',location:'Fort Campbell'},
{id:9,name:'9th Engineering Corps',location:'Fort Leonard Wood'},
{id:10,name:'10th Signal Regiment',location:'Fort Gordon'},
{id:11,name:'Central Armory Depot',location:'Aberdeen PG'},
{id:12,name:'Weapons Training Academy',location:'Fort Benning'}
],

weapons: [
{id:1,model:1,serial:'HK-2022-0001',status:'Active',unit:1,rounds:15000,rel:92.5},
{id:2,model:1,serial:'HK-2022-0002',status:'Active',unit:1,rounds:12000,rel:94.0},
{id:3,model:2,serial:'GD-2021-0001',status:'Active',unit:1,rounds:22000,rel:88.0},
{id:4,model:2,serial:'GD-2021-0002',status:'In Maintenance',unit:4,rounds:25000,rel:82.0},
{id:5,model:2,serial:'GD-2022-0003',status:'Active',unit:2,rounds:18000,rel:90.5},
{id:6,model:3,serial:'KC-2020-0001',status:'Active',unit:3,rounds:30000,rel:85.0},
{id:7,model:3,serial:'KC-2020-0002',status:'Decommissioned',unit:11,rounds:45000,rel:60.0},
{id:8,model:4,serial:'FN-2023-0001',status:'Active',unit:3,rounds:8000,rel:96.0},
{id:9,model:4,serial:'FN-2023-0002',status:'Active',unit:7,rounds:7500,rel:96.5},
{id:10,model:5,serial:'FN-2021-0003',status:'Active',unit:1,rounds:35000,rel:87.0},
{id:11,model:5,serial:'FN-2022-0004',status:'Active',unit:2,rounds:28000,rel:89.0},
{id:12,model:6,serial:'FN-2020-0005',status:'In Maintenance',unit:4,rounds:40000,rel:78.0},
{id:13,model:6,serial:'FN-2021-0006',status:'Active',unit:7,rounds:32000,rel:84.0},
{id:14,model:7,serial:'LM-2023-0001',status:'Active',unit:3,rounds:2000,rel:98.0},
{id:15,model:7,serial:'LM-2022-0002',status:'Active',unit:6,rounds:3500,rel:97.0},
{id:16,model:8,serial:'RM-2021-0001',status:'Active',unit:6,rounds:5000,rel:95.0},
{id:17,model:8,serial:'RM-2022-0002',status:'Active',unit:8,rounds:4200,rel:95.5},
{id:18,model:9,serial:'BR-2022-0001',status:'Active',unit:1,rounds:10000,rel:91.0},
{id:19,model:9,serial:'BR-2022-0002',status:'Active',unit:2,rounds:11000,rel:90.0},
{id:20,model:9,serial:'BR-2023-0003',status:'Active',unit:3,rounds:6000,rel:94.0},
{id:21,model:10,serial:'SG-2023-0001',status:'Active',unit:7,rounds:5500,rel:95.0},
{id:22,model:10,serial:'SG-2023-0002',status:'Active',unit:8,rounds:4800,rel:95.5},
{id:23,model:11,serial:'SG-2022-0003',status:'Active',unit:4,rounds:9000,rel:92.0},
{id:24,model:11,serial:'SG-2023-0004',status:'In Storage',unit:5,rounds:0,rel:100.0},
{id:25,model:12,serial:'HK-2021-0003',status:'Active',unit:3,rounds:14000,rel:93.0},
{id:26,model:12,serial:'HK-2022-0004',status:'Active',unit:6,rounds:11000,rel:94.0},
{id:27,model:13,serial:'HK-2023-0005',status:'Active',unit:3,rounds:6500,rel:96.0},
{id:28,model:13,serial:'HK-2023-0006',status:'Active',unit:8,rounds:5800,rel:96.5},
{id:29,model:14,serial:'FN-2022-0007',status:'Active',unit:6,rounds:9500,rel:93.0},
{id:30,model:14,serial:'FN-2023-0008',status:'In Transit',unit:5,rounds:3000,rel:97.0},
{id:31,model:15,serial:'BR-2023-0004',status:'Active',unit:7,rounds:4000,rel:97.0},
{id:32,model:15,serial:'BR-2022-0005',status:'Active',unit:1,rounds:7000,rel:94.5},
{id:33,model:16,serial:'GD-2021-0004',status:'Active',unit:8,rounds:8500,rel:93.0},
{id:34,model:16,serial:'GD-2022-0005',status:'Decommissioned',unit:11,rounds:20000,rel:65.0},
{id:35,model:17,serial:'BA-2022-0001',status:'Active',unit:2,rounds:16000,rel:89.5},
{id:36,model:17,serial:'BA-2023-0002',status:'Active',unit:9,rounds:10000,rel:92.0},
{id:37,model:18,serial:'TH-2021-0001',status:'In Maintenance',unit:4,rounds:19000,rel:84.0},
{id:38,model:18,serial:'TH-2022-0002',status:'Active',unit:10,rounds:12000,rel:91.0},
{id:39,model:19,serial:'RM-2020-0003',status:'Active',unit:2,rounds:38000,rel:80.0},
{id:40,model:19,serial:'RM-2021-0004',status:'Active',unit:4,rounds:29000,rel:85.5},
{id:41,model:20,serial:'HK-2023-0007',status:'Active',unit:9,rounds:7000,rel:95.0},
{id:42,model:20,serial:'HK-2024-0008',status:'Active',unit:10,rounds:3000,rel:98.0},
{id:43,model:1,serial:'HK-2023-0009',status:'Active',unit:7,rounds:9000,rel:94.5},
{id:44,model:2,serial:'GD-2023-0006',status:'Active',unit:8,rounds:11000,rel:91.0},
{id:45,model:5,serial:'FN-2023-0009',status:'In Storage',unit:11,rounds:0,rel:100.0},
{id:46,model:9,serial:'BR-2024-0006',status:'Active',unit:12,rounds:3500,rel:97.0},
{id:47,model:10,serial:'SG-2024-0003',status:'Active',unit:12,rounds:2000,rel:98.5},
{id:48,model:12,serial:'HK-2024-0010',status:'Active',unit:12,rounds:4000,rel:96.0},
{id:49,model:4,serial:'FN-2024-0010',status:'Active',unit:8,rounds:1500,rel:99.0},
{id:50,model:6,serial:'FN-2024-0011',status:'In Storage',unit:11,rounds:0,rel:100.0}
],

ammo: [
{id:1,caliber:'5.56x45mm NATO',name:'M855A1 EPR',mfr:5,stock:250000,expiry:'2028-06-30'},
{id:2,caliber:'5.56x45mm NATO',name:'M193 Ball',mfr:1,stock:180000,expiry:'2027-12-31'},
{id:3,caliber:'7.62x51mm NATO',name:'M80A1 EPR',mfr:5,stock:120000,expiry:'2028-03-15'},
{id:4,caliber:'7.62x51mm NATO',name:'M118LR Match',mfr:1,stock:45000,expiry:'2027-09-30'},
{id:5,caliber:'7.62x39mm',name:'M43 Ball',mfr:10,stock:80000,expiry:'2026-12-31'},
{id:6,caliber:'9x19mm Parabellum',name:'M882 FMJ',mfr:9,stock:300000,expiry:'2028-08-15'},
{id:7,caliber:'9x19mm Parabellum',name:'M1152 FMJ',mfr:7,stock:200000,expiry:'2029-01-31'},
{id:8,caliber:'12.7x99mm NATO',name:'M33 Ball',mfr:5,stock:25000,expiry:'2029-06-30'},
{id:9,caliber:'12.7x99mm NATO',name:'Mk 211 Raufoss',mfr:3,stock:8000,expiry:'2028-12-31'},
{id:10,caliber:'4.6x30mm',name:'DM11 FMJ',mfr:6,stock:60000,expiry:'2028-04-30'},
{id:11,caliber:'5.7x28mm',name:'SS190 AP',mfr:7,stock:55000,expiry:'2027-11-30'},
{id:12,caliber:'12 Gauge',name:'00 Buckshot',mfr:5,stock:40000,expiry:'2029-03-31'},
{id:13,caliber:'12 Gauge',name:'Rifled Slug',mfr:5,stock:20000,expiry:'2028-09-30'},
{id:14,caliber:'5.56x45mm NATO',name:'Mk 262 Mod 1',mfr:2,stock:35000,expiry:'2028-01-15'},
{id:15,caliber:'7.62x51mm NATO',name:'M62 Tracer',mfr:1,stock:60000,expiry:'2027-06-30'}
]
};

// Helper: get model name by id
function getModelName(id) {
    const m = DATA.models.find(x => x.id === id);
    return m ? m.name : 'Unknown';
}
function getModelType(id) {
    const m = DATA.models.find(x => x.id === id);
    return m ? m.type : 'Unknown';
}
function getUnitName(id) {
    const u = DATA.units.find(x => x.id === id);
    return u ? u.name : 'Unknown';
}
function getMfrName(id) {
    const m = DATA.manufacturers.find(x => x.id === id);
    return m ? m.name : 'Unknown';
}
