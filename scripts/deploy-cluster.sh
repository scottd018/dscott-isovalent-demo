#!/usr/bin/env bash

# validate environment
: ${CLUSTER_NAME?must provide CLUSTER_NAME environment variable}
: ${CLUSTER_ID?must provide CLUSTER_ID environment variable}
: ${CONFIG?must provide CONFIG environment variable}

if [ $CLUSTER_ID -gt 255 ]; then
    echo "cluster id must be a value less than 255; found ${CLUSTER_ID}"
    exit 1
fi

SUBNET="172.${CLUSTER_ID}.0.0/16"
GATEWAY="172.${CLUSTER_ID}.0.1"

# create the network that is unique to the cluster
docker network create \
    --driver=bridge \
    --subnet=${SUBNET} \
    --gateway=${GATEWAY} \
    --opt=com.docker.network.bridge.enable_ip_masquerade=true \
    --opt=com.docker.network.driver.mtu=1500 \
    ${CLUSTER_NAME}

# create the kind cluster in the network we just created
# NOTE: this is an experimental kind feature
export KIND_EXPERIMENTAL_DOCKER_NETWORK=${CLUSTER_NAME}
kind create cluster \
    --name ${CLUSTER_NAME} \
    --config ${CONFIG}
