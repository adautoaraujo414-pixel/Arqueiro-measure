# N05 (auditoria de 17/11): atualização do Windows por cima da versão publicada, sem perder dados.
# Uso: teste_atualizacao_windows.ps1 <msi-anterior> <msi-novo>
param([string]$Old, [string]$New)
$ErrorActionPreference = 'Continue'
$script:FALHAS = 0
function Falha($m) { Write-Host "FALHA: $m"; $script:FALHAS++ }
$out0 = 'atualizacao'; New-Item -ItemType Directory -Force $out0 | Out-Null
$data = Join-Path $env:LOCALAPPDATA 'Arque\Arquemestre'
function AcharExe { Get-ChildItem "$env:LOCALAPPDATA\Arquemestre\Arquemestre.exe","$env:ProgramFiles\Arquemestre\Arquemestre.exe" -ErrorAction SilentlyContinue | Select-Object -First 1 }
function Instalar($msi, $log) { $p = Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /qn /l*v $log" -Wait -PassThru; Write-Host "msiexec saiu com $($p.ExitCode)"; return $p.ExitCode }
function Abrir($s) { $e = AcharExe; if (-not $e) { Falha 'app instalado não encontrado'; return }
  $p = Start-Process $e.FullName -PassThru; Start-Sleep $s
  if ($p.HasExited) { Falha "o app fechou sozinho (saída $($p.ExitCode))" } else { Stop-Process -Id $p.Id -Force; Start-Sleep 3 } }
function Hashes { Get-Content "$script:out/lista.txt" | ForEach-Object { $f = Join-Path $data "files\$_"; if (Test-Path -LiteralPath $f) { "$((Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash.ToLower())  $_" } else { "  $_" } } }

# 24/11 (auditoria final): a mesma sequência pra cada backup de referência, cada uma do zero (sem o app e sem a pasta de dados):
# o de sempre (tests/backup-referencia) e o rico gerado pelo editor publicado (tests/backup-referencia-rico).
function Rodada($zip, $man, $tag) {
$script:out = Join-Path $out0 $tag; $out = $script:out; New-Item -ItemType Directory -Force $out | Out-Null; Write-Host "######## backup $tag"
if (AcharExe) { Start-Process msiexec.exe -ArgumentList "/x `"$New`" /qn" -Wait | Out-Null; Start-Process msiexec.exe -ArgumentList "/x `"$Old`" /qn" -Wait | Out-Null }
Remove-Item -Recurse -Force (Join-Path $data 'files') -ErrorAction SilentlyContinue
Write-Host '== 1. instala a versão anterior'
if ((Instalar $Old 'msi-anterior.log') -ne 0) { Falha 'não instalou a versão anterior' }
$e = AcharExe; Write-Host "versão anterior: $((Get-Item $e.FullName).VersionInfo.ProductVersion) em $($e.FullName)"
Abrir 20

Write-Host '== 2. põe os dados do backup de referência'
Remove-Item -Recurse -Force ref -ErrorAction SilentlyContinue
Expand-Archive $zip -DestinationPath ref
$base = (Resolve-Path ref/files).Path
Get-ChildItem -Recurse -File ref/files | ForEach-Object { $_.FullName.Substring($base.Length + 1).Replace('\', '/') } | Set-Content "$out/lista.txt"
Get-Content "$out/lista.txt" | ForEach-Object { $d = Join-Path $data "files\$_"; New-Item -ItemType Directory -Force (Split-Path $d) | Out-Null; Copy-Item -LiteralPath (Join-Path $base $_) $d -Force }
Abrir 25
Hashes | Set-Content "$out/antes.txt"; Get-Content "$out/antes.txt"

Write-Host '== 3. instala a versão nova por cima (sem desinstalar)'
if ((Instalar $New 'msi-novo.log') -ne 0) { Falha 'a versão nova não instalou por cima' }
$e = AcharExe; Write-Host "versão nova: $((Get-Item $e.FullName).VersionInfo.ProductVersion)"
$apps = Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall' -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.DisplayName -like 'Arquemestre*' }
Write-Host "instalações do Arquemestre no Windows: $(@($apps).Count) ($((@($apps) | ForEach-Object { $_.DisplayVersion }) -join ', '))"
if (@($apps).Count -ne 1) { Falha 'a versão nova ficou ao lado da antiga (duas instalações) em vez de atualizar' }
Abrir 30
Hashes | Set-Content "$out/depois.txt"

Write-Host '== 4. confere'
if (Compare-Object (Get-Content "$out/antes.txt") (Get-Content "$out/depois.txt")) { Falha 'arquivos mudaram ou sumiram na atualização' } else { Write-Host "arquivos iguais antes e depois: $((Get-Content "$out/depois.txt").Count)" }
$man = (Get-Content $man -Raw | ConvertFrom-Json).arquivos
$dep = @{}; Get-Content "$out/depois.txt" | ForEach-Object { $p = $_ -split '  ', 2; if ($p.Count -eq 2 -and $p[0]) { $dep[$p[1]] = $p[0] } }
$ruins = @($man.PSObject.Properties | Where-Object { $dep[$_.Name] -ne $_.Value } | ForEach-Object { $_.Name })
Write-Host "iguais ao manifesto: $(@($man.PSObject.Properties).Count - $ruins.Count) de $(@($man.PSObject.Properties).Count)"
if ($ruins.Count) { Falha "diferentes do manifesto: $($ruins -join ', ')" }
Get-ChildItem "$env:USERPROFILE\Documents\Arquemestre\Backups" -ErrorAction SilentlyContinue | Select-Object Name, Length | Format-Table | Out-String | Write-Host
}
Rodada 'tests/backup-referencia/android-backup-referencia.zip' 'tests/backup-referencia/manifesto.json' 'referencia'
Rodada 'tests/backup-referencia-rico/backup-rico.zip' 'tests/backup-referencia-rico/manifesto.json' 'rico'
Write-Host "RESULTADO: falhas $script:FALHAS"
exit $script:FALHAS
