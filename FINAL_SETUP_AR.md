# NutriVision — دليل الإعداد النهائي (Windows)

هذا الدليل يوضح ما هو جاهز في المشروع وما يلزم إضافته يدويًا. **لا توجد مفاتيح API أو ملفات Service Account داخل الحزمة**؛ أضفها محليًا فقط.

## 1) المتطلبات

- Flutter stable + Dart، وAndroid Studio/Android SDK لتشغيل Android.
- Node.js 20 أو أحدث (النسخة الحالية من Node 24 مناسبة).
- حساب Google AI Studio للحصول على Gemini API key.
- حساب USDA FoodData Central للحصول على مفتاح البحث الغذائي.
- حساب Firebase فقط إذا أردت تسجيل دخول حقيقيًا ومزامنة الوجبات في Firestore.

## 2) إعداد مفاتيح الـ Backend

من مجلد المشروع الرئيسي افتح PowerShell ونفّذ:

```powershell
Copy-Item .\backend\.env.example .\backend\.env
notepad .\backend\.env
```

إذا كان `backend\.env` موجودًا بالفعل، **لا تستبدله**؛ افتحه وعدّل القيم المطلوبة فقط. املأه هكذا مع وضع مفاتيحك الحقيقية:

```dotenv
PORT=8080
NODE_ENV=development
CORS_ORIGINS=http://localhost:3000,http://localhost:5000
GEMINI_API_KEY=YOUR_GEMINI_KEY
GEMINI_MODEL=gemini-2.5-flash
USDA_API_KEY=YOUR_USDA_KEY
REQUIRE_FIREBASE_AUTH=false
```

روابط الحصول على المفاتيح:

- Gemini: https://aistudio.google.com/app/apikey
- USDA FoodData Central: https://fdc.nal.usda.gov/api-key-signup/

**لا تضع مفاتيح Gemini أو USDA داخل Flutter أو GitHub أو ترسلها في المحادثة.** ضع كل مفتاح في `.env` فقط. ملف `.env` مستثنى من Git.

### معنى `REQUIRE_FIREBASE_AUTH=false`

هذا وضع **للتطوير المحلي فقط** حتى تعمل ميزتا USDA وGemini دون إعداد Firebase Admin في البداية. لا تنشر الخادم على الإنترنت ولا تستخدم هذا الخيار في الإنتاج؛ عند `NODE_ENV=production` لا يتجاوز الكود التحقق من المصادقة حتى لو كانت القيمة `false`.

في الوضع المحلي، تسجيل الوجبات يكون داخل الذاكرة إذا لم يكن Firebase Client مهيأً، وبالتالي قد لا يبقى بعد إغلاق التطبيق. للحصول على الحسابات والمزامنة السحابية اتبع القسم 4.

## 3) تشغيل الـ Backend

افتح Terminal أولى:

```powershell
cd .\backend
npm install
npm run check
npm start
```

اتركها مفتوحة. يجب أن يظهر `NutriVision API listening on port 8080`. اختبر:

- افتح http://localhost:8080/api/health
- المتوقع: `{"status":"ok","service":"nutrivision-api"}`

إذا ظهر `EADDRINUSE`، فالمنفذ مستخدم بالفعل. اعرف العملية أولًا:

```powershell
netstat -ano | findstr :8080
```

آخر رقم في السطر هو PID. اعرف العملية قبل إيقافها:

```powershell
tasklist /FI "PID eq YOUR_PID"
```

أوقفها فقط إذا تأكدت أنها نسخة Node القديمة الخاصة بـ NutriVision:

```powershell
taskkill /PID YOUR_PID /F
```

### اختبار مفاتيح USDA بدون كشف المفتاح

من مجلد `backend`:

```powershell
node -e "require('dotenv').config(); console.log('USDA configured:', Boolean(process.env.USDA_API_KEY?.trim()))"
```

يمكنك اختبار الطلب الحقيقي كما يلي؛ الأمر لا يطبع المفتاح:

```powershell
node -e "require('dotenv').config(); (async()=>{const u=new URL('https://api.nal.usda.gov/fdc/v1/foods/search');u.searchParams.set('api_key',(process.env.USDA_API_KEY||'').trim());u.searchParams.set('query','apple');u.searchParams.set('pageSize','1');const r=await fetch(u,{signal:AbortSignal.timeout(12000)});console.log('USDA HTTP status:',r.status);const d=await r.json();console.log('Food results:',d.foods?.length??0)})().catch(e=>console.log('Connection error:',e.message))"
```

