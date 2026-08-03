
function nav(page){
  var pg=document.getElementById('pg-'+page);
  if(!pg){
    if(page!=='home'&&page!=='legal'&&page!=='about'){window.location.href='dashboard.html#page-'+page}
    return false;
  }
  document.querySelectorAll('.pg').forEach(function(p){p.classList.remove('on')});
  document.querySelectorAll('.bi').forEach(function(b){b.classList.remove('on')});
  pg.classList.add('on');
  var nb=document.getElementById('nav-'+page);
  if(nb)nb.classList.add('on');
  if(page==='map'){initMapPage();setTimeout(initMap3d,300)}
  if(page==='add')setTimeout(fetchDistricts,100);
  if(page==='pulse')loadPulseData();
  if(page==='sources')loadSources();
  if(page==='heat'){initHeatMap();loadHeatData();}
}
window.__baseNav=nav;

/* RENDER */
function cardHTML(p){
  var im=pImg(p),fav=F.indexOf(p.id)>-1;
  return'<div class="card" onclick="showDetail('+p.id+')"><div class="card-img"><img src="'+im+'" alt="'+p.title+'" loading="lazy" onerror="this.onerror=null;this.src=\''+pFallback(p)+'\'"><div class="badges"><span class="badge '+(p.purpose==='إيجار'?'badge-r':'badge-s')+'">'+p.purpose+'</span>'+(p.status==='حصري'?'<span class="badge badge-x">⭐ حصري</span>':'')+'</div><button class="fav '+(fav?'on':'')+'" onclick="toggleFav('+p.id+',event)">'+(fav?'❤':'🤍')+'</button><span class="trust trust-'+tCls(p.trust)+'">'+tLbl(p.trust)+'</span>'+(p.panoramicImage||p.pano?'<span class="card-360">🌐 360°</span>':'')+(p.tourUrl||p.matterport||p.tour3d?'<span class="card-360">🕶️ 3D</span>':'')+(p.model3dUrl||p.model3d?'<span class="card-360">🧊 مجسم</span>':'')+'</div><div class="card-b"><div class="card-t">'+p.title+'</div><div class="card-l">📍 '+pLoc(p)+'</div><div class="card-p">'+pPrice(p)+'</div>'+(p.expectedPrice?'<div class="card-avm">💰 التقدير: '+fmt(p.expectedPrice)+' ر.س</div>':'')+'<div class="card-m"><span>🛏 '+p.rooms+'</span><span>📐 '+fmt(p.area)+' م²</span><span>🚿 '+p.baths+'</span>'+(p.type==='فيلا'&&p.apartments?'<span>🏢 '+p.apartments+' شقق</span>':'')+'</div></div></div>'
}
function render(f){
  var g=document.getElementById('pg'),list=f||A;
  if(!list.length){g.innerHTML='<div class="load">لا توجد عقارات</div>';return}
  g.innerHTML=list.map(cardHTML).join('');
}

function filt(el,purpose){
  document.querySelectorAll('.tab').forEach(function(t){t.classList.remove('on')});
  el.classList.add('on');cur=purpose;
  render(purpose?A.filter(function(p){return p.purpose===purpose}):A);
}

/* HOME SECTIONS */
function renderHomeSections(){
  var statsEl=document.getElementById('homeStats');
  var cities=['الرياض','جدة','مكة','الدمام','الخبر','حائل'];
  var counts={};cities.forEach(function(c){counts[c]=A.filter(function(p){return p.city===c}).length});
  statsEl.innerHTML='<div class="hs"><div class="hs-v">'+A.length+'</div><div class="hs-l">إجمالي العقارات</div></div>'+
    '<div class="hs"><div class="hs-v">'+cities.filter(function(c){return counts[c]>0}).length+'</div><div class="hs-l">المدن المتاحة</div></div>'+
    '<div class="hs"><div class="hs-v">'+A.filter(function(p){return p.purpose==='بيع'}).length+'</div><div class="hs-l">للبيع</div></div>'+
    '<div class="hs"><div class="hs-v">'+A.filter(function(p){return p.purpose==='إيجار'}).length+'</div><div class="hs-l">للإيجار</div></div>';

  var cityEl=document.getElementById('homeCities');
  cityEl.innerHTML='<div class="hc on" onclick="cityFilter(this,\'\')">الكل</div>'+
    cities.filter(function(c){return counts[c]>0}).map(function(c){return'<div class="hc" onclick="cityFilter(this,\''+c+'\')">📍 '+c+' ('+counts[c]+')</div>'}).join('');

  var feat=A.filter(function(p){return p.isFeatured||p.status==='حصري'}).slice(0,8);
  if(feat.length){
    document.getElementById('homeFeatured').style.display='block';
    document.getElementById('homeFeatGrid').innerHTML=feat.map(function(p){return'<div class="hf" onclick="showDetail('+p.id+')"><img src="'+pImg(p)+'" alt="" loading="lazy" onerror="this.src=\''+pFallback(p)+'\'"><div class="hf-b"><div class="hf-t">'+p.title+'</div><div class="hf-l">📍 '+pLoc(p)+'</div><div class="hf-p">'+pPrice(p)+'</div></div></div>'}).join('');
  }

  document.getElementById('propCount').textContent=A.length+' عقار';
}

function cityFilter(el,city){
  document.querySelectorAll('.hc').forEach(function(c){c.classList.remove('on')});
  el.classList.add('on');
  if(city){render(A.filter(function(p){return p.city===city}))}
  else{render()}
}

/* PULSE PAGE */
var pulseData=[];

function openPulseDetail(px){
  var metro='',projects='';
  if(px.metro_stations&&px.metro_stations.length){
    metro='<div style="margin-bottom:8px"><div style="font-size:11px;color:var(--g);font-weight:600;margin-bottom:6px">🚇 أقرب محطات المترو</div>'+
      px.metro_stations.map(function(m){return'<div style="display:flex;align-items:center;gap:8px;font-size:11px;color:var(--m);padding:5px 8px;border-radius:8px;background:rgba(255,255,255,.02);margin-bottom:4px"><span style="width:8px;height:8px;border-radius:50%;background:'+(m.line==='الأزرق'?'#2196f3':'#ef5350')+';flex-shrink:0"></span><span style="flex:1">'+m.name+'</span><span style="color:var(--green);font-weight:600">'+m.distance+'</span><span style="font-size:9px;color:var(--m)">'+m.year+'</span></div>'}).join('')+'</div>';
  }
  if(px.nearby_projects&&px.nearby_projects.length){
    projects='<div style="margin-bottom:8px"><div style="font-size:11px;color:var(--g);font-weight:600;margin-bottom:6px">🏗️ مشاريع كبرى قريبة</div>'+
      px.nearby_projects.map(function(m){return'<div style="display:flex;align-items:center;gap:8px;font-size:11px;color:var(--m);padding:5px 8px;border-radius:8px;background:rgba(255,255,255,.02);margin-bottom:4px"><span>'+m.name+'</span><span style="flex:1"></span><span style="color:var(--blue)">'+m.distance+'</span></div>'}).join('')+'</div>';
  }
  var growth=px.future_value_growth?('<span style="color:var(--green)">+'+px.future_value_growth+'%</span>'):'—';
  var roiColor=px.roi>7?'var(--green)':px.roi>5?'var(--g)':'var(--red)';
  var growthColor=px.future_value_growth>15?'var(--green)':px.future_value_growth>8?'var(--g)':'var(--m)';
  var sb=px.sports_boulevard?'<div style="display:flex;align-items:center;gap:6px;padding:8px 12px;border-radius:10px;background:rgba(74,222,128,.08);border:1px solid rgba(74,222,128,.2);font-size:11px;color:var(--green);margin-bottom:8px">🏃 يمر بالحي <strong>المسار الرياضي</strong> — جودة حياة أعلى</div>':'';
  var html='<button class="cls" onclick="closeD()">×</button>'+
    '<div class="dt" style="font-size:16px">📊 '+px.district+'</div>'+
    '<div class="dl" style="margin-bottom:12px">📍 '+px.city+'</div>'+
    '<div style="background:rgba(8,9,14,.95);border:1px solid rgba(212,175,55,.15);border-radius:var(--r);padding:14px;animation:pulseIn .4s ease;margin-bottom:12px">'+sb+
    '<div style="display:grid;grid-template-columns:1fr 1fr;gap:6px;margin-bottom:8px">'+
    '<div style="padding:10px;border-radius:10px;background:rgba(255,255,255,.02);border:1px solid rgba(255,255,255,.06);text-align:center"><div style="font-size:10px;color:var(--m)">العائد الإيجاري</div><div style="font-size:16px;font-weight:700;color:'+roiColor+'">'+(px.roi||'—')+'%</div></div>'+
    '<div style="padding:10px;border-radius:10px;background:rgba(255,255,255,.02);border:1px solid rgba(255,255,255,.06);text-align:center"><div style="font-size:10px;color:var(--m)">النمو المتوقع</div><div style="font-size:16px;font-weight:700;color:'+growthColor+'">'+growth+'</div></div>'+
    (px.avg_rent?'<div style="padding:10px;border-radius:10px;background:rgba(255,255,255,.02);border:1px solid rgba(255,255,255,.06);text-align:center"><div style="font-size:10px;color:var(--m)">متوسط الإيجار/سنوياً</div><div style="font-size:13px;font-weight:700;color:var(--g)">'+fmt(px.avg_rent)+' ر.س</div></div>':'')+
    (px.avg_sale?'<div style="padding:10px;border-radius:10px;background:rgba(255,255,255,.02);border:1px solid rgba(255,255,255,.06);text-align:center"><div style="font-size:10px;color:var(--m)">متوسط البيع</div><div style="font-size:13px;font-weight:700;color:var(--g)">'+fmt(px.avg_sale)+' ر.س</div></div>':'')+
    (px.walk_score?'<div style="padding:10px;border-radius:10px;background:rgba(255,255,255,.02);border:1px solid rgba(255,255,255,.06);text-align:center"><div style="font-size:10px;color:var(--m)">مؤشر المشي</div><div style="font-size:16px;font-weight:700;color:var(--blue)">'+px.walk_score+'</div></div>':'')+
    '</div>'+metro+projects+'<div style="font-size:9px;color:var(--m);text-align:left;padding-top:4px;border-top:1px solid rgba(255,255,255,.04)">📊 '+px.data_source+'</div><div id="officialBlock"></div></div>';
  document.getElementById('ovp').innerHTML=html;
  loadOfficialForDistrict(px.district).then(function(d){
    var b=renderOfficialBlock(d);
    var el=document.getElementById('officialBlock');
    if(el&&b)el.innerHTML=b;
  });
  document.getElementById('ov').classList.add('open');
  document.body.style.overflow='hidden';
}

function pScore(p){
  return Math.min(100,Math.max(0,Math.round(((p.roi||0)*3 + (p.walk_score||0)*0.4 + ((p.future_value_growth||0))*1.2)/2)));
}

