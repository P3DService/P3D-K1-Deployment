**English** | [Русский](CONTRIBUTING_RU.md)

# Contributing

Thanks for your interest in P3D K1 Deployment.

This project changes real printer runtime state, so the primary rule is: **reproducibility and safety first, convenience second**.

## Contributions welcome

- bug reports;
- compatibility reports for other firmware/hardware revisions;
- BusyBox compatibility fixes;
- healthcheck improvements;
- documentation;
- additional diagnostic checks;
- bootstrap/install improvements;
- carefully scoped compatibility fixes.

## Discuss first

Please open an issue before proposing:

- automatic installation of every Helper Script module;
- changes to the fan-control baseline;
- removal of fail-closed gates;
- destructive automatic fixes without backup;
- coupling this public project to a specific private fleet-management system;
- support for other printer families without a separate profile and validation.

## Before a Pull Request

1. Open an issue if runtime behavior changes.
2. Include printer model and firmware.
3. State the scenario: FRESH / RECONCILE / update / healthcheck-only.
4. Run:
   ```bash
   /usr/data/scripts/p3d-k1/healthcheck.sh --full
   ```
5. Include:
   ```
   PASS: N
   WARN: N
   FAIL: N
   STATUS: ...
   ```
6. If deployment logic changes, repeat `deploy.sh` and confirm idempotency.

## Shell requirements

Target environment is stock Creality userspace with BusyBox.

- use `#!/bin/sh`, not Bash;
- no Bash arrays;
- do not assume systemd;
- avoid GNU-only options;
- check external tools with `command -v`;
- destructive operations need backup/guards;
- validate readiness through real API/service state when possible.

## Helper Script

Creality Helper Script is an external upstream.

This project does not vendor its installer logic. It pins a tested commit and uses internal installer functions only after a compatibility gate.

## Pull Requests

A PR should include:

- what changed;
- why;
- affected models;
- firmware;
- test scenario;
- FULL healthcheck result;
- risks/rollback;
- CHANGELOG update when user-visible behavior changes.

## Security

Do not publish passwords, private SSH keys, tokens, private URLs, or data from private systems.

## License

By contributing, you agree that your contribution is licensed under the project's MIT license.
