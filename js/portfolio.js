/* portfolio.js — المحفظة والمفضلة (toggleFav + عرض المفضلة في الصفحة الشخصية) */

function renderPortfolio(){
  var pg=document.getElementById('pg-profile');if(!pg)return;
  var wrap=pg.querySelector('.prof');if(!wrap)return;
  var fav=A.filter(function(p){return F.indexOf(p.id)>-1});
  var box=document.getElementById('pf-favs');
  if(!box){box=document.createElement('div');box.id='pf-favs';wrap.appendChild(box)}
  if(!fav.length){
    box.innerHTML='<div style="font-size:12px;color:var(--m);margin-top:16px;text-align:center;padding:24px;border:1px dashed var(--b);border-radius:12px">💛 لم تُضف عقارات إلى المفضلة بعد — اضغط &#x2764; على أي عقار</div>';
    return;
  }
  var total=fav.reduce(function(s,p){return s+(p.price||0)},0);
  box.innerHTML=
    '<div style="font-size:13px;font-weight:700;color:var(--g);margin:18px 0 4px">💛 عقاراتك المفضلة <span style="color:var(--m);font-weight:500">('+fav.length+' · قيمة تقريبية '+fmt(total)+' ر.س)</span></div>'+
    '<div class="grid" style="grid-template-columns:1fr">'+fav.map(cardHTML).join('')+'</div>';
}

var __navPF=window.__baseNav||nav;
function nav(page){
  var r=__navPF(page);
  if(page==='profile')renderPortfolio();
  return r;
}

async function toggleFav(id,e){
  if(e)e.stopPropagation();
  var i=F.indexOf(id);if(i>-1)F.splice(i,1);else F.push(id);
  localStorage.setItem('darak_favs',JSON.stringify(F));
  if(authToken){await api('/properties/'+id+'/favorite',{method:'POST'}).catch(function(){})}
  if(document.getElementById('pg'))render();
  if(document.getElementById('pf-favs'))renderPortfolio();
  var profs=document.getElementById('prof-stats');
  if(profs&&F.length){profs.innerHTML='<div class="prof-stat"><div class="prof-stat-v">'+F.length+'</div><div class="prof-stat-l">المفضلة</div></div><div class="prof-stat"><div class="prof-stat-v">'+(A.length||'—')+'</div><div class="prof-stat-l">العقارات</div></div><div class="prof-stat"><div class="prof-stat-v">'+(user?'👤':'—')+'</div><div class="prof-stat-l">الحالة</div></div>'}
}

document.addEventListener('DOMContentLoaded',function(){
  if(document.getElementById('pg-profile'))setTimeout(renderPortfolio,600);
});
