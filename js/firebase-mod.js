/* firebase-mod.js — تهيئة Firebase للوحدات (ESM)
 * الصق إعدادات مشروعك من Firebase Console → Project settings → Web app.
 * تأكد من تفعيل Authentication (Email/Password) و Firestore. */
export const FB_KEYS={
  apiKey:'',
  authDomain:'',
  projectId:'',
  storageBucket:'',
  messagingSenderId:'',
  appId:''
};
export const isConfigured=!!(FB_KEYS.apiKey&&FB_KEYS.apiKey.length>4);
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-app.js";
import { getAuth } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-auth.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-firestore.js";
let app=null,auth=null,db=null;
if(isConfigured){app=initializeApp(FB_KEYS);auth=getAuth(app);db=getFirestore(app)}
export {app,auth,db};
