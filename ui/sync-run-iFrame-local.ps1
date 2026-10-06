$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$runPath = Join-Path $repo "run-iFrame-local.lua"
$iframePath = Join-Path $repo "iFrame.lua"

$lines = Get-Content $runPath
$bootIdx = -1
for ($i = $lines.Count - 1; $i -ge 0; $i--) {
	if ($lines[$i] -eq "-- --- bootstrap local ---") {
		$bootIdx = $i
		break
	}
}
if ($bootIdx -lt 0) {
	throw "No se encontro '-- --- bootstrap local ---' en run-iFrame-local.lua"
}

$boot = ($lines[$bootIdx..($lines.Count - 1)] | Out-String).TrimEnd()
$core = (Get-Content $iframePath -Raw) -replace "\r?\nreturn iFrame\s*\z", ""
$core = $core -replace '^\[\[ iFrame \| UI framework I-Hub \]\]\r?\n\r?\n', ''

$hdr = @"
--[[
	Copia pegada de ui/iFrame.lua para probar en local (un solo archivo, sin HttpGet/readfile).
	Sincroniza con: ui/sync-run-iFrame-local.ps1
]]
--[[ iFrame | UI framework I-Hub ]]

"@

$out = $hdr + $core + "`n-- --- bootstrap local ---`n" + $boot.Substring("-- --- bootstrap local ---".Length).TrimStart()
Set-Content -Path $runPath -Value $out -NoNewline -Encoding utf8
Write-Host "OK run-iFrame-local.lua ($((Get-Content $runPath).Count) lineas)"
