// ============================================================
// ER_DIAGRAM.JS — Chen Notation Conceptual ER Diagram (SVG)
// ============================================================
document.addEventListener('DOMContentLoaded', () => { createChenDiagram('chenDiagramContainer'); });

function createChenDiagram(containerId) {
    const c = document.getElementById(containerId);
    if (!c) return;
    const ns = 'http://www.w3.org/2000/svg';
    const svg = document.createElementNS(ns, 'svg');
    svg.setAttribute('viewBox', '0 0 1520 1080');
    svg.setAttribute('width', '100%');
    svg.style.maxHeight = '720px';

    // --- Defs ---
    const defs = document.createElementNS(ns, 'defs');
    defs.innerHTML = `<style>
        .ent-rect{fill:#12203a;stroke:#3b82f6;stroke-width:1.8;rx:4}
        .ent-text{fill:#e2e8f0;font-family:'Inter',sans-serif;font-size:13px;font-weight:700;text-anchor:middle;dominant-baseline:central}
        .attr-oval{fill:#0a1628;stroke:#475569;stroke-width:1;rx:30;ry:14}
        .attr-pk{stroke:#3b82f6;stroke-width:1.5}
        .attr-text{fill:#94a3b8;font-family:'Inter',sans-serif;font-size:10px;text-anchor:middle;dominant-baseline:central}
        .attr-pk-text{fill:#60a5fa;text-decoration:underline}
        .rel-diamond{fill:#1a1630;stroke:#f59e0b;stroke-width:1.5}
        .rel-text{fill:#fbbf24;font-family:'Inter',sans-serif;font-size:10.5px;font-weight:600;text-anchor:middle;dominant-baseline:central}
        .conn-line{stroke:#334155;stroke-width:1.2;fill:none}
        .card-text{fill:#f59e0b;font-family:'Inter',sans-serif;font-size:10px;font-weight:700;text-anchor:middle;dominant-baseline:central}
    </style>`;
    svg.appendChild(defs);

    // Background
    const bg = el(ns,'rect',{x:0,y:0,width:1520,height:1080,fill:'#060a13',rx:12});
    svg.appendChild(bg);

    // --- Entities ---
    const ents = [
        {n:'MANUFACTURER',x:760,y:60,a:['manufacturer_id*','company_name','country','cert_status'],ap:[[760,15,'t'],[610,40,'l'],[910,40,'r'],[760,110,'b']]},
        {n:'WEAPON_MODEL',x:260,y:280,a:['model_id*','model_name','weapon_type','caliber'],ap:[[110,260,'l'],[110,300,'l'],[410,260,'r'],[410,300,'r']]},
        {n:'AMMUNITION_TYPE',x:1260,y:280,a:['ammo_id*','ammo_name','stock_quantity','expiry_date'],ap:[[1110,260,'l'],[1110,300,'l'],[1410,260,'r'],[1410,300,'r']]},
        {n:'WEAPON',x:260,y:530,a:['weapon_id*','serial_number','current_status','reliability_score','total_rounds_fired'],ap:[[260,480,'t'],[80,510,'l'],[80,550,'l'],[440,510,'r'],[440,550,'r']]},
        {n:'MAINTENANCE_RECORD',x:1060,y:530,a:['maintenance_id*','maint_type','scheduled_date','completed_date'],ap:[[1060,480,'t'],[880,530,'l'],[1240,510,'r'],[1240,550,'r']]},
        {n:'UNIT',x:100,y:820,a:['unit_id*','unit_name','base_location'],ap:[[100,770,'t'],[100,870,'b'],[250,820,'r']]},
        {n:'CUSTODIAN',x:460,y:820,a:['custodian_id*','full_name','rank','clearance_level'],ap:[[310,800,'l'],[310,840,'l'],[610,800,'r'],[610,840,'r']]},
        {n:'CUSTODY_HISTORY',x:760,y:740,a:['custody_id*','transfer_date','authorized_by'],ap:[[760,690,'t'],[920,720,'r'],[920,760,'r']]},
        {n:'AMMO_COMPATIBILITY',x:760,y:380,a:['compat_id*','effectiveness_rating'],ap:[[630,380,'l'],[910,380,'r']]},
        {n:'AUDIT_LOG',x:1260,y:820,a:['log_id*','table_name','operation_type','change_timestamp'],ap:[[1110,800,'l'],[1110,840,'l'],[1410,800,'r'],[1410,840,'r']]}
    ];

    // --- Relationships ---
    const rels = [
        {n:'Produces',x:460,y:170,from:[760,85],to:[260,255],cf:'1',ct:'N'},
        {n:'Supplies',x:1060,y:170,from:[760,85],to:[1260,255],cf:'1',ct:'N'},
        {n:'Has Instance',x:260,y:405,from:[260,305],to:[260,505],cf:'1',ct:'N'},
        {n:'Compatible',x:760,y:280,from:[360,280],to:[1160,280],cf:'M',ct:'N',via:[760,355]},
        {n:'Undergoes',x:660,y:530,from:[360,530],to:[960,530],cf:'1',ct:'N'},
        {n:'Located At',x:150,y:680,from:[230,555],to:[100,795],cf:'N',ct:'1'},
        {n:'Holds',x:500,y:640,from:[290,555],to:[460,795],cf:'N',ct:'M',via:[760,715]},
        {n:'Belongs To',x:280,y:900,from:[420,845],to:[140,845],cf:'N',ct:'1'}
    ];

    // Draw connections first (behind everything)
    rels.forEach(r => {
        drawLine(svg,ns,r.from[0],r.from[1],r.x,r.y);
        if (r.via) {
            drawLine(svg,ns,r.x,r.y,r.via[0],r.via[1]);
            drawLine(svg,ns,r.via[0],r.via[1],r.to[0],r.to[1]);
        } else {
            drawLine(svg,ns,r.x,r.y,r.to[0],r.to[1]);
        }
        // Cardinality labels
        const mx1=(r.from[0]+r.x)/2, my1=(r.from[1]+r.y)/2;
        const mx2=r.via?((r.via[0]+r.to[0])/2):((r.x+r.to[0])/2);
        const my2=r.via?((r.via[1]+r.to[1])/2):((r.y+r.to[1])/2);
        drawCard(svg,ns,mx1,my1,r.cf);
        drawCard(svg,ns,mx2,my2,r.ct);
    });

    // Draw attribute connections and ovals
    ents.forEach(e => {
        e.ap.forEach((p,i) => {
            drawLine(svg,ns,e.x,e.y,p[0],p[1]);
            const isPK = e.a[i].endsWith('*');
            const name = e.a[i].replace('*','');
            drawAttr(svg,ns,p[0],p[1],name,isPK);
        });
    });

    // Draw relationship diamonds
    rels.forEach(r => drawDiamond(svg,ns,r.x,r.y,r.n));

    // Draw entity rectangles
    ents.forEach(e => drawEntity(svg,ns,e.x,e.y,e.n));

    // Title
    const title = el(ns,'text',{x:760,y:1060,class:'ent-text',style:'font-size:11px;fill:#64748b;font-weight:400'});
    title.textContent = 'Conceptual ER Diagram — Chen Notation';
    svg.appendChild(title);

    c.appendChild(svg);
}

