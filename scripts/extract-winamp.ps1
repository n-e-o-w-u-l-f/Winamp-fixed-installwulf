param(
    [Parameter(Mandatory = $true)][string]$SourceInstaller,
    [Parameter(Mandatory = $true)][string]$PayloadDirectory,
    [string]$ConfigFile = (Join-Path $PSScriptRoot '..\config\build-config.json')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $SourceInstaller -PathType Leaf)) {
    throw "Source installer not found: $SourceInstaller"
}
if (-not (Test-Path -LiteralPath $ConfigFile -PathType Leaf)) {
    throw "Build configuration not found: $ConfigFile"
}

$config = Get-Content -LiteralPath $ConfigFile -Raw | ConvertFrom-Json
$source = Get-Item -LiteralPath $SourceInstaller
$buildDirectory = Join-Path (Split-Path -Parent $PSScriptRoot) 'build'

Write-Host "Source installer: $($source.FullName)"
Write-Host "Source size: $($source.Length) bytes"
if ([int64]$source.Length -ne [int64]$config.source.sizeBytes) {
    throw "Source size mismatch. Expected $($config.source.sizeBytes), got $($source.Length)."
}

$sourceHash = (Get-FileHash -LiteralPath $SourceInstaller -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Host "Source SHA256: $sourceHash"
New-Item -ItemType Directory -Path $buildDirectory -Force | Out-Null
$sourceHashPath = Join-Path $buildDirectory 'source-sha256.txt'
"$sourceHash  $($source.Name)" | Set-Content -LiteralPath $sourceHashPath -Encoding ascii
if ($config.source.expectedSha256) {
    if ($sourceHash -ne $config.source.expectedSha256.ToLowerInvariant()) {
        throw "Source SHA256 mismatch. Expected $($config.source.expectedSha256), got $sourceHash."
    }
    Write-Host 'Source SHA256 validation: PASS'
} else {
    Write-Warning 'No expected source SHA256 is pinned in config/build-config.json; build is not release-reproducible until it is recorded.'
}
Write-Host "Source Git blob SHA-1: $($config.source.gitBlobSha1)"

$sevenZip = Get-Command 7z.exe -ErrorAction SilentlyContinue
if ($sevenZip) { $sevenZipPath = $sevenZip.Source }
if (-not $sevenZipPath -and (Test-Path 'C:\Program Files\7-Zip\7z.exe')) { $sevenZipPath = 'C:\Program Files\7-Zip\7z.exe' }
if (-not $sevenZipPath -and (Test-Path 'C:\Program Files (x86)\7-Zip\7z.exe')) { $sevenZipPath = 'C:\Program Files (x86)\7-Zip\7z.exe' }
if (-not $sevenZipPath) { throw '7z.exe is required on the build runner.' }

$sevenZipInfo = & $sevenZipPath i 2>&1 | Select-String -Pattern '^7-Zip ' | Select-Object -First 1
if (-not $sevenZipInfo) { throw 'Unable to determine 7-Zip version.' }
Write-Host "7-Zip: $($sevenZipInfo.Line.Trim())"

& $sevenZipPath t $SourceInstaller -y | Out-Host
if ($LASTEXITCODE -ne 0) { throw "Source installer archive test failed: $LASTEXITCODE" }
Write-Host 'Source archive validation: PASS'

Remove-Item -LiteralPath $PayloadDirectory -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $PayloadDirectory -Force | Out-Null

& $sevenZipPath x $SourceInstaller "-o$PayloadDirectory" -y | Out-Host
if ($LASTEXITCODE -ne 0) { throw "7-Zip extraction failed with exit code $LASTEXITCODE" }

foreach ($requiredFile in $config.payload.requiredFiles) {
    $requiredPath = Join-Path $PayloadDirectory ($requiredFile -replace '/', '\\')
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required payload file was not found: $requiredFile"
    }
}

$winamp = Join-Path $PayloadDirectory 'winamp.exe'
$info = [Diagnostics.FileVersionInfo]::GetVersionInfo($winamp)
Write-Host "Payload Winamp FileVersion: $($info.FileVersion)"
Write-Host "Payload Winamp ProductVersion: $($info.ProductVersion)"
Write-Host "Payload Winamp ProductName: $($info.ProductName)"
Write-Host "Payload winamp.exe SHA256: $((Get-FileHash -LiteralPath $winamp -Algorithm SHA256).Hash)"

$signature = Get-AuthenticodeSignature -LiteralPath $winamp
Write-Host "Payload winamp.exe Authenticode: $($signature.Status)"
if ($signature.SignerCertificate) {
    Write-Host "Payload signer: $($signature.SignerCertificate.Subject)"
    Write-Host "Payload signer thumbprint: $($signature.SignerCertificate.Thumbprint)"
}

& (Join-Path $PSScriptRoot 'new-payload-manifest.ps1') -PayloadDirectory $PayloadDirectory -OutputFile (Join-Path $buildDirectory 'payload-manifest.json')
