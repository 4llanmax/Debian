#!/bin/bash

#-----------------------------------------------------------------------------#
#                        Script para Ubuntu 24.04 LTS                         #
#-----------------------------------------------------------------------------#

set -e

#-----------------------------------------------------------------------------#
#                                   Funções                                   #
#-----------------------------------------------------------------------------#

# Função: Verificar se pacotes necessarios para execução estão disponiveis.
verifica_comando() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo -e "\e[33m"
        echo "Aviso: o comando '$1' não está instalado. Etapa correspondente será ignorada."
        echo -e "\e[0m"
        return 1
    fi
    return 0
}

# Função: Verificar a existencia de um diretório local.
verifica_diretorio() {
    local base_dir="$1"
    local nome_diretorio="$2"
    local caminho_completo="$base_dir/$nome_diretorio"

    if [ ! -d "$caminho_completo" ]; then
        echo -e "\e[31m"
        echo "Erro: Diretório '$nome_diretorio' não encontrado."
        echo "Caminho esperado: $caminho_completo"
        echo -e "\e[0m"
        exit 1
    fi

    echo "$caminho_completo"
}

#-----------------------------------------------------------------------------#
#                Verificação de usuário ROOT, inicio de LOG e                 #
#                   verificação de diretorios necessarios                     #
#-----------------------------------------------------------------------------#

# Verifica se o script está sendo executado como root.
if [ "$EUID" -ne 0 ]; then
    echo "Por favor, execute este script como root (ex: sudo ./configuraSO.sh)"
    exit 1
fi

# Arquivo de log: Obtém o caminho do diretório onde o script está localizado.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Arquivo de log: Gera timestamp no formato desejado: YYYYmmddHHMMSS.
TIMESTAMP=$(date +%Y%m%d%H%M%S)

# Arquivo de log: Define o caminho completo para o log.
LOGFILE="$SCRIPT_DIR/log_configuraSO_$TIMESTAMP.log"

# Arquivo de log: Redireciona saída padrão e de erro para o log (e para a tela).
exec > >(tee -a "$LOGFILE") 2>&1

echo "          Iniciando execução em: $(date)"

# Verificação: confirma se o diretorio dos pacotes .deb existe e está acessivel.
PASTA_DEBS=$(verifica_diretorio "$SCRIPT_DIR" "ProgramasDEB")

# Verificação: confirma se o diretorio das extensões existe e está acessivel.
PASTA_EXTS=$(verifica_diretorio "$SCRIPT_DIR" "ExtensoesGNOME")

#-----------------------------------------------------------------------------#
#      Etapa 1: Atualização de lista de pacotes e Atualização de pacotes.     #
#-----------------------------------------------------------------------------#

echo -e "\e[34m"
echo "#----------------------------------------------------------------------#"
echo "           Atualizando lista de pacotes e atualizando pacotes           "
echo "#----------------------------------------------------------------------#"
echo -e "\e[0m"

# Atualiza lista de pacotes.
apt-get update

# Atualiza pacotes de programas se disponivel sem interação.
apt-get upgrade -y

#-----------------------------------------------------------------------------#
#               Etapa 2: Instalação de pacotes básicos via APT.               #
#-----------------------------------------------------------------------------#

echo -e "\e[34m"
echo "#----------------------------------------------------------------------#"
echo "         Instalando pacotes principais e utilitários de sistema         "
echo "#----------------------------------------------------------------------#"
echo -e "\e[0m"

apt-get install -y \
    htop \
    iotop \
    iftop \
    lm-sensors \
    psensor \
    sysstat \
    smartmontools \
    mesa-utils \
    filezilla \
    gimp \
    gimp-plugin-registry \
    inkscape \
    audacity \
    obs-studio \
    vlc \
    vlc-plugin-video-splitter \
    libreoffice \
    libreoffice-gtk3 \
    libreoffice-l10n-pt-br \
    libreoffice-help-pt-br \
    git \
    curl \
    jq \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release \
    gnome-shell \
    gnome-tweaks \
    gnome-shell-extensions \
    gnome-shell-extension-manager

echo -e "\e[34m"
echo "#----------------------------------------------------------------------#"
echo "           Instalando codecs e suporte multimídia adicionais            "
echo "#----------------------------------------------------------------------#"
echo -e "\e[0m"

apt-get install -y \
    gstreamer1.0-libav \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    libavcodec-extra

#-----------------------------------------------------------------------------#
#                      Etapa 3: Adição de repositorios,                       #
#         Atualização de lista de pacotes e Atualização dos pacotes.          #
#-----------------------------------------------------------------------------#

