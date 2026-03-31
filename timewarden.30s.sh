#!/usr/bin/env bash
# <swiftbar.title>Timewarden Launcher</swiftbar.title>
# <swiftbar.version>v2.0</swiftbar.version>
# <swiftbar.author>abd3lraouf</swiftbar.author>
# <swiftbar.desc>Build and launch Timewarden on Android/iOS. Tracks running builds. Supports worktrees.</swiftbar.desc>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>false</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>

# ── Environment ─────────────────────────────────────
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
ADB="$ANDROID_HOME/platform-tools/adb"
EMULATOR="$ANDROID_HOME/emulator/emulator"
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
CACHE_DIR="$HOME/.cache/swiftbar-timewarden"
STATE_DIR="$CACHE_DIR/running"
CONFIG_FILE="$CACHE_DIR/config"

# ── Load config ─────────────────────────────────────
if [[ ! -f "$CONFIG_FILE" ]]; then
    mkdir -p "$CACHE_DIR"
    echo "⚠ Not configured | size=13"
    echo "---"
    echo "Run the install script first | color=#8E8E93 size=12"
    echo "See: github.com/gettimewarden/swiftbar-timewarden | size=12"
    exit 0
fi
if ! grep -qE '^TIMEWARDEN_PROJECT="[^"]+"$' "$CONFIG_FILE" 2>/dev/null; then
    echo "⚠ Config invalid | size=13"
    echo "---"
    echo "Invalid config file. Re-run install.sh | color=#8E8E93 size=12"
    exit 0
fi
# shellcheck source=/dev/null
source "$CONFIG_FILE"
MAIN_PROJECT="${TIMEWARDEN_PROJECT:?TIMEWARDEN_PROJECT not set in $CONFIG_FILE}"

# ── Self-dispatch ───────────────────────────────────
# Creates a temp launcher script with state tracking, then opens it in
# Terminal.app via osascript. Returns immediately so SwiftBar is never blocked.

_launch_in_terminal() {
    local platform="$1" display="$2" project_dir="$3" wt_name="$4"
    shift 4
    local -a run_args=("$@")

    mkdir -p "$STATE_DIR"
    local launcher
    launcher=$(mktemp "$STATE_DIR/_launch_XXXXXX.sh")
    local state_file
    state_file=$(mktemp "$STATE_DIR/XXXXXX.state")

    printf -v args_str '%q ' "${run_args[@]}"

    cat > "$launcher" << LAUNCHER
#!/bin/bash
BASHPID=\$\$
cd "$project_dir" || exit 1
export PATH="$ANDROID_HOME/platform-tools:\$PATH"
mkdir -p "$STATE_DIR"
echo "${platform}|${display}|${wt_name}|\$(date +%s)" > "$state_file"
trap "rm -f '$state_file'; rm -f '$launcher'" EXIT
./run.sh ${args_str}
LAUNCHER
    chmod +x "$launcher"

    osascript -e "tell application \"Terminal\"" \
              -e "activate" \
              -e "do script \"'$launcher'\"" \
              -e "end tell" >/dev/null 2>&1
}

case "${1:-}" in
    --launch-avd)
        avd_name="${2:?avd name required}"
        "$EMULATOR" -avd "$avd_name" &>/dev/null &
        disown
        exit 0
        ;;
    --run-android)
        project_dir="${2:?project dir required}"
        shift 2
        local -a run_args=()
        device="${1:-all}"
        wt_name="$(basename "$project_dir")"
        if [[ "$device" != "all" ]]; then
            run_args=("$device")
        fi
        _launch_in_terminal "android" "$device" "$project_dir" "$wt_name" "./run.sh" "${run_args[@]}"
        exit 0
        ;;
    --run-ios)
        project_dir="${2:?project dir required}"
        shift 2
        local run_args=()
        case "${1:-}" in
            --device) 
                ios_display="Physical device"
                run_args=("--device")
                ;;
            --sim)
                ios_display="${2:-Default sim}"
                run_args=("--sim" "${2:-}")
                shift
                ;;
            *)
                ios_display="auto"
                run_args=()
                ;;
        esac
        wt_name="$(basename "$project_dir")"
        _launch_in_terminal "ios" "$ios_display" "$project_dir" "$wt_name" "./run-ios.sh" "${run_args[@]}"
        exit 0
        ;;
    --stop)
        pid="${2:?pid required}"
        kill "$pid" 2>/dev/null
        rm -f "$STATE_DIR/${pid}.state" 2>/dev/null
        exit 0
        ;;
