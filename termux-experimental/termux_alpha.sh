#!/bin/bash

# Based on Linux version
# Supported x86/arm64 termux variant

# Set terminal title
echo -ne "\033]0;GLAUTUDE-Termux-1.0\007"

# GLAUTUDE-Termux-Prototype

# --- Configuration ---
SEARCH_RESULT_LIMIT=5

# Define the script's directory and the local bin directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BIN_DIR="${SCRIPT_DIR}/bin"

# Explicitly point to yt-dlp inside the local bin directory
YTDLP_BIN="${BIN_DIR}/yt-dlp"

# Other binaries (assume they are in system PATH or provide full path if not)
MPV_BIN="mpv"
JQ_BIN="jq"
FFMPEG_BIN="ffmpeg" # FFMPEG_BIN will be found in PATH after setup_dependencies

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m' # Keeping BLUE defined if you want to use it for other elements later
CYAN='\033[0;36m' # Cyan color definition - now used as main accent
NC='\033[0m' # No Color

# --- MPV Video Output Override ---
# User can set MPV_VO=caca to force caca output, or MPV_VO=tct to force tct.
# Otherwise, script will try tct then fallback to caca.
GLOBAL_MPV_VO_OVERRIDE="${MPV_VO:-}" # Initialize global override variable
# --- End MPV Video Output Override ---

# --- Functions ---

# Function to display the logo
function logo() {
    clear
    # Set terminal title when logo is displayed
    echo -ne "\033]0;GLAUTUDE-Linux-1.0\007"
    echo -e "${CYAN}" # Changed logo color to CYAN
    echo "  ██████╗ ██╗      █████╗  ██╗  ██╗████████╗██╗  ██╗ ██████╗ ███████╗"
    echo " ██╔════╝ ██║     ██╔══██╗ ██║  ██║╚══██╔══╝██║  ██║ ██╔══██╗██╔════╝"
    echo " ██║  ███╗██║     ███████║ ██║  ██║   ██║   ██║  ██║ ██║  ██║█████╗  "
    echo " ██║   ██║██║     ██╔══██║ ██║  ██║   ██║   ██║  ██║ ██║  ██║██╔══╝  "
    echo " ╚██████╔╝███████╗██║  ██║ ╚█████╔╝   ██║   ╚█████╔╝ ██████╔╝███████╗"
    echo "  ╚═════╝ ╚══════╝╚═╝  ╚═╝  ╚════╝    ╚═╝    ╚════╝  ╚═════╝ ╚══════╝"
    echo -e "-------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}            GLAUTUDE - Powered by mpv and yt-dlp${NC}"
    echo -e "-------------------------------------------------------------------"
    echo ""
    # The Sixel note, now formatted neatly within the logo function
    echo -e "${YELLOW}    [!] Note on Terminal Video Performance:"
    echo -e "        Playing video directly in the terminal can be resource-intensive,"
    echo -e "        particularly on mobile devices (Termux).${NC}"
    echo ""
    echo ""
}

