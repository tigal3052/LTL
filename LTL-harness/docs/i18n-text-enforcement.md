# I18n Text Enforcement

## Rule

User-facing UI text must be provided through a dynamic text catalog boundary. In `app-LTL`, the boundary is `app-LTL/src/ui/TextCatalog.gd`.

## Placement

The harness rule belongs between read-model/presenter contracts and scene rendering:

- Domain and vocabulary code may emit stable ids, enum values, and telemetry codes.
- Read models and presenters convert those ids into text keys or localized strings.
- Views render already-localized strings and must not own language decisions.
- Settings may change the active locale, then ask the current scene to re-render.

## Gate

Run this before completion:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/i18n-text-gate.ps1
```

The gate blocks known hardcoded English UI strings in formal UI and scene paths. When new user-facing phrases are added, add keys to `TextCatalog.gd` first and update the gate if the phrase would otherwise bypass review.