esac

# ── Icon generation & caching ──────────────────────
# Uses sips + base64 (macOS built-in) for app icon.
# Uses pre-generated base64 for Android robot icon (faster than compiling Swift).
# All results cached — regenerated only when source changes or cache missing.

_ANDROID_ICON_PREGEN="aVZCT1J3MEtHZ29BQUFBTlNVaEVVZ0FBQUNBQUFBQWdDQVlBQUFCemVucjBBQUFBQVhOU1IwSUFyczRjNlFBQUFEaGxXRWxtVFUwQUtnQUFBQWdBQVlkcEFBUUFBQUFCQUFBQUdnQUFBQUFBQXFBQ0FBUUFBQUFCQUFBQUlLQURBQVFBQUFBQkFBQUFJQUFBQUFDUFRrREpBQUFDY1VsRVFWUllDZTFXejB0VVVSUSs5L2xRTW0xUXFLV2JTSWdCTjBrRzVrWWlLUDhFb1lXNWFXR0xRRndWajJ3VFFZdEMzRWlMVnYwRkNoS3pDNUpxRXd4RzZzWmxncUdva09qY3puZkhZZTdjSC9QdTROV1ZEeDV6M2ozZmQ4NTN6cDMzN2lHNnVBSTdNUHdyRzZRc1N3TGhkUmh6RkxlKzBtQUZCUnhabS8yVXBPbTN1K05pcklFZDhBQU91SWpoZ2djSllPS0tJb3ZrcVN0STA3VTZweHJEQUFjSk9OalorMENTOWdXSmUzZCt6OTQwWW5nZmdRVUhYQlhEZ1F3UzhHUHc5WTRrK1JIOFZOQ1VJNDV6cVlZRkZ6RmNvQ0FCSUI1SmVvOWZydWpScmU4ekJkak5MbUNBQmFiR2RlR0RCWHp0Zjc3S2xYeG1CWmM3QzEwVHJtRDYycVZDOTJOZ3dRRlg5K2wyc0FCRmtwVjNKK1FoUFlqTEZpUnZHeHdYakRYbVhNTnJMNHNKSlpPUzZENEg3U01odW5Jb2pXNHA5eVNKVFU2MFhLSEt3cGNiTDhvNndDdWdXTTdhZTlyYjNyTEVKN3lYclhWS3o2RFp2QjBWZmlQbS94NGVQeXNYczBPNG5BS1F2TGVqYlluZG94by9vaWxMMi8rT0gwQ0VzekpWK1prbFYzV1BWbk00T29BOUYwTDhqTlYyWDl1d0hWTEtnZFFFNEEvSGE4N09tTmpUUEtOQXZpY3RBZFYvdXovMFVPZDFtcjc2VUFIZWJDM1N5c0ZHQXpqUHI0T1J5NnBVdldvNnlyQ1IvRnA2UmQwMUlUb2t6Njlqa2NzUzBQSjdya2RzMWVadmlpMGdKd2phL3Vkb1Y5Mnd6U3ZQYitLdDc4REkraXZlbXZPN1d1NUFiR2tYQXV3TzhPa1Z1ODNlZUp6TEVvQ2owMHVJN0VBdVN3RE83Y2g1dk9HUXl4S0FvVUdkMjE1YUhBZHlJSmNsUUUwc1BEVEVTZE1rQ3VkQUxrc0FLSmhZaUdTcENmMlVMbG1xNXZBY3U1aFVNTEh3ZVQwWGN6dE9ab0M1MmpTRUtxeFBzVm5hV1ErbC93RWZlUEV0K2x6NURBQUFBQUJKUlU1RXJrSmdnZz09"

