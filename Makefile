# Routine Tasks
report:
	docker run --rm \
       --volume "$(pwd):/data" \
       --user $(id -u):$(id -g) \
       pandoc/extra review/report.md -o review/report.pdf --template eisvogel --listings

# Local Dev Initialization

ln:
	ln -sf ../../../dvd2.ech5/FlashLoanReceiver.sol repo/contracts/naive-receiver/FlashLoanReceiver.sol
	ln -sf ../../../dvd2.ech5/NaiveReceiverLenderPool.sol repo/contracts/naive-receiver/NaiveReceiverLenderPool.sol
	ln -sf ../../../dvd2.ech5/Invariants.sol repo/contracts/naive-receiver/Invariants.sol
	ln -sf ../../../dvd2.ech5/config.yaml repo/contracts/naive-receiver/config.yaml

	ln -sf ../../../dvd1.ech6/ReceiverUnstoppable.sol repo/contracts/unstoppable/ReceiverUnstoppable.sol
	ln -sf ../../../dvd1.ech6/UnstoppableLender.sol repo/contracts/unstoppable/UnstoppableLender.sol
	ln -sf ../../../dvd1.ech6/Invariants.sol repo/contracts/unstoppable/Invariants.sol
	ln -sf ../../../dvd1.ech6/config.yaml repo/contracts/unstoppable/config.yaml

	ln -sf ../../../dvd4.ech7/src/SideEntranceLenderPool.sol repo/contracts/side-entrance/SideEntranceLenderPool.sol
	ln -sf ../../../dvd4.ech7/Invariants.sol repo/contracts/side-entrance/Invariants.sol
	ln -sf ../../../dvd4.ech7/config.yaml repo/contracts/side-entrance/config.yaml

	ln -sf ../../../dvd5.ech8/src/contracts/TheRewarderPool.sol repo/contracts/the-rewarder/TheRewarderPool.sol
	ln -sf ../../../dvd5.ech8/src/contracts/FlashLoanerPool.sol repo/contracts/the-rewarder/FlashLoanerPool.sol
	ln -sf ../../../dvd5.ech8/src/contracts/Invariants.sol repo/contracts/the-rewarder/Invariants.sol
	ln -sf ../../../dvd5.ech8/config.yaml repo/contracts/the-rewarder/config.yaml

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
