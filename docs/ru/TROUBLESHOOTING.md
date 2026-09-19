[English](../en/TROUBLESHOOTING.md) | **Русский**

# Troubleshooting

## SSH: REMOTE HOST IDENTIFICATION HAS CHANGED

После factory reset host key принтера может измениться.

На компьютере:

```bash
ssh-keygen -R PRINTER_IP
ssh root@PRINTER_IP
```

Перед подтверждением нового fingerprint убедитесь, что IP действительно принадлежит нужному принтеру.

## scp: /usr/libexec/sftp-server: not found

На чистой прошивке K1-series может отсутствовать SFTP server.

Используйте:

```bash
scp -O deploy.sh healthcheck.sh \
  root@PRINTER_IP:/usr/data/scripts/p3d-k1/
```

Ключ `-O` заставляет современный OpenSSH использовать legacy SCP protocol.

## Helper Script revision differs

Пример:

```
Helper Script revision is ..., but P3D baseline is tested only with ...
```

Это safety gate.

Не обходите его вручную. Upstream Helper Script мог изменить функции, пути или side effects.

Нужна новая совместимость/валидация baseline.

## Fans Control Macros detected

Deployment намеренно останавливается, если найден:

```
/usr/data/printer_data/config/Helper-Script/fans-control.cfg
```

Удалите компонент штатно через Creality Helper Script, затем повторите deployment.

## Moonraker API временно недоступен после restart

Deployment ждёт до 45 секунд.

Проверить вручную:

```bash
wget -q -T 3 -O /tmp/server_info.json \
  'http://127.0.0.1:7125/server/info' \
  && echo "MOONRAKER API OK" \
  || echo "MOONRAKER API FAIL"
```

## Timelapse: ffmpeg not found

Проверить:

```bash
which ffmpeg
ls -l /opt/bin/ffmpeg
/usr/bin/ffmpeg -version | head
```

На протестированной конфигурации stock `ffmpeg` находится в:

```
/usr/bin/ffmpeg
```

а Moonraker Timelapse ожидает:

```
/opt/bin/ffmpeg
```

Deployment автоматически создаёт symlink, если это необходимо.

## Камера работает в Creality App, но не во Fluidd

Проверка snapshot:

```bash
wget -O /tmp/test.jpg 'http://127.0.0.1:8080/?action=snapshot'
ls -lh /tmp/test.jpg
```

Проверка процесса:

```bash
ps | grep '[m]jpg_streamer'
netstat -lnt | grep 8080
```

Если snapshot недоступен, deployment создаёт `/etc/init.d/S99mjpg_camera` при наличии stock `mjpg_streamer`.

## Moonraker сообщает untracked timelapse.py

Moonraker Timelapse добавляет сторонний component в source tree Moonraker.

Допустимый baseline-файл:

```
moonraker/components/timelapse.py
```

Healthcheck разрешает его как ожидаемый untracked file.

## Проверить текущее состояние

```bash
/usr/data/scripts/p3d-k1/healthcheck.sh --full
```

Коротко:

```bash
cat /usr/data/scripts/p3d-k1/status
```

Логи:

```bash
tail -100 /usr/data/scripts/p3d-k1/healthcheck.log
tail -100 /usr/data/scripts/p3d-k1/deploy.log
```


## wget: TLS certificate validation not implemented

На некоторых stock-прошивках K1-series BusyBox `wget` выводит:

```
wget: note: TLS certificate validation not implemented
```

Это ограничение встроенного BusyBox `wget`: он может устанавливать HTTPS-соединение, но не выполняет полноценную проверку TLS-сертификата.

Во время field validation загрузка с `raw.githubusercontent.com` при этом отрабатывала успешно и bootstrap завершался с PASS.

Важно понимать trade-off:

- сообщение не означает, что загрузка уже сломалась;
- но transport trust слабее, чем у полноценного `curl`/OpenSSL-клиента с проверкой CA;
- для воспроизводимости bootstrap закреплён на конкретный release/tag;
- перед первым запуском рекомендуется скачать `install.sh`, просмотреть его и только затем выполнять.

Рекомендуемый вариант:

```bash
wget -q -O /tmp/p3d-k1-install.sh \
  https://raw.githubusercontent.com/P3DService/P3D-K1-Deployment/v0.5.1/install.sh

cat /tmp/p3d-k1-install.sh
sh /tmp/p3d-k1-install.sh
```

Если в вашей среде доступен клиент с полноценной TLS-валидацией, предпочтительно использовать его для загрузки bootstrap.
