# Release v0.5.1

Bootstrap/release packaging update для первого immutable installation workflow.

Runtime deployment logic по сравнению с v0.5.0 не изменялась.

## Что изменено

- Добавлен публичный `install.sh`.
- Bootstrap по умолчанию закреплён на tag `v0.5.1`.
- README использует release-pinned installation URL.
- VERSION обновлён до `0.5.1`.
- Сохранён тот же проверенный runtime baseline.

## Проверенный runtime baseline

Creality Helper Script:

```
b46787a61b3ce2f04ec04d115a73a46c26814057
```

Field validation:

- RECONCILE: Creality K1C ×3 — PASS
- FRESH после factory reset: Creality K1 Max ×1 — PASS
- повторный deployment / idempotency: K1 Max ×1 — PASS
- FULL healthcheck: 54 PASS / 0 WARN / 0 FAIL

## Рекомендуемая установка

После получения root-доступа подключитесь к принтеру по SSH и выполните:

```bash
wget -q -O /tmp/p3d-k1-install.sh \
  https://raw.githubusercontent.com/P3DService/P3D-K1-Deployment/v0.5.1/install.sh

cat /tmp/p3d-k1-install.sh
sh /tmp/p3d-k1-install.sh
```

Быстрый one-liner:

```bash
wget -qO- https://raw.githubusercontent.com/P3DService/P3D-K1-Deployment/v0.5.1/install.sh | sh
```

`install.sh` сам скачивает `deploy.sh`, `healthcheck.sh` и `VERSION` из того же tag `v0.5.1`.

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

## Совместимость

Проверено на:

- Creality K1C
- Creality K1 Max

Требуется root-доступ.

Это независимый community project и не является официальным продуктом Creality или Guilouz.
