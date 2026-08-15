param(
    [Parameter(Mandatory = $true)][string]$PayloadDirectory,
    [Parameter(Mandatory = $true)][string]$OutputFile
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $PayloadDirectory -PathType Container)) {
    throw "Payload directory not found: $PayloadDirectory"
}

$root = (Resolve-Path -LiteralPath $PayloadDirectory).Path
$files = Get-ChildItem -LiteralPath $root -Recurse -File | Sort-Object { $_.FullName.Substring($root.Length).TrimStart('\\') }

$entries = foreach ($file in $files) {
    $relativePath = $file.FullName.Substring($root.Length).TrimStart('\\').Replace('\\', '/')
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    $fileVersion = $null
    $productVersion = $null

    try {
        $info = [Diagnostics.FileVersionInfo]::GetVersionInfo($file.FullName)
        if ($info.FileVersion) { $fileVersion = $info.FileVersion }
        if ($info.ProductVersion) { $productVersion = $info.ProductVersion }
    } catch {
        # Non-versioned files are valid payload members.
    }

    [pscustomobject]@{
        path = $relativePath
        sizeBytes = [int64]$file.Length
        sha256 = $hash
        fileVersion = $fileVersion
        productVersion = $productVersion
    }
}

$manifest = [ordered]@{
    schemaVersion = 1
    generatedBy = 'scripts/new-payload-manifest.ps1'
    fileCount = @($entries).Count
    files = @($entries)
}

$outputDirectory = Split-Path -Parent $OutputFile
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $OutputFile -Encoding utf8

Write-Host "Payload manifest: $OutputFile"
Write-Host "Payload files: $(@($entries).Count)"
