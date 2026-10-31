@echo off
setlocal
set "ZO_CAPTURE_SCRIPT=%~dp0tools\studio\CaptureOfficialWeapons.luau"
title Zombie Outbreak Reborn - Capturar modelos oficiais
echo.
echo Mantenha aberta a experiencia salva no Roblox onde o carregamento foi permitido.
echo Pare o teste e deixe o Studio em modo de edicao.
echo Este atalho copia o comando; a captura acontece quando voce cola no Studio.
echo.
powershell.exe -NoProfile -STA -Command ^
 "$ErrorActionPreference='Stop'; try { $text=[System.IO.File]::ReadAllText($env:ZO_CAPTURE_SCRIPT); Set-Clipboard -Value $text; Write-Host 'Comando de captura copiado para a area de transferencia.' } catch { Write-Host ('Nao foi possivel copiar: '+$_.Exception.Message); exit 1 }"
if errorlevel 1 (
    pause
    exit /b 1
)
echo.
echo 1. Clique na Command Bar do Studio, cole com Ctrl+V e pressione Enter.
echo 2. Aguarde os resultados K17 REVIEW no Output.
echo 3. Exporte a pasta selecionada como ZO_OfficialWeaponReview.rbxm ou .rbxmx.
echo 4. Envie esse arquivo para revisar a estrutura real dos quatro modelos.
echo.
echo A captura guarda modelos em ServerStorage e fontes como texto sem execucao.
echo Ela nao atualiza nem publica os scripts da experiencia salva.
echo.
pause
