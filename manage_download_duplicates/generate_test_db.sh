#!/bin/bash

# Function to create the directory structure and sample files
generate_test_db() {
    local test_db="$1"

    echo "Setting up test database at $test_db..."

    # Create the directory structure
    mkdir -p "$test_db/Downloads/Usenet/complete"
    mkdir -p "$test_db/Downloads/Torrents/complete"
    mkdir -p "$test_db/Media"

    # Create sample media files
    echo "Dummy music file 1" > "$test_db/Downloads/Usenet/complete/music1.flac"
    echo "Dummy music file 2" > "$test_db/Downloads/Usenet/complete/music2.mp3"
    echo "Dummy music file 1" > "$test_db/Downloads/Usenet/complete/duplicate_music1.flac"
    echo "Dummy video file 1" > "$test_db/Downloads/Usenet/complete/video1.mkv"
    echo "Dummy video file 1" > "$test_db/Downloads/Usenet/complete/duplicate_video1.mkv"
    echo "Dummy video file 2" > "$test_db/Downloads/Usenet/complete/video2.mp4"

    echo "Dummy music file 1" > "$test_db/Downloads/Torrents/complete/music1.flac"
    echo "Dummy music file 1" > "$test_db/Downloads/Torrents/complete/duplicate_music1.flac"
    echo "Dummy video file 1" > "$test_db/Downloads/Torrents/complete/video1.mkv"
    echo "Dummy video file 1" > "$test_db/Downloads/Torrents/complete/duplicate_video1.mkv"

    echo "Dummy music file 1" > "$test_db/Media/music1.flac"
    echo "Dummy video file 1" > "$test_db/Media/video1.mkv"
    echo "Dummy video file 2" > "$test_db/Media/video2.mp4"

    echo "Test database setup complete."
}

# Check if the test database path is provided
if [[ -z "$1" ]]; then
    echo "Usage: $0 <path-to-test-db>"
    exit 1
fi

# Generate the test database
generate_test_db "$1"
