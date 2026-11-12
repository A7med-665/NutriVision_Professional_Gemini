# Main user flows

## First launch

1. Firebase configured? If not, show dashboard in Demo Mode.
2. If Firebase is configured, wait for `authStateChanges()`.
3. Signed-out user sees Login/Register.
4. New account receives email verification; unverified login is rejected with guidance.
5. Verified user enters Dashboard.

## Log a meal

1. Open Add Meal.
2. Enter meal name and optional notes/restrictions.
3. Optionally search USDA food data and select a result.
4. Review serving note and nutrition values; adjust values for actual serving size.
5. Submit; Cubit requests advice and persists the meal.
6. Dashboard updates from the meal stream.

## Discover snack alternatives

1. Open snack alternatives.
2. Enter the snack and dietary restrictions.
3. If AI backend is configured, send a token-authenticated request; otherwise show local fallback suggestions.
4. Present suggestions as non-medical general education.

## Sign out

1. Tap the sign-out icon.
2. Firebase Auth clears the current session.
3. AuthGate returns to the authentication screen; another account cannot access the previous account's Firestore path under the rules.
