# ابدأ من هنا — NutriVision

اتبع الملف **`FINAL_SETUP_AR.md`**؛ فهو المرجع الموحّد لإعداد مفاتيح Gemini وUSDA وFirebase، وتشغيل Backend وFlutter على Windows/Android Emulator/Chrome، وحل أخطاء `401` و`EADDRINUSE` وCORS.

## الترتيب المختصر
1. ثبت Flutter stable وNode.js 20+.
2. انسخ `backend/.env.example` إلى `backend/.env`، ثم أضف `GEMINI_API_KEY` و`USDA_API_KEY`.
3. للتطوير المحلي فقط، اترك `REQUIRE_FIREBASE_AUTH=false` كما في القالب، ولا تعرض الخادم للإنترنت.
4. شغّل Backend من مجلد `backend`: `npm install` ثم `npm run check` ثم `npm start`.
5. شغّل Flutter بالأوامر الموجودة في `FINAL_SETUP_AR.md` حسب المنصة.
6. إذا أردت حسابات ومزامنة حقيقية، نفّذ إعداد Firebase Client وFirebase Admin كما هو موضح بالدليل، ثم أعد `REQUIRE_FIREBASE_AUTH=true`.
7. قبل العرض النهائي شغّل `flutter analyze` و`flutter test` و`npm run check` واقرأ النتائج.

**ملاحظة أمان:** مفاتيح Gemini وUSDA تبقى في `backend/.env` فقط. لا تضع مفاتيح الخادم أو ملف Service Account في Flutter أو ZIP أو Git.