function renderPulse(){
  var city=document.querySelector('#pulseCityFilter .on')?.dataset?.city||'';
  var sort=document.getElementById('pulseSort').value;
  var list=pulseData.filter(function(p){return !city||p.city===city});
  list.sort(function(a,b){
    if(sort==='roi')return (b.roi||0)-(a.roi||0);
    if(sort==='growth')return (b.future_value_growth||0)-(a.future_value_growth||0);
    if(sort==='walk')return (b.walk_score||0)-(a.walk_score||0);
    return pScore(b)-pScore(a);
  });
  document.getElementById('pulseCount').textContent=list.length+' حي';
  document.getElementById('pulseGrid').innerHTML=list.map(function(p){
    var sc=pScore(p);
    var c=sc>70?'var(--green)':sc>45?'var(--g)':'var(--red)';
    var rc=p.roi>7?'var(--green)':p.roi>5?'var(--g)':'var(--red)';
    var gc=p.future_value_growth>15?'var(--green)':p.future_value_growth>8?'var(--g)':'var(--m)';
    var badge='';
    if(p.metro_stations&&p.metro_stations.length)badge+='<span class="pc-badge pc-badge-metro">🚇 '+p.metro_stations.length+' محطة</span>';
    if(p.nearby_projects&&p.nearby_projects.length)badge+='<span class="pc-badge pc-badge-project">🏗️ '+p.nearby_projects.length+' مشروع</span>';
    if(p.sports_boulevard)badge+='<span class="pc-badge pc-badge-sport">🏃 مسار رياضي</span>';
    if(p.green_spaces&&p.green_spaces.length)badge+='<span class="pc-badge pc-badge-green">🌳 '+p.green_spaces.length+' حديقة</span>';
    return '<div class="pc" onclick="openPulseDetail(pulseData.find(function(x){return x.district===\''+(p.district||'').replace(/'/g,"\\'")+'\'&&x.city===\''+(p.city||'').replace(/'/g,"\\'")+'\'}))">'+
      '<div class="pc-top"><div class="pc-score" style="background:'+c+'">'+sc+'</div>'+
      '<div class="pc-info"><div class="pc-dist">'+p.district+'</div><div class="pc-city">📍 '+p.city+'</div></div></div>'+
      '<div class="pc-stats"><div class="pc-stat"><div class="pc-stat-v" style="color:'+rc+'">'+(p.roi||'—')+'%</div><div class="pc-stat-l">العائد</div></div>'+
      '<div class="pc-stat"><div class="pc-stat-v" style="color:'+gc+'">'+(p.future_value_growth?'+'+(p.future_value_growth||0)+'%':'—')+'</div><div class="pc-stat-l">النمو</div></div>'+
      '<div class="pc-stat"><div class="pc-stat-v" style="color:var(--blue)">'+(p.walk_score||'—')+'</div><div class="pc-stat-l">المشي</div></div></div>'+
      (badge?'<div class="pc-badges">'+badge+'</div>':'')+'</div>';
  }).join('');
}

function loadPulseData(){
  api('/pulse').then(function(d){
    if(d&&d.success&&d.pulse&&d.pulse.length){
      pulseData=d.pulse;
      var cities=[...new Set(pulseData.map(function(p){return p.city}))];
      var cf=document.getElementById('pulseCityFilter');
      cf.innerHTML='<div class="hc on" data-city="" onclick="pulseCity(this)">الكل</div>'+
        cities.map(function(c){return'<div class="hc" data-city="'+c+'" onclick="pulseCity(this)">📍 '+c+'</div>'}).join('');
      renderPulse();
    }else{
      document.getElementById('pulseGrid').innerHTML='<div class="load">لا توجد بيانات متاحة</div>';
    }
  }).catch(function(){
    document.getElementById('pulseGrid').innerHTML='<div class="load">خطأ في تحميل البيانات</div>';
  });
}

function pulseCity(el){
  document.querySelectorAll('#pulseCityFilter .hc').forEach(function(c){c.classList.remove('on')});
  el.classList.add('on');
  renderPulse();
}

var officialCache={};
async function loadOfficialForDistrict(district){
  if(officialCache[district])return officialCache[district];
  var d=await api('/indicators/district/'+encodeURIComponent(district));
  officialCache[district]=d&&d.success?d:{success:false,indicators:[]};
  return officialCache[district];
}
function renderOfficialBlock(d){
  if(!d||!d.success||!d.indicators||!d.indicators.length)return'';
  var rows=d.indicators.slice(0,4);
  var items=rows.map(function(o){
    var label=o.property_type||'—';
    var perM2=o.avg_per_m2?'<div style="font-size:11px;font-weight:700;color:var(--green)">'+fmt(o.avg_per_m2)+' ر.س/م²</div>':'';
    return'<div style="display:flex;align-items:center;gap:8px;font-size:11px;color:var(--m);padding:6px 8px;border-radius:8px;background:rgba(255,255,255,.02);margin-bottom:4px">'+
      '<span style="flex:1;font-weight:600;color:var(--t)">'+label+'</span>'+
      '<span>'+fmt(o.deals)+' عقد</span>'+
      perM2+
      '</div>';
  }).join('');
  var src=d.indicators[0];
  return'<div style="margin-top:10px;padding:10px;border-radius:10px;background:rgba(212,175,55,.05);border:1px solid rgba(212,175,55,.18)">'+
    '<div style="font-size:11px;color:var(--g);font-weight:700;margin-bottom:6px">🏛️ متوسط الإيجار الرسمي — '+((src.year||'')+' '+qName(src.quarter))+'</div>'+
    items+
    '<div style="font-size:9px;color:var(--m);padding-top:6px;border-top:1px solid rgba(255,255,255,.06);display:flex;align-items:center;justify-content:space-between;gap:6px;flex-wrap:wrap">'+
    '<span>المصدر: '+src.source+'</span>'+
    '<a href="'+src.source_url+'" target="_blank" style="color:var(--g);text-decoration:none">المراجعة ←</a>'+
    '</div></div>';
}
function qName(q){return q===1?'الربع الأول':q===2?'الربع الثاني':q===3?'الربع الثالث':'الربع الرابع'}

function loadSources(){
  api('/indicators/sources').then(function(d){
    var el=document.getElementById('sourcesList');
    if(!d||!d.success||!d.sources||!d.sources.length){el.innerHTML='<div class="load">لا توجد مصادر</div>';return}
    el.innerHTML=d.sources.map(function(s){
      return'<div style="padding:12px;border-radius:12px;background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.07)">'+
        '<div style="display:flex;align-items:center;justify-content:space-between;gap:8px;margin-bottom:4px">'+
        '<div style="font-size:13px;font-weight:700;color:var(--t)">'+s.name+'</div>'+
        '<span style="font-size:9px;padding:2px 8px;border-radius:999px;background:rgba(212,175,55,.12);color:var(--g);font-weight:600;white-space:nowrap">'+s.update+'</span></div>'+
        '<div style="font-size:11px;color:var(--m);line-height:1.7;margin-bottom:8px">'+s.description+'</div>'+
        '<a href="'+s.url+'" target="_blank" style="display:inline-block;padding:6px 14px;border-radius:8px;background:linear-gradient(135deg,#d4af37,#b8941f);color:#05060a;font-size:11px;font-weight:700;text-decoration:none">زيارة المصدر 🔗</a></div>';
    }).join('');
  });
}

/* ADVANCED FILTERS */
function toggleAdvFilters(){
  var el=document.getElementById('advFilters');
  el.classList.toggle('open');
  if(el.classList.contains('open')&&A.length){loadSuggestions()}
}
document.querySelectorAll('.af-chip').forEach(function(chip){
  chip.addEventListener('click',function(){
    var group=this.parentElement;
    group.querySelectorAll('.af-chip').forEach(function(c){c.classList.remove('on')});
    this.classList.add('on');
  });
});
function getChipVal(id){
  var el=document.querySelector('#'+id+' .af-chip.on');
  return el?el.getAttribute('data-v'):'';
}
function resetFilters(){
  document.getElementById('hq').value='';
  document.getElementById('hc').value='';
  document.getElementById('ht').value='';
  document.getElementById('hp').value='';
  document.getElementById('af-minPrice').value='';
  document.getElementById('af-maxPrice').value='';
  document.getElementById('af-minArea').value='';
  document.getElementById('af-maxArea').value='';
  document.querySelectorAll('.af-chip').forEach(function(c){c.classList.remove('on')});
  document.querySelectorAll('.af-feat input').forEach(function(c){c.checked=false});
  document.getElementById('af-sort').value='';
  document.getElementById('af-suggestions').style.display='none';
  render();
}
async function doSearch(){
  var q=(document.getElementById('hq').value||'').toLowerCase();
  var c=document.getElementById('hc').value;
  var t=document.getElementById('ht').value;
  var mp=Number(document.getElementById('hp').value);
  var minP=Number(document.getElementById('af-minPrice').value)||0;
  var maxP=Number(document.getElementById('af-maxPrice').value)||mp;
  var minA=Number(document.getElementById('af-minArea').value)||0;
  var maxA=Number(document.getElementById('af-maxArea').value)||0;
  var purpose=document.getElementById('af-purpose').value||cur;
  var rooms=Number(getChipVal('af-rooms'))||0;
  var baths=Number(getChipVal('af-baths'))||0;
  var apartments=Number(getChipVal('af-apartments'))||0;
  var facing=getChipVal('af-facing');
  var age=getChipVal('af-age');
  var sort=document.getElementById('af-sort').value;
  var streetW=Number(getChipVal('af-streetW'))||0;
  var cars=Number(getChipVal('af-cars'))||0;
  var features=[];
  ['af-f-pool','af-f-elev','af-f-garage','af-f-ac','af-f-kitchen','af-f-furnished','af-f-entrance','af-f-roof'].forEach(function(id){
    var el=document.getElementById(id);if(el&&el.checked)features.push(el.value);
  });
  var hasFilters=q||c||t||minP||maxP||minA||maxA||purpose||rooms||baths||apartments||facing||age||sort||streetW||cars||features.length;
  if(!hasFilters){render();return}
  var params=new URLSearchParams();
  if(q)params.set('q',q);
  if(c)params.set('city',c);
  if(t)params.set('type',t);
  if(purpose)params.set('purpose',purpose);
  if(minP)params.set('minPrice',minP);
  if(maxP)params.set('maxPrice',maxP);
  if(minA)params.set('minArea',minA);
  if(maxA)params.set('maxArea',maxA);
  if(rooms)params.set('rooms',rooms);
  if(baths)params.set('baths',baths);
  if(apartments)params.set('apartments',apartments);
  if(facing)params.set('facing',facing);
  if(age)params.set('age',age);
  if(sort)params.set('sort',sort);
  if(streetW)params.set('minStreetWidth',streetW);
  if(cars)params.set('minCars',cars);
  if(features.length)params.set('features',features.join(','));
  params.set('limit','50');
  var d=await api('/search?'+params.toString());
  if(d&&d.success){
    var results=d.properties.map(function(p){
      return Object.assign({},p,{loc:p.loc||(p.district+'، '+p.city),status:p.isFeatured?'حصري':'متاح',agent:p.agent||{name:p.agentName||'مكتب الديار العقارية',role:'وسيط مرخص',phone:p.agentPhone||'+966501234567'}});
    });
    if(sort==='nearest'&&navigator.geolocation){
      navigator.geolocation.getCurrentPosition(function(pos){
        results.sort(function(a,b){
          var da=Math.hypot((a.lat||0)-pos.coords.latitude,(a.lng||0)-pos.coords.longitude);
          var db=Math.hypot((b.lat||0)-pos.coords.latitude,(b.lng||0)-pos.coords.longitude);
          return da-db;
        });
        render(results);
      },function(){render(results)});
    }else{render(results)}
    if(!results.length)toast('لا توجد نتائج مطابقة للفلاتر المحددة');
  }else{
    var f=A.filter(function(p){
      if(c&&p.city!==c)return false;if(t&&p.type!==t)return false;
      if(maxP&&p.price>maxP)return false;if(minP&&p.price<minP)return false;
      if(maxA&&p.area>maxA)return false;if(minA&&p.area<minA)return false;
      if(purpose&&p.purpose!==purpose)return false;
      if(rooms&&p.rooms<rooms)return false;
      if(baths&&p.baths<baths)return false;
      if(facing&&p.facing!==facing)return false;
      if(streetW&&p.streetW<streetW)return false;
      if(cars&&p.cars<cars)return false;
      if(features.length){var pf=p.features||[];if(!features.every(function(f){return pf.indexOf(f)>-1}))return false}
      if(q){var s=(p.title+' '+p.loc+' '+p.city+' '+p.district+' '+p.type+' '+(p.desc||'')).toLowerCase();if(s.indexOf(q)===-1)return false}
      return true;
    });
    if(sort==='price_asc')f.sort(function(a,b){return a.price-b.price});
    else if(sort==='price_desc')f.sort(function(a,b){return b.price-a.price});
    else if(sort==='area_desc')f.sort(function(a,b){return b.area-a.area});
    render(f);
  }
}
async function loadSuggestions(){
  if(!A.length)return;
  var sug=document.getElementById('af-suggestions');
  var list=document.getElementById('af-sugList');
  sug.style.display='block';
  var avgPrice=Math.round(A.reduce(function(s,p){return s+p.price},0)/A.length);
  var cities={};var types={};var facings={};
  A.forEach(function(p){cities[p.city]=(cities[p.city]||0)+1;types[p.type]=(types[p.type]||0)+1;if(p.facing)facings[p.facing]=(facings[p.facing]||0)+1});
  var topCity=Object.keys(cities).sort(function(a,b){return cities[b]-cities[a]})[0];
  var topType=Object.keys(types).sort(function(a,b){return types[b]-types[a]})[0];
  list.innerHTML='<div class="af-sug-card">📊 <b>متوسط السعر:</b> '+fmt(avgPrice)+' ر.س في '+A.length+' عقار</div><div class="af-sug-card">🏙️ <b>أكثر مدينة:</b> '+topCity+' ('+cities[topCity]+' عقار)</div><div class="af-sug-card">🏠 <b>أكثر نوع:</b> '+topType+' ('+types[topType]+' عقار)</div>';
}

async function toggleFav(id,e){
  if(e)e.stopPropagation();
  var i=F.indexOf(id);if(i>-1)F.splice(i,1);else F.push(id);
  localStorage.setItem('darak_favs',JSON.stringify(F));
  if(authToken){await api('/properties/'+id+'/favorite',{method:'POST'}).catch(function(){})}
  render();
}

/* REPORT */
async function reportAd(id){
  if(!authToken){alert('يرجى تسجيل الدخول أولاً');openLogin();return}
  var reason=prompt('سبب البلاغ:\n- إعلان وهمي\n- سعر غير واقعي\n- صور مضللة\n- مكرر\n- مخالف للشروط\n- أخرى');
  if(!reason)return;
  if(reason.length<3){alert('يرجى كتابة سبب واضح (3 أحرف على الأقل)');return}
  var desc=prompt('تفاصيل إضافية (اختياري):');
  try{
    var r=await api('/reports',{method:'POST',body:{propertyId:id,reason:reason,description:desc||''}});
    if(r&&r.message){alert(r.message)}
  }catch(e){
    if(e.code==='DUPLICATE'){alert('لقد أبلغت عن هذا العقار مسبقًا');return}
    if(e.code==='NOT_FOUND'){alert('العقار غير موجود');return}
    alert('حدث خطأ أثناء الإبلاغ، حاول مرة أخرى')
  }
}

/* DETAIL */
var currentDetail=null;
function showDetail(id){
  var p=A.find(function(x){return x.id===id});if(!p)return;currentDetail=p;destroyVT();
  var imgs=(p.images&&p.images.length)?p.images:[pFallback(p)];
  var tb3d=(p.tourUrl||p.matterport||p.tour3d)?'<button class="gal-360btn" onclick="openVR(currentDetailImages)">🕶️ جولة 3D</button>':'';
  var tb360=imgs.length?'<button class="gal-360btn" onclick="openVR(currentDetailImages)">🌐 جولة 360°</button>':'';
  var html='<button class="cls" onclick="closeD()">×</button>';
  html+='<div class="ov-gal" id="og">'+imgs.map(function(s,i){return'<img src="'+s+'" '+(i===0?'class="on"':'')+' onerror="this.onerror=null;this.src=\''+pFallback(p)+'\'">'}).join('')+(imgs.length>1?'<button class="gal-nav gal-n" onclick="gNav(1)">›</button><button class="gal-nav gal-p" onclick="gNav(-1)">‹</button>':'')+'<div class="gal-c">📷 '+imgs.length+' صور</div>'+tb3d+tb360+'</div>';
  currentDetailImages=imgs;
  html+='<span class="db db-'+tCls(p.trust)+'">'+tLbl(p.trust)+'</span>';
  html+='<div class="dt">'+p.title+'</div><div class="dl">📍 '+pLoc(p)+'</div><div class="dp">'+pPrice(p)+'</div><div id="avm-chip-'+p.id+'"></div>';
  html+='<div class="sp"><div class="si"><div class="si-v">'+fmt(p.area)+' م²</div><div class="si-l">المساحة</div></div><div class="si"><div class="si-v">'+(p.rooms||'—')+'</div><div class="si-l">الغرف</div></div><div class="si"><div class="si-v">'+(p.baths||'—')+'</div><div class="si-l">الحمامات</div></div><div class="si"><div class="si-v">'+(p.cars||'—')+'</div><div class="si-l">مواقف</div></div>'+(p.type==='فيلا'&&p.apartments?'<div class="si"><div class="si-v">'+p.apartments+'</div><div class="si-l">الشقق</div></div>':'')+'<div class="si"><div class="si-v">'+(p.facing||'—')+'</div><div class="si-l">الواجهة</div></div><div class="si"><div class="si-v">'+(p.year||'—')+'</div><div class="si-l">البناء</div></div></div>';
  if(p.features&&p.features.length){html+='<div class="fd"><h3>المميزات</h3><div class="fch">'+p.features.map(function(f){return'<span style="padding:6px 12px;border-radius:999px;background:rgba(212,175,55,.06);border:1px solid rgba(212,175,55,.15);font-size:11px;color:var(--m)">'+f+'</span>'}).join('')+'</div></div>'}
  if(p.desc){html+='<div class="desc"><h3>الوصف</h3><p>'+p.desc+'</p></div>'}
  var vtTour=p.tourUrl||p.matterport||p.tour3d;
  var vtPano=p.panoramicImage||p.pano;
  var vtModel=p.model3dUrl||p.model3d||null;
  var defMode=vtModel?'doll':'in';
  html+='<div class="vt-section"><div class="vt-head"><span class="vt-icon">'+(vtModel?'🧊':(vtTour?'🕶️':'🌐'))+'</span><h3>جولة العقار التفاعلية</h3></div>';
  html+='<div class="vt-tabs"><button class="vt-tab'+(defMode==='doll'?' on':'')+'" data-m="doll" onclick="vtSetMode(\'doll\')">🏡 بيت الدمية</button><button class="vt-tab" data-m="plan" onclick="vtSetMode(\'plan\')">📐 المخطط</button><button class="vt-tab'+(defMode==='in'?' on':'')+'" data-m="in" onclick="vtSetMode(\'in\')">👣 تجول داخلي</button></div>';
  html+='<div class="vt-body" id="vt-doll"'+(defMode==='doll'?'':' style="display:none"')+'></div>';
  html+='<div class="vt-body" id="vt-plan" style="display:none"></div>';
  html+='<div class="vt-body" id="vt-in"'+(defMode==='in'?'':' style="display:none"')+'></div>';
  html+='</div>';
  html+='<div id="pulse-card-'+p.id+'"><div class="load" style="padding:16px">جاري تحميل مؤشر نبض الحي...</div></div>'
  var ph=(p.agent&&p.agent.phone)?p.agent.phone.replace(/[^0-9]/g,''):'';
  html+='<div class="ag"><div class="ag-n">'+(p.agent&&p.agent.name||'دارك وحيك')+'</div><div class="ag-r">'+(p.agent&&p.agent.role||'بائع مباشر')+'</div><div id="ag-rating-'+p.id+'"></div><div class="ag-b">'+(ph?'<button class="ag-btn ag-w" onclick="contactAgent(\''+ph+'\',\'wa\')">💬 واتساب</button><button class="ag-btn ag-c" onclick="contactAgent(\''+ph+'\',\'tel\')">📞 اتصال</button>':'')+'</div></div>';
  html+='<div class="dacts"><button class="dbt s" onclick="openAVM(currentDetail)">🧮 قيمة تقديرية</button><button class="dbt s" onclick="openAIP(currentDetail)">🤖 تحليل السعر</button>'+(p.lat&&p.lng?'<button class="dbt s" onclick="open3D(currentDetail)">🏗️ عرض 3D</button>':'')+'<button class="dbt s" onclick="shareProp('+p.id+')">📤 مشاركة</button><button class="dbt d" onclick="reportAd('+p.id+')">🚩 بلاغ</button></div>';
  var dp=document.getElementById('detailPage');
  if(dp){
    dp.innerHTML='<div class="detail-page-inner">'+html+'</div>';
    window.scrollTo(0,0);
    document.title=p.title+' | دارك وحيك';
  }else{
    document.getElementById('ovp').innerHTML=html;
    document.getElementById('ov').classList.add('open');
    document.body.style.overflow='hidden';
  }
  renderDetailAVM(p);
  initVTSection(p);
  fetchPulse(p);
  var advId=p.agentUserId||(p.agent&&p.agent.id);
  if(advId)fetchAdvertiserRating(advId,p.id);
}
var vtViewer=null;
function destroyVT(){
  if(vtViewer){try{vtViewer.destroy()}catch(e){}vtViewer=null}
  var f=document.getElementById('vtFrame');
  if(f){try{f.src='about:blank'}catch(e){}if(f.parentNode)f.parentNode.removeChild(f)}
  var pc=document.getElementById('vt-pano');
  if(pc)pc.innerHTML='';
  var inn=document.getElementById('vt-in');
  if(inn){inn.innerHTML='';delete inn.dataset.built}
  ['doll','plan'].forEach(function(x){
    var e=document.getElementById('vt-'+x);
    if(e)e.innerHTML='';
  });
}
function initVTSection(p){
  var el=document.getElementById('vt-in');
  if(!el)return;
  if(el.style.display!=='none')vtBuildInside(p);
  var model=p.model3dUrl||p.model3d||null;
  if(model){vtModel3D(document.getElementById('vt-doll'),'doll',model);vtModel3D(document.getElementById('vt-plan'),'plan',model);}
}
function vtBuildInside(p){
  var el=document.getElementById('vt-in');
  if(!el||el.dataset.built)return;
  el.dataset.built='1';
  var tour=p.tourUrl||p.matterport||p.tour3d;
  var pano=p.panoramicImage||p.pano;
  el.innerHTML='';
  if(tour){
    var f=document.createElement('iframe');
    f.id='vtFrame';f.src=tour;
    f.setAttribute('allow','xr-spatial-tracking;gyroscope;accelerometer;fullscreen;camera');
    f.setAttribute('allowfullscreen','');
    f.setAttribute('referrerpolicy','no-referrer-when-downgrade');
    f.style.cssText='position:absolute;inset:0;width:100%;height:100%;border:0;background:#0a0b10';
    el.appendChild(f);
  }else if(pano&&window.pannellum){
    var pc=document.createElement('div');
    pc.id='vt-pano';
    pc.style.cssText='position:absolute;inset:0;width:100%;height:100%';
    el.appendChild(pc);
    try{
      vtViewer=pannellum.viewer('vt-pano',{
        type:'equirectangular',panorama:pano,autoLoad:true,autoRotate:-1,
        compass:false,showFullscreenCtrl:true,crossOrigin:'anonymous',hfov:100
      });
    }catch(e){}
  }else if(p.images&&p.images.length){
    var b=document.createElement('button');
    b.className='vt-gen';
    b.textContent='🤖 توليد جولة 360 من صور العقار';
    b.onclick=function(){tbPreload(currentDetail.images)};
    el.appendChild(b);
  }
}
function vtSetMode(mode){
  var p=currentDetail;if(!p)return;
  var tabs=document.querySelectorAll('.vt-tab');
  for(var i=0;i<tabs.length;i++)tabs[i].classList.toggle('on',tabs[i].getAttribute('data-m')===mode);
  ['doll','plan','in'].forEach(function(x){
    var e=document.getElementById('vt-'+x);
    if(e)e.style.display=(x===mode)?'block':'none';
  });
  if(mode==='in'){vtBuildInside(p);return}
  if(!p.model3dUrl&&!p.model3d){
    var el=document.getElementById('vt-'+mode);
    if(el&&!el.querySelector('model-viewer')){
      el.innerHTML='<div class="vt-empty"><div class="vt-empty-i">🧊</div><div class="vt-empty-t">لا يوجد نموذج ثلاثي الأبعاد لهذا العقار</div><div class="vt-empty-s">يُعرض بيت الدمية والمخطط من نموذج GLB/GLTF يُضاف عند نشر العقار</div><button class="vt-sample" onclick="vtSampleModel(\''+mode+'\')">🧪 جرّب نموذجًا تجريبيًا</button></div>';
    }
  }
}
function vtModel3D(el,mode,src){
  if(!el)return;
  var mv=el.querySelector('model-viewer');
  if(!mv){
    mv=document.createElement('model-viewer');
    mv.style.cssText='position:absolute;inset:0;width:100%;height:100%;--poster-color:transparent';
    mv.setAttribute('camera-controls','');
    mv.setAttribute('shadow-intensity','1');
    mv.setAttribute('src',src);
    el.appendChild(mv);
  }else if(mv.getAttribute('src')!==src){mv.setAttribute('src',src)}
  if(mode==='plan'){
    mv.setAttribute('camera-orbit','0deg 89deg 130%');
    mv.removeAttribute('auto-rotate');
  }else{
    mv.setAttribute('camera-orbit','-25deg 72deg 110%');
    mv.setAttribute('auto-rotate','');
  }
  if(mv.jumpCameraToGoal)mv.jumpCameraToGoal();
}
function vtSampleModel(mode){
  vtModel3D(document.getElementById('vt-'+mode),mode,'https://modelviewer.dev/shared-assets/models/Astronaut.glb');
}
function renderDetailAVM(p){
  var el=document.getElementById('avm-chip-'+(p&&p.id));
  if(!el)return;
  if(!p.expectedPrice){el.innerHTML='';return}
  var conf=p.saleChance||0;
  var diff=p.price?Math.round(((p.price-p.expectedPrice)/p.expectedPrice)*100):0;
  var col=diff<=-5?'#4ade80':diff<=10?'var(--g)':'#f87171';
  var fair=diff<=-5?'أقل من التقدير':diff<=10?'قريب من التقدير':'أعلى من التقدير';
  el.innerHTML='<div onclick="openAVM(currentDetail)" style="cursor:pointer;display:flex;align-items:center;gap:10px;margin:10px 0;padding:10px 12px;border-radius:12px;background:rgba(212,175,55,.07);border:1px solid rgba(212,175,55,.25)">'+
    '<div style="font-size:22px">💰</div>'+
    '<div style="flex:1;min-width:0"><div style="font-size:10px;color:var(--m)">القيمة التقديرية</div><div style="font-size:15px;font-weight:800;color:var(--g)">'+fmt(p.expectedPrice)+' ر.س</div></div>'+
    '<div style="text-align:left"><div style="font-size:11px;color:'+col+';font-weight:700">'+fair+'</div><div style="font-size:9px;color:var(--m)">'+(diff>0?'+':'')+diff+'% عن المطلوب</div></div>'+
    '<div style="font-size:9px;color:var(--m);text-align:center">دقة<br><b style="color:var(--g)">'+conf+'%</b></div>'+
    '<div style="font-size:10px;color:var(--m)">🔄</div></div>';
}
function fetchAdvertiserRating(advId,propId){
  api('/ratings/advertiser/'+advId).then(function(d){
    if(!d)return;
    var el=document.getElementById('ag-rating-'+propId);if(!el)return;
    var avg=d.average||0,count=d.count||0;
    var stars='';for(var i=1;i<=5;i++){stars+=i<=Math.round(avg)?'★':'☆'}
    el.innerHTML='<div style="display:flex;align-items:center;gap:6px;margin:6px 0;font-size:14px;color:var(--g);cursor:pointer" onclick="openRatingOv('+advId+','+propId+')">'+
      '<span style="color:'+(avg>=4.5?'#4ade80':avg>=3?'var(--g)':'#f87171')+'">'+stars+'</span>'+
      '<span style="font-size:11px;color:var(--m)">('+avg+')</span>'+
      '<span style="font-size:10px;color:var(--m)">— '+count+' تقييم</span>'+
      (count>=5&&avg>=4?'<span style="font-size:10px;padding:2px 6px;border-radius:999px;background:rgba(74,222,128,.15);color:#4ade80;border:1px solid rgba(74,222,128,.3)">✓ موثوق</span>':'')+
    '</div>'
  }).catch(function(){})
}
function openRatingOv(advId,propId){
  if(!authToken){toast('يرجى تسجيل الدخول أولاً');openLogin();return}
  var p=A.find(function(x){return x.id===propId});if(!p)return;
  var name=p.agent&&p.agent.name||'المعلن';
  var html='<button class="cls" onclick="closeOv()">×</button><div style="padding-top:44px;text-align:center">';
  html+='<div style="font-size:28px;margin-bottom:6px">⭐</div>';
  html+='<div style="font-size:15px;font-weight:700;color:var(--t);margin-bottom:4px">تقييم '+name+'</div>';
  html+='<div style="font-size:11px;color:var(--m);margin-bottom:16px">اختر تقييمك من 1 إلى 5 نجوم</div>';
  html+='<div style="display:flex;justify-content:center;gap:6px;margin-bottom:16px">';
  for(var i=1;i<=5;i++){html+='<span id="rs-'+i+'" onclick="selectRating('+i+')" style="font-size:32px;cursor:pointer;color:var(--m);transition:color .15s">☆</span>'}
  html+='</div>';
  html+='<div style="margin-bottom:12px"><input id="rating-comment" type="text" placeholder="تعليق (اختياري)" maxlength="200" style="width:100%;padding:10px;border-radius:10px;background:rgba(255,255,255,.04);border:1px solid var(--b);color:var(--t);font-size:13px;font-family:inherit;outline:none;text-align:right"></div>';
  html+='<button id="rating-submit-btn" onclick="submitRating('+advId+','+propId+')" style="width:100%;padding:14px;border-radius:12px;border:none;background:linear-gradient(135deg,var(--g),#c9a430);color:#05060a;font-size:14px;font-weight:700;font-family:inherit;cursor:pointer">إرسال التقييم</button>';
  html+='</div>';
  document.getElementById('ovp').innerHTML=html;
  document.getElementById('ov').classList.add('open');
  document.body.style.overflow='hidden';
  window._ratingScore=0;
}
function selectRating(s){window._ratingScore=s;for(var i=1;i<=5;i++){document.getElementById('rs-'+i).style.color=i<=s?'var(--g)':'var(--m)';document.getElementById('rs-'+i).textContent=i<=s?'★':'☆'}}
async function submitRating(advId,propId){
  var score=window._ratingScore||0;if(!score){toast('اختر تقييمًا من 1 إلى 5');return}
  var comment=document.getElementById('rating-comment')?document.getElementById('rating-comment').value:'';
  var btn=document.getElementById('rating-submit-btn');btn.disabled=true;btn.textContent='جاري الإرسال...';
  try{
    var r=await api('/ratings',{method:'POST',body:JSON.stringify({advertiserId:advId,score:score,comment:comment})});
    if(r&&r.message){toast(r.message);closeOv();fetchAdvertiserRating(advId,propId)}
    else{toast('فشل إرسال التقييم');btn.disabled=false;btn.textContent='إرسال التقييم'}
  }catch(e){toast('فشل إرسال التقييم');btn.disabled=false;btn.textContent='إرسال التقييم'}
}
function fetchPulse(p){
  var district=encodeURIComponent(p.district);
  api('/pulse/'+district).then(function(d){
    if(!d||!d.success){document.getElementById('pulse-card-'+p.id).innerHTML='';return}
    var px=d.pulse;
    var metro='',projects='';
    if(px.metro_stations&&px.metro_stations.length){
      metro='<div style="margin-bottom:8px"><div style="font-size:11px;color:var(--g);font-weight:600;margin-bottom:6px">🚇 أقرب محطات المترو</div>'+
        px.metro_stations.map(function(m){return'<div style="display:flex;align-items:center;gap:8px;font-size:11px;color:var(--m);padding:5px 8px;border-radius:8px;background:rgba(255,255,255,.02);margin-bottom:4px"><span style="width:8px;height:8px;border-radius:50%;background:'+(m.line==='الأزرق'?'#2196f3':'#ef5350')+';flex-shrink:0"></span><span style="flex:1">'+m.name+'</span><span style="color:var(--green);font-weight:600">'+m.distance+'</span><span style="font-size:9px;color:var(--m)">'+m.year+'</span></div>'}).join('')+'</div>';
    }
    if(px.nearby_projects&&px.nearby_projects.length){
      projects='<div style="margin-bottom:8px"><div style="font-size:11px;color:var(--g);font-weight:600;margin-bottom:6px">🏗️ مشاريع كبرى قريبة</div>'+
        px.nearby_projects.map(function(m){return'<div style="display:flex;align-items:center;gap:8px;font-size:11px;color:var(--m);padding:5px 8px;border-radius:8px;background:rgba(255,255,255,.02);margin-bottom:4px"><span>'+m.name+'</span><span style="flex:1"></span><span style="color:var(--blue)">'+m.distance+'</span></div>'}).join('')+'</div>';
    }
    var growth=px.future_value_growth?('<span style="color:var(--green)">+'+px.future_value_growth+'%</span>'):'—';
    var roiColor=px.roi>7?'var(--green)':px.roi>5?'var(--g)':'var(--red)';
    var growthColor=px.future_value_growth>15?'var(--green)':px.future_value_growth>8?'var(--g)':'var(--m)';
    
    var rentalYield=px.roi||0;
    var growthRate=px.future_value_growth||0;
    var walkScore=px.walk_score||0;
    var avgRent=px.avg_rent||0;
    var pulseScore=Math.round(
      (rentalYield*0.25)+(growthRate*0.20)+(walkScore*0.15)+(walkScore*0.15)+(walkScore*0.15)+(Math.min(100,(avgRent/50000)*100)*0.10)
    );
    pulseScore=Math.min(100,Math.max(0,pulseScore));
    var scoreColor=pulseScore>70?'var(--green)':pulseScore>45?'var(--g)':'var(--red)';
    var scoreBg=pulseScore>70?'rgba(74,222,128,.12)':pulseScore>45?'rgba(212,175,55,.12)':'rgba(248,113,113,.12)';
    var scoreBorder=pulseScore>70?'rgba(74,222,128,.3)':pulseScore>45?'rgba(212,175,55,.3)':'rgba(248,113,113,.3)';
    var scoreLabel=pulseScore>70?'ممتاز':pulseScore>45?'جيد جداً':'جيد';
    
    var cards='<div style="display:grid;grid-template-columns:1fr 1fr;gap:6px;margin-bottom:8px">'+
      '<div style="padding:10px;border-radius:10px;background:rgba(8,9,14,.95);border:1px solid rgba(255,255,255,.06);text-align:center"><div style="font-size:10px;color:var(--m)">العائد الإيجاري</div><div style="font-size:16px;font-weight:700;color:'+roiColor+'">'+(px.roi||'—')+'%</div></div>'+
      '<div style="padding:10px;border-radius:10px;background:rgba(8,9,14,.95);border:1px solid rgba(255,255,255,.06);text-align:center"><div style="font-size:10px;color:var(--m)">النمو المتوقع</div><div style="font-size:16px;font-weight:700;color:'+growthColor+'">'+growth+'</div></div>'+
      (px.walk_score?'<div style="padding:10px;border-radius:10px;background:rgba(8,9,14,.95);border:1px solid rgba(255,255,255,.06);text-align:center"><div style="font-size:10px;color:var(--m)">مؤشر المشي</div><div style="font-size:16px;font-weight:700;color:var(--blue)">'+px.walk_score+'</div></div>':'')+
      (px.avg_rent?'<div style="padding:10px;border-radius:10px;background:rgba(8,9,14,.95);border:1px solid rgba(255,255,255,.06);text-align:center"><div style="font-size:10px;color:var(--m)">متوسط الإيجار/سنوياً</div><div style="font-size:13px;font-weight:700;color:var(--g)">'+fmt(px.avg_rent)+' ر.س</div></div>':'')+
    '</div>';
    var sb=px.sports_boulevard?'<div style="display:flex;align-items:center;gap:6px;padding:8px 12px;border-radius:10px;background:rgba(74,222,128,.08);border:1px solid rgba(74,222,128,.2);font-size:11px;color:var(--green);margin-bottom:8px">🏃 يمر بالحي <strong>المسار الرياضي</strong> — جودة حياة أعلى</div>':'';
    document.getElementById('pulse-card-'+p.id).innerHTML='<div class="fd"><h3>📊 مؤشر نبض الحي الذكي</h3><div style="background:rgba(8,9,14,.95);border:1px solid rgba(212,175,55,.15);border-radius:var(--r);padding:14px;animation:pulseIn .4s ease">'+
      '<div style="display:flex;align-items:center;gap:12px;margin-bottom:12px;padding:10px;border-radius:10px;background:'+scoreBg+';border:1px solid '+scoreBorder+'"><div style="width:48px;height:48px;border-radius:50%;background:'+scoreColor+';color:#05060a;font-size:18px;font-weight:800;display:flex;align-items:center;justify-content:center;flex-shrink:0">'+pulseScore+'</div><div><div style="font-size:14px;font-weight:700;color:'+scoreColor+'">مؤشر نبض الحي: '+scoreLabel+'</div><div style="font-size:10px;color:var(--m);margin-top:2px">تقييم شامل للحي بناءً على العائد، النمو، جودة الحياة</div></div></div>'+
      sb+cards+metro+projects+'<div style="font-size:9px;color:var(--m);text-align:left;margin-top:4px;padding-top:4px;border-top:1px solid rgba(255,255,255,.04)">📊 '+px.data_source+'</div></div></div>';
  }).catch(function(){document.getElementById('pulse-card-'+p.id).innerHTML=''});
}
function closeD(){destroyVT();var dp=document.getElementById('detailPage');if(dp&&document.querySelector('#detailPage .detail-page-inner')){if(history.length>1)history.back();else window.location.href='dashboard.html';return}document.getElementById('ov').classList.remove('open');document.body.style.overflow=''}

function gNav(d){
  var imgs=document.querySelectorAll('#og img'),cur=0;
  imgs.forEach(function(im,i){if(im.classList.contains('on'))cur=i});
  imgs[cur].classList.remove('on');
  var n=cur+d;if(n<0)n=imgs.length-1;if(n>=imgs.length)n=0;
  imgs[n].classList.add('on');
}
document.addEventListener('click',function(e){
  var m1=document.getElementById('mapSearchResults'),m2=document.getElementById('mapFullSearchResults'),m3=document.getElementById('map3dSearchResults');
  if(!e.target.closest('#mapSearchInput')&&!e.target.closest('#mapSearchResults')&&m1)m1.style.display='none';
  if(!e.target.closest('#mapFullSearchInput')&&!e.target.closest('#mapFullSearchResults')&&m2)m2.style.display='none';
  if(!e.target.closest('#map3dSearchInput')&&!e.target.closest('#map3dSearchResults')&&m3)m3.style.display='none';
});
var _ovEl=document.getElementById('ov');if(_ovEl)_ovEl.addEventListener('click',function(e){if(e.target===this)closeD()});
document.addEventListener('keydown',function(e){if(e.key==='Escape'){try{closeD();closeLogin();closeAIP();closeVR();closeMap();close3D();closeMapPicker();closeUpload();closeFin();closeMkt();closeLeg();closeBiz();closeAddInvoice();closeAddVendor();closeMarket();closePayOv();closeDash()}catch(err){}}});

/* MAP */
var mapPropertyId=null,mapFullMap=null,map3dInstance=null,MB_TOKEN='',_tokenPromise=null,_tokenReady=false,_mapboxLoadPromise=null,_mbProbePromise=null;

function isNight(){var h=new Date().getHours();return h<6||h>=18}
function fallbackStyle(dark){
  var tiles=dark
    ?['https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png','https://b.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png','https://c.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png']
    :['https://a.tile.openstreetmap.org/{z}/{x}/{y}.png','https://b.tile.openstreetmap.org/{z}/{x}/{y}.png','https://c.tile.openstreetmap.org/{z}/{x}/{y}.png'];
  return {version:8,name:'darak-fallback',sources:{base:{type:'raster',tiles:tiles,tileSize:256,attribution:'© OpenStreetMap contributors'}},layers:[{id:'base',type:'raster',source:'base'}]};
}
function mapStyle(){return window._mbBlocked?fallbackStyle(true):'mapbox://styles/mapbox/dark-v11'}

function probeMapbox(){
  if(window._mbBlocked!==undefined)return Promise.resolve(window._mbBlocked===false);
  if(_mbProbePromise)return _mbProbePromise;
  try{
    var cached=localStorage.getItem('mb_probe');
    if(cached){var c=JSON.parse(cached);if(Date.now()-c.t<1800000){window._mbBlocked=!!c.blocked;return Promise.resolve(!c.blocked)}}
  }catch(e){}
  _mbProbePromise=new Promise(function(res){
    var done=false;
    var ctl=('AbortController' in window)?new AbortController():null;
    function save(blocked){try{localStorage.setItem('mb_probe',JSON.stringify({blocked:blocked,t:Date.now()}))}catch(e){}}
    var t=setTimeout(function(){if(ctl)ctl.abort();if(!done){done=true;window._mbBlocked=true;save(true);res(false)}},4000);
    fetch('https://api.mapbox.com/styles/v1/mapbox/streets-v12',{signal:ctl?ctl.signal:undefined}).then(function(){
      if(!done){done=true;clearTimeout(t);window._mbBlocked=false;save(false);res(true)}
    }).catch(function(){
      if(!done){done=true;clearTimeout(t);window._mbBlocked=true;save(true);res(false)}
    });
  });
  return _mbProbePromise;
}

var _mapboxLibSources=['mapbox-gl.js','https://cdnjs.cloudflare.com/ajax/libs/mapbox-gl/2.15.0/mapbox-gl.js'];
function loadMapboxLib(){
  if(window.mapboxgl)return Promise.resolve(true);
  if(_mapboxLoadPromise)return _mapboxLoadPromise;
  _mapboxLoadPromise=new Promise(function(resolve){
    var i=0;
    function attempt(){
      if(window.mapboxgl){resolve(true);return}
      var s=document.createElement('script');
      s.src=_mapboxLibSources[i%_mapboxLibSources.length]+'?v=2';
      s.async=true;
      var done=false,t;
      function finish(ok){
        if(done)return;done=true;clearTimeout(t);
        if(!ok&&i<(_mapboxLibSources.length*2-1)){i++;setTimeout(attempt,400)}
        else resolve(!!window.mapboxgl);
      }
      s.onload=function(){finish(!!window.mapboxgl)};
      s.onerror=function(){finish(false)};
      t=setTimeout(function(){finish(false)},12000);
      document.head.appendChild(s);
    }
    attempt();
  });
  _mapboxLoadPromise.catch(function(){});
  return _mapboxLoadPromise;
}

function warmMapboxLib(){
  if(document.getElementById('mbwarm'))return;
  var w=document.createElement('div');w.id='mbwarm';w.style.display='none';document.body.appendChild(w);
  ensureToken();
}
(function(){
  function warm(){warmMapboxLib();window.removeEventListener('touchstart',warm,true);window.removeEventListener('mousemove',warm,true)}
  window.addEventListener('touchstart',warm,{passive:true});
  window.addEventListener('mousemove',warm,{passive:true});
  setTimeout(warm,300);
})();

function withMap(cid,readyFn){
  var c=document.getElementById(cid);if(!c)return;
  c.style.background='#0a0b10';
  c.innerHTML='<div style="display:flex;flex-direction:column;align-items:center;justify-content:center;height:100%;color:var(--m);font-size:13px;gap:10px;direction:rtl"><div style="font-size:28px">🗺️</div><div>جاري تحميل الخرائط...</div></div>';
  var tries=0;
  function step(){
    if(navigator.onLine===false){mapFail(cid,function(){withMap(cid,readyFn)});return}
    ensureToken().then(function(ok){
      if(ok){c.innerHTML='';readyFn();return}
      tries++;
      if(tries>=60){mapFail(cid,function(){withMap(cid,readyFn)});return}
      setTimeout(step,5000);
    });
  }
  step();
}

function ensureToken(){
  if(_tokenReady&&MB_TOKEN&&window.mapboxgl)return Promise.resolve(true);
  if(_tokenPromise)return _tokenPromise.then(function(ok){
    if(!ok&&!window.mapboxgl){_tokenPromise=null}
    return ok||(!!window.mapboxgl&&window._mbBlocked);
  });
  _tokenPromise=Promise.all([
    loadMapboxLib(),
    fetch('/api/config/mapbox').then(function(r){return r.json()}).then(function(d){
      if(d&&d.token){MB_TOKEN=d.token;if(window.mapboxgl){mapboxgl.accessToken=d.token;try{mapboxgl.setRTLTextPlugin('mapbox-gl-rtl-text.js',null,false);}catch(e){}}}
      _tokenReady=true;
      return true;
    }).catch(function(){_tokenReady=true;return true}),
    probeMapbox()
  ]).then(function(res){return !!(res[0]&&(MB_TOKEN||window._mbBlocked))});
  _tokenPromise.catch(function(){_tokenReady=true;return false});
  return _tokenPromise;
}

function mapFail(cid,retryFn){
  var c=document.getElementById(cid);if(!c)return;
  c.style.background='#0a0b10';
  c.innerHTML='<div style="display:flex;flex-direction:column;align-items:center;justify-content:center;height:100%;color:var(--m);font-size:13px;text-align:center;padding:24px;direction:rtl;gap:10px">'+
    '<div style="font-size:32px">🗺️</div>'+
    '<div>الخرائط غير متاحة حالياً — تعذر الاتصال بخدمة الخرائط.<br>تحقق من اتصالك ثم حاول مرة أخرى.</div>'+
    (retryFn?'<button id="map-retry" style="padding:10px 22px;border-radius:999px;background:linear-gradient(135deg,#d4af37,#c9a430);color:#05060a;border:none;font-weight:700;font-size:12px;cursor:pointer;font-family:inherit">🔄 إعادة المحاولة</button>':'')+'</div>';
  var b=c.querySelector('#map-retry');
  if(b)b.addEventListener('click',function(){retryFn()});
}

function createMarkerEl(p){
  var isSale=p.purpose==='بيع';
  var color=isSale?'#d4af37':'#60a5fa';
  var glow=isSale?'rgba(212,175,55,.5)':'rgba(96,165,250,.5)';
  var letter=isSale?'ب':'إ';
  var badge=p.status==='حصري'?'⭐':'';
  var el=document.createElement('div');
  el.style.cssText='position:relative;cursor:pointer;-webkit-tap-highlight-color:transparent';
  el.innerHTML='<div style="width:42px;height:42px;border-radius:50% 50% 50% 0;background:'+color+';transform:rotate(-45deg);border:3px solid #fff;box-shadow:0 3px 15px '+glow+',0 0 20px '+glow+';display:flex;align-items:center;justify-content:center;transition:transform .2s,box-shadow .2s"><span style="transform:rotate(45deg);font-size:15px;color:#05060a;font-weight:800;font-family:Cairo">'+letter+'</span></div>'+(badge?'<div style="position:absolute;top:-4px;right:-4px;font-size:12px;z-index:2">'+badge+'</div>':'');
  el.addEventListener('mouseenter',function(){this.firstChild.style.transform='rotate(-45deg) scale(1.15)';this.firstChild.style.boxShadow='0 4px 25px '+glow});
  el.addEventListener('mouseleave',function(){this.firstChild.style.transform='rotate(-45deg) scale(1)';this.firstChild.style.boxShadow='0 3px 15px '+glow});
  return el;
}

function createPropertyPopup(p){
  var img=(p.images&&p.images[0])||'';
  var imgHtml=img?'<img src="'+img+'" style="width:100%;height:110px;object-fit:cover;border-radius:10px 10px 0 0;margin:-16px -16px 10px -16px;width:calc(100% + 32px)"><div style="position:absolute;top:8px;right:8px;padding:3px 8px;border-radius:999px;font-size:10px;font-weight:700;background:'+(p.purpose==='بيع'?'rgba(74,222,128,.2)':'rgba(96,165,250,.2)')+';color:'+(p.purpose==='بيع'?'#4ade80':'#60a5fa')+';backdrop-filter:blur(8px)">'+p.purpose+'</div>':'<div style="height:8px"></div>';
  var feat='';
  if(p.features&&p.features.length){
    feat='<div style="display:flex;flex-wrap:wrap;gap:4px;margin:8px 0">'+p.features.slice(0,4).map(function(f){return'<span style="padding:2px 8px;border-radius:999px;font-size:9px;background:rgba(212,175,55,.08);border:1px solid rgba(212,175,55,.15);color:#d4af37">'+f+'</span>'}).join('')+'</div>';
  }
  return new mapboxgl.Popup({offset:30,direction:'rtl',className:'map-popup',maxWidth:'280px'}).setHTML(
    '<div style="direction:rtl;font-family:\'Cairo\',sans-serif;min-width:220px;padding:16px;line-height:1.7;position:relative">'+imgHtml+
    '<div style="font-size:15px;font-weight:700;color:#fff;margin-bottom:4px">'+p.title+'</div>'+
    '<div style="font-size:11px;color:#999;margin-bottom:6px">📍 '+pLoc(p)+'</div>'+
    '<div style="font-size:22px;font-weight:800;color:#d4af37;margin-bottom:6px">'+fmt(p.price)+' ر.س</div>'+
    '<div style="display:flex;gap:10px;margin-bottom:8px;font-size:11px;color:#aaa"><span>🛏 '+p.rooms+'</span><span>📐 '+fmt(p.area)+' م²</span><span>🚿 '+p.baths+'</span>'+(p.type==='فيلا'&&p.apartments?'<span>🏢 '+p.apartments+' شقق</span>':'')+'</div>'+
    feat+
    '<button onclick="closeMap();showDetail('+p.id+')" style="width:100%;padding:10px;border-radius:10px;background:linear-gradient(135deg,#d4af37,#b8941f);color:#05060a;border:none;font-weight:700;font-size:13px;cursor:pointer;font-family:\'Cairo\',sans-serif;transition:opacity .2s" onmouseover="this.style.opacity=\'.85\'" onmouseout="this.style.opacity=\'1\'">عرض التفاصيل</button></div>'
  );
}

function addMarkersToMap(map){
  A.forEach(function(p){
    if(!p.lat||!p.lng)return;
    var marker=new mapboxgl.Marker({element:createMarkerEl(p),anchor:'bottom'}).setLngLat([p.lng,p.lat]).setPopup(createPropertyPopup(p)).addTo(map);
    marker._propertyData=p;
  });
}

function addLegend(map){
  var legend=document.createElement('div');
  legend.style.cssText='position:absolute;bottom:80px;right:12px;z-index:10;background:rgba(14,16,24,.92);border:1px solid rgba(255,255,255,.08);border-radius:12px;padding:10px 14px;backdrop-filter:blur(12px);font-family:Cairo,sans-serif';
  var saleCount=A.filter(function(p){return p.purpose==='بيع'}).length;
  var rentCount=A.filter(function(p){return p.purpose==='إيجار'}).length;
  legend.innerHTML='<div style="font-size:10px;color:#999;margin-bottom:6px">'+(saleCount+rentCount)+' عقار</div>'+
    '<div style="display:flex;align-items:center;gap:6px;margin-bottom:4px"><div style="width:12px;height:12px;border-radius:50% 50% 50% 0;background:#d4af37;transform:rotate(-45deg)"></div><span style="font-size:11px;color:#ccc">بيع ('+saleCount+')</span></div>'+
    '<div style="display:flex;align-items:center;gap:6px"><div style="width:12px;height:12px;border-radius:50% 50% 50% 0;background:#60a5fa;transform:rotate(-45deg)"></div><span style="font-size:11px;color:#ccc">إيجار ('+rentCount+')</span></div>';
  map.getContainer().appendChild(legend);
}

function createMap(opts){
  var o={style:mapStyle(),center:[46.6753,24.7136],zoom:11};
  Object.keys(opts||{}).forEach(function(k){o[k]=opts[k]});
  var loaded=false;
  var m;
  try{
    m=new mapboxgl.Map(o);
  }catch(e){
    mapFail(o.container);
    return null;
  }
  m.addControl(new mapboxgl.NavigationControl(),'top-left');
  m.on('load',function(){
    loaded=true;
    if(!window._mbBlocked){try{m.addSource('mapbox-dem',{type:'raster-dem',url:'mapbox://mapbox.mapbox-terrain-dem-v1',tileSize:512});m.setTerrain({source:'mapbox-dem',exaggeration:1})}catch(e){};try{m.addLayer({id:'3d-buildings',source:'composite','source-layer':'building',type:'fill-extrusion',minzoom:15,paint:{'fill-extrusion-color':'#2a2d35','fill-extrusion-height':['get','height'],'fill-extrusion-base':['get','min_height'],'fill-extrusion-opacity':0.6}})}catch(e){}}
    if(opts._addMarkers!==false){addMarkersToMap(m);addLegend(m)}
    if(opts._onLoad)opts._onLoad(m);
  });
  setTimeout(function(){
    if(!loaded&&m){try{m.remove()}catch(e){};mapFail(o.container)}
  },20000);
  return m;
}

function initMapPage(){
  if(mapInstance)return;
  withMap('mapView',function(){
    if(mapInstance)return;
    if(document.getElementById('mapView'))mapInstance=createMap({container:'mapView'});
  });
}
function openMap(){
  document.getElementById('mapOverlay').classList.add('on');
  withMap('mapViewFull',function(){
    if(mapFullMap)return;
    mapFullMap=createMap({container:'mapViewFull'});
  });
}
function closeMap(){document.getElementById('mapOverlay').classList.remove('on')}

/* HEATMAP */
var heatMapInstance=null,heatMetric='density',heatData=null,heatSorted=[];
function initHeatMap(){
  if(heatMapInstance)return;
  withMap('heatMap',function(){
    if(heatMapInstance)return;
    heatMapInstance=createMap({container:'heatMap',_addMarkers:false,_onLoad:function(m){renderHeatLayer(m)}});
    heatMapInstance.on('moveend',drawHeatOverlay);
    heatMapInstance.on('zoomend',drawHeatOverlay);
    heatMapInstance.on('resize',drawHeatOverlay);
  });
}
function heatDistrictMap(){
  var map={};
  if(heatData&&heatData.districts)heatData.districts.forEach(function(d){map[(d.district||'').replace(/^(حي\s+)/,'')]=d});
  return map;
}
function heatFeatureCollection(){
  var dmap=heatDistrictMap();
  var maxW=1,pts=[];
  A.forEach(function(p){
    if(!p.lat||!p.lng)return;
    var d=dmap[(p.district||'').replace(/^(حي\s+)/,'')];
    var w=1;
    if(heatMetric==='price'){w=(d&&(d.ourAvgPrice||d.avgSale))||p.price||0}
    else if(heatMetric==='demand'){w=(d&&d.deals)||0}
    if(w>maxW)maxW=w;
    pts.push({type:'Feature',properties:{w:w},geometry:{type:'Point',coordinates:[p.lng,p.lat]}});
  });
  if(heatMetric!=='density'&&heatData&&heatData.districts){
    heatData.districts.forEach(function(d){
      if(!d.lat||!d.lng)return;
      var w=heatMetric==='price'?(d.ourAvgPrice||d.avgSale||0):(d.deals||0);
      if(w<=0)return;
      if(w>maxW)maxW=w;
      pts.push({type:'Feature',properties:{w:w},geometry:{type:'Point',coordinates:[d.lng,d.lat]}});
    });
  }
  if(maxW>0)pts.forEach(function(f){f.properties.w=Math.min(1,f.properties.w/maxW)});
  return {type:'FeatureCollection',features:pts};
}
function renderHeatLayer(m){
  try{
    if(m.getLayer('heat'))m.removeLayer('heat');
    if(m.getSource('heatSrc'))m.removeSource('heatSrc');
  }catch(e){}
  drawHeatOverlay();
  renderHeatLegend();
}
var _heatCanvas=null,_heatCtx=null;
function ensureHeatCanvas(){
  var c=document.getElementById('heatMap');
  if(!c||!heatMapInstance)return null;
  if(!_heatCanvas||!_heatCanvas.parentNode){
    _heatCanvas=document.createElement('canvas');
    _heatCanvas.className='heat-overlay';
    _heatCanvas.style.cssText='position:absolute;left:0;top:0;width:100%;height:100%;pointer-events:none;z-index:1';
    c.appendChild(_heatCanvas);
  }
  var dpr=window.devicePixelRatio||1;
  var w=c.clientWidth,h=c.clientHeight;
  if(!w||!h)return null;
  if(_heatCanvas.width!==Math.round(w*dpr)||_heatCanvas.height!==Math.round(h*dpr)){
    _heatCanvas.width=Math.round(w*dpr);
    _heatCanvas.height=Math.round(h*dpr);
  }
  _heatCtx=_heatCanvas.getContext('2d');
  return {w:w,h:h,dpr:dpr};
}
function heatRampColor(t){
  var stops=[[0,[33,102,172]],[0.2,[66,150,240]],[0.4,[60,220,180]],[0.6,[255,220,80]],[0.8,[255,140,40]],[1,[255,50,50]]];
  if(t<=0)return [33,102,172];
  if(t>=1)return [255,50,50];
  for(var i=1;i<stops.length;i++){
    if(t<=stops[i][0]){
      var a=stops[i-1],b=stops[i],f=(t-a[0])/(b[0]-a[0]);
      return [Math.round(a[1][0]+(b[1][0]-a[1][0])*f),Math.round(a[1][1]+(b[1][1]-a[1][1])*f),Math.round(a[1][2]+(b[1][2]-a[1][2])*f)];
    }
  }
  return [255,50,50];
}
function drawHeatOverlay(){
  var env=ensureHeatCanvas();
  if(!env||!_heatCtx)return;
  var ctx=_heatCtx,dpr=env.dpr,w=env.w,h=env.h;
  ctx.setTransform(1,0,0,1,0,0);
  ctx.clearRect(0,0,_heatCanvas.width,_heatCanvas.height);
  ctx.setTransform(dpr,0,0,dpr,0,0);
  var fc=heatFeatureCollection();
  var pts=[];
  if(fc&&fc.features)fc.features.forEach(function(f){
    if(!f.geometry||f.properties.w==null||!(f.properties.w>0))return;
    pts.push({c:f.geometry.coordinates,w:f.properties.w});
  });
  if(!pts.length)return;
  var zoom=heatMapInstance.getZoom();
  var radius=Math.max(24,Math.min(90,28+zoom*6));
  ctx.globalCompositeOperation='lighter';
  for(var i=0;i<pts.length;i++){
    var pr=heatMapInstance.project(pts[i].c);
    if(pr.x<-radius||pr.y<-radius||pr.x>w+radius||pr.y>h+radius)continue;
    var g=ctx.createRadialGradient(pr.x,pr.y,0,pr.x,pr.y,radius);
    g.addColorStop(0,'rgba(255,255,255,'+(0.15+0.85*pts[i].w)+')');
    g.addColorStop(0.5,'rgba(255,255,255,'+(0.05+0.4*pts[i].w)+')');
    g.addColorStop(1,'rgba(255,255,255,0)');
    ctx.fillStyle=g;
    ctx.beginPath();
    ctx.arc(pr.x,pr.y,radius,0,Math.PI*2);
    ctx.fill();
  }
  ctx.globalCompositeOperation='source-over';
  var img=ctx.getImageData(0,0,_heatCanvas.width,_heatCanvas.height);
  var data=img.data,maxA=1;
  for(var j=3;j<data.length;j+=4){if(data[j]>maxA)maxA=data[j]}
  for(var k=0;k<data.length;k+=4){
    var a=data[k+3];
    if(a<4){data[k]=0;data[k+1]=0;data[k+2]=0;data[k+3]=0;continue}
    var t=(a/255)*(255/maxA);
    var c=heatRampColor(t>1?1:t);
    data[k]=c[0];data[k+1]=c[1];data[k+2]=c[2];
  }
  ctx.putImageData(img,0,0);
}
function renderHeatLegend(){
  var el=document.getElementById('heatLegend');
  if(!el)return;
  var labels=heatMetric==='density'?['منخفض','مرتفع']:(heatMetric==='price'?['أقل سعرًا','الأعلى سعرًا']:['أقل طلبًا','الأكثر طلبًا']);
  el.innerHTML='<div style="display:flex;align-items:center;gap:8px;direction:rtl">'+
    '<span style="font-size:10px;color:var(--m)">'+labels[0]+'</span>'+
    '<div style="flex:1;height:10px;border-radius:999px;background:linear-gradient(90deg,#428ff0,#3cdcb4,#ffdc50,#ff8c28,#ff3232)"></div>'+
    '<span style="font-size:10px;color:var(--m)">'+labels[1]+'</span></div>';
}
function setHeatMetric(metric,btn){
  heatMetric=metric;
  ['density','price','demand'].forEach(function(m){
    var b=document.getElementById('heat'+m.charAt(0).toUpperCase()+m.slice(1)+'Btn');
    if(b)b.classList.remove('on');
  });
  if(btn)btn.classList.add('on');
  if(heatMapInstance){try{renderHeatLayer(heatMapInstance)}catch(e){}}
  renderHeatList();
}
function heatValue(d){
  if(heatMetric==='density')return d.ourCount||0;
  if(heatMetric==='price')return d.ourAvgPrice||d.avgSale||d.avgRent||0;
  return d.deals||d.ourCount||0;
}
function renderHeatList(){
  var el=document.getElementById('heatList');
  if(!el)return;
  if(!heatData||!heatData.districts||!heatData.districts.length){
    el.innerHTML='<div class="load">لا توجد بيانات متاحة</div>';
    var c=document.getElementById('heatCount');if(c)c.textContent='';
    return;
  }
  var c=document.getElementById('heatCount');
  if(c)c.textContent=heatData.districts.length+' حي';
  heatSorted=heatData.districts.slice().sort(function(a,b){return heatValue(b)-heatValue(a)});
  var top=heatSorted.slice(0,10),mx=Math.max(1,heatValue(heatSorted[0])||1);
  el.innerHTML=top.map(function(d,i){
    var price;
    if(heatMetric==='price'){
      price=d.ourAvgPrice?'<span style="color:var(--g);font-weight:700">'+fmt(d.ourAvgPrice)+' ر.س</span>':(d.avgSale?'<span style="color:var(--g);font-weight:700">'+fmt(d.avgSale)+' ر.س · رسمي</span>':'<span style="color:var(--m)">لا توجد بيانات</span>');
    }else{
      price='<span style="color:var(--g);font-weight:700">'+fmt(d.ourAvgPrice||d.avgSale||0)+' ر.س</span>';
    }
    var meta=[];
    if(heatMetric==='demand'&&d.deals)meta.push('📄 '+fmt(d.deals)+' عقد');
    if(d.ourCount)meta.push('🏠 '+d.ourCount+' عقار');
    if(heatMetric==='price'&&d.ourAvgPriceM2)meta.push('📐 '+fmt(d.ourAvgPriceM2)+' ر.س/م²');
    var rank=i+1;
    var pct=Math.round(heatValue(d)/mx*100);
    var grad=rank===1?'#ff3232,#d60000':rank<=3?'#ff8c28,#e05d00':'#d4af37,#b8941f';
    return '<div class="card" style="cursor:pointer" onclick="heatFlyTo('+i+')">'+
      '<div style="display:flex;align-items:center;gap:10px">'+
      '<div style="width:28px;height:28px;border-radius:8px;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#05060a;background:linear-gradient(135deg,'+grad+')">'+rank+'</div>'+
      '<div style="flex:1;min-width:0">'+
      '<div style="font-size:12px;font-weight:700;color:var(--t);white-space:nowrap;overflow:hidden;text-overflow:ellipsis">📍 '+(d.district||'حي')+'</div>'+
      (meta.length?'<div style="font-size:10px;color:var(--m);margin-top:2px">'+meta.join(' · ')+'</div>':'')+
      '</div>'+
      '<div style="text-align:left">'+price+'</div></div>'+
      '<div style="height:4px;border-radius:999px;background:rgba(255,255,255,.06);margin-top:8px"><div style="height:100%;width:'+pct+'%;border-radius:999px;background:linear-gradient(90deg,#428ff0,#3cdcb4,#ffdc50,#ff8c28,#ff3232)"></div></div>'+
      '</div>';
  }).join('');
}
function heatFlyTo(i){
  var d=heatSorted[i];
  if(!d)return;
  if(d.lat&&d.lng&&heatMapInstance){heatMapInstance.flyTo({center:[d.lng,d.lat],zoom:13,duration:1500})}
  var c=document.getElementById('heatMap');
  if(c)c.scrollIntoView({behavior:'smooth',block:'start'});
}
function loadHeatData(){
  api('/heatmap').then(function(d){
    if(d&&d.success&&d.districts){
      heatData=d;
      renderHeatList();
      if(heatMapInstance){try{renderHeatLayer(heatMapInstance)}catch(e){}}
    }else{
      var el=document.getElementById('heatList');
      if(el)el.innerHTML='<div class="load">تعذر تحميل بيانات الأحياء — أعد المحاولة</div>';
    }
  }).catch(function(){
    var el=document.getElementById('heatList');
    if(el)el.innerHTML='<div class="load">خطأ في تحميل بيانات الأحياء</div>';
  });
}

/* 3D VIEW */
function open3DBuild(p){
  if(map3dInstance){map3dInstance.remove();map3dInstance=null}
  var area=p.area||300;
  var side=(Math.sqrt(area)/111000)*(Math.cos(p.lat*Math.PI/180)||1);
  var s=side/2;
  var plotGeoJSON={type:'Feature',properties:{title:p.title,type:p.type,area:p.area},geometry:{type:'Polygon',coordinates:[[[p.lng-s,p.lat-s],[p.lng+s,p.lat-s],[p.lng+s,p.lat+s],[p.lng-s,p.lat+s],[p.lng-s,p.lat-s]]]}};
  map3dInstance=createMap({container:'map3d',center:[p.lng,p.lat],zoom:17,pitch:60,bearing:-20,_addMarkers:false,_onLoad:function(m){
    m.addSource('plot',{type:'geojson',data:plotGeoJSON});
    m.addLayer({id:'plot-3d',type:'fill-extrusion',source:'plot',paint:{'fill-extrusion-color':'#d4af37','fill-extrusion-height':15,'fill-extrusion-opacity':0.85}});
    m.flyTo({center:[p.lng,p.lat],zoom:17,pitch:65,bearing:-30,duration:2000});
  }});
}
function open3D(p){
  if(!p||!p.lat||!p.lng)return;
  document.getElementById('ov3d').classList.add('on');
  withMap('map3d',function(){open3DBuild(p)});
}
function close3D(){document.getElementById('ov3d').classList.remove('on');if(map3dInstance){map3dInstance.remove();map3dInstance=null}}

/* MAP PICKER */
var mapPickerInstance=null,mapPickerMarker=null;
function openMapPicker(){
  document.getElementById('mapPickerOv').classList.add('on');
  withMap('mapPicker',function(){
    if(mapPickerInstance){mapPickerInstance.remove();mapPickerInstance=null}
    var lat=parseFloat(document.getElementById('ap-lat').value)||24.7136;
    var lng=parseFloat(document.getElementById('ap-lng').value)||46.6753;
    mapPickerInstance=createMap({container:'mapPicker',center:[lng,lat],zoom:14,_addMarkers:false});
    mapPickerInstance.on('click',function(e){
      var c=e.lngLat;
      if(mapPickerMarker)mapPickerMarker.remove();
      var el=document.createElement('div');
      el.style.cssText='width:30px;height:30px;border-radius:50% 50% 50% 0;background:#d4af37;transform:rotate(-45deg);border:3px solid #fff;box-shadow:0 2px 10px rgba(0,0,0,.5);display:flex;align-items:center;justify-content:center';
      el.innerHTML='<span style="transform:rotate(45deg);font-size:14px">📍</span>';
      mapPickerMarker=new mapboxgl.Marker({element:el}).setLngLat([c.lng,c.lat]).addTo(mapPickerInstance);
      document.getElementById('mapPickerInfo').innerHTML='<span style="color:#d4af37;font-weight:700">📍 '+c.lat.toFixed(5)+' , '+c.lng.toFixed(5)+'</span>';
      mapPickerMarker._lngLat=c;
    });
    if(parseFloat(document.getElementById('ap-lat').value)){
      var el2=document.createElement('div');
      el2.style.cssText='width:30px;height:30px;border-radius:50% 50% 50% 0;background:#d4af37;transform:rotate(-45deg);border:3px solid #fff;box-shadow:0 2px 10px rgba(0,0,0,.5);display:flex;align-items:center;justify-content:center';
      el2.innerHTML='<span style="transform:rotate(45deg);font-size:14px">📍</span>';
      mapPickerMarker=new mapboxgl.Marker({element:el2}).setLngLat([lng,lat]).addTo(mapPickerInstance);
      document.getElementById('mapPickerInfo').innerHTML='<span style="color:#d4af37;font-weight:700">📍 '+lat.toFixed(5)+' , '+lng.toFixed(5)+'</span>';
    }
  });
}
function confirmMapPicker(){
  if(mapPickerMarker&&mapPickerMarker._lngLat){
    var c=mapPickerMarker._lngLat;
    document.getElementById('ap-lat').value=c.lat;
    document.getElementById('ap-lng').value=c.lng;
    document.getElementById('ap-loc-display').textContent=c.lat.toFixed(5)+' , '+c.lng.toFixed(5);
    toast('تم تحديد الموقع ✓');
  }
  closeMapPicker();
}
function closeMapPicker(){document.getElementById('mapPickerOv').classList.remove('on');if(mapPickerInstance){mapPickerInstance.remove();mapPickerInstance=null}}

/* MAP SEARCH & LOCATE */
function getActiveMap(resultsId){
  if(resultsId==='map3dSearchResults')return map3dInstance;
  if(resultsId==='mapFullSearchResults')return mapFullMap;
  return mapInstance;
}

async function doMapSearch(query,resultsId,inputId){
  var res=document.getElementById(resultsId);
  if(!query||query.length<1){res.style.display='none';return}
  var html='';

  var props=A.filter(function(p){
    var q=query.toLowerCase();
    return(p.title&&p.title.indexOf(q)>-1)||(p.loc&&p.loc.indexOf(q)>-1)||(p.city&&p.city.indexOf(q)>-1)||(p.district&&p.district.indexOf(q)>-1)||(p.type&&p.type.indexOf(q)>-1);
  });
  if(props.length){
    html+='<div style="padding:8px 14px;font-size:10px;color:#999;font-weight:600;border-bottom:1px solid rgba(255,255,255,.06)">🏠 العقارات ('+props.length+')</div>';
    html+=props.slice(0,5).map(function(p){
      return'<div style="padding:10px 14px;cursor:pointer;border-bottom:1px solid rgba(255,255,255,.04);transition:background .15s" onmouseover="this.style.background=\'rgba(212,175,55,.08)\'" onmouseout="this.style.background=\'transparent\'" onclick="mapSelectProp('+p.id+',\''+resultsId+'\')"><div style="font-size:12px;font-weight:600;color:#fff">🏠 '+p.title+'</div><div style="font-size:10px;color:#999;margin-top:2px">📍 '+pLoc(p)+' — <span style="color:#d4af37;font-weight:700">'+fmt(p.price)+' ر.س</span></div></div>';
    }).join('');
  }

  if(MB_TOKEN&&query.length>=2){
    try{
      var r=await fetch('https://api.mapbox.com/geocoding/v5/mapbox.places/'+encodeURIComponent(query)+'.json?access_token='+MB_TOKEN+'&language=ar&limit=5&country=sa');
      var d=await r.json();
      if(d.features&&d.features.length){
        if(html)html+='<div style="padding:8px 14px;font-size:10px;color:#999;font-weight:600;border-bottom:1px solid rgba(255,255,255,.06)">📍 الأماكن</div>';
        html+=d.features.map(function(f,i){
          return'<div style="padding:10px 14px;cursor:pointer;border-bottom:1px solid rgba(255,255,255,.04);transition:background .15s" onmouseover="this.style.background=\'rgba(96,165,250,.08)\'" onmouseout="this.style.background=\'transparent\'" onclick="mapSelectPlace('+f.center[1]+','+f.center[0]+',\''+resultsId+'\')"><div style="font-size:12px;font-weight:600;color:#fff">📍 '+f.place_name+'</div><div style="font-size:10px;color:#999;margin-top:2px">'+f.center[1].toFixed(4)+' , '+f.center[0].toFixed(4)+'</div></div>';
        }).join('');
      }
    }catch(e){}
  }

  if(!html){html='<div style="padding:14px;color:#999;font-size:12px;text-align:center">لا توجد نتائج لـ "'+query+'"</div>'}
  res.innerHTML=html;
  res.style.display='block';
}

function mapSelectProp(id,resultsId){
  document.getElementById(resultsId).style.display='none';
  var p=A.find(function(x){return x.id===id});
  if(!p)return;
  var map=getActiveMap(resultsId);
  if(map){map.flyTo({center:[p.lng,p.lat],zoom:16,duration:1500})}
  setTimeout(function(){showDetail(id)},800);
}
function mapSelectPlace(lat,lng,resultsId){
  document.getElementById(resultsId).style.display='none';
  var map=getActiveMap(resultsId);
  if(map){map.flyTo({center:[lng,lat],zoom:14,duration:1500})}
}

var _mapSearchTimer=null;
function mapSearchDebounced(){clearTimeout(_mapSearchTimer);_mapSearchTimer=setTimeout(mapSearchNow,400)}
function mapSearchNow(){doMapSearch(document.getElementById('mapSearchInput').value,'mapSearchResults','mapSearchInput')}
var _mapFullSearchTimer=null;
function mapFullSearchDebounced(){clearTimeout(_mapFullSearchTimer);_mapFullSearchTimer=setTimeout(mapFullSearchNow,400)}
function mapFullSearchNow(){doMapSearch(document.getElementById('mapFullSearchInput').value,'mapFullSearchResults','mapFullSearchInput')}
var _map3dSearchTimer=null;
function map3dSearchDebounced(){clearTimeout(_map3dSearchTimer);_map3dSearchTimer=setTimeout(map3dSearchNow,400)}
function map3dSearchNow(){doMapSearch(document.getElementById('map3dSearchInput').value,'map3dSearchResults','map3dSearchInput')}
function map3dLocateMe(){
  if(!navigator.geolocation){toast('المتصفح لا يدعم تحديد الموقع');return}
  toast('جاري تحديد موقعك...');
  navigator.geolocation.getCurrentPosition(function(pos){
    var lat=pos.coords.latitude,lng=pos.coords.longitude;
    if(map3dInstance){map3dInstance.flyTo({center:[lng,lat],zoom:17,pitch:60,duration:1500})}
    var el=document.createElement('div');
    el.style.cssText='width:20px;height:20px;border-radius:50%;background:#60a5fa;border:3px solid #fff;box-shadow:0 0 15px rgba(96,165,250,.6)';
    new mapboxgl.Marker({element:el}).setLngLat([lng,lat]).addTo(map3dInstance);
    toast('تم تحديد موقعك ✓');
  },function(){toast('تعذر تحديد الموقع — تأكد من الأذن')},{enableHighAccuracy:true,timeout:8000});
}

function mapLocateMe(){
  if(!navigator.geolocation){toast('المتصفح لا يدعم تحديد الموقع');return}
  toast('جاري تحديد موقعك...');
  navigator.geolocation.getCurrentPosition(function(pos){
    var lat=pos.coords.latitude,lng=pos.coords.longitude;
    if(mapInstance){mapInstance.flyTo({center:[lng,lat],zoom:14,duration:1500})}
    var el=document.createElement('div');
    el.style.cssText='width:20px;height:20px;border-radius:50%;background:#60a5fa;border:3px solid #fff;box-shadow:0 0 15px rgba(96,165,250,.6)';
    new mapboxgl.Marker({element:el}).setLngLat([lng,lat]).addTo(mapInstance);
    toast('تم تحديد موقعك ✓');
  },function(){toast('تعذر تحديد الموقع — تأكد من الأذن')},{enableHighAccuracy:true,timeout:8000});
}
function mapFullLocateMe(){
  if(!navigator.geolocation){toast('المتصفح لا يدعم تحديد الموقع');return}
  toast('جاري تحديد موقعك...');
  navigator.geolocation.getCurrentPosition(function(pos){
    var lat=pos.coords.latitude,lng=pos.coords.longitude;
    if(mapFullMap){mapFullMap.flyTo({center:[lng,lat],zoom:14,duration:1500})}
    var el=document.createElement('div');
    el.style.cssText='width:20px;height:20px;border-radius:50%;background:#60a5fa;border:3px solid #fff;box-shadow:0 0 15px rgba(96,165,250,.6)';
    new mapboxgl.Marker({element:el}).setLngLat([lng,lat]).addTo(mapFullMap);
    toast('تم تحديد موقعك ✓');
  },function(){toast('تعذر تحديد الموقع — تأكد من الأذن')},{enableHighAccuracy:true,timeout:8000});
}

/* 3D MAP + NEIGHBORHOODS + FILTERS + SIDEBAR */
var map3dInstance2=null,map3dMarkers2=[],map3dSelectedArea='',map3dSidebarOpen=false,map3dNeighborhoodSource='riyadh-neighborhoods';

function clearSelectedArea(){map3dSelectedArea='';document.getElementById('mapSelectedArea').style.display='none';loadMapAds()}
function toggleSidebar(){map3dSidebarOpen=!map3dSidebarOpen;document.getElementById('mapSidebar').style.display=map3dSidebarOpen?'block':'none'}
function mapFilterChanged(){loadMapAds()}

var map3dNeighborhoods={
  type:'FeatureCollection',
  features:[
    /* NORTH */
    {type:'Feature',properties:{name:'النرجس',dir:'شمال',color:'#4ade80'},geometry:{type:'Polygon',coordinates:[[[46.700,24.900],[46.720,24.905],[46.725,24.890],[46.705,24.885],[46.700,24.900]]]}},
    {type:'Feature',properties:{name:'الفلاح',dir:'شمال',color:'#4ade80'},geometry:{type:'Polygon',coordinates:[[[46.680,24.895],[46.700,24.900],[46.705,24.885],[46.685,24.880],[46.680,24.895]]]}},
    {type:'Feature',properties:{name:'الربيع',dir:'شمال',color:'#4ade80'},geometry:{type:'Polygon',coordinates:[[[46.660,24.890],[46.680,24.895],[46.685,24.880],[46.665,24.875],[46.660,24.890]]]}},
    {type:'Feature',properties:{name:'الياسمين',dir:'شمال',color:'#4ade80'},geometry:{type:'Polygon',coordinates:[[[46.720,24.880],[46.735,24.885],[46.740,24.870],[46.725,24.865],[46.720,24.880]]]}},
    {type:'Feature',properties:{name:'الوادي',dir:'شمال',color:'#4ade80'},geometry:{type:'Polygon',coordinates:[[[46.740,24.895],[46.755,24.900],[46.760,24.885],[46.745,24.880],[46.740,24.895]]]}},
    {type:'Feature',properties:{name:'الغدير',dir:'شمال',color:'#4ade80'},geometry:{type:'Polygon',coordinates:[[[46.755,24.880],[46.770,24.885],[46.775,24.870],[46.760,24.865],[46.755,24.880]]]}},
    {type:'Feature',properties:{name:'حطين',dir:'شمال',color:'#4ade80'},geometry:{type:'Polygon',coordinates:[[[46.680,24.870],[46.695,24.875],[46.700,24.860],[46.685,24.855],[46.680,24.870]]]}},
    {type:'Feature',properties:{name:'النفل',dir:'شمال',color:'#4ade80'},geometry:{type:'Polygon',coordinates:[[[46.695,24.875],[46.710,24.880],[46.715,24.865],[46.700,24.860],[46.695,24.875]]]}},
    {type:'Feature',properties:{name:'الملقا',dir:'شمال',color:'#4ade80'},geometry:{type:'Polygon',coordinates:[[[46.650,24.875],[46.665,24.880],[46.670,24.865],[46.655,24.860],[46.650,24.875]]]}},
    {type:'Feature',properties:{name:'العارض',dir:'شمال',color:'#4ade80'},geometry:{type:'Polygon',coordinates:[[[46.665,24.860],[46.680,24.865],[46.685,24.850],[46.670,24.845],[46.665,24.860]]]}},
    {type:'Feature',properties:{name:'الصحافة',dir:'شمال',color:'#4ade80'},geometry:{type:'Polygon',coordinates:[[[46.640,24.860],[46.655,24.865],[46.660,24.850],[46.645,24.845],[46.640,24.860]]]}},
    {type:'Feature',properties:{name:'القيروان',dir:'شمال',color:'#4ade80'},geometry:{type:'Polygon',coordinates:[[[46.710,24.865],[46.725,24.870],[46.730,24.855],[46.715,24.850],[46.710,24.865]]]}},
    {type:'Feature',properties:{name:'الندى',dir:'شمال',color:'#4ade80'},geometry:{type:'Polygon',coordinates:[[[46.725,24.870],[46.740,24.875],[46.745,24.860],[46.730,24.855],[46.725,24.870]]]}},
    {type:'Feature',properties:{name:'العقيق',dir:'شمال',color:'#4ade80'},geometry:{type:'Polygon',coordinates:[[[46.745,24.865],[46.760,24.870],[46.765,24.855],[46.750,24.850],[46.745,24.865]]]}},
    {type:'Feature',properties:{name:'الخير',dir:'شمال',color:'#4ade80'},geometry:{type:'Polygon',coordinates:[[[46.620,24.870],[46.635,24.875],[46.640,24.860],[46.625,24.855],[46.620,24.870]]]}},
    {type:'Feature',properties:{name:'جامعة الامام',dir:'شمال',color:'#4ade80'},geometry:{type:'Polygon',coordinates:[[[46.690,24.840],[46.710,24.845],[46.715,24.830],[46.695,24.825],[46.690,24.840]]]}},
    {type:'Feature',properties:{name:'بنيان',dir:'شمال',color:'#4ade80'},geometry:{type:'Polygon',coordinates:[[[46.635,24.845],[46.650,24.850],[46.655,24.835],[46.640,24.830],[46.635,24.845]]]}},
    /* SOUTH */
    {type:'Feature',properties:{name:'الشفاء',dir:'جنوب',color:'#60a5fa'},geometry:{type:'Polygon',coordinates:[[[46.710,24.600],[46.730,24.605],[46.735,24.585],[46.715,24.580],[46.710,24.600]]]}},
    {type:'Feature',properties:{name:'بدر',dir:'جنوب',color:'#60a5fa'},geometry:{type:'Polygon',coordinates:[[[46.690,24.600],[46.710,24.605],[46.715,24.585],[46.695,24.580],[46.690,24.600]]]}},
    {type:'Feature',properties:{name:'العزيزية',dir:'جنوب',color:'#60a5fa'},geometry:{type:'Polygon',coordinates:[[[46.730,24.585],[46.750,24.590],[46.755,24.570],[46.735,24.565],[46.730,24.585]]]}},
    {type:'Feature',properties:{name:'الدار البيضاء',dir:'جنوب',color:'#60a5fa'},geometry:{type:'Polygon',coordinates:[[[46.710,24.575],[46.730,24.580],[46.735,24.560],[46.715,24.555],[46.710,24.575]]]}},
    {type:'Feature',properties:{name:'المنصورة',dir:'جنوب',color:'#60a5fa'},geometry:{type:'Polygon',coordinates:[[[46.690,24.575],[46.710,24.580],[46.715,24.560],[46.695,24.555],[46.690,24.575]]]}},
    {type:'Feature',properties:{name:'نمار',dir:'جنوب',color:'#60a5fa'},geometry:{type:'Polygon',coordinates:[[[46.670,24.575],[46.690,24.580],[46.695,24.560],[46.675,24.555],[46.670,24.575]]]}},
    {type:'Feature',properties:{name:'شبرا',dir:'جنوب',color:'#60a5fa'},geometry:{type:'Polygon',coordinates:[[[46.710,24.555],[46.725,24.560],[46.730,24.545],[46.715,24.540],[46.710,24.555]]]}},
    {type:'Feature',properties:{name:'اليمامة',dir:'جنوب',color:'#60a5fa'},geometry:{type:'Polygon',coordinates:[[[46.690,24.555],[46.710,24.560],[46.715,24.545],[46.695,24.540],[46.690,24.555]]]}},
    {type:'Feature',properties:{name:'الحاير',dir:'جنوب',color:'#60a5fa'},geometry:{type:'Polygon',coordinates:[[[46.650,24.545],[46.670,24.550],[46.675,24.530],[46.655,24.525],[46.650,24.545]]]}},
    {type:'Feature',properties:{name:'الشعلان',dir:'جنوب',color:'#60a5fa'},geometry:{type:'Polygon',coordinates:[[[46.730,24.545],[46.745,24.550],[46.750,24.535],[46.735,24.530],[46.730,24.545]]]}},
    {type:'Feature',properties:{name:'الدريهمية',dir:'جنوب',color:'#60a5fa'},geometry:{type:'Polygon',coordinates:[[[46.670,24.555],[46.690,24.560],[46.695,24.545],[46.675,24.540],[46.670,24.555]]]}},
    {type:'Feature',properties:{name:'المروة',dir:'جنوب',color:'#60a5fa'},geometry:{type:'Polygon',coordinates:[[[46.670,24.595],[46.690,24.600],[46.695,24.585],[46.675,24.580],[46.670,24.595]]]}},
    {type:'Feature',properties:{name:'الفواز',dir:'جنوب',color:'#60a5fa'},geometry:{type:'Polygon',coordinates:[[[46.650,24.590],[46.670,24.595],[46.675,24.580],[46.655,24.575],[46.650,24.590]]]}},
    {type:'Feature',properties:{name:'الحزم',dir:'جنوب',color:'#60a5fa'},geometry:{type:'Polygon',coordinates:[[[46.650,24.575],[46.670,24.580],[46.675,24.565],[46.655,24.560],[46.650,24.575]]]}},
    {type:'Feature',properties:{name:'المصانع',dir:'جنوب',color:'#60a5fa'},geometry:{type:'Polygon',coordinates:[[[46.730,24.565],[46.750,24.570],[46.755,24.555],[46.735,24.550],[46.730,24.565]]]}},
    {type:'Feature',properties:{name:'بن تركي',dir:'جنوب',color:'#60a5fa'},geometry:{type:'Polygon',coordinates:[[[46.710,24.540],[46.725,24.545],[46.730,24.530],[46.715,24.525],[46.710,24.540]]]}},
    {type:'Feature',properties:{name:'الشميسي',dir:'جنوب',color:'#60a5fa'},geometry:{type:'Polygon',coordinates:[[[46.690,24.540],[46.710,24.545],[46.715,24.530],[46.695,24.525],[46.690,24.540]]]}},
    /* EAST */
    {type:'Feature',properties:{name:'اليرموك',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.740,24.710],[46.755,24.715],[46.760,24.700],[46.745,24.695],[46.740,24.710]]]}},
    {type:'Feature',properties:{name:'النسيم الشرقي',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.770,24.700],[46.790,24.705],[46.795,24.685],[46.775,24.680],[46.770,24.700]]]}},
    {type:'Feature',properties:{name:'النسيم الغربي',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.750,24.700],[46.770,24.705],[46.775,24.685],[46.755,24.680],[46.750,24.700]]]}},
    {type:'Feature',properties:{name:'النهضة',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.790,24.705],[46.810,24.710],[46.815,24.690],[46.795,24.685],[46.790,24.705]]]}},
    {type:'Feature',properties:{name:'غرناطة',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.735,24.695],[46.750,24.700],[46.755,24.685],[46.740,24.680],[46.735,24.695]]]}},
    {type:'Feature',properties:{name:'السلي',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.755,24.685],[46.770,24.690],[46.775,24.675],[46.760,24.670],[46.755,24.685]]]}},
    {type:'Feature',properties:{name:'اشبيليا',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.770,24.675],[46.785,24.680],[46.790,24.665],[46.775,24.660],[46.770,24.675]]]}},
    {type:'Feature',properties:{name:'الروضة',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.750,24.670],[46.765,24.675],[46.770,24.660],[46.755,24.655],[46.750,24.670]]]}},
    {type:'Feature',properties:{name:'الريان',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.765,24.660],[46.780,24.665],[46.785,24.650],[46.770,24.645],[46.765,24.660]]]}},
    {type:'Feature',properties:{name:'قرطبة',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.735,24.680],[46.750,24.685],[46.755,24.670],[46.740,24.665],[46.735,24.680]]]}},
    {type:'Feature',properties:{name:'السلام',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.790,24.680],[46.805,24.685],[46.810,24.670],[46.795,24.665],[46.790,24.680]]]}},
    {type:'Feature',properties:{name:'المونسية',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.785,24.690],[46.800,24.695],[46.805,24.680],[46.790,24.675],[46.785,24.690]]]}},
    {type:'Feature',properties:{name:'الرمال',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.805,24.690],[46.820,24.695],[46.825,24.680],[46.810,24.675],[46.805,24.690]]]}},
    {type:'Feature',properties:{name:'الفيحاء',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.770,24.690],[46.785,24.695],[46.790,24.680],[46.775,24.675],[46.770,24.690]]]}},
    {type:'Feature',properties:{name:'الخليج',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.755,24.695],[46.770,24.700],[46.775,24.685],[46.760,24.680],[46.755,24.695]]]}},
    {type:'Feature',properties:{name:'النظيم',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.790,24.710],[46.805,24.715],[46.810,24.700],[46.795,24.695],[46.790,24.710]]]}},
    {type:'Feature',properties:{name:'الروابي',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.785,24.665],[46.800,24.670],[46.805,24.655],[46.790,24.650],[46.785,24.665]]]}},
    {type:'Feature',properties:{name:'الشهداء',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.750,24.710],[46.765,24.715],[46.770,24.700],[46.755,24.695],[46.750,24.710]]]}},
    {type:'Feature',properties:{name:'الرواد',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.770,24.710],[46.785,24.715],[46.790,24.700],[46.775,24.695],[46.770,24.710]]]}},
    {type:'Feature',properties:{name:'المغرزات',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.735,24.710],[46.750,24.715],[46.755,24.700],[46.740,24.695],[46.735,24.710]]]}},
    {type:'Feature',properties:{name:'السعادة',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.755,24.675],[46.770,24.680],[46.775,24.665],[46.760,24.660],[46.755,24.675]]]}},
    {type:'Feature',properties:{name:'الحمراء',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.740,24.700],[46.755,24.705],[46.760,24.690],[46.745,24.685],[46.740,24.700]]]}},
    {type:'Feature',properties:{name:'الجزيرة',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.770,24.685],[46.785,24.690],[46.790,24.675],[46.775,24.670],[46.770,24.685]]]}},
    {type:'Feature',properties:{name:'الشعلة',dir:'شرق',color:'#fbbf24'},geometry:{type:'Polygon',coordinates:[[[46.750,24.660],[46.765,24.665],[46.770,24.650],[46.755,24.645],[46.750,24.660]]]}},
    /* WEST */
    {type:'Feature',properties:{name:'السويدي',dir:'غرب',color:'#a78bfa'},geometry:{type:'Polygon',coordinates:[[[46.650,24.650],[46.670,24.655],[46.675,24.635],[46.655,24.630],[46.650,24.650]]]}},
    {type:'Feature',properties:{name:'العارض',dir:'غرب',color:'#a78bfa'},geometry:{type:'Polygon',coordinates:[[[46.630,24.650],[46.650,24.655],[46.655,24.635],[46.635,24.630],[46.630,24.650]]]}},
    {type:'Feature',properties:{name:'لبن',dir:'غرب',color:'#a78bfa'},geometry:{type:'Polygon',coordinates:[[[46.590,24.650],[46.610,24.655],[46.615,24.635],[46.595,24.630],[46.590,24.650]]]}},
    {type:'Feature',properties:{name:'وادي لبن',dir:'غرب',color:'#a78bfa'},geometry:{type:'Polygon',coordinates:[[[46.570,24.640],[46.590,24.645],[46.595,24.625],[46.575,24.620],[46.570,24.640]]]}},
    {type:'Feature',properties:{name:'البديعة',dir:'غرب',color:'#a78bfa'},geometry:{type:'Polygon',coordinates:[[[46.610,24.655],[46.630,24.660],[46.635,24.640],[46.615,24.635],[46.610,24.655]]]}},
    {type:'Feature',properties:{name:'العريجاء',dir:'غرب',color:'#a78bfa'},geometry:{type:'Polygon',coordinates:[[[46.590,24.665],[46.610,24.670],[46.615,24.650],[46.595,24.645],[46.590,24.665]]]}},
    {type:'Feature',properties:{name:'العريجاء الغربي',dir:'غرب',color:'#a78bfa'},geometry:{type:'Polygon',coordinates:[[[46.570,24.660],[46.590,24.665],[46.595,24.645],[46.575,24.640],[46.570,24.660]]]}},
    {type:'Feature',properties:{name:'العوالي',dir:'غرب',color:'#a78bfa'},geometry:{type:'Polygon',coordinates:[[[46.630,24.670],[46.650,24.675],[46.655,24.660],[46.635,24.655],[46.630,24.670]]]}},
    {type:'Feature',properties:{name:'طويق',dir:'غرب',color:'#a78bfa'},geometry:{type:'Polygon',coordinates:[[[46.610,24.670],[46.630,24.675],[46.635,24.660],[46.615,24.655],[46.610,24.670]]]}},
    {type:'Feature',properties:{name:'ظهيرة لبن',dir:'غرب',color:'#a78bfa'},geometry:{type:'Polygon',coordinates:[[[46.560,24.655],[46.580,24.660],[46.585,24.640],[46.565,24.635],[46.560,24.655]]]}},
    {type:'Feature',properties:{name:'الناصرية',dir:'غرب',color:'#a78bfa'},geometry:{type:'Polygon',coordinates:[[[46.650,24.670],[46.665,24.675],[46.670,24.660],[46.655,24.655],[46.650,24.670]]]}},
    {type:'Feature',properties:{name:'عليشة',dir:'غرب',color:'#a78bfa'},geometry:{type:'Polygon',coordinates:[[[46.665,24.675],[46.680,24.680],[46.685,24.665],[46.670,24.660],[46.665,24.675]]]}},
    {type:'Feature',properties:{name:'الخزامى',dir:'غرب',color:'#a78bfa'},geometry:{type:'Polygon',coordinates:[[[46.640,24.665],[46.655,24.670],[46.660,24.655],[46.645,24.650],[46.640,24.665]]]}},
    {type:'Feature',properties:{name:'السفارات',dir:'غرب',color:'#a78bfa'},geometry:{type:'Polygon',coordinates:[[[46.655,24.690],[46.670,24.695],[46.675,24.680],[46.660,24.675],[46.655,24.690]]]}},
    {type:'Feature',properties:{name:'المعذر',dir:'غرب',color:'#a78bfa'},geometry:{type:'Polygon',coordinates:[[[46.655,24.675],[46.670,24.680],[46.675,24.665],[46.660,24.660],[46.655,24.675]]]}},
    {type:'Feature',properties:{name:'الشرفية',dir:'غرب',color:'#a78bfa'},geometry:{type:'Polygon',coordinates:[[[46.650,24.680],[46.665,24.685],[46.670,24.670],[46.655,24.665],[46.650,24.680]]]}},
    {type:'Feature',properties:{name:'الهدا',dir:'غرب',color:'#a78bfa'},geometry:{type:'Polygon',coordinates:[[[46.630,24.680],[46.645,24.685],[46.650,24.670],[46.635,24.665],[46.630,24.680]]]}},
    {type:'Feature',properties:{name:'سلطانة',dir:'غرب',color:'#a78bfa'},geometry:{type:'Polygon',coordinates:[[[46.590,24.675],[46.610,24.680],[46.615,24.665],[46.595,24.660],[46.590,24.675]]]}},
    {type:'Feature',properties:{name:'ظهيرة البديعة',dir:'غرب',color:'#a78bfa'},geometry:{type:'Polygon',coordinates:[[[46.610,24.680],[46.630,24.685],[46.635,24.670],[46.615,24.665],[46.610,24.680]]]}},
    /* CENTER */
    {type:'Feature',properties:{name:'العليا',dir:'وسط',color:'#f87171'},geometry:{type:'Polygon',coordinates:[[[46.685,24.730],[46.700,24.735],[46.705,24.720],[46.690,24.715],[46.685,24.730]]]}},
    {type:'Feature',properties:{name:'المربع',dir:'وسط',color:'#f87171'},geometry:{type:'Polygon',coordinates:[[[46.670,24.725],[46.685,24.730],[46.690,24.715],[46.675,24.710],[46.670,24.725]]]}},
    {type:'Feature',properties:{name:'الملز',dir:'وسط',color:'#f87171'},geometry:{type:'Polygon',coordinates:[[[46.700,24.720],[46.715,24.725],[46.720,24.710],[46.705,24.705],[46.700,24.720]]]}},
    {type:'Feature',properties:{name:'البطحاء',dir:'وسط',color:'#f87171'},geometry:{type:'Polygon',coordinates:[[[46.710,24.710],[46.725,24.715],[46.730,24.700],[46.715,24.695],[46.710,24.710]]]}},
    {type:'Feature',properties:{name:'الديرة',dir:'وسط',color:'#f87171'},geometry:{type:'Polygon',coordinates:[[[46.720,24.715],[46.735,24.720],[46.740,24.705],[46.725,24.700],[46.720,24.715]]]}},
    {type:'Feature',properties:{name:'الورود',dir:'وسط',color:'#f87171'},geometry:{type:'Polygon',coordinates:[[[46.685,24.745],[46.700,24.750],[46.705,24.735],[46.690,24.730],[46.685,24.745]]]}},
    {type:'Feature',properties:{name:'المحمدية',dir:'وسط',color:'#f87171'},geometry:{type:'Polygon',coordinates:[[[46.700,24.745],[46.715,24.750],[46.720,24.735],[46.705,24.730],[46.700,24.745]]]}},
    {type:'Feature',properties:{name:'النزهة',dir:'وسط',color:'#f87171'},geometry:{type:'Polygon',coordinates:[[[46.715,24.730],[46.730,24.735],[46.735,24.720],[46.720,24.715],[46.715,24.730]]]}},
    {type:'Feature',properties:{name:'أم الحمام',dir:'وسط',color:'#f87171'},geometry:{type:'Polygon',coordinates:[[[46.675,24.710],[46.690,24.715],[46.695,24.700],[46.680,24.695],[46.675,24.710]]]}},
    {type:'Feature',properties:{name:'المنفوحة',dir:'وسط',color:'#f87171'},geometry:{type:'Polygon',coordinates:[[[46.695,24.700],[46.710,24.705],[46.715,24.690],[46.700,24.685],[46.695,24.700]]]}},
    {type:'Feature',properties:{name:'الصالحية',dir:'وسط',color:'#f87171'},geometry:{type:'Polygon',coordinates:[[[46.700,24.695],[46.715,24.700],[46.720,24.685],[46.705,24.680],[46.700,24.695]]]}},
    {type:'Feature',properties:{name:'المزبلية',dir:'وسط',color:'#f87171'},geometry:{type:'Polygon',coordinates:[[[46.715,24.700],[46.730,24.705],[46.735,24.690],[46.720,24.685],[46.715,24.700]]]}},
    {type:'Feature',properties:{name:'المرقب',dir:'وسط',color:'#f87171'},geometry:{type:'Polygon',coordinates:[[[46.685,24.715],[46.700,24.720],[46.705,24.705],[46.690,24.700],[46.685,24.715]]]}},
    {type:'Feature',properties:{name:'الزهرة',dir:'وسط',color:'#f87171'},geometry:{type:'Polygon',coordinates:[[[46.665,24.705],[46.680,24.710],[46.685,24.695],[46.670,24.690],[46.665,24.705]]]}},
    {type:'Feature',properties:{name:'أم سليم',dir:'وسط',color:'#f87171'},geometry:{type:'Polygon',coordinates:[[[46.675,24.695],[46.690,24.700],[46.695,24.685],[46.680,24.680],[46.675,24.695]]]}},
    {type:'Feature',properties:{name:'الفاخرية',dir:'وسط',color:'#f87171'},geometry:{type:'Polygon',coordinates:[[[46.665,24.690],[46.680,24.695],[46.685,24.680],[46.670,24.675],[46.665,24.690]]]}},
    {type:'Feature',properties:{name:'الجرادية',dir:'وسط',color:'#f87171'},geometry:{type:'Polygon',coordinates:[[[46.680,24.700],[46.695,24.705],[46.700,24.690],[46.685,24.685],[46.680,24.700]]]}},
    {type:'Feature',properties:{name:'سكيرينة',dir:'وسط',color:'#f87171'},geometry:{type:'Polygon',coordinates:[[[46.690,24.685],[46.705,24.690],[46.710,24.675],[46.695,24.670],[46.690,24.685]]]}},
    {type:'Feature',properties:{name:'العود',dir:'وسط',color:'#f87171'},geometry:{type:'Polygon',coordinates:[[[46.705,24.685],[46.720,24.690],[46.725,24.675],[46.710,24.670],[46.705,24.685]]]}},
    {type:'Feature',properties:{name:'ديراب',dir:'غرب',color:'#a78bfa'},geometry:{type:'Polygon',coordinates:[[[46.550,24.630],[46.570,24.635],[46.575,24.615],[46.555,24.610],[46.550,24.630]]]}}
  ]
};

