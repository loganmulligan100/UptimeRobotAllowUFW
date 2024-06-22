# UptimeRobotAllowUFW

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Version](https://img.shields.io/badge/version-1.0.0-green.svg)
![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)

## Table of Contents
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [What the Script Does](#what-the-script-does)
- [Notes](#notes)
- [License](#license)
- [Contributing](#contributing)
- [Contact](#contact)

## Introduction
This script allows you to easily add Uptime Robot IP addresses to your UFW (Uncomplicated Firewall) rules. It downloads the list of IP addresses from Uptime Robot and configures UFW to allow traffic from those IPs, ensuring that your server can be monitored by Uptime Robot.

## Prerequisites
- Ubuntu or Debian-based Linux distribution
- UFW (Uncomplicated Firewall) installed and enabled
- `curl` installed

## Installation
Clone the repository or download the script directly from GitHub:

```bash
# Clone the repository
git clone https://github.com/loganmulligan100/UptimeRobotAllowUFW.git

# Navigate to the project directory
cd UptimeRobotAllowUFW

# Make the script executable
chmod +x ufw_add_uptime_robot_ips.sh
```

## Usage
You can run the script directly from GitHub using the following command:

```bash
curl -s https://raw.githubusercontent.com/loganmulligan100/UptimeRobotAllowUFW/main/ufw_add_uptime_robot_ips.sh | bash
```
To remove rules run | IPV6 is currently working, Im sure its supper jank the way Im doing it, but its working. 
```bash
curl -s https://raw.githubusercontent.com/loganmulligan100/UptimeRobotAllowUFW/main/ufw_add_uptime_robot_ips.sh | bash -s -- --purge
```

Alternatively, you can run the script locally if you have cloned the repository or downloaded the script:
```bash
./ufw_add_uptime_robot_ips.sh
```
## What the Script Does
- Downloads the latest list of Uptime Robot IP addresses.
- Reads each IP address from the downloaded list.
- Adds each IP address to the UFW rules with a comment indicating it's for Uptime Robot.
- Reloads UFW to apply the new rules.
- Cleans up by removing the temporary IP list file.

## Notes
Ensure you have the necessary permissions to run UFW commands. You may need to run the script as a superuser (`sudo`).

The script assumes UFW is installed and enabled. If UFW is not enabled, you can enable it using:
```bash
sudo ufw enable
```
You can check the status of UFW and see the added rules with:
```bash
ufw status
```
## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

## Contributing
If you would like to contribute to this project, feel free to submit a pull request or open an issue on GitHub.

## Contact
If you have any questions or feedback, feel free to reach out.

- GitHub: [loganmulligan100](https://github.com/loganmulligan100)