echo -e "\e[34m"
echo "#----------------------------------------------------------------------#"
echo "     Adicionando novos repositorios, atualizando lista de pacotes e     "
echo "                          atualizando pacotes                           "
echo "#----------------------------------------------------------------------#"
echo -e "\e[0m"

if verifica_comando curl && verifica_comando gpg; then
    # Repositório Spotify: Adiciona chave GPG do repositório.
    curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg \
        | gpg --dearmor -o /etc/apt/trusted.gpg.d/spotify.gpg

    # Repositório Spotify: Adiciona repositório do Spotify.
    echo "deb https://repository.spotify.com stable non-free" \
        | tee /etc/apt/sources.list.d/spotify.list

    # Repositório Docker: Cria diretório seguro para chave.
    install -m 0755 -d /etc/apt/keyrings

    # Repositório Docker: Baixa a chave GPG do Docker
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Repositório Docker: Adiciona repositório do Docker (compatível com Ubuntu)
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Atualiza lista de pacotes e atualiza pacotes de programas se disponivel.
    apt-get update
    apt-get upgrade -y

    echo -e "\e[32m"
    echo "Repositórios adicionados."
    echo -e "\e[0m"
else
    echo -e "\e[33m"
    echo "Repositórios não adicionados devido à ausência de 'curl' ou 'gpg'."
    echo -e "\e[0m"
fi

#-----------------------------------------------------------------------------#
#             Etapa 4: Instalação de pacotes adicionais via APT.              #
#-----------------------------------------------------------------------------#

echo -e "\e[34m"
echo "#----------------------------------------------------------------------#"
echo "                Instalação de pacotes adicionais via APT                "
echo "#----------------------------------------------------------------------#"
echo -e "\e[0m"

apt-get install -y spotify-client

#-----------------------------------------------------------------------------#
#            Etapa 5: Ativando a detecção dos sensores de hardware            #
#                           para telemetria de uso.                           #
#-----------------------------------------------------------------------------#

echo -e "\e[34m"
echo "#----------------------------------------------------------------------#"
echo "    Ativando detecção de sensores de hardware para telemetria de uso    "
echo "#----------------------------------------------------------------------#"
echo -e "\e[0m"

set +e
if ! /usr/sbin/sensors-detect --auto; then
    echo -e "\e[33m"
    echo "Modo automático falhou. Iniciando modo interativo..."
    echo -e "\e[0m"
    echo ""
    sensors-detect
fi
set -e

#-----------------------------------------------------------------------------#
#              Etapa 6: Configuração de usuário e e-mail do GIT.              #
#-----------------------------------------------------------------------------#

echo -e "\e[34m"
echo "#----------------------------------------------------------------------#"
echo "              Configuração de usuário e e-mail para o GIT               "
echo "#----------------------------------------------------------------------#"
echo -e "\e[0m"

# Solicita o nome do usuário
read -p "Digite seu nome de usuário para o Git: " git_username

# Solicita o e-mail do usuário
read -p "Digite seu e-mail para o Git: " git_email

# Define as configurações globais do Git
git config --global user.name "$git_username"
git config --global user.email "$git_email"

# Confirmação
echo -e "\e[33m"
echo "#====================== Configurações aplicadas =======================#"
echo -e "\e[0m"

git config --global --get user.name
git config --global --get user.email

#-----------------------------------------------------------------------------#
#              Etapa 7: Instalação de pacotes via arquivos .deb.              #
#-----------------------------------------------------------------------------#

echo -e "\e[34m"
echo "#----------------------------------------------------------------------#"
echo "                Instalação dos pacotes via arquivos .deb                "
echo "#----------------------------------------------------------------------#"
echo -e "\e[0m"

