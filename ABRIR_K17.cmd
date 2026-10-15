@echo off
setlocal
set "ZO_PROJECT_ROOT=%~dp0"
title Zombie Outbreak Reborn - Abrir K-17
echo.
echo K-17 - Abrir o mapa atual pelo caminho completo
echo.
echo Se o plugin Rojo estiver conectado a um projeto antigo, desconecte-o no Studio.
echo Salve uma copia do place antigo antes de fecha-lo.
echo.
powershell.exe -NoProfile -Command ^
 "$ErrorActionPreference='Stop'; try { $place=Join-Path $env:ZO_PROJECT_ROOT 'buildsZombieOutbreakReborn_K17.rbxl'; $manifest=Join-Path $env:ZO_PROJECT_ROOT 'buildsK17.release.json'; if (!(Test-Path -LiteralPath $place) -or !(Test-Path -LiteralPath $manifest)) { throw 'Arquivos K-17 ausentes. Atualize main no GitHub Desktop com Fetch/Pull.' }; $info=Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json; if ($info.file -ne 'ZombieOutbreakReborn_K17.rbxl' -or $info.map -ne 'ZO_K17Foundry') { throw 'Manifesto de outro mapa.' }; $hash=(Get-FileHash -LiteralPath $place -Algorithm SHA256).Hash; if ($hash -ne $info.sha256) { throw 'O arquivo local difere da entrega verificada. Preserve suas edicoes e confira as alteracoes no GitHub Desktop antes de atualizar.' }; Write-Host 'ARQUIVO K-17 VERIFICADO:'; Write-Host $place; Write-Host ('Objetos de barricada: '+$info.barricades+' | Dutos: '+$info.ducts); Write-Host 'No Explorer do Studio, procure Workspace > ZO_K17Foundry e pressione F.'; Write-Host 'Se nao abrir automaticamente, use File > Open from File e selecione o caminho acima.'; Start-Process -FilePath $place } catch { Write-Host ('Nao foi possivel abrir: '+$_.Exception.Message); exit 1 }"
set "ZO_OPEN_STATUS=%ERRORLEVEL%"
echo.
pause
exit /b %ZO_OPEN_STATUS%
