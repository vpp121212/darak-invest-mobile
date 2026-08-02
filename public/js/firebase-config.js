/* firebase-config.js — تهيئة Firebase للتسجيل والدخول
 * املأ مفاتيح مشروعك من Firebase Console → Project settings → Your apps → Web.
 * عند تركها فارغة يعمل التطبيق بشكل طبيعي عبر خادم Express فقط. */
var FB_CONFIG={
  apiKey:'',
  authDomain:'',
  projectId:'',
  storageBucket:'',
  messagingSenderId:'',
  appId:''
};
var FB_CONFIGURED=FB_CONFIG&&FB_CONFIG.apiKey&&FB_CONFIG.apiKey.length>4;
var FB_READY=false,FB_APP=null,FB_AUTH=null;
var FB_SDK='10.12.2';

if(FB_CONFIGURED){
  function fbLoad(){
    FB_APP=window.firebase.initializeApp(FB_CONFIG);
    FB_AUTH=window.firebase.auth(FB_APP);
    FB_READY=true;
    document.dispatchEvent(new CustomEvent('fb-ready'));
    FB_AUTH.onAuthStateChanged(function(fbUser){
      if(fbUser&&!authToken&&typeof bridgeFirebaseUser==='function'){
        var pw=localStorage.getItem('darak_fbpw')||('');
        bridgeFirebaseUser(fbUser,pw);
      }
    });
  }
  if(window.firebase&&window.firebase.auth){fbLoad()}
  else{
    var d1=document.createElement('script');d1.src='https://www.gstatic.com/firebasejs/'+FB_SDK+'/firebase-app-compat.js';document.head.appendChild(d1);
    var d2=document.createElement('script');d2.src='https://www.gstatic.com/firebasejs/'+FB_SDK+'/firebase-auth-compat.js';document.head.appendChild(d2);
    var fbTry=0,fbTimer=setInterval(function(){
      if(window.firebase&&window.firebase.auth){clearInterval(fbTimer);fbLoad()}
      else if(++fbTry>40)clearInterval(fbTimer);
    },250);
  }
}
