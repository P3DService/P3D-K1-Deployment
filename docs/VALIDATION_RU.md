# Field Validation

## Версия

P3D K1 Deployment v0.5 / 0.5.0.

## Upstream baseline

Creality Helper Script:

```
b46787a61b3ce2f04ec04d115a73a46c26814057
```

## RECONCILE validation

Три уже настроенных Creality K1C были приведены к P3D managed baseline.

Финальный результат на каждом:

```
PASS: 54
WARN: 0
FAIL: 0
STATUS: PASS

P3D K1 DEPLOYMENT: PASS
```

Итого:

```
K1C ×3 — PASS
```

## FRESH validation

Creality K1 Max был сброшен до заводских настроек.

После получения root-доступа deployment с нуля:

- клонировал Helper Script;
- установил все approved components;
- настроил camera compatibility;
- отключил stock Creality Timelapse;
- включил Moonraker Timelapse;
- настроил ffmpeg path;
- настроил cleanup/cron;
- создал boot healthcheck.

Финальный FULL:

```
PASS: 54
WARN: 0
FAIL: 0
STATUS: PASS
```

## Idempotency validation

На том же K1 Max `deploy.sh` был запущен повторно.

Все компоненты были обнаружены как уже установленные.

После reconcile, Moonraker restart и API readiness:

```
PASS: 54
WARN: 0
FAIL: 0
STATUS: PASS

P3D K1 DEPLOYMENT: PASS
```

## Ошибки, обнаруженные до v0.5

Field validation помог обнаружить несколько проблем orchestration layer:

1. FULL запускался раньше готовности Moonraker API.
2. При прямом вызове Helper Script installer functions не загружался `menu/functions.sh`.
3. Ненулевой exit code Moonraker init-script преждевременно завершал deployment.
4. Stock BusyBox grep на K1 Max не поддерживал GNU `-R`, что давало ложные FAIL internal API checks.
5. Слишком общий поиск `Traceback` создавал ложный WARN.

Все эти случаи устранены к v0.5.

## Что означает validated

Validated означает, что указанные сценарии реально прошли на данном тестовом парке.

Это не гарантирует идентичное поведение:
- на другой версии firmware;
- на другой hardware revision;
- после изменения upstream Helper Script;
- при наличии сторонних модификаций.

Именно поэтому deployment содержит fail-closed gates и FULL validation.


## Public release bootstrap validation

Immutable bootstrap из public release `v0.5.1` был запущен на ранее настроенном Creality K1C через:

```bash
wget -qO- \
  https://raw.githubusercontent.com/P3DService/P3D-K1-Deployment/v0.5.1/install.sh | sh
```

Результат:

```
P3D K1 Deployment 0.5.1 installed
Moonraker API ready after 6s

PASS: 54
WARN: 0
FAIL: 0
STATUS: PASS

P3D K1 DEPLOYMENT: PASS
```

Подтверждено:

- release tag доступен через `raw.githubusercontent.com`;
- `install.sh` скачивает deployment files из того же `v0.5.1`;
- RECONCILE через публичный bootstrap идемпотентен на протестированном K1C;
- FULL gate проходит после bootstrap.

На stock BusyBox `wget` при тесте выводилось предупреждение `TLS certificate validation not implemented`. Оно задокументировано отдельно в troubleshooting.
