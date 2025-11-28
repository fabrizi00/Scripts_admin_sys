#!/bin/bash

# ===== VARIABLES =====
REPO="/srv/repo"
SRC_PATH="$1"
IP=$(hostname -I | awk '{ print $1 }')

# ===== CRÉATION DU RÉPERTOIRE =====
mkdir -p $REPO

# ===== CONFIGURATION APACHE2 =====
cat >> /etc/apache2/sites-available/repo.conf << EOF
<VirtualHost *:80>
    ServerName repo.local
    ServerAlias repo

    DocumentRoot $REPO

    <Directory $REPO>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

</VirtualHost>
EOF

a2ensite repo.conf
systemctl reload apache2

# ===== COPIE DES FICHIERS .DEB =====
if [ -f "$SRC_PATH" ]; then
    cp "$SRC_PATH" "$REPO_PATH/"
elif [ -d "$SRC_PATH" ]; then
    cp "$SRC_PATH"/*.deb "$REPO_PATH/"
else
    echo "Argument invalide"
fi

# ===== GÉNÉRATION DU FICHIER PACKAGES.GZ =====
cd "$REPO"
dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz

systemctl reload apache2

# ===== CRÉATION DU FICHIER DE CONFIGURATION APT =====
cat > repo.list << EOF
deb [trusted=yes] http://$IP ./"
EOF

echo "copier repo.list dans /etc/apt/sources.list.d/monrepo.list "