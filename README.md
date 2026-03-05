# Docker Alpine Linux - Lightweight & High Performance PHP Web Application

A Docker image based on Alpine Linux equipped with **NGINX Unit** and **Supervisord**. Highly optimized for PHP applications (including frameworks like Laravel) aiming for ultra-high performance and layered security.

## 🚀 Key Features

- **Ultra Fast**: Powered by NGINX Unit + OPcache JIT. Proven to handle up to **15,000+ Requests Per Second** in benchmarks.
- **Auto-Scaling Workers**: Automatically detects container RAM (cgroup v2 / host meminfo) and CPU limits to calculate the most optimal `max` and `spare` PHP workers without any manual configuration.
- **100% Non-Root Runtime**: After the initial secure build-time configuration, all running processes (Supervisord, NGINX Unit, and PHP Workers) run entirely as an *unprivileged user* (`unit`) for maximum security.
- **Smart Build System**: The NGINX Unit configuration is natively *baked* into the image's state file during *build time*, granting instant startup without the overhead of complex initialization scripts.
- **Separated Clean Logs**: NGINX Unit logs and Laravel worker logs (Queue & Schedule) are cleanly segregated in `/var/log` for frictionless debugging.

## 📦 Environment Variables

Easily modify your application's behavior via `docker-compose.yml` or at *runtime*:

| Variable | Default | Description |
|---|---|---|
| `VALIDATE_TIMESTAMPS` | `1` | Set to `0` for maximum *production* performance (OPcache will never re-check SSD/HDD file modifications). |
| `REVALIDATE_FREQ` | `2` | Interval in seconds for OPcache to check files on disk (only active if validate_timestamps=1). |
| `TIMEZONE` | `UTC` | The default application timezone. |
| `WITH_QUEUE` | `false` | Pass `true` to automatically run `artisan queue:work` via Supervisord continuously. |
| `WITH_SCHEDULE` | `false` | Pass `true` to automatically run `artisan schedule:work` via Supervisord continuously. |
| `PHP_WORKER_MEMORY` | `32` | Estimated RAM footprint per PHP worker in MB. Used by the Auto-Scaling feature. (Default is 32MB. For Laravel, `64` or `128` is recommended). |
| `UNIT_MAX_PROCESSES` | *Auto* | Manual override for the maximum allowed PHP worker processes (Optional). |
| `UNIT_SPARE_PROCESSES` | *Auto* | Manual override for the standby idle PHP workers kept in RAM (Optional). |

## 🛠 Building the custom Image

The image can be dynamically built for your specific Alpine and PHP versions using `ARG`.

**Example Build for PHP 8.4:**
```bash
docker build \
  --build-arg="ALPINE_VERSION=3.21" \
  --build-arg="PHP_VERSION=8.4" \
  --build-arg="PHP_NUMBER=84" \
  -t adityadarma/alpine-php-unit:8.4 \
  -f Dockerfile .
```

**Example Build for PHP 7.4:**
*(Fully supported utilizing the same secure mechanisms)*
```bash
docker build \
  --build-arg="ALPINE_VERSION=3.15" \
  --build-arg="PHP_VERSION=7.4" \
  --build-arg="PHP_NUMBER=7" \
  -t adityadarma/alpine-php-unit:7.4 \
  -f Dockerfile .
```

**Build with the 'mini' variant (minimum required PHP modules):**
```bash
docker build \
  --build-arg="ALPINE_VERSION=3.21" \
  --build-arg="PHP_VERSION=8.4" \
  --build-arg="PHP_NUMBER=84" \
  --build-arg="VARIANT=mini" \
  -t adityadarma/alpine-php-unit:8.4-mini \
  -f Dockerfile .
```

### Push to Docker Hub
```bash
docker push adityadarma/alpine-php-unit:8.1
docker push adityadarma/alpine-php-unit:8.2
docker push adityadarma/alpine-php-unit:8.3
docker push adityadarma/alpine-php-unit:8.4
```

## 🔍 Log Directories (Mountable Volumes)

If external log persistence is required, map Docker volumes to these paths:
- `/var/log/unit/unit.log` - NGINX Unit core and application activity/error logs.
- `/var/log/supervisor/` - Contains separated logs specifically for Supervisor, Laravel Queue (`queue.log`, `queue-error.log`), and Laravel Schedule (`schedule.log`).

## 🧰 Debugging Cheatsheet

Live view of the NGINX Unit worker status & memory state:
```bash
docker exec <container_name> curl --unix-socket /run/control.unit.sock http://localhost/status
```

View the current Auto-scaling calculations and overrides applied:
```bash
docker exec <container_name> env | grep -E "UNIT|PHP"
```