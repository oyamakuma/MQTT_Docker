#!/bin/bash

# Setup working dir
declare -r WORK_DIR="${HOME}/Desktop/mqtt-container"
mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}" || exit 1


# MQTT broker image
declare -r BROKER_IMAGE='mqtt-broker'
mkdir -p "${BROKER_IMAGE}/config"
cat <<EOF >"${BROKER_IMAGE}/config/Dockerfile"
FROM alpine:latest
RUN apk --no-cache add mosquitto
EOF
docker build --no-cache -t "${BROKER_IMAGE}" "${BROKER_IMAGE}/config"


# MQTT publisher/subscriber image
declare -r PUB_SUB_IMAGE='mqtt-pub/sub'
mkdir -p "${PUB_SUB_IMAGE}/config"
cat <<EOF >"${PUB_SUB_IMAGE}/config/Dockerfile"
FROM alpine:latest
RUN apk --no-cache add mosquitto-clients
EOF
docker build --no-cache -t "${PUB_SUB_IMAGE}" "${PUB_SUB_IMAGE}/config"


# Create docker network to link each container
declare -r DOCKER_NETWORK='MQTT_NETWORK'
docker network create "${DOCKER_NETWORK}"

# Start MQTT
declare -r BROKER_NAME='mqtt-broker'
declare -r SUBSCRIBER_NAME='mqtt-sub'
declare -r PUBLISHER_NAME='mqtt-pub'

declare -r MQTT_TOPIC='test'
declare -r MQTT_MESSAGE='Hello MQTT'

docker run -d --rm --net "${DOCKER_NETWORK}" --expose 1883 --name "${BROKER_NAME}" "${BROKER_IMAGE}" mosquitto
cat <<EOF
# On TTY A
$ docker run -it --rm --net "${DOCKER_NETWORK}" --name "${SUBSCRIBER_NAME}" "${PUB_SUB_IMAGE}" /bin/sh
/ # mosquitto_sub -h "${BROKER_NAME}" -t ${MQTT_TOPIC}

# On TTY B
$ docker run -it --rm --net "${DOCKER_NETWORK}" --name "${PUBLISHER_NAME}" "${PUB_SUB_IMAGE}" /bin/sh
/ # mosquitto_pub -h "${BROKER_NAME}" -t ${MQTT_TOPIC} -m "${MQTT_MESSAGE}"
EOF

read -rp 'Press Enter to Exit MQTT>>'
docker stop "${PUBLISHER_NAME}"
docker stop "${SUBSCRIBER_NAME}"
docker stop "${BROKER_NAME}"
docker network rm "${DOCKER_NETWORK}"
