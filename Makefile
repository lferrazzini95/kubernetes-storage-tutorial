.PHONY: create delete restart info kubeconfig

CLUSTER_NAME := k3d-cluster
K3D_CONFIG := cluster.yaml
K8S_VERSION := v1.34.1

create:
	@echo "Creating cluster..."
	minikube start \
		--driver=docker \
		--addons metrics-server \
	kubectl create namespace playground

	@echo "Cluster is ready!"

create-minikube-kvm:
	@echo "Creating cluster..."
	minikube start \
		--driver=kvm2 \
		--nodes 5 \
		--addons metrics-server \
		--kubernetes-version=v1.30.3

	kubectl label nodes minikube node-role.kubernetes.io/tier=controlplane --overwrite
	kubectl label nodes minikube-m02 node-role.kubernetes.io/tier=infra --overwrite
	kubectl label nodes minikube-m03 node-role.kubernetes.io/tier=infra --overwrite
	kubectl label nodes minikube-m04 node-role.kubernetes.io/tier=worker --overwrite
	kubectl label nodes minikube-m05 node-role.kubernetes.io/tier=worker --overwrite
	
	minikube ssh --node minikube 'sudo apt-get update && sudo apt-get install -y open-iscsi'
	minikube ssh --node minikube-m02 'sudo apt-get update && sudo apt-get install -y open-iscsi'
	minikube ssh --node minikube-m03 'sudo apt-get update && sudo apt-get install -y open-iscsi'
	minikube ssh --node minikube-m04 'sudo apt-get update && sudo apt-get install -y open-iscsi'
	minikube ssh --node minikube-m05 'sudo apt-get update && sudo apt-get install -y open-iscsi'
	
	@echo "Cluster is ready!"

delete:
	@echo "Deleting cluster $(CLUSTER_NAME)..."
	minikube delete
	@echo "Cluster deleted."

install-longhorn:
	@echo "Installing Longhorn CSI Driver via Helm with V2 Data Engine (NVMe/TCP)..."
	helm repo add longhorn https://charts.longhorn.io
	helm repo update
	helm install longhorn longhorn/longhorn \
		--set 'global.nodeSelector.node-role\.kubernetes\.io/tier=infra' \
		--namespace longhorn-system \
		--create-namespace
		# --set longhorn.v2DataEngine.enabled=true \
		# --set longhorn.defaultDataEngine=v2 \
		# --set networkPolicies.enabled=true \
	@echo "Waiting for Longhorn pods to become ready..."
	# Note: V2 Engine pods (engine-manager-v2) will also start up.
	kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=longhorn -n longhorn-system --timeout=300s
	@echo "Longhorn V2 (NVMe/TCP) installation complete."

longhorn-prep-storage-class:
	@echo "Setting 'longhorn' as the default StorageClass..."
	# Unset the default k3s local-path SC
	kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
	# Set longhorn as the new default SC
	kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
	@echo "Default StorageClass updated to 'longhorn'."