function initMap3d(){
  if(map3dInstance2)return;
  withMap('map3dView',function(){
    if(map3dInstance2)return;
    var loaded=false;
    try{
      map3dInstance2=new mapboxgl.Map({
        container:'map3dView',
        style:mapStyle(),
        center:[46.738586,24.774265],
        zoom:11,
        pitch:60,
        bearing:-17.6
      });
    }catch(e){
      mapFail('map3dView',function(){initMap3d()});
      return;
    }
    map3dInstance2.addControl(new mapboxgl.NavigationControl(),'top-left');
    map3dInstance2.on('load',function(){
      loaded=true;
      if(!window._mbBlocked){try{map3dInstance2.addSource('mapbox-dem',{type:'raster-dem',url:'mapbox://mapbox.mapbox-terrain-dem-v1',tileSize:512});map3dInstance2.setTerrain({source:'mapbox-dem',exaggeration:1})}catch(e){};try{map3dInstance2.addLayer({id:'3d-buildings',source:'composite','source-layer':'building',type:'fill-extrusion',minzoom:15,paint:{'fill-extrusion-color':'#2a2d35','fill-extrusion-height':['get','height'],'fill-extrusion-base':['get','min_height'],'fill-extrusion-opacity':0.6}})}catch(e){}}
      addNeighborhoodsLayer();
    });
    map3dInstance2.on('moveend',loadMapAdsByBounds);
    map3dInstance2.on('zoom',function(){var z=map3dInstance2.getZoom();map3dInstance2.setLayoutProperty('neighborhoods-fill','visibility',z>=11?'visible':'none');map3dInstance2.setLayoutProperty('neighborhoods-outline','visibility',z>=11?'visible':'none');map3dInstance2.setLayoutProperty('neighborhoods-labels','visibility',z>=11?'visible':'none')});
    setTimeout(loadMapAdsByBounds,1000);
    setTimeout(function(){
      if(!loaded&&map3dInstance2){try{map3dInstance2.remove()}catch(e){};map3dInstance2=null;mapFail('map3dView',function(){initMap3d()})}
    },20000)
  })
}
function addNeighborhoodsLayer(){
  if(map3dInstance2.getSource(map3dNeighborhoodSource))return;
  map3dInstance2.addSource(map3dNeighborhoodSource,{type:'geojson',data:map3dNeighborhoods});
  map3dInstance2.addLayer({id:'neighborhoods-fill',type:'fill',source:map3dNeighborhoodSource,paint:{'fill-color':['get','color'],'fill-opacity':0.2}});
  map3dInstance2.addLayer({id:'neighborhoods-outline',type:'line',source:map3dNeighborhoodSource,paint:{'line-color':['get','color'],'line-width':1.5,'line-opacity':0.6}});
  map3dInstance2.addLayer({id:'neighborhoods-labels',type:'symbol',source:map3dNeighborhoodSource,layout:{'text-field':['get','name'],'text-font':['Cairo Regular'],'text-size':10,'text-offset':[0,-0.5]},paint:{'text-color':'#fff','text-halo-color':'rgba(0,0,0,.8)','text-halo-width':1}});
  map3dInstance2.on('click','neighborhoods-fill',function(e){var f=e.features[0];if(f){selectMapArea(f.properties.name);fetchNeighborhoodPulse(f.properties.name)}});
  map3dInstance2.on('mouseenter','neighborhoods-fill',function(){map3dInstance2.getCanvas().style.cursor='pointer'});
  map3dInstance2.on('mouseleave','neighborhoods-fill',function(){map3dInstance2.getCanvas().style.cursor=''});
}
function selectMapArea(name){
  map3dSelectedArea=name;
  document.getElementById('mapSelectedArea').style.display='block';
  document.getElementById('mapSelectedAreaName').textContent=name;
  loadMapAds();
  if(!map3dSidebarOpen)toggleSidebar();
}
async function fetchNeighborhoodPulse(name){
  try{
    var r=await fetch('/api/pulse/neighborhood/'+encodeURIComponent(name));
    var d=await r.json();
    if(d&&d.success){showPulseOnUI(d.pulse)}else{document.getElementById('mapPulseCard').style.display='none'}
  }catch(e){document.getElementById('mapPulseCard').style.display='none'}
}
function showPulseOnUI(px){
  var pulseScore=Math.round(
    ((px.roi||0)*0.25)+((px.future_value_growth||0)*0.20)+((px.walk_score||0)*0.15)+((px.walk_score||0)*0.15)+((px.walk_score||0)*0.15)+(Math.min(100,((px.avg_rent||0)/50000)*100)*0.10)
  );
  pulseScore=Math.min(100,Math.max(0,pulseScore));
  var color=pulseScore>70?'#4ade80':pulseScore>45?'#d4af37':'#f87171';
  var bg=pulseScore>70?'rgba(74,222,128,.15)':pulseScore>45?'rgba(212,175,55,.15)':'rgba(248,113,113,.15)';
  var label=pulseScore>70?'ممتاز':pulseScore>45?'جيد جداً':'جيد';
  document.getElementById('mapPulseScore').style.background=bg;
  document.getElementById('mapPulseScore').style.color=color;
  document.getElementById('mapPulseScore').textContent=pulseScore;
  document.getElementById('mapPulseLabel').textContent='📊 مؤشر نبض الحي: '+label;
  document.getElementById('mapPulseDetails').innerHTML=
    '<span style="color:'+color+'">العائد: '+(px.roi||'—')+'%</span> · '+
    'النمو: '+(px.future_value_growth||'—')+'% · '+
    'المشي: '+(px.walk_score||'—')+' · '+
    'الإيجار: '+fmt(px.avg_rent||0)+' ر.س';
  document.getElementById('mapPulseCard').style.display='block';
  document.getElementById('mapPulseOfficial').innerHTML='';
  if(px.district){
    loadOfficialForDistrict(px.district).then(function(d){
      var b=renderOfficialBlock(d);
      var el=document.getElementById('mapPulseOfficial');
      if(el&&b)el.innerHTML=b;
    });
  }
}
async function loadMapAds(){
  var type=document.getElementById('mapTypeFilter').value;
  var purpose=document.getElementById('mapPurposeFilter').value;
  var price=document.getElementById('mapPriceFilter').value;
  var url='/api/ads/search?area='+encodeURIComponent(map3dSelectedArea)+'&type='+encodeURIComponent(type)+'&purpose='+encodeURIComponent(purpose)+'&price='+encodeURIComponent(price);
  var res=await api(url);
  if(res&&res.success){renderMapMarkers(res.ads);renderMapSidebar(res.ads)}
}
async function loadMapAdsByBounds(){
  if(!map3dInstance2||map3dSelectedArea)return;
  var b=map3dInstance2.getBounds();
  if(!b)return;
  var ne=b.getNorthEast(),sw=b.getSouthWest();
  var res=await api('/api/ads/in-bounds?ne='+ne.lat+','+ne.lng+'&sw='+sw.lat+','+sw.lng);
  if(res&&res.success){renderMapMarkers(res.ads);renderMapSidebar(res.ads)}
}
function renderMapMarkers(ads){
  map3dMarkers2.forEach(function(m){m.remove()});map3dMarkers2=[];
  ads.forEach(function(p){
    if(!p.lat||!p.lng)return;
    var isSale=p.purpose==='بيع';var color=isSale?'#d4af37':'#60a5fa';var letter=isSale?'ب':'إ';
    var el=document.createElement('div');
    el.style.cssText='position:relative;cursor:pointer';
    el.innerHTML='<div style="width:36px;height:36px;border-radius:50% 50% 50% 0;background:'+color+';transform:rotate(-45deg);border:3px solid #fff;box-shadow:0 3px 10px '+color+';display:flex;align-items:center;justify-content:center"><span style="transform:rotate(45deg);font-size:13px;color:#05060a;font-weight:800;font-family:Cairo">'+letter+'</span></div>';
    var popup=new mapboxgl.Popup({offset:25,direction:'rtl'}).setHTML(
      '<div style="direction:rtl;font-family:Cairo,sans-serif;min-width:200px;padding:14px;line-height:1.6">'+
      '<div style="font-size:14px;font-weight:700;color:#fff;margin-bottom:2px">'+p.title+'</div>'+
      '<div style="font-size:10px;color:#999;margin-bottom:4px">📍 '+(p.district||'')+'، '+(p.city||'')+'</div>'+
      '<div style="font-size:18px;font-weight:800;color:#d4af37;margin-bottom:4px">'+fmt(p.price)+' ر.س</div>'+
      '<div style="display:flex;gap:8px;font-size:10px;color:#aaa;margin-bottom:6px">'+(p.rooms?'<span>🛏 '+p.rooms+'</span>':'')+(p.area?'<span>📐 '+fmt(p.area)+' م²</span>':'')+(p.baths?'<span>🚿 '+p.baths+'</span>':'')+'</div>'+
      '<button onclick="closeMap3d();showDetail('+p.id+')" style="width:100%;padding:8px;border-radius:8px;background:linear-gradient(135deg,#d4af37,#b8941f);color:#05060a;border:none;font-weight:700;font-size:12px;cursor:pointer;font-family:Cairo">عرض التفاصيل</button></div>'
    );
    var marker=new mapboxgl.Marker({element:el,anchor:'bottom'}).setLngLat([p.lng,p.lat]).setPopup(popup).addTo(map3dInstance2);
    map3dMarkers2.push(marker);
  })
}
function renderMapSidebar(ads){
  var html='';
  if(!ads.length){html='<div style="color:var(--m);text-align:center;padding:30px;font-size:12px">لا توجد عقارات في هذا النطاق</div>'}
  ads.forEach(function(p){
    var bg=p.purpose==='بيع'?'rgba(212,175,55,.12)':'rgba(96,165,250,.12)';var cl=p.purpose==='بيع'?'var(--g)':'#60a5fa';
    html+='<div onclick="showDetail('+p.id+')" style="padding:10px;border-radius:10px;background:rgba(18,20,30,.6);border:1px solid rgba(255,255,255,.04);margin-bottom:6px;cursor:pointer">'+
      '<div style="font-size:12px;font-weight:600;color:var(--t);margin-bottom:2px">'+(p.images&&p.images[0]?'<span style="font-size:10px">🏠</span> ':'')+p.title+'</div>'+
      '<div style="font-size:10px;color:var(--m);margin-bottom:2px">'+(p.district||'')+'، '+(p.city||'')+'</div>'+
      '<div style="display:flex;gap:6px;align-items:center"><span style="font-size:12px;font-weight:700;color:var(--g)">'+fmt(p.price)+' ر.س</span>'+
      '<span style="padding:2px 8px;border-radius:999px;font-size:9px;font-weight:600;background:'+bg+';color:'+cl+'">'+p.purpose+'</span>'+
      (p.rooms?'<span style="font-size:9px;color:var(--m)">🛏 '+p.rooms+'</span>':'')+
      (p.area?'<span style="font-size:9px;color:var(--m)">📐 '+fmt(p.area)+' م²</span>':'')+
      '</div></div>'
  });
  document.getElementById('mapSidebarList').innerHTML=html;
  document.getElementById('mapSidebarTitle').innerHTML='🏠 '+ads.length+' عقار'+(map3dSelectedArea?' في '+map3dSelectedArea:'');
}
function closeMap3d(){}
/* LOGIN */
function openLogin(){var el=document.getElementById('login');if(el)el.classList.add('on')}
function closeLogin(){var el=document.getElementById('login');if(el)el.classList.remove('on')}
function switchLoginTab(el,formId){
  document.querySelectorAll('.login-tab').forEach(function(t){t.classList.remove('on')});
  el.classList.add('on');
  document.getElementById('login-form').style.display=formId==='login-form'?'flex':'none';
  document.getElementById('phone-form').style.display=formId==='phone-form'?'flex':'none';
  document.getElementById('register-form').style.display=formId==='register-form'?'flex':'none';
  document.getElementById('otp-code-group').style.display='none';
  document.getElementById('otp-verify-btn').style.display='none';
  document.getElementById('otp-timer').style.display='none';
  document.getElementById('otp-send-btn').style.display='block';
  document.getElementById('otp-send-btn').textContent='إرسال كود التحقق';
  document.getElementById('otp-send-btn').disabled=false;
}
function formatOtpPhone(i){i.value=i.value.replace(/[^0-9]/g,'').slice(0,13)}
var otpTimer=null;
async function doSendOtp(){
  var ph=document.getElementById('otp-phone').value;
  if(ph.length<10){toast('أدخل رقم جوال صحيح');return}
  var btn=document.getElementById('otp-send-btn');
  btn.disabled=true;btn.textContent='جاري الإرسال...';
  try{
    var d=await api('/auth/send-otp',{method:'POST',body:JSON.stringify({phone:ph})});
    if(d&&!d.code){toast('تم إرسال الكود');document.getElementById('otp-code-group').style.display='block';document.getElementById('otp-verify-btn').style.display='block';startOtpTimer();if(d.otp){document.getElementById('otp-code').value=d.otp;var el=document.createElement('div');el.style.cssText='text-align:center;font-size:16px;color:var(--g);font-weight:700;margin-top:8px;padding:8px;border-radius:8px;background:rgba(212,175,55,.1);border:1px solid rgba(212,175,55,.3)';el.textContent='🔑 الكود التجريبي: '+d.otp;document.getElementById('otp-code-group').appendChild(el)}}
    else{toast(d.message||'فشل الإرسال');btn.disabled=false;btn.textContent='إرسال كود التحقق'}
  }catch(e){toast('فشل الإرسال');btn.disabled=false;btn.textContent='إرسال كود التحقق'}
}
function startOtpTimer(){
  var t=300;
  var el=document.getElementById('otp-timer');el.style.display='block';
  if(otpTimer)clearInterval(otpTimer);
  otpTimer=setInterval(function(){
    var m=Math.floor(t/60),s=t%60;el.textContent='⏱ '+(m<10?'0':'')+m+':'+(s<10?'0':'')+s;
    if(--t<0){clearInterval(otpTimer);el.textContent='انتهت صلاحية الكود، أعد الإرسال';document.getElementById('otp-send-btn').disabled=false;document.getElementById('otp-send-btn').textContent='إعادة إرسال'}
  },1000);
}
async function doVerifyOtp(){
  var ph=document.getElementById('otp-phone').value;
  var otp=document.getElementById('otp-code').value;
  if(!otp||otp.length<6){toast('أدخل الكود كاملاً');return}
  var btn=document.getElementById('otp-verify-btn');
  btn.disabled=true;btn.textContent='جاري التحقق...';
  try{
    var d=await api('/auth/verify-otp',{method:'POST',body:JSON.stringify({phone:ph,otp:otp})});
    if(d&&d.success){
      authToken=d.accessToken;localStorage.setItem('darak_token',d.accessToken);
      user=d.user;closeLogin();toast('مرحباً '+d.user.name+'! ✓');updateUserUI();
    }else{toast(d.message||'كود غير صحيح');btn.disabled=false;btn.textContent='تأكيد الدخول'}
  }catch(e){toast('خطأ في التحقق');btn.disabled=false;btn.textContent='تأكيد الدخول'}
}
async function doLogin(){
  var em=document.getElementById('login-email')?document.getElementById('login-email').value:'';
  var pw=document.getElementById('login-pass')?document.getElementById('login-pass').value:'';
  if(!em||!pw){toast('أدخل البريد وكلمة المرور');return}
  var d=await api('/auth/login',{method:'POST',body:JSON.stringify({email:em,password:pw})});
  if(d&&d.success){
    authToken=d.accessToken;localStorage.setItem('darak_token',d.accessToken);
    user=d.user;closeLogin();toast('مرحباً '+d.user.name+'! ✓');updateUserUI();
  }else{
    toast(d.error||'فشل تسجيل الدخول');
  }
}
async function doRegister(){
  var nm=document.getElementById('reg-name')?document.getElementById('reg-name').value:'';
  var em=document.getElementById('reg-email')?document.getElementById('reg-email').value:'';
  var ph=document.getElementById('reg-phone')?document.getElementById('reg-phone').value:'';
  var pw=document.getElementById('reg-pass')?document.getElementById('reg-pass').value:'';
  if(!nm||!em||!ph||!pw){toast('أكمل جميع الحقول');return}
  if(!document.getElementById('reg-agree').checked){toast('يجب الموافقة على الشروط القانونية');return}
  var d=await api('/auth/register',{method:'POST',body:JSON.stringify({name:nm,email:em,phone:ph,password:pw})});
  if(d&&d.success){
    authToken=d.accessToken;localStorage.setItem('darak_token',d.accessToken);
    user=d.user;closeLogin();toast('تم إنشاء الحساب بنجاح! ✓');updateUserUI();
  }else{
    toast(d.error||'فشل إنشاء الحساب');
  }
}
function doLogout(){
  if(user&&authToken)api('/auth/logout',{method:'POST',body:JSON.stringify({userId:user.id})}).catch(function(){});
  authToken=null;localStorage.removeItem('darak_token');user=null;toast('تم تسجيل الخروج');updateUserUI();nav('home');
}
function updateUserUI(){
  var h=document.querySelector('.hd .wrap');if(!h)return;
  function setTxt(id,txt){var el=document.getElementById(id);if(el)el.textContent=txt}
  function setHtml(id,html){var el=document.getElementById(id);if(el)el.innerHTML=html}
  function setDisp(id,val){var el=document.getElementById(id);if(el)el.style.display=val}
  if(user){h.innerHTML='<a href="#" onclick="nav(\'home\');return false" class="logo"><span class="logo-i">د</span> دارك وحيك</a><div style="display:flex;gap:8px"><a href="#" onclick="openNotif();return false">🔔</a><a href="#" onclick="nav(\'profile\');return false" style="background:rgba(212,175,55,.15);border-color:rgba(212,175,55,.4);color:var(--g)">👤 '+user.name+'</a></div>';
    setTxt('prof-avatar',user.name.charAt(0));
    setTxt('prof-name',user.name);
    setTxt('prof-email',user.email||'—');
    setDisp('dashLink',(user.role==='admin'||user.role==='owner')?'block':'none');
    if(authToken){api('/users/profile').then(function(r){if(r&&r.success){
      var pkgName={basic:'الأساسي',pro:'احترافي',enterprise:'مؤسسات'}[r.user.package]||(r.user.package==='free'?'مجاني':(r.user.package?'الاحترافي':'مجاني'));
      setHtml('prof-stats','<div class="prof-stat"><div class="prof-stat-v">'+r.user.favorites.length+'</div><div class="prof-stat-l">المفضلة</div></div><div class="prof-stat"><div class="prof-stat-v">'+(r.user.role==='agent'?'مكتب':'فرد')+'</div><div class="prof-stat-l">النوع</div></div><div class="prof-stat"><div class="prof-stat-v">'+(r.user.role==='admin'?'🔧':r.user.role==='owner'?'👑':'—')+'</div><div class="prof-stat-l">الصلاحية</div></div><div class="prof-stat"><div class="prof-stat-v" style="font-size:12px">'+pkgName+'</div><div class="prof-stat-l">الباقة</div></div>');
      setDisp('dashLink',(r.user.role==='admin'||r.user.role==='owner')?'block':'none')
    }}).catch(function(){})}
  }else{h.innerHTML='<a href="#" onclick="nav(\'home\');return false" class="logo"><span class="logo-i">د</span> دارك وحيك</a><div style="display:flex;gap:8px"><a href="#" onclick="openNotif();return false">🔔</a><a href="#" onclick="openLogin();return false">دخول</a></div>';
    setTxt('prof-avatar','؟');
    setTxt('prof-name','زائر');
    setTxt('prof-email','سجّل دخولك للوصول لبياناتك');
    setHtml('prof-stats','<div class="prof-stat"><div class="prof-stat-v">0</div><div class="prof-stat-l">المفضلة</div></div><div class="prof-stat"><div class="prof-stat-v">—</div><div class="prof-stat-l">الباقة</div></div>');
    setDisp('dashLink','none')
  }
}

