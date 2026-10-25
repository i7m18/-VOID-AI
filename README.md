# VOID AI — Android Assistant

VOID AI is an Arabic-first Android assistant built with Kotlin, Jetpack Compose, Android speech recognition, Text-to-Speech, Gemini API, and an explicitly enabled Accessibility Service.

## Current build

- App version: **1.3**.
- Animated orbital interface with active/listening/thinking status.
- Arabic voice input and spoken responses.
- Gemini model fallback: `gemini-3.8-flash`, `gemini-3.6-flash`, and `gemini-3.5-flash-lite`.
- Multi-step screen agent: open apps, inspect visible accessibility text, tap visible controls, type into a focused non-password field, scroll, wait, and navigate Back/Home.
- Up to 16 planning/execution turns, longer waits after opening apps, and replanning after failed steps.
- Guardrails prevent the agent from automatically tapping clear send/publish/delete/purchase/payment controls. Password fields are never filled by the accessibility typing helper.
- GitHub Actions builds a debug APK and uploads it as `VOID-AI-debug-apk`.

## First setup

1. Install the debug APK.
2. In VOID AI, select **ربط AI** and enter your own Gemini API key. The app stores the key in its private app preferences. Do not share or commit the key.
3. Select **تحكم الشاشة**, find the VOID AI accessibility service in Android settings, and enable it only after reviewing what accessibility access means.
4. Return to VOID AI. Use **اختبار AI** before starting a task.
5. Give a clear task. For example: “افتح CapCut، ابدأ مشروع جديد، وورّيني شاشة اختيار المقاطع”. For video editing, the agent can only proceed through controls exposed to Android accessibility and assets you choose.

## Build APK

Open **Actions → Build VOID AI APK** and download the artifact `VOID-AI-debug-apk` after the workflow succeeds.

## Important capability boundaries

VOID AI is not unrestricted remote control. Android permissions, app login states, visual-only controls, protected screens, and each app's own behavior can block automation. The current agent reads accessibility-visible text; it does not yet have reliable vision for every canvas/timeline, and it cannot promise a finished CapCut export on every device. It must not claim a task was completed unless a visible result supports that claim. High-impact actions such as sending, publishing, deleting, or paying require manual confirmation.

## Development notes

- Android package: `com.voidai.app`
- Minimum SDK: 23
- Target SDK: 35
- Language/UI: Kotlin + Jetpack Compose
- API model support and availability may change; check the [official Gemini models guide](https://ai.google.dev/gemini-api/docs/models).
