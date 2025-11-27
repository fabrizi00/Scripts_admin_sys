#!/bin/bash

# Script de vérification des quotas (exécuté quotidiennement)
cat > /tmp/check_quota.sh << 'EOF'
#!/bin/bash
for PARTITION in /data /home; do
    USER=$(repquota -aug "$PARTITION" | awk '/\+\-/ { print \$1 }')
    if [ -n "$USER" ]; then
        mail -s "Quota soft dépassé sur $PARTITION" admin@gmail.com "$USER@gmail.com"
    fi
done
EOF

# Script principal (exécuté une fois par semaine)
cat > /tmp/weekly_quota.sh << 'EOF'
#!/bin/bash
for PARTITION in /data /home; do
    USER=$(repquota -aug "$PARTITION" | awk '/\+\-/ { print \$1 }')
    if [ -n "$USER" ]; then
        crontab /tmp/quota_daily
        mail -s "Quota soft dépassé sur $PARTITION" admin@gmail.com "$USER@gmail.com"
        exit 0
    fi
done
crontab /tmp/quota_weekly
EOF

chmod +x /tmp/check_quota.sh
chmod +x /tmp/weekly_quota.sh

# Cron hebdomadaire seul
cat > /tmp/quota_weekly << 'EOF'
0 0 * * 1 /tmp/weekly_quota.sh
EOF

# Cron hebdomadaire + quotidien
cat > /tmp/quota_daily << 'EOF'
0 0 * * 1 /tmp/weekly_quota.sh
0 0 * * * /tmp/check_quota.sh
EOF

crontab /tmp/quota_weekly