/* NOTIFICATIONS */
async function openNotif(){
  document.getElementById('notif').classList.add('on');
  if(!authToken)return;
  var d=await api('/notifications');
  if(d&&d.success&&d.notifications.length){
    var icons={info:'📢',price:'📈',new:'🆕',alert:'⚠️'};
    document.getElementById('notifList').innerHTML=d.notifications.map(function(n){
      return'<div class="ni'+(n.isRead?'':' un')+'"><div class="nic">'+(icons[n.type]||'📢')+'</div><div><div class="ntt">'+n.title+'</div><div class="ntm">'+n.message+'</div></div></div>';
    }).join('');
  }
}
function closeNotif(){var el=document.getElementById('notif');if(el)el.classList.remove('on')}
var _notifEl=document.getElementById('notif');if(_notifEl)_notifEl.addEventListener('click',function(e){if(e.target===this)closeNotif()});

/* AI PRICE */
function openAIP(p){
  document.getElementById('aip').classList.add('on');
  document.getElementById('aip-expected').textContent='—';
  document.getElementById('aip-suitable').textContent='—';
  document.getElementById('aip-max').textContent='—';
  document.getElementById('aip-pct').textContent='—';
}
function closeAIP(){document.getElementById('aip').classList.remove('on')}
async function runAIPrice(){
  if(!currentDetail){toast('اختر عقاراً أولاً');return}
  document.getElementById('aip-expected').textContent='جاري التحليل...';
  document.getElementById('aip-suitable').textContent='—';
  document.getElementById('aip-max').textContent='—';
  document.getElementById('aip-pct').textContent='—';
  var d=await api('/ai/estimate',{method:'POST',body:JSON.stringify({
    city:currentDetail.city,type:currentDetail.type,purpose:currentDetail.purpose,
    area:currentDetail.area,rooms:currentDetail.rooms,baths:currentDetail.baths,
    features:currentDetail.features||[]
  })});
  if(d&&d.success&&d.estimation){
    var e=d.estimation;
    document.getElementById('aip-expected').textContent=e.expected?fmt(e.expected)+' ر.س':'غير متوفر';
    document.getElementById('aip-suitable').textContent=e.suitable?fmt(e.suitable)+' ر.س':'غير متوفر';
    document.getElementById('aip-max').textContent=e.maximum?fmt(e.maximum)+' ر.س':'غير متوفر';
    document.getElementById('aip-pct').textContent=e.saleChance?e.saleChance+'%':'—';
    toast('تم التحليل بنجاح ✓ ('+e.sampleSize+' عقار مشابه)');
  }else{
    var base=currentDetail.price;
    document.getElementById('aip-expected').textContent=fmt(Math.round(base*0.95))+' ر.س';
    document.getElementById('aip-suitable').textContent=fmt(Math.round(base*0.88))+' ر.س';
    document.getElementById('aip-max').textContent=fmt(Math.round(base*1.12))+' ر.س';
    document.getElementById('aip-pct').textContent=Math.round(60+Math.random()*25)+'%';
    toast('تم التحليل (بيانات محلية) ✓');
  }
}

