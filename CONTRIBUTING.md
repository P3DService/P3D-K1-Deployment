# Contributing

Спасибо за интерес к P3D K1 Deployment.

Проект предназначен для воспроизводимого развёртывания и проверки rooted-принтеров Creality K1-series. Изменения в deployment-логике потенциально затрагивают рабочие принтеры, поэтому основной принцип проекта — **сначала воспроизводимость и безопасность, потом удобство**.

## Что можно присылать

Приветствуются:

- bug reports;
- подтверждение работы на других K1-series firmware/hardware revisions;
- исправления BusyBox-совместимости;
- улучшения healthcheck;
- документация;
- дополнительные диагностические проверки;
- улучшения bootstrap/install flow;
- аккуратные compatibility fixes.

## Что не стоит добавлять без отдельного обсуждения

- автоматическое включение всех модулей Creality Helper Script;
- изменения fan-control baseline;
- удаление fail-closed gates;
- автоматические destructive fixes без backup;
- привязку публичного проекта к конкретной приватной fleet-management системе;
- поддержку других семейств принтеров без отдельного профиля/валидации.

## Перед Pull Request

1. Откройте issue и опишите проблему/цель, если изменение влияет на runtime.
2. Укажите модель принтера и версию firmware.
3. Укажите, был ли сценарий:
   - FRESH;
   - RECONCILE;
   - update;
   - healthcheck-only.
4. Выполните:
   ```bash
   /usr/data/scripts/p3d-k1/healthcheck.sh --full
   ```
5. Приложите итог:
   ```
   PASS: N
   WARN: N
   FAIL: N
   STATUS: ...
   ```
6. Если изменение касается deployment — повторите запуск `deploy.sh` и подтвердите идемпотентность.

## Требования к shell-скриптам

Target environment — stock Creality userspace с BusyBox.

Поэтому:

- `#!/bin/sh`, не Bash;
- избегайте GNU-only опций;
- не используйте Bash arrays;
- не рассчитывайте на `systemd`;
- не рассчитывайте на полноценный GNU `grep`, `sed`, `find`;
- внешняя утилита должна проверяться через `command -v`;
- destructive operation должна иметь backup/guard;
- runtime readiness лучше проверять фактом работы API/сервиса, а не только exit code init-script.

## Helper Script

Creality Helper Script рассматривается как внешний upstream.

Проект:

- не форкает его код;
- не копирует installer logic;
- фиксирует протестированный commit;
- использует internal functions только после compatibility gate.

Если upstream commit изменился, обновление baseline должно сопровождаться повторной field validation.

## Pull Request

PR должен содержать:

- краткое описание;
- причину изменения;
- затронутые модели;
- сценарий тестирования;
- результат FULL healthcheck;
- риски/rollback;
- изменение CHANGELOG, если поведение пользователя изменилось.

## Безопасность

Не публикуйте:

- пароли;
- приватные SSH keys;
- IP/hostname, если не хотите раскрывать инфраструктуру;
- токены;
- приватные URL;
- данные сторонних приватных систем.

## Лицензия

Отправляя вклад, вы соглашаетесь, что ваш вклад распространяется по лицензии MIT данного проекта.
