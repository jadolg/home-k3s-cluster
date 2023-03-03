deploy:
	cd terraform && terraform init && terraform apply -auto-approve
	cd ansible && ansible-playbook cluster.yaml

destroy:
	cd terraform && terraform init && terraform destroy

copy-kubeconfig:
	ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "$(shell sed -n '2p' ansible/inventory/hosts.ini)"
	mkdir -p ~/.kube/
	scp -o StrictHostKeyChecking=no ubuntu@$(shell sed -n '2p' ansible/inventory/hosts.ini):~/.kube/config ~/.kube/config

install-charts:
	cd k8s && terraform init && terraform apply -auto-approve
