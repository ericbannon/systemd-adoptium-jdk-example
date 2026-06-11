FROM cgr.dev/chainguard-private/adoptium-jdk:latest-dev

USER root

RUN apk add --no-cache \
    systemd \
    systemd-init \
    systemd-systemctl \
    nginx \
    python-3

RUN mkdir -p /app /etc/systemd/system

RUN cat > /app/server.py <<'EOF'
import http.server
import socketserver

PORT = 9000
with socketserver.TCPServer(("", PORT), http.server.SimpleHTTPRequestHandler) as httpd:
    print(f"Python server running on {PORT}")
    httpd.serve_forever()
EOF

RUN cat > /app/java-loop.sh <<'EOF'
#!/bin/sh
while true; do
  echo "Java placeholder running: $(java -version 2>&1 | head -n 1)"
  sleep 30
done
EOF
RUN chmod +x /app/java-loop.sh

RUN cat > /etc/systemd/system/python-test.service <<'EOF'
[Unit]
Description=Python test server

[Service]
ExecStart=/usr/bin/python3 /app/server.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

RUN cat > /etc/systemd/system/java-test.service <<'EOF'
[Unit]
Description=Java test loop

[Service]
ExecStart=/app/java-loop.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

RUN cat > /etc/systemd/system/nginx-test.service <<'EOF'
[Unit]
Description=Nginx test

[Service]
ExecStart=/usr/sbin/nginx -g "daemon off;"
Restart=always

[Install]
WantedBy=multi-user.target
EOF

RUN systemctl enable python-test.service java-test.service nginx-test.service

STOPSIGNAL SIGRTMIN+3

CMD ["/sbin/init"]
