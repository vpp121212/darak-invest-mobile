/* auth.js — ربط Firebase مع Express، قفل جهات الاتصال، والتوجيه بعد الدخول */

function setSession(d){
  authToken=d.accessToken;
  localStorage.setItem('darak_token',d.accessToken);
  user=d.user;
  closeLogin();
  updateUserUI();
}
function postAuthNav(){
  if(window.nav)window.nav('home');
  else window.location.href='index.html';
}
function goHome(){window.location.href='index.html'}

async function bridgeFirebaseUser(fbUser,pw){
  var em=fbUser.email||'';
  if(!em){toast('لا يوجد بريد إلكتروني مرتبط بحساب Firebase');return false}
  if(!pw){pw=localStorage.getItem('darak_fbpw')||('Darak!'+Math.random().toString(36).slice(2,10)+'X');localStorage.setItem('darak_fbpw',pw)}
  var nm=fbUser.displayName||em.split('@')[0];
  var ph=fbUser.phoneNumber||'';
  var d=await api('/auth/login',{method:'POST',body:JSON.stringify({email:em,password:pw})});
  if(d&&d.success){setSession(d);return true}
  var r=await api('/auth/register',{method:'POST',body:JSON.stringify({name:nm,email:em,phone:ph,password:pw})});
  if(r&&r.success){setSession(r);return true}
  if(r&&r.code==='DUPLICATE'){
    var l=await api('/auth/login',{method:'POST',body:JSON.stringify({email:em,password:pw})});
    if(l&&l.success){setSession(l);return true}
    toast('حسابك مرتبط بكلمة مرور مختلفة — سجّل الدخول بالبريد وكلمة المرور');
    return false;
  }
  toast(fmtErr(r&&r.error?r:d)||'تعذر الربط مع الخادم');
  return false;
}
window.bridgeFirebaseUser=bridgeFirebaseUser;

async function fbGoogleLogin(){
  if(!FB_READY){toast('تسجيل الدخول عبر جوجل غير متاح حالياً');return}
  try{
    var res=await FB_AUTH.signInWithPopup(new window.firebase.auth.GoogleAuthProvider());
    if(res&&res.user){await bridgeFirebaseUser(res.user,'');postAuthNav()}
  }catch(e){toast('فشل تسجيل الدخول عبر جوجل')}
}

/* الدخول بالبريد وكلمة المرور: Express أولاً، ثم Firebase كمسار بديل */
async function doLogin(){
  var em=document.getElementById('login-email')?document.getElementById('login-email').value:'';
  var pw=document.getElementById('login-pass')?document.getElementById('login-pass').value:'';
  if(!em||!pw){toast('أدخل البريد وكلمة المرور');return}
  var d=await api('/auth/login',{method:'POST',body:JSON.stringify({email:em,password:pw})});
  if(d&&d.success){setSession(d);postAuthNav();return}
  if(FB_READY){
    try{
      var cred=await FB_AUTH.signInWithEmailAndPassword(em,pw);
      if(cred&&cred.user){await bridgeFirebaseUser(cred.user,pw);postAuthNav();return}
    }catch(fbErr){}
  }
  toast(d.error||'فشل تسجيل الدخول');
}

/* إنشاء حساب: Firebase أولاً ثم Express */
async function doRegister(){
  var nm=document.getElementById('reg-name')?document.getElementById('reg-name').value:'';
  var em=document.getElementById('reg-email')?document.getElementById('reg-email').value:'';
  var ph=document.getElementById('reg-phone')?document.getElementById('reg-phone').value:'';
  var pw=document.getElementById('reg-pass')?document.getElementById('reg-pass').value:'';
  if(!nm||!em||!ph||!pw){toast('أكمل جميع الحقول');return}
  var agree=document.getElementById('reg-agree');
  if(!agree||!agree.checked){toast('يجب الموافقة على الشروط القانونية');return}
  if(FB_READY){
    try{
      var cred=await FB_AUTH.createUserWithEmailAndPassword(em,pw);
      if(cred&&cred.user){cred.user.updateProfile({displayName:nm}).catch(function(){})}
    }catch(fe){
      if(fe&&fe.code==='auth/email-already-in-use'){try{await FB_AUTH.signInWithEmailAndPassword(em,pw)}catch(e2){}}
    }
  }
  var d=await api('/auth/register',{method:'POST',body:JSON.stringify({name:nm,email:em,phone:ph,password:pw})});
  if(d&&d.success){setSession(d);postAuthNav();return}
  if(d&&d.code==='DUPLICATE'){
    var l=await api('/auth/login',{method:'POST',body:JSON.stringify({email:em,password:pw})});
    if(l&&l.success){setSession(l);postAuthNav();return}
  }
  toast(d.error||'فشل إنشاء الحساب');
}

