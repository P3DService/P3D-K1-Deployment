# Компоненты baseline

P3D K1 Deployment не пытается установить всё, что доступно в Helper Script. Цель — минимальный проверенный production baseline.

## Moonraker + Nginx

Moonraker предоставляет API между Klipper и внешними интерфейсами/интеграциями.

Nginx используется как web/reverse-proxy слой.

Deployment проверяет:
- процесс Moonraker;
- процесс Nginx;
- `/server/info`;
- соединение Moonraker ↔ Klippy;
- доступность `printer/info` в FULL режиме.

## Fluidd

Основной web UI baseline.

Проверяется HTTP-доступность:

```
http://127.0.0.1:4408/
```

## Entware

Используется как package layer, в том числе Helper Script для зависимостей Moonraker Timelapse.

Проверяется наличие:

```
/opt/bin/opkg
```

## Klipper Gcode Shell Command

Добавляет возможность вызывать shell commands из Klipper macros. Требуется некоторым расширениям baseline.

## KAMP

Klipper Adaptive Meshing & Purging.

Используется для adaptive bed mesh и purge в области текущей модели.

Deployment автоматически отвечает `n` на:

```
Do you want to enable needed macros for PrusaSlicer?
```

и проверяет include:

```
[include Helper-Script/KAMP/KAMP_Settings.cfg]
```

## Nozzle Cleaning Fan Control

Отдельный компонент Helper Script для поведения вентилятора в процессе nozzle cleaning.

Важно: это **не** `Fans Control Macros`.

## Improved Shapers Calibrations

Дополнительные calibration macros для input shaper / belts / resonance workflows.

## Useful Macros

Набор utility macros Helper Script.

## Save Z-Offset Macros

Макросы для сохранения/восстановления Z-offset.

## M600 Support

Поддержка filament-change macro `M600`.

## Moonraker Timelapse

Сторонний компонент Moonraker для формирования timelapse.

Deployment проверяет:
- Python component;
- `timelapse.cfg`;
- секцию `[timelapse]`;
- snapshot URL;
- `ffmpeg`.

## Почему stock Creality Timelapse выключается

Deployment использует Moonraker Timelapse как единственный baseline-механизм timelapse.

Stock Creality Timelapse выключается в:

```
/usr/data/creality/userdata/config/user_print_refer.json
```

и перед первым изменением сохраняется:

```
user_print_refer.json.p3d-original
```

Это снижает вероятность параллельного создания двух независимых наборов видео/кадров и упрощает контроль диска.

## Fans Control Macros — deny-list

`Fans Control Macros` намеренно не входит в baseline.

На тестовом K1C-парке P3D установка этого компонента ранее совпала с появлением ошибки вентилятора во время печати. После отключения компонент был исключён из production baseline.

Поэтому при обнаружении:

```
/usr/data/printer_data/config/Helper-Script/fans-control.cfg
```

deployment останавливается.

Это консервативное решение данного проекта, а не универсальное утверждение о совместимости компонента со всеми прошивками/ревизиями K1-series.
