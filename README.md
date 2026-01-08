# SAFT-Fix

Ferramenta para corrigir números de documentos duplicados em ficheiros SAFT (Standard Audit File for Tax) XML.

## Requisitos

- Python 3.7+
- lxml

## Instalação

```bash
pip install -r requirements.txt
```

## Uso

```bash
python saft_fix_gui.py
```

## Funcionalidades

- Corrige números de documentos duplicados em SalesInvoices
- Corrige números de documentos duplicados em WorkingDocuments
- Atualiza ATCUD automaticamente
- Interface gráfica intuitiva
- Log detalhado de alterações
- Validação robusta de entrada
- Tratamento de erros melhorado

## Como usar

1. Abre a aplicação executando `python saft_fix_gui.py`
2. Seleciona o ficheiro SAFT original
3. Define o ficheiro de saída
4. Configura os tipos de documentos a processar:
   - Marca "SalesInvoices" e seleciona os tipos (FT, FR, FS, NC, ND)
   - Para cada tipo, define a série e ATCUD
   - Opcionalmente, marca "WorkingDocuments" e define série e ATCUD
5. Clica em "Executar"
6. Verifica o log de alterações na área inferior

## Compilação

Para criar executáveis para diferentes plataformas, use os scripts de compilação:

### macOS (ARM - Apple Silicon)

```bash
./build_mac_arm.sh
```

O executável será criado em `dist/SAFT-Fix.app`

### Linux

```bash
./build_linux.sh
```

O executável será criado em `dist/SAFT-Fix`

### Windows

**No Windows:**
```batch
build_windows.bat
```

**A partir do Linux (limitado):**
```bash
./build_windows_from_linux.sh
```

O executável será criado em `dist\SAFT-Fix.exe`

**Nota sobre cross-compilation:** PyInstaller não suporta cross-compilation nativa. Para compilar Windows a partir do Linux, as melhores opções são:

1. **GitHub Actions** (recomendado): Use o workflow `.github/workflows/build.yml` que compila automaticamente para todas as plataformas
2. **Docker**: Use uma imagem Windows Server Core
3. **VM Windows**: Execute `build_windows.bat` numa máquina virtual Windows
4. **Wine**: Pode funcionar mas requer configuração adicional (Python instalado no Wine)

**Nota:** Os scripts verificam automaticamente se as dependências estão instaladas e criam/ativam um ambiente virtual se necessário.

## Estrutura do projeto

- `saft_core.py`: Lógica principal de processamento do SAFT
- `saft_fix_gui.py`: Interface gráfica
- `requirements.txt`: Dependências do projeto
- `build_mac_arm.sh`: Script de compilação para macOS ARM
- `build_linux.sh`: Script de compilação para Linux
- `build_windows.bat`: Script de compilação para Windows
- `build_windows_from_linux.sh`: Script para tentar compilar Windows a partir do Linux
- `SAFT-Fix.spec`: Configuração do PyInstaller
- `.github/workflows/build.yml`: GitHub Actions workflow para compilar todas as plataformas

## Notas

- A ferramenta preserva o primeiro documento encontrado e corrige apenas os duplicados
- O ATCUD é atualizado automaticamente com o novo número sequencial
- O ficheiro de saída mantém a estrutura XML original com formatação melhorada

