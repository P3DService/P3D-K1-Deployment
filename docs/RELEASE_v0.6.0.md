# P3D K1 Deployment v0.6.0

[English](https://github.com/P3DService/P3D-K1-Deployment/blob/v0.6.0/docs/en/RELEASE_v0.6.0.md) | [Русский](https://github.com/P3DService/P3D-K1-Deployment/blob/v0.6.0/docs/ru/RELEASE_v0.6.0.md)

---

## English

New stable baseline with automatic Fluidd provisioning.

Highlights:

- validated on Creality K1C ×3 and K1 Max ×1;
- Fluidd macro groups: PRINT / CALIBRATION / KAMP / TIMELAPSE;
- all non-baseline live Klipper macros hidden from the dashboard, not deleted;
- Moonraker webcam automatically created or normalized;
- existing webcam name/UID preserved during reconcile;
- relative `/webcam/` URLs remove IP dependency;
- Fluidd state backup before provisioning;
- FULL healthcheck now validates Fluidd webcam and macro provisioning;
- validated FULL result: `56 PASS / 0 WARN / 0 FAIL`.

Install:

```bash
wget -q -O /tmp/p3d-k1-install.sh \
  https://raw.githubusercontent.com/P3DService/P3D-K1-Deployment/v0.6.0/install.sh

cat /tmp/p3d-k1-install.sh
sh /tmp/p3d-k1-install.sh
```

Full English notes: [docs/en/RELEASE_v0.6.0.md](en/RELEASE_v0.6.0.md)

---

## Русский

Новый stable baseline с автоматическим Fluidd provisioning.

Главное:

- проверено на Creality K1C ×3 и K1 Max ×1;
- группы макросов Fluidd: PRINT / CALIBRATION / KAMP / TIMELAPSE;
- остальные live Klipper macros скрываются из dashboard, но не удаляются;
- Moonraker webcam создаётся или нормализуется автоматически;
- существующие имя/UID камеры сохраняются при reconcile;
- relative `/webcam/` URL убирают зависимость от IP;
- перед provisioning создаётся backup Fluidd state;
- FULL healthcheck проверяет webcam и macro provisioning;
- подтверждённый FULL: `56 PASS / 0 WARN / 0 FAIL`.

Установка:

```bash
wget -q -O /tmp/p3d-k1-install.sh \
  https://raw.githubusercontent.com/P3DService/P3D-K1-Deployment/v0.6.0/install.sh

cat /tmp/p3d-k1-install.sh
sh /tmp/p3d-k1-install.sh
```

Полные русские release notes: [docs/ru/RELEASE_v0.6.0.md](ru/RELEASE_v0.6.0.md)
