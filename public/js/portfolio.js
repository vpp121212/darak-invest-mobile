/* portfolio.js — لوحة المحفظة الاستثمارية (نسخة محلية عبر localStorage، بدون Firebase) */
const $=id=>document.getElementById(id);
const setTxt=(id,t)=>{const e=$(id);if(e)e.textContent=t};
const fmt=n=>Number(n||0).toLocaleString('en-US');
let curUser=null;

function toast(msg){
  let t=$('toasts');
  if(!t){t=document.createElement('div');t.id='toasts';t.style.cssText='position:fixed;bottom:24px;left:50%;transform:translateX(-50%);z-index:999;display:flex;flex-direction:column;gap:8px;align-items:center';document.body.appendChild(t)}
  const x=document.createElement('div');
  x.textContent=msg;
  x.style.cssText='background:var(--c);color:var(--t);border:1px solid rgba(99,102,241,.4);border-radius:12px;padding:10px 16px;font-size:13px;box-shadow:0 10px 30px rgba(0,0,0,.5)';
  t.appendChild(x);
  setTimeout(()=>x.remove(),3200);
}

function save(){localStorage.setItem('darak_user',JSON.stringify(curUser))}

function renderBalance(){setTxt('balance-display',fmt(curUser.balance)+' ر.س')}

function renderInvestments(){
  const box=$('my-investments-list');if(!box)return;
  const list=curUser.investments||[];
  if(!list.length){box.innerHTML='<div class="empty-state">لا توجد استثمارات بعد — ابدأ باستثمار أول فرصة ✨</div>';return}
  box.innerHTML=list.map(iv=>{
    const d=iv.at?new Date(iv.at):new Date();
    return '<div class="invest-item"><div class="invest-item-name">📈 '+(iv.name||'')+'</div>'+
      '<div class="invest-item-meta"><span>المبلغ: <strong>'+fmt(iv.amount)+' ر.س</strong></span><span class="invest-item-roi">+'+iv.roi+' عائد</span></div>'+
      '<div class="invest-item-at">'+d.toLocaleDateString('ar-SA')+'</div></div>';
  }).join('');
}

function loadUser(){
  try{curUser=JSON.parse(localStorage.getItem('darak_user')||'null')}catch(e){curUser=null}
  if(!curUser||!curUser.email){window.location.href='auth.html';return}
  curUser.investments=curUser.investments||[];
  curUser.balance=Number(curUser.balance)||0;
  setTxt('user-display-name',curUser.name||'مستثمر');
  renderBalance();
  renderInvestments();
}

loadUser();

const btnLogout=$('btn-logout');
if(btnLogout)btnLogout.addEventListener('click',()=>{localStorage.removeItem('darak_user');window.location.href='auth.html'});

const btnDeposit=$('btn-deposit');
if(btnDeposit)btnDeposit.addEventListener('click',()=>{
  const v=prompt('المبلغ المراد إيداعه (ر.س):');
  if(v===null)return;
  const amt=parseFloat(v);
  if(isNaN(amt)||amt<=0){toast('أدخل مبلغًا صحيحًا');return}
  curUser.balance+=amt;
  save();
  renderBalance();
  toast('تم الإيداع +'+fmt(amt)+' ر.س ✓');
});

window.handleInvest=function(name,amount,roi){
  if(!curUser){toast('المحفظة غير متاحة');return}
  const amt=Number(amount);
  if(isNaN(amt)||amt<=0)return;
  if((curUser.balance||0)<amt){toast('رصيد غير كافٍ للاستثمار');return}
  curUser.balance-=amt;
  curUser.investments.unshift({name:String(name),amount:amt,roi:String(roi),at:new Date().toISOString()});
  save();
  renderBalance();
  renderInvestments();
  toast('تم الاستثمار في '+name+' ✓');
};
