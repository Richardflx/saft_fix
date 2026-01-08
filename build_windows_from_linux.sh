#!/bin/bash
# Script para compilar SAFT-Fix para Windows a partir do Linux
# NOTA: PyInstaller não suporta cross-compilation nativa
# Este script tenta usar Wine como alternativa

set -e  # Parar em caso de erro

echo "========================================="
echo "Compilando SAFT-Fix para Windows (Linux)"
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

# Verificar se Wine está instalado
WINE_AVAILABLE=false
if command -v wine &> /dev/null; then
    WINE_AVAILABLE=true
    echo "Wine encontrado: $(wine --version)"
else
    echo ""
    echo "AVISO: Wine não está instalado"
    echo ""
    echo "Para compilar para Windows no Linux, você tem algumas opções:"
    echo ""
    echo "OPÇÃO 1: Instalar Wine (recomendado para testes)"
    echo "  Ubuntu/Debian: sudo apt-get install wine"
    echo "  Fedora: sudo dnf install wine"
    echo "  Arch: sudo pacman -S wine"
    echo ""
    echo "OPÇÃO 2: Usar Docker com imagem Windows"
    echo "  docker run -v \$(pwd):/app -w /app mcr.microsoft.com/windows/servercore:ltsc2019"
    echo ""
    echo "OPÇÃO 3: Usar GitHub Actions / CI/CD"
    echo "  Criar workflow que compila automaticamente no Windows"
    echo ""
    echo "OPÇÃO 4: Usar uma VM Windows"
    echo ""
    read -p "Deseja continuar sem Wine? (N/s): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
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
rm -rf build dist SAFT-Fix.exe

# Criar spec file para Windows
echo "Criando configuração para Windows..."
cat > SAFT-Fix-windows.spec << 'EOF'
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

# Tentar compilar
if [ "$WINE_AVAILABLE" = true ]; then
    echo ""
    echo "Tentando compilar usando Wine..."
    echo "NOTA: Isso pode não funcionar perfeitamente devido às limitações do PyInstaller"
    echo ""
    
    # Configurar Wine para Windows 10
    export WINEPREFIX="${HOME}/.wine-saft-fix"
    export WINEARCH=win64
    
    # Tentar instalar Python no Wine (se necessário)
    if [ ! -d "$WINEPREFIX" ]; then
        echo "Configurando Wine prefix..."
        winecfg &
        sleep 2
        pkill winecfg || true
    fi
    
    # Tentar usar pyinstaller via wine
    # NOTA: Isso requer Python instalado no Wine
    echo "AVISO: Para usar Wine, você precisa:"
    echo "  1. Instalar Python para Windows no Wine"
    echo "  2. Instalar PyInstaller no Python do Wine"
    echo ""
    echo "Alternativamente, use uma das opções mencionadas acima."
    echo ""
    
    read -p "Deseja tentar continuar mesmo assim? (N/s): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        rm -f SAFT-Fix-windows.spec
        exit 1
    fi
fi

# Limpar spec temporário
rm -f SAFT-Fix-windows.spec

echo ""
echo "========================================="
echo "Compilação para Windows a partir do Linux"
echo "========================================="
echo ""
echo "RECOMENDAÇÃO: Use uma das seguintes alternativas:"
echo ""
echo "1. GitHub Actions (mais fácil):"
echo "   - Crie um workflow .github/workflows/build.yml"
echo "   - Use uma runner Windows"
echo ""
echo "2. Docker com Windows:"
echo "   - Use uma imagem Windows Server Core"
echo "   - Instale Python e PyInstaller"
echo ""
echo "3. VM Windows:"
echo "   - Use VirtualBox/VMware com Windows"
echo "   - Execute build_windows.bat na VM"
echo ""
echo "4. Máquina Windows física:"
echo "   - Execute build_windows.bat diretamente"
echo ""

