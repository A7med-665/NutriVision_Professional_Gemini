# NutriVision — مساعد غذائي ذكي | Flutter + Firebase + AI

NutriVision مشروع تعليمي متقدم لتسجيل الوجبات، ومراجعة السعرات والمغذيات الكبرى، والبحث في قاعدة بيانات الأغذية USDA FoodData Central، والحصول على إرشادات غذائية عامة وبدائل للوجبات من خلال Backend آمن. الواجهة عربية RTL، ومتجاوبة مع الشاشات الصغيرة والكبيرة.

> **الحالة بوضوح:** هذه حزمة مصدر منظمة وقابلة للتطوير، وليست تطبيقًا منشورًا جاهزًا للإنتاج. يلزم إعداد Firebase ومفاتيح الخدمات على بيئتك وتشغيل `flutter analyze` و`flutter test` على نسخة Flutter لديك قبل الاعتماد عليها. لم تُنفّذ اختبارات تشغيل فعلية داخل بيئة إنشاء هذه الحزمة.


## تحديثات التسجيل الغذائي الذكي
- يتيح نموذج إضافة الوجبة البحث التلقائي أثناء كتابة اسم الطعام من خلال Backend وقاعدة USDA FoodData Central.
- عند اختيار نتيجة، تُحسب السعرات والماكروز والقيم الغذائية المتاحة حسب وزن الحصة بالجرام؛ يمكن استخدام أزرار 50/100/200 جم لتغيير الكمية سريعًا.
- تعرض الشاشة الألياف والسكريات والصوديوم والدهون المشبعة والكوليسترول عندما تكون متاحة من المصدر، مع توضيح أن البيانات تقديرية وليست بديلًا عن الملصق الغذائي أو اختصاصي التغذية.
- إذا لم تتوفر نتيجة مناسبة، يمكن تفعيل الإدخال اليدوي. لا يعتمد التطبيق على اسم طبق مركب وحده لتوليد أرقام غذائية دقيقة.
- سجل الوجبة يحفظ الوزن ومصدر البيانات والقيم الإضافية، وتظهر هذه التفاصيل عند فتح الوجبة من لوحة التحكم.


## ما الذي يتضمنه المشروع؟

- Flutter + Material 3 + دعم العربية واتجاه RTL.
- تقسيمة Feature-First لتقليل الترابط بين الواجهات والمنطق والبيانات.
- Cubit لإدارة حالة سجل الوجبات، وDio مع Interceptors للطلبات.
- Firebase Authentication: تسجيل، دخول، تأكيد البريد، وإعادة تعيين كلمة المرور.
- Firestore تحت `users/{uid}/meals/{mealId}` مع قواعد تمنع المستخدم من قراءة أو تعديل بيانات مستخدم آخر.
- Backend بـ Node.js/Express يتضمن التحقق من Firebase ID tokens، والتحقق من المدخلات، وRate Limiting، وHelmet، وCORS.
- AI service server-side، بحيث لا يُضمّن مفتاح مزود الذكاء الاصطناعي داخل تطبيق Flutter.
- بحث غذائي عبر USDA FoodData Central من خلال Backend proxy.
- لوحة ملخص فيها `Stack` و`GridView` متجاوب ورسم `fl_chart`.
- Unit Tests لحساب المغذيات وتحويل نموذج الوجبة، وWidget Test للواجهة الأساسية.
- ملفات تصميم تفكيري: Personas وUser Flows وWireframes نصية.

## أسرع طريقة للبدء على Windows

راجع الملف `FINAL_SETUP_AR.md` للتعليمات التفصيلية (و`START_HERE_AR.md` كبداية سريعة)، أو شغّل `scripts/setup_windows.ps1` من PowerShell بعد تثبيت Flutter وNode.js. السكربت ينزل الحزم ويشغّل الفحوصات، لكنه لا ينشئ مفاتيح Gemini أو بيانات اعتماد Firebase الخاصة بك.

## 1. المتطلبات

- Flutter stable متوافق مع Dart `>=3.3.0 <4.0.0` (يفضل إصدار Flutter حديث ومستقر).
- Android Studio أو VS Code وAndroid SDK لتشغيل Android.
- Node.js 20+ لتشغيل Backend.
- حساب Firebase لتفعيل الحسابات والمزامنة السحابية.
- مفتاح Gemini API اختياري لاقتراحات AI، ومفتاح USDA FoodData Central اختياري للبحث الغذائي.

## 2. تشغيل Flutter

افتح Terminal داخل مجلد `nutrivision`:

```bash
flutter doctor
flutter create . --platforms=android,ios,web
flutter pub get
flutter analyze
flutter test
flutter run
```

يبدأ التطبيق في **Demo Mode** إذا لم تتوفر إعدادات Firebase. في هذا الوضع تكون البيانات محلية في الذاكرة فقط وقد تضيع عند إعادة تشغيل التطبيق؛ لا تعتبرها مزامنة سحابية.

