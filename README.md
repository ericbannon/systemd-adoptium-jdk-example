# systemd-adoptium-jdk-example

Chainguard Adoptium JDK image plus systemd packages. systemd can run multiple processes in the container — the demo successfully stars an HTTP server, a Java process, and a Python API service.

NOTE:  systemd also tries to bring along VM-style units/sockets like journald, networkd, resolved, oomd, cgroups, etc.

```
docker build -t adoptium-systemd-test .

docker run --rm -it \
  --privileged \
  --tmpfs /run \
  --tmpfs /run/lock \
  --tmpfs /tmp \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  -p 8081:80 \
  -p 9001:9000 \
  adoptium-systemd-test
```