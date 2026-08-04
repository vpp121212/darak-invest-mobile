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
    var r=await fetch(API+path,{...opts,headers:{...headers,...(opts&&opts.headers||{})},signal:AbortSignal.timeout?AbortSignal.timeout(30000):undefined});
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
function pImg(p){return absImg((p.images&&p.images[0])||'/uploads/properties/default.jpg')}
function pFallback(p){return API_ORIGIN+'/uploads/properties/default.jpg'}
function pPrice(p){return fmt(p.price)+' ر.س'+(p.purpose==='إيجار'?'/سنوي':'')}
function pLoc(p){return p.loc||(p.district+'، '+p.city)}

function toast(msg){
  var c=document.getElementById('toasts'),t=document.createElement('div');
  t.className='tt';t.textContent=msg;c.appendChild(t);
  setTimeout(function(){t.remove()},3500);
}
