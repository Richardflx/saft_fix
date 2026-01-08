#!/bin/bash
# Script para compilar SAFT-Fix para Linux

set -e  # Parar em caso de erro

echo "========================================="
echo "Compilando SAFT-Fix para Linux"
echo "========================================="

# Verificar se estamos no Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "ERRO: Este script deve ser executado no Linux"
    exit 1
fi

# Verificar se Python está instalado
if ! command -v python3 &> /dev/null; then
    echo "ERRO: Python 3 não encontrado"
    exit 1
fi

# Verificar se está em um ambiente virtual
if [[ -z "$VIRTUAL_ENV" ]]; then
    echo "AVISO: Não está em um ambiente virtual"
    read -p "Deseja criar/ativar um venv? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        if [ ! -d "venv" ]; then
            python3 -m venv venv
        fi
        source venv/bin/activate
    fi
fi

# Instalar dependências
echo "Instalando dependências..."
pip install -q --upgrade pip
pip install -q -r requirements.txt

# Limpar builds anteriores
echo "Limpando builds anteriores..."
rm -rf build dist SAFT-Fix

# Criar spec file para Linux (sem BUNDLE)
echo "Criando configuração para Linux..."
cat > SAFT-Fix-linux.spec << 'EOF'
# -*- mode: python ; coding: utf-8 -*-

a = Analysis(
    ['saft_fix_gui.py'],
    pathex=[],
    binaries=[],
    datas=[],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='SAFT-Fix',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
EOF

# Compilar com PyInstaller
echo "Compilando com PyInstaller..."
pyinstaller SAFT-Fix-linux.spec --clean --noconfirm

# Limpar spec temporário
rm -f SAFT-Fix-linux.spec

# Verificar se a compilação foi bem-sucedida
if [ -f "dist/SAFT-Fix" ]; then
    echo ""
    echo "========================================="
    echo "Compilação concluída com sucesso!"
    echo "========================================="
    echo "Executável criado em: dist/SAFT-Fix"
    echo ""
    echo "Para testar, execute:"
    echo "  ./dist/SAFT-Fix"
    echo ""
    
    # Tornar executável
    chmod +x dist/SAFT-Fix
else
    echo "ERRO: Compilação falhou"
    exit 1
fi

