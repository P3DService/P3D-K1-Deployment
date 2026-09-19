[English](../en/INSTALLATION.md) | **Русский**

# Установка P3D K1 Deployment

## Перед началом

Поддерживаемый текущий baseline:

- Creality K1C
- Creality K1 Max

Требования:

- актуальная совместимая прошивка;
- включённый root-доступ;
- SSH-доступ к принтеру;
- интернет-доступ с принтера для загрузки upstream-компонентов;
- не менее ~250 МБ свободного места в `/usr/data`.

## Сценарий A: новый или сброшенный принтер

### 1. Получить root-доступ

После factory reset сначала выполните стандартную процедуру получения root-доступа для вашей прошивки.

### 2. Проверить SSH

На компьютере:

```bash
ssh root@PRINTER_IP
```

Если после сброса изменился SSH host key:

```bash
ssh-keygen -R PRINTER_IP
```

и подключитесь заново.

### 3. Подготовить каталог

```bash
ssh root@PRINTER_IP 'mkdir -p /usr/data/scripts/p3d-k1'
```

### 4. Скопировать скрипты

На macOS OpenSSH новых версий `scp` использует SFTP по умолчанию. На чистом K1/K1 Max SFTP server может отсутствовать:

```
sh: /usr/libexec/sftp-server: not found
```

В этом случае используйте legacy SCP:

```bash
scp -O deploy.sh healthcheck.sh \
  root@PRINTER_IP:/usr/data/scripts/p3d-k1/
```

### 5. Проверить модель и место

```bash
ssh root@PRINTER_IP
/usr/bin/get_sn_mac.sh model
df -h /usr/data
```

### 6. Запустить deployment

```bash
chmod +x /usr/data/scripts/p3d-k1/*.sh
/usr/data/scripts/p3d-k1/deploy.sh
```

Скрипт сам:

1. проверит модель;
2. проверит свободное место;
3. установит Creality Helper Script;
4. сверит его commit;
5. загрузит нужный internal API;
6. установит baseline-компоненты;
7. настроит камеру;
8. отключит stock Creality Timelapse;
9. проверит Moonraker Timelapse и ffmpeg;
10. поставит cleanup + cron;
11. создаст boot QUICK healthcheck;
12. перезапустит Moonraker;
13. дождётся API readiness;
14. запустит FULL healthcheck.

Успешный финал:

```
STATUS: PASS
P3D K1 DEPLOYMENT: PASS
```

## Сценарий B: уже настроенный принтер

Для существующего K1C/K1 Max используется тот же `deploy.sh`.

Скрипт обнаружит уже присутствующие компоненты:

```
[PASS] Moonraker + Nginx already present
[PASS] Fluidd already present
...
```

и применит только недостающие элементы baseline.

Перед первым reconcile можно вручную снять исходный FULL healthcheck:

```bash
/usr/data/scripts/p3d-k1/healthcheck.sh --full
```

После `deploy.sh` FULL запускается автоматически.

## После reboot

QUICK healthcheck выполняется автоматически приблизительно через 25 секунд после загрузки.

Текущий статус:

```bash
cat /usr/data/scripts/p3d-k1/status
```

Лог:

```bash
tail -100 /usr/data/scripts/p3d-k1/healthcheck.log
```

## Если deployment остановился

Не пытайтесь многократно подтверждать неизвестные ошибки вручную.

Сохраните:

```bash
cat /usr/data/scripts/p3d-k1/deploy.log
```

и выполните:

```bash
/usr/data/scripts/p3d-k1/healthcheck.sh --full
```

Дальше используйте [TROUBLESHOOTING_RU.md](TROUBLESHOOTING_RU.md).
