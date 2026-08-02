/* portfolio.js — لوحة المحفظة الاستثمارية (وحدة ESM تعتمد Firebase Auth + Firestore) */
import { auth, db, isConfigured } from './firebase-mod.js';
import { onAuthStateChanged, signOut } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-auth.js";
import { doc, getDoc, setDoc, updateDoc } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-firestore.js";

const $=id=>document.getElementById(id);
const setTxt=(id,t)=>{const e=$(id);if(e)e.textContent=t};
const fmt=n=>Number(n||0).toLocaleString('en-US');
let curUser=null,curDoc=null,docRef=null;

function toast(msg){
  let t=$('toasts');
  if(!t){t=document.createElement('div');t.id='toasts';t.style.cssText='position:fixed;bottom:24px;left:50%;transform:translateX(-50%);z-index:999;display:flex;flex-direction:column;gap:8px;align-items:center';document.body.appendChild(t)}
  const x=document.createElement('div');
  x.textContent=msg;
  x.style.cssText='background:var(--c);color:var(--t);border:1px solid rgba(212,175,55,.4);border-radius:12px;padding:10px 16px;font-size:13px;box-shadow:0 10px 30px rgba(0,0,0,.5)';
  t.appendChild(x);
  setTimeout(()=>x.remove(),3200);
}

function renderBalance(){setTxt('balance-display',fmt(curDoc.balance)+' ر.س')}
function renderInvestments(){
  const box=$('my-investments-list');if(!box)return;
  const list=curDoc.investments||[];
  if(!list.length){box.innerHTML='<div class="empty-state">لا توجد استثمارات بعد — ابدأ باستثمار أول فرصة ✨</div>';return}
  box.innerHTML=list.map(iv=>{
    const d=iv.at?new Date(iv.at):new Date();
    return '<div class="invest-item"><div class="invest-item-name">📈 '+(iv.name||'')+'</div>'+
      '<div class="invest-item-meta"><span>المبلغ: <strong>'+fmt(iv.amount)+' ر.س</strong></span><span class="invest-item-roi">+'+iv.roi+' عائد</span></div>'+
      '<div class="invest-item-at">'+d.toLocaleDateString('ar-SA')+'</div></div>';
  }).join('');
}

async function loadUser(user){
  docRef=doc(db,'users',user.uid);
  let snap=await getDoc(docRef);
  if(!snap.exists()){
    await setDoc(docRef,{name:user.displayName||'مستثمر',email:user.email,balance:10000,investments:[],createdAt:new Date().toISOString()});
    snap=await getDoc(docRef);
  }
  curDoc=snap.data();
  setTxt('user-display-name',curDoc.name||'مستثمر');
  renderBalance();
  renderInvestments();
}

if(isConfigured){
  onAuthStateChanged(auth,user=>{
    if(!user){window.location.href='auth.html';return}
    curUser=user;
    setTxt('user-display-name','جاري التحميل...');
    loadUser(user).catch(e=>toast('تعذر تحميل المحفظة: '+(e.message||e)));
  });
}else{
  setTxt('user-display-name','⚠️ لم تُضبط مفاتيح Firebase');
  const el=$('my-investments-list');
  if(el)el.innerHTML='<div class="empty-state">أكمل تهيئة Firebase (املأ مفاتيحك في js/firebase-mod.js) لتشغيل المحفظة الاستثمارية</div>';
}

const btnLogout=$('btn-logout');
if(btnLogout)btnLogout.addEventListener('click',async()=>{if(!isConfigured)return;await signOut(auth);window.location.href='auth.html'});

const btnDeposit=$('btn-deposit');
if(btnDeposit)btnDeposit.addEventListener('click',()=>{
  if(!curDoc){toast('جاري تحميل المحفظة...');return}
  const v=prompt('المبلغ المراد إيداعه (ر.س):');
  if(v===null)return;
  const amt=parseFloat(v);
  if(isNaN(amt)||amt<=0){toast('أدخل مبلغًا صحيحًا');return}
  curDoc.balance=(curDoc.balance||0)+amt;
  updateDoc(docRef,{balance:curDoc.balance}).then(renderBalance).catch(e=>toast('فشل الإيداع: '+(e.message||e)));
});

window.handleInvest=async function(name,amount,roi){
  if(!isConfigured||!curDoc){toast('المحفظة غير متاحة بعد');return}
  const amt=Number(amount);
  if(isNaN(amt)||amt<=0)return;
  if((curDoc.balance||0)<amt){toast('رصيد غير كافٍ للاستثمار');return}
  curDoc.balance-=amt;
  curDoc.investments=curDoc.investments||[];
  curDoc.investments.unshift({name:String(name),amount:amt,roi:String(roi),at:new Date().toISOString()});
  try{
    await updateDoc(docRef,{balance:curDoc.balance,investments:curDoc.investments});
    renderBalance();renderInvestments();
    toast('تم الاستثمار في '+name+' ✓');
  }catch(e){
    curDoc.balance+=amt;curDoc.investments.shift();
    toast('فشل الاستثمار: '+(e.message||e));
  }
};