/* AVM VALUATION */
var avmLoading=false;
function openAVM(p){
  document.getElementById('avmOv').classList.add('on');
  if(p&&p.id)runAVM(p.id);
}
function closeAVM(){document.getElementById('avmOv').classList.remove('on')}
async function runAVM(id){
  var pid=id||(currentDetail?currentDetail.id:null);
  if(!pid){toast('اختر عقاراً أولاً');return}
  if(avmLoading)return;avmLoading=true;
  document.getElementById('avm-est').textContent='جاري الحساب...';
  document.getElementById('avm-range').textContent='—';
  document.getElementById('avm-perm2').textContent='—';
  document.getElementById('avm-conf-label').textContent='—';
  document.getElementById('avm-conf-bar').style.width='0%';
  document.getElementById('avm-factors').innerHTML='<div class="load" style="padding:12px">جاري جلب النظائر والبيانات الرسمية...</div>';
  document.getElementById('avm-pricecheck').style.display='none';
  var d=await api('/avm/evaluate',{method:'POST',body:JSON.stringify({propertyId:pid})});
  avmLoading=false;
  if(d&&d.success&&d.valuation){renderAVM(d.valuation);if(currentDetail&&currentDetail.id===pid){currentDetail.expectedPrice=d.valuation.estimate;currentDetail.saleChance=d.valuation.confidence;renderDetailAVM(currentDetail)}}
  else{document.getElementById('avm-est').textContent='غير متوفر';document.getElementById('avm-factors').innerHTML='';toast(d&&d.message||'تعذر حساب التقدير')}
}
function renderAVM(v){
  var fmtV=function(x){return x==null?'—':fmt(x)+' ر.س'};
  document.getElementById('avm-est').textContent=fmtV(v.estimate);
  document.getElementById('avm-range').textContent=v.min&&v.max?fmt(v.min)+' – '+fmt(v.max)+' ر.س':'—';
  document.getElementById('avm-perm2').textContent=v.perM2?fmt(v.perM2)+' ر.س/م²':'—';
  document.getElementById('avm-conf-label').textContent=v.confidence+'% · '+v.confidenceLabel;
  document.getElementById('avm-conf-bar').style.width=v.confidence+'%';
  var fac=document.getElementById('avm-factors');
  if(v.factors&&v.factors.length){
    fac.innerHTML='<div style="font-size:11px;color:var(--m);margin-bottom:6px">مكونات التقدير</div>'+v.factors.map(function(f){
      var eff=f.effect?(' <span style="color:'+(f.effect>0?'#4ade80':'#f87171')+';font-size:10px">'+(f.effect>0?'+':'')+Math.round(f.effect*100)+'%</span>'):'';
      return'<div style="display:flex;justify-content:space-between;gap:8px;padding:6px 0;border-bottom:1px solid rgba(255,255,255,.05)"><div style="min-width:0"><div style="font-size:12px;color:var(--t)">'+f.label+eff+'</div><div style="font-size:10px;color:var(--m)">'+f.detail+'</div></div><div style="font-size:12px;color:var(--g);white-space:nowrap">'+(f.value||'')+'</div></div>'
    }).join('');
  }else{fac.innerHTML=''}
  var pc=document.getElementById('avm-pricecheck');
  if(v.priceCheck){
    pc.style.display='block';
    var col=v.priceCheck.deviation<=-5?'#4ade80':v.priceCheck.deviation<=10?'var(--g)':'#f87171';
    pc.innerHTML='<b>مقارنة بالسعر المطلوب:</b> <span style="color:'+col+';font-weight:700">'+v.priceCheck.fair+'</span> <span style="color:var(--m)">('+(v.priceCheck.deviation>0?'+':'')+v.priceCheck.deviation+'% عن التقدير)</span>';
  }else{pc.style.display='none'}
  document.getElementById('avm-note').textContent=v.dataLimited?'بيانات هذا الحي محدودة — التقدير استرشادي ومنخفض الدقة.':'تقييم آلي استرشادي، وليس تقريراً رسمياً لتثمين العقار.';
}

/* 360 VR */
var vrActive=false,vrAngle=0,vrDragging=false,vrLastX=0,vrImg=null,vrRAF=null,vrAuto=true,vrImages=[],vrCurrentIdx=0;
var vrPanoViewer=null,vrPanoFailed=false,vrPanoWatchdog=null,vrForcePano=false;
function openVR(imgs,labels){
  if(!imgs||!imgs.length){toast('لا توجد صور لهذه الجولة');return}
  if(typeof imgs==='string')imgs=[imgs];
  var prop=currentDetail||{};
  if(!vrForcePano&&(prop.tourUrl||prop.matterport||prop.tour3d)){vrTourOpen(prop.tourUrl||prop.matterport||prop.tour3d);return}
  if(!vrForcePano&&(prop.panoramicImage||prop.pano)){imgs=[prop.panoramicImage||prop.pano].concat(imgs)}
  vrImages=imgs;vrCurrentIdx=0;vrPanoFailed=false;
  document.getElementById('vr360').classList.add('on');
  var hint=document.getElementById('vrHint');
  if(hint)hint.style.display='block';
  setTimeout(function(){if(hint)hint.style.display='none'},3000);
  var rooms=document.getElementById('vrRooms');
  if(rooms)rooms.innerHTML=imgs.map(function(url,i){return'<button class="'+(i===0?'on':'')+'" onclick="vrSwitchRoom('+i+')">'+(labels&&labels[i]?labels[i]:'غرفة '+(i+1))+'</button>'}).join('');
  vrLoadImage(imgs[0]);
}
function vrTourOpen(url){
  document.getElementById('vr360').classList.add('on');
  var t=document.querySelector('#vr360 .v3t');
  if(t)t.textContent='🕶️ جولة ثلاثية الأبعاد';
  vrImages=[url];vrCurrentIdx=0;vrPanoFailed=false;vrActive=true;
  var hint=document.getElementById('vrHint');
  if(hint){hint.style.display='block';setTimeout(function(){if(hint)hint.style.display='none'},3500)}
  var rooms=document.getElementById('vrRooms');
  if(rooms)rooms.innerHTML='<button class="on">🕶️ جولة 3D</button>';
  var pano=document.getElementById('vrPano'),canvas=document.getElementById('vrCanvas');
  if(pano){
    pano.innerHTML='';
    var f=document.createElement('iframe');
    f.id='vrIframe';f.src=url;
    f.setAttribute('allow','xr-spatial-tracking;gyroscope;accelerometer;fullscreen;camera');
    f.setAttribute('allowfullscreen','');
    f.setAttribute('referrerpolicy','no-referrer-when-downgrade');
    f.style.cssText='position:absolute;inset:0;width:100%;height:100%;border:0;background:#0a0b10';
    pano.style.display='block';
    pano.appendChild(f);
  }
  if(canvas)canvas.style.display='none';
}
function vrSwitchRoom(idx){
  if(idx===vrCurrentIdx)return;
  vrCurrentIdx=idx;
  var btns=document.querySelectorAll('#vrRooms button');
  btns.forEach(function(b,i){b.classList.toggle('on',i===idx)});
  vrLoadImage(vrImages[idx]);
}
function vrPanoOpen(url){
  var container=document.getElementById('vrPano');
  if(!container||!window.pannellum)return false;
  try{
    if(vrPanoViewer){try{vrPanoViewer.destroy()}catch(e){}vrPanoViewer=null}
    vrPanoViewer=pannellum.viewer('vrPano',{
      type:'equirectangular',
      panorama:url,
      autoLoad:true,
      autoRotate:-1,
      compass:false,
      showFullscreenCtrl:true,
      crossOrigin:'anonymous',
      hfov:100
    });
    var watchdog=0,tries=0;
    clearInterval(vrPanoWatchdog);
    vrPanoWatchdog=setInterval(function(){
      tries++;
      if(!vrPanoViewer||vrPanoFailed){clearInterval(vrPanoWatchdog);return}
      var colored=false;
      try{
        var r=vrPanoViewer.getRenderer();
        r.render();
        var cnv=r.getCanvas(),gl=cnv.getContext('webgl');
        var w=gl.drawingBufferWidth,h=gl.drawingBufferHeight;
        var buf=new Uint8Array(100),o=0;
        for(var yy=1;yy<=5;yy++)for(var xx=1;xx<=5;xx++){
          gl.readPixels(Math.floor(w*xx/6),Math.floor(h*yy/6),1,1,gl.RGBA,gl.UNSIGNED_BYTE,buf.subarray(o));
          o+=4;
          if(buf[o-4]+buf[o-3]+buf[o-2]+buf[o-1]>30){colored=true;break}
        }
        if(colored){clearInterval(vrPanoWatchdog);return}
      }catch(e){}
      if(tries>=14){
        clearInterval(vrPanoWatchdog);
        vrPanoFailed=true;
        try{vrPanoViewer.destroy()}catch(e){}
        vrPanoViewer=null;
        vrPano2DFallback();
      }
    },500);
    return true;
  }catch(e){
    vrPanoFailed=true;
    if(vrPanoViewer){try{vrPanoViewer.destroy()}catch(_){}}vrPanoViewer=null;
    return false;
  }
}
function vrPano2DFallback(){
  var container=document.getElementById('vrPano');
  if(container)container.style.display='none';
  var canvas=document.getElementById('vrCanvas');
  if(canvas)canvas.style.display='block';
  vrLoadImage(vrImages[vrCurrentIdx],true);
}
function vrLoadImage(url,force2d){
  var prop=currentDetail||{};
  var isPano=!force2d&&!vrPanoFailed&&(vrForcePano||(prop.panoramicImage&&url===prop.panoramicImage)||(prop.pano&&url===prop.pano));
  var container=document.getElementById('vrPano'),canvas=document.getElementById('vrCanvas');
  if(isPano&&container&&window.pannellum){
    if(vrPanoOpen(url)){
      container.style.display='block';
      if(canvas)canvas.style.display='none';
      return;
    }
  }
  if(container)container.style.display='none';
  if(canvas)canvas.style.display='block';
  if(!vrActive&&document.getElementById('vr360').classList.contains('on'))vrActive=true;
  var c=document.getElementById('vrCanvas'),ctx=c.getContext('2d');
  c.width=window.innerWidth;c.height=window.innerHeight-100;
  var img=new Image();img.crossOrigin='anonymous';
  img.onload=function(){
    vrImg=img;
    var iW=vrImg.width,iH=vrImg.height;
    function draw(){
      if(!document.getElementById('vr360').classList.contains('on'))return;
      ctx.clearRect(0,0,c.width,c.height);
      var sx=(iW/360)*vrAngle;
      var srcW=iW/3;
      ctx.drawImage(vrImg,sx,0,srcW,iH,0,0,c.width,c.height);
      if(sx+srcW>iW){
        var over=(sx+srcW)-iW;
        ctx.drawImage(vrImg,0,0,over,iH,c.width-((over/srcW)*c.width),0,(over/srcW)*c.width,c.height);
      }
    }
    draw();
    function animate(){
      if(!document.getElementById('vr360').classList.contains('on'))return;
      if(vrAuto)vrAngle=(vrAngle+0.3)%360;
      draw();
      vrRAF=requestAnimationFrame(animate);
    }
    c.ontouchstart=function(e){vrDragging=true;vrAuto=false;vrLastX=e.touches[0].clientX;e.preventDefault()};
    c.ontouchmove=function(e){if(!vrDragging)return;vrAngle-=(e.touches[0].clientX-vrLastX)*0.5;vrLastX=e.touches[0].clientX;vrAngle=(vrAngle+360)%360;e.preventDefault()};
    c.ontouchend=function(){vrDragging=false;setTimeout(function(){vrAuto=true},2000)};
    c.onmousedown=function(e){vrDragging=true;vrAuto=false;vrLastX=e.clientX};
    c.onmousemove=function(e){if(!vrDragging)return;vrAngle-=(e.clientX-vrLastX)*0.5;vrLastX=e.clientX;vrAngle=(vrAngle+360)%360};
    c.onmouseup=function(){vrDragging=false;setTimeout(function(){vrAuto=true},2000)};
    c.onmouseleave=function(){vrDragging=false;setTimeout(function(){vrAuto=true},2000)};
    if(vrRAF)cancelAnimationFrame(vrRAF);
    animate();
  };
  img.onerror=function(){
    ctx.fillStyle='#0a0b10';ctx.fillRect(0,0,c.width,c.height);
    ctx.fillStyle='#d4af37';ctx.font='16px Cairo';ctx.textAlign='center';
    ctx.fillText('صورة غير متوفرة',c.width/2,c.height/2);
  };
  img.src=url;
}
function closeVR(){
  vrActive=false;vrImg=null;vrAuto=false;vrImages=[];vrCurrentIdx=0;vrPanoFailed=false;vrForcePano=false;
  if(vrRAF)cancelAnimationFrame(vrRAF);
  clearInterval(vrPanoWatchdog);
  if(vrPanoViewer){try{vrPanoViewer.destroy()}catch(e){}vrPanoViewer=null}
  var tf=document.getElementById('vrIframe');
  if(tf){try{tf.src='about:blank'}catch(e){}if(tf.parentNode)tf.parentNode.removeChild(tf)}
  var t=document.querySelector('#vr360 .v3t');
  if(t)t.textContent='🌐 جولة 360°';
  document.getElementById('vr360').classList.remove('on');
}

/* UPLOAD */
function openUpload(){document.getElementById('upload').classList.add('on')}
function closeUpload(){document.getElementById('upload').classList.remove('on')}
async function saveUpload(){
  if(!authToken){toast('سجّل دخول أولاً');closeUpload();openLogin();return}
  var files=document.getElementById('upl-files').files;
  var pano=document.getElementById('upl-pano').files;
  var panoUrlInput=document.getElementById('upl-pano-url');
  var panoUrl=panoUrlInput?panoUrlInput.value.trim():'';
  if(!files.length&&!pano.length&&!panoUrl){toast('اختر صوراً أولاً');return}
  var fd=new FormData();
  for(var i=0;i<files.length;i++)fd.append('images',files[i]);
  if(pano.length)fd.append('image',pano[0]);
  toast('جاري رفع الصور...');
  try{
    var r1=await fetch(API+'/upload/images',{method:'POST',headers:{'Authorization':'Bearer '+authToken},body:fd});
    var d1=await r1.json();
    if(pano.length){
      var fd2=new FormData();fd2.append('image',pano[0]);
      var up2=await fetch(API+'/upload/panoramic',{method:'POST',headers:{'Authorization':'Bearer '+authToken},body:fd2}).then(function(r){return r.json()}).catch(function(){return null});
      if(up2&&up2.success&&up2.url){panoUrl=up2.url;localStorage.setItem('darak_pano_url',up2.url)}
    }
    if(panoUrl&&/^https?:\/\//i.test(panoUrl)){
      localStorage.setItem('darak_pano_url',panoUrl);
      toast('✓ تم حفظ رابط الجولة 360°');
    }
    if(d1.success){toast('تم رفع '+d1.images.length+' صور بنجاح ✓');closeUpload()}
    else if(!pano.length&&!panoUrl){toast(d1.error||'خطأ في الرفع')}
  }catch(e){toast('خطأ في الاتصال بالخادم')}
}

/* ADS */
async function openAds(){
  document.getElementById('ads').classList.add('open');
  if(!authToken){document.getElementById('adsList').innerHTML='<div style="color:var(--m);text-align:center;padding:40px">سجّل دخولك لعرض إعلاناتك</div>';return}
  var d=await api('/my-properties');
  if(d&&d.success&&d.properties.length){
    document.getElementById('adsList').innerHTML=d.properties.map(function(p){
      var status=p.status==='active'?'🟢 نشط':p.status==='pending'?'🟡 قيد المراجعة':'🔴 '+p.status;
      return'<div class="card" style="margin-bottom:12px"><div class="card-b"><div class="card-t">'+p.title+'</div><div class="card-l">📍 '+p.loc+'</div><div class="card-p">'+pPrice(p)+'</div><div style="font-size:11px;color:var(--m)">'+status+' · 👁 '+p.views+' · ❤ '+p.favorites+'</div></div></div>';
    }).join('');
  }else{
    document.getElementById('adsList').innerHTML='<div style="color:var(--m);text-align:center;padding:40px">لا توجد إعلانات نشطة<br><small>أضف عقارك من صفحة الإضافة</small></div>';
  }
}
function closeAds(){document.getElementById('ads').classList.remove('open')}

/* PACKAGES */
async function openPkg(){
  document.getElementById('pkg').classList.add('open');
  var d=await api('/packages');
  if(d&&d.success){
    var html='<button class="cls" onclick="closePkg()">✕</button><div class="pkg" style="padding-top:44px"><div style="font-size:16px;font-weight:700;color:var(--g);margin-bottom:16px">📦 الباقة المناسبة</div>';
    d.packages.forEach(function(p){
      var featured=p.id==='pro';
      html+='<div class="pkg-card'+(featured?' featured':'')+'"><div class="pkg-name">'+p.name+(featured?' ⭐':'')+'</div><div class="pkg-price">'+(p.price===0?'مجاني':p.price+' ر.س')+' <span>/ '+p.period+'</span></div><ul class="pkg-features">'+p.features.map(function(f){return'<li>'+f+'</li>'}).join('')+'</ul>';
      if(p.price===0)html+='<button class="pkg-btn secondary">الباقة الحالية</button>';
      else if(featured)html+='<button class="pkg-btn primary" onclick="subscribePkg(\''+p.id+'\')">اشترك الآن</button>';
      else html+='<button class="pkg-btn secondary" onclick="toast(\'سيتم التواصل معك قريباً\');closePkg()">تواصل معنا</button>';
      html+='</div>';
    });
    html+='</div>';
    document.getElementById('pkg').innerHTML=html;
  }
}
async function subscribePkg(id){
  if(!authToken){toast('سجّل دخول أولاً');closePkg();openLogin();return}
  if(id==='basic'){var d=await api('/packages/subscribe',{method:'POST',body:JSON.stringify({packageId:id})});if(d&&d.success){toast('تم الاشتراك ✓');api('/auth/me').then(function(r){if(r&&r.success){user=r.user;updateUserUI()}}).catch(function(){});closePkg()}return}
  var cfg=await api('/payments/config');
  if(cfg&&cfg.publishableKey&&!cfg.testMode){
    var intent=await api('/payments/create-intent',{method:'POST',body:JSON.stringify({packageId:id})});
    if(intent&&intent.success&&intent.invoiceUrl){window.location.href=intent.invoiceUrl;return}
    toast(intent&&intent.message||'فشل إنشاء الدفعة')
  }
  openPaymentOv(id)
}
function closePkg(){document.getElementById('pkg').classList.remove('open')}
var selectedPkgId=null;
var pkgsData={basic:{name:'الأساسي',price:0},pro:{name:'الاحترافي',price:99},enterprise:{name:'المؤسسات',price:299}};
async function openPaymentOv(id){
  selectedPkgId=id;
  var p=pkgsData[id]||{name:'',price:0};
  document.getElementById('paySummary').innerText='باقة '+p.name+' · '+p.price+' ر.س/شهرياً';
  document.getElementById('payError').style.display='none';
  document.getElementById('paySpinner').style.display='none';
  var cfg=await api('/payments/config');
  if(cfg&&cfg.testMode){
    document.getElementById('payCardForm').style.display='none';
    document.getElementById('payMoyasarForm').style.display='none';
    document.getElementById('payTestNotice').style.display='block';
    document.getElementById('payBtn').style.display='block';
    document.getElementById('payBtn').textContent='✅ تفعيل الباقة تجريبياً';
  }else{
    document.getElementById('payCardForm').style.display='none';
    document.getElementById('payTestNotice').style.display='block';
    document.getElementById('payTestNotice').innerHTML='سيتم تحويلك إلى بوابة الدفع الآمنة...';
    document.getElementById('payBtn').style.display='none';
  }
  document.getElementById('payOv').classList.add('open')
}
function fillTestCard(number,exp,cvc){
  document.getElementById('pay-number').value=number.replace(/(.{4})/g,'$1 ').trim();
  document.getElementById('pay-exp').value=exp;
  document.getElementById('pay-cvc').value=cvc;
  document.getElementById('pay-name').focus()
}
var _payN=document.getElementById('pay-number'),_payE=document.getElementById('pay-exp'),_payC=document.getElementById('pay-cvc');
if(_payN)_payN.addEventListener('input',function(e){var v=e.target.value.replace(/\D/g,'');e.target.value=v.replace(/(.{4})/g,'$1 ').trim()});
if(_payE)_payE.addEventListener('input',function(e){var v=e.target.value.replace(/\D/g,'');if(v.length>2){e.target.value=v.slice(0,2)+'/'+v.slice(2,4)}else{e.target.value=v}});
if(_payC)_payC.addEventListener('input',function(e){e.target.value=e.target.value.replace(/\D/g,'')});
function closePayOv(){document.getElementById('payOv').classList.remove('open')}
async function processPayment(){
  if(!selectedPkgId)return;
  document.getElementById('payBtn').style.display='none';
  document.getElementById('payCardForm').style.display='none';
  document.getElementById('paySpinner').style.display='block';
  document.getElementById('payError').style.display='none';
  var intent=await api('/payments/create-intent',{method:'POST',body:JSON.stringify({packageId:selectedPkgId})});
  if(!intent||!intent.success){showPayErr('فشل إنشاء الدفعة');return}
  var d=await api('/payments/test-complete',{method:'POST',body:JSON.stringify({paymentId:intent.paymentId})});
  document.getElementById('paySpinner').style.display='none';
  if(d&&d.success){toast('✅ تم تفعيل الباقة تجريبياً');api('/auth/me').then(function(r){if(r&&r.success){user=r.user;updateUserUI()}}).catch(function(){});closePayOv();closePkg()}
  else{showPayErr(d&&d.message||'فشل التفعيل، حاول مرة أخرى')}
}
function showPayErr(msg){
  document.getElementById('payError').innerText=msg;
  document.getElementById('payError').style.display='block';
  document.getElementById('payBtn').style.display='block';
  document.getElementById('paySpinner').style.display='none'
}

/* DASHBOARD */
function openDash(){document.getElementById('dashOv').classList.add('open');loadDashData()}
function closeDash(){document.getElementById('dashOv').classList.remove('open')}
function showDashTab(el,id){document.querySelectorAll('#dashOv .dash-tab').forEach(function(t){t.classList.remove('on')});el.classList.add('on');document.getElementById('dashOverview').style.display=id==='dashOverview'?'block':'none';document.getElementById('dashUsers').style.display=id==='dashUsers'?'block':'none';if(id==='dashUsers')loadDashUsers()}
async function loadDashData(){
  if(!authToken)return;
  var d=await api('/dashboard/stats');
  if(!d||!d.success)return;
  document.getElementById('dashRole').innerText='مرحباً '+(d.stats.isOwner?'مالك المنصة':'مشرف')+' 👋';
  var s=d.stats;
  document.getElementById('dashStats').innerHTML=
    '<div class="dash-card"><div class="dash-card-v">'+s.users+'</div><div class="dash-card-l">👥 مستخدمين</div></div>'+
    '<div class="dash-card"><div class="dash-card-v">'+s.properties+'</div><div class="dash-card-l">🏠 عقارات</div></div>'+
    '<div class="dash-card"><div class="dash-card-v">'+s.agents+'</div><div class="dash-card-l">🏢 مكاتب</div></div>'+
    '<div class="dash-card"><div class="dash-card-v">'+s.pending+'</div><div class="dash-card-l">⏳ قيد المراجعة</div></div>'+
    '<div class="dash-card"><div class="dash-card-v">'+fmt(s.monthlyRevenue)+'</div><div class="dash-card-l">💰 شهرياً</div></div>'+
    '<div class="dash-card"><div class="dash-card-v">'+fmt(s.totalRevenue)+'</div><div class="dash-card-l">💵 إجمالي الإيرادات<small>مدفوع</small></div></div>';
  document.getElementById('dashRecentUsers').innerHTML=s.recentUsers.length?s.recentUsers.map(function(u){return'<div class="dash-row"><span style="padding:3px 6px;border-radius:6px;font-size:10px;background:rgba(255,255,255,.04)">'+(u.role==='owner'?'👑':u.role==='admin'?'🔧':u.role==='agent'?'🏢':'👤')+'</span><span style="flex:1">'+u.name+'</span><span style="font-size:10px;color:var(--m)">'+u.email+'</span></div>'}).join(''):'<div style="color:var(--m);font-size:11px">لا يوجد مستخدمين</div>';
  document.getElementById('dashRecentProps').innerHTML=s.recentProperties.length?s.recentProperties.map(function(p){return'<div class="dash-row"><span style="flex:1">'+p.title+'</span><span style="font-size:10px;color:var(--m)">'+p.district+'، '+p.city+'</span><span style="font-size:11px;color:var(--g);font-weight:700">'+fmt(p.price)+' ر.س</span></div>'}).join(''):'<div style="color:var(--m);font-size:11px">لا توجد عقارات</div>';
  document.getElementById('dashCities').innerHTML=s.cityStats.length?s.cityStats.map(function(c){return'<span class="dash-city">'+c.city+' <b>'+c.count+'</b></span>'}).join(''):'<div style="color:var(--m);font-size:11px">لا توجد بيانات</div>'
}
async function loadDashUsers(){
  if(!authToken)return;
  var d=await api('/users');
  if(!d||!d.success)return;
  var roles={owner:'👑 مالك',admin:'🔧 مشرف',agent:'🏢 وسيط',user:'👤 مستخدم'};
  var roleCls={owner:'owner',admin:'admin',agent:'agent',user:'user'};
  document.getElementById('dashUsersList').innerHTML=d.users.map(function(u){
    return'<div class="dash-row"><span style="padding:3px 6px;border-radius:6px;font-size:10px;background:rgba(255,255,255,.04)">'+(roles[u.role]||u.role)+'</span><span style="flex:1;font-weight:600">'+u.name+'</span><span style="font-size:10px;color:var(--m);flex:1">'+u.email+'</span><span class="dash-row-role '+roleCls[u.role]+'">'+u.role+'</span>'+(u.role!=='owner'?'<button class="dash-act danger" onclick="deleteUser('+u.id+')">🗑</button>':'')+(u.role==='user'?'<button class="dash-act" onclick="promoteUser('+u.id+')">👑 ترقية</button>':'')+'</div>'
  }).join('')
}
async function deleteUser(id){if(!confirm('حذف المستخدم؟'))return;var d=await api('/users/'+id,{method:'DELETE'});if(d&&d.success){toast('تم الحذف');loadDashUsers()}}
async function promoteUser(id){var r=prompt('الصلاحية الجديدة (agent/admin):');if(!r||!['agent','admin'].includes(r))return;var d=await api('/users/'+id+'/role',{method:'PUT',body:JSON.stringify({role:r})});if(d&&d.success){toast('تم الترقية ✓');loadDashUsers()}}

