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
    echo -e "${YELLOW}    [!] For the best results with terminal pixel graphics,"
    echo -e "        your terminal *must* support Sixel (e.g., foot, mlterm, Kitty,"
    echo -e "        Alacritty configured with Sixel.).${NC}"
    echo ""
    echo ""
}

# Function to check and install dependencies
function setup_dependencies() {
    echo -e "${GREEN}[INFO] Checking and installing dependencies...${NC}"

    # Create the local bin directory if it doesn't exist
    if [ ! -d "${BIN_DIR}" ]; then
        echo -e "${CYAN}[INFO] Creating local bin directory: ${BIN_DIR}${NC}" # Changed to CYAN
        mkdir -p "${BIN_DIR}" || { echo -e "${RED}[ERROR] Failed to create ${BIN_DIR}. Check permissions.${NC}"; read -p "Press Enter to abort..."; exit 1; }
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
        read -p "Press Enter to abort..."
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
                read -p "Press Enter to abort..."
                exit 1
            fi
        elif [ "$PKG_MANAGER" = "apt" ]; then
            if ! sudo apt update || ! sudo apt install -y "${packages_to_install[@]}"; then
                echo -e "${RED}[ERROR] Failed to install one or more apt dependencies. Please install them manually and try again.${NC}"
                read -p "Press Enter to abort..."
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
        read -p "Press Enter to abort..."
        exit 1
    fi

    echo -e "${GREEN}[WORK-DONE] yt-dlp updated to latest from GitHub in ${YTDLP_BIN}.${NC}"

    echo -e "${GREEN}[WORK-DONE] All dependencies checked and installed/updated.${NC}"
    sleep 2
    return 0
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
    read -p "Press [Enter] to go back."
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
        echo "Version: Termux-1.0" # Updated version string
        echo ""
        echo "[1] Play video/audio by YouTube URL"
        echo "[2] Search YouTube Video"
        echo "[3] Clear Temp (recommended before playback)"
        echo "[4] Exit"
        echo ""
        echo -n "Select an option [1-4]: " # Prints the prompt without a newline
        read MENU_CHOICE                   # Reads the user's input

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

function search_video() {
    cleanup_temp
    echo -e "${GREEN}Done cleaning temp files.${NC}"
    echo ""

    while true; do
        echo -n "Enter search term for YouTube (leave blank to return to menu): "
        read SEARCH_QUERY
        if [ -z "$SEARCH_QUERY" ]; then
            return # Go back to main menu if blank
        fi

        echo -e "${CYAN}[INFO] Searching YouTube for: $SEARCH_QUERY${NC}" # Changed to CYAN
        # Search and get N results as JSON
        SEARCH_RESULTS=$("$YTDLP_BIN" "ytsearch${SEARCH_RESULT_LIMIT}:${SEARCH_QUERY}" --print-json | "$JQ_BIN" -r '.id + " | " + .title')

        if [ -z "$SEARCH_RESULTS" ]; then
            echo -e "${RED}[ERROR] No results found, try another search.${NC}"
            continue
        fi

        echo -e "${YELLOW}Top $SEARCH_RESULT_LIMIT results:${NC}"
        IFS=$'\n'; select RESULT in $SEARCH_RESULTS "Back to menu"; do
            if [[ "$REPLY" == "$((SEARCH_RESULT_LIMIT + 1))" || "$RESULT" == "Back to menu" ]]; then
                return
            elif [[ -n "$RESULT" ]]; then
                VIDEO_ID=$(echo "$RESULT" | cut -d" " -f1)
                # Correct YouTube URL construction
                VIDEO_URL="https://www.youtube.com/watch?v=${VIDEO_ID}"
                search_playback "$VIDEO_URL"
                break
            else
                echo "Invalid option, try again."
            fi
        done
    done
}

# Play video by URL
function paste_url() {
    cleanup_temp
    echo -e "${GREEN}Done cleaning old video temp.${NC}"
    echo ""
    read -p "Enter YouTube URL: " YOUTUBE_URL

    if [ -z "$YOUTUBE_URL" ]; then
        return
    fi

    show_formats "$YOUTUBE_URL"

    AUDIO_ONLY=""
    read -p "Play audio only? (y/N): " AUDIO_CHOICE
    [[ "$AUDIO_CHOICE" =~ ^[Yy]$ ]] && AUDIO_ONLY="yes"

    VIDEO_QUALITY=""
    local MPV_OPTS_ARRAY=()

    # Automatically set terminal video options if not playing audio only
    if [ -z "$AUDIO_ONLY" ]; then
        read -p "Enter format code for desired quality (e.g., 137 for 1080p, leave blank for best quality): " VIDEO_QUALITY

        # Check for global override first (e.g., MPV_VO=caca)
        if [ -n "$GLOBAL_MPV_VO_OVERRIDE" ]; then
            MPV_OPTS_ARRAY=("--vo=$GLOBAL_MPV_VO_OVERRIDE" "--no-osd-bar" "--osd-level=0" "--quiet" "--no-config" "--profile=fast" "--hwdec=auto")
            echo -e "${CYAN}[INFO] Forced playback mode: --vo=$GLOBAL_MPV_VO_OVERRIDE (via MPV_VO environment variable).${NC}" # Changed to CYAN
            if [ "$GLOBAL_MPV_VO_OVERRIDE" == "caca" ]; then
                echo -e "${YELLOW}Note: Expect significant resolution reduction and performance trade-offs with caca.${NC}"
            elif [ "$GLOBAL_MPV_VO_OVERRIDE" == "tct" ]; then
                echo -e "${YELLOW}Note: Best results with true-color terminal. Performance may still be limited.${NC}"
            fi
        else # No override, proceed with automatic detection (TCT then Caca)
            echo -e "${CYAN}[INFO] Attempting terminal video playback (TCT/Caca fallback)...${NC}" # Changed to CYAN
            # Check if mpv supports tct video output
            if "$MPV_BIN" --vo=help 2>&1 | grep -q "tct"; then
                MPV_OPTS_ARRAY=("--vo=tct" "--no-osd-bar" "--osd-level=0" "--quiet" "--no-config" "--profile=fast" "--hwdec=auto")
                echo -e "${GREEN}[WORK-DONE] TCT support detected and enabled for mpv. Expect better color.${NC}"
                echo -e "${YELLOW}Note: Best results with a true-color compatible terminal. Performance may still be limited.${NC}"
            else
                MPV_OPTS_ARRAY=("--vo=caca" "--no-osd-bar" "--osd-level=0" "--quiet" "--no-config" "--profile=fast" "--hwdec=auto")
                echo -e "${YELLOW}[WARNING] TCT support not detected for mpv. Falling back to ASCII art (caca).${NC}"
                echo -e "${YELLOW}Note: Expect significant resolution reduction and performance trade-offs with caca.${NC}"
            fi
            # Provide override instruction for caca
            echo -e "${YELLOW}    To force ASCII (caca) if TCT is not preferred, run: ${NC}${CYAN}MPV_VO=caca ./GlauTude.sh${NC}"
            echo -e "${NC}"
        fi
        sleep 2 # Give user time to read the message
    fi

    # Use TMPDIR for Termux compatibility
    local OUTPUT_PATH="${TMPDIR:-/tmp}/yt_temp_play.mp4"
    rm -f "$OUTPUT_PATH" 2>/dev/null

    echo -e "${CYAN}[INFO] Starting download...${NC}" # Changed to CYAN
    if [ -n "$AUDIO_ONLY" ]; then
        "$YTDLP_BIN" --extract-audio --audio-format mp3 -o "$OUTPUT_PATH" "$YOUTUBE_URL"
    elif [ -n "$VIDEO_QUALITY" ]; then
        "$YTDLP_BIN" -f "${VIDEO_QUALITY}+bestaudio[ext=m4a]" --merge-output-format mp4 -o "$OUTPUT_PATH" "$YOUTUBE_URL"
    else
        "$YTDLP_BIN" -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]" --merge-output-format mp4 -o "$OUTPUT_PATH" "$YOUTUBE_URL"
    fi

local FILE_TO_PLAY="$OUTPUT_PATH" # Default to the video path

    # If audio-only, the actual file to play will have .mp3 extension
    if [ -n "$AUDIO_ONLY" ]; then
        FILE_TO_PLAY="${OUTPUT_PATH}.mp3"
    fi

    if [ -f "$FILE_TO_PLAY" ]; then
        clear
        echo -e "${GREEN}Starting playback...${NC}"
        echo -e "-----------------------------------------------------"
        "$MPV_BIN" "${MPV_OPTS_ARRAY[@]}" "$FILE_TO_PLAY" # Play the correct file
        echo -e "-----------------------------------------------------"
        cleanup_temp
        echo -e "${GREEN}Done.${NC}"
        read -p "Press Enter to continue..."
    else
        echo -e "${RED}[ERR] Download or playback failed! The file '$FILE_TO_PLAY' was not found.${NC}" # More specific error message
        cleanup_temp
        read -p "Press Enter to continue..."
    fi
} # Correct closing brace for paste_url function

