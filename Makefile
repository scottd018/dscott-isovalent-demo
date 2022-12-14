cli:
	@scripts/install-cli.sh

grpcurl:
	@curl -Lo /tmp/grpcurl.tar.gz "https://github.com/fullstorydev/grpcurl/releases/download/v1.8.7/grpcurl_1.8.7_linux_x86_64.tar.gz"
	@tar zxvf /tmp/grpcurl.tar.gz -C /usr/local/bin grpcurl

#
# cluster
#
CLUSTER_PREFIX ?= isovalent-
deploy-cluster-1:
	@CLUSTER_NAME=$(CLUSTER_PREFIX)1 CLUSTER_ID=1 CONFIG=config/kind-cluster-1.yaml scripts/deploy-cluster.sh

deploy-cluster-2:
	@CLUSTER_NAME=$(CLUSTER_PREFIX)2 CLUSTER_ID=2 CONFIG=config/kind-cluster-2.yaml scripts/deploy-cluster.sh

delete-cluster-1:
	@kind delete cluster --name $(CLUSTER_PREFIX)1
	@docker network rm $(CLUSTER_PREFIX)1

delete-cluster-2:
	@kind delete cluster --name $(CLUSTER_PREFIX)2
	@docker network rm $(CLUSTER_PREFIX)2

#
# kube-proxy
#   as per https://docs.cilium.io/en/v1.12/gettingstarted/kubeproxy-free/#kubeproxy-free the existing implementation
#   of kube-proxy needs to be removed so that cilium can serve service traffic for the cluster
#
# DEPRECATED: now using the kubeProxyMode=none to deploy the kind cluster which disabled kube-proxy out of the box
config-kube-proxy:
	@scripts/config-kube-proxy.sh

#
# cilium
#
deploy-cilium-cluster-1:
	@CLUSTER_NAME=$(CLUSTER_PREFIX)1 CLUSTER_ID=1 scripts/deploy-cilium.sh

deploy-cilium-cluster-2:
	@CLUSTER_NAME=$(CLUSTER_PREFIX)2 CLUSTER_ID=2 CA_CLUSTER_CONTEXT=kind-$(CLUSTER_PREFIX)1 scripts/deploy-cilium.sh

delete-cilium:
	@cilium uninstall

#
# load-balancer
#   as per https://docs.cilium.io/en/v1.12/gettingstarted/servicemesh/ingress/#gs-ingress the cluster must support
#   service of Type=LoadBalancer, so we will use MetalLB as a simple load balancer to satisfy this requirement.
#
#   NOTE: in a real production environment we would likely rely on the cloud provider load balancer to satisfy this.
#
deploy-load-balancer-cluster-1:
	@kubectl apply \
		-f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml \
		-f config/metallb-cluster-1.yaml \
		-f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml

deploy-load-balancer-cluster-2:
	@kubectl apply \
		-f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml \
		-f config/metallb-cluster-2.yaml \
		-f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml

delete-load-balancer:
	@kubectl delete \
		-f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml \
		-f config/metallb-cluster-1.yaml \
		-f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml

#
# examples
#
deploy-example-http:
	@kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/platform/kube/bookinfo.yaml
	@kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/v1.12/examples/kubernetes/servicemesh/basic-ingress.yaml

delete-example-http:
	@kubectl delete -f https://raw.githubusercontent.com/cilium/cilium/v1.12/examples/kubernetes/servicemesh/basic-ingress.yaml
	@kubectl delete -f https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/platform/kube/bookinfo.yaml

deploy-example-grpc:
	@kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/kubernetes-manifests.yaml
	@curl -o build/demo.proto https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/pb/demo.proto
	@kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/v1.12/examples/kubernetes/servicemesh/grpc-ingress.yaml

delete-example-grpc:
	@kubectl delete -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/kubernetes-manifests.yaml
	@rm -rf build/demo.proto
	@kubectl delete -f https://raw.githubusercontent.com/cilium/cilium/v1.12/examples/kubernetes/servicemesh/grpc-ingress.yaml
