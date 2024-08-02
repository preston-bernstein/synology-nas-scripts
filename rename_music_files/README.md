# Music File Renamer Script

This script is designed to rename music files (both `.flac` and `.mp3`) on a Synology NAS according to a specified format. The script extracts metadata from the files and renames them to follow a consistent naming convention, either for single-disc or multi-disc albums.

## Features

- Supports `.flac` and `.mp3` files
- Extracts metadata using `ffprobe`
- Renames files according to specified formats
- Logs progress and errors for debugging and tracking
- Uses parallel processing for better performance

## Requirements

Ensure the following dependencies are installed on your Synology NAS:

- `ffprobe` (part of `ffmpeg`)
- `jq`
- `parallel`

## Installation

1. **Install Dependencies:**

   - **ffmpeg:**
     ```bash
     sudo synopkg install ffmpeg
     ```
   - **jq:**
     ```bash
     sudo ipkg install jq
     ```
   - **parallel:**
     ```bash
     sudo ipkg install parallel
     ```

2. **Download the Script:**

   Clone this repository or download the `rename_music_files.sh` script directly to your Synology NAS.

3. **Set Permissions:**

   Ensure the script has execute permissions:
   ```bash
   chmod +x /path/to/rename_music_files.sh

## Usage

1. **Edit the Script:**

Update the following variables in the script to match your setup:

```bash
MUSIC_DIR="/volume1/Media/Music"
LOG_DIR="/volume1/scripts/rename_music_files/rename_music_files"
```

2. **Run the Script:**

Execute the script manually or set up a scheduled task in the Synology DSM to run it periodically:

```bash
/path/to/rename_music_files.sh
```

## File Naming Convention

The script renames files to follow these formats:

- **Standard Track Format:**

  ```sql
  {Album Title} ({Release Year})/{Artist Name} - {Album Title} - {track:00} - {Track Title}
  ```

- **Multi-Disc Track Format:**
  
  ```sql
  {Album Title} ({Release Year})/{Medium Format} {medium:00}/{Artist Name} - {Album Title} - {track:00} - {Track Title}
  ```

## Logging

The script logs its progress and any errors to a log file located in the LOG_DIR directory. The log file is named with a timestamp to ensure uniqueness:

  ```bash
  /volume1/scripts/rename_music_files/rename_music_files/rename_music_files_YYYYMMDD_HHMMSS.log
  ```

## Troubleshooting

- **Missing Dependencies:** Ensure all required dependencies are installed and accessible from the script.
- **Permission Issues:** Verify that the script has the necessary permissions to read, write, and execute within the specified directories.
- **Log Files:** Check the log files for any errors or progress messages to help diagnose issues.

## Contributing

Feel free to fork this repository, make improvements, and submit pull requests. Contributions are welcome!

## License

This project is licensed under the MIT License. See the LICENSE file for details.
