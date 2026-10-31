@echo off
setlocal
set "ZO_IMPORT_SCRIPT=%~dp0tools\studio\ImportOfficialWeapons.luau"
title Zombie Outbreak Reborn - Importar armas oficiais
echo.
echo Este atalho copia o comando de importacao. Ele nao controla o Studio.
echo Abra primeiro o K-17 atualizado com ABRIR_K17.cmd e pare qualquer teste.
echo.
powershell.exe -NoProfile -STA -Command ^
 "$ErrorActionPreference='Stop'; try { $text=[System.IO.File]::ReadAllText($env:ZO_IMPORT_SCRIPT); Set-Clipboard -Value $text; Write-Host 'Comando copiado para a area de transferencia.' } catch { Write-Host ('Nao foi possivel copiar: '+$_.Exception.Message); exit 1 }"
if errorlevel 1 (
    pause
    exit /b 1
)
echo.
echo 1. No Studio, em modo de edicao, abra a Command Bar e o Output.
echo 2. Cole com Ctrl+V na Command Bar e pressione Enter.
echo 3. Confira os resultados das quatro armas no Output.
echo 4. Salve COMO uma copia fora de builds, sem sobrescrever o arquivo verificado.
echo 5. Exporte a pasta selecionada como ZO_WeaponAssets_Official.rbxmx.
echo.
echo Permissoes e disponibilidade dos modelos sao verificadas pelo proprio Roblox.
echo.
pause