# Function to check and install dependencies
function setup_dependencies() {
    echo -e "${GREEN}[INFO] Checking and installing dependencies...${NC}"

    # Create the local bin directory if it doesn't exist
    if [ ! -d "${BIN_DIR}" ]; then
        echo -e "${CYAN}[INFO] Creating local bin directory: ${BIN_DIR}${NC}" # Changed to CYAN
        mkdir -p "${BIN_DIR}" || { echo -e "${RED}[ERROR] Failed to create ${BIN_DIR}. Check permissions.${NC}"; read -r -p "Press Enter to abort..."; exit 1; }
    fi

    local packages_to_install=()
    local PKG_MANAGER=""

    # Detect package manager (pkg for Termux, apt for Debian/Ubuntu)
    if command -v pkg &> /dev/null; then
        PKG_MANAGER="pkg"
        echo -e "${CYAN}[INFO] Detected Termux. Using 'pkg' for package management.${NC}"
    elif command -v apt &> /dev/null; then
        PKG_MANAGER="apt"
        echo -e "${CYAN}[INFO] Detected apt-based Linux. Using 'apt' for package management.${NC}"
    else
        echo -e "${RED}[ERROR] No supported package manager (pkg or apt) found. Please install mpv, ffmpeg, jq, curl, and libcaca manually.${NC}"
        read -r -p "Press Enter to abort..."
        exit 1
    fi

    # --- Check for curl ---
    if ! command -v curl &> /dev/null; then
        echo -e "${YELLOW}[INFO] curl not found. Will attempt to install...${NC}"
        packages_to_install+=("curl")
    fi

    # --- Check for mpv ---
    if ! command -v mpv &> /dev/null; then
        echo -e "${YELLOW}[INFO] mpv not found. Will attempt to install...${NC}"
        packages_to_install+=("mpv")
    fi

    # --- Check for jq ---
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}[INFO] jq not found. Will attempt to install...${NC}"
        packages_to_install+=("jq")
    fi

    # --- Check for ffmpeg ---
    # Termux's ffmpeg usually includes required components
    if ! command -v ffmpeg &> /dev/null; then
        echo -e "${YELLOW}[INFO] ffmpeg not found. Will attempt to install...${NC}"
        packages_to_install+=("ffmpeg") # Package name is same for both
    fi

    # --- Check for libcaca / caca (for ASCII/pixel art video in terminal) ---
    if [ "$PKG_MANAGER" = "pkg" ]; then
        if ! pkg list-installed caca &> /dev/null; then # Termux package name is usually just 'caca'
            echo -e "${YELLOW}[INFO] caca not found. Will attempt to install for terminal video output...${NC}"
            packages_to_install+=("caca")
        fi
    elif [ "$PKG_MANAGER" = "apt" ]; then
        if ! dpkg -s libcaca0 &> /dev/null; then # Debian/Ubuntu library package
            echo -e "${YELLOW}[INFO] libcaca0 not found. Will attempt to install for terminal video output...${NC}"
            packages_to_install+=("libcaca0")
        fi
    fi

    # Install any missing packages
    if [ ${#packages_to_install[@]} -gt 0 ]; then
        echo -e "${CYAN}[INFO] Attempting to install: ${packages_to_install[*]}${NC}"
        if [ "$PKG_MANAGER" = "pkg" ]; then
            if ! pkg update -y || ! pkg install -y "${packages_to_install[@]}"; then
                echo -e "${RED}[ERROR] Failed to install one or more Termux dependencies. Please install them manually and try again.${NC}"
                read -r -p "Press Enter to abort..."
                exit 1
            fi
        elif [ "$PKG_MANAGER" = "apt" ]; then
            if ! apt update || ! apt install -y "${packages_to_install[@]}"; then
                echo -e "${RED}[ERROR] Failed to install one or more apt dependencies. Please install them manually and try again.${NC}"
                read -r -p "Press Enter to abort..."
                exit 1
            fi
        fi
    fi

    # --- Download and install/update yt-dlp from GitHub to local bin ---
    # This is kept as a local download to ensure the absolute latest version.
    echo -e "${CYAN}[INFO] Ensuring yt-dlp is the latest version from GitHub...${NC}" # Changed to CYAN
    local YTDLP_LATEST_URL="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp"

    # Download directly to the calculated YTDLP_BIN path
    if ! curl -L "$YTDLP_LATEST_URL" -o "${YTDLP_BIN}" || ! chmod a+rx "${YTDLP_BIN}"; then
        echo -e "${RED}[ERROR] Failed to download or make yt-dlp executable to ${YTDLP_BIN}. Please check internet and permissions.${NC}"
        read -r -p "Press Enter to abort..."
        exit 1
    fi

    echo -e "${GREEN}[WORK-DONE] yt-dlp updated to latest from GitHub in ${YTDLP_BIN}.${NC}"

    echo -e "${GREEN}[WORK-DONE] All dependencies checked and installed/updated.${NC}"
    sleep 2
    return 0
}

# check for updates
function check_for_updates() {
    local current_version="1.1"
    local version_url="https://raw.githubusercontent.com/NammIsADev/glautude/main/update/version.txt"
    local release_page="https://github.com/NammIsADev/glautude/releases"

    echo -e "${CYAN}[INFO] Checking for updates...${NC}"
    local latest_version
    latest_version=$(curl -s "$version_url" | tr -d '\r' | head -n 1)

    if [ -z "$latest_version" ]; then
        echo -e "${RED}[ERROR] Failed to check latest version.${NC}"
        return
    fi

    if [[ "$latest_version" != "$current_version" ]]; then
        echo -e "${YELLOW}[UPDATE AVAILABLE] your version: ${current_version}, latest: ${latest_version}${NC}"
        echo -e "${CYAN}→ Open ${release_page} to download the latest version${NC}"
        echo ""
        read -r -p "Press [enter] to continue..."
    else
        echo -e "${GREEN}[OK] You're running the latest version (${current_version})${NC}"
    fi
}

# Function to clean up temporary files
function cleanup_temp() {
    echo -e "${YELLOW}[INFO] Cleaning up temporary files...${NC}"
    # Use /tmp/ (or Termux's equivalent via TMPDIR) for generic temporary files
    # Termux's default TMPDIR is typically /data/data/com.termux/files/usr/tmp or similar
    rm -f "${TMPDIR:-/tmp}/yt_temp_play.mp4" \
          "${TMPDIR:-/tmp}/yt_temp_play.mp4.mp3" \
          "${TMPDIR:-/tmp}/yt_temp.mp4" \
          "${TMPDIR:-/tmp}/yt_temp.mp4.mp3" \
          "${TMPDIR:-/tmp}/yt_search.tmp" \
          "${TMPDIR:-/tmp}/yt_selected_url.txt" \
          "${TMPDIR:-/tmp}/yt_dlp_search_err.log" \
          "${TMPDIR:-/tmp}/yt_dlp_formats_only*" \
          "${TMPDIR:-/tmp}/yt_dlp_raw_output*" \
          2>/dev/null
    echo -e "${GREEN}Done.${NC}"
}

# Function to clear all system temporary files (more aggressive)
function clear_all_temp() {
    echo -e "${YELLOW}[INFO] Clearing all user-specific temporary files...${NC}"
    # This is a very aggressive command and might affect other running programs.
    # Use with caution!
    rm -rf "$HOME/.cache/yt-dlp" 2>/dev/null
    # Use TMPDIR for /tmp/ equivalent in Termux
    rm -rf "${TMPDIR:-/tmp}/*" 2>/dev/null # This might require root privileges for some files and is very aggressive

    # If you remove /tmp/* above, these specific removals might be redundant,
    # but their syntax is now correct.
    rm -f "${TMPDIR:-/tmp}/yt_temp_play.mp4" \
          "${TMPDIR:-/tmp}/yt_temp_play.mp4.mp3" \
          "${TMPDIR:-/tmp}/yt_temp.mp4" \
          "${TMPDIR:-/tmp}/yt_temp.mp4.mp3" \
          "${TMPDIR:-/tmp}/yt_search.tmp" \
          "${TMPDIR:-/tmp}/yt_selected_url.txt" \
          "${TMPDIR:-/tmp}/yt_dlp_search_err.log" \
          "${TMPDIR:-/tmp}/yt_dlp_formats_only*" \
          "${TMPDIR:-/tmp}/yt_dlp_raw_output*" \
          2>/dev/null
    echo -e "${GREEN}Done.${NC}"
    read -r -p "Press [Enter] to go back."
}

# Function to display available formats for a URL
function show_formats() {
    local url="$1"
    echo -e "${CYAN}[INFO] Fetching available formats...${NC}" # Changed to CYAN

    # Use mktemp, which respects TMPDIR, so it's Termux-friendly
    local RAW_YTDLP_OUTPUT=$(mktemp) # File to capture all yt-dlp output
    local YTDLP_FORMATS_ONLY=$(mktemp) # File for only the format table

    # Run yt-dlp to list formats in table format (-F).
    # Redirect ALL output (stdout and stderr) to RAW_YTDLP_OUTPUT.
    "$YTDLP_BIN" -F "$url" &> "$RAW_YTDLP_OUTPUT"

    # Separate informational/warning messages from the format table.
    # The format table usually starts with "ID" and ends after the last format.
    # We'll extract lines *between* the 'ID' header and the end of file for formats.
    # All other lines (before ID, and warnings) go to stderr.

    # Identify the start of the format list (line containing "ID ")
    local start_line=$(grep -nE '^ID|^format code' "$RAW_YTDLP_OUTPUT" | head -n 1 | cut -d: -f1)

    if [ -z "$start_line" ]; then
        # If 'ID' header is not found, assume all output is warnings/errors
        cat "$RAW_YTDLP_OUTPUT" >&2
        echo -e "${YELLOW}(yt-dlp did not return a list of formats. Check warnings above.)${NC}"
        rm "$RAW_YTDLP_OUTPUT" "$YTDLP_FORMATS_ONLY"
        return 1 # Indicate failure
    fi

    # Print messages *before* the format list to stderr (as warnings/info)
    head -n $((start_line - 1)) "$RAW_YTDLP_OUTPUT" >&2

    # Extract only the format list into a separate temp file
    tail -n +$start_line "$RAW_YTDLP_OUTPUT" > "$YTDLP_FORMATS_ONLY"


    echo -e "${YELLOW}[Available video-only MP4 formats (select ID for video playback):]${NC}"
    # Filter for 'mp4' and 'video only', excluding DASH and unknown
    grep -E 'mp4.*video only' "$YTDLP_FORMATS_ONLY" | \
        grep -vE 'DASH video|unknown' || echo -e "${YELLOW}(None found.)${NC}"

    echo ""
    echo -e "${YELLOW}[Available audio-only formats (select ID for audio-only playback):]${NC}"
    # Filter for 'audio only', excluding DASH audio
    grep -E 'audio only' "$YTDLP_FORMATS_ONLY" | \
        grep -vE 'DASH audio' || echo -e "${YELLOW}(None found.)${NC}"
    echo ""

    # Clean up temporary files
    rm "$RAW_YTDLP_OUTPUT" "$YTDLP_FORMATS_ONLY"
}

# Main menu
function main_menu() {
    while true; do
        logo
        echo "Version: TermuxAlpha-1.1" # Updated version string
        echo ""
        echo "[1] Play video/audio by YouTube URL"
        echo "[2] Search YouTube Video"
        echo "[3] Clear Temp (recommended before playback)"
        echo "[4] Exit"
        echo ""
        echo -n "Select an option [1-4]: " # Prints the prompt without a newline
        read -r MENU_CHOICE                   # Reads the user's input

        case "$MENU_CHOICE" in
            1) paste_url ;;
            2) search_video ;;
            3) clear_all_temp ;;
            4) exit 0 ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                sleep 1
                ;;
        esac
    done
}

