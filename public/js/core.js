var A=[],F=JSON.parse(localStorage.getItem('darak_favs')||'[]'),cur='',user=null,mapInstance=null,currentDetailImages=[];
var API='https://darak-invest-backend-j6hy.onrender.com/api';
if(location.hostname==='localhost'||location.hostname==='127.0.0.1'||location.port==='5000'||location.hostname.indexOf('trycloudflare')>-1){API=location.origin+'/api';}
if(location.hostname==='darak-invest-backend-j6hy.onrender.com'){API=location.origin+'/api';}
if(window.location.protocol==='file:'){API='http://172.20.10.3:5000/api';}
var authToken=localStorage.getItem('darak_token')||null;
var API_ORIGIN=API.indexOf('/api')>-1?API.split('/api')[0]:API;
function absImg(s){return s&&s.indexOf('/')===0?API_ORIGIN+s:s}
function normProps(list){return(list||[]).map(function(p){var np=Object.assign({},p);if(np.images)np.images=np.images.map(absImg);if(np.panoramicImage)np.panoramicImage=absImg(np.panoramicImage);if(np.pano)np.pano=absImg(np.pano);return np})}

function fmtErr(d){
  if(d.details&&d.details.length)return d.details.map(function(e){return e.message||e.field+': '+e.message}).join(' | ');
  return d.message||d.error||'خطأ في الخادم';
}
async function api(path,opts){
  var headers={'Content-Type':'application/json'};
  if(authToken)headers['Authorization']='Bearer '+authToken;
  try{
    var r=await fetch(API+path,{...opts,headers:{...headers,...(opts&&opts.headers||{})},signal:AbortSignal.timeout?AbortSignal.timeout(10000):undefined});
    var d=await r.json().catch(function(){return{}});
    if(!r.ok){return {error:fmtErr(d),code:d.code||'UNKNOWN',status:r.status}}
    return d;
  }catch(e){return {error:'تعذر الاتصال بالخادم',code:'NETWORK_ERROR'}}
}

function fmt(n){return Number(n||0).toLocaleString('en')}

// تهريب HTML لمنع XSS عند حقن بيانات العقارات في innerHTML (البيانات مصدرها
// إعلانات المستخدمين فيجب ألا تُفسَّر كوسوم/سكربت).
function esc(s){return String(s==null?'':s).replace(/[&<>"']/g,function(c){return{'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]})}
function tLbl(t){return t==='verified'?'✓ موثق':t==='office'?'🏢 مكتب':'👤 مباشر'}
function tCls(t){return t==='verified'?'v':t==='office'?'o':'d'}
function pImg(p){var s=(p.images&&p.images[0]);if(s&&s.indexOf('default.jpg')===-1)return absImg(s);return pImageSrc(p)}
function pFallback(p){return pImageSrc(p)}
function pGallery(p){
  var real=(p.images||[]).filter(function(s){return s&&s.indexOf('default.jpg')===-1}).map(absImg);
  var out=real.slice(0,1);
  if(!out.length)out.push(pImageSrc(p));
  out.push(pImageSrc(p,1),pImageSrc(p,2),pImageSrc(p,3));
  return out.slice(0,4);
}
function pImageSrc(p,v){
  var id=Math.abs((((p&&p.id)||0)+((v||0)*97))||7);
  var hue=(id*53)%360,hue2=(hue+70)%360;
  var type=(p&&p.type)||'عقار';
  var emoji=(type==='فيلا')?'🏠':(type==='شقة')?'🏢':(type==='بنتهاوس')?'🌆':(type==='مكتب')?'💼':(type==='مزرعة')?'🌳':(type==='أرض')?'📐':(type==='عمارة')?'🏙️':(type==='محل')?'🛍️':(type==='شاليه')?'🏖️':(type==='قصر')?'🏛️':'🏘️';
  var city=(p&&p.city)||'';
  var cx1=60+(id%440),cy1=30+(id%240);
  var cx2=(id*3)%540,cy2=(id*7)%330;
  var svg='<svg xmlns="http://www.w3.org/2000/svg" width="600" height="420" viewBox="0 0 600 420">'+
    '<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">'+
    '<stop offset="0" stop-color="hsl('+hue+',42%,40%)"/>'+
    '<stop offset="1" stop-color="hsl('+hue2+',48%,20%)"/>'+
    '</linearGradient></defs>'+
    '<rect width="600" height="420" fill="url(#g)"/>'+
    '<circle cx="'+cx1+'" cy="'+cy1+'" r="110" fill="rgba(255,255,255,0.06)"/>'+
    '<circle cx="'+cx2+'" cy="'+cy2+'" r="50" fill="rgba(255,255,255,0.08)"/>'+
    '<text x="300" y="200" font-size="96" text-anchor="middle">'+emoji+'</text>'+
    '<text x="300" y="292" font-size="32" font-weight="700" fill="rgba(255,255,255,0.92)" text-anchor="middle" font-family="Cairo,sans-serif">'+type+'</text>'+
    '<text x="300" y="340" font-size="20" fill="rgba(255,255,255,0.55)" text-anchor="middle" font-family="Cairo,sans-serif">'+city+'</text></svg>';
  return 'data:image/svg+xml;charset=utf-8,'+encodeURIComponent(svg);
}
function pPrice(p){return fmt(p.price)+' ر.س'+(p.purpose==='إيجار'?'/سنوي':'')}
function pLoc(p){return p.loc||(p.district+'، '+p.city)}

function toast(msg){
  var c=document.getElementById('toasts'),t=document.createElement('div');
  t.className='tt';t.textContent=msg;c.appendChild(t);
  setTimeout(function(){t.remove()},3500);
}
