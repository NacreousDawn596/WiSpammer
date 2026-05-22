# WiSpammer 🚀

A lightweight and powerful WiFi SSID spammer built with Bash, Python, and MDK3. Designed for network security testing and educational purposes.

## 🛠 Features
- **Custom SSIDs:** Spam specific names with automatic numbering.
- **Wordlist Support:** Use your own SSID wordlists.
- **Randomized Spam:** Generate and spam random SSID names using `pwgen`.
- **MAC Anonymization:** Automatically changes your MAC address before starting.
- **Cross-Platform:** Now supports Docker for easier deployment across different Linux distributions.

## 📋 Dependencies
The following tools are required for WiSpammer to function:
- `mdk3` / `mdk4`
- `macchanger`
- `pwgen`
- `python3`
- `curl` & `wget`
- `cowsay` & `figlet`
- `wireless_tools` & `net-tools`
- `rfkill` & `aircrack-ng` (for `airmon-ng`)

## 🚀 Quick Start (Native)

### 1. Installation (Debian/Ubuntu)
```bash
git clone https://github.com/NacreousDawn596/WiSpammer
cd WiSpammer
chmod +x setup.sh
./setup.sh
```

### 2. Execution
```bash
sudo ./main.sh
```

---

## 🐳 Docker (Recommended for Portability)

Run WiSpammer without worrying about local dependencies. The Docker image caches all tools for offline use.

### Build
```bash
docker build -t wispammer .
```

### Run
```bash
sudo docker run --rm -it --privileged --network host --pid host -v /var/run/dbus:/var/run/dbus wispammer
```
*Note: Requires a WiFi adapter that supports Monitor Mode.*

---

## ⚠️ Disclaimer
**WiSpammer is for educational and authorized security testing only.** Unauthorized use of this tool against networks you do not own is illegal and unethical. The developer is not responsible for any misuse.

## 🤝 Acknowledgments
- Big thanks to [@archstrike](https://github.com/archstrike) for their contributions to the wireless security community.
