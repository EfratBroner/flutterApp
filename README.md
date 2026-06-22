# 📚 סיכומי לימוד — אפליקציית קהילה

אפליקציית Flutter לשיתוף וניהול סיכומי לימוד בין סטודנטים.

---

## ✨ תכונות עיקריות

- 📝 פרסום סיכומי לימוד עם תמונה, כותרת ותוכן
- 🔍 סינון סיכומים לפי נושא (מתמטיקה, פיזיקה, היסטוריה ועוד)
- ❤️ לייקים ותגובות על סיכומים
- 🔖 שמירת סיכומים למועדפים — זמינים גם ללא אינטרנט
- 💡 ציטוט השראה יומי
- 🌙 מצב כהה/בהיר + גודל גופן מותאם אישית

---

## 🛠️ טכנולוגיות

| טכנולוגיה | שימוש |
|-----------|-------|
| Flutter | פיתוח האפליקציה |
| Firebase Auth | הרשמה וכניסה עם אימייל וסיסמה |
| Cloud Firestore | מאגר סיכומים ותגובות בזמן אמת |
| Firebase Storage | העלאת תמונות לפוסטים |
| SQLite | מועדפים מקומיים — offline |
| Shared Preferences | הגדרות אפליקציה (dark mode, גודל גופן) |
| Provider | ניהול מצב (State Management) |
| HTTP | קריאת API חיצוני לציטוט יומי |

---

## 📱 מסכים

- **Auth Screen** — הרשמה וכניסה
- **Home/Feed** — פיד סיכומים עם סינון נושאים
- **Detail View** — צפייה מורחבת, לייק, bookmark ותגובות
- **Profile & Create** — פרופיל אישי, הגדרות והוספת סיכום

---

## 🚀 הרצת הפרויקט

```bash
flutter pub get
flutter run
```

> נדרש: חשבון Firebase עם Firestore ו-Storage מופעלים, וקובץ `google-services.json` בתיקיית `android/app/`.

---

## 🗂️ מבנה הפרויקט

```
lib/
├── models/          # מודלים (StudySummary)
├── providers/       # ניהול מצב (Auth, Summary, Settings)
├── services/        # שירותים (Firebase, SQLite, API)
└── views/           # מסכים (Auth, Home, Detail, Profile, AddSummary)
```
