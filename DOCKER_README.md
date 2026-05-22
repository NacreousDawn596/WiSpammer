# Running WiSpammer with Docker

This Dockerfile allows you to run WiSpammer in a containerized environment, ensuring all dependencies are met.

## Prerequisites

1.  **Wireless Card:** You must have a wireless network adapter that supports **Monitor Mode** and **Packet Injection**.
2.  **Linux Host:** Best performance and compatibility are on Linux.
3.  **Windows/macOS:** You will likely need to use a USB wireless adapter and pass it through to the Docker Desktop VM (which is complex). Direct use of built-in cards on Mac/Windows is generally not supported by Docker.

## How to Build

```bash
docker build -t wispammer .
```

## How to Run (Linux)

To run the container, you must grant it privileged access, host network permissions, and host process namespace access. **Mounting the D-Bus socket is highly recommended** to allow the container to tell your host's NetworkManager to step aside.

```bash
sudo docker run --rm -it \
    --privileged \
    --network host \
    --pid host \
    -v /var/run/dbus:/var/run/dbus \
    wispammer
```

### Why these flags?
- `--privileged`: Allows the container to access host hardware (like your WiFi card).
- `--network host`: Allows the container to see and manipulate the host's network interfaces.
- `--pid host`: Allows the container to kill host-level background processes.
- `-v /var/run/dbus:/var/run/dbus`: **(Highly Recommended)** Allows `nmcli` inside the container to talk to the host's NetworkManager. This is often the only way to stop the host from "stealing" the interface back and causing "Device or resource busy" errors.
- `-it`: Interactive terminal.
- `--rm`: Automatically removes the container.

## Troubleshooting

### "Network is down" or "wi_write() failed"
This error usually occurs when the wireless interface cannot be brought up in monitor mode. 
1.  **Check Hardware:** Ensure your WiFi card supports Monitor Mode and Packet Injection.
2.  **Kill Interfering Processes:** The script now tries to do this automatically with `airmon-ng check kill`. If it still fails, try running `sudo airmon-ng check kill` on your **host** machine before starting the container.
3.  **RF-Kill:** Ensure your WiFi is not hard-blocked (check `rfkill list` on the host).
4.  **Driver Issues:** Some drivers (like `rtw_8822bu`) require specific patches or versions to support monitor mode in Docker.

### No interfaces listed
If the script shows no interfaces, ensure you are running with `--privileged` and `--network host`.
