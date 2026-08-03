/* invest.js — المحفظة الاستثمارية داخل التطبيق الأصلي (localStorage) */
(function(){
  var $=function(id){return document.getElementById(id)};
  var curUser=null;

  function load(){
    try{curUser=JSON.parse(localStorage.getItem('darak_user')||'null')}catch(e){curUser=null}
    var gate=$('invest-gate'),content=$('invest-content');
    if(!gate||!content)return;
    if(!curUser||!curUser.email){
      gate.style.display='block';content.style.display='none';
      return;
    }
    curUser.investments=curUser.investments||[];
    curUser.balance=Number(curUser.balance)||0;
    gate.style.display='none';content.style.display='block';
    var nm=$('user-display-name');if(nm)nm.textContent=curUser.name||'مستثمر';
    renderBalance();
    renderInvestments();
  }

  function renderBalance(){
    var e=$('balance-display');
    if(e)e.textContent=Number(curUser.balance||0).toLocaleString('en-US')+' ر.س';
  }

  function renderInvestments(){
    var box=$('my-investments-list');if(!box)return;
    var list=curUser.investments||[];
    if(!list.length){box.innerHTML='<div class="empty-state">لا توجد استثمارات بعد — ابدأ باستثمار أول فرصة ✨</div>';return}
    box.innerHTML=list.map(function(iv){
      var d=iv.at?new Date(iv.at):new Date();
      return '<div class="invest-item"><div class="invest-item-name">📈 '+(iv.name||'')+'</div>'+
        '<div class="invest-item-meta"><span>المبلغ: <strong>'+Number(iv.amount).toLocaleString('en-US')+' ر.س</strong></span><span class="invest-item-roi">+'+iv.roi+' عائد</span></div>'+
        '<div class="invest-item-at">'+d.toLocaleDateString('ar-SA')+'</div></div>';
    }).join('');
  }

  function save(){localStorage.setItem('darak_user',JSON.stringify(curUser))}

  window.handleInvest=function(name,amount,roi){
    if(!curUser||!curUser.email){toast('سجّل الدخول أولًا للاستثمار');return}
    var amt=Number(amount);
    if(isNaN(amt)||amt<=0)return;
    if((curUser.balance||0)<amt){toast('رصيد غير كافٍ للاستثمار');return}
    curUser.balance-=amt;
    curUser.investments.unshift({name:String(name),amount:amt,roi:String(roi),at:new Date().toISOString()});
    save();
    renderBalance();
    renderInvestments();
    toast('تم الاستثمار في '+name+' ✓');
  };

  var bd=$('btn-deposit');
  if(bd)bd.addEventListener('click',function(){
    if(!curUser||!curUser.email){toast('سجّل الدخول أولًا');return}
    var v=prompt('المبلغ المراد إيداعه (ر.س):');
    if(v===null)return;
    var amt=parseFloat(v);
    if(isNaN(amt)||amt<=0){toast('أدخل مبلغًا صحيحًا');return}
    curUser.balance+=amt;
    save();
    renderBalance();
    toast('تم الإيداع +'+Number(amt).toLocaleString('en-US')+' ر.س ✓');
  });

  var lo=$('btn-logout');
  if(lo)lo.addEventListener('click',function(){localStorage.removeItem('darak_user');toast('تم تسجيل الخروج');load()});

  window.investRefresh=load;
  if(document.readyState==='complete'||document.readyState==='interactive'){load()}
  else{document.addEventListener('DOMContentLoaded',load)}
})();
