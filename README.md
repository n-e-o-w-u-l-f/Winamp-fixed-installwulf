# Winamp Install-Wulf

**A reproducible Windows installer pipeline for Winamp using NSIS and GitHub Actions.**

> Project name: **Winamp-fixed-installwulf**  
> Installer family: **Install-Wulf**  
> Current installer line: **v1,33,7a**

## Overview

Winamp Install-Wulf is a build and packaging project for creating a consistent Windows installer from a supplied `winamp_latest_installer.exe` source installer.

The project separates the original Winamp payload from the installer technology used to deploy it. The repository contains the build instructions, validation scripts, documentation, and GitHub Actions automation required to reproduce the Install-Wulf package.

The project does **not** disable Windows security controls and does not attempt to bypass Winamp licensing or activation. If Windows reports a signing, reputation, SmartScreen, Defender, WDAC, or AppLocker issue for an original Winamp binary, that issue is documented and investigated separately from the installer packaging process.

## What this project does

1. Accepts a designated Winamp source installer named `winamp_latest_installer.exe`.
2. Extracts the source payload using a pinned/known extraction tool.
3. Validates that the expected Winamp executable and payload files exist.
4. Builds a native NSIS installer with administrator elevation requested through the normal Windows UAC mechanism.
5. Creates an uninstall entry and an uninstaller.
6. Runs structural and payload validation before publishing an artifact.
7. Publishes the resulting `Winamp_InstallWulf-fixed.exe` as a GitHub Actions artifact and, when configured, as a release asset.

## Reproducible update model

When a newer Winamp installer becomes available, replace:

```text
winamp/winamp_latest_installer.exe
```

with the new source file and commit it. GitHub Actions then performs the build from the repository instructions instead of relying on a manually modified installer binary.

The intended flow is:

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
 hash + structural tests
          |
          v
 GitHub Actions artifact/release
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

The source installer may be kept in a private/release-controlled branch or replaced by a permitted distribution mechanism if redistribution rights require that approach. Do not commit proprietary material unless you have the right to distribute it.

## Requirements

### Local development

- Windows 10/11
- PowerShell 7 or Windows PowerShell
- NSIS **3.12**
- 7-Zip or another approved extraction tool used by the build scripts
- A valid `winamp_latest_installer.exe`

### GitHub Actions

The workflow installs or invokes the exact tool versions declared by the workflow. The build must not depend on software installed only on a developer's machine.

## Building locally

From an elevated PowerShell when testing the real installation path:

```powershell
& 'C:\Program Files (x86)\NSIS\makensis.exe' .\installer\Install-Wulf.nsi
```

The build should produce:

```text
Winamp_InstallWulf-fixed.exe
```

Never use a locally produced EXE as the authoritative source for another build. The NSIS script and source payload are the build inputs.

## Installation

1. Download the Install-Wulf installer from the project's Releases or Actions artifact.
2. Verify its SHA-256 hash if a release hash is provided.
3. Start the installer normally.
4. Accept the Windows UAC prompt when Windows requests administrator permission.
5. Review the installation destination.
6. Complete installation.
7. Start Winamp from its installed executable or shortcut.

The installer requests elevation through the standard Windows mechanism. It does not instruct Windows to disable UAC, Defender, SmartScreen, WDAC, or AppLocker.

## Troubleshooting

### Windows blocks Winamp.exe

An installer cannot safely assume that every Windows security decision is a UAC decision. Possible causes include:

- Authenticode signature validation
- certificate chain or revocation status
- SmartScreen reputation
- Microsoft Defender detections
- AppLocker policy
- Windows Defender Application Control / Code Integrity policy
- Mark-of-the-Web
- enterprise security software

Collect the exact Windows event/error first. Do not disable security controls merely to make an installer test pass.

### Installer installs but Winamp does not start

Check:

1. `C:\Program Files (x86)\Winamp\winamp.exe` exists.
2. The installed executable's file version.
3. Windows Event Viewer for the exact block event.
4. Microsoft Defender protection history.
5. Code Integrity/AppLocker logs where applicable.
6. Whether the original Winamp executable also fails outside Install-Wulf.

This distinction determines whether the problem belongs to the installer or to execution policy/security validation.

## Code signing

Install-Wulf can be signed as an independently distributed installer using an appropriate code-signing certificate. A self-signed certificate is useful for controlled testing but does not automatically establish public Windows trust.

Signing the Install-Wulf installer is different from replacing the Authenticode signature of an original Winamp executable. The project does not overwrite or falsify original vendor signatures.

## Licensing and distribution

Winamp and its components may be subject to licenses, trademarks, copyrights, and distribution restrictions. This repository's installer scripts are not a grant of rights to redistribute Winamp.

Before committing or publishing `winamp_latest_installer.exe`, confirm that the source file may legally be redistributed through the chosen GitHub repository and release mechanism.

## Security principles

Install-Wulf follows these principles:

- use normal Windows UAC elevation;
- never disable Defender or UAC as part of installation;
- never silently add Defender exclusions;
- do not bypass licensing/activation controls;
- validate build inputs before packaging;
- publish hashes for release artifacts where practical;
- keep build logic in source-controlled scripts;
- avoid hidden network downloads during the build;
- make CI failures visible instead of silently producing a partial installer.

## GitHub Actions

The CI pipeline is designed to make the build repeatable. A successful workflow should expose the generated installer as an artifact and record its SHA-256 hash. A release workflow may additionally attach the installer and checksum to a GitHub Release.

For source updates, the recommended procedure is:

```text
1. Replace winamp/winamp_latest_installer.exe
2. Commit the change
3. Push to main
4. GitHub Actions builds the installer
5. Validation runs
6. Inspect the artifact
7. Publish a release when appropriate
```

## Project status

The project is actively being developed around the Install-Wulf packaging pipeline. The installer build and validation logic should be treated as the authoritative implementation; manually generated installers are development artifacts only.

## License

The repository's installer/build scripts are intended to be licensed independently from the Winamp software payload. See `LICENSE` for the repository license and the Winamp documentation/source package for applicable third-party terms.
