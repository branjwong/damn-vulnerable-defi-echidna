# Routine Tasks
report:
	docker run --rm \
       --volume "$(pwd):/data" \
       --user $(id -u):$(id -g) \
       pandoc/extra review/report.md -o review/report.pdf --template eisvogel --listings

# Local Dev Initialization

ln:
	ln -sf ../../../exercise5/FlashLoanReceiver.sol repo/contracts/naive-receiver/FlashLoanReceiver.sol
	ln -sf ../../../exercise5/NaiveReceiverLenderPool.sol repo/contracts/naive-receiver/NaiveReceiverLenderPool.sol

fixperm:
	sudo chmod -R a+rwX .
	sudo chmod -R g+rwX .
	sudo find . -type d -exec chmod g+s '{}' +

# Project Initialization

git_url := https://github.com/crytic/damn-vulnerable-defi-echidna.git

init:
	git init
	if [ ! -d "repo" ]; then \
		git submodule add $(git_url) repo; \
	fi
	git submodule update --init