## 3. إعداد Firebase الحقيقي

1. أنشئ مشروعًا من Firebase Console.
2. فعّل **Authentication → Email/Password**.
3. فعّل **Cloud Firestore**.
4. نفّذ `dart pub global activate flutterfire_cli` ثم `flutterfire configure`، أو أكمل إعداد ملفات المنصة بالطريقة الرسمية.
5. على Android تأكد من وجود `google-services.json` في `android/app/` ومن إعداد Google Services Gradle plugin حسب مخرجات FlutterFire CLI. على iOS أضف `GoogleService-Info.plist` إلى Runner من خلال إعداد المنصة.
6. انشر قواعد `firestore.rules` بعد مراجعتها:

```bash
firebase deploy --only firestore:rules
```

الكود يستخدم إعدادات Firebase الافتراضية للمنصة. إذا كنت تشغّل Web، مرّر خيارات Firebase العامة وقت التشغيل (يمكن العثور عليها في إعدادات تطبيق Web داخل Firebase Console):

```bash
flutter run -d chrome \
  --dart-define=FIREBASE_API_KEY=YOUR_WEB_API_KEY \
  --dart-define=FIREBASE_APP_ID=YOUR_WEB_APP_ID \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID \
  --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID \
  --dart-define=FIREBASE_AUTH_DOMAIN=YOUR_PROJECT_ID.firebaseapp.com
```

قيم إعداد Firebase الخاصة بالعميل ليست بديلًا عن قواعد الأمان. لا تضع Service Account أو مفاتيح خادم في تطبيق Flutter.

### حدود الأمان المطبقة

- المسار السحابي للوجبات خاص بكل UID: `users/{uid}/meals/{mealId}`.
- قواعد Firestore تتحقق من ملكية المستخدم، ووجود الحقول الأساسية، ونوع القيم الرقمية، وعدم السماح بحقول غير معروفة.
- التسجيل يرسل رسالة تأكيد بريد، وتسجيل الدخول يطلب تأكيد البريد.
- تسجيل الخروج متاح من لوحة التحكم عند تفعيل Firebase.
- **قبل الإطلاق العام:** أضف App Check، وسياسة خصوصية وموافقة واضحة، واختبر القواعد في Firebase Emulator Suite، وحدد سياسة حذف الحساب والبيانات والاحتفاظ بها.

## 4. تشغيل Backend

انتقل إلى مجلد `backend`. على Windows (Command Prompt) انسخ ملف البيئة بهذا الأمر: `copy .env.example .env`، وعلى macOS/Linux استخدم `cp .env.example .env`. ثم افتح `.env` وأضف مفاتيحك محليًا؛ لا ترفع الملف إلى Git:

```bash
# Windows CMD: copy .env.example .env
# PowerShell: Copy-Item .env.example .env
# macOS/Linux: cp .env.example .env
npm install
npm run check
npm start
```

الخادم الافتراضي يعمل على `http://localhost:8080`. لا تجعل `GEMINI_API_KEY` أو `USDA_API_KEY` متاحين للعميل؛ ضعهما في متغيرات بيئة الخادم فقط.

### متغيرات البيئة

- `GEMINI_API_KEY`: مطلوب لاقتراحات AI الحقيقية.
- `GEMINI_MODEL`: اسم نموذج Gemini المتاح لحسابك، والقيمة المقترحة في القالب `gemini-2.5-flash`.
- `USDA_API_KEY`: مطلوب للبحث الغذائي.
- `REQUIRE_FIREBASE_AUTH=false`: قالب التطوير المحلي فقط لتجربة الـ API دون Firebase Admin؛ اجعلها `true` مع إعداد Firebase Admin قبل الاستخدام الآمن أو الإنتاج.
- `GOOGLE_APPLICATION_CREDENTIALS`: مسار اعتماد Firebase Admin خارج المستودع، أو استخدم Application Default Credentials في بيئة استضافة موثوقة.
- `CORS_ORIGINS`: أصول Web المسموح لها. لا تستخدم wildcard في الإنتاج.

للتجربة المحلية الأولى فقط، يسمح قالب `.env.example` بتجاوز المصادقة عبر `REQUIRE_FIREBASE_AUTH=false` داخل `NODE_ENV=development` حتى تختبر ميزتي USDA وGemini دون Firebase Admin. أبقِ الخادم محليًا ولا تستخدم ذلك في الإنتاج. لتجربة الوضع الآمن، اضبط `REQUIRE_FIREBASE_AUTH=true` وأضف `GOOGLE_APPLICATION_CREDENTIALS` كما في `FINAL_SETUP_AR.md`.

## 5. ربط التطبيق بالخدمات

شغّل التطبيق بتمرير عنوان AI endpoint الكامل وعنوان API الأساسي للبحث الغذائي:

```bash
flutter run \
  --dart-define=AI_BACKEND_URL=https://YOUR_API_HOST/api/nutrition \
  --dart-define=NUTRITION_API_BASE_URL=https://YOUR_API_HOST/api
```

