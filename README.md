# Synology NAS Scripts

This repository contains useful scripts for managing and automating tasks on a Synology NAS. These scripts can help streamline various maintenance and management activities.

## Scripts

### `clear_unsorted.sh`

This script deletes the contents of the "unsorted" folder while keeping the folder itself intact.

#### Usage:

1. Save the script to your Synology NAS, preferably in a directory like `/volume1/scripts`.
2. Make the script executable by running the following command via SSH:
   ```bash
   chmod +x /volume1/scripts/clear_unsorted.sh
   ```
3. Schedule the script to run daily using Synology's Tash Scheduler:
   - Open Control Panel and navigate to Task Scheduler.
   - Create a new Scheduled Task with the following settings:
     - **General**: Name the task (e.g., "Clear Unsorted Folder") and set the user to "automaton".
     - **Schedule**: Set the frequency to "Daily" and the time to "00:00".
     - **Task Settings**: Enter the path to your script:
      ```bash
      /volume1/scripts/clear_unsorted.sh
      ```
      Replace `/volume1/path/to/your/unsorted/folder` with the actual path to your "unsorted" folder.

### `cleanup_logs.sh`

This script deletes all but the latest 30 log files in specified log directories.

#### Usage:

1. Save the script to your Synology NAS, preferably in a directory like **`/volume1/scripts`**.
2. Make the script executable by running the following command via SSH:
   ```bash
   chmod +x /volume1/scripts/cleanup_logs.sh
   ```
3. Update the script to include the paths to your log directories. Edit the **`LOG_DIRS`** array in the script to include the directories you want to manage:
  ```bash
  LOG_DIRS=("/config/logs1" "/config/logs2" "/configs/logs3")
  ```
4. Schedule the script to run daily using Synology's Task Scheduler:
   - Open Control Panel and navigate to Task Scheduler.
   - Create a new Scheduled Task with the following settings:
      - **General:** Name the task (e.g., "Cleanup Log Files") and set the user to your desired user to run automated tasks (ie: "automaton").
      - **Schedule:** Set the frequency to "Daily" and the time to "01:00".
      - **Task Settings:** Enter the path to your script:
        ```bash
        /volume1/scripts/cleanup_logs.sh
        ```

### `manage_download_duplicates.sh`

This script searches the Usenet and Torrents complete folders, deletes all duplicates while leaving the highest quality files, consolidates the highest quality music tracks from each folder, and ensures removal of lower quality duplicates in Movies and TV Shows folders.

#### Usage:

1. Save the script to your Synology NAS, preferably in a directory like `/volume1/scripts`.
2. Make the script executable by running the following command via SSH:
   ```bash
   chmod +x /volume1/scripts/manage_download_duplicates.sh
   ```
3. Ensure the folder structure is as follows:
   - **`/volume1/Media/Downloads`**
   - **`/volume1/Media/Movies`**
   - **`/volume1/Media/Music`**
   - **`/volume1/Media/TV Shows`**
4. Schedule the script to run daily using Synology's Task Scheduler:
   - Open Control Panel and navigate to Task Scheduler:
   - Create a new Scheduled Task with the following settings:
     - **General:** Name the task (e.g., "Manage Usenet Duplicates") and set the user to "automaton".
     - **Schedule:** Set the frequency to "Daily" and the time to "00:00".
     - **Task Settings:** Enter the path to your script:
       ```bash
       /volume1/scripts/manage_download_duplicates.sh
       ```

##### Test Database Generation

To ensure that the script works properly, you can generate a test database and run a verification script.

**`generate_test_db.sh`**

This script creates a test database with a variety of media files, including some duplicates.

###### Usage:

1. Save the script to your Synology NAS, preferably in a directory like **`/volume1/scripts`**.
2. Make the script executable by running the following command via SSH:
   ```bash
   chmod +x /volume1/scripts/generate_test_db.sh
   ```
3. Run the script to generate the test database:
   ```bash
   /volume1/scripts/generate_test_db.sh /path/to/test_database
   ```

   ```bash
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
   ```
**`verify.sh`**

This script runs the main script on the test database and verifies the results.

###### Usage:

1. Save the script to your Synology NAS, preferable in a directory like **`/volume1/scripts`**.
2. Make the script executable by running the following command via SSH:
```bash
/volume1/scripts.verify.sh
```

```bash
#!/bin/bash

# Path to the main script
MAIN_SCRIPT="/volume1/scripts/manage_download_duplicates.sh"

# Path to the test database
TEST_DB="/path/to/test_database"

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
```

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an Issue if you have any suggestions or improvements.
