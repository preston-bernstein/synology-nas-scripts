#!/bin/bash

# Path to the main script
MAIN_SCRIPT="path/to/your/main/script.sh"

# Path to the test database
TEST_DB="path/to/test_database"

# Function to setup the test database
setup_test_database() {
    echo "Setting up test database..."

    mkdir -p "$TEST_DB/Downloads/Usenet/complete"
    mkdir -p "$TEST_DB/Downloads/Torrents/complete"
    mkdir -p "$TEST_DB/Media"

    echo "Dummy music file 1" > "$TEST_DB/Downloads/Usenet/complete/music1.flac"
    echo "Dummy music file 2" > "$TEST_DB/Downloads/Usenet/complete/music2.mp3"
    echo "Dummy music file 1" > "$TEST_DB/Downloads/Usenet/complete/duplicate_music1.flac"
    echo "Dummy video file 1" > "$TEST_DB/Downloads/Usenet/complete/video1.mkv"
    echo "Dummy video file 1" > "$TEST_DB/Downloads/Usenet/complete/duplicate_video1.mkv"
    echo "Dummy video file 2" > "$TEST_DB/Downloads/Usenet/complete/video2.mp4"

    echo "Dummy music file 1" > "$TEST_DB/Downloads/Torrents/complete/music1.flac"
    echo "Dummy music file 1" > "$TEST_DB/Downloads/Torrents/complete/duplicate_music1.flac"
    echo "Dummy video file 1" > "$TEST_DB/Downloads/Torrents/complete/video1.mkv"
    echo "Dummy video file 1" > "$TEST_DB/Downloads/Torrents/complete/duplicate_video1.mkv"

    echo "Dummy music file 1" > "$TEST_DB/Media/music1.flac"
    echo "Dummy video file 1" > "$TEST_DB/Media/video1.mkv"
    echo "Dummy video file 2" > "$TEST_DB/Media/video2.mp4"

    echo "Test database setup complete."
}

# Function to run the main script
run_main_script() {
    echo "Running the main script..."
    bash "$MAIN_SCRIPT"
}

# Function to verify the results
verify_results() {
    echo "Verifying results..."

    # Verify Usenet
    if [[ -f "$TEST_DB/Downloads/Usenet/complete/duplicate_music1.flac" ]]; then
        echo "Failed: duplicate_music1.flac should be deleted from Usenet"
    else
        echo "Passed: duplicate_music1.flac deleted from Usenet"
    fi

    if [[ -f "$TEST_DB/Downloads/Usenet/complete/duplicate_video1.mkv" ]]; then
        echo "Failed: duplicate_video1.mkv should be deleted from Usenet"
    else
        echo "Passed: duplicate_video1.mkv deleted from Usenet"
    fi

    # Verify Torrents
    if [[ -f "$TEST_DB/Downloads/Torrents/complete/duplicate_music1.flac" ]]; then
        echo "Failed: duplicate_music1.flac should be deleted from Torrents"
    else
        echo "Passed: duplicate_music1.flac deleted from Torrents"
    fi

    if [[ -f "$TEST_DB/Downloads/Torrents/complete/duplicate_video1.mkv" ]]; then
        echo "Failed: duplicate_video1.mkv should be deleted from Torrents"
    else
        echo "Passed: duplicate_video1.mkv deleted from Torrents"
    fi

    # Verify Media
    if [[ -f "$TEST_DB/Media/music1.flac" ]]; then
        echo "Passed: music1.flac kept in Media"
    else
        echo "Failed: music1.flac should be kept in Media"
    fi

    if [[ -f "$TEST_DB/Media/video1.mkv" ]]; then
        echo "Passed: video1.mkv kept in Media"
    else
        echo "Failed: video1.mkv should be kept in Media"
    fi

    if [[ -f "$TEST_DB/Media/video2.mp4" ]]; then
        echo "Passed: video2.mp4 kept in Media"
    else
        echo "Failed: video2.mp4 should be kept in Media"
    fi

    echo "Verification complete."
}

# Main function to run the test
main() {
    setup_test_database
    run_main_script
    verify_results
}

# Execute the main function
main
