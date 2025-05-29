# Forge Minecraft Server Installer 🚀

A Bash script to automate downloading, installing, and configuring a Forge Minecraft server on systemd-based Linux systems. The script handles version selection, EULA agreement, headless mode configuration, default server properties, and optional systemd service setup.

## Features ✅
- Download a specific Forge version (including full build number)
- Run the official Forge server installer
- Automatically agree to the Minecraft EULA
- Configure headless startup mode (`-nogui`)
- Download a default `server.properties` file
- Optionally install a systemd service for automatic startup on boot

## Prerequisites 🛠️
- A Linux distribution with **systemd**
- **bash** (version 4 or higher)
- **curl**
- **Java** (OpenJDK or Oracle) available in `PATH`
- **sudo** privileges (required for systemd integration)

## Installation 📦
1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```
2. Make the script executable:
   ```bash
   chmod +x setup-forge-server.sh
   ```

## Usage 🎮
Run the script with the required options:
```bash
./setup-forge-server.sh -v <forge_version> [-s yes|no] [-w <working_directory>]
```

## Options ⚙️
| Flag                         | Description                                                      | Default            | Required |
|------------------------------|------------------------------------------------------------------|--------------------|----------|
| `-v`, `--forge-version`      | Forge version (e.g., `1.20.1-41.2.0`)                            | —                  | Yes      |
| `-s`, `--startup`            | Install a systemd service? Use `yes` or `no`                    | `no`               | No       |
| `-w`, `--working-directory`  | Directory for server installation                                | Current directory  | No       |
| `-h`, `--help`               | Display the help message                                         | —                  | No       |

## Examples 📝
### 1. Full installation with systemd
```bash
./setup-forge-server.sh \
  -v 1.20.1-41.2.0 \
  -s yes \
  -w /opt/minecraft-server
```

### 2. Quick start in the current directory
```bash
./setup-forge-server.sh --forge-version 1.19.4-45.1.0
```

## Support ❓
For questions or support, please open an issue in this repository.
