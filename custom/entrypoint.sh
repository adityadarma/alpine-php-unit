#!/bin/sh
set -e  # Exit if error

# Auto-calculate process limits from container/host resources
_mem_limit=$(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo "max")
if [ "$_mem_limit" = "max" ] || [ "$_mem_limit" -gt 9000000000000 ] 2>/dev/null; then
    _ram_mb=$(awk '/MemTotal/{printf "%d",$2/1024}' /proc/meminfo)
else
    _ram_mb=$(( _mem_limit / 1024 / 1024 ))
fi
_cpu=$(nproc)
_worker_mem=${PHP_WORKER_MEMORY:-32}

_max=$(( (_ram_mb * 80 / 100) / _worker_mem ))
[ $_max -gt $(( _cpu * 8 )) ] && _max=$(( _cpu * 8 ))
[ $_max -lt 5   ] && _max=5
[ $_max -gt 200 ] && _max=200
_spare=$(( _max * 40 / 100 ))
[ $_spare -lt 2 ] && _spare=2

export UNIT_MAX_PROCESSES=${UNIT_MAX_PROCESSES:-$_max}
export UNIT_SPARE_PROCESSES=${UNIT_SPARE_PROCESSES:-$_spare}

# Change file supervisord
envsubst < /etc/supervisord.conf.template > /etc/supervisord.conf

# Run execute supervisord command
exec /usr/bin/supervisord -c /etc/supervisord.conf