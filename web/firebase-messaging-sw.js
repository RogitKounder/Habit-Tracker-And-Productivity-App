importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js");

const firebaseConfig = {
  apiKey: "AIzaSyDQ-y3QSdrvH5PLtQkrHZE3LjRtk97f0hs",
  authDomain: "habit-ccd80.firebaseapp.com",
  projectId: "habit-ccd80",
  storageBucket: "habit-ccd80.firebasestorage.app",
  messagingSenderId: "186128623949",
  appId: "1:186128623949:web:312fe28b303ab44386af04",
  measurementId: "G-GNSQ1JQFMJ"
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messenger-sw.js] Received background message:", payload);
  const notificationTitle = payload.notification?.title || "Habit Reminder";
  const notificationOptions = {
    body: payload.notification?.body || "Time to work on your habit!",
    icon: "/favicon.png"
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});