[English](../en/RELEASE_v0.6.1.md) | [Русский](RELEASE_v0.6.1.md)

# Release v0.6.1

Patch release с исправлением **ложной CF0502 на Creality K1 Max** и нормальным пользовательским путём поиска решения.

## Исправлено

- K1 Max: устранена `CF0502` / `motherboard fan running abnormal`, которую вызывал прежний P3D `[controller_fan board_fan]` после перехода вентилятора в 0 RPM по idle timeout.
- Для вентилятора платы K1 Max применяется field-validated PWM baseline:
  - 50% в простое
  - 100% при MCU >= 48 C
  - возврат на 50% при MCU <= 42 C
  - штатного 0 RPM нет
- Stock/legacy fan mapping K1 Max мигрируется fail-closed.
- Перед изменением сохраняется backup `printer.cfg`.
- Healthcheck проверяет новый K1 Max board-fan baseline.

## Пользовательский кейс

Добавлена отдельная страница, которую можно найти по запросам:

- `CF0502`
- `Mainboard fan exception`
- `Motherboard fan running abnormal`
- ошибка вентилятора материнской платы

См. [K1 Max: CF0502 / ошибка вентилятора материнской платы](K1_MAX_CF0502.md).

## Field validation

- idle tach: примерно 3200 RPM
- печать: примерно 4000 RPM
- печать завершена успешно
- после 15+ минут простоя CF0502 не повторилась

## Установка

```bash
wget -q -O /tmp/p3d-k1-install.sh \
  https://raw.githubusercontent.com/P3DService/P3D-K1-Deployment/v0.6.1/install.sh

cat /tmp/p3d-k1-install.sh
sh /tmp/p3d-k1-install.sh
```

One-liner:

```bash
wget -qO- https://raw.githubusercontent.com/P3DService/P3D-K1-Deployment/v0.6.1/install.sh | sh
```
