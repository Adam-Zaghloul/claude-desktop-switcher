#!/bin/bash
# ─────────────────────────────────────────────────────────────
# Claude Desktop Account Switcher
# https://github.com/Adam-Zaghloul/claude-desktop-switcher
#
# Switches between multiple Claude Desktop accounts on Linux
# without re-logging in. Each account gets its own isolated
# --user-data-dir, bypassing Electron keyring issues entirely.
#
# Requirements:
#   - claude-desktop (aaddrick/claude-desktop-debian)
#   - zenity (GNOME GTK dialogs)
#   - bash 4+
#
# Tested on: Fedora 44 Workstation (GNOME)
# ─────────────────────────────────────────────────────────────

ACCOUNTS_DIR="$HOME/.config/Claude-accounts"
CURRENT_FILE="$ACCOUNTS_DIR/.current"
mkdir -p "$ACCOUNTS_DIR"

get_current() { [[ -f "$CURRENT_FILE" ]] && cat "$CURRENT_FILE" || echo "(none)"; }

kill_claude() {
    pkill -f "claude-desktop" 2>/dev/null
    while pgrep -f "claude-desktop" > /dev/null; do sleep 0.3; done
}

launch_claude() {
    nohup claude-desktop --user-data-dir="$1" > /dev/null 2>&1 &
    disown
}

CURRENT=$(get_current)
ACCOUNTS=$(ls "$ACCOUNTS_DIR" 2>/dev/null | grep -v '^\.')
COUNT=$(echo "$ACCOUNTS" | grep -c '[^[:space:]]' 2>/dev/null || echo 0)

ACTION=$(zenity --list \
    --title="Claude Desktop — Account Switcher" \
    --text="<b>Active account:</b>  <span foreground='#5865F2'>$CURRENT</span>" \
    --column="Action" --column="Description" \
    --hide-column=1 --print-column=1 \
    --width=460 --height=300 \
    "switch"    "🔄  Switch to a saved account" \
    "new"       "➕  Add new account" \
    "delete"    "🗑️   Remove account" \
    "status"    "ℹ️   Status" \
    2>/dev/null)

[[ -z "$ACTION" ]] && exit 0

# ── SWITCH ────────────────────────────────────────────────────
if [[ "$ACTION" == "switch" ]]; then
    if [[ $COUNT -lt 1 ]] || [[ -z "$ACCOUNTS" ]]; then
        zenity --error \
            --title="No Accounts Saved" \
            --text="No accounts saved yet.\n\nUse <b>Add new account</b> to set one up." \
            --width=340 2>/dev/null
        exit 1
    fi

    RADIO=()
    while IFS= read -r acc; do
        [[ -z "$acc" ]] && continue
        [[ "$acc" == "$CURRENT" ]] && RADIO+=("TRUE" "$acc  ✓") || RADIO+=("FALSE" "$acc")
    done <<< "$ACCOUNTS"

    SELECTED=$(zenity --list \
        --title="Switch Account" \
        --text="Select an account:" \
        --radiolist \
        --column=" " --column="Account" \
        --width=380 --height=280 \
        "${RADIO[@]}" 2>/dev/null)

    [[ -z "$SELECTED" ]] && exit 0
    SELECTED="${SELECTED/  ✓/}"

    if [[ "$SELECTED" == "$CURRENT" ]]; then
        zenity --info \
            --title="Already Active" \
            --text="<b>$SELECTED</b> is already the active account." \
            --width=320 2>/dev/null
        exit 0
    fi

    kill_claude
    echo "$SELECTED" > "$CURRENT_FILE"
    launch_claude "$ACCOUNTS_DIR/$SELECTED"
    zenity --notification --text="Switched to: $SELECTED" 2>/dev/null &
fi

# ── ADD NEW ACCOUNT ───────────────────────────────────────────
if [[ "$ACTION" == "new" ]]; then
    NAME=$(zenity --entry \
        --title="New Account" \
        --text="Name for this account:\n(e.g. <i>personal</i>, <i>work</i>, <i>free2</i>)" \
        --width=360 2>/dev/null)

    [[ -z "$NAME" ]] && exit 0
    NAME=$(echo "$NAME" | tr ' ' '_' | tr -cd '[:alnum:]_-')

    if [[ -z "$NAME" ]]; then
        zenity --error --title="Invalid Name" \
            --text="Name cannot be empty or contain special characters." \
            --width=340 2>/dev/null
        exit 1
    fi

    if [[ -d "$ACCOUNTS_DIR/$NAME" ]]; then
        zenity --question \
            --title="Account Exists" \
            --text="<b>$NAME</b> already exists.\nRe-open it to log in again?" \
            --ok-label="Yes" --cancel-label="Cancel" \
            --width=340 2>/dev/null || exit 0
    fi

    mkdir -p "$ACCOUNTS_DIR/$NAME"
    kill_claude
    echo "$NAME" > "$CURRENT_FILE"
    launch_claude "$ACCOUNTS_DIR/$NAME"

    zenity --info \
        --title="Log In Now" \
        --text="Claude Desktop is opening a fresh session for <b>$NAME</b>.\n\nWait <b>20–30 seconds</b> for the login page to appear,\nthen sign into this account.\n\nThe session is saved automatically." \
        --width=400 2>/dev/null
fi

# ── DELETE ACCOUNT ────────────────────────────────────────────
if [[ "$ACTION" == "delete" ]]; then
    if [[ $COUNT -lt 1 ]] || [[ -z "$ACCOUNTS" ]]; then
        zenity --error --title="No Accounts" \
            --text="No saved accounts to delete." --width=300 2>/dev/null
        exit 0
    fi

    CHECK=()
    while IFS= read -r acc; do
        [[ -z "$acc" ]] && continue
        CHECK+=("FALSE" "$acc")
    done <<< "$ACCOUNTS"

    TO_DEL=$(zenity --list \
        --title="Delete Account" \
        --text="Select accounts to delete:" \
        --checklist \
        --column=" " --column="Account" \
        --width=360 --height=280 \
        "${CHECK[@]}" 2>/dev/null)

    [[ -z "$TO_DEL" ]] && exit 0

    zenity --question \
        --title="Confirm Delete" \
        --text="Permanently delete: <b>$TO_DEL</b>?\n\n(Your Claude account is not deleted — only the saved session on this machine.)" \
        --ok-label="Delete" --cancel-label="Cancel" \
        --width=380 2>/dev/null || exit 0

    IFS='|' read -ra DEL <<< "$TO_DEL"
    for acc in "${DEL[@]}"; do
        acc=$(echo "$acc" | xargs)
        rm -rf "$ACCOUNTS_DIR/$acc"
        [[ "$acc" == "$CURRENT" ]] && echo "(none)" > "$CURRENT_FILE"
    done
    zenity --info --text="🗑️  Deleted: $TO_DEL" --width=300 2>/dev/null
fi

# ── STATUS ────────────────────────────────────────────────────
if [[ "$ACTION" == "status" ]]; then
    LIST=$(ls "$ACCOUNTS_DIR" 2>/dev/null | grep -v '^\.' | sed 's/^/  • /')
    [[ -z "$LIST" ]] && LIST="  (none saved yet)"
    PID=$(pgrep -f "claude-desktop" | head -1)
    [[ -n "$PID" ]] && STATE="Running (PID $PID)" || STATE="Not running"

    zenity --info \
        --title="Account Status" \
        --text="<b>Active account:</b>  $CURRENT\n<b>Claude Desktop:</b>  $STATE\n\n<b>Saved accounts:</b>\n$LIST" \
        --width=360 2>/dev/null
fi

exit 0
