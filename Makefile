KUBECONFIG_PATH ?= ~/.kube/config-k3s
S3_ACCESS_KEY=$(shell sops -d s3.sops.yaml | yq .s3.access_key)
S3_SECRET_KEY=$(shell sops -d s3.sops.yaml | yq .s3.secret_key)

deploy: create-machines install-kubernetes copy-kubeconfig install-software

destroy:
	cd k8s && terraform init -backend-config="access_key=$(S3_ACCESS_KEY)" -backend-config="secret_key=$(S3_SECRET_KEY)" && TF_VAR_kubeconfig=$(KUBECONFIG_PATH) terraform destroy
	cd proxmox-cluster && terraform init -backend-config="access_key=$(S3_ACCESS_KEY)" -backend-config="secret_key=$(S3_SECRET_KEY)" && terraform destroy

copy-kubeconfig:
	ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "$(shell sed -n '2p' install-k3s/inventory/hosts.ini)"
	mkdir -p ~/.kube/
	scp -o StrictHostKeyChecking=no ubuntu@$(shell sed -n '2p' install-k3s/inventory/hosts.ini):~/.kube/config $(KUBECONFIG_PATH)

install-software:
	cd k8s && terraform init -backend-config="access_key=$(S3_ACCESS_KEY)" -backend-config="secret_key=$(S3_SECRET_KEY)" && TF_VAR_kubeconfig=$(KUBECONFIG_PATH) terraform apply -auto-approve

create-machines:
	cd proxmox-cluster && terraform init -backend-config="access_key=$(S3_ACCESS_KEY)" -backend-config="secret_key=$(S3_SECRET_KEY)" && terraform apply -auto-approve

install-kubernetes:
	cd install-k3s && ansible-playbook cluster.yaml
