# =============================================================================
# start_server.ps1
# Inicia o Windrose Dedicated Server manualmente.
# Execute via RDP ou Task Scheduler.
# =============================================================================

$serverDir = "C:\windrose-server"
$batFile   = "$serverDir\StartServerForeground.bat"

if (-not (Test-Path $batFile)) {
    Write-Error "Arquivo $batFile nao encontrado. Verifique se o setup foi concluido (C:\windrose-setup.log)."
    exit 1
}

Write-Host "Iniciando Windrose Dedicated Server..."
Start-Process -FilePath $batFile -WorkingDirectory $serverDir
