#!/bin/bash
# =============================================================================
# One-command MinIO installer for RHEL 9 & RHEL 8 (latest stable version)
# Runs as systemd service → auto-start, secure, ready for S3 clients
# =============================================================================

set -euo pipefail

MINIO_USER="minio"
MINIO_DATA="/var/lib/minio"
MINIO_CONFIG="/etc/minio"
MINIO_PORT="9000"
MINIO_CONSOLE_PORT="9001"

# Change these only if you know what you're doing
MINIO_ACCESS_KEY="minioadmin"
MINIO_SECRET_KEY="minioadmin123456"   # ← CHANGE THIS IN PRODUCTION!

echo "Installing latest MinIO on RHEL..."

# 1. Create minio system user
id -u $MINIO_USER &>/dev/null || useradd -r -m -s /sbin/nologin $MINIO_USER

# 2. Download latest MinIO binary (always up-to-date)
wget -qO /usr/local/bin/minio https://dl.min.io/server/minio/release/linux-amd64/minio
chmod +x /usr/local/bin/minio

# 3. Download MinIO client (mc) – optional but very useful
wget -qO /usr/local/bin/mc https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x /usr/local/bin/mc

# 4. Create data and config directories
mkdir -p "$MINIO_DATA" "$MINIO_CONFIG"
chown -R $MINIO_USER:$MINIO_USER "$MINIO_DATA" "$MINIO_CONFIG"

# 5. Create default environment file
cat > /etc/default/minio <<EOF
MINIO_ROOT_USER=$MINIO_ACCESS_KEY
MINIO_ROOT_PASSWORD=$MINIO_SECRET_KEY
MINIO_VOLUMES="$MINIO_DATA"
MINIO_OPTS="--address :$MINIO_PORT --console-address :$MINIO_CONSOLE_PORT"
EOF

# 6. Create systemd service
cat > /etc/systemd/system/minio.service <<EOF
[Unit]
Description=MinIO Object Storage
After=network.target

[Service]
Type=simple
User=$MINIO_USER
EnvironmentFile=/etc/default/minio
ExecStart=/usr/local/bin/minio server \$MINIO_OPTS \$MINIO_VOLUMES
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# 7. Enable and start MinIO
systemctl daemon-reload
systemctl enable minio
systemctl start minio

# 8. Open firewall ports
if systemctl is-active --quiet firewalld; then
    firewall-cmd --permanent --add-port=${MINIO_PORT}/tcp
    firewall-cmd --permanent --add-port=${MINIO_CONSOLE_PORT}/tcp
    firewall-cmd --reload
fi

# 9. Final output
IP=$(hostname -I | awk '{print $1}')

clear
echo "============================================================"
echo " MinIO is successfully installed and running!"
echo "============================================================"
echo ""
echo "Web Console (Browser UI):"
echo "   http://$IP:$MINIO_CONSOLE_PORT"
echo "   Login: $MINIO_ACCESS_KEY"
echo "   Password: $MINIO_SECRET_KEY"
echo ""
echo "S3 Endpoint:"
echo "   http://$IP:$MINIO_PORT"
echo ""
echo "Quick test with MinIO Client (mc):"
echo "   mc alias set myminio http://$IP:$MINIO_PORT $MINIO_ACCESS_KEY $MINIO_SECRET_KEY"
echo "   mc mb myminio/mybucket"
echo "   mc ls myminio"
echo ""
echo "Service commands:"
echo "   systemctl status minio"
echo "   journalctl -u minio -f"
echo "============================================================"

exit 0