search_video() {
    cleanup_temp
    echo -e "${GREEN}temporary files cleaned.${NC}\n"

    while true; do
        echo -n "enter youtube search term (leave blank to return): "
        read -r SEARCH_QUERY
        [ -z "$SEARCH_QUERY" ] && return

        echo -e "${CYAN}[info] searching: \"$SEARCH_QUERY\"${NC}"

        # fetch and clean json using jq: extract id, title (escape newlines), and uploader
        mapfile -t SEARCH_RESULTS < <(
            "$YTDLP_BIN" "ytsearch${SEARCH_RESULT_LIMIT}:${SEARCH_QUERY}" --print-json |
            "$JQ_BIN" -r 'select(.id and .title) | [.id, (.title | gsub("\n"; " ") | gsub("\t"; " ")), .uploader] | @tsv'
        )

        if [ "${#SEARCH_RESULTS[@]}" -eq 0 ]; then
            echo -e "${RED}[error] no results found.${NC}"
            continue
        fi

        echo -e "${YELLOW}top ${SEARCH_RESULT_LIMIT} results:${NC}"
        for i in "${!SEARCH_RESULTS[@]}"; do
            IFS=$'\t' read -r VID TITLE UPLOADER <<< "${SEARCH_RESULTS[$i]}"
            printf "%2d) %s%s%s\n" "$((i+1))" "${TITLE}" "${UPLOADER:+  \e[90mby $UPLOADER\e[0m}"
        done
        echo -e "$((SEARCH_RESULT_LIMIT + 1))) back to menu"

        while true; do
            echo -n "choose a video [1-${SEARCH_RESULT_LIMIT}] or ${SEARCH_RESULT_LIMIT}+ to return: "
            read -r CHOICE

            if [[ "$CHOICE" =~ ^[0-9]+$ ]] && (( CHOICE >= 1 && CHOICE <= SEARCH_RESULT_LIMIT )); then
                IFS=$'\t' read -r VIDEO_ID _ <<< "${SEARCH_RESULTS[$((CHOICE-1))]}"
                VIDEO_URL="https://www.youtube.com/watch?v=${VIDEO_ID}"
                search_playback "$VIDEO_URL"
                break
            elif (( CHOICE == SEARCH_RESULT_LIMIT + 1 )); then
                return
            else
                echo -e "${RED}invalid option. try again.${NC}"
            fi
        done
    done
}