- `AI_BACKEND_URL` يشير إلى endpoint يقبل POST لمهام `meal_analysis` و`snack_alternatives` و`recipe_generation`.
- `NUTRITION_API_BASE_URL` هو المسار الأساسي؛ يضيف التطبيق `foods/search` إليه.
- يضيف Dio Interceptor Firebase ID token عندما يكون المستخدم مسجلًا وFirebase مهيأً.
- بدون AI endpoint، يستخدم التطبيق fallback إرشاديًا محليًا، ولا يدّعي أنه تحليل مولّد من نموذج حقيقي.
- قيم USDA الغذائية قد تكون لكل 100 غرام أو حصة مرجعية. لا تفترض أنها كمية وجبتك الفعلية؛ راجع حجم الحصة قبل الحفظ.

## 6. هيكل الملفات

```text
nutrivision/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── config/app_config.dart
│   │   └── theme/app_theme.dart
│   └── features/
│       ├── auth/presentation/        # AuthGate + تسجيل/دخول/استعادة كلمة المرور
│       ├── dashboard/                # Dashboard + Chart
│       ├── meals/
│       │   ├── domain/               # Meal model + NutritionCalculator
│       │   ├── data/                 # Firestore repository scoped per UID
│       │   └── presentation/         # Cubit + إضافة وجبة + سجل الوجبات
│       ├── nutrition/
│       │   ├── data/                 # USDA proxy client + model
│       │   └── presentation/         # واجهة البحث عن الغذاء
│       ├── ai/data/                  # AI advisor client + Dio interceptors
│       └── recipes/presentation/     # بدائل الوجبات الخفيفة
├── backend/
│   ├── src/server.js                 # API, auth verification, validation, rate limit
│   ├── package.json
│   └── .env.example
├── docs/                             # personas, flows, wireframes, architecture
├── test/                             # Unit + Widget tests
├── firestore.rules
├── README_AR.md
└── README.md
```

## 7. شرح تدفق البيانات

### إضافة وجبة

1. المستخدم يملأ النموذج ويجري `Form Validation`.
2. يمكنه البحث عن الطعام في USDA؛ تمر النتائج عبر Backend حتى يبقى مفتاح USDA على الخادم.
3. `MealCubit` يطلب إرشادات من `AiAdvisorService`.
4. يرسل Dio الطلب إلى Backend مع ID token إذا كان المستخدم مسجلًا.
5. يحفظ `MealRepository` السجل في مسار المستخدم داخل Firestore، أو في ذاكرة Demo Mode عند عدم إعداد Firebase.
6. يتابع `watchMeals()` تغييرات Firestore عبر snapshots، وتُحدّث الواجهة تلقائيًا.

### حساب السعرات

يستخدم `NutritionCalculator` المعادلة التقريبية:

`Calories ≈ (Protein × 4) + (Carbohydrates × 4) + (Fat × 9)`

هي طريقة تقديرية وليست بديلًا عن بيانات ملصق الغذاء أو تقييم اختصاصي. يتحقق الكود من القيم السالبة وغير المحدودة في دالة الحساب.

## 8. الاختبارات والجودة

```bash
flutter analyze
flutter test
```

الاختبارات الحالية تشمل:
- حساب الطاقة بمعاملات 4/4/9.
- رفض قيم المغذيات السالبة أو غير المحدودة.
- التعامل الآمن مع إدخال الأرقام والنسبة اليومية.
- تحويل `Meal` من وإلى Map.
- ظهور عناصر أساسية في Dashboard.

قبل الإصدار، أضف اختبارات تكامل لـ Firebase Emulator، وDio mock tests، واختبارات Auth، وحالات انقطاع الشبكة، واختبارات إمكانية الوصول وأحجام الشاشات. اختبارات Flutter لم تُشغّل داخل بيئة إنشاء الحزمة لعدم توفر Flutter SDK هنا؛ يجب تشغيل `flutter analyze` و`flutter test` محليًا وقراءة النتائج قبل الاعتماد على الإصدار.

## 9. ملاحظات طبية وخصوصية

NutriVision أداة تثقيف وتتبع غذائي عامة وليست جهازًا طبيًا. لا تعتمد على AI لتشخيص الأمراض أو وصف الحميات العلاجية. يجب على المستخدمين ذوي الحساسية الغذائية أو الحالات الصحية الرجوع إلى مختص مؤهل، ويجب ألا تُعرض اقتراحات AI على أنها دقيقة أو مضمونة. لا ترسل بيانات صحية حساسة إلى مزود خارجي دون موافقة واضحة وسياسة خصوصية مناسبة.

## 10. ملفات التصميم

راجع `docs/architecture.md` و`docs/user_personas.md` و`docs/user_flows.md` و`docs/wireframes.md` لتفاصيل بنية النظام، واحتياجات المستخدم، وتدفقات الاستخدام، والتخطيط الأولي للشاشات.
