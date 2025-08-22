# DisplayLink Driver Manager for Ubuntu

A robust and user-friendly shell script to automate the installation and uninstallation of DisplayLink USB Graphics drivers on Ubuntu and its derivatives (like Pop!_OS, Linux Mint, etc.).

This script improves upon the manual installation process by providing error handling, dependency management, and a clean uninstall option.

## Features

-   ✅ **Install & Uninstall**: Easily install or completely uninstall the DisplayLink driver with a simple command.
-   ⚙️ **Automatic Dependency Handling**: Checks for and installs required packages like `dkms` and `unzip`.
-   🛡️ **Robust & Safe**: The script exits immediately if any command fails (`set -e`) and uses secure temporary directories for downloads.
-   📝 **Detailed Logging**: All actions are logged to `/var/log/displaylink-installer.log` for easy troubleshooting.
-   🎨 **User-Friendly Output**: Color-coded terminal output makes it easy to follow the script's progress.
-   ✨ **Automatic Cleanup**: Temporary files and directories are automatically removed after execution.

## Prerequisites

-   An Ubuntu-based Linux distribution (e.g., Ubuntu 20.04/22.04, Pop!_OS, Linux Mint).
-   `sudo` or root privileges.
-   An active internet connection to download the driver.

## Usage

You can either clone this repository or download the script directly.

### 1. Get the Script

**Option A: Clone the repository (recommended)**

```sh
git clone [https://github.com/Thugney/Displaylink-ubuntu-installer.git](https://github.com/Thugney/Displaylink-ubuntu-installer.git)
cd Displaylink-ubuntu-installer
```

**Option B: Download the script directly**

```sh
wget [https://raw.githubusercontent.com/Thugney/Displaylink-ubuntu-installer/main/manage-displaylink.sh](https://raw.githubusercontent.com/Thugney/Displaylink-ubuntu-installer/main/manage-displaylink.sh)
```

### 2. Make the Script Executable

Before running the script, you need to give it execute permissions.

```sh
chmod +x manage-displaylink.sh
```

### 3. Run the Script

Run the script with `sudo` and choose one of the available options.

#### To Install the Driver:

This is the default action. The script will download the latest DisplayLink driver, install dependencies, and run the official installer.

```sh
sudo ./manage-displaylink.sh --install
# Or simply:
sudo ./manage-displaylink.sh
```

#### To Uninstall the Driver:

This will run the official DisplayLink uninstaller to cleanly remove the driver and its components from your system.

```sh
sudo ./manage-displaylink.sh --uninstall
```

#### To Get Help:

Displays the help message with all available options.

```sh
./manage-displaylink.sh --help
```

A system reboot is required after installation or uninstallation for the changes to take full effect.

## Troubleshooting

If you encounter any issues, the first place to look is the log file. It contains a detailed record of all the steps the script took, including any errors.

You can view the log file with:
```sh
cat /var/log/displaylink-installer.log
```
Or follow it in real-time during execution:
```sh
tail -f /var/log/displaylink-installer.log
```

## Disclaimer

This script is provided "as is". Always be cautious when running scripts that require root privileges. While this script is designed to be safe, you are responsible for any changes made to your system.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
