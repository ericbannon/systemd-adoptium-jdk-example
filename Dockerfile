FROM cgr.dev/chainguard-private/adoptium-jdk:latest-dev

USER root

RUN apk add --no-cache \
    systemd \
    systemd-init \
    systemd-systemctl \
    dbus \
    python-3

RUN mkdir -p \
    /app \
    /etc/systemd/system \
    /usr/share/demo

RUN echo "hello from process 1" > /usr/share/demo/index.html

RUN cat > /app/python-api.py <<'EOF'
import http.server
import socketserver

PORT = 9000

with socketserver.TCPServer(("", PORT), http.server.SimpleHTTPRequestHandler) as httpd:
    print(f"Python API running on {PORT}", flush=True)
    httpd.serve_forever()
EOF

RUN cat > /app/java-loop.sh <<'EOF'
#!/bin/sh
while true; do
  echo "Java process alive: $(java -version 2>&1 | head -n 1)"
  sleep 30
done
EOF

RUN chmod +x /app/java-loop.sh

RUN cat > /etc/systemd/system/http-test.service <<'EOF'
[Unit]
Description=HTTP test server
After=basic.target

[Service]
ExecStart=/usr/bin/python3 -m http.server 8080 --directory /usr/share/demo
Restart=always

[Install]
WantedBy=multi-user.target
EOF

RUN cat > /etc/systemd/system/python-api.service <<'EOF'
[Unit]
Description=Python API server
After=basic.target

[Service]
ExecStart=/usr/bin/python3 /app/python-api.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

RUN cat > /etc/systemd/system/java-test.service <<'EOF'
[Unit]
Description=Java test loop
After=basic.target

[Service]
ExecStart=/app/java-loop.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

RUN systemctl enable \
    http-test.service \
    python-api.service \
    java-test.service

RUN systemctl mask \
    systemd-journald.service \
    systemd-journal-flush.service \
    systemd-networkd.service \
    systemd-resolved.service \
    proc-sys-fs-binfmt_misc.automount \
    getty.target \
    console-getty.service || true

STOPSIGNAL SIGRTMIN+3

CMD ["/sbin/init"]