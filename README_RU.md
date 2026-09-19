# P3D K1 Deployment

[English](README.md) | **Русский**

Автоматизированное развёртывание, настройка Fluidd и проверка состояния rooted-принтеров **Creality K1C** и **Creality K1 Max**.

P3D K1 Deployment превращает rooted K1-series в воспроизводимый проверенный baseline: нужный набор Helper Script, рабочая камера, Moonraker Timelapse, автоочистка диска, организованные макросы Fluidd и QUICK/FULL healthcheck.

> Это независимый community-проект P3D Service. Он не является официальным продуктом Creality или Guilouz. [Creality Helper Script](https://github.com/Guilouz/Creality-Helper-Script) используется как внешний upstream, его installer logic в репозиторий не копируется.

## Текущий stable baseline

**v0.6.0**

Проверено на:

- Creality K1C ×3
- Creality K1 Max ×1

Финальный FULL:

```
PASS: 56
WARN: 0
FAIL: 0
STATUS: PASS
```

Протестированный Creality Helper Script commit:

```
b46787a61b3ce2f04ec04d115a73a46c26814057
```

## Что делает проект

`deploy.sh`:

- проверяет модель K1-series и свободное место;
- устанавливает или сверяет Creality Helper Script;
- останавливается при непроверенной revision Helper Script;
- устанавливает approved modules;
- блокирует `Fans Control Macros` в текущем baseline;
- проверяет/восстанавливает MJPEG camera runtime;
- отключает штатный Creality Timelapse;
- включает Moonraker Timelapse;
- проверяет/исправляет путь ffmpeg;
- ставит cleanup timelapse + cron;
- включает автоматический QUICK после boot и раз в сутки;
- ждёт реальной готовности Moonraker API;
- автоматически настраивает webcam во Fluidd;
- группирует макросы Fluidd и скрывает системные;
- завершает работу только после FULL validation.

## Approved Helper Script modules

1. Moonraker + Nginx
2. Fluidd
3. Entware
4. Klipper Gcode Shell Command
5. KAMP
6. Nozzle Cleaning Fan Control
7. Improved Shapers Calibrations
8. Useful Macros
9. Save Z-Offset Macros
10. M600 Support
11. Moonraker Timelapse

PrusaSlicer-specific KAMP macros по умолчанию не включаются.

## Fluidd baseline

### Группы макросов

```
PRINT         4
CALIBRATION   6
KAMP          2
TIMELAPSE     2
```

Остальные live Klipper macros не удаляются, а только скрываются из dashboard Fluidd.

### Камера

Baseline:

```
service: mjpegstreamer-adaptive
stream_url: /webcam/?action=stream
snapshot_url: /webcam/?action=snapshot
target_fps: 15
target_fps_idle: 5
aspect_ratio: 4:3
```

Если database-managed camera уже существует, её `name` и `uid` сохраняются. Относительные URL не зависят от IP принтера.

## Быстрый старт

После получения root:

```bash
ssh root@PRINTER_IP
```

Рекомендуемый pinned bootstrap:

```bash
wget -q -O /tmp/p3d-k1-install.sh \
  https://raw.githubusercontent.com/P3DService/P3D-K1-Deployment/v0.6.0/install.sh

cat /tmp/p3d-k1-install.sh
sh /tmp/p3d-k1-install.sh
```

One-liner:

```bash
wget -qO- https://raw.githubusercontent.com/P3DService/P3D-K1-Deployment/v0.6.0/install.sh | sh
```

> На некоторых stock BusyBox выводится `TLS certificate validation not implemented`. Подробности и trade-off — в [Troubleshooting](docs/ru/TROUBLESHOOTING.md).

## FRESH и RECONCILE

### FRESH

```
factory reset / новый принтер
→ root
→ bootstrap
→ Helper Script stack
→ P3D fixes
→ Fluidd provisioning
→ FULL healthcheck
→ READY
```

### RECONCILE

```
уже настроенный принтер
→ deploy
→ обнаружение существующих компонентов
→ добавление недостающего baseline
→ сохранение совместимого пользовательского состояния
→ FULL healthcheck
```

## Healthcheck

QUICK:

```bash
/usr/data/scripts/p3d-k1/healthcheck.sh --quick
```

FULL:

```bash
/usr/data/scripts/p3d-k1/healthcheck.sh --full
```

Текущий статус:

```bash
cat /usr/data/scripts/p3d-k1/status
```

История:

```bash
tail -100 /usr/data/scripts/p3d-k1/healthcheck.log
```

Лог deployment:

```bash
tail -100 /usr/data/scripts/p3d-k1/deploy.log
```

## Документация

### Русский

- [Установка](docs/ru/INSTALLATION.md)
- [Компоненты](docs/ru/COMPONENTS.md)
- [Healthcheck](docs/ru/HEALTHCHECK.md)
- [Fluidd provisioning](docs/ru/FLUIDD_PROVISIONING.md)
- [Архитектура](docs/ru/ARCHITECTURE.md)
- [Troubleshooting](docs/ru/TROUBLESHOOTING.md)
- [Валидация](docs/ru/VALIDATION.md)
- [Release notes v0.6.0](docs/ru/RELEASE_v0.6.0.md)

### English

- [Installation](docs/en/INSTALLATION.md)
- [Components](docs/en/COMPONENTS.md)
- [Healthcheck](docs/en/HEALTHCHECK.md)
- [Fluidd provisioning](docs/en/FLUIDD_PROVISIONING.md)
- [Architecture](docs/en/ARCHITECTURE.md)
- [Troubleshooting](docs/en/TROUBLESHOOTING.md)
- [Validation](docs/en/VALIDATION.md)
- [v0.6.0 release notes](docs/en/RELEASE_v0.6.0.md)

## Сообщество

Ошибки, compatibility reports и идеи — через GitHub Issues.

См. [CONTRIBUTING_RU.md](CONTRIBUTING_RU.md) или [CONTRIBUTING.md](CONTRIBUTING.md).

## Внешний мониторинг

Проект экспортирует локальное состояние через:

```
/usr/data/scripts/p3d-k1/status
/usr/data/scripts/p3d-k1/healthcheck.log
```

Эти данные можно использовать в Home Assistant, дашбордах или системах управления парком без привязки публичного репозитория к приватной инфраструктуре.

## Лицензия

MIT. См. [LICENSE](LICENSE).

## Credits

- [Creality](https://www.creality.com/)
- [Guilouz / Creality Helper Script](https://github.com/Guilouz/Creality-Helper-Script)
- Klipper
- Moonraker
- Fluidd
- KAMP

P3D Service — production 3D printing / CAD / reverse engineering.
