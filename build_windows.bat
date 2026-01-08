@echo off
REM Script para compilar SAFT-Fix para Windows

echo =========================================
echo Compilando SAFT-Fix para Windows
echo =========================================

REM Verificar se Python está instalado
python --version >nul 2>&1
if errorlevel 1 (
    echo ERRO: Python não encontrado
    echo Certifique-se de que Python está instalado e no PATH
    pause
    exit /b 1
)

REM Verificar se está em um ambiente virtual
if "%VIRTUAL_ENV%"=="" (
    echo AVISO: Não está em um ambiente virtual
    set /p CREATE_VENV="Deseja criar/ativar um venv? (s/N): "
    if /i "%CREATE_VENV%"=="s" (
        if not exist "venv" (
            python -m venv venv
        )
        call venv\Scripts\activate.bat
    )
)

REM Instalar dependências
echo Instalando dependências...
python -m pip install --quiet --upgrade pip
python -m pip install --quiet -r requirements.txt

REM Limpar builds anteriores
echo Limpando builds anteriores...
if exist build rmdir /s /q build
if exist dist rmdir /s /q dist
if exist SAFT-Fix.exe del /q SAFT-Fix.exe

REM Criar spec file para Windows
echo Criando configuração para Windows...
(
echo # -*- mode: python ; coding: utf-8 -*-
echo.
echo a = Analysis(
echo     ['saft_fix_gui.py'],
echo     pathex=[],
echo     binaries=[],
echo     datas=[],
echo     hiddenimports=[],
echo     hookspath=[],
echo     hooksconfig={},
echo     runtime_hooks=[],
echo     excludes=[],
echo     noarchive=False,
echo     optimize=0,
echo ^)
echo pyz = PYZ(a.pure^)
echo.
echo exe = EXE(
echo     pyz,
echo     a.scripts,
echo     a.binaries,
echo     a.datas,
echo     [],
echo     name='SAFT-Fix',
echo     debug=False,
echo     bootloader_ignore_signals=False,
echo     strip=False,
echo     upx=True,
echo     upx_exclude=[],
echo     runtime_tmpdir=None,
echo     console=False,
echo     disable_windowed_traceback=False,
echo     argv_emulation=False,
echo     target_arch=None,
echo     codesign_identity=None,
echo     entitlements_file=None,
echo ^)
) > SAFT-Fix-windows.spec

REM Compilar com PyInstaller
echo Compilando com PyInstaller...
pyinstaller SAFT-Fix-windows.spec --clean --noconfirm

REM Limpar spec temporário
del /q SAFT-Fix-windows.spec

REM Verificar se a compilação foi bem-sucedida
if exist "dist\SAFT-Fix.exe" (
    echo.
    echo =========================================
    echo Compilação concluída com sucesso!
    echo =========================================
    echo Executável criado em: dist\SAFT-Fix.exe
    echo.
    echo Para testar, execute:
    echo   dist\SAFT-Fix.exe
    echo.
) else (
    echo ERRO: Compilação falhou
    pause
    exit /b 1
)

pause