generate_icons() {
    mkdir -p "$CACHE_DIR"

    # ── Menu bar icon: white foreground as templateImage (adapts to dark/light mode) ──
    local src="$MAIN_PROJECT/app/android/src/main/res/mipmap-xhdpi/ic_launcher_foreground.png"
    local cached="$CACHE_DIR/menubar.b64"
    if [[ ! -s "$cached" ]] || [[ "$src" -nt "$cached" ]]; then
        local tmp="$CACHE_DIR/menubar_tmp.png"
        cp "$src" "$tmp"
        sips -z 36 36 "$tmp" --out "$tmp" >/dev/null 2>&1
        base64 -i "$tmp" | tr -d '\n' > "$cached"
        rm -f "$tmp"
    fi

    # ── Android robot icon: use pre-generated base64 (no Swift compilation needed) ──
    local android_cached="$CACHE_DIR/android.b64"
    if [[ ! -s "$android_cached" ]]; then
        echo "$_ANDROID_ICON_PREGEN" > "$android_cached"
    fi
}

read_icon() {
    local path="$CACHE_DIR/$1.b64"
    [[ -s "$path" ]] && cat "$path" || echo ""
}

generate_icons
ICON_MENUBAR=$(read_icon menubar)
ICON_ANDROID=$(read_icon android)

# ── Design tokens (macOS HIG system colors) ───────
C_ANDROID="#3DDC84"    # Android brand green
C_IOS="#007AFF"        # Apple system blue
C_BUILD="#FF9F0A"      # System orange — active build
C_STOP="#FF453A"       # System red — stop/destructive
C_SECONDARY="#8E8E93"  # System gray — secondary labels
C_DISABLED="#636366"   # System gray 3 — disabled/empty

# ── Helpers ─────────────────────────────────────────

_adb_timeout() {
    local timeout=5
    if command -v timeout &>/dev/null; then
        timeout "$timeout" "$@"
    else
        "$@"
    fi
}

# Resolve Android serial → model name using already-gathered data
serial_to_model() {
    local serial="$1"
    for idx in "${!android_serials[@]}"; do
        if [[ "${android_serials[$idx]}" == "$serial" ]]; then
            echo "${android_models[$idx]}"
            return
        fi
    done
    echo "$serial"
}

# Map battery level → SF Symbol + color
battery_icon() {
    local level=$1
    if (( level > 75 )); then echo "battery.100"
    elif (( level > 50 )); then echo "battery.75"
    elif (( level > 25 )); then echo "battery.50"
    elif (( level > 10 )); then echo "battery.25"
    else echo "battery.0"
    fi
}
battery_color() {
    local level=$1
    if (( level > 50 )); then echo "$C_ANDROID"
    elif (( level > 20 )); then echo "$C_BUILD"
    else echo "$C_STOP"
    fi
}

# Format seconds → human-readable elapsed time
format_elapsed() {
    local secs=$1
    local mins=$(( secs / 60 ))
    if (( mins >= 60 )); then
        printf "%dh%dm" $(( mins / 60 )) $(( mins % 60 ))
    elif (( mins > 0 )); then
        printf "%dm%02ds" "$mins" $(( secs % 60 ))
    else
        printf "%ds" "$secs"
    fi
}

# Format seconds → short form for menu bar (e.g. "3m" not "3m12s")
format_elapsed_short() {
    local secs=$1
    local mins=$(( secs / 60 ))
    if (( mins >= 60 )); then
        printf "%dh%dm" $(( mins / 60 )) $(( mins % 60 ))
    elif (( mins > 0 )); then
        printf "%dm" "$mins"
    else
        printf "%ds" "$secs"
    fi
}

