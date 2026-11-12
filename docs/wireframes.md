# Low-fidelity wireframes

These text wireframes describe information hierarchy, not final visual assets.

## Dashboard — narrow screen

```text
┌──────────────────────────────────┐
│ 🌿 NutriVision              AI ⋮  │
│ Tuesday, 20 October               │
│ Your health starts with choices   │
├──────────────────────────────────┤
│ CALORIES LOGGED                   │
│ 1,240 kcal     3 meals            │
│       decorative leaf (Stack)     │
├──────────────────────────────────┤
│ Macronutrients                    │
│ ● Protein        42 g             │
│ ● Carbohydrates  130 g            │
│ ● Fat             35 g            │
├──────────────────────────────────┤
│ Macro distribution (pie chart)    │
├──────────────────────────────────┤
│ Meal history                      │
│ Breakfast          420 kcal       │
│ Lunch              610 kcal       │
│ Snack              210 kcal       │
│                         [+ Meal]  │
└──────────────────────────────────┘
```

## Add meal

```text
┌──────────────────────────────────┐
│ ← Add a meal                     │
│ Meal name / description           │
│ Ingredients and serving size      │
│ Nutrition values (approximate)    │
│ Calories [      ]  Search food    │
│ Protein  [  ]  Carbs [  ]         │
│ Fat      [      ]                 │
│ Dietary restrictions (optional)   │
│ [ Save and analyze ]              │
│ AI output is general education    │
└──────────────────────────────────┘
```

## Responsive behavior

- Narrow view: stack macro card and chart vertically.
- Wide view: `GridView.extent` places cards in multiple columns where space permits.
- `Stack` decorates the calorie hero card without obscuring its text.
- Forms use a scroll view and bounded fields to support smaller displays and accessibility text scaling.
