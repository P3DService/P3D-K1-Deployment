# Changelog

## Unreleased

### Исправлено

- K1 Max: устранён ложный `CF0502` / `motherboard fan running abnormal`, возникавший после остановки отдельного `[controller_fan board_fan]`.
- `PB2` переведён на отдельный PWM board-fan baseline: 50% в idle, 100% при `mcu_temp >= 48 C`, возврат к 50% при `mcu_temp <= 42 C`.
- Добавлена fail-closed миграция stock/legacy K1 Max fan mapping и backup исходного `printer.cfg`.
- Healthcheck проверяет наличие K1 Max CF0502 baseline, отсутствие legacy `controller_fan board_fan` и отсутствие `PB2` в `heater_fans`.

### Field validation

- K1 Max: idle tach ~3200 RPM.
- K1 Max: printing tach ~4000 RPM.
- Печать завершена успешно; после 15+ минут idle CF0502 не повторилась.

## 0.6.0 — 2026-09-19

Новый stable baseline после field validation на K1C ×3 и K1 Max ×1.

### Validation

- K1C ×3 — PASS.
- K1 Max ×1 — PASS.
- FULL healthcheck: 56 PASS / 0 WARN / 0 FAIL.
- Fluidd macro grouping/visibility — PASS.
- Fluidd/Moonraker webcam provisioning — PASS.
- Relative camera URLs — PASS.

### Добавлено

- Автоматический Fluidd provisioning.
- Регистрация/нормализация Moonraker webcam.
- Относительные camera URLs через `/webcam/`, без привязки к IP.
- Сохранение существующего camera name/UID при reconcile.
- Группы макросов PRINT / CALIBRATION / KAMP / TIMELAPSE.
- Скрытие остальных macros только на уровне Fluidd dashboard, без удаления из Klipper.
- Защита custom Fluidd layouts: без force существующая нестандартная раскладка сохраняется и даёт WARN.
- Backup Fluidd state перед provisioning.
- FULL healthcheck validation для Fluidd macro/webcam baseline.

## 0.5.1 — 2026-09-19

Bootstrap/release packaging update. Runtime deployment baseline не изменён относительно 0.5.0.

### Изменено

- Добавлен публичный `install.sh` для bootstrap одной командой.
- Bootstrap по умолчанию закреплён на immutable release/tag `v0.5.1`.
- README обновлён на release-pinned installation workflow.
- Версия проекта синхронизирована с публичным release.

### Runtime baseline

- Creality Helper Script commit: `b46787a61b3ce2f04ec04d115a73a46c26814057`.
- RECONCILE: K1C ×3 — PASS.
- FRESH: K1 Max ×1 — PASS.
- Idempotency: K1 Max ×1 — PASS.
- FULL: 54 PASS / 0 WARN / 0 FAIL.

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
