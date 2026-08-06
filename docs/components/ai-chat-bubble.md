# Component: AI Chat Bubble

**Related documents:** [AI Coach feature](../features/ai-coach.md) · [AI Coach screen](../screens/ai-coach.md) · [AI Coaching Engine § 7](../09-ai-coaching-engine.md#7-safety-guardrails) · [UI/UX Design System § 3](../06-ui-ux-design-system.md#3-core-components)

## Table of Contents
- [Purpose](#purpose)
- [Variants](#variants)
- [States](#states)
- [Properties](#properties)
- [Accessibility](#accessibility)
- [Usage Guidelines](#usage-guidelines)
- [Flutter Implementation Notes](#flutter-implementation-notes)

## Purpose
The message bubble rendering both user and AI turns in the Coach tab conversation view.

## Variants
| Variant | Usage |
|---|---|
| User | Right-aligned, `brand.primary`-tinted background |
| Assistant | Left-aligned, `surface.card` background, persona avatar + name header |
| Disclaimer | Assistant sub-variant for guardrail-appended professional-referral text ([AI Coaching Engine § 7](../09-ai-coaching-engine.md#7-safety-guardrails)) — visually distinct (subtle border/icon) so users learn to recognize it, without looking alarming |
| System/Info | Centered, low-emphasis, for conversation-level notices (e.g., "Persona switched to Nutrition Coach") |

## States
Streaming (partial content, subtle cursor/pulse indicator at the text's end), Complete, Error (failed to generate — shows a retry affordance inline in place of content).

## Properties
| Property | Type | Notes |
|---|---|---|
| `role` | enum | user/assistant/system |
| `content` | String | Supports markdown-lite: bold, bullet lists (per [UI/UX Design System § 3](../06-ui-ux-design-system.md#3-core-components)) |
| `persona` | enum? | Assistant only — drives avatar/name header |
| `isStreaming` | bool | |
| `timestamp` | DateTime | |

## Accessibility
Streaming updates announced in complete-sentence chunks, not per-token (per [AI Coach screen § Accessibility](../screens/ai-coach.md#accessibility)); persona identity is conveyed via both an icon/avatar and a text name, never icon alone.

## Usage Guidelines
Markdown rendering is deliberately minimal (bold + lists only, no headers/tables/code blocks) — keeps AI responses feeling conversational rather than document-like, consistent with the "calm intelligence" principle in [UI/UX Design System § 1](../06-ui-ux-design-system.md#1-design-philosophy).

## Flutter Implementation Notes
Content rendered via a constrained markdown-lite parser (not a full CommonMark package, to keep the sandboxed rendering surface small and predictable given it displays LLM-generated text); streaming text updates use an efficient append-only text-span builder rather than re-parsing the full message on every token to avoid jank during rapid streaming.
