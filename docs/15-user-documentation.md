# User Documentation

**Product:** Aesthetic Coach
**Related documents:** [PRD](01-prd.md) · [UI/UX Design System](06-ui-ux-design-system.md) · [AI Coaching Engine](09-ai-coaching-engine.md)

This document defines the *structure and content* of user-facing help material. It is written as the source content for the in-app help center and onboarding flow — copy here should match the tone rules in [UI/UX Design System § Content & Tone Guidelines](06-ui-ux-design-system.md#9-content--tone-guidelines).

---

## 1. User Onboarding

**Goal:** get a new user to their first logged action and first AI interaction within the first session, per [PRD § Objectives](01-prd.md#2-objectives) (O2).

**Flow:**
1. **Account creation** — email/password or Google/Apple (one tap).
2. **Profile basics** — units preference, timezone (auto-detected), optional date of birth/sex/height (explained: "used to personalize your nutrition targets and score, never shared").
3. **Goal selection** — pick a primary goal type (strength / body composition / general habit-building / event-based); this seeds the AI Personal Trainer persona's initial context.
4. **Experience level** — beginner / intermediate / advanced, and equipment access (home / gym / minimal) — feeds adaptive template generation (FR-206).
5. **Meet your coach** — a short, guided first conversation with the Personal Trainer persona that ends in an actual generated first workout, so the user experiences the core AI loop immediately rather than landing on an empty log screen (addresses the "Guided Beginner" persona directly, [PRD § 3.1](01-prd.md#31-user-personas)).
6. **Notification permission prompt** — asked with context ("We'll remind you before your streak resets and let you know when your weekly review is ready") rather than a bare OS prompt with no explanation.

Onboarding can be skipped/resumed — nothing is a hard gate except account creation and email verification (which only blocks AI features per BR-2, not core logging).

## 2. User Guide (Help Center Article Outline)

### Getting Started
- Creating your account and signing in (email, Google, Apple)
- Setting your goal and preferences
- Understanding your Daily Fitness Score
- Meeting your AI coach

### Training
- Logging a workout (guided and freeform)
- Using workout templates and AI-generated plans
- Understanding personal records (PRs)
- Browsing the exercise library
- Logging a workout offline

### Nutrition
- Logging meals and searching foods
- Setting macro/calorie targets
- Logging water intake
- Getting meal suggestions from your Nutrition Coach

### Body Metrics
- Logging weight and measurements
- Adding progress photos (privacy: who can see these — answer: only you)
- Reading your trend charts

### Habits & Goals
- Creating and tracking habits
- Understanding streaks
- Setting and editing goals

### AI Coach
- Starting a conversation
- Switching coaching personas
- Reading your Weekly Review
- What your coach can and can't help with (see § 4 FAQ, ties to [AI Coaching Engine § Safety Guardrails](09-ai-coaching-engine.md#7-safety-guardrails))

### Account & Settings
- Managing notification preferences
- Managing devices/sessions, signing out remotely
- Exporting your data
- Deleting your account

## 3. FAQ

**Q: Is my AI coach a real trainer or a doctor?**
No. Aesthetic Coach's AI coach gives general fitness, nutrition, and habit guidance based on your logged data. It is not a substitute for medical, nutritional, or physical therapy advice, and it will tell you when something you're describing is better handled by a professional.

**Q: Can I use the app without an internet connection?**
Yes — logging workouts, viewing recent history, and checking off habits all work offline and sync automatically once you're back online. AI coaching requires a connection.

**Q: Why did my Daily Fitness Score drop even though I worked out?**
The score blends training, nutrition, recovery, and habits — tap the score to see the breakdown of all four components and what moved.

**Q: How is my data used by the AI?**
Your coach only sees the data relevant to what you're asking about (e.g., the Nutrition Coach doesn't see your workout history) and never shares your data with other users. See [AI Coaching Engine § Context Management](09-ai-coaching-engine.md#3-context-management) for the technical detail behind this.

**Q: Can I delete my account and data?**
Yes, from Settings → Account → Delete Account. Your data is hidden immediately and permanently deleted after a 30-day grace period (in case you change your mind).

**Q: How do I switch between coaching personas?**
Use the persona switcher at the top of the Coach tab. Some personas are marked "Coming soon" — see the roadmap for what's next.

## 4. Troubleshooting

| Symptom | Likely cause | Resolution |
|---|---|---|
| "Pending sync" never clears on a workout | No connectivity, or app hasn't been foregrounded to trigger background sync | Open the app with an internet connection; sync runs automatically |
| AI coach not responding | Daily coaching limit reached, or no connectivity | Check for the in-app "limit reached, resets at..." message; otherwise check connection |
| Notifications not arriving | Notification permission denied at OS level, or category disabled in-app | Check OS settings and Settings → Notifications in-app |
| Score not updating | Score computes once per day; today's data logged after your local end-of-day cutoff counts toward tomorrow | Wait for the next daily computation, or check the score breakdown for what's missing |
| Can't sign in after reinstalling | Sessions are device-bound; reinstalling counts as a "new device" | Sign in again normally; this doesn't affect your data |

## 5. Help Center Structure

```
Help Center
├── Getting Started
├── Training
├── Nutrition
├── Body Metrics
├── Habits & Goals
├── AI Coach
├── Account & Settings
├── Troubleshooting
└── Contact Support (escalation to human support, out of scope for the AI coach per its guardrails)
```

Searchable, with each article tagged to the feature area so in-app contextual help links (e.g., a "?" icon on the Score Ring) deep-link directly to the relevant article rather than a generic help homepage.

## 6. Admin Documentation

Internal-only reference for the (Phase 2+) admin/support tooling — not customer-facing:

- **User lookup & support actions:** search by email/ID, view (not edit) tracked data for support diagnosis, force-revoke sessions, trigger a manual data export on a user's behalf, process account deletion requests submitted via support channel instead of in-app.
- **AI usage oversight:** per-user token usage view (for cost/abuse investigation), guardrail-trigger log review (per [AI Coaching Engine § Safety Guardrails](09-ai-coaching-engine.md#7-safety-guardrails)).
- **Content management:** exercise library and food database curation (add/edit/deprecate entries), prompt template review workflow (ties to [AI Coaching Engine § Prompt Management](09-ai-coaching-engine.md#2-prompt-management) — prompt changes go through the same PR review as code).
- **Feature flag management:** toggle flags defined in [CI/CD Pipeline § Feature Flags](11-cicd-pipeline.md#6-feature-flags) per user segment.
- Access to admin tooling requires a distinct elevated-privilege auth path, audit-logged for every action — never the same session/token type as regular user auth.
