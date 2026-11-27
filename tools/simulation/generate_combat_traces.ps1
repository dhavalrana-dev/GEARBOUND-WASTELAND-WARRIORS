# Compiles the Unity reference simulation with Unity's bundled Mono and writes
# shared/test-fixtures/combat_traces.json. Pass -Check to fail when the file is stale.
param(
    [switch]$Check,
    [string]$UnityEditor = "C:\Program Files\Unity\Hub\Editor\6000.3.27f1\Editor"
)
$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$monoBin = Join-Path $UnityEditor "Data\MonoBleedingEdge\bin"
$outDir = Join-Path $root "artifacts"
New-Item -ItemType Directory -Force $outDir | Out-Null
$exe = Join-Path $outDir "CombatTraceGenerator.exe"
$sources = @(Get-ChildItem (Join-Path $root "unity\Assets\Game\Core") -Filter *.cs | ForEach-Object { $_.FullName })
$sources += (Join-Path $PSScriptRoot "CombatTraceGenerator.cs")
& (Join-Path $monoBin "mcs.bat") -nologo -langversion:latest -out:$exe @sources
if ($LASTEXITCODE -ne 0) { throw "mcs failed with exit code $LASTEXITCODE" }
$runArgs = @($exe, (Join-Path $root "shared"))
if ($Check) { $runArgs += "--check" }
& (Join-Path $monoBin "mono.exe") @runArgs
exit $LASTEXITCODE
