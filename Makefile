KUBECONFIG_PATH ?= ~/.kube/config-k3s

deploy: create-machines install-kubernetes copy-kubeconfig install-software

destroy:
	cd proxmox-cluster && terraform init && terraform destroy

copy-kubeconfig:
	ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "$(shell sed -n '2p' install-k3s/inventory/hosts.ini)"
	mkdir -p ~/.kube/
	scp -o StrictHostKeyChecking=no ubuntu@$(shell sed -n '2p' install-k3s/inventory/hosts.ini):~/.kube/config $(KUBECONFIG_PATH)

install-software:
	cd k8s && terraform init && TF_VAR_kubeconfig=$(KUBECONFIG_PATH) terraform apply -auto-approve

create-machines:
	cd proxmox-cluster && terraform init && terraform apply -auto-approve

install-kubernetes:
	cd install-k3s && ansible-playbook cluster.yaml
