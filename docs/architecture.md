# Architecture overview

## Design principles

- Feature-first organization: each product capability owns its presentation, data, and domain code.
- UI does not access Firestore directly; `MealRepository` is the persistence boundary.
- `MealCubit` owns loading, data, and error states for the meal feature.
- External provider secrets live only in the Node backend.
- Firestore document paths and rules share the same user boundary: `users/{uid}/meals/{mealId}`.

## Request flow

```text
Flutter UI -> Cubit -> Repository -> Cloud Firestore snapshots
     |            |
     |            +-> AI service -> Dio interceptor -> Express API -> AI provider
     +-> Food search screen -> NutritionCatalogService -> Express API -> USDA FoodData Central
```

## Trust boundaries

The Flutter client is untrusted. Firestore rules authorize direct data access by UID. The backend verifies Firebase ID tokens and validates request bodies. API provider keys are server environment variables. Rate limiting and payload size limits reduce abuse but do not replace quotas, monitoring, App Check, or deployment-level protections.

## Production hardening still required

- Automated CI with Flutter analyze/tests and backend tests.
- Firebase Emulator integration tests and API integration tests.
- Persistent offline cache and conflict strategy if offline-first behavior is required.
- Account deletion workflow, privacy policy, consent, observability, and data retention policy.
- AI output evaluation, abuse monitoring, spend limits, and prompt-injection testing.
