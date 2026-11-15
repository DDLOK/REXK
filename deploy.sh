#!/usr/bin/env bash
# ============================================================
# deploy.sh - one-shot fivem install on altare Debian container
# usage:   bash deploy.sh                 (first time)
#          bash deploy.sh update          (pull repo + restart)
#          bash deploy.sh stop            (stop server)
#          bash deploy.sh logs            (tail live logs)
# ============================================================
set -e

ROOT="$HOME/fxs"
ALPINE="$ROOT/alpine"
DATA="$ROOT/server-data"
REPO="https://github.com/andreh901300/REXK.git"
SCREEN_NAME="fxs"
LOG="$ROOT/fxs.log"

API="https://changelogs-live.fivem.net/api/changelog/versions/win32/server"

ensure_deps() {
    if ! command -v screen >/dev/null || ! command -v git >/dev/null || ! command -v curl >/dev/null; then
        echo "[*] installing deps (sudo prompt may appear)..."
        (sudo apt-get update -y && sudo apt-get install -y curl git screen xz-utils tar ca-certificates) || \
        (apt-get update -y && apt-get install -y curl git screen xz-utils tar ca-certificates)
    fi
}

fetch_fxserver() {
    mkdir -p "$ROOT"
    local url
    url=$(curl -fsSL "$API" | python3 -c "import sys,json,re; d=json.load(sys.stdin); u=d['recommended_download']; m=re.search(r'(\d+-[a-f0-9]+)',u); print('https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/'+m.group(1)+'/fx.tar.xz')")
    echo "[*] downloading FXServer linux: $url"
    curl -fsSL "$url" -o /tmp/fx.tar.xz
    # tarball contains its own top-level 'alpine/' dir, so extract into ROOT
    rm -rf "$ALPINE"
    tar -xJf /tmp/fx.tar.xz -C "$ROOT"
    rm /tmp/fx.tar.xz
    # safety: if the layout wrapped it (older builds), unwrap
    if [ -d "$ALPINE/alpine" ] && [ ! -f "$ALPINE/opt/cfx-server/FXServer" ]; then
        mv "$ALPINE/alpine"/* "$ALPINE/"
        rmdir "$ALPINE/alpine"
    fi
    echo "[+] FXServer extracted to $ALPINE"
}

sync_repo() {
    if [ ! -d "$DATA/.git" ]; then
        echo "[*] cloning REXK into $DATA ..."
        git clone "$REPO" "$DATA"
    else
        echo "[*] pulling latest REXK..."
        (cd "$DATA" && git pull --ff-only)
    fi
}

inject_key() {
    if [ -n "$LICENSE_KEY" ]; then
        echo "[*] injecting LICENSE_KEY into server.cfg"
        sed -i -E "s|^#?\s*sv_licenseKey.*|sv_licenseKey \"$LICENSE_KEY\"|" "$DATA/server.cfg"
    fi
    # prefer FIVEM_PORT; ignore altare's auto-exported SERVER_PORT (which is SSH)
    local PORT="${FIVEM_PORT:-${SERVER_PORT:-}}"
    # sanity: never use port 22, 25195 (altare SSH sandbox default) or any obvious ssh port
    if [ "$PORT" = "22" ] || [ "$PORT" = "25195" ]; then
        echo "[!] refusing to bind FiveM to SSH-looking port $PORT — set FIVEM_PORT=<your extra altare port>"
        PORT=""
    fi
    if [ -n "$PORT" ]; then
        echo "[*] forcing port $PORT in server.cfg"
        sed -i -E "s|endpoint_add_tcp.*|endpoint_add_tcp \"0.0.0.0:$PORT\"|" "$DATA/server.cfg"
        sed -i -E "s|endpoint_add_udp.*|endpoint_add_udp \"0.0.0.0:$PORT\"|" "$DATA/server.cfg"
    fi
}

start_server() {
    screen -S "$SCREEN_NAME" -X quit 2>/dev/null || true
    cd "$DATA"
    echo "[*] starting FXServer in screen session '$SCREEN_NAME'..."
    screen -dmS "$SCREEN_NAME" -L -Logfile "$LOG" bash -c "
        '$ALPINE/opt/cfx-server/ld-musl-x86_64.so.1' \
            --library-path '$ALPINE/usr/lib/v8/:$ALPINE/lib/:$ALPINE/usr/lib/' \
            -- '$ALPINE/opt/cfx-server/FXServer' \
            +set citizen_dir '$ALPINE/opt/cfx-server/citizen/' \
            +exec server.cfg
    "
    sleep 2
    echo ""
    echo "============================================================"
    echo " server started in screen session: $SCREEN_NAME"
    echo " commands:"
    echo "   bash deploy.sh logs      # tail live log"
    echo "   screen -r $SCREEN_NAME   # attach to console (Ctrl-A D to detach)"
    echo "   bash deploy.sh stop      # stop server"
    echo "   bash deploy.sh update    # pull repo + restart"
    echo "============================================================"
}

stop_server() {
    screen -S "$SCREEN_NAME" -X quit 2>/dev/null && echo "[+] stopped" || echo "[!] no running screen session"
}

logs() { tail -f "$LOG"; }

case "${1:-install}" in
    install|setup|"")
        ensure_deps
        [ ! -f "$ALPINE/opt/cfx-server/FXServer" ] && fetch_fxserver
        sync_repo
        inject_key
        start_server
        ;;
    update|pull)
        sync_repo
        inject_key
        stop_server || true
        sleep 1
        start_server
        ;;
    stop)      stop_server ;;
    start)     start_server ;;
    restart)   stop_server || true; sleep 1; start_server ;;
    logs|tail) logs ;;
    *) echo "usage: $0 [install|update|restart|stop|start|logs]" ;;
esac
