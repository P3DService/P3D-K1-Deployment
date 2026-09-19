# P3D K1 Deployment

Автоматизированное развёртывание, настройка и проверка состояния rooted-принтеров **Creality K1C** и **Creality K1 Max**.

Проект создан P3D Service как воспроизводимый способ привести принтер K1-series к заранее проверенному operational baseline после получения root-доступа — как на новом/сброшенном принтере, так и на уже настроенной машине.

> Проект не является официальным продуктом Creality или Guilouz. Он использует [Creality Helper Script](https://github.com/Guilouz/Creality-Helper-Script) как внешний upstream и не копирует его код.

## Что делает проект

`deploy.sh` автоматически:

- проверяет, что устройство относится к K1-series;
- проверяет свободное место и базовые зависимости;
- устанавливает или сверяет Creality Helper Script;
- проверяет совместимость внутреннего API Helper Script;
- устанавливает утверждённый набор компонентов;
- не допускает установку `Fans Control Macros` в baseline P3D;
- проверяет/восстанавливает MJPEG-поток камеры;
- отключает штатный Creality Timelapse;
- включает Moonraker Timelapse;
- проверяет `ffmpeg` и создаёт compatibility path `/opt/bin/ffmpeg` при необходимости;
- ставит автоматическую очистку timelapse-файлов при заполнении диска;
- включает QUICK healthcheck после загрузки и по расписанию;
- перезапускает Moonraker и ждёт реальной готовности API;
- завершает установку только после FULL healthcheck.

Проект поддерживает два сценария:

### FRESH

Новый принтер или принтер после factory reset:

```
Factory reset / new printer
→ root access
→ P3D deploy
→ Helper Script
→ approved components
→ P3D compatibility fixes
→ FULL healthcheck
→ PASS / WARN / FAIL
```

### RECONCILE

Уже настроенный K1C / K1 Max:

```
existing printer
→ P3D deploy
→ installed components are detected
→ missing baseline parts are added
→ configuration is reconciled
→ FULL healthcheck
```

Повторный запуск `deploy.sh` предусмотрен и должен быть идемпотентным для уже приведённого к baseline принтера.

## Поддерживаемые модели

На текущем подтверждённом baseline:

- Creality K1C
- Creality K1 Max

Скрипт намеренно проверяет модель перед изменениями.

## Устанавливаемые компоненты Helper Script

P3D baseline включает:

1. Moonraker + Nginx
2. Fluidd
3. Entware
4. Klipper Gcode Shell Command
5. Klipper Adaptive Meshing & Purging (KAMP)
6. Nozzle Cleaning Fan Control
7. Improved Shapers Calibrations
8. Useful Macros
9. Save Z-Offset Macros
10. M600 Support
11. Moonraker Timelapse

Для KAMP PrusaSlicer-specific macros автоматически оставляются выключенными.

### Что намеренно не входит в baseline

В частности, проект **не устанавливает Fans Control Macros**.

На тестовом парке P3D именно этот компонент ранее совпал с появлением ошибки вентилятора во время печати, поэтому в текущем baseline он является safety deny-list элементом. Это не утверждение о том, что компонент неисправен на всех K1-series; это консервативное решение данного deployment-профиля.

Другие необязательные компоненты Helper Script также не устанавливаются автоматически.

Подробности: [docs/COMPONENTS_RU.md](docs/COMPONENTS_RU.md).

## Быстрый старт

### 1. Получить root-доступ

Root-доступ должен быть уже включён штатным/поддерживаемым для вашей прошивки способом.

### 2. Скопировать скрипты на принтер

На macOS современные версии `scp` по умолчанию используют SFTP. На factory-reset K1/K1 Max может отсутствовать `/usr/libexec/sftp-server`, поэтому используйте legacy SCP mode:

```bash
ssh root@PRINTER_IP 'mkdir -p /usr/data/scripts/p3d-k1'

scp -O deploy.sh healthcheck.sh \
  root@PRINTER_IP:/usr/data/scripts/p3d-k1/
```

### 3. Запустить deployment

```bash
ssh root@PRINTER_IP
chmod +x /usr/data/scripts/p3d-k1/*.sh
/usr/data/scripts/p3d-k1/deploy.sh
```

Успешный финал выглядит так:

```
PASS: 54
WARN: 0
FAIL: 0
STATUS: PASS

P3D K1 DEPLOYMENT: PASS
```

Полная пошаговая инструкция: [docs/INSTALLATION_RU.md](docs/INSTALLATION_RU.md).

## Healthcheck

В проекте **один** `healthcheck.sh` и два режима.

### QUICK

```bash
/usr/data/scripts/p3d-k1/healthcheck.sh --quick
```

Проверяет operational health: Klipper, Moonraker, Fluidd/Nginx, camera snapshot, timelapse, ffmpeg, cron, место на диске и safety-инварианты.

QUICK автоматически запускается:
- после загрузки принтера;
- раз в сутки через cron.

### FULL

```bash
/usr/data/scripts/p3d-k1/healthcheck.sh --full
```

Включает QUICK-проверки и дополнительно проверяет:
- revision Helper Script;
- совместимость ожидаемого Helper API;
- наличие всех baseline-компонентов;
- Git-state Moonraker;
- KAMP integration;
- Moonraker printer API;
- boot services и P3D hooks.

FULL автоматически выполняется в конце `deploy.sh` и рекомендуется после обновлений/существенных изменений.

## Где смотреть результаты healthcheck

### Если healthcheck запущен вручную

Результат виден прямо в SSH-консоли:

```bash
/usr/data/scripts/p3d-k1/healthcheck.sh --quick
/usr/data/scripts/p3d-k1/healthcheck.sh --full
```

### Последний краткий статус

```bash
cat /usr/data/scripts/p3d-k1/status
```

Возможные значения:

```
PASS
WARN
FAIL
```

### История healthcheck

```bash
cat /usr/data/scripts/p3d-k1/healthcheck.log
```

или последние строки:

```bash
tail -100 /usr/data/scripts/p3d-k1/healthcheck.log
```

### Лог deployment

```bash
cat /usr/data/scripts/p3d-k1/deploy.log
```

Подробности: [docs/HEALTHCHECK_RU.md](docs/HEALTHCHECK_RU.md).

## Timelapse

Deployment оставляет **Moonraker Timelapse** и отключает штатный Creality Timelapse, чтобы избежать параллельного хранения двух наборов timelapse-файлов.

Проверяется:
- наличие Moonraker Timelapse component;
- `[timelapse]` в `moonraker.conf`;
- include `timelapse.cfg`;
- snapshot камеры;
- рабочий `ffmpeg`;
- путь `/opt/bin/ffmpeg`.

Если на конкретной прошивке `ffmpeg` расположен в `/usr/bin/ffmpeg`, deployment создаёт compatibility symlink.

## Автоочистка диска

Политика:

- запуск cleanup при заполнении `/usr/data` до 80%;
- удаление самых старых timelapse-файлов;
- остановка очистки после снижения заполнения до 75%;
- проверка раз в час.

## Безопасность изменений

Проект намеренно работает fail-closed:

- если модель не K1-series — deployment прекращается;
- если upstream Helper Script отличается от протестированного commit — deployment прекращается;
- если ожидаемые функции Helper Script исчезли — deployment прекращается;
- если найден `Fans Control Macros` — deployment прекращается;
- успешность Moonraker определяется по реальной готовности API, а не только по exit code init-script;
- production-ready состояние подтверждается FULL healthcheck.

## Проверенный baseline

Версия проекта: **v0.5**

Протестированный Helper Script commit:

```
b46787a61b3ce2f04ec04d115a73a46c26814057
```

Field validation:

| Сценарий | Модель | Результат |
|---|---|---|
| RECONCILE | K1C ×3 | PASS |
| FRESH | K1 Max ×1 | PASS |
| Повторный deploy / идемпотентность | K1 Max ×1 | PASS |

Подробности: [docs/VALIDATION_RU.md](docs/VALIDATION_RU.md).

## Интеграция с внешним мониторингом

Healthcheck хранит локальный итоговый статус в:

```
/usr/data/scripts/p3d-k1/status
```

и детальный лог в:

```
/usr/data/scripts/p3d-k1/healthcheck.log
```

Эти данные могут использоваться внешними системами мониторинга, Home Assistant, собственными дашбордами и системами управления парком оборудования.

Проект не зависит от какой-либо конкретной внешней платформы мониторинга.

## Документация

- [Установка](docs/INSTALLATION_RU.md)
- [Компоненты](docs/COMPONENTS_RU.md)
- [Healthcheck](docs/HEALTHCHECK_RU.md)
- [Архитектура](docs/ARCHITECTURE_RU.md)
- [Troubleshooting](docs/TROUBLESHOOTING_RU.md)
- [Валидация](docs/VALIDATION_RU.md)

## Ограничения

- Требуется root-доступ.
- Проект изменяет системные файлы принтера.
- Перед использованием рекомендуется иметь резервную копию критичных конфигов.
- Baseline привязан к протестированному commit Creality Helper Script.
- Новая версия прошивки Creality или Helper Script может потребовать повторной валидации.

## Лицензия

MIT. См. [LICENSE](LICENSE).

## Credits

- [Creality](https://www.creality.com/)
- [Guilouz / Creality Helper Script](https://github.com/Guilouz/Creality-Helper-Script)
- Moonraker
- Klipper
- Fluidd
- KAMP

P3D Service — production 3D printing / CAD / reverse engineering.
