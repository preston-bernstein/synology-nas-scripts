#!/bin/bash

# Create log directory if it doesn't exist
LOG_DIR="/volume1/scripts/manage_download_duplicates/logs"
mkdir -p "$LOG_DIR"

# Generate a log file name with the current timestamp
LOG_FILE="$LOG_DIR/manage_download_duplicates_$(date +'%Y%m%d_%H%M%S').log"

# Ensure required tools are available
command -v ffprobe >/dev/null 2>&1 || { echo >&2 "ffprobe is required but it's not installed. Aborting."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo >&2 "jq is required but it's not installed. Aborting."; exit 1; }
command -v sha256sum >/dev/null 2>&1 || { echo >&2 "sha256sum is required but it's not installed. Aborting."; exit 1; }
command -v xargs >/dev/null 2>&1 || { echo >&2 "xargs is required but it's not installed. Aborting."; exit 1; }

# Function to log messages with timestamps
log() {
    local type="$1"; shift
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') [${type}] $*" | tee -a "$LOG_FILE"
}

# Initialize counters
files_deleted=0
folders_deleted=0
folders_kept=0
duplicates_kept=0

# Metadata and hash caches
declare -A metadata_cache
declare -A quality_cache
declare -A hash_cache

log INFO "Starting organization process..."

# Function to extract metadata from a media file
# Caches the metadata to avoid redundant operations
get_metadata() {
    local file="$1"
    if [[ -n "${metadata_cache["$file"]}" ]]; then
        echo "${metadata_cache["$file"]}"
    else
        local metadata
        metadata=$(ffprobe -v quiet -print_format json -show_format "$file" | jq .format.tags)
        if [[ $? -ne 0 ]]; then
            log ERROR "Failed to extract metadata from: $file"
        fi
        metadata_cache["$file"]=$metadata
        echo "$metadata"
    fi
}

# Function to normalize metadata for comparison
# Removes unnecessary fields that may differ but do not affect content identity
normalize_metadata() {
    local metadata="$1"
    echo "$metadata" | jq -c 'del(.comment, .encoded_by, .encoder, .language, .major_brand, .minor_version, .compatible_brands)'
}

# Function to compute and cache the hash of a file
get_file_hash() {
    local file="$1"
    if [[ -n "${hash_cache["$file"]}" ]]; then
        echo "${hash_cache["$file"]}"
    else
        local hash
        hash=$(sha256sum "$file" | awk '{ print $1 }')
        if [[ $? -ne 0 ]]; then
            log ERROR "Failed to compute hash for: $file"
        fi
        hash_cache["$file"]=$hash
        echo "$hash"
    fi
}

# Function to extract and cache the quality of a media file
get_quality() {
    local file="$1"
    if [[ -n "${quality_cache["$file"]}" ]]; then
        echo "${quality_cache["$file"]}"
    else
        local quality
        quality=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height,bit_rate,codec_name -of default=nw=1:nk=1 "$file" | tr '\n' ' ')
        if [[ $? -ne 0 ]]; then
            log ERROR "Failed to extract quality from: $file"
        fi
        quality_cache["$file"]=$quality
        echo "$quality"
    fi
}

# Function to compare qualities of two media files
# Returns 1 if the first file is of higher quality, otherwise 0
compare_quality() {
    local quality1="$1"
    local quality2="$2"
    IFS=' ' read -r -a q1 <<< "$quality1"
    IFS=' ' read -r -a q2 <<< "$quality2"

    # Compare width, height, bit rate, and codec name
    if [[ "${q1[0]}" -gt "${q2[0]}" ]] || 
       [[ "${q1[0]}" -eq "${q2[0]}" && "${q1[1]}" -gt "${q2[1]}" ]] || 
       [[ "${q1[0]}" -eq "${q2[0]}" && "${q1[1]}" -eq "${q2[1]}" && "${q1[2]}" -gt "${q2[2]}" ]] || 
       [[ "${q1[0]}" -eq "${q2[0]}" && "${q1[1]}" -eq "${q2[1]}" && "${q1[2]}" -eq "${q2[2]}" && "${q1[3]}" == "${q2[3]}" ]]; then
        echo 1
    else
        echo 0
    fi
}

