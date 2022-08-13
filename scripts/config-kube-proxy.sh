#!/bin/bash

# remove the existing kube-proxy resources
kubectl -n kube-system delete ds kube-proxy
kubectl -n kube-system delete cm kube-proxy

# remove the kubernetes-specific items from iptables nodes
for CONTAINER in `docker ps | grep isovalent | awk '{print $1}'`; do
    docker exec -it ${CONTAINER} bash -c "iptables-save | grep -v KUBE | iptables-restore"
done
