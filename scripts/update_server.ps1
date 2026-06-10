# =============================================================================
# update_server.ps1
# Atualiza o Windrose Dedicated Server para a versao mais recente via SteamCMD.
#
# IMPORTANTE: Sempre atualize o servidor apos atualizar o game client.
# Versoes diferentes causam bugs e podem impedir conexoes.
# Referencia: https://playwindrose.com/dedicated-server-guide/
# =============================================================================

$steamCmdDir = "C:\steamcmd"
$serverDir   = "C:\windrose-server"

Write-Host "[1/2] Parando processos do servidor (se estiver rodando)..."
Get-Process -Name "WindroseServer" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 3

Write-Host "[2/2] Atualizando Windrose Dedicated Server..."
$updateScript = @"
force_install_dir "$serverDir"
login anonymous
app_update 4129620 validate
quit
"@
$updateScript | Out-File -FilePath "$steamCmdDir\update_windrose.txt" -Encoding ASCII

Start-Process -FilePath "$steamCmdDir\steamcmd.exe" `
    -ArgumentList "+runscript $steamCmdDir\update_windrose.txt" `
    -Wait -NoNewWindow

Write-Host "Atualizacao concluida. Reinicie o servidor com start_server.ps1."
