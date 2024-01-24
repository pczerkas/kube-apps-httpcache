install-act:
	curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | bash

install-gitlab-ci-local:
	curl -s "https://gitlab-ci-local-ppa.firecow.dk/pubkey.gpg" | sudo apt-key add -
	echo "deb https://gitlab-ci-local-ppa.firecow.dk ./" | sudo tee /etc/apt/sources.list.d/gitlab-ci-local.list
	sudo apt-get update
	sudo apt-get install gitlab-ci-local

install-google-cloud-code:
	code --install-extension googlecloudtools.cloudcode

create-kind-cluster:
	cd ./skaffold && ./recreate-kind-cluster.sh

delete-kind-cluster:
	cd ./skaffold && ./delete-kind-cluster.sh