paste_url() {
    cleanup_temp
    echo -e "${GREEN}Cleaned old temp.${NC}\n"
    read -r -p "Enter YouTube URL: " YOUTUBE_URL
    [ -z "$YOUTUBE_URL" ] && return

    show_formats "$YOUTUBE_URL"

    read -r -p "Play audio only? (y/N): " AUDIO_CHOICE
    local AUDIO_ONLY=""
    [[ "$AUDIO_CHOICE" =~ ^[Yy]$ ]] && AUDIO_ONLY="yes"

    local VIDEO_QUALITY=""
    local MPV_OPTS_ARRAY=()
    [ -z "$AUDIO_ONLY" ] && {
        read -r -p "Enter format code (blank = best): " VIDEO_QUALITY
        MPV_OPTS_ARRAY=($(get_mpv_opts))
    }

    local OUTPUT_PATH="${TMPDIR:-/tmp}/yt_temp_play"
    rm -f "$OUTPUT_PATH"* 2>/dev/null

    echo -e "${CYAN}[INFO] Downloading...${NC}"
    if [ -n "$AUDIO_ONLY" ]; then
        "$YTDLP_BIN" --extract-audio --audio-format mp3 --no-mtime -o "${OUTPUT_PATH}.%(ext)s" "$YOUTUBE_URL"
    else
        local FORMAT="${VIDEO_QUALITY:+${VIDEO_QUALITY}+}bestaudio[ext=m4a]"
        "$YTDLP_BIN" -f "${FORMAT:-bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]}" \
            --merge-output-format mp4 --no-mtime -o "${OUTPUT_PATH}.mp4" "$YOUTUBE_URL"
    fi

    local FILE_TO_PLAY="${AUDIO_ONLY:+${OUTPUT_PATH}.mp3}"
    FILE_TO_PLAY="${FILE_TO_PLAY:-${OUTPUT_PATH}.mp4}"
    
    if [ -f "$FILE_TO_PLAY" ]; then
        clear
        echo -e "${GREEN}Playing...${NC}\n--------------------------"
        "$MPV_BIN" "${MPV_OPTS_ARRAY[@]}" "$FILE_TO_PLAY"
        echo -e "--------------------------\n${GREEN}Done.${NC}"
    else
        echo -e "${RED}[ERROR] Playback failed: file not found.${NC}"
    fi
    cleanup_temp
    read -r -p "Press Enter to continue..."
}