// --- Drawing Helpers ---
function el(ns,tag,attrs){const e=document.createElementNS(ns,tag);for(const[k,v]of Object.entries(attrs))e.setAttribute(k,v);return e;}

function drawEntity(svg,ns,x,y,name){
    const w=name.length*8.5+30, h=38;
    svg.appendChild(el(ns,'rect',{x:x-w/2,y:y-h/2,width:w,height:h,class:'ent-rect'}));
    const t=el(ns,'text',{x:x,y:y,class:'ent-text'});t.textContent=name;svg.appendChild(t);
}

function drawAttr(svg,ns,x,y,name,isPK){
    const w=Math.max(name.length*6.5+20,60), h=26;
    svg.appendChild(el(ns,'rect',{x:x-w/2,y:y-h/2,width:w,height:h,class:'attr-oval'+(isPK?' attr-pk':'')}));
    const t=el(ns,'text',{x:x,y:y,class:'attr-text'+(isPK?' attr-pk-text':'')});t.textContent=name;svg.appendChild(t);
}

function drawDiamond(svg,ns,cx,cy,name){
    const s=38;
    const pts=`${cx},${cy-s*0.65} ${cx+s},${cy} ${cx},${cy+s*0.65} ${cx-s},${cy}`;
    svg.appendChild(el(ns,'polygon',{points:pts,class:'rel-diamond'}));
    const t=el(ns,'text',{x:cx,y:cy,class:'rel-text',style:'font-size:'+(name.length>10?'8px':'9.5px')});
    t.textContent=name;svg.appendChild(t);
}

function drawLine(svg,ns,x1,y1,x2,y2){
    svg.appendChild(el(ns,'line',{x1:x1,y1:y1,x2:x2,y2:y2,class:'conn-line'}));
}

function drawCard(svg,ns,x,y,label){
    const t=el(ns,'text',{x:x+8,y:y-8,class:'card-text'});t.textContent=label;svg.appendChild(t);
}