/* OFFICE */
function openOff(){document.getElementById('off').classList.add('open')}
function closeOff(){document.getElementById('off').classList.remove('open')}
async function submitOffice(){
  var nm=document.getElementById('off-name').value;
  var ph=document.getElementById('off-phone').value;
  var em=document.getElementById('off-email').value;
  var rg=document.getElementById('off-reg').value;
  var ct=document.getElementById('off-city').value;
  var ds=document.getElementById('off-desc').value;
  if(!nm||!ph||!em){toast('أكمل الحقول المطلوبة');return}
  if(!authToken){toast('سجّل دخول أولاً');closeOff();openLogin();return}
  var d=await api('/agents',{method:'POST',body:JSON.stringify({officeName:nm,phone:ph,email:em,commercialReg:rg||'000000',city:ct,description:ds})});
  if(d&&d.success){toast('تم تسجيل المكتب بنجاح ✓');closeOff()}
}

/* REQUEST */
function openReq(){document.getElementById('req').classList.add('open')}
function closeReq(){document.getElementById('req').classList.remove('open')}
async function submitPropertyRequest(){
  var nm=document.getElementById('req-name').value;
  var tp=document.getElementById('req-type').value;
  var ct=document.getElementById('req-city').value;
  var pr=Number(document.getElementById('req-price').value)||0;
  var nt=document.getElementById('req-notes').value;
  if(!nm){toast('أدخل اسمك');return}
  if(!authToken){toast('سجّل دخول أولاً');closeReq();openLogin();return}
  var d=await api('/property-requests',{method:'POST',body:JSON.stringify({type:tp,city:ct,maxPrice:pr,notes:nt})});
  if(d&&d.success){toast('تم إرسال الطلب بنجاح ✓');closeReq()}
}

/* FINANCE */
function openFin(){document.getElementById('finOv').classList.add('on')}
function closeFin(){document.getElementById('finOv').classList.remove('on')}
function showFinTab(el,id){document.querySelectorAll('#finOv .mkt-tab').forEach(function(t){t.classList.remove('on')});el.classList.add('on');document.getElementById('fin-analyze').style.display=id==='fin-analyze'?'block':'none';document.getElementById('fin-compare').style.display=id==='fin-compare'?'block':'none'}
async function runFinance(){
  var price=Number(document.getElementById('fin-price').value)||0;
  var rent=Number(document.getElementById('fin-rent').value)||0;
  var expenses=Number(document.getElementById('fin-expenses').value)||0;
  var down=Number(document.getElementById('fin-down').value)||30;
  var rate=Number(document.getElementById('fin-rate').value)||5;
  var years=Number(document.getElementById('fin-years').value)||20;
  if(!price){toast('أدخل سعر العقار');return}
  toast('جاري التحليل المالي...');
  var d=await api('/finance/analysis',{method:'POST',body:JSON.stringify({purchasePrice:price,monthlyRent:rent,annualExpenses:expenses,downPayment:price*down/100,loanRate:rate,loanYears:years})});
  if(d&&d.success){renderFinanceResult(d.analysis)}else{toast('خطأ في التحليل')}
}
function renderFinanceResult(a){
  var el=document.getElementById('finResult');el.style.display='block';
  var roiColor=a.roi>8?'green':a.roi>4?'':'red';
  var cfColor=a.cashFlow.monthly>0?'green':'red';
  el.innerHTML='<div class="fin-card"><div class="fin-h">📊 نتائج التحليل</div><div class="fin-grid"><div class="fin-metric big"><div class="fin-label">العائد على الاستثمار (ROI)</div><div class="fin-value '+roiColor+'">'+a.roi+'%</div><div class="fin-bar"><div class="fin-bar-fill" style="width:'+Math.min(100,a.roi*5)+'%;background:var(--g)"></div></div></div><div class="fin-metric"><div class="fin-label">الإيجار السنوي</div><div class="fin-value">'+fmt(a.annualRent)+'</div></div><div class="fin-metric"><div class="fin-label">الدخل الصافي</div><div class="fin-value">'+fmt(a.netIncome)+'</div></div><div class="fin-metric"><div class="fin-label">Cash Flow شهري</div><div class="fin-value '+cfColor+'">'+fmt(a.cashFlow.monthly)+'</div></div><div class="fin-metric"><div class="fin-label">القسط الشهري</div><div class="fin-value">'+fmt(a.cashFlow.mortgage)+'</div></div><div class="fin-metric"><div class="fin-label">فترة الاسترداد</div><div class="fin-value">'+a.paybackYears+' سنة</div></div><div class="fin-metric"><div class="fin-label">هامش الربح</div><div class="fin-value">'+a.grossMargin+'%</div></div><div class="fin-metric"><div class="fin-label">مقارنة بالسوق</div><div class="fin-value">'+(a.market.priceVsMarket>0?'+':'')+a.market.priceVsMarket+'%</div></div></div></div>';
  if(a.aiInsight){el.innerHTML+='<div class="fin-ai-box">🤖 '+a.aiInsight+'</div>'}
}
function openCompareList(){
  var el=document.getElementById('finCompareList');
  if(!A.length){el.innerHTML='<div style="color:var(--m);text-align:center;padding:20px">لا توجد عقارات</div>';return}
  el.innerHTML=A.slice(0,20).map(function(p){return'<div class="fin-compare-item" data-id="'+p.id+'" onclick="toggleCompareItem(this)"><div class="fin-compare-check">✓</div><div style="flex:1"><div style="font-size:13px;font-weight:600;color:var(--t)">'+p.title+'</div><div style="font-size:10px;color:var(--m)">'+p.city+' · '+fmt(p.price)+' ر.س</div></div></div>'}).join('');
}
function toggleCompareItem(el){el.classList.toggle('selected')}
async function runCompare(){
  var sel=document.querySelectorAll('#finCompareList .fin-compare-item.selected');
  var ids=[];sel.forEach(function(el){ids.push(Number(el.getAttribute('data-id')))});
  if(ids.length<2){toast('اختر عقارين على الأقل');return}
  toast('جاري المقارنة...');
  var d=await api('/finance/compare',{method:'POST',body:JSON.stringify({properties:ids})});
  if(d&&d.success&&d.comparison.length){
    var el=document.getElementById('finCompareResult');el.style.display='block';
    el.innerHTML='<div class="fin-card"><div class="fin-h">⚖️ نتائج المقارنة</div>'+d.comparison.map(function(p,i){return'<div style="display:flex;align-items:center;gap:10px;padding:10px;border-radius:10px;background:rgba(8,9,14,.95);border:1px solid '+(i===0?'rgba(212,175,55,.4)':'var(--b)')+';margin-bottom:6px"><div style="font-size:14px;font-weight:700;color:'+(i===0?'var(--g)':'var(--m)')+'">'+(i+1)+'</div><div style="flex:1"><div style="font-size:12px;font-weight:600;color:var(--t)">'+p.title+'</div><div style="font-size:10px;color:var(--m)">'+p.city+' · '+fmt(p.price)+' ر.س</div></div><div style="text-align:center"><div style="font-size:14px;font-weight:700;color:var(--g)">'+p.roi+'%</div><div style="font-size:9px;color:var(--m)">ROI</div></div></div>'}).join('')+'</div>';
  }
}

/* MARKETING */
function openMkt(){document.getElementById('mktOv').classList.add('on');openCompareList()}
function closeMkt(){document.getElementById('mktOv').classList.remove('on')}
function showMktTab(el,id){document.querySelectorAll('#mktOv .mkt-tab').forEach(function(t){t.classList.remove('on')});el.classList.add('on');document.getElementById('mkt-desc').style.display=id==='mkt-desc'?'block':'none';document.getElementById('mkt-seo').style.display=id==='mkt-seo'?'block':'none'}
async function runMktDesc(){
  toast('جاري توليد الوصف بالذكاء الاصطناعي...');
  var features=(document.getElementById('mkt-features').value||'').split(',').map(function(f){return f.trim()}).filter(Boolean);
  var d=await api('/marketing/description',{method:'POST',body:JSON.stringify({
    type:document.getElementById('mkt-type').value,city:document.getElementById('mkt-city').value,
    district:document.getElementById('mkt-district').value,area:Number(document.getElementById('mkt-area').value)||0,
    rooms:Number(document.getElementById('mkt-rooms').value)||0,price:Number(document.getElementById('mkt-price').value)||0,
    features:features,style:document.getElementById('mkt-style').value
  })});
  if(d&&d.success){
    var el=document.getElementById('mktDescResult');el.style.display='block';
    el.innerHTML='<div class="mkt-result">'+(d.description||'لم يتم التوليد')+'</div><div style="margin-top:10px;display:flex;gap:8px"><button class="fin-run" style="flex:1;font-size:12px" onclick="navigator.clipboard.writeText(document.querySelector(\'.mkt-result\').textContent);toast(\'تم النسخ ✓\')">📋 نسخ</button><button class="fin-run" style="flex:1;font-size:12px;background:linear-gradient(135deg,#25d366,#128c7e);color:#fff" onclick="navigator.share?navigator.share({text:document.querySelector(\'.mkt-result\').textContent}):toast(\'تم النسخ ✓\')">📤 مشاركة</button></div>';
    if(d.seoAnalysis){el.innerHTML+='<div class="fin-ai-box" style="margin-top:10px">📊 تحليل SEO:\n'+d.seoAnalysis+'</div>'}
  } else if(d&&d.error){
    var el=document.getElementById('mktDescResult');el.style.display='block';
    el.innerHTML='<div class="mkt-result" style="color:var(--red);border-color:rgba(239,68,68,.4)">⚠️ تعذر التوليد: '+d.error+'</div>';
  }
}
async function runSeo(){
  toast('جاري تحليل SEO...');
  var d=await api('/marketing/seo',{method:'POST',body:JSON.stringify({
    title:document.getElementById('seo-title').value,description:document.getElementById('seo-desc').value,
    city:document.getElementById('seo-city').value,type:'فيلا',price:0
  })});
  if(d&&d.success){
    var s=d.seo;var scoreColor=s.score>=70?'var(--green)':s.score>=40?'var(--g)':'var(--red)';
    var el=document.getElementById('mktSeoResult');el.style.display='block';
    el.innerHTML='<div class="mkt-seo-score">'+s.score+'/100</div><div class="mkt-seo-bar"><div class="mkt-seo-bar-fill" style="width:'+s.score+'%;background:'+scoreColor+'"></div></div><div style="font-size:12px;color:var(--m);margin-bottom:12px">'+s.keywords.join(' · ')+'</div><div style="font-size:11px;font-weight:600;color:var(--g);margin-bottom:6px">💡 نصائح التحسين:</div>'+s.tips.map(function(t){return'<div class="mkt-tip"><div class="mkt-tip-icon">💡</div><div>'+t+'</div></div>'}).join('')+'<div style="margin-top:10px;padding:10px;border-radius:8px;background:rgba(212,175,55,.05);border:1px solid rgba(212,175,55,.2);font-size:11px;color:var(--m)">'+s.hashtags+'</div>';
  }
}

/* ABOUT */
function openAbout(){document.getElementById('aboutOv').style.display='flex'}
function closeAbout(){document.getElementById('aboutOv').style.display='none'}

/* LEGAL */
function openLeg(){document.getElementById('legOv').classList.add('on')}
function closeLeg(){document.getElementById('legOv').classList.remove('on')}
function openSkills(){document.getElementById('skillOv').classList.add('on')}
function closeSkills(){document.getElementById('skillOv').classList.remove('on')}
function skillFileSelected(input){
  var el=document.getElementById('skillFileName');
  if(input.files&&input.files[0]){el.textContent=input.files[0].name;var b=document.getElementById('skillRunBtn');b.disabled=false;b.style.opacity='1'}
  else{el.textContent='';document.getElementById('skillRunBtn').disabled=true;document.getElementById('skillRunBtn').style.opacity='.5'}
}
async function runSkill(){
  var input=document.getElementById('skillFile');
  if(!input.files||!input.files[0]){toast('اختر ملف أولاً');return}
  var btn=document.getElementById('skillRunBtn');btn.disabled=true;btn.textContent='⏳ جاري التحويل...';
  var fd=new FormData();fd.append('file',input.files[0]);
  var res=document.getElementById('skillResult');res.style.display='block';res.innerHTML='<div class="load">جاري استخراج النص وتحليل البنية...<br><small>قد يستغرق ذلك دقيقة أو أكثر حسب حجم الملف</small></div>';
  try{
    var r=await fetch('/api/skills/convert',{method:'POST',body:fd});
    var d=await r.json();
    if(d&&d.success){
      var m=d.metadata||{};
      res.innerHTML='<div style="padding:14px;border-radius:var(--r);background:rgba(74,222,128,.06);border:1px solid rgba(74,222,128,.3);margin-top:12px">'+
        '<div style="font-size:14px;font-weight:700;color:var(--green);margin-bottom:8px">✅ تم التحويل بنجاح!</div>'+
        '<div style="font-size:12px;color:var(--m);line-height:1.8">'+
        '<div>📄 الملف: <b style="color:var(--g)">'+m.filename+'</b></div>'+
        '<div>📖 الصفحات: <b style="color:var(--g)">'+m.pages+'</b></div>'+
        '<div>📝 الكلمات: <b style="color:var(--g)">'+m.words.toLocaleString('ar-SA')+'</b></div>'+
        '<div>📊 التوكينز: <b style="color:var(--g)">'+m.estimated_tokens_human+'</b></div>'+
        '<div>📑 الفصول المكتشفة: <b style="color:var(--g)">'+m.chapters_detected+'</b></div>'+
        '</div></div>'+
        '<div style="margin-top:10px"><a href="'+d.downloadUrl+'" download style="display:block;text-align:center;padding:12px;border-radius:999px;background:linear-gradient(135deg,#d4af37,#c9a430);color:#05060a;font-size:13px;font-weight:700">⬇️ تحميل النص الكامل</a></div>'+
        (d.skill?'<div style="margin-top:8px"><a href="'+d.skill+'" download style="display:block;text-align:center;padding:12px;border-radius:999px;border:1px solid rgba(74,222,128,.4);background:rgba(74,222,128,.1);color:var(--green);font-size:13px;font-weight:700">🧠 تحميل SKILL.md (المهارة الجاهزة)</a></div>':'')+
        '<div style="margin-top:8px;padding:10px;border-radius:10px;background:rgba(8,9,14,.9);border:1px solid var(--b);font-size:10px;color:var(--m);line-height:1.6">💡 ضع مجلد skill في دليل مشروعك مع وكيلك الذكي ليقرأ الكتاب عند الحاجة فقط</div>';
    }else{
      res.innerHTML='<div style="padding:14px;border-radius:var(--r);background:rgba(248,113,113,.08);border:1px solid rgba(248,113,113,.3);margin-top:12px;font-size:12px;color:var(--red)">⚠️ '+((d&&d.error)||'فشل التحويل')+'</div>';
    }
  }catch(e){
    res.innerHTML='<div style="padding:14px;border-radius:var(--r);background:rgba(248,113,113,.08);border:1px solid rgba(248,113,113,.3);margin-top:12px;font-size:12px;color:var(--red)">⚠️ خطأ في الاتصال بالخادم</div>';
  }
  btn.disabled=false;btn.textContent='🚀 تحويل الكتاب';
}
function showLegTab(el,id){document.querySelectorAll('#legOv .mkt-tab').forEach(function(t){t.classList.remove('on')});el.classList.add('on');document.getElementById('leg-contract').style.display=id==='leg-contract'?'block':'none';document.getElementById('leg-compliance').style.display=id==='leg-compliance'?'block':'none'}
async function runContract(){
  toast('جاري مراجعة العقد بالذكاء الاصطناعي...');
  var d=await api('/legal/review-contract',{method:'POST',body:JSON.stringify({
    contractType:document.getElementById('leg-type').value,sellerName:document.getElementById('leg-seller').value,
    buyerName:document.getElementById('leg-buyer').value,propertyTitle:document.getElementById('leg-title').value,
    propertyCity:document.getElementById('leg-city').value,price:Number(document.getElementById('leg-price').value)||0,
    paymentTerms:document.getElementById('leg-payment').value
  })});
  if(d&&d.success){
    var el=document.getElementById('legContractResult');el.style.display='block';
    el.innerHTML='<div class="leg-result">'+(d.review||'لم يتم التحليل')+'</div>';
    if(d.template){el.innerHTML+='<div style="margin-top:12px;padding:14px;border-radius:var(--r);background:rgba(212,175,55,.04);border:1px solid rgba(212,175,55,.2)"><div style="font-size:12px;font-weight:600;color:var(--g);margin-bottom:8px">📋 نموذج العقد المرجعي:</div><div style="font-size:11px;color:var(--m);line-height:1.8;white-space:pre-wrap">'+d.template+'</div></div>'}
  }
}
async function runCompliance(){
  toast('جاري فحص الامتثال...');
  var d=await api('/legal/compliance',{method:'POST',body:JSON.stringify({
    type:document.getElementById('comp-type').value,
    hasLicense:document.getElementById('comp-license').value==='true',
    hasApproval:document.getElementById('comp-approval').value==='true',
    city:'الرياض',price:2000000
  })});
  if(d&&d.success){
    var c=d.compliance;var scoreClass=c.summary.score>=70?'good':c.summary.score>=40?'mid':'bad';
    var el=document.getElementById('legComplianceResult');el.style.display='block';
    el.innerHTML='<div class="leg-score '+scoreClass+'">'+c.summary.score+'%</div><div style="font-size:12px;color:var(--m);text-align:center;margin-bottom:12px">'+c.recommendation+'</div>'+c.checks.map(function(ch){return'<div class="leg-check"><div class="leg-check-icon">'+ch.status+'</div><div class="leg-check-text">'+ch.item+'<div class="leg-check-note">'+ch.note+'</div></div></div>'}).join('');
  }
}

/* BUSINESS */
function openBiz(){document.getElementById('bizOv').classList.add('on');if(authToken)loadBizData()}
function closeBiz(){document.getElementById('bizOv').classList.remove('on')}
function showBizTab(el,id){document.querySelectorAll('#bizOv .biz-tab').forEach(function(t){t.classList.remove('on')});el.classList.add('on');document.getElementById('biz-invoices').style.display=id==='biz-invoices'?'block':'none';document.getElementById('biz-vendors').style.display=id==='biz-vendors'?'block':'none'}
async function loadBizData(){
  var d=await api('/business/invoices');
  if(d&&d.success){
    var s=d.stats;
    document.getElementById('bizInvStats').innerHTML='<div class="biz-stat"><div class="biz-stat-v">'+fmt(s.paid)+'</div><div class="biz-stat-l">مدفوعة</div></div><div class="biz-stat"><div class="biz-stat-v">'+fmt(s.pending)+'</div><div class="biz-stat-l">معلقة</div></div><div class="biz-stat"><div class="biz-stat-v">'+fmt(s.overdue)+'</div><div class="biz-stat-l">متأخرة</div></div><div class="biz-stat"><div class="biz-stat-v">'+s.count+'</div><div class="biz-stat-l">الإجمالي</div></div>';
    if(d.invoices.length){
      var statusCls={مدفوعة:'paid',معلقة:'pending',متأخرة:'overdue'};
      var icons={بيع:'🏠',إيجار:'🔑',عمولة:'💰',صيانة:'🔧',أخرى:'📄'};
      document.getElementById('bizInvList').innerHTML=d.invoices.map(function(inv){
        return'<div class="biz-item"><div class="biz-item-icon" style="background:rgba(212,175,55,.12)">'+(icons[inv.type]||'📄')+'</div><div class="biz-item-info"><div class="biz-item-title">'+(inv.description||inv.type)+'</div><div class="biz-item-sub">'+(inv.clientName||'—')+' · '+inv.createdAt.split(' ')[0]+'</div><span class="biz-status '+(statusCls[inv.status]||'pending')+'">'+inv.status+'</span></div><div class="biz-item-amount">'+fmt(inv.amount)+' ر.س</div></div>';
      }).join('');
    }else{document.getElementById('bizInvList').innerHTML='<div style="color:var(--m);text-align:center;padding:30px">لا توجد فواتير</div>'}
  }
  var v=await api('/business/vendors');
  if(v&&v.success&&v.vendors.length){
    var cats={مقاول:'🔨',سمسار:'🤝',محامي:'⚖️',مهندس:'📐',مقايس:'📊',أخرى:'👤'};
    document.getElementById('bizVenList').innerHTML=v.vendors.map(function(vn){
      var stars='★'.repeat(Math.round(vn.rating||0))+'☆'.repeat(5-Math.round(vn.rating||0));
      return'<div class="biz-item"><div class="biz-item-icon" style="background:rgba(96,165,250,.12)">'+(cats[vn.category]||'👤')+'</div><div class="biz-item-info"><div class="biz-item-title">'+vn.name+'</div><div class="biz-item-sub">'+vn.category+(vn.city?' · '+vn.city:'')+'</div><div class="biz-rating" style="color:var(--g)">'+stars+'</div></div><div style="font-size:11px;color:var(--m)">'+(vn.phone||'')+'</div></div>';
    }).join('');
  }else{document.getElementById('bizVenList').innerHTML='<div style="color:var(--m);text-align:center;padding:30px">لا يوجد موردون</div>'}
}
function openAddInvoice(){document.getElementById('addInvOv').classList.add('on')}
function closeAddInvoice(){document.getElementById('addInvOv').classList.remove('on')}
async function saveInvoice(){
  if(!authToken){toast('سجّل دخول أولاً');closeAddInvoice();openLogin();return}
  var d=await api('/business/invoices',{method:'POST',body:JSON.stringify({
    type:document.getElementById('inv-type').value,amount:Number(document.getElementById('inv-amount').value)||0,
    description:document.getElementById('inv-desc').value,clientName:document.getElementById('inv-client').value,
    dueDate:document.getElementById('inv-due').value
  })});
  if(d&&d.success){toast('تم إضافة الفاتورة ✓');closeAddInvoice();loadBizData()}
}
function openAddVendor(){document.getElementById('addVenOv').classList.add('on')}
function closeAddVendor(){document.getElementById('addVenOv').classList.remove('on')}
async function saveVendor(){
  if(!authToken){toast('سجّل دخول أولاً');closeAddVendor();openLogin();return}
  var d=await api('/business/vendors',{method:'POST',body:JSON.stringify({
    name:document.getElementById('ven-name').value,category:document.getElementById('ven-cat').value,
    phone:document.getElementById('ven-phone').value,city:document.getElementById('ven-city').value
  })});
  if(d&&d.success){toast('تم إضافة المورد ✓');closeAddVendor();loadBizData()}
}

/* REAL ESTATE SERVICES */
function openDoc(){document.getElementById('docOv').classList.add('on');if(authToken)loadDocData()}
function closeDoc(){document.getElementById('docOv').classList.remove('on')}
function closeSubOv(id){document.getElementById(id).classList.remove('on')}
function showDocTab(el,id){document.querySelectorAll('#docOv .mkt-tab').forEach(function(t){t.classList.remove('on')});el.classList.add('on');['doc-licenses','doc-contracts','doc-delivery','doc-rental-inv','doc-certificates','doc-deeds'].forEach(function(s){document.getElementById(s).style.display=s===id?'block':'none'})}
async function loadDocData(){
  if(!authToken)return;
  var l=await api('/realestate/licenses');
  if(l&&l.success&&l.licenses.length){
    var badge={فال:'📜', 'وسيط عقاري':'🤝','مكتب هندسي':'📐','وساطة':'⚖️','إيجار':'🔑'};
    var statusCls={active:'paid',expired:'overdue',suspended:'pending',pending:'pending'};
    document.getElementById('docLicList').innerHTML=l.licenses.map(function(lic){
      return'<div class="biz-item"><div class="biz-item-icon" style="background:rgba(76,175,80,.12)">'+(badge[lic.license_type]||'📜')+'</div><div class="biz-item-info"><div class="biz-item-title">'+(badge[lic.license_type]||'')+' '+lic.holder_name+'</div><div class="biz-item-sub">'+(lic.license_number||'')+' · '+lic.license_type+'</div><span class="biz-status '+(statusCls[lic.status]||'pending')+'">'+statusText(lic.status)+'</span></div><div style="font-size:11px;color:var(--m)">'+(lic.city||'')+ (lic.expiry_date?' · حتى '+lic.expiry_date:'')+'</div></div>';
    }).join('');
  }else{document.getElementById('docLicList').innerHTML='<div style="color:var(--m);text-align:center;padding:24px">لا توجد تراخيص حالياً</div>'}
  var c=await api('/realestate/contracts');
  if(c&&c.success&&c.contracts.length){
    document.getElementById('docConList').innerHTML=c.contracts.map(function(con){
      return'<div class="biz-item"><div class="biz-item-icon" style="background:rgba(33,150,243,.12)">📝</div><div class="biz-item-info"><div class="biz-item-title">'+con.contract_type+' · '+(con.contract_number||'')+'</div><div class="biz-item-sub">'+(con.first_party||'')+' ← '+(con.second_party||'')+'</div><span class="biz-status '+(con.is_authenticated?'paid':'pending')+'">'+(con.is_authenticated?'موثق ✓':'غير موثق')+'</span></div><div style="font-size:11px;color:var(--m)">'+(con.amount?fmt(con.amount)+' ر.س':'')+'</div></div>';
    }).join('');
  }else{document.getElementById('docConList').innerHTML='<div style="color:var(--m);text-align:center;padding:24px">لا توجد عقود حالياً</div>'}
  var d=await api('/realestate/delivery-forms');
  if(d&&d.success&&d.forms.length){
    var fCls={pending:'pending',signed:'paid',completed:'paid'};
    document.getElementById('docDelList').innerHTML=d.forms.map(function(f){
      return'<div class="biz-item"><div class="biz-item-icon" style="background:rgba(255,152,0,.12)">📦</div><div class="biz-item-info"><div class="biz-item-title">'+(f.form_type==='تسليم'?'🔑 تسليم':'📥 استلام')+' — '+f.unit_desc+'</div><div class="biz-item-sub">'+(f.lessor_name||'')+' → '+(f.lessee_name||'')+'</div><span class="biz-status '+(fCls[f.status]||'pending')+'">'+statusText(f.status)+'</span></div></div>';
    }).join('');
  }else{document.getElementById('docDelList').innerHTML='<div style="color:var(--m);text-align:center;padding:24px">لا توجد نماذج حالياً</div>'}
  var ri=await api('/realestate/rental-invoices');
  if(ri&&ri.success&&ri.stats){
    document.getElementById('rentInvPaid').innerText=fmt(ri.stats.paid_total);
    document.getElementById('rentInvPending').innerText=fmt(ri.stats.pending_total);
    document.getElementById('rentInvOverdue').innerText=fmt(ri.stats.overdue_total);
  }
  if(ri&&ri.success&&ri.invoices&&ri.invoices.length){
    var riCls={paid:'paid',pending:'pending',overdue:'overdue',cancelled:'pending'};
    document.getElementById('docRentInvList').innerHTML=ri.invoices.map(function(inv){
      return'<div class="biz-item"><div class="biz-item-icon" style="background:rgba(76,175,80,.12)">🧾</div><div class="biz-item-info"><div class="biz-item-title">'+(inv.invoice_number||'')+' — '+inv.tenant_name+'</div><div class="biz-item-sub">'+(inv.period_from||'')+' → '+(inv.period_to||'')+'</div><span class="biz-status '+(riCls[inv.status]||'pending')+'">'+statusText(inv.status)+'</span></div><div style="font-size:12px;font-weight:700;color:var(--g)">'+fmt(inv.total_amount)+' ر.س</div></div>';
    }).join('');
  }else{document.getElementById('docRentInvList').innerHTML='<div style="color:var(--m);text-align:center;padding:24px">لا توجد فواتير إيجارية</div>'}
  var cert=await api('/realestate/certificates');
  if(cert&&cert.success&&cert.certificates.length){
    var cCls={pending:'pending',approved:'paid',rejected:'overdue'};
    document.getElementById('docCertList').innerHTML=cert.certificates.map(function(ct){
      return'<div class="biz-item"><div class="biz-item-icon" style="background:rgba(156,39,176,.12)">📋</div><div class="biz-item-info"><div class="biz-item-title">'+ct.certificate_type+' — '+(ct.certificate_number||'')+'</div><div class="biz-item-sub">'+(ct.property_desc||'')+(ct.engineer_name?' · '+ct.engineer_name:'')+'</div><span class="biz-status '+(cCls[ct.status]||'pending')+'">'+statusText(ct.status)+'</span></div></div>';
    }).join('');
  }else{document.getElementById('docCertList').innerHTML='<div style="color:var(--m);text-align:center;padding:24px">لا توجد شهادات فرز</div>'}
  var deeds=await api('/realestate/deeds');
  if(deeds&&deeds.success&&deeds.deeds.length){
    document.getElementById('docDeedList').innerHTML=deeds.deeds.map(function(dd){
      return'<div class="biz-item"><div class="biz-item-icon" style="background:rgba(212,175,55,.12)">📜</div><div class="biz-item-info"><div class="biz-item-title">'+(dd.deed_number||'')+' — '+dd.owner_name+'</div><div class="biz-item-sub">'+(dd.property_desc||'')+(dd.area?' · '+dd.area+' م²':'')+'</div><span class="biz-status '+(dd.is_verified?'paid':'pending')+'">'+(dd.is_verified?'موثق ✓':'غير موثق')+'</span></div></div>';
    }).join('');
  }else{document.getElementById('docDeedList').innerHTML='<div style="color:var(--m);text-align:center;padding:24px">لا توجد صكوك مسجلة</div>'}
}
function statusText(s){
  var m={active:'نشط',expired:'منتهي',suspended:'موقوف',pending:'قيد الانتظار',paid:'مدفوع',overdue:'متأخر',signed:'موقع',completed:'مكتمل',draft:'مسودة',approved:'معتمد',rejected:'مرفوض',cancelled:'ملغي'};
  return m[s]||s;
}
function openAddLicense(){if(!authToken){toast('سجّل دخول أولاً');openLogin();return}document.getElementById('addLicOv').classList.add('on')}
async function saveLicense(){
  if(!authToken){toast('سجّل دخول أولاً');closeSubOv('addLicOv');openLogin();return}
  var d=await api('/realestate/licenses',{method:'POST',body:JSON.stringify({
    license_type:document.getElementById('lic-type').value,holder_name:document.getElementById('lic-holder').value,
    holder_id:document.getElementById('lic-id').value,city:document.getElementById('lic-city').value,
    notes:document.getElementById('lic-notes').value
  })});
  if(d&&d.success){toast('تم تقديم طلب الترخيص ✓\nالرقم: '+d.license_number);closeSubOv('addLicOv');loadDocData()}
}
function openAddContract(){if(!authToken){toast('سجّل دخول أولاً');openLogin();return}document.getElementById('addConOv').classList.add('on')}
async function saveContract(){
  if(!authToken){toast('سجّل دخول أولاً');closeSubOv('addConOv');openLogin();return}
  var d=await api('/realestate/contracts',{method:'POST',body:JSON.stringify({
    contract_type:document.getElementById('con-type').value,first_party:document.getElementById('con-party1').value,
    second_party:document.getElementById('con-party2').value,property_desc:document.getElementById('con-prop').value,
    amount:Number(document.getElementById('con-amount').value)||0,payment_terms:document.getElementById('con-payment').value,
    start_date:document.getElementById('con-start').value,end_date:document.getElementById('con-end').value
  })});
  if(d&&d.success){toast('تم إنشاء العقد ✓\nالرقم: '+d.contract_number);closeSubOv('addConOv');loadDocData()}
}
function openAddDelivery(){if(!authToken){toast('سجّل دخول أولاً');openLogin();return}document.getElementById('addDelOv').classList.add('on')}
async function saveDelivery(){
  if(!authToken){toast('سجّل دخول أولاً');closeSubOv('addDelOv');openLogin();return}
  var d=await api('/realestate/delivery-forms',{method:'POST',body:JSON.stringify({
    form_type:document.getElementById('del-type').value,unit_desc:document.getElementById('del-unit').value,
    unit_address:document.getElementById('del-addr').value,lessor_name:document.getElementById('del-lessor').value,
    lessee_name:document.getElementById('del-lessee').value,handover_date:document.getElementById('del-date').value,
    condition_notes:document.getElementById('del-notes').value,meter_readings:document.getElementById('del-meter').value,
    keys_count:Number(document.getElementById('del-keys').value)||0
  })});
  if(d&&d.success){toast('تم حفظ النموذج ✓');closeSubOv('addDelOv');loadDocData()}
}
function openAddRentalInv(){if(!authToken){toast('سجّل دخول أولاً');openLogin();return}document.getElementById('addRentInvOv').classList.add('on')}
async function saveRentalInv(){
  if(!authToken){toast('سجّل دخول أولاً');closeSubOv('addRentInvOv');openLogin();return}
  var d=await api('/realestate/rental-invoices',{method:'POST',body:JSON.stringify({
    tenant_name:document.getElementById('rentInv-tenant').value,rent_amount:Number(document.getElementById('rentInv-amount').value)||0,
    services_fee:Number(document.getElementById('rentInv-services').value)||0,tax_amount:Number(document.getElementById('rentInv-tax').value)||0,
    period_from:document.getElementById('rentInv-from').value,period_to:document.getElementById('rentInv-to').value,
    payment_method:document.getElementById('rentInv-method').value
  })});
  if(d&&d.success){toast('تم إصدار الفاتورة ✓\nالرقم: '+d.invoice_number+' المبلغ: '+fmt(d.total_amount)+' ر.س');closeSubOv('addRentInvOv');loadDocData()}
}
function openAddCertificate(){if(!authToken){toast('سجّل دخول أولاً');openLogin();return}document.getElementById('addCertOv').classList.add('on')}
async function saveCertificate(){
  if(!authToken){toast('سجّل دخول أولاً');closeSubOv('addCertOv');openLogin();return}
  var d=await api('/realestate/certificates',{method:'POST',body:JSON.stringify({
    certificate_type:document.getElementById('cert-type').value,property_desc:document.getElementById('cert-prop').value,
    total_units:Number(document.getElementById('cert-units').value)||0,engineer_name:document.getElementById('cert-eng').value,
    notes:document.getElementById('cert-notes').value
  })});
  if(d&&d.success){toast('تم تقديم طلب الشهادة ✓');closeSubOv('addCertOv');loadDocData()}
}
function openAddDeed(){if(!authToken){toast('سجّل دخول أولاً');openLogin();return}document.getElementById('addDeedOv').classList.add('on')}
async function saveDeed(){
  if(!authToken){toast('سجّل دخول أولاً');closeSubOv('addDeedOv');openLogin();return}
  var d=await api('/realestate/deeds',{method:'POST',body:JSON.stringify({
    property_desc:document.getElementById('deed-prop').value,owner_name:document.getElementById('deed-owner').value,
    area:Number(document.getElementById('deed-area').value)||0,property_city:document.getElementById('deed-city').value,
    deed_type:document.getElementById('deed-type').value,issue_date:document.getElementById('deed-date').value,
    boundaries:document.getElementById('deed-bounds').value
  })});
  if(d&&d.success){toast('تم تسجيل الصك ✓\nالرقم: '+d.deed_number);closeSubOv('addDeedOv');loadDocData()}
}

