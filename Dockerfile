FROM ros:humble-ros-base-jammy

SHELL ["/bin/bash", "-c"]

ARG USERNAME=voice_ia
ARG UID=1000
ARG GID=1000


RUN groupadd -g ${GID} ${USERNAME} && \
    useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USERNAME} && \
    usermod -aG audio ${USERNAME}
# ==========================================
# Piper voices
# ==========================================

RUN mkdir -p /voices

WORKDIR /voices



RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    python3-pip \
    build-essential \
    cmake \
    alsa-utils \
    python3-colcon-common-extensions \
    ros-humble-rmw-cyclonedds-cpp \
    ros-humble-joy \
    ros-humble-teleop-twist-joy \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir piper-tts

RUN wget -O amy.onnx \
    https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/amy/medium/en_US-amy-medium.onnx

RUN wget -O amy.onnx.json \
    https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/amy/medium/en_US-amy-medium.onnx.json

WORKDIR /ws

COPY src/ src/
COPY config/ config/


RUN source /opt/ros/humble/setup.bash && \
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

CMD ["ros2", "run", "piper_tts", "voice_tts", "--ros-args", "--params-file", "/ws/config/params.yaml"]