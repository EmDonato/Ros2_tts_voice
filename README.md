# Piper voice output

The image uses ROS 2 Jazzy on Ubuntu Noble and Piper 1.7.0 in `/opt/piper`,
an isolated virtual environment. ROS uses system Python 3.12; the node invokes
Piper through `/usr/local/bin/piper`. This avoids modifying externally managed
system Python packages (PEP 668).

From this directory, build on the development PC without audio hardware:

```bash
ROBOT_PLATFORM=linux/amd64 docker compose build
```

The default platform is ARM64 for the Raspberry Pi. `docker compose up -d`
starts the node and requires `/dev/snd` and the configured ALSA device.
The image is tagged `open-pi-voice-ia-img:jazzy`. Configuration is in
`config/params.yaml`; `/assistant/response` receives `std_msgs/msg/String`.
Keep `ROS_DOMAIN_ID` consistent with the other robot containers.
