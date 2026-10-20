param(
    [Parameter(Mandatory=$true)][string]$SdkPath,
    [Parameter(Mandatory=$true)][string]$DeveloperKey,
    [switch]$Tests
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$compiler = Join-Path $SdkPath 'bin\monkeyc.bat'
if (!(Test-Path -LiteralPath $compiler)) { throw "No se encuentra monkeyc.bat en $SdkPath" }
if (!(Test-Path -LiteralPath $DeveloperKey)) { throw 'No se encuentra la clave de desarrollador.' }
if (!(Get-Command java -ErrorAction SilentlyContinue)) { throw 'Instala el Java requerido por tu SDK y anadelo a PATH.' }
New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot 'bin') | Out-Null
$outputName = if ($Tests) { 'RunIntervalsLab-tests.prg' } else { 'RunIntervalsLab.prg' }
$compilerArgs = @('-f', (Join-Path $projectRoot 'monkey.jungle'), '-d', 'fr970', '-y', $DeveloperKey, '-o', (Join-Path $projectRoot "bin\$outputName"), '-w')
if ($Tests) { $compilerArgs += '-t' }
& $compiler @compilerArgs
if ($LASTEXITCODE -ne 0) { throw "Compilacion fallida ($LASTEXITCODE)." }
