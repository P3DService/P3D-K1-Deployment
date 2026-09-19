# Release v0.5.0

Первый публичный field-validated baseline P3D K1 Deployment.

## Поддержка

Проверено на:

- Creality K1C
- Creality K1 Max

## Validation

- RECONCILE: K1C ×3 — PASS
- FRESH после factory reset: K1 Max ×1 — PASS
- повторный deployment / идемпотентность: K1 Max ×1 — PASS
- финальный FULL gate: 54 PASS / 0 WARN / 0 FAIL

## Что входит

- автоматическая установка/сверка Creality Helper Script;
- Moonraker + Nginx;
- Fluidd;
- Entware;
- Klipper Gcode Shell Command;
- KAMP;
- Nozzle Cleaning Fan Control;
- Improved Shapers Calibrations;
- Useful Macros;
- Save Z-Offset Macros;
- M600 Support;
- Moonraker Timelapse;
- camera compatibility;
- stock Creality Timelapse OFF;
- ffmpeg compatibility;
- timelapse cleanup 80% → 75%;
- QUICK/FULL healthcheck;
- boot + daily QUICK monitoring;
- fail-closed safety gates.

## Tested Helper Script revision

```
b46787a61b3ce2f04ec04d115a73a46c26814057
```

## Установка

Рекомендуемый вариант:

```bash
wget -q -O /tmp/p3d-k1-install.sh \
  https://raw.githubusercontent.com/P3DService/P3D-K1-Deployment/main/install.sh

cat /tmp/p3d-k1-install.sh
sh /tmp/p3d-k1-install.sh
```

Быстрый one-liner:

```bash
wget -qO- https://raw.githubusercontent.com/P3DService/P3D-K1-Deployment/main/install.sh | sh
```

До появления immutable release/tag эти команды используют текущую ветку `main`. Для production рекомендуется просмотреть `install.sh` перед запуском.

## Healthcheck

QUICK:

```bash
/usr/data/scripts/p3d-k1/healthcheck.sh --quick
```

FULL:

```bash
/usr/data/scripts/p3d-k1/healthcheck.sh --full
```

Краткий статус:

```bash
cat /usr/data/scripts/p3d-k1/status
```

История:

```bash
tail -100 /usr/data/scripts/p3d-k1/healthcheck.log
```

## Известные ограничения

- требуется root;
- baseline привязан к конкретной ревизии Helper Script;
- новая firmware/hardware revision требует повторной валидации;
- это независимый community project, не официальный продукт Creality или Guilouz.
