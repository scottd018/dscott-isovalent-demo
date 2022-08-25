#!/usr/bin/env bash

# validate environment
: ${CLUSTER_NAME?must provide CLUSTER_NAME environment variable}
: ${CLUSTER_ID?must provide CLUSTER_ID environment variable}

# HACK: because we are running on kind, we will use the direct node IP as the API server
# HACK: this is ugly but it works for a demo.  would want something more robust than relying on
#       field order to provide a value.
# NOTE: in a production environment we would obviously use the more resilient load-balanced address
API_SERVER_IP=$(kubectl get nodes -o wide | grep control-plane | awk '{print $6}')
API_SERVER_PORT="6443"
VERSION="1.12.0"
INSTALL_OPTIONS="
    --helm-set cluster.id=${CLUSTER_ID}
    --helm-set cluster.name=${CLUSTER_NAME}
    --helm-set k8sServiceHost=${API_SERVER_IP}
    --helm-set k8sServicePort=${API_SERVER_PORT}
    --helm-set kubeProxyReplacement=strict
    --helm-set ingressController.enabled=true
    --version ${VERSION}
"

if [[ -n "${CA_CLUSTER_CONTEXT}" ]]; then
    INSTALL_OPTIONS+=" --inherit-ca ${CA_CLUSTER_CONTEXT}"
fi

# install via cilium cli
cilium install --namespace kube-system ${INSTALL_OPTIONS}
