[English](../en/K1_MAX_CF0502.md) | [Русский](K1_MAX_CF0502.md)

# K1 Max: CF0502 / ошибка вентилятора материнской платы

## Симптом

Этот кейс подходит, если rooted **Creality K1 Max** показывает одну из ошибок:

- `CF0502`
- `Mainboard fan exception`
- `Motherboard fan running abnormal`
- ошибка вентилятора материнской платы

Ошибка может появляться после печати, в простое или после остывания принтера.

## Причина

В подтверждённом P3D-кейсе вентилятор материнской платы K1 Max на `PB2` управлялся отдельным Klipper-блоком `[controller_fan board_fan]`.

После `idle_timeout` этот controller полностью останавливал вентилятор. При этом штатный Creality `master-server` продолжал контролировать тахометр и после устойчивых 0 RPM выставлял fault code `502`.

Сам вентилятор, выход `PB2` и тахосигнал `PC6` были исправны.

## Рекомендуемое решение

Установить или выполнить reconcile через **P3D K1 Deployment v0.6.1 или новее**.

После получения root:

```bash
ssh root@PRINTER_IP
```

Рекомендуемый pinned bootstrap:

```bash
wget -q -O /tmp/p3d-k1-install.sh \
  https://raw.githubusercontent.com/P3DService/P3D-K1-Deployment/v0.6.1/install.sh

cat /tmp/p3d-k1-install.sh
sh /tmp/p3d-k1-install.sh
```

Deployment сам определяет K1 Max и применяет проверенный board-fan baseline.

## Как должен работать вентилятор после исправления

- в простое: минимум 50%
- при температуре MCU >= 48 C: 100%
- при охлаждении MCU <= 42 C: возврат на 50%
- 42-48 C: зона гистерезиса
- штатного режима 0 RPM больше нет

Это сохраняет охлаждение платы во время холодных калибровок и работы моторов, но уменьшает шум и износ по сравнению с постоянными 100%.

## Проверка

В Fluidd Console:

```gcode
QUERY_FAN_CHECK
```

Нас интересует:

```text
fan1_speed
```

Ожидается:

- в простое: больше 0 RPM; в field validation было примерно 3200 RPM
- во время печати / при нагретом MCU: выше; в field validation было примерно 4000 RPM

Если `fan1_speed` остаётся `0`, когда вентилятор должен работать, не маскируйте CF0502 — нужно проверять сам вентилятор, проводку или тахосигнал.

## Healthcheck

```bash
/usr/data/scripts/p3d-k1/healthcheck.sh --full
```

Для K1 Max healthcheck проверяет:

- наличие P3D baseline для CF0502;
- отсутствие старого `[controller_fan board_fan]`;
- отсутствие `PB2` внутри `heater_fans`.

## Field validation

Проверено на K1 Max 2026-09-21:

- PB2 output/control: PASS
- PC6 tach feedback: PASS
- idle: примерно 3200 RPM
- печать: примерно 4000 RPM
- печать завершена успешно
- после 15+ минут простоя CF0502 не повторилась

## См. также

- [Troubleshooting](TROUBLESHOOTING.md)
- [TMC2209: перегрев во время холодной калибровки](TMC2209_OVERHEAT.md)