# Function to detect similar filenames using Levenshtein distance
# Returns 1 if filenames are similar, otherwise 0
is_similar_filename() {
    local file1="$1"
    local file2="$2"
    similarity=$(echo $(basename "$file1") $(basename "$file2") | awk '
    BEGIN {
        FS=""
        split("", a)
        split("", b)
    }
    {
        for (i = 1; i <= length($1); i++) a[i] = substr($1, i, 1)
        for (i = 1; i <= length($2); i++) b[i] = substr($2, i, 1)
        m = length(a)
        n = length(b)
        for (i = 0; i <= m; i++) d[i,0] = i
        for (j = 0; j <= n; j++) d[0,j] = j
        for (i = 1; i <= m; i++) {
            for (j = 1; j <= n; j++) {
                cost = (a[i] == b[j]) ? 0 : 1
                d[i,j] = min(d[i-1,j] + 1, d[i,j-1] + 1, d[i-1,j-1] + cost)
            }
        }
        print d[m,n]
    }
    function min(x,y,z) {
        return (x <= y && x <= z) ? x : (y <= z) ? y : z
    }')
    if [ "$similarity" -lt 3 ]; then
        echo 1
    else
        echo 0
    fi
}

# Function to process a music file
# Checks for duplicate tracks based on metadata
process_music_file() {
    local file="$1"
    local metadata
    metadata=$(get_metadata "$file")
    normalized_metadata=$(normalize_metadata "$metadata")

    # Check for duplicates in the media folder
    for existing_file in /volume1/Media/*; do
        if [[ -f "$existing_file" ]]; then
            existing_metadata=$(get_metadata "$existing_file")
            normalized_existing_metadata=$(normalize_metadata "$existing_metadata")

            if [[ "$normalized_metadata" == "$normalized_existing_metadata" ]]; then
                log WARN "Duplicate music track found, deleting: $file"
                rm -f "$file" || log ERROR "Failed to delete file: $file"
                files_deleted=$((files_deleted + 1))
                return 0
            fi
        fi
    done

    log INFO "Unique music track, keeping: $file"
    return 1
}

# Function to process a video file
# Checks for duplicate videos based on hash and quality
process_video_file() {
    local file="$1"
    local quality
    quality=$(get_quality "$file")
    file_hash=$(get_file_hash "$file")

    # Check for duplicates in the media folder
    for existing_file in /volume1/Media/*; do
        if [[ -f "$existing_file" ]]; then
            existing_hash=$(get_file_hash "$existing_file")
            if [[ "$file_hash" == "$existing_hash" ]]; then
                log WARN "Duplicate video file found, deleting: $file"
                rm -f "$file" || log ERROR "Failed to delete file: $file"
                files_deleted=$((files_deleted + 1))
                return 0
            fi

            local existing_quality
            existing_quality=$(get_quality "$existing_file")
            if [[ $(compare_quality "$quality" "$existing_quality") -eq 1 ]]; then
                log INFO "Higher quality video file found, keeping: $file and deleting: $existing_file"
                rm -f "$existing_file" || log ERROR "Failed to delete file: $existing_file"
                files_deleted=$((files_deleted + 1))
                return 1
            fi
        fi
    done
    log INFO "Unique video file, keeping: $file"
    return 1
}

# Function to process a folder for duplicates
# Removes duplicate folders and deletes empty folders
process_folder() {
    local folder="$1"
    local duplicate_found=false

    # Check for duplicate folders
    for subfolder in "$folder"/*; do
        if [ -d "$subfolder" ]; then
            if [ "$(basename "$subfolder")" == "$(basename "$folder")" ]; then
                log WARN "Duplicate folder found: $subfolder"
                rm -rf "$subfolder" || log ERROR "Failed to delete folder: $subfolder"
                folders_deleted=$((folders_deleted + 1))
                duplicate_found=true
            fi
        fi
    done

    if ! $duplicate_found; then
        folders_kept=$((folders_kept + 1))
    else
        duplicates_kept=$((duplicates_kept + 1))
    fi

    # Remove empty folders
    find "$folder" -type d -empty -delete || log ERROR "Failed to remove empty folder: $folder"
}

# Function to process a batch of files in parallel
process_batch() {
    local batch=("$@")
    for file in "${batch[@]}"; do
        if [[ -f "$file" ]]; then
            log INFO "Processing file: $file"
            case "${file##*.}" in
                flac|mp3)
                    process_music_file "$file" &
                    ;;
                mp4|mkv|avi)
                    process_video_file "$file" &
                    ;;
                *)
                    log INFO "Unsupported file type, skipping: $file"
                    ;;
            esac
        elif [[ -d "$file" ]]; then
            log INFO "Processing folder: $file"
            process_folder "$file" &
        fi
    done
    wait
}

# Function to organize files in a directory using batch processing
organize_files_in_directory() {
    local dir="$1"
    log INFO "Starting to organize files in $dir..."
    
    find "$dir" -mindepth 1 -maxdepth 1 -print0 | xargs -0 -n 10 -P 4 bash -c '
    batch=("$@")
    process_batch "${batch[@]}"
    ' _
}

# Trap function to log and handle errors
trap 'log ERROR "An error occurred on line $LINENO. Exiting..."; exit 1;' ERR

# Main function to manage duplicates
main() {
    # Organize files in Usenet and Torrents complete folders
    organize_files_in_directory "/volume1/Media/Downloads/Usenet/complete"
    organize_files_in_directory "/volume1/Media/Downloads/Torrents/complete"

    log INFO "Organization process complete."
    log INFO "Summary:"
    log INFO "Files Deleted: $files_deleted"
    log INFO "Folders Deleted: $folders_deleted"
    log INFO "Folders Kept: $folders_kept"
    log INFO "Duplicates Kept: $duplicates_kept"
}

# Execute the main function
main
