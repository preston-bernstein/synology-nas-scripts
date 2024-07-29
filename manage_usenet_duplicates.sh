#!/bin/bash

# Define directories
MEDIA_DIR="/volume1/Media"
DOWNLOADS_DIR="$MEDIA_DIR/Downloads"
COMPLETE_DIR="$DOWNLOADS_DIR/Usenet/complete"
MOVIES_DIR="$MEDIA_DIR/Movies"
MUSIC_DIR="$MEDIA_DIR/Music"
TV_SHOWS_DIR="$MEDIA_DIR/TV Shows"
LOGS_DIR="$DOWNLOADS_DIR/Usenet/logs"
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
LOG_FILE="$LOGS_DIR/manage_usenet_duplicates_$TIMESTAMP.log"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to log messages with color
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Function to determine the quality of an audio file
get_audio_quality() {
    bitrate=$(ffmpeg -i "$1" 2>&1 | grep -oP '(?<=bitrate: )\d+')
    echo "$bitrate"
}

# Function to organize music files
organize_music() {
    log "${YELLOW}Starting to organize music files...${NC}"
    find "$COMPLETE_DIR" -type f -name "*.mp3" -or -name "*.flac" -or -name "*.m4a" | while read -r file; do
        log "Processing music file: $file"
        artist=$(ffprobe -v error -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 "$file")
        album=$(ffprobe -v error -show_entries format_tags=album -of default=noprint_wrappers=1:nokey=1 "$file")
        title=$(ffprobe -v error -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 "$file")
        cdnumber=$(ffprobe -v error -show_entries format_tags=disc -of default=noprint_wrappers=1:nokey=1 "$file")
        year=$(ffprobe -v error -show_entries format_tags=date -of default=noprint_wrappers=1:nokey=1 "$file")
        version=$(ffprobe -v error -show_entries format_tags=version -of default=noprint_wrappers=1:nokey=1 "$file")

        if [ -z "$cdnumber" ]; then
            cdnumber="1"
        fi

        if [ -n "$artist" ] && [ -n "$album" ] && [ -n "$title" ]; then
            # Create the base album directory, appending version info if it exists
            album_dir="$MUSIC_DIR/$artist/$album"
            if [ -n "$version" ]; then
                album_dir="$album_dir [$version]"
            fi
            if [ -n "$year" ]; then
                album_dir="$album_dir ($year)"
            fi

            cd_dir="$album_dir/CD $cdnumber"
            mkdir -p "$cd_dir"

            existing_file="$cd_dir/$(basename "$file")"
            if [ -f "$existing_file" ]; then
                log "Comparing qualities of $file and $existing_file"
                current_quality=$(get_audio_quality "$existing_file")
                new_quality=$(get_audio_quality "$file")
                if [ "$new_quality" -gt "$current_quality" ]; then
                    mv -f "$file" "$existing_file"
                    log "${GREEN}Replaced $existing_file with higher quality version${NC}"
                else
                    rm "$file"
                    log "${YELLOW}Deleted lower quality duplicate: $file${NC}"
                fi
            else
                mv "$file" "$cd_dir"
                log "${GREEN}Moved $file to $cd_dir${NC}"
            fi
        else
            log "${RED}Missing metadata for $file, skipping...${NC}"
        fi
    done
}

# Function to organize TV shows
organize_tvshows() {
    log "${YELLOW}Starting to organize TV shows...${NC}"
    find "$COMPLETE_DIR" -type f -name "*.mp4" -or -name "*.mkv" | while read -r file; do
        log "Processing TV show file: $file"
        show=$(ffprobe -v error -show_entries format_tags=show -of default=noprint_wrappers=1:nokey=1 "$file")
        season=$(ffprobe -v error -show_entries format_tags=season_number -of default=noprint_wrappers=1:nokey=1 "$file")

        if [ -n "$show" ] && [ -n "$season" ]; then
            season_dir="$TV_SHOWS_DIR/$show/Season $season"
            mkdir -p "$season_dir"
            mv "$file" "$season_dir"
            log "${GREEN}Moved $file to $season_dir${NC}"
        else
            log "${RED}Missing metadata for $file, skipping...${NC}"
        fi
    done
}

# Function to organize movies
organize_movies() {
    log "${YELLOW}Starting to organize movies...${NC}"
    find "$COMPLETE_DIR" -type f -name "*.mp4" -or -name "*.mkv" | while read -r file; do
        log "Processing movie file: $file"
        movie=$(ffprobe -v error -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 "$file")
        year=$(ffprobe -v error -show_entries format_tags=date -of default=noprint_wrappers=1:nokey=1 "$file")

        if [ -n "$movie" ]; then
            movie_dir="$MOVIES_DIR/$movie ($year)"
            mkdir -p "$movie_dir"
            mv "$file" "$movie_dir"
            log "${GREEN}Moved $file to $movie_dir${NC}"
        else
            log "${RED}Missing metadata for $file, skipping...${NC}"
        fi
    done
}

# Function to remove lower quality duplicates from the existing library
remove_lower_quality_duplicates() {
    log "${YELLOW}Starting to remove lower quality duplicates...${NC}"
    find "$MEDIA_DIR" -type f -name "*.mp3" -or -name "*.flac" -or -name "*.m4a" | while read -r file; do
        log "Checking for duplicates of: $file"
        artist=$(ffprobe -v error -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 "$file")
        album=$(ffprobe -v error -show_entries format_tags=album -of default=noprint_wrappers=1:nokey=1 "$file")
        title=$(ffprobe -v error -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 "$file")
        cdnumber=$(ffprobe -v error -show_entries format_tags=disc -of default=noprint_wrappers=1:nokey=1 "$file")
        year=$(ffprobe -v error -show_entries format_tags=date -of default=noprint_wrappers=1:nokey=1 "$file")
        version=$(ffprobe -v error -show_entries format_tags=version -of default=noprint_wrappers=1:nokey=1 "$file")

        if [ -z "$cdnumber" ]; then
            cdnumber="1"
        fi

        if [ -n "$artist" ] && [ -n "$album" ] && [ -n "$title" ]; then
            # Create the base album directory, appending version info if it exists
            album_dir="$MUSIC_DIR/$artist/$album"
            if [ -n "$version" ]; then
                album_dir="$album_dir [$version]"
            fi
            if [ -n "$year" ]; then
                album_dir="$album_dir ($year)"
            fi

            cd_dir="$album_dir/CD $cdnumber"
            mkdir -p "$cd_dir"

            existing_file="$cd_dir/$(basename "$file")"
            if [ -f "$existing_file" ]; then
                log "Comparing qualities of $file and $existing_file"
                current_quality=$(get_audio_quality "$existing_file")
                new_quality=$(get_audio_quality "$file")
                if [ "$new_quality" -gt "$current_quality" ]; then
                    mv -f "$file" "$existing_file"
                    log "${GREEN}Replaced $existing_file with higher quality version${NC}"
                else
                    rm "$file"
                    log "${YELLOW}Deleted lower quality duplicate: $file${NC}"
                fi
            else
                mv "$file" "$cd_dir"
                log "${GREEN}Moved $file to $cd_dir${NC}"
            fi
        else
            log "${RED}Missing metadata for $file, skipping...${NC}"
        fi
    done
}

# Run the organization functions
log "${YELLOW}Starting organization process...${NC}"
organize_music
organize_tvshows
organize_movies
remove_lower_quality_duplicates
log "${GREEN}Organization complete.${NC}"