shopt -s nullglob
arquivos_deb=("$PASTA_DEBS"/*.deb)

if [ ${#arquivos_deb[@]} -eq 0 ]; then
    echo -e "\e[31m"
    echo "Nenhum arquivo .deb encontrado, etapa ignorada."
    echo "Diretório lido: $PASTA_DEBS."
    echo -e "\e[0m"
else
    for pacote in "${arquivos_deb[@]}"; do
        echo "Instalando: $(basename "$pacote")"
        if ! apt-get install -y "$pacote"; then
            echo "Erro ao instalar o pacote: $(basename "$pacote")" >&2
        fi
    done
fi

echo -e "\e[34m"
echo "#=============== Resolvendo dependências (caso existam) ===============#"
echo -e "\e[0m"

# Faz a instalação de dependências caso haja necessidade.
apt-get -f install -y

#-----------------------------------------------------------------------------#
#                   Etapa 8: Instalação de extensões GNOME.                   #
#-----------------------------------------------------------------------------#

echo -e "\e[34m"
echo "#----------------------------------------------------------------------#"
echo "                    Instalação das extensões GNOME.                     "
echo "#----------------------------------------------------------------------#"
echo -e "\e[0m"

if verifica_comando jq && verifica_comando unzip; then
    EXT_SRC_DIR="$PASTA_EXTS"
    EXT_DST_DIR="/usr/share/gnome-shell/extensions"

    echo ""
    echo "instalando a partir de: $EXT_SRC_DIR"
    echo ""

    zip_count=$(find "$EXT_SRC_DIR" -maxdepth 1 -name '*.zip' | wc -l)

    if [ "$zip_count" -eq 0 ]; then
        echo -e "\e[31m"
        echo "Nenhum arquivo .zip encontrado, etapa ignorada."
        echo "Diretório lido: $EXT_SRC_DIR."
        echo -e "\e[0m"
    else
        # Processa todos os arquivos ZIP da pasta
        for ZIP in "$EXT_SRC_DIR"/*.zip; do

            echo "Processando arquivos ZIP das extensões: $(basename "$ZIP")"

            # Cria pasta temporária
            TMP_DIR=$(mktemp -d)

            # Extrai conteúdo para pasta temporária
            unzip -q "$ZIP" -d "$TMP_DIR"

            # Lê o UUID do metadata.json
            METADATA="$TMP_DIR/metadata.json"
            if [ ! -f "$METADATA" ]; then
                echo -e "\e[33m"
                echo "Arquivo metadata.json não encontrado em $(basename "$ZIP"), ignorando."
                echo -e "\e[0m"
                rm -rf "$TMP_DIR"
                continue
            fi

            UUID=$(jq -r '.uuid' "$METADATA")
            if [ -z "$UUID" ] || [ "$UUID" == "null" ]; then
                echo -e "\e[33m"
                echo "UUID inválido em $(basename "$ZIP"), ignorando."
                echo -e "\e[0m"
                rm -rf "$TMP_DIR"
                continue
            fi

            DEST="$EXT_DST_DIR/$UUID"
            echo "→ Instalando em: $DEST"
            mkdir -p "$DEST"
            cp -r "$TMP_DIR"/* "$DEST"

            # Corrige permissões
            chmod -R 755 "$DEST"
            chown -R root:root "$DEST"

            # Limpa pasta temporária
            rm -rf "$TMP_DIR"

            echo -e "\e[32m"
            echo "Extensão $UUID instalada com sucesso."
            echo -e "\e[0m"
        done

        echo -e "\e[32m"
        echo "Todas as extensões disponiveis para sua versão do GNOME foram instaladas"
        echo -e "\e[0m"
    fi
else
    echo -e "\e[33m"
    echo "Instalação das extensões GNOME ignorada por falta de dependências."
    echo -e "\e[0m"
fi

# Remove pacotes sem uso.
apt-get autoremove -y

echo -e "\e[34m"
echo "#=========================== FIM DO SCRIPT ============================#"
echo "|                 Instalação e configuração concluída!                 |"
echo "|                                                                      |"
echo "|     Apos reiniciar o sistema, ative manualmente as extensões via     |"
echo "|                  GNOME Tweaks ou Extension Manager.                  |"
echo "|                                                                      |"
echo "|                   Log completo da execução salvo!                    |"
echo "|         Execução finalizada em: $(date)         |"
echo "#======================================================================#"
echo -e "\e[0m"

#-----------------------------------------------------------------------------#
#           Etapa Final: Pergunta sobre reinicialização do sistema.           #
#-----------------------------------------------------------------------------#

# Verificação se o usuario deseja reiniciar o computador.
echo
read -p "Deseja reiniciar o computador agora? (S/N): " resposta

# Converte a resposta para minúsculas
resposta_normalizada=$(echo "$resposta" | tr '[:upper:]' '[:lower:]')

case "$resposta_normalizada" in
    s | sim)
        echo "Reiniciando o computador..."
        reboot
        ;;
    n | nao | não)
        echo "Você optou por não reiniciar agora."
        echo "Lembre-se de reiniciar manualmente para aplicar todas as alterações."
        ;;
    *)
        echo "Resposta inválida. Reinicialização cancelada. Reinicie manualmente depois."
        ;;
esac