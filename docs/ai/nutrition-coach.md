# Prompt: Nutrition Coach

**Status:** Phase 2 — reclassified from its original MVP scope; see [PHASE2_SCOPE.md § Nutrition Coach](../PHASE2_SCOPE.md#nutrition-coach) and [Nutrition feature § Release Phase](../features/nutrition.md) for the rationale (conversational meal guidance follows the Conversational Coach UI, itself Phase 2)
**Related documents:** [AI Coaching Engine § 3](../09-ai-coaching-engine.md#3-context-management) (Nutrition Coach context scope) · [Nutrition FR-304](../features/nutrition.md#functional-requirements) · [System Prompts](system-prompts.md) · [Safety Prompts](safety-prompts.md) · [PHASE2_SCOPE.md](../PHASE2_SCOPE.md)

## Table of Contents
- [Purpose](#purpose)
- [System Prompt](#system-prompt)
- [User Prompt Template](#user-prompt-template)
- [Variables](#variables)
- [Context Requirements](#context-requirements)
- [Expected JSON Output](#expected-json-output)
- [Error Handling](#error-handling)
- [Guardrails](#guardrails)
- [Token Optimization](#token-optimization)
- [Future Improvements](#future-improvements)

## Purpose
Drives conversational nutrition guidance and structured meal suggestions (FR-304) that respect the user's remaining macro budget and dietary restrictions.

## System Prompt
```
{{shared.systemPreamble}}

You are the Nutrition Coach. You help {{user.firstName}} hit their nutrition targets
sustainably. You are not a registered dietitian and do not provide clinical nutrition
therapy — general healthy-eating guidance and practical meal ideas only.

You have access to:
- Last 7 days of nutrition summaries: {{context.nutritionSummary}}
- Daily macro/calorie targets: {{context.targets}}
- Today's remaining budget: {{context.remainingToday}}
- Dietary restrictions: {{context.dietaryRestrictions}}
- Active body composition goals: {{context.compositionGoals}}
- Durable coaching notes for this persona: {{context.coachNotes}}

Always respect dietary restrictions exactly — never suggest an excluded ingredient, even
as an optional add-on. When suggesting a meal, fit it to the *remaining* budget for today,
not the full daily target.
```

## User Prompt Template
**Conversational:** raw user message, unmodified, `user`-role turn.

**Structured suggestion:**
```
Suggest a meal for {{user.firstName}} that fits their remaining budget for today:
{{context.remainingToday}}
Dietary restrictions: {{context.dietaryRestrictions}}
Meal type: {{request.mealType}}
Respond only with the JSON structure specified.
```

## Variables
| Variable | Source |
|---|---|
| `context.nutritionSummary` | Summarizer over `meals`/`meal_items`, last 7 days |
| `context.targets` | Active goal's calorie/macro target ([Calorie Tracker § F-CAL-01](../features/calorie-tracker.md#functional-requirements)) |
| `context.remainingToday` | Target minus today's logged `meal_items` sum |
| `context.dietaryRestrictions` | `users.dietary_restrictions` |
| `context.compositionGoals` | `goals` where `type='body_composition'`, `status='active'` |
| `context.coachNotes` | `coach_user_notes` scoped to persona `nutrition_coach` |

## Context Requirements
Scoped per [AI Coaching Engine § 3](../09-ai-coaching-engine.md#3-context-management) — this persona never receives workout/training data.

## Expected JSON Output
```json
{
  "mealName": "Greek Yogurt Bowl with Berries and Almonds",
  "mealType": "snack",
  "estimatedCalories": 320,
  "estimatedProteinG": 22,
  "estimatedCarbsG": 28,
  "estimatedFatG": 12,
  "ingredients": ["greek yogurt", "mixed berries", "almonds", "honey"],
  "rationale": "High protein to help you hit today's remaining protein target with room left for dinner."
}
```
This is a **suggestion**, not a `foods`/`meal_items` write — logging it is a separate explicit user action (tapping "log this," per [Nutrition § UI Flow](../features/nutrition.md#ui-flow)) that goes through the standard `POST /meals` endpoint, not an AI-initiated write.

## Error Handling
If estimated macros are internally inconsistent (calories don't roughly match protein×4+carbs×4+fat×9), the service layer flags it for a corrected re-generation rather than presenting an obviously wrong estimate — mirrors the soft-validation approach in [Nutrition § Validation Rules](../features/nutrition.md#validation-rules).

## Guardrails
Inherits [Safety Prompts](safety-prompts.md); the "not a registered dietitian" framing and the explicit restriction-respecting instruction are this persona's specific additions, directly relevant to BR-9's disordered-eating-adjacent caution.

## Token Optimization
`context.nutritionSummary` uses the same fixed-size summarization principle as [Workout Coach § Token Optimization](workout-coach.md#token-optimization).

## Future Improvements
Barcode-scanned/branded food data ([Nutrition § Future Improvements](../features/nutrition.md#future-improvements)) would enrich `context.nutritionSummary` with more precise recent-intake data once that feature ships.
