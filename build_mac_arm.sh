#!/bin/bash
# Script para compilar SAFT-Fix para macOS ARM (Apple Silicon)

set -e  # Parar em caso de erro

echo "========================================="
echo "Compilando SAFT-Fix para macOS ARM"
echo "========================================="

# Verificar se estamos no macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "ERRO: Este script deve ser executado no macOS"
    exit 1
fi

# Verificar arquitetura
ARCH=$(uname -m)
if [[ "$ARCH" != "arm64" ]]; then
    echo "AVISO: Este script é para ARM64. Arquitetura detectada: $ARCH"
    read -p "Continuar mesmo assim? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
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
rm -rf build dist *.app

# Compilar com PyInstaller
echo "Compilando com PyInstaller..."
pyinstaller SAFT-Fix.spec --clean --noconfirm

# Verificar se a compilação foi bem-sucedida
if [ -d "dist/SAFT-Fix.app" ]; then
    echo ""
    echo "========================================="
    echo "Compilação concluída com sucesso!"
    echo "========================================="
    echo "Aplicação criada em: dist/SAFT-Fix.app"
    echo ""
    echo "Para testar, execute:"
    echo "  open dist/SAFT-Fix.app"
    echo ""
else
    echo "ERRO: Compilação falhou"
    exit 1
fi

