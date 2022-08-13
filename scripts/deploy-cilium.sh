#!/usr/bin/env bash

# HACK: because we are running on kind, we will use the direct node IP as the API server
# HACK: this is ugly but it works for a demo.  would want something more robust than relying on
#       field order to provide a value.
# NOTE: in a production environment we would obviously use the more resilient load-balanced address
API_SERVER_IP=$(kubectl get nodes -o wide | grep control-plane | awk '{print $6}')
API_SERVER_PORT="6443"

# install via helm
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --version 1.12.0 \
    --namespace kube-system \
    --set kubeProxyReplacement=strict \
    --set k8sServiceHost=${API_SERVER_IP} \
    --set k8sServicePort=${API_SERVER_PORT} \
    --set ingressController.enabled=true