`HTTP status: 200` ونتيجة طعام واحدة على الأقل يعني أن مفتاح USDA والاتصال يعملان. إذا نجح هذا الاختبار وفشل التطبيق، راجع عنوان Flutter وحالة Backend بدل تغيير المفتاح.

## 4) تشغيل Flutter على Android Emulator

افتح Terminal ثانية من **جذر المشروع** وليس من مجلد `backend`:

```powershell
flutter pub get
flutter run --dart-define=AI_BACKEND_URL=http://10.0.2.2:8080/api/nutrition --dart-define=NUTRITION_API_BASE_URL=http://10.0.2.2:8080/api/
```

`10.0.2.2` هو عنوان جهاز الكمبيوتر من داخل Android Emulator. لا تستخدم `localhost` داخل المحاكي لأنه يشير إلى المحاكي نفسه.

### التشغيل على Chrome أو Windows Desktop

إذا كان التطبيق يعمل على الكمبيوتر نفسه داخل Chrome، استخدم:

```powershell
flutter run -d chrome --dart-define=AI_BACKEND_URL=http://localhost:8080/api/nutrition --dart-define=NUTRITION_API_BASE_URL=http://localhost:8080/api/
```

لتشغيل نسخة Windows Desktop الأصلية بدل Chrome استخدم `flutter run -d windows` مع نفس `--dart-define`، إذا كان مجلد `windows/` قد تم إنشاؤه. لا تستخدم `https://localhost:8080`؛ الخادم المحلي الحالي يستخدم `http://`. أثناء التطوير يسمح CORS بمنافذ localhost على HTTP فقط؛ في الإنتاج يجب وضع أصول الويب الفعلية في `CORS_ORIGINS` واستخدام HTTPS.

### تشغيل التطبيق على هاتف حقيقي

استبدل `localhost` أو `10.0.2.2` بعنوان IPv4 المحلي للكمبيوتر (مثل `192.168.1.20`) بشرط أن يكون الهاتف والكمبيوتر على شبكة Wi-Fi نفسها. قد تحتاج إلى قاعدة Windows Firewall تسمح بالاتصال بالمنفذ 8080. لا تفتح المنفذ للإنترنت.

## 5) إعداد Firebase الحقيقي (الحسابات + Firestore)

1. أنشئ مشروعًا من https://console.firebase.google.com/.
2. في Authentication → Sign-in method فعّل Email/Password.
3. أنشئ Cloud Firestore.
4. من جذر المشروع نفّذ:

```powershell
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

5. اختر منصات التشغيل المطلوبة، وتأكد من إنشاء إعدادات Firebase للمنصة. الكود الحالي يستخدم إعدادات Android/iOS الافتراضية؛ ولـ Web مرّر إعدادات تطبيق الويب العامة كما هو موضح أدناه.
6. انشر قواعد Firestore بعد التأكد من اختيار مشروعك الصحيح:

```powershell
firebase use YOUR_FIREBASE_PROJECT_ID
firebase deploy --only firestore:rules
```

### إعداد Firebase Web

من إعدادات تطبيق Web في Firebase Console خذ قيم العميل العامة ومرّرها عند تشغيل Chrome:

```powershell
flutter run -d chrome `
  --dart-define=FIREBASE_API_KEY=YOUR_WEB_API_KEY `
  --dart-define=FIREBASE_APP_ID=YOUR_WEB_APP_ID `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID `
  --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID `
  --dart-define=FIREBASE_AUTH_DOMAIN=YOUR_PROJECT_ID.firebaseapp.com `
  --dart-define=AI_BACKEND_URL=http://localhost:8080/api/nutrition `
  --dart-define=NUTRITION_API_BASE_URL=http://localhost:8080/api/
