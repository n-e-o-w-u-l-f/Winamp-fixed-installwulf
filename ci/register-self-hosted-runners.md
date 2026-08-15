# Dedicated GitHub Actions runners

This repository intentionally uses **only self-hosted runners** for its workflows. GitHub-hosted runner labels such as `ubuntu-latest` and `windows-2025` are not used.

## Required runner labels

| Machine | OS | Labels | Purpose |
|---|---|---|---|
| `andreas-BMAX` | Windows x64 | `self-hosted`, `windows`, `x64`, `winamp-build` | Full Winamp installer build and validation |
| `legion` | Linux x64 | `self-hosted`, `linux`, `x64`, `legion` | Release promotion and GitHub Pages |

## Registration

Runner registration requires a short-lived GitHub Actions runner registration token. The token must be generated from the repository's **Settings → Actions → Runners → New self-hosted runner** page (or equivalent GitHub API endpoint) and must never be committed to this repository or written to a log.

The runner software must be downloaded from GitHub's official `actions/runner` releases and its release checksum/signature should be verified before installation.

After registration, verify that each runner appears online with the expected labels before starting a CI run.

## Security requirements

- Do not use a personal access token as a runner registration token when GitHub provides the short-lived registration token.
- Do not place the token in workflow YAML, repository files, shell history, or process arguments visible to other users.
- Run the runner under a dedicated account with only the permissions required for the build.
- Do not disable Defender, UAC, SmartScreen, WDAC, AppLocker, or other Windows security controls.
- Keep the Windows build runner dedicated to this repository while release builds are running.

The release gate remains closed until the Windows runner is registered and a complete successful build from `main` is observed.