/* الدخول برمز الجوال: يبقى عبر Express */
async function doVerifyOtp(){
  var ph=document.getElementById('otp-phone').value;
  var otp=document.getElementById('otp-code').value;
  if(!otp||otp.length<6){toast('أدخل الكود كاملاً');return}
  var btn=document.getElementById('otp-verify-btn');
  btn.disabled=true;btn.textContent='جاري التحقق...';
  var d=await api('/auth/verify-otp',{method:'POST',body:JSON.stringify({phone:ph,otp:otp})});
  if(d&&d.success){setSession(d);toast('مرحباً '+d.user.name+'! ✓');postAuthNav()}
  else{toast(d.message||'كود غير صحيح');btn.disabled=false;btn.textContent='تأكيد الدخول'}
}

/* تسجيل الخروج */
async function doLogout(){
  if(FB_READY&&FB_AUTH.currentUser){try{await FB_AUTH.signOut()}catch(e){}}
  if(user&&authToken)api('/auth/logout',{method:'POST',body:JSON.stringify({userId:user.id})}).catch(function(){});
  authToken=null;localStorage.removeItem('darak_token');user=null;
  localStorage.removeItem('darak_fbpw');
  toast('تم تسجيل الخروج');
  updateUserUI();
  var p=location.pathname.split('/').pop()||'';
  if(p==='dashboard.html')window.location.href='index.html';
  else if(document.getElementById('pg'))nav('home');
}

/* قفل بيانات التواصل خلف تسجيل الدخول */
function requireContact(){
  if(authToken)return true;
  toast('سجّل دخولك لعرض بيانات التواصل');
  openLogin();
  return false;
}
function contactAgent(ph,type){
  if(!requireContact())return;
  if(type==='wa')window.open('https://wa.me/'+ph,'_blank');
  else window.location.href='tel:+'+ph;
}

/* زر Google داخل نافذة الدخول (يظهر فقط عند تفعيل Firebase) */
if(FB_CONFIGURED){
  document.addEventListener('DOMContentLoaded',function(){
    var box=document.querySelector('.login-box');if(!box)return;
    var g=document.createElement('button');
    g.type='button';g.onclick=fbGoogleLogin;
    g.style.cssText='width:100%;padding:12px;border-radius:12px;background:#fff;color:#111;font-size:13px;font-weight:700;font-family:inherit;border:none;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:8px;margin-bottom:12px';
    g.innerHTML='<svg width="18" height="18" viewBox="0 0 48 48" style="flex-shrink:0"><path fill="#FFC107" d="M43.6 20.1H42V20H24v8h11.3C33.7 32.7 29.2 36 24 36c-6.6 0-12-5.4-12-12s5.4-12 12-12c3.1 0 5.9 1.1 8.1 3l5.7-5.7C34.6 6.1 29.5 4 24 4 13 4 4 13 4 24s9 20 20 20 20-9 20-20c0-1.3-.1-2.6-.4-3.9z"/><path fill="#FF3D00" d="M6.3 14.7l6.6 4.8C14.7 15.1 18.9 12 24 12c3.1 0 5.9 1.1 8.1 3l5.7-5.7C34.6 6.1 29.5 4 24 4 16.3 4 9.7 8.3 6.3 14.7z"/><path fill="#4CAF50" d="M24 44c5.2 0 9.9-1.9 13.4-5.1l-6.2-5.2C29.2 35.1 26.7 36 24 36c-5.2 0-9.6-3.3-11.3-8l-6.5 5C9.5 39.6 16.2 44 24 44z"/><path fill="#1976D2" d="M43.6 20.1H42V20H24v8h11.3c-.8 2.3-2.3 4.3-4.1 5.7l6.2 5.2C36.9 40.2 44 35 44 24c0-1.3-.1-2.6-.4-3.9z"/></svg>متابعة مع Google';
    var hr=document.createElement('div');
    hr.style.cssText='display:flex;align-items:center;gap:10px;margin:0 0 12px;color:var(--m);font-size:11px';
    hr.innerHTML='<span style="flex:1;height:1px;background:var(--b)"></span>أو<span style="flex:1;height:1px;background:var(--b)"></span>';
    var tabs=box.querySelector('.login-tabs');
    box.insertBefore(hr,tabs);box.insertBefore(g,tabs);
  });
}
