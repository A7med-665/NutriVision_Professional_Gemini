# Security and release checklist

- [ ] Firebase Email/Password provider enabled; email verification tested.
- [ ] Firestore rules deployed and tested in Firebase Emulator Suite with two distinct users.
- [ ] No service-account JSON, AI provider key, or USDA key committed to source control.
- [ ] Backend runs with `REQUIRE_FIREBASE_AUTH=true` and verifies revoked/expired ID tokens.
- [ ] Production `CORS_ORIGINS` lists only the actual web origins.
- [ ] Backend is served over HTTPS; secrets are configured in the hosting platform's secret manager.
- [ ] App Check enabled and enforced where supported.
- [ ] Rate limits, provider usage quotas, timeout handling, and spend alerts configured.
- [ ] Privacy policy explains what meal data is stored and which external providers receive prompts.
- [ ] User consent is obtained before sending dietary descriptions to AI providers.
- [ ] Account deletion and associated Firestore data deletion workflow implemented.
- [ ] Logs avoid storing access tokens, secrets, and unnecessary dietary/personal data.
- [ ] `flutter analyze`, `flutter test`, backend checks, and device smoke tests pass on release commit.
- [ ] Accessibility, screen sizes, offline behavior, localization, and error states manually reviewed.
- [ ] Nutrition and AI content clearly states it is general education, not medical diagnosis or treatment.