/* MARKET DASHBOARD */
function openMarket(){document.getElementById('marketOv').classList.add('on');loadMarketData()}
function closeMarket(){document.getElementById('marketOv').classList.remove('on')}
async function loadMarketData(){
  var el=document.getElementById('marketContent');
  el.innerHTML='<div style="text-align:center;padding:20px"><div style="font-size:24px;margin-bottom:8px">⏳</div><div>جاري تحميل بيانات السوق...</div></div>';
  var d=await api('/market/overview');
  if(!d||!d.success){
    el.innerHTML='<div style="text-align:center;color:var(--red);padding:20px">⚠️ تعذر تحميل بيانات السوق</div>';
    return;
  }
  var s=d.sama||{};
  var t=d.tasi||{};
  var c=d.cma||{};
  var g=d.gold||{};
  var o=d.oil||{};
  var ix=d.indices||{};
  var tasiDir=t.change>=0;
  var html='';
  html+='<div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:16px">';
  html+='<span class="mkt-source-badge sama">🏦 ساما</span>';
  html+='<span class="mkt-source-badge tasi">📈 تداول</span>';
  if(g.source)html+='<span class="mkt-source-badge" style="background:#d4af3733;color:#d4af37">🥇 ذهب</span>';
  if(o.source)html+='<span class="mkt-source-badge" style="background:#33415533;color:#94a3b8">🛢️ نفط</span>';
  if(ix.source)html+='<span class="mkt-source-badge" style="background:#10b98122;color:#10b981">🌍 عالمي</span>';
  if(c.source)html+='<span class="mkt-source-badge cma">🏛️ هيئة السوق المالية</span>';
  html+='</div>';

  html+='<div class="mkt-rate-card"><div class="mkt-rate-title">📈 مؤشر تاسي (TASI)</div><div class="mkt-rate-value">'+(t.tasi?t.tasi.toLocaleString():'—')+'</div>';
  if(t.change!==undefined)html+='<div class="mkt-rate-sub">التغيير: <span class="mkt-rate-change '+(tasiDir?'up':'down')+'">'+(tasiDir?'+':'')+t.change+' ('+(t.changePercent?t.changePercent.toFixed(2):'0')+'%)</span></div>';
  html+='<div class="mkt-rate-sub">المصدر: '+(t.source||'—')+'</div></div>';

  html+='<div class="mkt-grid-3">';
  html+='<div class="mkt-mini-card"><div class="mkt-mini-label">سعر الفائدة (Repo)</div><div class="mkt-mini-val blue">'+s.repoRate+'%</div></div>';
  html+='<div class="mkt-mini-card"><div class="mkt-mini-label">السعر العكسي</div><div class="mkt-mini-val">'+s.reverseRepoRate+'%</div></div>';
  html+='<div class="mkt-mini-card"><div class="mkt-mini-label">SAIBOR 3 شهور</div><div class="mkt-mini-val green">'+s.saibor3M+'%</div></div>';
  html+='<div class="mkt-mini-card"><div class="mkt-mini-label">النسبة (CPI)</div><div class="mkt-mini-val">'+s.inflationRate+'%</div></div>';
  html+='<div class="mkt-mini-card"><div class="mkt-mini-label">نمو الناتج المحلي</div><div class="mkt-mini-val green">'+s.gdpGrowth+'%</div></div>';
  html+='<div class="mkt-mini-card"><div class="mkt-mini-label">نمو العرض النقدي</div><div class="mkt-mini-val">'+s.moneySupplyGrowth+'%</div></div>';
  html+='</div>';

  html+='<div class="mkt-section-title">🥇 الذهب والسلع الأساسية</div>';
  html+='<div class="mkt-grid-3">';
  html+='<div class="mkt-mini-card gold"><div class="mkt-mini-label">ذهب (XAU/USD)</div><div class="mkt-mini-val gold">'+(g.xauUsd?g.xauUsd.toLocaleString()+'$':'—')+'</div>';
  if(g.change!==undefined)html+='<div class="mkt-mini-change '+(g.change>=0?'up':'down')+'">'+(g.change>=0?'+':'')+g.change+' ('+g.changePercent+'%)</div>';
  html+='</div>';
  html+='<div class="mkt-mini-card gold"><div class="mkt-mini-label">ذهب (XAU/SAR)</div><div class="mkt-mini-val gold">'+(g.xauSar?g.xauSar.toLocaleString()+' ر.س':'—')+'</div></div>';
  html+='<div class="mkt-mini-card"><div class="mkt-mini-label">نفط WTI</div><div class="mkt-mini-val black">'+(o.wti?o.wti+'$':'—')+'</div>';
  if(o.change!==undefined)html+='<div class="mkt-mini-change '+(o.change>=0?'up':'down')+'">'+(o.change>=0?'+':'')+o.change+' ('+o.changePercent+'%)</div>';
  html+='</div>';
  html+='<div class="mkt-mini-card"><div class="mkt-mini-label">نفط برنت</div><div class="mkt-mini-val black">'+(o.brent?o.brent+'$':'—')+'</div></div>';
  html+='</div>';

  html+='<div class="mkt-section-title">🌍 المؤشرات العالمية</div>';
  html+='<div class="mkt-grid-3">';
  var indices=[
    {name:'S&P 500',val:ix.sp500,chg:ix.sp500Change,sym:'SPY'},
    {name:'NASDAQ',val:ix.nasdaq,chg:ix.nasdaqChange,sym:'QQQ'},
    {name:'Dow Jones',val:ix.dowJones,chg:ix.dowJonesChange,sym:'DJI'},
    {name:'FTSE 100',val:ix.ftse100,chg:ix.ftse100Change,sym:'^FTSE'},
    {name:'Nikkei 225',val:ix.nikkei,chg:ix.nikkeiChange,sym:'^N225'},
    {name:'DAX',val:ix.dax,chg:ix.daxChange,sym:'^GDAXI'}
  ];
  indices.forEach(function(idx){
    var dir=(idx.chg||0)>=0;
    html+='<div class="mkt-mini-card"><div class="mkt-mini-label">'+idx.name+'</div><div class="mkt-mini-val '+(dir?'green':'red')+'">'+(idx.val?idx.val.toLocaleString():'—')+'</div>';
    if(idx.chg)html+='<div class="mkt-mini-change '+(dir?'up':'down')+'">'+(dir?'+':'')+idx.chg.toFixed(2)+'</div>';
    html+='</div>';
  });
  html+='</div>';

  html+='<div style="margin-top:16px;margin-bottom:8px;font-size:13px;font-weight:700;color:var(--g)">🏛️ آخر إعلانات هيئة السوق المالية (CMA)</div>';
  if(c.recentAnnouncements&&c.recentAnnouncements.length){
    c.recentAnnouncements.forEach(function(a){
      html+='<div class="mkt-cma-item"><div class="mkt-cma-dot"></div><div class="mkt-cma-text">'+a.title+'</div><div class="mkt-cma-date">'+a.date+'</div></div>';
    });
  }else{
    html+='<div style="color:var(--m);text-align:center;padding:10px;font-size:12px">لا توجد إعلانات حديثة</div>';
  }
  html+='<div class="mkt-rate-sub" style="margin-top:12px;text-align:center">آخر تحديث: '+(s.lastUpdate?new Date(s.lastUpdate).toLocaleString('ar-SA'):'—')+'</div>';
  html+='<button class="mkt-refresh-btn" onclick="loadMarketData()">🔄 تحديث البيانات</button>';
  el.innerHTML=html;
  if(s.repoRate){window._samaRate=s.repoRate;updateFinRate()}
}
function updateFinRate(){
  if(window._samaRate){
    var el=document.getElementById('fin-rate');
    if(el)el.value=window._samaRate;
  }
}

