# Summary

This repo exists to demonstrate the capabilities of Isovalent/Cilium as per instructions identified at
https://docs.cilium.io/en/v1.12/gettingstarted/servicemesh/ingress/#gs-ingress

## Instructions

1. Install the local cluster:

```bash
make deploy-cluster
```

2. Install the load balancer:

```bash
make deploy-load-balancer
```

3. Remove the existing kube-proxy implementation:

```bash
make config-kube-proxy
```

4. Install Cilium:

```bash
make deploy-cilium
```