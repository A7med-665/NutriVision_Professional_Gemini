# User personas (design-thinking artifact)

## Persona A — Busy student

- **Goal:** Log meals quickly and understand basic daily patterns.
- **Needs:** Few form fields, fast search, clear units, readable chart, forgiving validation.
- **Pain points:** Unclear serving sizes, nutrition labels with unfamiliar terms, limited time.
- **Design response:** Short add-meal form, USDA search, macro summary, and visible estimate disclaimer.

## Persona B — Person building healthier habits

- **Goal:** Discover realistic alternatives to frequent snacks without judgment.
- **Needs:** Respectful language, dietary restriction input, practical suggestions, no shame-based scoring.
- **Pain points:** Generic advice that ignores preferences or restrictions.
- **Design response:** AI alternatives request includes restrictions and presents suggestions as optional general information.

## Persona C — Privacy-conscious user

- **Goal:** Keep personal meal history private and available across devices.
- **Needs:** Authenticated account, clear cloud-sync behavior, data isolation, secure account access.
- **Pain points:** Unclear whether data is local or cloud-backed.
- **Design response:** Firebase Authentication, UID-scoped Firestore path and rules, explicit Demo Mode documentation.
