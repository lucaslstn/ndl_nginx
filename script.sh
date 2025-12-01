apt update -y
apt upgrade -y
apt autoremove -y
apt install -y sudo wget curl nginx
read -p "Nom du site (ex: monsite) : " SITE
SITE_DIR="/var/www/html/$SITE"
mkdir -p "$SITE_DIR"
CONF="/etc/nginx/sites-available/$SITE"
cat > "$CONF" <<EOF
server {
    listen 80;
    server_name _;
    root $SITE_DIR;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

ln -s "$CONF" /etc/nginx/sites-enabled/$SITE
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
echo "Le site '$SITE' a été créé dans $SITE_DIR et est actif."
