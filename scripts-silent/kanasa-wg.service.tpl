[Unit]
Description=Kanasa WireGuard Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/kanasa-wg
ExecStart=/opt/kanasa-wg/kanasa-wg
EnvironmentFile=/opt/kanasa-wg/.env
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target

