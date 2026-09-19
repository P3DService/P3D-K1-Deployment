## Summary / Что изменено

<!-- Brief description / Краткое описание -->

## Why / Зачем

<!-- Problem and rationale / Проблема и причина -->

## Scope / Область

- [ ] deploy.sh
- [ ] healthcheck.sh
- [ ] install.sh
- [ ] Fluidd provisioning
- [ ] docs
- [ ] compatibility
- [ ] other / другое

## Tested on / Проверено на

Printer model / Модель:

Firmware / Прошивка:

P3D K1 Deployment version:

Creality Helper Script commit:

Scenario / Сценарий:

- [ ] FRESH
- [ ] RECONCILE
- [ ] repeat deploy / idempotency
- [ ] QUICK
- [ ] FULL

## FULL healthcheck

```text
PASS:
WARN:
FAIL:
STATUS:
```

## Risks and rollback / Риски и rollback

<!-- What can fail and how to revert / Что может сломаться и как откатить -->

## Checklist

- [ ] BusyBox / `/bin/sh` compatible.
- [ ] No unchecked GNU-only dependencies.
- [ ] No secrets or private infrastructure data.
- [ ] CHANGELOG updated if user-visible behavior changed.
- [ ] Repeat deployment does not break a baseline printer.
