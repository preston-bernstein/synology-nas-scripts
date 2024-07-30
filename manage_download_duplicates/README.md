# Overview
This is **manage_download_duplicates**, a script to organize and remove duplicate media files from downloaded directories on a Synology NAS. Accompanying this script is a test database generation script and a verification script to ensure the correctness of the main script.

## Directory Structure

```markdown
project/
├── main_script.sh
├── verify.sh
├── generate_test_db.sh
└── test_database/
    ├── Downloads/
    │   ├── Usenet/
    │   │   └── complete/
    │   └── Torrents/
    │       └── complete/
    └── Media/
```

## Setup
1. **Clone the repository**
   ```sh
   git clone <repository-url>
   cd project
   ```
2. **Ensure the required tools are installed:**
   - **`ffprobe`**
   - **`jq`**
   - **`sha256sum`**
   - **`xargs`**
3. **Generate the test database:**
   ```sh
   bash generate_test_db.sh /path/to/test_database
   ```
4. **Setup the test database** (optional if already generated)**:**
   ```sh
   bash verify.sh
   ```
### Running the Test
1. **Run the verification script:**
   ```sh
   bash verify.sh
   ```

This script will:
1. Set up the test database with sample media files.
2. Run the main script to process the media files.
3. Verify the results to ensure duplicates are handled correctly.
