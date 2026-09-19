[English](CONTRIBUTING.md) | **Русский**

# Участие в проекте

Спасибо за интерес к P3D K1 Deployment.

Проект предназначен для воспроизводимого развёртывания и проверки rooted-принтеров Creality K1-series. Изменения в deployment-логике потенциально затрагивают рабочие принтеры, поэтому основной принцип проекта — **сначала воспроизводимость и безопасность, потом удобство**.

## Что приветствуется

- bug reports;
- подтверждение работы на других firmware/hardware revisions;
- BusyBox compatibility fixes;
- улучшения healthcheck;
- документация;
- дополнительные diagnostic checks;
- улучшения bootstrap/install flow;
- аккуратные compatibility fixes.

## Что требует предварительного обсуждения

- автоматическое включение всех модулей Helper Script;
- изменение fan-control baseline;
- удаление fail-closed gates;
- destructive fixes без backup;
- привязка публичного проекта к конкретной приватной fleet-management системе;
- поддержка других семейств принтеров без отдельного профиля и валидации.

## Перед Pull Request

1. Откройте issue, если изменение влияет на runtime.
2. Укажите модель и firmware.
3. Укажите сценарий: FRESH / RECONCILE / update / healthcheck-only.
4. Выполните:
   ```bash
   /usr/data/scripts/p3d-k1/healthcheck.sh --full
   ```
5. Приложите:
   ```
   PASS: N
   WARN: N
   FAIL: N
   STATUS: ...
   ```
6. Если меняется deployment — повторите `deploy.sh` и подтвердите идемпотентность.

## Требования к shell

Target environment — stock Creality userspace + BusyBox.

- `#!/bin/sh`, не Bash;
- без Bash arrays;
- без предположения о systemd;
- избегать GNU-only опций;
- внешние утилиты проверять через `command -v`;
- destructive operation должна иметь backup/guard;
- runtime readiness проверять фактическим API/service state.

## Helper Script

Creality Helper Script — внешний upstream.

Проект не форкает его installer logic, фиксирует протестированный commit и использует internal functions только после compatibility gate.

## Pull Request

PR должен содержать:

- что изменено;
- зачем;
- затронутые модели;
- firmware;
- сценарий тестирования;
- FULL healthcheck;
- риски/rollback;
- CHANGELOG, если меняется поведение пользователя.

## Безопасность

Не публикуйте пароли, SSH keys, токены, приватные URL и данные приватных систем.

## Лицензия

Отправляя вклад, вы соглашаетесь с лицензией MIT проекта.
