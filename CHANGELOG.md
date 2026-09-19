# Changelog

## 0.5.0 — 2026-09-19

Первый публичный validated baseline.

### Подтверждено

- RECONCILE на Creality K1C ×3.
- FRESH deployment после factory reset на Creality K1 Max.
- Повторный deployment на K1 Max без переустановки уже присутствующих компонентов.
- FULL healthcheck: 54 PASS / 0 WARN / 0 FAIL на финальной проверке.

### Исправления, найденные во время field validation

- Добавлено ожидание готовности Moonraker API после restart вместо фиксированной задержки.
- Внутренние функции Creality Helper Script теперь загружаются вместе с `scripts/menu/functions.sh`.
- Ненулевой exit code старого Moonraker init-script больше не считается единственным источником истины: решающим является API readiness.
- Проверка Helper Script API совместима со stock BusyBox grep (`-r`/проверка конкретных файлов вместо GNU-only `-R`).
- Убраны ложные WARN по одиночной строке `Traceback` без подтверждённой критической ошибки.

### Baseline

Creality Helper Script commit:

```
b46787a61b3ce2f04ec04d115a73a46c26814057
```
