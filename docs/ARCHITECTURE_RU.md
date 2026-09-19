# Архитектура

## Цель

P3D K1 Deployment — тонкий orchestration layer поверх Creality Helper Script и штатной системы K1-series.

Проект не форкает Helper Script и не копирует его installer logic. Вместо этого он:

1. фиксирует проверенный upstream commit;
2. загружает штатные функции Helper Script;
3. вызывает выбранные installer functions в контролируемом порядке;
4. добавляет P3D compatibility/safety layer;
5. валидирует фактический runtime.

## Поток deployment

```
rooted K1-series
       |
       v
preflight
       |
       v
Helper Script revision gate
       |
       v
Helper Script API compatibility gate
       |
       v
approved component installation/reconcile
       |
       v
camera + timelapse + ffmpeg compatibility
       |
       v
cleanup + cron + boot healthcheck
       |
       v
Moonraker restart
       |
       v
Moonraker API readiness
       |
       v
FULL healthcheck
       |
       v
PASS / WARN / FAIL
```

## Почему фиксируется upstream commit

Внутренние installer functions Helper Script не являются стабильным публичным API.

Поэтому текущий deployment разрешает автоматические изменения только с commit:

```
b46787a61b3ce2f04ec04d115a73a46c26814057
```

Если upstream изменился, deployment останавливается до новой проверки совместимости.

Это deliberate fail-closed behavior.

## Runtime readiness

Exit code старых BusyBox/init scripts не всегда отражает реальное состояние сервиса.

Поэтому после restart Moonraker deployment использует реальный API gate:

```
GET http://127.0.0.1:7125/server/info
```

с timeout 45 секунд.

## BusyBox compatibility

Stock Creality userspace содержит BusyBox utilities, которые могут отличаться от GNU coreutils.

Например, используемый на K1 Max `grep` поддерживает `-r`, но не `-R`.

Healthcheck поэтому избегает предположений о GNU-specific options и проверяет Helper Script functions в конкретных canonical files.

## Идемпотентность

Для каждого baseline-компонента deployment сначала проверяет ожидаемый installation artifact.

Если компонент уже присутствует, установка не повторяется.

После каждого запуска состояние всё равно подтверждается FULL healthcheck.

## External monitoring boundary

Проект экспортирует локальный operational state через:

```
/usr/data/scripts/p3d-k1/status
/usr/data/scripts/p3d-k1/healthcheck.log
```

Внешние системы могут читать эти данные, но не являются частью данного публичного проекта.

Таким образом deployment/health logic остаётся автономным и не связан с конкретным fleet manager, dashboard или Home Assistant installation.
