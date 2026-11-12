# حالة التحقق من الحزمة

## تم التحقق منه في بيئة إنشاء الحزمة
- فحص صياغة JavaScript باستخدام `node --check backend/src/server.js`.
- فحص صياغة ملف الاختبارات `backend/test/api.test.js` باستخدام `node --check`.
- التحقق من سلامة ZIP الأصلي قبل التعديل.
- إضافة اختبارات Node تغطي health endpoint، والتحقق من المدخلات، وحالة المصادقة، ووضع التطوير المحلي، وCORS على localhost.

## لم يمكن تشغيله هنا
- `npm install` لم يكتمل بسبب انتهاء مهلة الاتصال بمصدر الحزم؛ لذلك لم يتم تشغيل `npm run check` على الحزمة المعدلة في هذه البيئة.
- Flutter SDK غير متوفر في بيئة إنشاء الحزمة؛ لذلك لم يتم تشغيل `flutter analyze` أو `flutter test` هنا.
- لم يتم اختبار مفاتيح Gemini أو USDA الخاصة بالمستخدم، ولا مشروع Firebase الحقيقي أو جهاز Android/Chrome الخاص به.

## المطلوب قبل وصفه بأنه إصدار مُختبر
من جهاز التطوير، شغّل `npm install` ثم `npm run check` داخل `backend`، وشغّل `flutter pub get` و`flutter analyze` و`flutter test` من جذر المشروع. أصلح أي أخطاء تظهر، ثم اختبر تدفقًا كاملًا من البحث الغذائي حتى حفظ الوجبة، وكذلك تسجيل الدخول وFirestore إذا تم إعداد Firebase.
