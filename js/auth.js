/* auth.js — تسجيل الدخول وإنشاء الحساب عبر Firebase Auth + Firestore (وحدة ESM) */
import { auth, db } from "./firebase-mod.js";
import { 
  createUserWithEmailAndPassword, 
  signInWithEmailAndPassword,
  onAuthStateChanged 
} from "https://www.gstatic.com/firebasejs/10.8.0/firebase-auth.js";
import { 
  doc, 
  setDoc 
} from "https://www.gstatic.com/firebasejs/10.8.0/firebase-firestore.js";


// التتحقق التلقائي: إذا كان المستخدم مسجلاً بالدخول سابقاً، نوجهه فوراً للوحة التحكم
onAuthStateChanged(auth, (user) => {
  if (user) {
    window.location.href = "dashboard.html";
  }
});


// عناصر الواجهة
const formTitle = document.getElementById("form-title");
const nameGroup = document.getElementById("name-group");
const userNameInput = document.getElementById("user-name");
const userEmailInput = document.getElementById("user-email");
const userPasswordInput = document.getElementById("user-password");
const btnSubmit = document.getElementById("btn-submit");
const btnToggleMode = document.getElementById("btn-toggle-mode");
const authError = document.getElementById("auth-error");


let isSignUpMode = false;


// التبديل بين وضع تسجيل الدخول ووضع إنشاء حساب جديد
btnToggleMode.addEventListener("click", () => {
  isSignUpMode = !isSignUpMode;
  authError.innerText = "";


  if (isSignUpMode) {
    formTitle.innerText = "إنشاء حساب جديد";
    nameGroup.style.display = "flex";
    btnSubmit.innerText = "إنشاء الحساب والبدء";
    btnToggleMode.innerHTML = 'لديك حساب بالفعل؟ <strong>تسجيل الدخول</strong>';
  } else {
    formTitle.innerText = "تسجيل الدخول";
    nameGroup.style.display = "none";
    btnSubmit.innerText = "دخول للمنصة";
    btnToggleMode.innerHTML = 'ليس لديك حساب؟ <strong>إنشاء حساب جديد</strong>';
  }
});


// تنفيذ التسجيل أو الدخول عند الضغط على الزر
btnSubmit.addEventListener("click", async () => {
  const email = userEmailInput.value.trim();
  const password = userPasswordInput.value.trim();
  const name = userNameInput.value.trim();


  authError.innerText = "";


  if (!email || !password) {
    authError.innerText = "يرجى كتابة البريد الإلكتروني وكلمة المرور.";
    return;
  }


  if (isSignUpMode && !name) {
    authError.innerText = "يرجى كتابة الاسم الكامل.";
    return;
  }


  btnSubmit.disabled = true;
  btnSubmit.innerText = "جاري الاتصال...";


  try {
    if (isSignUpMode) {
      // 1. إنشاء حساب جديد في Firebase Auth
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;


      // 2. إنشاء ملف المحفظة الاستثمارية الخاصة به في Firestore
      await setDoc(doc(db, "users", user.uid), {
        name: name,
        email: email,
        balance: 10000, // رصيد استثماري ترحيبي للتجربة (10,000 ريال)
        investments: [],
        createdAt: new Date().toISOString()
      });


      window.location.href = "dashboard.html";
    } else {
      // تسجيل دخول حساب قائم
      await signInWithEmailAndPassword(auth, email, password);
      window.location.href = "dashboard.html";
    }
  } catch (error) {
    btnSubmit.disabled = false;
    btnSubmit.innerText = isSignUpMode ? "إنشاء الحساب والبدء" : "دخول للمنصة";
    
    // تخصيص رسائل الخطأ بالعربية
    if (error.code === 'auth/invalid-credential' || error.code === 'auth/user-not-found' || error.code === 'auth/wrong-password') {
      authError.innerText = "بيانات الدخول غير صحيحة، يرجى التأكد وإعادة المحاولة.";
    } else if (error.code === 'auth/email-already-in-use') {
      authError.innerText = "هذا البريد الإلكتروني مُسجل مسبقاً.";
    } else if (error.code === 'auth/weak-password') {
      authError.innerText = "كلمة المرور ضعيفة، يجب أن تحتوي على 6 خانات على الأقل.";
    } else {
      authError.innerText = "حدث خطأ: " + error.message;
    }
  }
});
