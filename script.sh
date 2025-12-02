#!/bin/bash

# variable pour les couleurs
RED="\e[31m"
GREEN="\e[32m"
RESET="\e[0m"

# installation paquets
echo -e "${GREEN}Mise à jour et installation...${RESET}"
apt-get update -y
apt-get install -y git nginx

# prompt infos
echo ""
read -p "Nom du dossier du site (ex: mon_site) : " SITE
read -p "Source ? (1: GitHub, 2: Site vide) : " CHOIX

# Variable pour le chemin du site
DOSSIER="/var/www/html/$SITE"

# choix
if [ "$CHOIX" == "1" ]; then
    # Option GITHUB
    read -p "Lien HTTPS du repo GitHub : " URL_GIT
    
    # On supprime le dossier pour éviter erreur
    rm -rf "$DOSSIER"
    
    echo "Clonage de GitHub..."
    git clone "$URL_GIT" "$DOSSIER"

    #  gestion cron (mise à jour auto du site)
    echo "Activation de la mise à jour automatique"
    CRON_FILE="/etc/cron.d/update_$SITE"
    
    # Explication : 
    # 1. */60 : Se lance toutes les 60 minutes 
    # 2. sleep $((RANDOM % 300))  Attend un temps aléatoire entre 0 et 5 min avant de lancer.
    # 3. git fetch & reset  Force la version GitHub exacte.
    
    echo "*/60 * * * * root sleep \$((RANDOM \% 300)) && cd $DOSSIER && git fetch --all && git reset --hard origin/HEAD && chown -R www-data:www-data $DOSSIER" > "$CRON_FILE"
else
    # Option SITE VIDE partir de 0 
    echo "Création d'un site local..."
    mkdir -p "$DOSSIER"
    # création d'un index.html de test
    echo "<h1>Site Local TEST $SITE</h1>" > "$DOSSIER/index.html"
fi

# configuration nginx

# gestions droits
chown -R www-data:www-data "$DOSSIER"
chmod -R 755 "$DOSSIER"

#création fichier de config nginx
CONFIG="/etc/nginx/sites-available/$SITE"

# création de la configurations du site NGINX
cat > "$CONFIG" <<EOF
server {
    listen 80;
    root $DOSSIER;
    index index.html;
    server_name _;
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# activation du site
ln -sf "$CONFIG" /etc/nginx/sites-enabled/$SITE

# supression du site par défaut de Nginx pour éviter les conflits
rm -f /etc/nginx/sites-enabled/default

# rédemarrage du service NGINX
echo -e "${GREEN}Redémarrage de Nginx...${RESET}"
systemctl reload nginx

echo ""
echo -e "${GREEN}Terminé, le site est prêt.${RESET}"
echo "Dossier : $DOSSIER"
if [ "$CHOIX" == "1" ]; then
    echo "Mise à jour auto : ACTIVE (toutes les 30 min)"
fi
