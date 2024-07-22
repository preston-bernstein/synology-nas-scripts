# Synology NAS Scripts

This repository contains useful scripts for managing and automating tasks on a Synology NAS. These scripts can help streamline various maintenance and management activities.

## Scripts

### `clear_unsorted.sh`

This script deletes the contents of the "unsorted" folder while keeping the folder itself intact.

**Usage:**

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

**Usage:**

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

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an Issue if you have any suggestions or improvements.
