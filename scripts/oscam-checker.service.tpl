[Unit]
Description=Oscam Checker Service
After=network.target

[Service]
Type=simple
ExecStart=/opt/oscam-agent/oscam-checker/oscam-checker
WorkingDirectory=/opt/oscam-agent/oscam-checker
EnvironmentFile=/opt/oscam-agent/oscam-checker/.env
Restart=always
RestartSec=3
User=root

[Install]
WantedBy=multi-user.target
