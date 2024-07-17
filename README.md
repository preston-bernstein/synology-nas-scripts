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

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an Issue if you have any suggestions or improvements.
