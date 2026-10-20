FROM ros:jazzy-ros-base-noble

SHELL ["/bin/bash", "-c"]

ARG USERNAME=voice_ia
ARG UID=1000
ARG GID=1000


# Noble reserves UID/GID 1000 for its default ubuntu account.
RUN if id ubuntu >/dev/null 2>&1; then userdel -r ubuntu; fi && \
    groupadd -g ${GID} ${USERNAME} && \
    useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USERNAME} && \
    usermod -aG audio ${USERNAME}
# ==========================================
# Piper voices
# ==========================================

RUN mkdir -p /voices

WORKDIR /voices



RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    python3-venv \
    build-essential \
    cmake \
    alsa-utils \
    python3-colcon-common-extensions \
    ros-jazzy-rmw-cyclonedds-cpp \
    ros-jazzy-joy \
    ros-jazzy-teleop-twist-joy \
    && rm -rf /var/lib/apt/lists/*

# Keep Piper isolated from Noble system Python (PEP 668).
# This is the version used by the existing Humble image.
ARG PIPER_VERSION=1.7.0
RUN python3 -m venv /opt/piper && \
    /opt/piper/bin/pip install --no-cache-dir "piper-tts==${PIPER_VERSION}" && \
    ln -s /opt/piper/bin/piper /usr/local/bin/piper

RUN wget -O amy.onnx \
    https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/amy/medium/en_US-amy-medium.onnx

RUN wget -O amy.onnx.json \
    https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/amy/medium/en_US-amy-medium.onnx.json

WORKDIR /ws

COPY src/ src/
COPY config/ config/


RUN source /opt/ros/jazzy/setup.bash && \
    colcon build --merge-install \
        --cmake-args -DCMAKE_BUILD_TYPE=Release

COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

USER ${USERNAME} 


RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /home/${USERNAME}/.bashrc && \
    echo "source /ws/install/setup.bash" >> /home/${USERNAME}/.bashrc && \
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.bashrc
    
ENTRYPOINT ["/entrypoint.sh"]

CMD ["/ws/install/lib/piper_tts/voice_tts", "voice_tts", "--ros-args", "--params-file", "/ws/config/params.yaml"]