# Search YouTube video
function search_playback() {
    local url_to_play="$1"

    show_formats "$url_to_play"

    AUDIO_ONLY=""
    read -p "Play audio only? (y/N): " AUDIO_CHOICE
    [[ "$AUDIO_CHOICE" =~ ^[Yy]$ ]] && AUDIO_ONLY="yes"

    VIDEO_QUALITY=""
    local MPV_OPTS_ARRAY=()

    # Automatically set terminal video options if not playing audio only
    if [ -z "$AUDIO_ONLY" ]; then
        read -p "Enter format code for desired quality (e.g., 137 for 1080p, leave blank for best quality): " VIDEO_QUALITY

        # Check for global override first (e.g., MPV_VO=caca)
        if [ -n "$GLOBAL_MPV_VO_OVERRIDE" ]; then
            MPV_OPTS_ARRAY=("--vo=$GLOBAL_MPV_VO_OVERRIDE" "--no-osd-bar" "--osd-level=0" "--quiet" "--no-config" "--profile=fast" "--hwdec=auto")
            echo -e "${CYAN}[INFO] Forced playback mode: --vo=$GLOBAL_MPV_VO_OVERRIDE (via MPV_VO environment variable).${NC}" # Changed to CYAN
            if [ "$GLOBAL_MPV_VO_OVERRIDE" == "caca" ]; then
                echo -e "${YELLOW}Note: Expect significant resolution reduction and performance trade-offs with caca.${NC}"
            elif [ "$GLOBAL_MPV_VO_OVERRIDE" == "tct" ]; then
                echo -e "${YELLOW}Note: Best results with true-color terminal. Performance may still be limited.${NC}"
            fi
        else # No override, proceed with automatic detection (TCT then Caca)
            echo -e "${CYAN}[INFO] Attempting terminal video playback (TCT/Caca fallback)...${NC}" # Changed to CYAN
            # Check if mpv supports tct video output
            if "$MPV_BIN" --vo=help 2>&1 | grep -q "tct"; then
                MPV_OPTS_ARRAY=("--vo=tct" "--no-osd-bar" "--osd-level=0" "--quiet" "--no-config" "--profile=fast" "--hwdec=auto")
                echo -e "${GREEN}[WORK-DONE] TCT support detected and enabled for mpv. Expect better color.${NC}"
                echo -e "${YELLOW}Note: Best results with a true-color compatible terminal. Performance may still be limited.${NC}"
            else
                MPV_OPTS_ARRAY=("--vo=caca" "--no-osd-bar" "--osd-level=0" "--quiet" "--no-config" "--profile=fast" "--hwdec=auto")
                echo -e "${YELLOW}[WARNING] TCT support not detected for mpv. Falling back to ASCII art (caca).${NC}"
                echo -e "${YELLOW}Note: Expect significant resolution reduction and performance trade-offs with caca.${NC}"
            fi
            # Provide override instruction for caca
            echo -e "${YELLOW}    To force ASCII (caca) if TCT is not preferred, run: ${NC}${CYAN}MPV_VO=caca ./GlauTude.sh${NC}"
            echo -e "${NC}"
        fi
        sleep 2 # Give user time to read the message
    fi

    # Use TMPDIR for Termux compatibility
    local OUTPUT_PATH="${TMPDIR:-/tmp}/yt_temp.mp4" # Different temp file for search_playback
    rm -f "$OUTPUT_PATH" 2>/dev/null

    echo -e "${CYAN}[INFO] Starting download...${NC}" # Changed to CYAN
    if [ -n "$AUDIO_ONLY" ]; then
        "$YTDLP_BIN" --extract-audio --audio-format mp3 -o "$OUTPUT_PATH" "$url_to_play"
    elif [ -n "$VIDEO_QUALITY" ]; then
        "$YTDLP_BIN" -f "${VIDEO_QUALITY}+bestaudio[ext=m4a]" --merge-output-format mp4 -o "$OUTPUT_PATH" "$url_to_play"
    else
        "$YTDLP_BIN" -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]" --merge-output-format mp4 -o "$OUTPUT_PATH" "$url_to_play"
    fi

    local FILE_TO_PLAY="$OUTPUT_PATH" # Default to the video path

    # If audio-only, the actual file to play will have .mp3 extension
    if [ -n "$AUDIO_ONLY" ]; then
        FILE_TO_PLAY="${OUTPUT_PATH}.mp3"
    fi

    if [ -f "$FILE_TO_PLAY" ]; then
        clear
        echo -e "${GREEN}Starting playback...${NC}"
        echo -e "-----------------------------------------------------"
        "$MPV_BIN" "${MPV_OPTS_ARRAY[@]}" "$FILE_TO_PLAY" # Play the correct file
        echo -e "-----------------------------------------------------"
        cleanup_temp
        echo -e "${GREEN}Done.${NC}"
        read -p "Press Enter to continue..."
    else
        echo -e "${RED}[ERR] Download or playback failed! The file '$FILE_TO_PLAY' was not found.${NC}" # More specific error message
        cleanup_temp
        read -p "Press Enter to continue..."
    fi
} # This closing brace is already there for search_playback

# --- Main Program Flow ---
setup_dependencies
main_menu
