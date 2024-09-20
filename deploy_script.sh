#!/bin/bash

# Função para verificar se o comando anterior foi bem-sucedido
check_error() {
    if [[ $? -ne 0 ]]; then
        echo "Erro na etapa: $1"
        exit 1
    else
        echo "Etapa concluída com sucesso: $1"
    fi
}

echo "Iniciando deploy da skin"


# CASO ACONTEÇA ALGUM PROBLEMA DE ERROR 500, VERIFICAR SE O CONTEÚDO DA SKIN FOI CARREGADO DENTRO 
# CORRETAMENTE DENTRO DE /opt/zimbra/jetty/webapps/zimbra/skins/Esmeralda


# Removendo arquivo temporário, se existir
if [[ -f /tmp/Esmeralda.zip ]]; then
    sudo rm /tmp/Esmeralda.zip
fi


if [[ -d /tmp/Esmeralda ]]; then
        sudo rm -rf /tmp/Esmeralda
fi

if [[ -f /tmp/main.zip ]]; then
        sudo rm /tmp/main.zip
fi

if [[ -d /tmp/Esmeralda-main ]]; then
        sudo rm -rf /tmp/Esmeralda-main
fi


# Fazer o download do repositório do template do GitHub
cd /tmp
sudo git clone https://github.com/astatonn/Esmeralda
check_error "Download do template do GitHub"

sudo zip -r /tmp/Esmeralda.zip Esmeralda

# Alterar a propriedade do novo arquivo zip para o usuário e grupo zimbra
sudo chown zimbra:zimbra /tmp/Esmeralda.zip
check_error "Alteração de propriedade do arquivo"

# Modificar o arquivo zmskindeploy para remover a linha +ZimbraInstalledSkin
sudo sed -i '/+ZimbraInstalledSkin/d' /opt/zimbra/bin/zmskindeploy
check_error "Modificação do arquivo zmskindeploy"

# Substituir 'harmony' por 'zextras' no arquivo zimbra.web.xml.in
sudo sed -i 's/harmony/zextras/g' /opt/zimbra/jetty/etc/zimbra.web.xml.in
check_error "Substituição de 'harmony' por 'zextras'"

# Executar operações como usuário zimbra
su - zimbra -c "zmprov mcf +zimbraInstalledSkin Esmeralda"
check_error "Adicionando skin Esmeralda"

# Executar zmskindeploy com o arquivo corrigido
su - zimbra -c "zmskindeploy /tmp/Esmeralda.zip"
check_error "Executando zmskindeploy com o arquivo corrigido"

# Reiniciar o serviço zmmailboxd
su - zimbra -c "zmmailboxdctl restart"
check_error "Reiniciando o serviço zmmailboxd"

# Limpar o cache de skins
su - zimbra -c "zmprov fc skin"
check_error "Limpando o cache de skins"

# Remover os arquivos temporários
sudo rm -rf /tmp/Esmeralda_temp
check_error "Limpando arquivos temporários"

echo "Operações com usuário zimbra concluídas com sucesso"

echo "Iniciando alteração de cores"
css_file="/opt/zimbra/jetty/webapps/zimbra/modern/clients/default/palette.css"

# Verifica se o arquivo existe
if [[ ! -f $css_file ]]; then
    echo "O arquivo $css_file não foi encontrado."
    exit 1
else
    echo "Arquivo CSS encontrado."
fi

# Atualiza as cores
declare -A colors=(
    ["--brand-primary-50"]="--brand-primary-50: #d9edf6;"
    ["--brand-primary-100"]="--brand-primary-100: #b3dbec;"
    ["--brand-primary-200"]="--brand-primary-200: #80c4e0;"
    ["--brand-primary-300"]="--brand-primary-300: #4dacd4;"
    ["--brand-primary-400"]="--brand-primary-400: #1f96c8;"
    ["--brand-primary-500"]="--brand-primary-500: #556b2f;"
    ["--brand-primary-600"]="--brand-primary-600: #0076a8;"
)

for color in "${!colors[@]}"; do
    sudo sed -i "s/^$color.*/${colors[$color]}/" "$css_file"
done
check_error "Atualização de cores no arquivo CSS"

# Atualiza o arquivo JSON de configuração
config_file="/opt/zimbra/jetty/webapps/zimbra/modern/clients/default/config.json"
if [[ ! -f $config_file ]]; then
    echo "O arquivo $config_file não foi encontrado."
    exit 1
else
    echo "Arquivo JSON encontrado."
fi

