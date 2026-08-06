# Component: Button

**Related documents:** [UI/UX Design System § 2](../06-ui-ux-design-system.md#2-design-tokens) · [Mobile Architecture § 1](../08-mobile-architecture.md#1-state-management)

## Table of Contents
- [Purpose](#purpose)
- [Variants](#variants)
- [States](#states)
- [Properties](#properties)
- [Accessibility](#accessibility)
- [Usage Guidelines](#usage-guidelines)
- [Flutter Implementation Notes](#flutter-implementation-notes)

## Purpose
The primary interactive control for triggering actions — the single most-used component in the app.

## Variants
| Variant | Usage |
|---|---|
| Primary | One per screen/section max — the main CTA ("Start Workout", "Log In") |
| Secondary | Supporting actions alongside a primary button |
| OAuth | Google/Apple sign-in buttons, provider-branded per platform guidelines (a documented exception to the single-icon-family rule in [UI/UX Design System § 2.4](../06-ui-ux-design-system.md#24-iconography), since provider brand marks are contractually fixed) |
| Text/Link | Low-emphasis actions ("Forgot password?", "Skip") |
| Icon | Compact, icon-only actions (e.g., close, more-options) — always paired with a semantic label for accessibility even without visible text |
| Destructive | Red-toned (`accent.danger`), reserved for irreversible actions, always paired with a [Dialog](dialog.md) confirmation |

## States
Default, Pressed (scale/opacity feedback, `motion.fast`), Disabled (reduced opacity, non-interactive), Loading (label replaced by inline spinner, button remains its full size to avoid layout shift).

## Properties
| Property | Type | Notes |
|---|---|---|
| `label` | String | Required unless icon-only |
| `variant` | enum | primary/secondary/oauth/text/icon/destructive |
| `isLoading` | bool | Disables interaction, shows spinner |
| `isDisabled` | bool | |
| `icon` | IconData? | Optional leading icon |
| `onPressed` | callback | Required unless disabled |

## Accessibility
Minimum 48x48dp touch target regardless of visual size (§ [UI/UX Design System § 2.3](../06-ui-ux-design-system.md#23-spacing--layout)); icon-only buttons require a `Semantics` label; disabled state is announced, not just visually muted.

## Usage Guidelines
Exactly one primary button visible per screen/section at a time — multiple competing primaries violate the "one glance, one action" principle ([UI/UX Design System § 1](../06-ui-ux-design-system.md#1-design-philosophy)). Destructive variant is never used for a primary/default action.

## Flutter Implementation Notes
Implemented as a themed wrapper around `FilledButton`/`OutlinedButton`/`TextButton` driven by `ButtonStyle` from the app `ThemeData` (tokens in [UI/UX Design System § 2](../06-ui-ux-design-system.md#2-design-tokens)), not ad hoc `Container`+`GestureDetector` composition — ensures consistent focus/ripple/disabled behavior for free from the framework.
