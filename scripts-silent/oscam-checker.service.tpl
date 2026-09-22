[Unit]
Description=Oscam Checker Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/oscam-agent/oscam-checker
ExecStart=/opt/oscam-agent/oscam-checker/oscam-checker
EnvironmentFile=/opt/oscam-agent/oscam-checker/.env
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
