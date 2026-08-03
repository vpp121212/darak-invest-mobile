import { initializeApp } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-app.js";
import { getAuth } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-auth.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-firestore.js";

// إعدادات البيئة التجريبية الحية لمنصة دارك وحيك
const firebaseConfig = {
  apiKey: "AIzaSyD-DEMO-KEY-FOR-DARAK-HATTOK",
  authDomain: "darak-hattok.firebaseapp.com",
  projectId: "darak-hattok",
  storageBucket: "darak-hattok.appspot.com",
  messagingSenderId: "1234567890",
  appId: "1:1234567890:web:demo1234"
};

export const isConfigured = !!(firebaseConfig.apiKey && firebaseConfig.apiKey.length > 4);

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