search_playback() {
    local url_to_play="$1"
    show_formats "$url_to_play"

    read -r -p "Play audio only? (y/N): " AUDIO_CHOICE
    local AUDIO_ONLY=""
    [[ "$AUDIO_CHOICE" =~ ^[Yy]$ ]] && AUDIO_ONLY="yes"

    local VIDEO_QUALITY=""
    local MPV_OPTS_ARRAY=()
    [ -z "$AUDIO_ONLY" ] && {
        read -r -p "Enter format code (blank = best): " VIDEO_QUALITY
        MPV_OPTS_ARRAY=($(get_mpv_opts))
    }

    local OUTPUT_PATH="${TMPDIR:-/tmp}/yt_temp_search"
    rm -f "$OUTPUT_PATH"* 2>/dev/null

    echo -e "${CYAN}[INFO] Downloading...${NC}"
    if [ -n "$AUDIO_ONLY" ]; then
        "$YTDLP_BIN" --extract-audio --audio-format mp3 --no-mtime -o "${OUTPUT_PATH}.%(ext)s" "$url_to_play"
    else
        local FORMAT="${VIDEO_QUALITY:+${VIDEO_QUALITY}+}bestaudio[ext=m4a]"
        "$YTDLP_BIN" -f "${FORMAT:-bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]}" \
            --merge-output-format mp4 --no-mtime -o "${OUTPUT_PATH}.mp4" "$url_to_play"
    fi

    local FILE_TO_PLAY="${AUDIO_ONLY:+${OUTPUT_PATH}.mp3}"
    FILE_TO_PLAY="${FILE_TO_PLAY:-${OUTPUT_PATH}.mp4}"

    if [ -f "$FILE_TO_PLAY" ]; then
        clear
        echo -e "${GREEN}Playing...${NC}\n--------------------------"
        "$MPV_BIN" "${MPV_OPTS_ARRAY[@]}" "$FILE_TO_PLAY"
        echo -e "--------------------------\n${GREEN}Done.${NC}"
    else
        echo -e "${RED}[ERROR] Playback failed: file not found.${NC}"
    fi
    cleanup_temp
    read -r -p "Press Enter to continue..."
}

get_mpv_opts() {
    local opts=()
    if [ -n "$GLOBAL_MPV_VO_OVERRIDE" ]; then
        opts+=("--vo=$GLOBAL_MPV_VO_OVERRIDE")
        echo -e "${CYAN}[INFO] Using MPV_VO override: $GLOBAL_MPV_VO_OVERRIDE${NC}"
    elif "$MPV_BIN" --vo=help 2>&1 | grep -q "tct"; then
        opts+=("--vo=tct")
        echo -e "${GREEN}[INFO] TCT support enabled${NC}"
    else
        opts+=("--vo=caca")
        echo -e "${YELLOW}[INFO] Falling back to ASCII (caca)${NC}"
    fi
    opts+=("--no-osd-bar" "--osd-level=0" "--quiet" "--no-config" "--profile=fast" "--hwdec=mediacodec")
    echo "${opts[@]}"
}


# --- Main Program Flow ---
setup_dependencies
check_for_updates
main_menu

