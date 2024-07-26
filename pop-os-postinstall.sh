#!/usr/bin/env bash
#
# pos-os-postinstall.sh - Instalar e configura programas no Pop!_OS (22.04 LTS ou superior)
#
# Website:             rafaelchicovis.com
# Autor:               Rafael Chicovis
# Autor Original:      Dionatan Simioni (https://diolinux.com.br)
#
# ------------------------------------------------------------------------ #
#
# COMO USAR?
#   $ ./pos-os-postinstall.sh
#
# ----------------------------- VARIÁVEIS ----------------------------- #
set -e

##URLS DOWNLOAD
URL_GOOGLE_CHROME="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
URL_DOCKER="https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb"
URL_INSOMINIA="https://packages.konghq.com/public/insomnia-legacy/deb/ubuntu/pool/focal/main/i/in/insomnia_2023.5.8/insomnia_2023.5.8_amd64.deb"
URL_ANYDESK="https://anydesk.com/pt/downloads/thank-you?dv=deb_64"
URL_RQUICKSHARE="https://github.com/Martichou/rquickshare/releases/download/v0.10.2/r-quick-share-main_v0.10.2_glibc-2.39_amd64.deb"

##URLS SCRIPTS
URL_NVM="https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh"
URL_TOOBOX="https://raw.githubusercontent.com/nagygergo/jetbrains-toolbox-install/master/jetbrains-toolbox.sh"

##DIRETÓRIOS E ARQUIVOS
DIRETORIO_DOWNLOADS="$HOME/Downloads/programas"
FILE="/home/$USER/.config/gtk-3.0/bookmarks"

#CORES
VERMELHO='\e[1;91m'
VERDE='\e[1;92m'
SEM_COR='\e[0m'


#FUNÇÕES

# -------------------------------------------------------------------------------- #
# -------------------------------TESTES E REQUISITOS----------------------------------------- #

# Internet conectando?
testes_internet(){
if ! ping -c 1 8.8.8.8 -q &> /dev/null; then
  echo -e "${VERMELHO}[ERROR] - Seu computador não tem conexão com a Internet. Verifique a rede.${SEM_COR}"
  exit 1
else
  echo -e "${VERDE}[INFO] - Conexão com a Internet funcionando normalmente.${SEM_COR}"
fi
}

# ------------------------------------------------------------------------------ #

## Removendo travas eventuais do apt ##
travas_apt(){
  sudo rm /var/lib/dpkg/lock-frontend
  sudo rm /var/cache/apt/archives/lock
}

## Adicionando/Confirmando arquitetura de 32 bits ##
add_archi386(){
sudo dpkg --add-architecture i386
}

install_ngrok(){
   curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list && sudo apt update && sudo apt install ngrok
}

install_toolbox(){
  curl -fsSL $URL_TOOBOX | bash
}

install_nvm(){
  wget -qO- $URL_NVM | bash
}

install_node(){
  nvm install lts | nvm use lts
}

# Atualizando repositório e fazendo atualização do sistema
apt_update(){
  sudo apt update && sudo apt dist-upgrade -y
}

## Atualizando o repositório ##
just_apt_update(){
sudo apt update -y
}

##DEB SOFTWARES TO INSTALL

PROGRAMAS_PARA_INSTALAR=(
  vlc
  git
  folder-color
  wget
  ubuntu-restricted-extras
  v4l2loopback-utils
)

PROGRAMAS_FLATPAK_PARA_INSTALAR=(
  org.flameshot.Flameshot
  org.gnome.Boxes
  org.freedesktop.Piper
  org.telegram.desktop
  com.bitwarden.desktop
  com.obsproject.Studio
  org.mozilla.Thunderbird
  org.remmina.Remmina
  com.visualstudio.code
  com.github.IsmaelMartinez.teams_for_linux
  com.discordapp.Discord
  com.jetbrains.WebStorm
  com.jetbrains.Rider
  org.openrgb.OpenRGB
)

PROGRAMAS_WEBAPP_PARA_INSTALAR=(
  "WhatsApp,https://web.whatsapp.com"
  "YouTube,https://www.youtube.com"
  "YTMusic,https://music.youtube.com"
  "Notion,https://www.notion.so"
)

