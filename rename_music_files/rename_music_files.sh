#!/bin/bash

# Define your directories
MUSIC_DIR="/volume1/Media/Music"
LOG_DIR="/volume1/scripts/rename_music_files/rename_music_files"
LOG_FILE="$LOG_DIR/rename_music_files_$(date +%Y%m%d_%H%M%S).log"

# Ensure the log directory exists
mkdir -p "$LOG_DIR"
if [ $? -ne 0 ]; then
    echo "Failed to create log directory $LOG_DIR" >&2
    exit 1
fi

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Log function with timestamp
log() {
    echo -e "$(date +%Y-%m-%d\ %H:%M:%S) $1" | tee -a "$LOG_FILE"
}

# Dependency check for Synology NAS
if ! command -v ffprobe &> /dev/null; then
    log "${RED}Error: ffprobe is required but not installed. Please install ffmpeg package.${NC}"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    log "${RED}Error: jq is required but not installed. Please install jq package.${NC}"
    exit 1
fi

if ! command -v parallel &> /dev/null; then
    log "${RED}Error: GNU parallel is required but not installed. Please install parallel package.${NC}"
    exit 1
fi

# Log environment variables for debugging
log "${YELLOW}Environment variables:${NC}"
env | tee -a "$LOG_FILE"

# Function to extract metadata using ffprobe
extract_metadata() {
    file="$1"
    metadata=$(ffprobe -v quiet -print_format json -show_format -show_streams "$file")
    echo "$metadata"
}

# Function to parse metadata and return structured values
parse_metadata() {
    metadata="$1"
    album_title=$(echo "$metadata" | jq -r '.format.tags.album')
    release_year=$(echo "$metadata" | jq -r '.format.tags.date' | cut -d'-' -f1)
    artist_name=$(echo "$metadata" | jq -r '.format.tags.artist')
    track=$(echo "$metadata" | jq -r '.format.tags.track')
    track_title=$(echo "$metadata" | jq -r '.format.tags.title')
    disc=$(echo "$metadata" | jq -r '.format.tags.disc')
    media_format=$(echo "$metadata" | jq -r '.format.tags.media')

    echo "$album_title" "$release_year" "$artist_name" "$track" "$track_title" "$disc" "$media_format"
}

# Function to clean filename
clean_filename() {
    filename="$1"
    # Remove multiple number groups at the beginning
    base=$(echo "$filename" | sed -E 's/^([0-9]{1,2} - )+//')
    # Remove anything after the .flac or .mp3 extension
    base=$(echo "$base" | sed -E 's/\.(flac|mp3).*/.\1/')
    echo "$base"
}

# Function to construct new file path
construct_new_path() {
    album_title="$1"
    release_year="$2"
    artist_name="$3"
    track="$4"
    track_title="$5"
    disc="$6"
    media_format="$7"
    extension="$8"

    if [ -z "$disc" ]; then
        new_path="$album_title ($release_year)/$artist_name - $album_title - ${track} - $track_title.$extension"
    else
        new_path="$album_title ($release_year)/$media_format $disc/$artist_name - $album_title - ${track} - $track_title.$extension"
    fi

    echo "$new_path"
}

# Function to rename files in folder using GNU Parallel for parallel processing
rename_files_in_folder() {
    folder_path="$1"
    total_files=$(find "$folder_path" -type f \( -name "*.flac*" -o -name "*.mp3*" \) | wc -l)
    log "${YELLOW}Starting renaming process for $total_files files in $folder_path...${NC}"

    export -f extract_metadata parse_metadata clean_filename construct_new_path log

    find "$folder_path" -type f \( -name "*.flac*" -o -name "*.mp3*" \) | parallel --bar -j4 '
        base_dir=$(dirname "{}")
        old_filename=$(basename "{}")
        extension="${old_filename##*.}"

        metadata=$(extract_metadata "{}")
        read album_title release_year artist_name track track_title disc media_format < <(parse_metadata "$metadata")

        new_filename=$(construct_new_path "$album_title" "$release_year" "$artist_name" "$track" "$track_title" "$disc" "$media_format" "$extension")
        new_file="$base_dir/$new_filename"

        if [ "{}" != "$new_file" ]; then
            mkdir -p "$(dirname "$new_file")"
            if mv "{}" "$new_file"; then
                log "${GREEN}Success: Renamed {} -> $new_file${NC}"
            else
                log "${RED}Fail: Could not rename {} -> $new_file${NC}"
            fi
        fi
    '

    log "${YELLOW}Renaming process completed.${NC}"
}

# Main execution
log "${YELLOW}Script started at $(date).${NC}"

# Verify MUSIC_DIR exists
if [ ! -d "$MUSIC_DIR" ]; then
    log "${RED}Error: Music directory $MUSIC_DIR does not exist.${NC}"
    exit 1
fi

# Run the renaming process on MUSIC_DIR
rename_files_in_folder "$MUSIC_DIR"
log "${YELLOW}Renaming completed in $MUSIC_DIR.${NC}"
log "${YELLOW}Script finished at $(date).${NC}"
