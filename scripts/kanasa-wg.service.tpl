[Unit]
Description=Kanasa WireGuard Execution Service
After=network.target

[Service]
Type=simple
ExecStart=/opt/kanasa-wg/kanasa-wg
WorkingDirectory=/opt/kanasa-wg
EnvironmentFile=-/opt/kanasa-wg/.env
Restart=always
RestartSec=3
User=root

[Install]
WantedBy=multi-user.target