# ---------------------------------------------------------------------- #

## Install WebApp
create_desktop_entry() {
    local name="$1"
    local url="$2"
    local desktop_file="$HOME/.local/share/applications/${name}.desktop"

    cat << EOF > "$desktop_file"
[Desktop Entry]
Version=1.0
Name=$name
Exec=google-chrome --profile-directory=Default --app=$url
Icon=google-chrome
Terminal=false
Type=Application
Categories=Web;Internet;
EOF
    echo -e "${VERDE}[INFO] - Criado WebApp ${name} ${SEM_COR}"
}

install_webapp(){
  for site in "${PROGRAMAS_WEBAPP_PARA_INSTALAR[@]}"; do
      IFS=',' read -r name url <<< "$site"
      create_desktop_entry "$name" "$url"
  done
  echo -e "${VERDE}[INFO] - Instlado WebApps ${SEM_COR}"
}

## Download e instalaçao de programas debs ##
install_debs(){
  echo -e "${VERDE}[INFO] - Baixando pacotes .deb${SEM_COR}"

  ## Baixa os pacotes .deb
  mkdir "$DIRETORIO_DOWNLOADS"
  wget -c "$URL_GOOGLE_CHROME"       -P "$DIRETORIO_DOWNLOADS"
  wget -c "$URL_RQUICKSHARE" -P "$DIRETORIO_DOWNLOADS"
  wget -c "$URL_ANYDESK"              -P "$DIRETORIO_DOWNLOADS"
  wget -c "$URL_INSOMINIA"      -P "$DIRETORIO_DOWNLOADS"
  wget -c "$URL_DOCKER"      -P "$DIRETORIO_DOWNLOADS"

  ## Instalando pacotes .deb baixados na sessão anterior ##
  echo -e "${VERDE}[INFO] - Instalando pacotes .deb baixados${SEM_COR}"
  sudo dpkg -i $DIRETORIO_DOWNLOADS/*.deb

  # Instalar programas no apt
  echo -e "${VERDE}[INFO] - Instalando pacotes apt do repositório${SEM_COR}"

  for nome_do_programa in "${PROGRAMAS_PARA_INSTALAR[@]}"; do
    if ! dpkg -l | grep -q $nome_do_programa; then # Só instala se já não estiver instalado
      sudo apt install "$nome_do_programa" -y
    else
      echo "[INSTALADO] - $nome_do_programa"
    fi
  done
}

## Instalando pacotes Flatpak ##
install_flatpaks(){
  echo -e "${VERDE}[INFO] - Instalando pacotes flatpak${SEM_COR}"

  for id_flatpak in "${PROGRAMAS_FLATPAK_PARA_INSTALAR[@]}"; do
    flatpak install flathub $id_flatpak -y
  done
}

# -------------------------------------------------------------------------- #
# ----------------------------- PÓS-INSTALAÇÃO ----------------------------- #


## Finalização, atualização e limpeza##

system_clean(){
  apt_update -y
  flatpak update -y
  sudo apt autoclean -y
  sudo apt autoremove -y
  nautilus -q
}

# -------------------------------------------------------------------------- #
# ----------------------------- CONFIGS EXTRAS ----------------------------- #

#Cria pastas para produtividade no nautilus
extra_config(){

  mkdir /home/$USER/TEMP
  mkdir /home/$USER/AppImage

  #Adiciona atalhos ao Nautilus
  if test -f "$FILE"; then
      echo "$FILE já existe"
  else
      echo "$FILE não existe, criando..."
      touch /home/$USER/.config/gkt-3.0/bookmarks
  fi
  echo "file:///home/$USER/AppImage" >> $FILE
  echo "file:///home/$USER/TEMP 🕖 TEMP" >> $FILE
}

# -------------------------------------------------------------------------------- #
# -------------------------------EXECUÇÃO----------------------------------------- #

travas_apt
testes_internet
travas_apt
apt_update
travas_apt
add_archi386
just_apt_update
install_debs
install_flatpaks
install_webapp
install_ngrok
install_toolbox
install_node
install_nvm
extra_config
apt_update
system_clean

## finalização

  echo -e "${VERDE}[INFO] - Script finalizado, instalação concluída! :)${SEM_COR}"
