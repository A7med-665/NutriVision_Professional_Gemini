# NutriVision Backend API contract

All protected endpoints require `Authorization: Bearer <Firebase ID token>`. The Node backend verifies this token using Firebase Admin before processing requests. Provider secrets remain on the server.

## `POST /api/nutrition`

### Meal analysis request

```json
{"task":"meal_analysis","meal_description":"oats with milk","dietary_restrictions":"lactose-free"}
```

Response: `{"advice":"..."}`

### Snack alternatives request

```json
{"task":"snack_alternatives","snack":"potato chips","dietary_restrictions":"vegan"}
```

Response: `{"alternatives":["...","..."]}`

### Recipe generation request (backend-supported)

```json
{"task":"recipe_generation","ingredients":["oats","banana"],"dietary_restrictions":"no added sugar"}
```

Response: `{"recipe":"..."}`

Inputs are length-limited and validated with Zod. Requests are rate-limited. Error responses intentionally avoid exposing provider internals or credentials. AI output is non-clinical and may be inaccurate.

## `GET /api/foods/search?q=<query>`

Requires a Firebase ID token. Proxies USDA FoodData Central search and returns a small normalized list:

```json
{"foods":[{"id":123,"name":"Food description","caloriesKcal":100,"proteinG":3,"carbsG":20,"fatG":1,"servingNote":"..."}]}
```

Values and serving conventions come from the USDA source and can vary. The app must not treat values as exact for the user's portion.

## `GET /api/health`

Public liveness check. Does not expose environment values.