```

هذه قيم إعداد عميل Firebase، وليست بديلًا عن قواعد Firestore. لا تضع Service Account أو أي مفتاح خادم داخل Flutter.

## 6) تفعيل التحقق الآمن من Firebase على Backend

هذا مطلوب عندما تريد أن تكون واجهات `/api/nutrition` و`/api/foods/search` محمية بتوكن Firebase:

1. في Firebase Console → Project settings → Service accounts أنشئ مفتاح خدمة لبيئة التطوير فقط.
2. احفظ ملف JSON خارج المشروع، مثل `C:\Users\YOUR_USER\secrets\nutrivision-service-account.json`.
3. أضف إلى `backend/.env`:

```dotenv
REQUIRE_FIREBASE_AUTH=true
GOOGLE_APPLICATION_CREDENTIALS=C:/Users/YOUR_USER/secrets/nutrivision-service-account.json
```

استبدل `YOUR_USER` بمجلد مستخدم Windows الفعلي. لا تضع ملف JSON داخل ZIP أو Git ولا ترسله لأحد. أعد تشغيل Backend. عند استخدام هذا الوضع يجب أن يكون المستخدم قد سجّل الدخول وأكد بريده الإلكتروني، وأن يكون Firebase Client وFirebase Admin مربوطين بالمشروع نفسه.

**في الإنتاج:** استخدم Secret Manager/اعتماد بيئة الاستضافة بدل ملف JSON إن أمكن، وابقِ `REQUIRE_FIREBASE_AUTH=true`، وفعّل HTTPS، وحدد CORS origins بدقة، وراجع حدود الطلبات وسياسة الخصوصية.

## 7) ما الذي يعمل وما الذي يحتاج بياناتك؟

- واجهات Flutter، لوحة الملخص، سجل الوجبات، النموذج الغذائي، وحساب القيم بحسب الوزن: ضمن الكود.
- بحث USDA: يحتاج `USDA_API_KEY` صالحًا واتصال Backend.
- إرشادات الوجبات والوصفات وبدائل السناكس المولّدة من AI: تحتاج `GEMINI_API_KEY` واسم نموذج متاحًا لحسابك.
- تسجيل الدخول ومزامنة Firestore: تحتاج إعداد Firebase Client، وقواعد Firestore المنشورة.
- حماية API بتوكن Firebase في وضع المصادقة الكامل: تحتاج أيضًا اعتماد Firebase Admin على الخادم.
- بيانات الأطباق المركبة مثل كشري أو بيتزا لا تكون دقيقة من الاسم وحده؛ استخدم مكونات وكميات فعلية أو أدخل تقديرًا موضحًا للمستخدم.

## 8) فحوصات ما قبل العرض

من جذر المشروع:

```powershell
flutter analyze
flutter test
```

ومن `backend`:

```powershell
npm run check
```

لا تعتبر المشروع مُختبرًا نهائيًا قبل تشغيل الأوامر فعليًا على جهازك. اختبر على الأقل: البحث عن `apple`، تسجيل وجبة، إعادة فتح السجل، تحليل وجبة عبر Gemini، إنشاء حساب، تأكيد البريد، تسجيل الدخول، ثم التحقق من بقاء الوجبات بعد إعادة تشغيل التطبيق.

## 9) تشخيص سريع

| الخطأ | السبب المرجح | الإجراء |
|---|---|---|
| `EADDRINUSE :8080` | نسخة Backend أخرى تعمل | استخدم `netstat -ano | findstr :8080` وتحقق من PID قبل إيقافه |
| `Connection refused` | Backend متوقف أو عنوان/بروتوكول خاطئ | استخدم `http://` واتبع عنوان المنصة الصحيح |
| `401 unauthorized` | المصادقة مطلوبة لكن التوكن مفقود/غير صالح | للتطوير المحلي فقط اضبط `REQUIRE_FIREBASE_AUTH=false`؛ للإنتاج أعد إعداد Firebase Admin والتوكن |
| `403 origin_not_allowed` | أصل Web غير مسموح | أضف الأصل الصحيح إلى `CORS_ORIGINS`، ولا تستخدم wildcard في الإنتاج |
| `503 food_data_not_configured` | مفتاح USDA غير متوفر في عملية Backend | راجع `backend/.env` ثم أعد تشغيل Backend |
| `502 food_data_unavailable` | طلب USDA فشل أو تجاوز مهلة | راجع سجل Backend واختبر المفتاح مباشرة |
| `503 service_unavailable` في AI | `GEMINI_API_KEY` مفقود | أضف المفتاح إلى `.env` وأعد تشغيل Backend |

لا ترسل ملف `.env` أو Firebase service-account JSON أو أي token عند طلب المساعدة. احذف الأسرار من سجل الخطأ قبل مشاركته.
