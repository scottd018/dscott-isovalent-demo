cli:
	@scripts/install-cli.sh

grpcurl:
	@curl -Lo /tmp/grpcurl.tar.gz "https://github.com/fullstorydev/grpcurl/releases/download/v1.8.7/grpcurl_1.8.7_linux_x86_64.tar.gz"
	@tar zxvf /tmp/grpcurl.tar.gz -C /usr/local/bin grpcurl

#
# cluster
#
CLUSTER_NAME ?= isovalent
deploy-cluster:
	@kind create cluster \
		--name $(CLUSTER_NAME) \
		--config config/kind.yaml

delete-cluster:
	@kind delete cluster --name $(CLUSTER_NAME)

#
# load-balancer
#   as per https://docs.cilium.io/en/v1.12/gettingstarted/servicemesh/ingress/#gs-ingress the cluster must support
#   service of Type=LoadBalancer, so we will use MetalLB as a simple load balancer to satisfy this requirement.
#
#   NOTE: in a real production environment we would likely rely on the cloud provider load balancer to satisfy this.
#
deploy-load-balancer:
	@kubectl apply \
		-f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml \
		-f config/metallb.yaml \
		-f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml

delete-load-balancer:
	@kubectl delete \
		-f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml \
		-f config/metallb.yaml \
		-f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml

#
# kube-proxy
#   as per https://docs.cilium.io/en/v1.12/gettingstarted/kubeproxy-free/#kubeproxy-free the existing implementation
#   of kube-proxy needs to be removed so that cilium can serve service traffic for the cluster
#
config-kube-proxy:
	@scripts/config-kube-proxy.sh

#
# cilium
#
deploy-cilium:
	@scripts/deploy-cilium.sh

delete-cilium:
	@helm uninstall cilium -n kube-system

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
