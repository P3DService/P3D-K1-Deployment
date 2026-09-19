## Что изменено

<!-- Кратко -->

## Зачем

<!-- Проблема / причина -->

## Scope

- [ ] deploy.sh
- [ ] healthcheck.sh
- [ ] install.sh
- [ ] docs
- [ ] compatibility
- [ ] другое

## Проверено на

Модель:

Firmware:

P3D K1 Deployment version:

Creality Helper Script commit:

Сценарий:

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

## Риски / rollback

<!-- Что может пойти не так и как откатить -->

## Checklist

- [ ] Код совместим с BusyBox / `/bin/sh`.
- [ ] Нет GNU-only зависимостей без проверки.
- [ ] Не добавлены secrets/private data.
- [ ] CHANGELOG обновлён, если поведение пользователя изменилось.
- [ ] Повторный deploy не ломает уже приведённый к baseline принтер.
