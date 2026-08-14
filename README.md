# Winamp Install-Wulf

**A security-conscious Windows installer build pipeline for a supplied Winamp payload, using NSIS 3.12 and GitHub Actions.**

> Project: **Winamp-fixed-installwulf**  
> Installer family: **Install-Wulf**  
> Installer version: **1.33.7.0**  
> Installer display version: **1,33,7a**

## Scope and security model

This repository contains installer/build logic, validation, documentation and CI automation. The Winamp executable and other Winamp payload files are treated as third-party payload and are not represented as repository-owned open-source code.

The build never disables UAC, Defender, SmartScreen, WDAC or AppLocker, and it does not create security exclusions. It does not bypass Winamp licensing or activation and does not replace original vendor signatures.

A Windows security or reputation warning is treated as a validation/execution issue, not as something the installer should suppress.

## Build pipeline

The CI pipeline is deliberately staged:

```text
1. Source validation
2. Toolchain setup
3. Payload extraction
4. Payload validation
5. Installer build
6. Installer validation
7. SHA-256
8. Artifact upload
```

A failed stage stops the job. Artifact upload occurs only after all previous stages succeed. A CI artifact is **not automatically a release**.

## Central build configuration

`config/build-config.json` is the authoritative source for:

- Install-Wulf file version: `1.33.7.0`
- Install-Wulf display version: `1,33,7a`
- source path and current Git blob SHA-1
- source size
- required payload files
- NSIS version and SHA-256
- 7-Zip version and SHA-256

The NSIS and 7-Zip installer downloads are fetched by exact version and verified against pinned SHA-256 values before installation. GitHub Actions themselves are referenced by immutable commit SHA.

### Current source identity

The checked-in source installer is:

```text
winamp/winamp_latest_installer.exe
Git blob SHA-1: 6c3aa2dbf463daae1496cfb1cc40d2c9447153ed
Size: 13,034,408 bytes
```

CI calculates the source SHA-256 on every build and publishes it as `source-sha256.txt`. The current repository does **not** yet contain an expected source SHA-256 value. Therefore the project does not claim full source reproducibility yet. Before a release can be promoted, the calculated SHA-256 must be recorded in `config/build-config.json` as `source.expectedSha256`.

## Toolchain

| Tool | Version | SHA-256 |
|---|---|---|
| NSIS | 3.12 | `3bc2b06253a7e4957111be152ac6a536e0c7478a706e19da814038db5d706495` |
| 7-Zip | 26.02 | `6745fa76dc2ea031596d8678f6f6b99c3c1b435b4164a63485adbbc7b8d82ef0` |

The NSIS 3.12 package is obtained from the NSIS SourceForge distribution. The 7-Zip 26.02 executable is obtained from the official `ip7z/7zip` GitHub release.

## Payload inventory

After extraction, `scripts/new-payload-manifest.ps1` creates `build/payload-manifest.json` containing, in deterministic path order:

- relative path
- file size
- SHA-256
- file version, where available
- product version, where available

The build currently requires `winamp.exe`. If a complete expected payload manifest is added later, it can be used to reject unexpected files as well.

## Installer validation

`scripts/verify-installer.ps1` checks:

- installer exists and has a plausible size;
- MZ and PE headers are valid;
- ProductName is `Install-Wulf`;
- FileVersion and ProductVersion match the central configuration;
- required payload files and payload manifest exist;
- the generated installer passes a 7-Zip structural test;
- SHA-256 is calculated;
- Authenticode status is reported separately, without modifying signatures;
- build metadata is written to `BUILD-METADATA.json`.

The payload's own Authenticode status and signer information are also reported when Windows exposes them. No signature is fabricated, removed or replaced.

## Local build

On Windows, install the pinned tool versions and run:

```powershell
.\scripts\build-installer.ps1
```

The script reads `config/build-config.json`, extracts the payload, generates the payload manifest, generates the NSIS version include and builds the installer.

The authoritative output is:

```text
build/output/Winamp_InstallWulf-fixed.exe
```

For a full local validation, run:

```powershell
.\scripts\verify-installer.ps1 `
  -Installer .\build\output\Winamp_InstallWulf-fixed.exe `
  -ConfigFile .\config\build-config.json `
  -PayloadDirectory .\build\payload
```

## Cross-platform static tests

The repository contains tests that do not require Windows or a completed installer build:

```text
python -m unittest discover -s tests -p "test_*.py" -v
```

These tests validate the central configuration, source identity, pinned tool hashes, required payload files, workflow staging/pinning and the absence of a falsely claimed repository `LICENSE` file.

## Documentation

The GitHub Pages site is intentionally self-contained. Bootstrap and jQuery CDN dependencies have been removed; the documentation uses only repository-local CSS and JavaScript plus normal navigation links to GitHub.

## Legal separation

The repository must be treated as several distinct categories:

1. **Repository code** — PowerShell, NSIS and test/build logic.
2. **Documentation** — README, CI documentation and GitHub Pages content.
3. **Winamp payload** — third-party binaries supplied as build input.
4. **Winamp trademarks/copyrights** — third-party intellectual property.
5. **Third-party build tools** — NSIS, 7-Zip and their respective licenses.

The repository currently has **no `LICENSE` file**. Documentation therefore does not claim that repository contents are licensed under a particular open-source license. If a project license is chosen later, add the actual license file and update the documentation accordingly.

Redistribution of the Winamp payload is a separate legal question from the license of the build scripts. Before publishing a source installer or release, confirm that redistribution is permitted.

## Release policy

A successful CI artifact is not automatically a release. A release should only be promoted after:

1. the complete Windows build passes;
2. the source SHA-256 is pinned in `config/build-config.json`;
3. the payload and installer metadata have been inspected;
4. the artifact checksum has been recorded;
5. the applicable Winamp redistribution rights have been confirmed.

## Security principles

- use normal Windows UAC elevation;
- never disable Defender or UAC as part of installation;
- never silently add Defender exclusions;
- do not bypass licensing or activation controls;
- verify build-tool downloads cryptographically;
- validate source and payload before packaging;
- keep build parameters in source control;
- avoid unpinned build-tool/CDN dependencies;
- fail CI rather than publishing a partial or unvalidated installer.
