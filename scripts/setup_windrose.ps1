# =============================================================================
# setup_windrose.ps1
# Script de inicializacao do servidor Windrose — executado via EC2 User Data.
# Roda automaticamente na PRIMEIRA inicializacao da instancia.
#
# O que este script faz:
#   1. Instala o SteamCMD
#   2. Baixa o Windrose Dedicated Server (App ID 4129620)
#   3. Cria o ServerDescription.json com os parametros do Terraform
#   4. Cria atalho na area de trabalho para iniciar o servidor
#   5. Configura regras do Windows Firewall para a porta do jogo
# =============================================================================

<powershell>
Set-ExecutionPolicy Bypass -Scope Process -Force
$ErrorActionPreference = "Stop"

$logFile = "C:\windrose-setup.log"
function Log($msg) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] $msg" | Tee-Object -FilePath $logFile -Append
}

# Captura qualquer erro fatal, loga e encerra com codigo de erro
trap {
    Log "ERRO FATAL: $_"
    exit 1
}

Log "=== Iniciando setup do Windrose Dedicated Server ==="

$steamCmdDir   = "C:\steamcmd"
$serverDir     = "C:\windrose-server"

# Caminho correto do ServerDescription.json conforme guia oficial do Windrose:
# https://playwindrose.com/dedicated-server-guide/
$serverDescDir  = "$serverDir\R5\Saved\SaveProfiles\Default"
$serverDescFile = "$serverDescDir\ServerDescription.json"

# --- 1. Instalar SteamCMD ---
Log "[1/4] Instalando SteamCMD..."
New-Item -ItemType Directory -Path $steamCmdDir -Force | Out-Null
$steamCmdZip = "$steamCmdDir\steamcmd.zip"
Invoke-WebRequest -Uri "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip" -OutFile $steamCmdZip -UseBasicParsing
Expand-Archive -Path $steamCmdZip -DestinationPath $steamCmdDir -Force
Remove-Item $steamCmdZip
Log "SteamCMD instalado em $steamCmdDir"

# --- 2. Baixar o Windrose Dedicated Server ---
Log "[2/4] Baixando Windrose Dedicated Server (App ID 4129620)..."
New-Item -ItemType Directory -Path $serverDir -Force | Out-Null

$steamCmdScript = @"
force_install_dir "$serverDir"
login anonymous
app_update 4129620 validate
quit
"@
$steamCmdScript | Out-File -FilePath "$steamCmdDir\install_windrose.txt" -Encoding ASCII

$process = Start-Process -FilePath "$steamCmdDir\steamcmd.exe" `
    -ArgumentList "+runscript $steamCmdDir\install_windrose.txt" `
    -Wait -PassThru -NoNewWindow

if ($process.ExitCode -ne 0) {
    Log "ERRO: SteamCMD retornou exit code $($process.ExitCode)."
    exit 1
}
Log "Windrose Dedicated Server baixado com sucesso em $serverDir"

# --- 3. Criar ServerDescription.json ---
# Usamos ConvertTo-Json para evitar conflito de aspas duplas com o
# templatefile do Terraform, que substituiria as variaveis ${...} incorretamente
# dentro de um here-string PowerShell com JSON.
Log "[3/4] Configurando ServerDescription.json..."
New-Item -ItemType Directory -Path $serverDescDir -Force | Out-Null

$serverDesc = @{
    Version = 1
    ServerDescription_Persistent = @{
        InviteCode                       = "${invite_code}"
        IsPasswordProtected              = if ("${server_password}" -ne "") { $true } else { $false }
        Password                         = "${server_password}"
        ServerName                       = "${server_name}"
        MaxPlayerCount                   = ${max_players}
        UseDirectConnection              = $true
        DirectConnectionServerPort       = ${direct_connection_port}
        DirectConnectionProxyAddress     = "0.0.0.0"
        AutoLoadLatestBackupIfHasBroken  = $true
        CanLaunchMultipleServerInstances = $false
    }
}
$serverDesc | ConvertTo-Json -Depth 3 | Out-File -FilePath $serverDescFile -Encoding UTF8 -Force
Log "ServerDescription.json criado em $serverDescFile"

# --- 4. Atalho na area de trabalho ---
Log "[4/4] Criando atalho para iniciar o servidor..."
$desktopPath  = [System.Environment]::GetFolderPath("CommonDesktopDirectory")
$shortcutPath = "$desktopPath\Iniciar Windrose Server.lnk"
$WshShell  = New-Object -ComObject WScript.Shell
$shortcut  = $WshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath       = "$serverDir\StartServerForeground.bat"
$shortcut.WorkingDirectory = $serverDir
$shortcut.Description      = "Inicia o Windrose Dedicated Server"
$shortcut.Save()
Log "Atalho criado em: $shortcutPath"

# --- Firewall local do Windows ---
Log "Configurando regras do Windows Firewall..."
netsh advfirewall firewall add rule name="Windrose Server TCP" dir=in action=allow protocol=TCP localport=${direct_connection_port}
netsh advfirewall firewall add rule name="Windrose Server UDP" dir=in action=allow protocol=UDP localport=${direct_connection_port}
Log "Firewall configurado para porta ${direct_connection_port} TCP+UDP"

Log "=== Setup concluido com sucesso! ==="
Log "Invite Code: ${invite_code}"
Log "Conexao direta: <IP_PUBLICO>:${direct_connection_port}"
Log "Log completo em: C:\windrose-setup.log"
</powershell>
