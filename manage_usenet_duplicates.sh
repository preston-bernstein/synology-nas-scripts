#!/bin/bash

# Define paths
MEDIA_DIR="/volume1/Media"
DOWNLOADS_DIR="$MEDIA_DIR/Downloads"
COMPLETE_DIR="$DOWNLOADS_DIR/Usenet/complete"
MOVIES_DIR="$MEDIA_DIR/Movies"
MUSIC_DIR="$MEDIA_DIR/Music"
TV_SHOWS_DIR="$MEDIA_DIR/TV Shows"
LOGS_DIR="$DOWNLOADS_DIR/Usenet/logs"
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
LOG_FILE="$LOGS_DIR/manage_usenet_duplicates_$TIMESTAMP.log"

# Ensure logs directory exists
mkdir -p "$LOGS_DIR"

# ANSI color codes
RESET="\033[0m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"

# Function to log messages with color
log_message() {
    local color="$1"
    local message="$2"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - ${color}${message}${RESET}" >> "$LOG_FILE"
}

# Function to handle errors
handle_error() {
    log_message "$RED" "ERROR: $1"
    exit 1
}

# Function to normalize names for comparison
normalize_name() {
    local name="$1"
    echo "$name" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' ' ' | sed -E 's/ \(.*\)$//' | sed 's/[0-9]* //g'
}

# Function to determine file quality
get_file_quality() {
    local file="$1"
    case "${file##*.}" in
        flac) echo 3 ;;
        mp3) echo 2 ;;
        mkv) echo 3 ;;
        mp4) echo 2 ;;
        avi) echo 1 ;;
        *) echo 1 ;;  # Default to lowest quality if not recognized
    esac
}

# Function to get the disc number from the track name
get_disc_number() {
    local track_name="$1"
    if [[ "$track_name" =~ [Dd]isc[[:space:]]*([0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo 1
    fi
}

# Function to format the track name according to the FileBot naming convention
format_track_name() {
    local artist="$1"
    local album="$2"
    local year="$3"
    local disc="$4"
    local track="$5"
    local title="$6"
    local codec="$7"
    local format="$8"
    local khz="$9"
    local bitdepth="${10}"
    local bitrate="${11}"

    local formatted_name="${artist:-Unknown Artist}/${album:-Unknown Album}"
    if [[ -n "$year" ]]; then
        formatted_name+=" (${year})"
    fi
    formatted_name+="/"
    if [[ -n "$disc" ]]; then
        formatted_name+="CD ${disc}/"
    fi
    formatted_name+="${track:-00} - ${title:-Unknown Title} - (${codec:-N/A} ${format:-N/A} ${khz:-N/A} ${bitdepth:-N/A}bit ${bitrate:-N/A})"
    echo "$formatted_name"
}

# Function to consolidate highest quality music tracks
consolidate_album_tracks() {
    local album_dir="$1"
    local artist_name=$(basename "$(dirname "$album_dir")")
    local album_name=$(basename "$album_dir")
    local year=$(echo "$album_name" | grep -oP '\(\K[0-9]{4}(?=\))')

    declare -A track_map

    while IFS= read -r -d '' track; do
        local track_name
        track_name=$(basename "$track")
        log_message "$BLUE" "Processing track: $track_name"
        norm_track_name=$(normalize_name "$track_name")
        track_quality=$(get_file_quality "$track")
        disc_number=$(get_disc_number "$track_name")
        track_num=$(printf "%02d" "${track_name%% *}")
        title=$(echo "$track_name" | sed -E 's/[0-9]{2} - (.*) - \(.*/\1/')

        formatted_name=$(format_track_name "$artist_name" "$album_name" "$year" "$disc_number" "$track_num" "$title" "aco" "af" "khz" "bitdepth" "abr")

        target_dir="$MUSIC_DIR/$formatted_name"
        mkdir -p "$(dirname "$target_dir")"

        track_key="${disc_number}_${norm_track_name}"

        if [[ -n "${track_map[$track_key]}" ]]; then
            existing_track="${track_map[$track_key]}"
            existing_quality=$(get_file_quality "$existing_track")
            if (( track_quality > existing_quality )); then
                log_message "$GREEN" "Replacing lower quality track: $existing_track with higher quality track: $track"
                mv "$track" "$target_dir"
                rm -rf "$existing_track"
                track_map[$track_key]="$target_dir"
            else
                log_message "$YELLOW" "Keeping existing higher quality track: $existing_track, removing lower quality track: $track"
                rm -rf "$track"
            fi
        else
            log_message "$BLUE" "Keeping track: $track"
            mv "$track" "$target_dir"
            track_map[$track_key]="$target_dir"
        fi
    done < <(find "$album_dir" -type f -print0)
}

# Function to check and delete lower quality duplicates in target directories
remove_duplicates_in_target() {
    local source_file="$1"
    local target_dir="$2"

    while IFS= read -r -d '' target_file; do
        norm_source_name=$(normalize_name "$(basename "$source_file")")
        norm_target_name=$(normalize_name "$(basename "$target_file")")
        if [[ "$norm_source_name" == "$norm_target_name" ]]; then
            source_quality=$(get_file_quality "$source_file")
            target_quality=$(get_file_quality "$target_file")
            if (( source_quality > target_quality )); then
                log_message "$GREEN" "Removing lower quality target file: $target_file"
                rm -f "$target_file"
            else
                log_message "$YELLOW" "Removing lower quality source file: $source_file"
                rm -f "$source_file"
                return
            fi
        fi
    done < <(find "$target_dir" -type f -print0)
}

# Function to handle duplicates in the usenet complete folder
handle_usenet_duplicates() {
    local complete_dir="$1"

    while IFS= read -r -d '' file; do
        remove_duplicates_in_target "$file" "$MOVIES_DIR"
        remove_duplicates_in_target "$file" "$TV_SHOWS_DIR"
        remove_duplicates_in_target "$file" "$MUSIC_DIR"
    done < <(find "$complete_dir" -type f -print0)
}

# Function to consolidate duplicates across the usenet complete folder
consolidate_usenet_duplicates() {
    local complete_dir="$1"
    declare -A file_map

    while IFS= read -r -d '' file; do
        norm_file_name=$(normalize_name "$(basename "$file")")
        file_quality=$(get_file_quality "$file")

        if [[ -n "${file_map[$norm_file_name]}" ]]; then
            existing_file="${file_map[$norm_file_name]}"
            existing_quality=$(get_file_quality "$existing_file")
            if (( file_quality > existing_quality )); then
                log_message "$GREEN" "Replacing lower quality file: $existing_file with higher quality file: $file"
                rm -rf "$existing_file"
                file_map[$norm_file_name]="$file"
            else
                log_message "$YELLOW" "Keeping existing higher quality file: $existing_file, removing lower quality file: $file"
                rm -rf "$file"
            fi
        else
            log_message "$BLUE" "Keeping file: $file"
            file_map[$norm_file_name]="$file"
        fi
    done < <(find "$complete_dir" -type f -print0)
}

# Main function
main() {
    # Check if the usenet complete directory exists
    if [ ! -d "$COMPLETE_DIR" ]; then
        handle_error "Usenet complete directory '$COMPLETE_DIR' not found."
    fi

    log_message "$CYAN" "Starting usenet duplicates removal process."

    # Handle duplicates within the usenet complete folder
    consolidate_usenet_duplicates "$COMPLETE_DIR"

    # Check for duplicates in Movies, TV Shows, and Music directories
    handle_usenet_duplicates "$COMPLETE_DIR"

    log_message "$CYAN" "Usenet duplicates removal process completed."
}

main "$@"