/* ADD PROPERTY */
async function fetchDistricts(){
  var city=document.getElementById('ap-city')?document.getElementById('ap-city').value:'';
  try{
    var url='/search/districts';
    if(city)url+='?city='+encodeURIComponent(city);
    var d=await api(url);
    if(d&&d.success&&d.districts){
      var dl=document.getElementById('districts-list');
      dl.innerHTML=d.districts.map(function(x){return '<option value="'+x+'">'}).join('');
    }
  }catch(e){}
}
async function fetchMktDistricts(){
  var city=document.getElementById('mkt-city')?document.getElementById('mkt-city').value:'';
  try{
    var url='/search/districts';
    if(city)url+='?city='+encodeURIComponent(city);
    var d=await api(url);
    if(d&&d.success&&d.districts){
      var dl=document.getElementById('mkt-districts-list');
      dl.innerHTML=d.districts.map(function(x){return '<option value="'+x+'">'}).join('');
    }
  }catch(e){}
}
function toggleApartmentsFilter(){
  var g=document.getElementById('af-apartments-group');
  var t=document.getElementById('ht')?document.getElementById('ht').value:'';
  if(g)g.style.display=(t==='فيلا')?'block':'none';
}
function toggleApApartments(){
  var row=document.getElementById('ap-apartments-row');
  var tp=document.getElementById('ap-type')?document.getElementById('ap-type').value:'';
  if(row)row.style.display=(tp==='فيلا')?'flex':'none';
}
async function submitAddProp(){
  var t=document.getElementById('ap-title')?document.getElementById('ap-title').value:'';
  var tp=document.getElementById('ap-type')?document.getElementById('ap-type').value:'شقة';
  var pr=document.getElementById('ap-purpose')?document.getElementById('ap-purpose').value:'بيع';
  var prc=Number(document.getElementById('ap-price')?document.getElementById('ap-price').value:0);
  var ar=Number(document.getElementById('ap-area')?document.getElementById('ap-area').value:100);
  var rm=Number(document.getElementById('ap-rooms')?document.getElementById('ap-rooms').value:3);
  var bt=Number(document.getElementById('ap-baths')?document.getElementById('ap-baths').value:2);
  var ap=Number(document.getElementById('ap-apartments')?document.getElementById('ap-apartments').value:0);
  var ct=document.getElementById('ap-city')?document.getElementById('ap-city').value:'الرياض';
  var di=document.getElementById('ap-district')?document.getElementById('ap-district').value:'';
  var ds=document.getElementById('ap-desc')?document.getElementById('ap-desc').value:'';
  if(!t){toast('أدخل عنوان الإعلان');return}
  if(!authToken){toast('سجّل دخول أولاً');openLogin();return}
  var images=[],panoUrl=null;
  var imgFiles=document.getElementById('ap-img')?document.getElementById('ap-img').files:[];
  var panoFiles=document.getElementById('ap-pano')?document.getElementById('ap-pano').files:[];
  if(imgFiles.length){
    var fd=new FormData();
    for(var i=0;i<imgFiles.length;i++)fd.append('images',imgFiles[i]);
    var up=await fetch(API+'/upload/images',{method:'POST',headers:{'Authorization':'Bearer '+authToken},body:fd}).then(function(r){return r.json()}).catch(function(){return null});
    if(up&&up.success)images=up.images.map(function(u){return u.url});
  }
  if(panoFiles.length){
    var fd2=new FormData();fd2.append('image',panoFiles[0]);
    var up2=await fetch(API+'/upload/panoramic',{method:'POST',headers:{'Authorization':'Bearer '+authToken},body:fd2}).then(function(r){return r.json()}).catch(function(){return null});
    if(up2&&up2.success)panoUrl=up2.url;
  }
  var panoUrlInput=document.getElementById('ap-pano-url');
  var panoUrlTxt=panoUrlInput?panoUrlInput.value.trim():'';
  if(!panoUrl&&/^https?:\/\//i.test(panoUrlTxt))panoUrl=panoUrlTxt;
  if(!panoUrl)panoUrl=localStorage.getItem('darak_pano_url')||null;
  var model3dInput=document.getElementById('ap-model3d');
  var model3dUrl=model3dInput?model3dInput.value.trim():'';
  if(model3dUrl&&!/^https?:\/\//i.test(model3dUrl))model3dUrl='';
  var autoLocal=null;
  if(!panoUrl&&window.autoPanoBlob){
    try{
      var fd3=new FormData();fd3.append('image',window.autoPanoBlob,'auto360.jpg');
      var up3=await fetch(API+'/upload/panoramic',{method:'POST',headers:{'Authorization':'Bearer '+authToken},body:fd3}).then(function(r){return r.json()}).catch(function(){return null});
      if(up3&&up3.success)panoUrl=up3.url;
      else autoLocal=window.autoPanoDataUrl||null;
    }catch(e){autoLocal=window.autoPanoDataUrl||null}
  }
  var d=await api('/properties',{method:'POST',body:JSON.stringify({
    title:t,type:tp,purpose:pr,price:prc,area:ar,rooms:rm,baths:bt,apartments:ap,
    city:ct,district:di||ct,description:ds,year:new Date().getFullYear(),age:0,
    facing:'شمالي',features:[],images:images,panoramicImage:panoUrl,model3dUrl:model3dUrl,
    lat:Number(document.getElementById('ap-lat').value)||null,
    lng:Number(document.getElementById('ap-lng').value)||null
  })});
  if(d&&d.success){
    if(autoLocal){
      var np=d.property||null;
      try{
        var lmap=JSON.parse(localStorage.getItem('darak_local_panos')||'{}');
        lmap[(np&&np.id)||('x'+Date.now())]=autoLocal;
        localStorage.setItem('darak_local_panos',JSON.stringify(lmap));
      }catch(e){}
    }
    toast('تم نشر الإعلان بنجاح ✓');await loadProperties();nav('home')
  }
}

/* SHARE */
function shareProp(id){
  var p=A.find(function(x){return x.id===id});if(!p)return;
  if(navigator.share){navigator.share({title:p.title,text:pLoc(p)+' - '+pPrice(p),url:window.location.href})}
  else{navigator.clipboard.writeText(p.title+' - '+pPrice(p));toast('تم نسخ رابط العقار ✓')}
}

/* PWA */
var deferredPrompt;
window.addEventListener('beforeinstallprompt',function(e){e.preventDefault();deferredPrompt=e;var ua=navigator.userAgent;var pb=document.getElementById('pb');if(!ua.includes('iPhone')&&!ua.includes('iPad')&&pb)pb.classList.add('show')});
function doInstall(){if(!deferredPrompt)return;deferredPrompt.prompt();deferredPrompt.userChoice.then(function(r){if(r.outcome==='accepted'){var pb=document.getElementById('pb');if(pb)pb.classList.remove('show')}deferredPrompt=null})}
function closePB(){var pb=document.getElementById('pb');if(pb)pb.classList.remove('show')}
if(navigator.standalone||window.matchMedia('(display-mode:standalone)').matches){var pb0=document.getElementById('pb');if(pb0)pb0.classList.remove('show')}
if(/iPhone|iPad|iPod/.test(navigator.userAgent)&&!window.matchMedia('(display-mode:standalone)').matches)setTimeout(function(){var ios=document.getElementById('ios');if(ios)ios.classList.add('show')},3000);
if('serviceWorker' in navigator){navigator.serviceWorker.register('sw.js').then(function(reg){if(reg.waiting)reg.waiting.postMessage('SKIP_WAITING')}).catch(function(){});navigator.serviceWorker.addEventListener('controllerchange',function(){location.reload()})}

/* LOAD DATA */
var FALLBACK=[
{id:1,title:"فيلا فاخرة في حي النرجس",type:"فيلا",loc:"حي النرجس، الرياض",district:"حي النرجس",city:"الرياض",price:2500000,rooms:6,baths:5,cars:3,apartments:3,area:450,year:2023,age:1,status:"حصري",lat:24.7935,lng:46.6898,street:"طريق الأمير تركي",streetW:20,facing:"شرقي",purpose:"بيع",desc:"فيلا فاخرة بتصميم عصري مع حديقة خاصة ومسبح خارجي ونادي صحي",images:[],pano:null,features:["حديقة خاصة","مسبح خارجي","موقف سيارات","نادي صحي","غرفة خادمة","مطبخ مفروش"],trust:"verified",agent:{name:"مكتب الديار العقارية",role:"وسيط مرخص",phone:"+966501234567"}},
{id:2,title:"شقة مفروشة في حي الملقا",type:"شقة",loc:"حي الملقا، الرياض",district:"حي الملقا",city:"الرياض",price:2500,rooms:3,baths:2,cars:1,area:180,year:2022,age:2,status:"حصري",lat:24.7115,lng:46.6748,street:"طريق الملك فهد",streetW:15,facing:"شمالي",purpose:"إيجار",desc:"شقة مفروشة بالكامل بإطلالة رائعة على برج المملكة",images:[],pano:null,features:["مفروشة بالكامل","إطلالة بانورامية","أمن 24/7","موقف سيارات"],trust:"office",agent:{name:"مكتب الديار العقارية",role:"وسيط مرخص",phone:"+966501234567"}},
{id:3,title:"بنتهاوس فاخر في حي الشفا",type:"بنتهاوس",loc:"حي الشفا، الرياض",district:"حي الشفا",city:"الرياض",price:3800000,rooms:5,baths:4,cars:2,area:350,year:2023,age:1,status:"حصري",lat:24.8155,lng:46.6545,street:"طريق الثمامة",streetW:25,facing:"غربي",purpose:"بيع",desc:"بنتهاوس فاخر بإطلالة بانورامية على برج المملكة",images:[],pano:null,features:["إطلالة بانورامية","مسبح داخلي","نادي صحي","خدمة كونسيرج"],trust:"verified",agent:{name:"مكتب الدار العقارية",role:"وسيط مرخص",phone:"+966555123456"}},
{id:4,title:"شقة عائلية في حي الراكة",type:"شقة",loc:"حي الراكة، جدة",district:"حي الراكة",city:"جدة",price:3500,rooms:4,baths:3,cars:1,area:220,year:2021,age:3,status:"متاح",lat:21.6553,lng:39.1553,street:"شارع الأمير سلطان",streetW:20,facing:"شرقي",purpose:"إيجار",desc:"شقة عائلية واسعة في حي هادئ قريب من جميع الخدمات",images:[],pano:null,features:["مدخل خاص","موقف سيارة","قريب من المدارس"],trust:"office",agent:{name:"مكتب جدة العقاري",role:"وسيط مرخص",phone:"+966555987654"}},
{id:5,title:"أرض سكنية في حي النخيل",type:"أرض",loc:"حي النخيل، الرياض",district:"حي النخيل",city:"الرياض",price:1800000,rooms:0,baths:0,cars:0,area:750,year:0,age:0,status:"حصري",lat:24.6895,lng:46.7348,street:"طريق الأمير محمد بن سعد",streetW:30,facing:"شمالي",purpose:"بيع",desc:"أرض سكنية مميزة على شارعين في حي النخيل. مثالية لبناء فيلا عائلية",images:[],pano:null,features:["شارعين","مرافق متكاملة"],trust:"verified",agent:{name:"مكتب الديار العقارية",role:"وسيط مرخص",phone:"+966501234567"}},
{id:6,title:"مكتب تجاري في برج المملكة",type:"مكتب",loc:"الملقا، الرياض",district:"الملقا",city:"الرياض",price:120000,rooms:2,baths:1,cars:0,area:150,year:2020,age:4,status:"متاح",lat:24.7115,lng:46.6748,street:"طريق الملك فهد",streetW:25,facing:"شرقي",purpose:"إيجار",desc:"مكتب تجاري فاخر في برج المملكة مع إطلالة رائعة على المدينة",images:[],pano:null,features:["إطلالة","أمن 24/7","موقف سيارات","قاعة اجتماعات"],trust:"office",agent:{name:"مكتب الرياض للمكاتب",role:"وسيط مرخص",phone:"+966555111222"}},
{id:7,title:"شاليه على البحر في الصواري",type:"شاليه",loc:"الصواري، جدة",district:"الصواري",city:"جدة",price:2500,rooms:3,baths:2,cars:1,area:200,year:2022,age:2,status:"حصري",lat:21.7847,lng:39.1150,street:"طريق الساحل",streetW:20,facing:"شرقي",purpose:"إيجار",desc:"شاليه فاخر على الشاطئ مباشرة مع مسبح خارجي وإطلالة بحرية ساحرة",images:[],pano:null,features:["شاطئ خاص","مسبح","شواء","إطلالة بحرية"],trust:"verified",agent:{name:"مكتب جدة العقاري",role:"وسيط مرخص",phone:"+966555987654"}},
{id:8,title:"قصر فاخر في حي الورود",type:"قصر",loc:"حي الورود، الرياض",district:"حي الورود",city:"الرياض",price:8500000,rooms:8,baths:6,cars:4,area:1200,year:2023,age:1,status:"حصري",lat:24.6969,lng:46.6918,street:"طريق الأمير فيصل بن فهد",streetW:35,facing:"شمالي",purpose:"بيع",desc:"قصر فاخر بتصميم معماري أنيق مع حدائق واسعة ومسبح أولمبي ونادي صحي خاص",images:[],pano:null,features:["مسبح أولمبي","نادي صحي","حدائق","ساعة استقبال","غرفة سينما"],trust:"verified",agent:{name:"مكتب الدار العقارية",role:"وسيط مرخص",phone:"+966555123456"}},
{id:9,title:"شقة حديثة في حي الياسمين",type:"شقة",loc:"حي الياسمين، الرياض",district:"حي الياسمين",city:"الرياض",price:1800,rooms:2,baths:2,cars:1,area:120,year:2024,age:0,status:"متاح",lat:24.7366,lng:46.6557,street:"طريق الأمير تركي بن عبد العزيز",streetW:18,facing:"غربي",purpose:"إيجار",desc:"شقة حديثة التصميم في حي الياسمين مع تشطيبات عصرية",images:[],pano:null,features:["تشطيب حديث","موقف سيارة","قريب من المولات"],trust:"direct",agent:{name:"أحمد العلي",role:"بائع مباشر",phone:"+966555333444"}},
{id:10,title:"محل تجاري في سوق الراكة",type:"محل",loc:"سوق الراكة، جدة",district:"سوق الراكة",city:"جدة",price:80000,rooms:1,baths:1,cars:0,area:80,year:2019,age:5,status:"متاح",lat:21.6325,lng:39.1728,street:"شارع الأمير سلطان",streetW:15,facing:"شرقي",purpose:"إيجار",desc:"محل تجاري مميز في سوق الراكة مع حركة مرور عالية وواجهة واسعة",images:[],pano:null,features:["واجهة واسعة","حركة مرور عالية","موقف قريب"],trust:"office",agent:{name:"مكتب جدة العقاري",role:"وسيط مرخص",phone:"+966555987654"}},

{id:100,title:"مزرعة  في كدي",type:"مزرعة",loc:"كدي، مكة",district:"كدي",city:"مكة",price:8700,rooms:3,baths:2,cars:4,area:49559,year:2018,age:2,status:"متاح",lat:24.714667680190715,lng:46.82149160375672,facing:"شرقي",purpose:"إيجار",desc:"مزرعة منتجة بها أشجار مثمرة في كدي بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["مياه وفيرة","مخيم","بيوت ضيافة","أشجار مثمرة","مسبح"],trust:"office",agent:{name:"شركة أصول العقارية",role:"وسيط مرخص",phone:"+966554445566"}},
{id:101,title:"أرض  في حي الفيحاء",type:"أرض",loc:"حي الفيحاء، الخبر",district:"حي الفيحاء",city:"الخبر",price:670000,rooms:0,baths:0,cars:0,area:543,year:2022,age:6,status:"متاح",lat:24.833904180646748,lng:46.8754221494893,facing:"جنوبي",purpose:"بيع",desc:"أرض سكنية مميزة على شارع رئيسي في حي الفيحاء بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["مرافق","شارعين","مخطط","تجاري"],trust:"office",agent:{name:"مكتب الديار العقارية",role:"وسيط مرخص",phone:"+966501234567"}},
{id:102,title:"شاليه  في حي الخبر الشمالية",type:"شاليه",loc:"حي الخبر الشمالية، الخبر",district:"حي الخبر الشمالية",city:"الخبر",price:1450000,rooms:4,baths:1,cars:2,area:114,year:2024,age:4,status:"متاح",lat:24.734136406535413,lng:46.86041186956969,facing:"شمالي",purpose:"بيع",desc:"شاليه رائع على الشاطئ مباشرة في حي الخبر الشمالية بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["إطلالة بحرية","مسبح"],trust:"verified",agent:{name:"الخبر العقارية",role:"وسيط مرخص",phone:"+966556667788"}},
{id:103,title:"قصر  في حي المحمدية",type:"قصر",loc:"حي المحمدية، جدة",district:"حي المحمدية",city:"جدة",price:9600000,rooms:10,baths:9,cars:4,area:1721,year:2021,age:0,status:"متاح",lat:24.719386715079043,lng:46.66678975191433,facing:"شرقي",purpose:"بيع",desc:"قصر فاخر بتصميم معماري فريد في حي المحمدية بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["ملعب","ساعة استقبال"],trust:"direct",agent:{name:"حائل العقارية",role:"وسيط مرخص",phone:"+966555556677"}},
{id:104,title:"محل  في حي الطبيشي",type:"محل",loc:"حي الطبيشي، الدمام",district:"حي الطبيشي",city:"الدمام",price:6200,rooms:1,baths:2,cars:0,area:34,year:2021,age:7,status:"متاح",lat:24.88374882988594,lng:46.63341125705226,facing:"جنوبي",purpose:"إيجار",desc:"مساحة تجارية في سوق مزدحم في حي الطبيشي بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["موقف قريب","حركة مرور عالية","دورات مياه","مستودع"],trust:"office",agent:{name:"مكتب جدة العقاري",role:"وسيط مرخص",phone:"+966555987654"}},
{id:105,title:"محل  في حي الكندرة",type:"محل",loc:"حي الكندرة، جدة",district:"حي الكندرة",city:"جدة",price:2600,rooms:2,baths:2,cars:1,area:134,year:2019,age:2,status:"متاح",lat:24.800739362977698,lng:46.69947105166558,facing:"جنوبي",purpose:"إيجار",desc:"مساحة تجارية في سوق مزدحم في حي الكندرة بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["موقف قريب","مستودع","حركة مرور عالية","واجهة واسعة"],trust:"verified",agent:{name:"مكتب الديار العقارية",role:"وسيط مرخص",phone:"+966501234567"}},
{id:106,title:"شقة  في حي البندر",type:"شقة",loc:"حي البندر، الخبر",district:"حي البندر",city:"الخبر",price:1400,rooms:2,baths:1,cars:1,area:104,year:2025,age:1,status:"متاح",lat:24.77776682214926,lng:46.834626537274495,facing:"غربي",purpose:"إيجار",desc:"شقة عائلية واسعة في حي سكني هادئ في حي البندر بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["أمن 24/7","نادي صحي","موقف سيارات","مطبخ مفروش","إطلالة بانورامية"],trust:"direct",agent:{name:"حائل العقارية",role:"وسيط مرخص",phone:"+966555556677"}},
{id:107,title:"مزرعة  في الزاهر",type:"مزرعة",loc:"الزاهر، مكة",district:"الزاهر",city:"مكة",price:6770000,rooms:3,baths:3,cars:3,area:27299,year:2018,age:4,status:"متاح",lat:24.796060059131953,lng:46.64004457293562,facing:"جنوبي",purpose:"بيع",desc:"مزرعة استثمارية بمساحة كبيرة في الزاهر بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["مسبح","ملعب","بيوت ضيافة"],trust:"direct",agent:{name:"مكة للاستثمار العقاري",role:"وسيط مرخص",phone:"+966558888777"}},
{id:108,title:"شقة  في حي الجامعيين",type:"شقة",loc:"حي الجامعيين، الدمام",district:"حي الجامعيين",city:"الدمام",price:620000,rooms:5,baths:2,cars:2,area:193,year:2019,age:3,status:"متاح",lat:24.875947469339707,lng:46.7629235845279,facing:"شرقي",purpose:"بيع",desc:"شقة حديثة التشطيب قريبة من جميع الخدمات في حي الجامعيين بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["إطلالة بانورامية","نادي صحي","موقف سيارات","مفروشة بالكامل"],trust:"office",agent:{name:"حائل العقارية",role:"وسيط مرخص",phone:"+966555556677"}},
{id:109,title:"فيلا  في حي البساتين",type:"فيلا",loc:"حي البساتين، جدة",district:"حي البساتين",city:"جدة",price:5300,rooms:4,baths:6,cars:3,area:617,year:2022,age:5,status:"متاح",lat:24.798644586623418,lng:46.72327833037388,facing:"شرقي",purpose:"إيجار",desc:"فيلا فاخرة بتصميم حديث ومساحات خضراء في حي البساتين بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["خزان أرضي","حديقة خاصة","سطح خاص","مسبح خارجي"],trust:"verified",agent:{name:"شركة أصول العقارية",role:"وسيط مرخص",phone:"+966554445566"}},
{id:110,title:"محل  في حي نمار",type:"محل",loc:"حي نمار، الرياض",district:"حي نمار",city:"الرياض",price:660000,rooms:1,baths:2,cars:1,area:60,year:2021,age:4,status:"متاح",lat:24.758297479410288,lng:46.647834723640436,facing:"شرقي",purpose:"بيع",desc:"محل مميز مع واجهة عرض واسعة في حي نمار بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["دورات مياه","واجهة واسعة","مستودع","حركة مرور عالية"],trust:"direct",agent:{name:"مكة للاستثمار العقاري",role:"وسيط مرخص",phone:"+966558888777"}},
{id:111,title:"مكتب  في حي الخبر الشمالية",type:"مكتب",loc:"حي الخبر الشمالية، الخبر",district:"حي الخبر الشمالية",city:"الخبر",price:7000,rooms:3,baths:2,cars:2,area:197,year:2023,age:0,status:"متاح",lat:24.717665469169397,lng:46.64481114012874,facing:"غربي",purpose:"إيجار",desc:"مكتب تنفيذي بإطلالة على المدينة في حي الخبر الشمالية بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["استقبال","إطلالة"],trust:"office",agent:{name:"الخبر العقارية",role:"وسيط مرخص",phone:"+966556667788"}},
{id:112,title:"قصر  في حي الخالدية",type:"قصر",loc:"حي الخالدية، الدمام",district:"حي الخالدية",city:"الدمام",price:42600,rooms:9,baths:6,cars:3,area:1475,year:2018,age:7,status:"متاح",lat:24.750854174041734,lng:46.854313685491704,facing:"غربي",purpose:"إيجار",desc:"قصر أنيق مع حدائق واسعة ومرافق ترفيهية في حي الخالدية بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["ملعب","خزائن أمنية"],trust:"verified",agent:{name:"مكتب الديار العقارية",role:"وسيط مرخص",phone:"+966501234567"}},
{id:113,title:"محل  في حي القابل",type:"محل",loc:"حي القابل، حائل",district:"حي القابل",city:"حائل",price:1750000,rooms:2,baths:2,cars:0,area:96,year:2024,age:7,status:"متاح",lat:24.87125501761274,lng:46.85367260906368,facing:"شرقي",purpose:"بيع",desc:"محل مميز مع واجهة عرض واسعة في حي القابل بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["مستودع","دورات مياه","موقف قريب","حركة مرور عالية","واجهة واسعة"],trust:"office",agent:{name:"مكة للاستثمار العقاري",role:"وسيط مرخص",phone:"+966558888777"}},
{id:114,title:"فيلا  في حي الحمراء",type:"فيلا",loc:"حي الحمراء، جدة",district:"حي الحمراء",city:"جدة",price:13300,rooms:4,baths:4,cars:4,area:698,year:2020,age:1,status:"متاح",lat:24.723531949843014,lng:46.64189370307571,facing:"شرقي",purpose:"إيجار",desc:"فيلا فاخرة بتصميم حديث ومساحات خضراء في حي الحمراء بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["موقف سيارات","مسبح خارجي","مطبخ مفروش","غرفة خادمة","خزان أرضي"],trust:"office",agent:{name:"مكتب الدار العقارية",role:"وسيط مرخص",phone:"+966555123456"}},
{id:115,title:"مزرعة  في حي الفيحاء",type:"مزرعة",loc:"حي الفيحاء، الخبر",district:"حي الفيحاء",city:"الخبر",price:7080000,rooms:2,baths:1,cars:2,area:30946,year:2022,age:2,status:"متاح",lat:24.827043838489033,lng:46.67878593885225,facing:"شمالي",purpose:"بيع",desc:"مزرعة منتجة بها أشجار مثمرة في حي الفيحاء بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["بيوت ضيافة","ملعب","مسبح"],trust:"direct",agent:{name:"مكتب الديار العقارية",role:"وسيط مرخص",phone:"+966501234567"}},
{id:116,title:"مكتب  في حي الزهراء",type:"مكتب",loc:"حي الزهراء، جدة",district:"حي الزهراء",city:"جدة",price:1320000,rooms:2,baths:2,cars:0,area:141,year:2021,age:7,status:"متاح",lat:24.76986821975258,lng:46.66380682224429,facing:"غربي",purpose:"بيع",desc:"مكتب إداري مجهز بالكامل في برج تجاري في حي الزهراء بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["قاعة اجتماعات","موقف سيارات","استقبال","أمن 24/7"],trust:"direct",agent:{name:"مكة للاستثمار العقاري",role:"وسيط مرخص",phone:"+966558888777"}},
{id:117,title:"بنتهاوس  في حي الخبر الشمالية",type:"بنتهاوس",loc:"حي الخبر الشمالية، الخبر",district:"حي الخبر الشمالية",city:"الخبر",price:2340000,rooms:3,baths:2,cars:1,area:350,year:2024,age:1,status:"متاح",lat:24.70334803175855,lng:46.88702497417817,facing:"شرقي",purpose:"بيع",desc:"بنتهاوس فاخر مع إطلالة 360 درجة في حي الخبر الشمالية بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["إطلالة بانورامية","مسبح خاص"],trust:"verified",agent:{name:"مكتب الديار العقارية",role:"وسيط مرخص",phone:"+966501234567"}},
{id:118,title:"أرض  في حي القدس",type:"أرض",loc:"حي القدس، الرياض",district:"حي القدس",city:"الرياض",price:3530000,rooms:0,baths:0,cars:0,area:2500,year:2019,age:2,status:"متاح",lat:24.89051893887822,lng:46.83611274920304,facing:"شمالي",purpose:"بيع",desc:"أرض سكنية مميزة على شارع رئيسي في حي القدس بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["سكني","تجاري","شارعين"],trust:"office",agent:{name:"الخبر العقارية",role:"وسيط مرخص",phone:"+966556667788"}},
{id:119,title:"فيلا  في حي المرجان",type:"فيلا",loc:"حي المرجان، الدمام",district:"حي المرجان",city:"الدمام",price:4800,rooms:4,baths:4,cars:3,area:534,year:2020,age:5,status:"متاح",lat:24.738920532272754,lng:46.69043267197709,facing:"شمالي",purpose:"إيجار",desc:"فيلا دوبلكس بإطلالة ساحرة وحديقة خاصة في حي المرجان بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["مطبخ مفروش","غرفة خادمة","نادي صحي"],trust:"verified",agent:{name:"الدمام العقارية الأولى",role:"وسيط مرخص",phone:"+966557778899"}},
{id:120,title:"شقة مميزة في حي الخبر الشمالية",type:"شقة",loc:"حي الخبر الشمالية، الخبر",district:"حي الخبر الشمالية",city:"الخبر",price:1020000,rooms:4,baths:4,cars:2,area:126,year:2022,age:7,status:"حصري",lat:24.780337022371118,lng:46.83065865880808,facing:"شرقي",purpose:"بيع",desc:"شقة مفروشة بالكامل جاهزة للسكن في حي الخبر الشمالية بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["إطلالة بانورامية","موقف سيارات","غرفة خادمة","مفروشة بالكامل"],trust:"direct",agent:{name:"مكتب الدار العقارية",role:"وسيط مرخص",phone:"+966555123456"}},
{id:121,title:"مزرعة  في حي الخبر الشمالية",type:"مزرعة",loc:"حي الخبر الشمالية، الخبر",district:"حي الخبر الشمالية",city:"الخبر",price:10330000,rooms:3,baths:1,cars:3,area:14187,year:2021,age:0,status:"متاح",lat:24.721870426701102,lng:46.79998994171078,facing:"شمالي",purpose:"بيع",desc:"مزرعة استثمارية بمساحة كبيرة في حي الخبر الشمالية بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["بيوت ضيافة","مياه وفيرة"],trust:"direct",agent:{name:"شركة أصول العقارية",role:"وسيط مرخص",phone:"+966554445566"}},
{id:122,title:"قصر  في حي الشفاء",type:"قصر",loc:"حي الشفاء، حائل",district:"حي الشفاء",city:"حائل",price:38600,rooms:11,baths:9,cars:4,area:1125,year:2020,age:2,status:"متاح",lat:24.890692271335844,lng:46.75115952017868,facing:"شرقي",purpose:"إيجار",desc:"قصر أنيق مع حدائق واسعة ومرافق ترفيهية في حي الشفاء بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["حدائق واسعة","خزائن أمنية","نادي صحي"],trust:"office",agent:{name:"شركة أصول العقارية",role:"وسيط مرخص",phone:"+966554445566"}},
{id:123,title:"مزرعة  في حي الوادي",type:"مزرعة",loc:"حي الوادي، الرياض",district:"حي الوادي",city:"الرياض",price:6210000,rooms:3,baths:4,cars:4,area:20801,year:2025,age:4,status:"متاح",lat:24.714355412063377,lng:46.874036797135155,facing:"غربي",purpose:"بيع",desc:"مزرعة استثمارية بمساحة كبيرة في حي الوادي بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["مياه وفيرة","بيوت ضيافة","مسبح","ملعب"],trust:"verified",agent:{name:"مكة للاستثمار العقاري",role:"وسيط مرخص",phone:"+966558888777"}},
{id:124,title:"مزرعة  في الشوقية",type:"مزرعة",loc:"الشوقية، مكة",district:"الشوقية",city:"مكة",price:14700,rooms:4,baths:4,cars:2,area:43752,year:2023,age:0,status:"متاح",lat:24.7220339840913,lng:46.80616163780344,facing:"غربي",purpose:"إيجار",desc:"مزرعة استثمارية بمساحة كبيرة في الشوقية بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["أشجار مثمرة","مسبح","مخيم","ملعب"],trust:"direct",agent:{name:"مكتب الدار العقارية",role:"وسيط مرخص",phone:"+966555123456"}},
{id:125,title:"مكتب  في المسفلة",type:"مكتب",loc:"المسفلة، مكة",district:"المسفلة",city:"مكة",price:6100,rooms:3,baths:2,cars:2,area:175,year:2022,age:2,status:"متاح",lat:24.83056162400724,lng:46.749673423199575,facing:"شرقي",purpose:"إيجار",desc:"مكتب إداري مجهز بالكامل في برج تجاري في المسفلة بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["قاعة اجتماعات","إطلالة","أمن 24/7","مطبخ","استقبال"],trust:"verified",agent:{name:"مكتب الدار العقارية",role:"وسيط مرخص",phone:"+966555123456"}},
{id:126,title:"مكتب  في حي الحمراء",type:"مكتب",loc:"حي الحمراء، جدة",district:"حي الحمراء",city:"جدة",price:13000,rooms:3,baths:2,cars:1,area:180,year:2018,age:7,status:"متاح",lat:24.891718249134136,lng:46.71220313309228,facing:"جنوبي",purpose:"إيجار",desc:"مكتب إداري مجهز بالكامل في برج تجاري في حي الحمراء بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["قاعة اجتماعات","موقف سيارات","مطبخ","أمن 24/7"],trust:"office",agent:{name:"مكتب جدة العقاري",role:"وسيط مرخص",phone:"+966555987654"}},
{id:127,title:"مكتب  في حي الفيحاء",type:"مكتب",loc:"حي الفيحاء، الخبر",district:"حي الفيحاء",city:"الخبر",price:1370000,rooms:3,baths:1,cars:2,area:127,year:2023,age:1,status:"متاح",lat:24.803923563719884,lng:46.7188574594888,facing:"شرقي",purpose:"بيع",desc:"مساحة مكتبية مرنة تناسب الشركات الناشئة في حي الفيحاء بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["قاعة اجتماعات","موقف سيارات","استقبال"],trust:"verified",agent:{name:"الدمام العقارية الأولى",role:"وسيط مرخص",phone:"+966557778899"}},
{id:128,title:"شقة  في حي السليمانية",type:"شقة",loc:"حي السليمانية، الرياض",district:"حي السليمانية",city:"الرياض",price:320000,rooms:3,baths:1,cars:1,area:223,year:2023,age:7,status:"متاح",lat:24.752047498282614,lng:46.64583283789788,facing:"جنوبي",purpose:"بيع",desc:"شقة مفروشة بالكامل جاهزة للسكن في حي السليمانية بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["مطبخ مفروش","غرفة خادمة","نادي صحي"],trust:"office",agent:{name:"مكتب الرياض للمكاتب",role:"وسيط مرخص",phone:"+966555111222"}},
{id:129,title:"مزرعة  في العزيزية",type:"مزرعة",loc:"العزيزية، مكة",district:"العزيزية",city:"مكة",price:3180000,rooms:5,baths:2,cars:4,area:37619,year:2025,age:2,status:"متاح",lat:24.830395891241114,lng:46.62645992106394,facing:"غربي",purpose:"بيع",desc:"مزرعة منتجة بها أشجار مثمرة في العزيزية بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["مخيم","بيوت ضيافة","ملعب","مسبح"],trust:"direct",agent:{name:"الخبر العقارية",role:"وسيط مرخص",phone:"+966556667788"}},
{id:130,title:"مكتب  في الخالدية",type:"مكتب",loc:"الخالدية، مكة",district:"الخالدية",city:"مكة",price:1510000,rooms:1,baths:1,cars:1,area:125,year:2023,age:1,status:"متاح",lat:24.881445027277532,lng:46.6883723401003,facing:"شمالي",purpose:"بيع",desc:"مساحة مكتبية مرنة تناسب الشركات الناشئة في الخالدية بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["أمن 24/7","مطبخ","استقبال","موقف سيارات","قاعة اجتماعات"],trust:"direct",agent:{name:"حائل العقارية",role:"وسيط مرخص",phone:"+966555556677"}},
{id:131,title:"أرض  في حي مشرفة",type:"أرض",loc:"حي مشرفة، جدة",district:"حي مشرفة",city:"جدة",price:2470000,rooms:0,baths:0,cars:0,area:3893,year:2021,age:6,status:"متاح",lat:24.84379432295648,lng:46.843556835408464,facing:"غربي",purpose:"بيع",desc:"أرض سكنية مميزة على شارع رئيسي في حي مشرفة بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["تجاري","مخطط","سكني","شارعين","مرافق"],trust:"office",agent:{name:"مكتب الرياض للمكاتب",role:"وسيط مرخص",phone:"+966555111222"}},
{id:132,title:"شقة مميزة في حي النورس",type:"شقة",loc:"حي النورس، الدمام",district:"حي النورس",city:"الدمام",price:3800,rooms:1,baths:3,cars:2,area:98,year:2018,age:4,status:"حصري",lat:24.859967421191772,lng:46.72147162921126,facing:"جنوبي",purpose:"إيجار",desc:"شقة حديثة التشطيب قريبة من جميع الخدمات في حي النورس بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["إطلالة بانورامية","موقف سيارات"],trust:"office",agent:{name:"الخبر العقارية",role:"وسيط مرخص",phone:"+966556667788"}},
{id:133,title:"أرض  في حي بلجرشي",type:"أرض",loc:"حي بلجرشي، حائل",district:"حي بلجرشي",city:"حائل",price:4960000,rooms:0,baths:0,cars:0,area:2606,year:2025,age:4,status:"متاح",lat:24.802267165466514,lng:46.66521760972871,facing:"شرقي",purpose:"بيع",desc:"أرض تجارية في موقع استراتيجي في حي بلجرشي بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["مرافق","شارعين","مخطط","تجاري","سكني"],trust:"direct",agent:{name:"الدمام العقارية الأولى",role:"وسيط مرخص",phone:"+966557778899"}},
{id:134,title:"قصر  في حي الحزام الذهبي",type:"قصر",loc:"حي الحزام الذهبي، الخبر",district:"حي الحزام الذهبي",city:"الخبر",price:46200,rooms:9,baths:8,cars:3,area:1893,year:2022,age:6,status:"متاح",lat:24.822171231060587,lng:46.79572258942683,facing:"شمالي",purpose:"إيجار",desc:"قصر فاخر بتصميم معماري فريد في حي الحزام الذهبي بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["مسبح أولمبي","غرفة سينما"],trust:"direct",agent:{name:"شركة أصول العقارية",role:"وسيط مرخص",phone:"+966554445566"}},
{id:135,title:"مكتب  في حي القابل",type:"مكتب",loc:"حي القابل، حائل",district:"حي القابل",city:"حائل",price:1070000,rooms:4,baths:2,cars:0,area:76,year:2021,age:4,status:"متاح",lat:24.8471659221751,lng:46.69183584076512,facing:"شمالي",purpose:"بيع",desc:"مساحة مكتبية مرنة تناسب الشركات الناشئة في حي القابل بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["إطلالة","أمن 24/7","مطبخ","موقف سيارات","استقبال"],trust:"direct",agent:{name:"مكتب الدار العقارية",role:"وسيط مرخص",phone:"+966555123456"}},
{id:136,title:"مكتب  في حي العليا",type:"مكتب",loc:"حي العليا، الخبر",district:"حي العليا",city:"الخبر",price:13600,rooms:4,baths:2,cars:1,area:102,year:2021,age:4,status:"متاح",lat:24.70392999027981,lng:46.88141155779884,facing:"شمالي",purpose:"إيجار",desc:"مكتب تنفيذي بإطلالة على المدينة في حي العليا بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["أمن 24/7","موقف سيارات"],trust:"office",agent:{name:"شركة أصول العقارية",role:"وسيط مرخص",phone:"+966554445566"}},
{id:137,title:"مزرعة  في حي القابل",type:"مزرعة",loc:"حي القابل، حائل",district:"حي القابل",city:"حائل",price:9600,rooms:3,baths:1,cars:4,area:37990,year:2019,age:0,status:"متاح",lat:24.772108921742472,lng:46.61118291032593,facing:"شرقي",purpose:"إيجار",desc:"مزرعة منتجة بها أشجار مثمرة في حي القابل بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["مسبح","أشجار مثمرة"],trust:"office",agent:{name:"مكتب الرياض للمكاتب",role:"وسيط مرخص",phone:"+966555111222"}},
{id:138,title:"مكتب  في حي الفردوس",type:"مكتب",loc:"حي الفردوس، الدمام",district:"حي الفردوس",city:"الدمام",price:8400,rooms:1,baths:1,cars:0,area:175,year:2025,age:0,status:"متاح",lat:24.836746167948963,lng:46.62279889748346,facing:"شمالي",purpose:"إيجار",desc:"مكتب إداري مجهز بالكامل في برج تجاري في حي الفردوس بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["إطلالة","أمن 24/7","استقبال","موقف سيارات"],trust:"office",agent:{name:"مكتب الدار العقارية",role:"وسيط مرخص",phone:"+966555123456"}},
{id:139,title:"قصر  في حي النورس",type:"قصر",loc:"حي النورس، الدمام",district:"حي النورس",city:"الدمام",price:40500,rooms:7,baths:5,cars:6,area:1919,year:2024,age:2,status:"متاح",lat:24.780974729658382,lng:46.74372246566874,facing:"شمالي",purpose:"إيجار",desc:"قصر أنيق مع حدائق واسعة ومرافق ترفيهية في حي النورس بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["مسبح أولمبي","ملعب","غرفة سينما","خزائن أمنية"],trust:"direct",agent:{name:"مكتب الدار العقارية",role:"وسيط مرخص",phone:"+966555123456"}},
{id:140,title:"شقة  في حي المصيف",type:"شقة",loc:"حي المصيف، الرياض",district:"حي المصيف",city:"الرياض",price:770000,rooms:2,baths:3,cars:1,area:219,year:2018,age:1,status:"متاح",lat:24.83649111078684,lng:46.73144801686275,facing:"شمالي",purpose:"بيع",desc:"شقة مفروشة بالكامل جاهزة للسكن في حي المصيف بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["أمن 24/7","إطلالة بانورامية"],trust:"verified",agent:{name:"حائل العقارية",role:"وسيط مرخص",phone:"+966555556677"}},
{id:141,title:"بنتهاوس  في حي المغرزات",type:"بنتهاوس",loc:"حي المغرزات، الرياض",district:"حي المغرزات",city:"الرياض",price:18700,rooms:6,baths:4,cars:1,area:296,year:2021,age:3,status:"متاح",lat:24.888514742953944,lng:46.62136968724665,facing:"غربي",purpose:"إيجار",desc:"بنتهاوس فاخر مع إطلالة 360 درجة في حي المغرزات بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["نادي صحي","مسبح خاص","غرفة سينما","تراس خاص","إطلالة بانورامية"],trust:"office",agent:{name:"مكتب جدة العقاري",role:"وسيط مرخص",phone:"+966555987654"}},
{id:142,title:"فيلا  في حي العليا",type:"فيلا",loc:"حي العليا، الخبر",district:"حي العليا",city:"الخبر",price:1780000,rooms:5,baths:6,cars:3,area:475,year:2024,age:3,status:"متاح",lat:24.820614985849947,lng:46.68142956457791,facing:"شمالي",purpose:"بيع",desc:"فيلا مميزة بتشطيبات عصرية وراقية في حي العليا بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["حديقة خاصة","مسبح خارجي"],trust:"office",agent:{name:"الدمام العقارية الأولى",role:"وسيط مرخص",phone:"+966557778899"}},
{id:143,title:"محل  في حي المرجان",type:"محل",loc:"حي المرجان، الدمام",district:"حي المرجان",city:"الدمام",price:1580000,rooms:1,baths:2,cars:1,area:130,year:2021,age:4,status:"متاح",lat:24.850973468551125,lng:46.68723809827577,facing:"شرقي",purpose:"بيع",desc:"محل مميز مع واجهة عرض واسعة في حي المرجان بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["دورات مياه","مستودع","واجهة واسعة"],trust:"office",agent:{name:"شركة أصول العقارية",role:"وسيط مرخص",phone:"+966554445566"}},
{id:144,title:"قصر مميزة في حي القابل",type:"قصر",loc:"حي القابل، حائل",district:"حي القابل",city:"حائل",price:12400000,rooms:8,baths:8,cars:6,area:970,year:2025,age:7,status:"حصري",lat:24.707580374824445,lng:46.76227921201193,facing:"شمالي",purpose:"بيع",desc:"قصر الملكية مع صالات استقبال فخمة في حي القابل بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["مسبح أولمبي","نادي صحي","حدائق واسعة","غرفة سينما"],trust:"direct",agent:{name:"مكتب الرياض للمكاتب",role:"وسيط مرخص",phone:"+966555111222"}},
{id:145,title:"شاليه  في حي النورس",type:"شاليه",loc:"حي النورس، الدمام",district:"حي النورس",city:"الدمام",price:2620000,rooms:2,baths:3,cars:3,area:219,year:2019,age:7,status:"متاح",lat:24.773110135784055,lng:46.71156896232174,facing:"غربي",purpose:"بيع",desc:"شاليه فاخر بمسبح وحديقة خاصة في حي النورس بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["ملعب أطفال","شاطئ خاص"],trust:"verified",agent:{name:"مكتب الدار العقارية",role:"وسيط مرخص",phone:"+966555123456"}},
{id:146,title:"شاليه  في حي المخواة",type:"شاليه",loc:"حي المخواة، حائل",district:"حي المخواة",city:"حائل",price:1080000,rooms:4,baths:3,cars:3,area:230,year:2022,age:3,status:"متاح",lat:24.85827804623966,lng:46.75323530250891,facing:"شمالي",purpose:"بيع",desc:"شاليه فاخر بمسبح وحديقة خاصة في حي المخواة بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["مسبح","ملعب أطفال"],trust:"direct",agent:{name:"شركة أصول العقارية",role:"وسيط مرخص",phone:"+966554445566"}},
{id:147,title:"بنتهاوس  في حي العليا",type:"بنتهاوس",loc:"حي العليا، الرياض",district:"حي العليا",city:"الرياض",price:2900000,rooms:4,baths:2,cars:3,area:403,year:2024,age:4,status:"متاح",lat:24.77760108602379,lng:46.7478975615712,facing:"شرقي",purpose:"بيع",desc:"بنتهاوس فريد مع مسبح خاص وإطلالة بحرية في حي العليا بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["مسبح خاص","نادي صحي"],trust:"office",agent:{name:"مكتب جدة العقاري",role:"وسيط مرخص",phone:"+966555987654"}},
{id:148,title:"قصر  في حي لبن",type:"قصر",loc:"حي لبن، الرياض",district:"حي لبن",city:"الرياض",price:9220000,rooms:7,baths:9,cars:6,area:2839,year:2024,age:5,status:"متاح",lat:24.87838944697755,lng:46.603806219456146,facing:"جنوبي",purpose:"بيع",desc:"قصر أنيق مع حدائق واسعة ومرافق ترفيهية في حي لبن بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["ملعب","مسبح أولمبي","غرفة سينما"],trust:"verified",agent:{name:"الدمام العقارية الأولى",role:"وسيط مرخص",phone:"+966557778899"}},
{id:149,title:"مكتب  في حي المحمدية",type:"مكتب",loc:"حي المحمدية، جدة",district:"حي المحمدية",city:"جدة",price:9500,rooms:4,baths:2,cars:1,area:161,year:2018,age:4,status:"متاح",lat:24.71073738992621,lng:46.84195628733619,facing:"شرقي",purpose:"إيجار",desc:"مكتب إداري مجهز بالكامل في برج تجاري في حي المحمدية بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["قاعة اجتماعات","موقف سيارات"],trust:"direct",agent:{name:"شركة أصول العقارية",role:"وسيط مرخص",phone:"+966554445566"}},
{id:150,title:"فيلا  في حي البساتين",type:"فيلا",loc:"حي البساتين، جدة",district:"حي البساتين",city:"جدة",price:3500,rooms:4,baths:5,cars:2,area:564,year:2022,age:3,status:"متاح",lat:24.87054823818908,lng:46.60132796997385,facing:"جنوبي",purpose:"إيجار",desc:"فيلا عائلية واسعة في حي هادئ مع جميع الخدمات في حي البساتين بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["مجلس مستقل","حديقة خاصة","نادي صحي","سطح خاص"],trust:"office",agent:{name:"شركة أصول العقارية",role:"وسيط مرخص",phone:"+966554445566"}},
{id:151,title:"مكتب  في حي المخواة",type:"مكتب",loc:"حي المخواة، حائل",district:"حي المخواة",city:"حائل",price:10500,rooms:3,baths:2,cars:0,area:87,year:2025,age:7,status:"متاح",lat:24.871814711293297,lng:46.886595043997154,facing:"شرقي",purpose:"إيجار",desc:"مساحة مكتبية مرنة تناسب الشركات الناشئة في حي المخواة بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["استقبال","مطبخ","قاعة اجتماعات","موقف سيارات","أمن 24/7"],trust:"verified",agent:{name:"الدمام العقارية الأولى",role:"وسيط مرخص",phone:"+966557778899"}},
{id:152,title:"مزرعة  في حي الكندرة",type:"مزرعة",loc:"حي الكندرة، جدة",district:"حي الكندرة",city:"جدة",price:5990000,rooms:5,baths:2,cars:4,area:36676,year:2020,age:0,status:"متاح",lat:24.79445452973661,lng:46.758543724898864,facing:"جنوبي",purpose:"بيع",desc:"مزرعة ريفية بنظام ري متطور في حي الكندرة بالرياض، عائد استثماري ممتاز وموقع متميز",images:["/uploads/properties/default.jpg"],pano:null,features:["مخيم","مياه وفيرة","مسبح","بيوت ضيافة"],trust:"direct",agent:{name:"مكتب الرياض للمكاتب",role:"وسيط مرخص",phone:"+966555111222"}}
];

async function loadProperties(){
  var d=null;
  for(var attempt=0;attempt<4;attempt++){
    d=await api('/properties/all');
    if(d&&Array.isArray(d)&&d.length)break;
    if(attempt<3)await new Promise(function(r){setTimeout(r,3000)});
  }
  if(d&&Array.isArray(d)&&d.length){
    A=normProps(d).map(function(p){return Object.assign({},p,{loc:p.loc||(p.district+'، '+p.city),status:p.isFeatured?'حصري':'متاح',agent:p.agent||{name:p.agentName||'مكتب الديار العقارية',role:'وسيط مرخص',phone:p.agentPhone||'+966501234567'}})});
  }else{
    A=normProps(FALLBACK);
  }
  try{
    var lmap=JSON.parse(localStorage.getItem('darak_local_panos')||'{}');
    if(lmap&&Object.keys(lmap).length){
      A.forEach(function(p){if(p&&lmap[p.id]!==undefined)p.panoramicImage=lmap[p.id]});
    }
  }catch(e){}
  if(document.getElementById('pg'))render();
  if(document.getElementById('homeStats'))renderHomeSections();
  var sel=document.getElementById('hc');
  if(sel){
    var cs=[...new Set(A.map(function(p){return p.city}).filter(Boolean))];
    sel.innerHTML='<option value="">المدينة</option>';
    cs.forEach(function(c){var o=document.createElement('option');o.value=c;o.textContent=c;sel.appendChild(o)});
  }
  if(authToken){api('/auth/me').then(function(r){if(r&&r.success){user=r.user;updateUserUI()}}).catch(function(){})}
  api('/market/overview').then(function(d){if(d&&d.success&&d.sama&&d.sama.repoRate){window._samaRate=d.sama.repoRate;updateFinRate()}}).catch(function(){});
}
loadProperties();
var payParam=new URLSearchParams(location.search).get('payment');
if(payParam){
  setTimeout(function(){
    if(payParam==='success'){toast('✅ تم تفعيل الباقة بنجاح');if(authToken){api('/auth/me').then(function(r){if(r&&r.success){user=r.user;updateUserUI()}}).catch(function(){})}}
    else if(payParam==='failed'){toast('⚠️ تعذر إتمام الدفع، حاول مرة أخرى')}
    history.replaceState({},document.title,location.pathname);
  },1200);
}
if(location.hash&&location.hash.indexOf('#page-')===0){setTimeout(function(){nav(location.hash.replace('#page-',''))},300)}
window.addEventListener('hashchange',function(){var h=location.hash;if(h&&h.indexOf('#page-')===0)nav(h.replace('#page-',''))});
