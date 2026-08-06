# Component: Card

**Related documents:** [UI/UX Design System § 2](../06-ui-ux-design-system.md#2-design-tokens) · [Dashboard screen](../screens/dashboard.md) · [Analytics screen](../screens/analytics.md)

## Table of Contents
- [Purpose](#purpose)
- [Variants](#variants)
- [States](#states)
- [Properties](#properties)
- [Accessibility](#accessibility)
- [Usage Guidelines](#usage-guidelines)
- [Flutter Implementation Notes](#flutter-implementation-notes)

## Purpose
The general-purpose content container used throughout Home, Progress, and Settings — groups related information on `surface.card` with consistent radius/elevation.

## Variants
| Variant | Usage |
|---|---|
| Standard | Default content grouping (e.g., nutrition summary, section wrapper) |
| Interactive | Tappable card that navigates/opens a detail view — includes a pressed state and disclosure affordance (chevron) |
| Stat | Compact variant for a single value + label + trend delta, used interchangeably with the dedicated Stat Tile pattern in [UI/UX Design System § 3](../06-ui-ux-design-system.md#3-core-components) |

## States
Default, Pressed (Interactive variant only), Loading (skeleton placeholder matching final card dimensions), Error (inline retry affordance within the card bounds).

## Properties
| Property | Type | Notes |
|---|---|---|
| `child` | Widget | Content slot |
| `onTap` | callback? | Present only for Interactive variant |
| `padding` | EdgeInsets | Defaults to `spacing.16` per token scale |
| `elevation` | token | `elevation.1` default, `elevation.2` for modals/raised contexts |

## Accessibility
Interactive cards are a single semantic tap target (not multiple nested tappable regions within, which confuses screen readers) — if a card needs multiple actions, it uses explicit [Button](button.md) children instead of making the whole card ambiguous.

## Usage Guidelines
Cards never nest more than one level deep (a card inside a card is a layout smell — restructure with sections/dividers instead). Consistent `radius.md` (14dp) across all card usages per [UI/UX Design System § 2](../06-ui-ux-design-system.md#2-design-tokens) — never a one-off radius value.

## Flutter Implementation Notes
Built on `Material`/`Card` with the design-system's `ThemeData.cardTheme` supplying color/radius/elevation tokens, wrapped in a shared `AcCard` widget so call sites never hardcode `BoxDecoration` values directly.
