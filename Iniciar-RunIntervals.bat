@echo off
setlocal
title RunIntervals - Compilar y abrir simulador
pushd "%~dp0"
if errorlevel 1 exit /b 1

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { try { $ErrorActionPreference = 'Stop'; $sdk = (Get-Content (Join-Path $env:APPDATA 'Garmin\ConnectIQ\current-sdk.cfg') -Raw).Trim(); $simulator = Join-Path $sdk 'bin\simulator.exe'; $monkeydo = Join-Path $sdk 'bin\monkeydo.bat'; if (!(Test-Path -LiteralPath $simulator) -or !(Test-Path -LiteralPath $monkeydo)) { throw 'No se encuentra el simulador o monkeydo en el SDK configurado.' }; Write-Host 'Compilando RunIntervals...'; & '.\tools\build.ps1' -SdkPath $sdk -DeveloperKey '.\developer_key'; Write-Host 'Abriendo el simulador...'; if (!(Get-Process -Name simulator -ErrorAction SilentlyContinue)) { Start-Process -FilePath $simulator -WindowStyle Normal }; $deadline = (Get-Date).AddSeconds(30); do { $output = & $monkeydo '.\bin\RunIntervals.prg' 'fr970' 2>&1; $runExitCode = $LASTEXITCODE; $notReady = ($output -join [Environment]::NewLine) -match 'Unable to connect to simulator'; if (!$notReady) { break }; Start-Sleep -Milliseconds 500; } while ((Get-Date) -lt $deadline); $output | Out-Host; if ($notReady -or $runExitCode -ne 0) { throw 'No se pudo cargar RunIntervals en el simulador.' }; Write-Host 'RunIntervals cargado en el simulador.'; exit 0; } catch { Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red; exit 1 } }"

set "result=%errorlevel%"
popd
echo.
pause
exit /b %result%
