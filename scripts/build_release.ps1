# Compila Plantamoss en modo release con el codigo Dart ofuscado.
#
# - APK y App Bundle: --obfuscate --split-debug-info (los simbolos quedan en
#   build/debug-info y NO se suben a git; sirven para leer trazas de errores).
# - R8 (minify + shrinkResources) se activa solo en android/app/build.gradle.kts.
# - Web: release minificado (dart2js); la ofuscacion de Dart no aplica a web.
#
# Uso (desde la raiz de la app):
#   powershell -ExecutionPolicy Bypass -File scripts\build_release.ps1
#   powershell -ExecutionPolicy Bypass -File scripts\build_release.ps1 -Solo web
param(
    [ValidateSet('todo', 'apk', 'appbundle', 'web')]
    [string]$Solo = 'todo'
)

$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

$debugInfo = 'build/debug-info'
$ofuscar = @('--obfuscate', "--split-debug-info=$debugInfo")

function Compilar([string]$nombre, [string[]]$argumentos) {
    Write-Host "== flutter build $nombre $($argumentos -join ' ')"
    & flutter build $nombre @argumentos
    if ($LASTEXITCODE -ne 0) { throw "Fallo flutter build $nombre" }
}

flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Fallo flutter pub get' }

if (-not (Test-Path 'android/key.properties')) {
    Write-Warning 'No existe android/key.properties: el APK se firma con la llave de debug (solo pruebas).'
}

if ($Solo -in @('todo', 'apk'))       { Compilar 'apk'       (@('--release') + $ofuscar) }
if ($Solo -in @('todo', 'appbundle')) { Compilar 'appbundle' (@('--release') + $ofuscar) }
if ($Solo -in @('todo', 'web'))       { Compilar 'web'       @('--release') }

Write-Host ''
Write-Host 'Listo:'
Write-Host '  APK:        build/app/outputs/flutter-apk/app-release.apk'
Write-Host '  App Bundle: build/app/outputs/bundle/release/app-release.aab'
Write-Host '  Web:        build/web'
Write-Host "  Simbolos:   $debugInfo (guardalos en privado, no los publiques)"
