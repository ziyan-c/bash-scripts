# Server Setup Script

This script automates the setup and configuration of a Debian-based server. It performs tasks such as installing software, configuring firewalls, setting up SSH keys, enabling BBR, and more. The script requires a user-specific `info.private` file to provide necessary configuration details.

---

## Prerequisites
1. A **Debian-based** server with root access.
2. Install `bash` and `openssl` (pre-installed on most Debian systems).
3. A valid `info.private` configuration file (see below).

---

## Usage Instructions

### 1. Create the `info.private` File
The `info.private` file must contain the following user-specific details. It should be placed in the same directory as the script.

```bash
# The hostname to set for the server
hostname=<your-hostname>

# The name of the network interface (e.g., eth0, ens33)
nic_name=<your-network-interface-name>

# Size of the swap file in MB
swapfile_size=<size-in-mb>

# Your personal SSH public key (e.g., key for your personal access)
ssh_public_key_personal=""

# A server-specific SSH public key (e.g., for server-to-server authentication)
ssh_public_key_server=""
```

## Example `info.private` file 
```bash
hostname=my-server
nic_name=eth0
swapfile_size=2048
ssh_public_key_personal="ssh-rsa AAAAB3... user@local"
ssh_public_key_server="ssh-rsa AAAAB3... root@server"
```