# Atualiza os valores no arquivo JSON
sudo sed -i 's/"title":.*/"title": "Correio Eletrônico Funcional",/' "$config_file"
sudo sed -i 's/"version":.*/"version": "2",/' "$config_file"
sudo sed -i 's/"clientName":.*/"clientName": "Correio Eletrônico Funcional",/' "$config_file"
sudo sed -i 's/"svgIcon":.*/"svgIcon": "#556b2f",/' "$config_file"
sudo sed -i 's/"brandPrimary":.*/"brandPrimary": "#556b2f",/' "$config_file"
sudo sed -i 's/"brandSecondary":.*/"brandSecondary": "#198f00",/' "$config_file"
sudo sed -i 's/"brandTertiary":.*/"brandTertiary": "#a4b35c",/' "$config_file"
sudo sed -i 's/"brandSuccess":.*/"brandSuccess": "#007a3e",/' "$config_file"
sudo sed -i 's/"brandInfo":.*/"brandInfo": "#5bc0de",/' "$config_file"
sudo sed -i 's/"brandWarning":.*/"brandWarning": "#ffb81c",/' "$config_file"
sudo sed -i 's/"brandDanger":.*/"brandDanger": "#cf2a2a",/' "$config_file"
sudo sed -i 's/"backgroundColor":.*/"backgroundColor": "#556b2f",/' "$config_file"
sudo sed -i 's/"themeColor":.*/"themeColor": "#556b2f"/' "$config_file"
check_error "Atualização do arquivo JSON"

# Baixar e mover ícones
download_and_move_icon() {
    sudo wget $1 -P /tmp
    check_error "Download do arquivo $1"
    sudo mv /tmp/$2 /opt/zimbra/jetty/webapps/zimbra/modern/clients/default/assets/
    check_error "Movendo $2 para o diretório de assets"
}

download_and_move_icon "https://raw.githubusercontent.com/astatonn/assetszimbra/refs/heads/main/favicon.ico" "favicon.ico"
download_and_move_icon "https://raw.githubusercontent.com/astatonn/assetszimbra/refs/heads/main/icon.ico" "icon.ico"
download_and_move_icon "https://raw.githubusercontent.com/astatonn/assetszimbra/refs/heads/main/icon.png" "icon.png"
download_and_move_icon "https://github.com/astatonn/assetszimbra/blob/main/logo.png" "logo.png"
download_and_move_icon "https://raw.githubusercontent.com/astatonn/assetszimbra/b917fde95d9cdae4fe078408995f21fd9cdea626/logo.svg" "logo.svg"
download_and_move_icon "https://raw.githubusercontent.com/astatonn/assetszimbra/5faf3fe4f17e7e2eaba4268c6136247833318774/icon.svg" "icon.svg"
# download_and_move_icon "https://raw.githubusercontent.com/astatonn/assetszimbra/5faf3fe4f17e7e2eaba4268c6136247833318774/Coat_of_arms_of_the_Brazilian_Army.svg" "jitsi.svg"

# Copiar o ícone para a pasta de ícones PWA
sudo cp /opt/zimbra/jetty/webapps/zimbra/modern/clients/default/assets/icon.svg /opt/zimbra/jetty/webapps/zimbra/modern/clients/default/pwa/icons/icon_300x300.svg
check_error "Cópia do ícone PWA"

# Instalar zimlet Jitsi
#sudo apt install zimbra-zimlet-jitsi -y
#check_error "Instalação do Zimlet Jitsi"

# Caminho do arquivo de configuração
#CONFIG_FILE="/opt/zimbra/zimlets-deployed/zimbra-zimlet-jitsi/config_template.xml"
# Substituir o valor da propriedade jitsiUrl
#sed -i 's|<property name="jitsiUrl">.*</property>|<property name="jitsiUrl">https://meetlogin.51ct.eb.mil.br</property>|' "$CONFIG_FILE"
#check_error "Configuração do arquivo xml"

# Entrar como usuário zimbra e aplicar a nova configuração
#su - zimbra -c "zmzimletctl configure $CONFIG_FILE"

# Atualizando ícone para criação de chamada
#sudo base64 -w 0 /opt/zimbra/jetty/webapps/zimbra/modern/clients/default/assets/jitsi.svg > /tmp/svg_base.txt
#check_error "Conversão ícone para base64"

# Armazene o novo valor do SVG em uma variável
#novo_svg=$(<svg_base64.txt)

# Use o sed para substituir o valor da variável T no arquivo index.js
#sudo sed -i 's|var T = "data:image/svg+xml;base64,[^"]*"|var T = "data:image/svg+xml;base64,'"${novo_svg}"'"|' opt/zimbra/zimlets-deployed/zimbra-zimlet-jitsi/index.js
#check_error "atualização do ícone base64"


# INSTALAÇÃO DO NOVO ZIMLET
# O ANTERIOR NÃO SERÁ UTILIZADO NO PRIMEIRO DEPLOY

# COPIANDO PROJETO ATUALIZADO
sudo cd /tmp
sudo git clone https://github.com/astatonn/zimlet_reu.git
sudo mv zimlet_reu/ zimbra-pensomeet-cal-modern
check_error "Download do Zimlet"

# DEPLOY DO ZIMLET
su - zimbra -c "zmzimletctl deploy /tmp/zimbra-pensomeet-cal-modern"
su - zimbra -c "zmmailboxdctl restart"
su - zimbra -c "zmprov fc all"
check_error "instalação do zimlet concluída"



# Saída do script
exit 0
