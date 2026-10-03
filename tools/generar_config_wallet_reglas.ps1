# Genera solo el bloque de configuración de Wallet de firestore.rules.
# Ejecutar al cambiar instalaciones, horarios, precios o cancelación y publicar
# después las reglas. No instala nada ni escribe datos en Firebase.
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$config = [IO.File]::ReadAllText((Join-Path $projectRoot 'lib/config/club/club_config_actual.dart'))
if ($config -notmatch "clubId:\s*'club-demo'" -or $config -notmatch "zonaHoraria:\s*'Europe/Madrid'") {
  throw 'Estas reglas de prueba solo admiten club-demo en Europe/Madrid.'
}
$constants = @{}
foreach ($match in [regex]::Matches($config, 'static const\s+(\w+)\s*=\s*([\[{][\s\S]*?[\]}]);')) {
  $constants[$match.Groups[1].Value] = $match.Groups[2].Value
}
function Get-ConfigValue($body, $field, $default) {
  $match = [regex]::Match($body, ('\b' + $field + ':\s*(\[[\s\S]*?\]|\{[\s\S]*?\}|\w+)\s*,'))
  if (!$match.Success) { return $default }
  $value = $match.Groups[1].Value
  if ($constants.ContainsKey($value)) { return $constants[$value] }
  if ($value -notmatch '^(\d+|\[[\s\S]*\]|\{[\s\S]*\})$') { throw "Configuración no admitida: $field = $value" }
  return $value
}
$entries = @()
$walletActivo = $config -match "'wallet':\s*true"
foreach ($match in [regex]::Matches($config, 'Instalacion\(([\s\S]*?)\r?\n\s*\),')) {
  $body = $match.Groups[1].Value
  $id = [regex]::Match($body, "\bid:\s*'([^']+)'").Groups[1].Value
  if (!$id) { throw 'Instalación sin ID literal.' }
  $horarios = Get-ConfigValue $body 'horarios' '[]'
  $precios = Get-ConfigValue $body 'preciosPorHorarioCentimos' '{}'
  if (!$walletActivo) { $precios = '{}' }
  $duracion = Get-ConfigValue $body 'duracionReservaMinutos' '60'
  $cancelacion = Get-ConfigValue $body 'minutosAntelacionCancelacion' '60'
  $horarios = ($horarios -replace '\s+', ' ').Trim() -replace ',\s*\]', ']'
  $precios = ($precios -replace '\s+', ' ').Trim() -replace ',\s*\}', '}'
  $entries += "        '$id': {'horarios': $horarios, 'precios': $precios, 'duracion': $duracion, 'cancelacion': $cancelacion}"
}
if ($entries.Count -eq 0) { throw 'No se encontraron instalaciones.' }
$block = "    // INICIO CONFIG WALLET GENERADA (tools/generar_config_wallet_reglas.ps1)`n" +
  "    function configuracionReserva(instalacionId) {`n      return {`n" +
  ($entries -join ",`n") + "`n      }.get(instalacionId, {});`n    }`n" +
  '    // FIN CONFIG WALLET GENERADA'
$rulesPath = Join-Path $projectRoot 'firestore.rules'
$rules = [IO.File]::ReadAllText($rulesPath)
$pattern = '    // INICIO CONFIG WALLET GENERADA[\s\S]*?    // FIN CONFIG WALLET GENERADA'
if (![regex]::IsMatch($rules, $pattern)) { throw 'Faltan los marcadores de configuración de Wallet.' }
$rules = [regex]::Replace($rules, $pattern, [Text.RegularExpressions.MatchEvaluator]{ param($match) $block })
[IO.File]::WriteAllText($rulesPath, $rules, [Text.UTF8Encoding]::new($false))
Write-Output "Configuración local generada desde ClubConfigActual: $($entries.Count) instalaciones. Sin cambios en Firebase."
