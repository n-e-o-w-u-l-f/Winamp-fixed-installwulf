# Winamp Install-Wulf

**A reproducible Windows installer pipeline for Winamp using NSIS 3.12 and GitHub Actions.**

> Project: **Winamp-fixed-installwulf**  
> Installer family: **Install-Wulf**  
> Current installer line: **v1,33,7a**

## Overview

Winamp Install-Wulf builds a consistent Windows installer from a supplied `winamp_latest_installer.exe` source package. The installer technology is deliberately separated from the original Winamp payload: the repository contains the build instructions, validation scripts, documentation, and CI automation needed to regenerate the Install-Wulf package.

The project does **not** disable Windows security controls and does not attempt to bypass Winamp licensing or activation. If Windows reports a signing, reputation, SmartScreen, Defender, WDAC, or AppLocker issue for an original Winamp binary, that issue is investigated as an execution/security-policy problem rather than hidden by the installer.

## Reproducible update model

Replace:

```text
winamp/winamp_latest_installer.exe
```

with the new source installer, commit it, and push to `main`. The CI workflow rebuilds the installer from source-controlled instructions rather than using a previously generated EXE.

```text
winamp_latest_installer.exe
          |
          v
   source validation
          |
          v
      extraction
          |
          v
    payload checks
          |
          v
       NSIS 3.12
          |
          v
Winamp_InstallWulf-fixed.exe
          |
          v
 PE + structure + SHA-256
          |
          v
     CI artifact
```

## Repository layout

```text
.github/
  workflows/
    build-installer.yml
    pages.yml
installer/
  Install-Wulf.nsi
scripts/
  extract-winamp.ps1
  build-installer.ps1
  verify-installer.ps1
winamp/
  winamp_latest_installer.exe
web/
  index.html
  how-to-use.html
  assets/
    css/
    js/
README.md
LICENSE
.gitignore
```

## Requirements

### Local development

- Windows 10/11
- PowerShell 7 or Windows PowerShell
- **NSIS 3.12**
- 7-Zip
- a permitted `winamp_latest_installer.exe` source file

### GitHub Actions

CI installs the declared build tools on the runner. The build must not depend on software that happens to be installed on a developer's workstation.

## Local build

```powershell
& 'C:\Program Files (x86)\NSIS\makensis.exe' .\installer\Install-Wulf.nsi
```

The authoritative output is:

```text
Winamp_InstallWulf-fixed.exe
```

The build scripts validate the output before it is uploaded as a CI artifact.

## Installation

1. Download `Winamp_InstallWulf-fixed.exe` from a release or CI artifact.
2. Verify the published SHA-256 checksum when available.
3. Run the installer normally.
4. Accept the standard Windows UAC prompt if requested.
5. Review the installation directory.
6. Complete the installation.
7. Launch Winamp normally.

Install-Wulf uses the normal Windows elevation model. It does not disable UAC, Defender, SmartScreen, WDAC, or AppLocker and does not silently create security exclusions.

## Troubleshooting: Windows blocks Winamp

UAC is not synonymous with executable-signature validation. A Windows block can involve Authenticode, certificate-chain/revocation status, SmartScreen, Defender, AppLocker, WDAC/Code Integrity, Mark-of-the-Web, or third-party security software.

For a useful diagnosis, record the exact error and inspect the relevant Windows security/event logs. Compare the behavior of the original Winamp executable with the installed copy. Do not disable security controls merely to make a test pass.

## Code signing

Install-Wulf can be signed as an independently distributed installer with an appropriate code-signing certificate. A self-signed certificate is useful for controlled testing but does not establish public Windows trust.

Signing the Install-Wulf installer is distinct from replacing the Authenticode signature of an original Winamp executable. This project does not falsify or overwrite original vendor signatures.

## Licensing and distribution

Winamp and its components may be subject to licenses, trademarks, copyrights, and distribution restrictions. The installer scripts do not grant redistribution rights. Before committing or publishing `winamp_latest_installer.exe`, confirm that the source can legally be redistributed through this repository and its releases.

## Security principles

- use normal Windows UAC elevation;
- never disable Defender or UAC as part of installation;
- never silently add Defender exclusions;
- do not bypass licensing or activation controls;
- validate source and payload before packaging;
- publish SHA-256 hashes for release artifacts where practical;
- keep build logic in source control;
- avoid hidden downloads during the build where possible;
- fail CI rather than publishing a partial installer.

## GitHub Actions

The CI pipeline builds and validates the installer, then uploads the installer and checksum as an artifact. A release workflow can subsequently attach the validated files to a GitHub Release.

For updates:

```text
1. Replace winamp/winamp_latest_installer.exe
2. Commit the source update
3. Push to main
4. GitHub Actions builds Install-Wulf
5. Validation must pass
6. Inspect the artifact/checksum
7. Publish a release when appropriate
```

## Status

The repository is under active development. A generated installer is not considered a release until the complete CI validation succeeds.

## License

Repository build scripts and documentation should be licensed independently from the Winamp payload. See `LICENSE` and the applicable Winamp/third-party terms.