# ── Scan running builds ────────────────────────────
# State files: $STATE_DIR/<PID>.state
# Format: platform|device|worktree_name|start_unix_ts
# Stale files (dead PID) get cleaned up automatically.

running_pids=()
running_platforms=()
running_devices=()
running_sources=()
running_elapsed=()
mkdir -p "$STATE_DIR"
for sf in "$STATE_DIR"/*.state; do
    [[ -f "$sf" ]] || continue
    pid=$(basename "$sf" .state)
    if kill -0 "$pid" 2>/dev/null; then
        IFS='|' read -r r_platform r_device r_wt r_start < "$sf"
        secs=$(( $(date +%s) - r_start ))
        running_pids+=("$pid")
        running_platforms+=("$r_platform")
        running_devices+=("$r_device")
        running_sources+=("$r_wt")
        running_elapsed+=("$secs")
    else
        rm -f "$sf"
    fi
done
running_count=${#running_pids[@]}

# ── Gather: Android devices ────────────────────────
android_serials=()
android_models=()
android_versions=()
android_apis=()
android_batteries=()
if [[ -x "$ADB" ]]; then
    while IFS= read -r serial; do
        [[ -z "$serial" ]] && continue
        android_serials+=("$serial")
        info=$(_adb_timeout "$ADB" -s "$serial" shell "echo \$(getprop ro.product.model);echo \$(getprop ro.build.version.release);echo \$(getprop ro.build.version.sdk);echo \$(dumpsys battery | grep level: | awk '{print \$2}')" 2>/dev/null | tr -d '\r\n' | awk -F';' '{
            model=$1
            ver=$2
            sdk=$3
            bat=$4
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", model)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", ver)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", sdk)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", bat)
            print model "|" ver "|" sdk "|" bat
        }')
        IFS='|' read -r model ver sdk bat <<< "$info"
        android_models+=("${model:-$serial}")
        android_versions+=("${ver:-?}")
        android_apis+=("${sdk:-?}")
        android_batteries+=("${bat:-?}")
    done < <("$ADB" devices 2>/dev/null | awk 'NR>1 && $2=="device" {print $1}')
fi
android_count=${#android_serials[@]}

# ── Gather: Android AVDs (available emulators, like iOS simulators) ──
avd_names=()
if [[ -x "$EMULATOR" ]]; then
    # Find which AVDs are already running
    running_avds=()
    for serial in "${android_serials[@]}"; do
        if [[ "$serial" == emulator-* ]]; then
            avd=$(_adb_timeout "$ADB" -s "$serial" emu avd name 2>/dev/null | head -1 | tr -d '\r\n')
            [[ -n "$avd" ]] && running_avds+=("$avd")
        fi
    done
    while IFS= read -r avd; do
        [[ -z "$avd" ]] && continue
        # Skip AVDs that are already running
        skip=false
        for r in "${running_avds[@]}"; do
            [[ "$r" == "$avd" ]] && { skip=true; break; }
        done
        $skip || avd_names+=("$avd")
    done < <("$EMULATOR" -list-avds 2>/dev/null)
fi
avd_count=${#avd_names[@]}

# ── Gather: iOS physical devices (via devicectl) ──
ios_phy_names=()
ios_phy_os=()
ios_phy_model=()
if command -v xcrun &>/dev/null; then
    json_tmp=$(mktemp)
    xcrun devicectl list devices --json-output "$json_tmp" >/dev/null 2>&1 || true
    while IFS='|' read -r name os_ver hw_model; do
        [[ -z "$name" ]] && continue
        ios_phy_names+=("$name")
        ios_phy_os+=("${os_ver:-?}")
        ios_phy_model+=("${hw_model:-?}")
    done < <(python3 -c "
import json
import sys
try:
    data = json.load(open(sys.argv[1]))
    for d in data.get('result',{}).get('devices',[]):
        hw = d.get('hardwareProperties',{})
        if hw.get('platform') == 'iOS':
            name = d.get('name') or hw.get('marketingName','Unknown')
            os_ver = d.get('deviceProperties',{}).get('osVersionNumber','')
            hw_model = hw.get('marketingName','')
            print(f'{name}|{os_ver}|{hw_model}')
except Exception:
    pass
" "$json_tmp" 2>/dev/null)
    rm -f "$json_tmp"
fi
ios_phy_count=${#ios_phy_names[@]}

# ── Gather: iOS simulators (deduplicated, latest runtime) ──
ios_sim_names=()
if command -v xcrun &>/dev/null; then
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        ios_sim_names+=("$name")
    done < <(xcrun simctl list devices available -j 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
seen = set()
for runtime in sorted(data['devices'].keys(), reverse=True):
    for d in data['devices'][runtime]:
        if d['isAvailable'] and d['name'] not in seen and 'iPhone' in d['name']:
            seen.add(d['name'])
            print(d['name'])
" 2>/dev/null)
fi
ios_sim_count=${#ios_sim_names[@]}

# ── Gather: Git project status (main worktree) ────
main_branch=$(git -C "$MAIN_PROJECT" branch --show-current 2>/dev/null || echo "?")
main_commit=$(git -C "$MAIN_PROJECT" log --oneline -1 --no-decorate 2>/dev/null || echo "?")
main_commit_hash="${main_commit%% *}"
main_commit_msg="${main_commit#* }"
main_dirty=$(git -C "$MAIN_PROJECT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
main_stash=$(git -C "$MAIN_PROJECT" stash list 2>/dev/null | wc -l | tr -d ' ')
main_ahead=$(git -C "$MAIN_PROJECT" rev-list --count '@{upstream}..HEAD' 2>/dev/null || echo "0")
main_behind=$(git -C "$MAIN_PROJECT" rev-list --count 'HEAD..@{upstream}' 2>/dev/null || echo "0")

# ── Gather: Git worktrees (excluding main) ─────────
wt_paths=()
wt_branches=()
wt_has_run_sh=()
wt_has_run_ios=()
wt_dirty=()
wt_commits=()
wt_ahead=()
main_upstream=$(git -C "$MAIN_PROJECT" rev-parse --abbrev-ref @{upstream} 2>/dev/null || echo "")
while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    wt_path="${line%% *}"
    wt_branch=$(echo "$line" | sed -n 's/.*\[\(.*\)\].*/\1/p')
    [[ "$wt_path" == "$MAIN_PROJECT" ]] && continue
    wt_paths+=("$wt_path")
    wt_branches+=("${wt_branch:-detached}")
    [[ -f "$wt_path/run.sh" ]]     && wt_has_run_sh+=("yes")  || wt_has_run_sh+=("no")
    [[ -f "$wt_path/run-ios.sh" ]] && wt_has_run_ios+=("yes") || wt_has_run_ios+=("no")
    d=$(git -C "$wt_path" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    wt_dirty+=("$d")
    c=$(git -C "$wt_path" log --oneline -1 --no-decorate 2>/dev/null)
    wt_commits+=("${c#* }")
    if [[ -n "$main_upstream" ]]; then
        a=$(git -C "$wt_path" rev-list --count "$main_upstream..HEAD" 2>/dev/null || echo "0")
    else
        a="0"
    fi
    wt_ahead+=("$a")
done < <(git -C "$MAIN_PROJECT" worktree list 2>/dev/null)
wt_count=${#wt_paths[@]}

android_wt_count=0
ios_wt_count=0
for v in "${wt_has_run_sh[@]}";  do [[ "$v" == "yes" ]] && ((android_wt_count++)); done
for v in "${wt_has_run_ios[@]}"; do [[ "$v" == "yes" ]] && ((ios_wt_count++)); done

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  MENU OUTPUT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Menu bar (20 chars max, show model name + time) ──
if (( running_count > 0 )); then
    if (( running_count == 1 )); then
        p="${running_platforms[0]}"
        d="${running_devices[0]}"
        t=$(format_elapsed_short "${running_elapsed[0]}")
        if [[ "$p" == "android" ]]; then
            [[ "$d" == "all" ]] && bar_status="Android · ${t}" || bar_status="$(serial_to_model "$d") · ${t}"
        else
            [[ "$d" == "default" ]] && bar_status="iOS · ${t}" || bar_status="${d} · ${t}"
        fi
        bar_status="${bar_status:0:20}"
    else
        bar_status="${running_count} builds"
    fi
    if [[ -n "$ICON_MENUBAR" ]]; then
        echo "$bar_status | templateImage=$ICON_MENUBAR width=28 height=28 color=$C_BUILD"
    else
        echo "$bar_status | sfimage=hammer.fill color=$C_BUILD size=13"
    fi
else
    if [[ -n "$ICON_MENUBAR" ]]; then
        echo "| templateImage=$ICON_MENUBAR width=28 height=28"
    else
        echo "TW | sfimage=hammer.fill size=13"
    fi
fi
echo "---"

# ── Building (active builds) ──────────────────────
if (( running_count > 0 )); then
    echo "Building | sfimage=hammer.fill color=$C_BUILD size=14"
    for i in "${!running_pids[@]}"; do
        p="${running_platforms[$i]}"
        d="${running_devices[$i]}"
        wt="${running_sources[$i]}"
        t=$(format_elapsed "${running_elapsed[$i]}")

        # Resolve to display name
        if [[ "$p" == "android" ]]; then
            [[ "$d" == "all" ]] && dn="All devices" || dn="$(serial_to_model "$d")"
            p_icon="play.rectangle.fill"
            p_color="$C_ANDROID"
        else
            [[ "$d" == "default" ]] && dn="Default simulator" || dn="$d"
            p_icon="apple.logo"
            p_color="$C_IOS"
        fi

        # Source suffix (only show if not main project)
        [[ "$wt" == "timewarden.mobile" ]] && src="" || src="  [$wt]"

        echo "--${dn} · ${t}${src} | sfimage=$p_icon color=$p_color size=13"
        echo "----Stop Build | sfimage=stop.fill color=$C_STOP bash='$SELF' param1='--stop' param2='${running_pids[$i]}' terminal=false refresh=true size=12"
    done
    echo "---"
fi

# ── Project status ──────────────────────────────────
# Sync status suffix
sync_parts=()
(( main_ahead > 0 )) && sync_parts+=("${main_ahead}↑")
(( main_behind > 0 )) && sync_parts+=("${main_behind}↓")
if (( ${#sync_parts[@]} > 0 )); then
    sync_str=" · $(IFS=' '; echo "${sync_parts[*]}")"
else
    sync_str=""
fi
# Dirty indicator
(( main_dirty > 0 )) && dirty_suffix=" · ${main_dirty} changed" || dirty_suffix=""

echo "${main_branch}${sync_str}${dirty_suffix} | sfimage=arrow.triangle.branch color=$C_SECONDARY size=14"
echo "--${main_commit_hash} ${main_commit_msg:0:40} | sfimage=point.topleft.down.to.point.bottomright.curvepath color=$C_SECONDARY size=12"
if (( main_dirty > 0 )); then
    echo "--${main_dirty} uncommitted changes | sfimage=pencil.circle color=$C_BUILD size=12"
fi
if (( main_stash > 0 )); then
    echo "--${main_stash} stashed | sfimage=tray.full color=$C_SECONDARY size=12"
fi
if (( main_ahead > 0 )); then
    echo "--${main_ahead} ahead of remote | sfimage=arrow.up.circle color=$C_ANDROID size=12"
fi
if (( main_behind > 0 )); then
    echo "--${main_behind} behind remote | sfimage=arrow.down.circle color=$C_BUILD size=12"
fi
if (( wt_count > 0 )); then
    echo "-----"
    echo "--Worktrees (${wt_count}) | sfimage=arrow.triangle.branch color=$C_SECONDARY size=12"
    for i in "${!wt_paths[@]}"; do
        wt_name="$(basename "${wt_paths[$i]}")"
        # Status badge: dirty count + ahead count
        wt_badge=""
        (( ${wt_dirty[$i]} > 0 )) && wt_badge+=" · ${wt_dirty[$i]} changed"
        (( ${wt_ahead[$i]} > 0 )) && wt_badge+=" · ${wt_ahead[$i]}↑"
        echo "----${wt_name} · ${wt_branches[$i]}${wt_badge} | sfimage=folder.fill color=$C_SECONDARY size=12 tooltip=${wt_paths[$i]}"
        echo "------${wt_commits[$i]:0:45} | sfimage=point.topleft.down.to.point.bottomright.curvepath color=$C_DISABLED size=11"
    done
fi

echo "---"

# ── Android ─────────────────────────────────────────
android_header="Android"
android_parts=()
if (( android_count > 0 )); then
    (( android_count == 1 )) && android_parts+=("${android_count} device") || android_parts+=("${android_count} devices")
fi
if (( avd_count > 0 )); then
    (( avd_count == 1 )) && android_parts+=("${avd_count} avd") || android_parts+=("${avd_count} avds")
fi
if (( ${#android_parts[@]} > 0 )); then
    android_label="Android · $(printf '%s, ' "${android_parts[@]}" | sed 's/, $//')"
else
    android_label="Android · 0 devices"
fi
if [[ -n "$ICON_ANDROID" ]]; then
    echo "$android_label | image=$ICON_ANDROID width=16 height=16 size=14"
else
    echo "$android_label | sfimage=play.rectangle.fill color=$C_ANDROID size=14"
fi

echo "--Run All Devices | sfimage=play.fill bash='$SELF' param1='--run-android' param2='$MAIN_PROJECT' terminal=false size=13"
if (( android_count > 0 )); then
    echo "-----"
    for i in "${!android_serials[@]}"; do
        bat="${android_batteries[$i]}"
        bat_icon=$(battery_icon "$bat")
        bat_col=$(battery_color "$bat")
        echo "--${android_models[$i]} · A${android_versions[$i]} · ${bat}% | sfimage=$bat_icon color=$bat_col bash='$SELF' param1='--run-android' param2='$MAIN_PROJECT' param3='${android_serials[$i]}' terminal=false size=13 tooltip='${android_serials[$i]} · API ${android_apis[$i]}'"
    done
fi

# AVDs (available emulators, not yet running)
if (( avd_count > 0 )); then
    echo "-----"
    for i in "${!avd_names[@]}"; do
        echo "--${avd_names[$i]} | sfimage=desktopcomputer bash='$SELF' param1='--launch-avd' param2='${avd_names[$i]}' terminal=false refresh=true size=13"
    done
fi

if (( android_count == 0 && avd_count == 0 )); then
    echo "-----"
    echo "--Waiting for devices | color=$C_DISABLED sfimage=cable.connector.slash size=12"
fi

if (( android_wt_count > 0 )); then
    echo "-----"
    echo "--Worktrees | sfimage=arrow.triangle.branch color=$C_SECONDARY size=12"
    for i in "${!wt_paths[@]}"; do
        [[ "${wt_has_run_sh[$i]}" != "yes" ]] && continue
        wt_name="$(basename "${wt_paths[$i]}")"
        wt_badge=""
        (( ${wt_dirty[$i]} > 0 )) && wt_badge+=" · ${wt_dirty[$i]}~"
        (( ${wt_ahead[$i]} > 0 )) && wt_badge+=" · ${wt_ahead[$i]}↑"
        echo "----${wt_name} · ${wt_branches[$i]}${wt_badge} | sfimage=folder.fill bash='$SELF' param1='--run-android' param2='${wt_paths[$i]}' terminal=false size=13 tooltip=${wt_paths[$i]}"
        if (( android_count > 0 )); then
            for j in "${!android_serials[@]}"; do
                echo "------${android_models[$j]} | sfimage=cable.connector bash='$SELF' param1='--run-android' param2='${wt_paths[$i]}' param3='${android_serials[$j]}' terminal=false size=12"
            done
        fi
    done
fi

echo "---"

# ── iOS ─────────────────────────────────────────────
# Build header: "iOS · 1 device, 5 sims" or "iOS · 5 sims" etc.
ios_header="iOS"
ios_parts=()
if (( ios_phy_count > 0 )); then
    (( ios_phy_count == 1 )) && ios_parts+=("${ios_phy_count} device") || ios_parts+=("${ios_phy_count} devices")
fi
if (( ios_sim_count > 0 )); then
    (( ios_sim_count == 1 )) && ios_parts+=("${ios_sim_count} sim") || ios_parts+=("${ios_sim_count} sims")
fi
if (( ${#ios_parts[@]} > 0 )); then
    ios_header="iOS · $(printf '%s, ' "${ios_parts[@]}" | sed 's/, $//')"
fi
echo "$ios_header | sfimage=apple.logo color=$C_IOS size=14"

# Default run: auto-detects (prefers physical device over simulator)
echo "--Run | sfimage=play.fill bash='$SELF' param1='--run-ios' param2='$MAIN_PROJECT' terminal=false size=13"

# Physical devices
if (( ios_phy_count > 0 )); then
    echo "-----"
    for i in "${!ios_phy_names[@]}"; do
        echo "--${ios_phy_names[$i]} · iOS ${ios_phy_os[$i]} | sfimage=cable.connector bash='$SELF' param1='--run-ios' param2='$MAIN_PROJECT' param3='--device' terminal=false size=13 tooltip='${ios_phy_model[$i]}'"
    done
fi

# Simulators
if (( ios_sim_count > 0 )); then
    echo "-----"
    for i in "${!ios_sim_names[@]}"; do
        echo "--${ios_sim_names[$i]} | sfimage=iphone bash='$SELF' param1='--run-ios' param2='$MAIN_PROJECT' param3='--sim' param4='${ios_sim_names[$i]}' terminal=false size=13"
    done
else
    echo "-----"
    echo "--No simulators available | color=$C_DISABLED sfimage=iphone.slash size=12"
fi

# Worktrees
if (( ios_wt_count > 0 )); then
    echo "-----"
    echo "--Worktrees | sfimage=arrow.triangle.branch color=$C_SECONDARY size=12"
    for i in "${!wt_paths[@]}"; do
        [[ "${wt_has_run_ios[$i]}" != "yes" ]] && continue
        wt_name="$(basename "${wt_paths[$i]}")"
        wt_badge=""
        (( ${wt_dirty[$i]} > 0 )) && wt_badge+=" · ${wt_dirty[$i]}~"
        (( ${wt_ahead[$i]} > 0 )) && wt_badge+=" · ${wt_ahead[$i]}↑"
        echo "----${wt_name} · ${wt_branches[$i]}${wt_badge} | sfimage=folder.fill bash='$SELF' param1='--run-ios' param2='${wt_paths[$i]}' terminal=false size=13 tooltip=${wt_paths[$i]}"
        if (( ios_phy_count > 0 )); then
            for j in "${!ios_phy_names[@]}"; do
                echo "------${ios_phy_names[$j]} | sfimage=cable.connector bash='$SELF' param1='--run-ios' param2='${wt_paths[$i]}' param3='--device' terminal=false size=12"
            done
        fi
        if (( ios_sim_count > 0 )); then
            for j in "${!ios_sim_names[@]}"; do
                echo "------${ios_sim_names[$j]} | sfimage=iphone bash='$SELF' param1='--run-ios' param2='${wt_paths[$i]}' param3='--sim' param4='${ios_sim_names[$j]}' terminal=false size=12"
            done
        fi
    done
fi

echo "---"
echo "Refresh | sfimage=arrow.clockwise refresh=true color=$C_SECONDARY size=12"

