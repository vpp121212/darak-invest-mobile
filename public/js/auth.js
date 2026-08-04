/* auth.js — تسجيل الدخول وإنشاء الحساب (نسخة تجريبية محلية عبر localStorage) */
const formTitle = document.getElementById("form-title");
const nameGroup = document.getElementById("name-group");
const userNameInput = document.getElementById("user-name");
const userEmailInput = document.getElementById("user-email");
const userPasswordInput = document.getElementById("user-password");
const btnSubmit = document.getElementById("btn-submit");
const btnToggleMode = document.getElementById("btn-toggle-mode");
const authError = document.getElementById("auth-error");


let isSignUpMode = false;


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


btnSubmit.addEventListener("click", () => {
  const email = userEmailInput.value.trim();
  const password = userPasswordInput.value.trim();
  const name = userNameInput.value.trim();


  if (!email || !password) {
    authError.innerText = "يرجى كتابة البريد الإلكتروني وكلمة المرور.";
    return;
  }


  const userObj = {
    name: name || "مستثمر دارك وحيك",
    email: email,
    balance: 10000,
    investments: []
  };


  localStorage.setItem("darak_user", JSON.stringify(userObj));
  window.location.href = "index.html";
});
