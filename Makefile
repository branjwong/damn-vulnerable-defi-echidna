# Routine Tasks
report:
	docker run --rm \
       --volume "$(pwd):/data" \
       --user $(id -u):$(id -g) \
       pandoc/extra review/report.md -o review/report.pdf --template eisvogel --listings

# Local Dev Initialization

ln:
	mkdir dvd3/common/ -p
	mkdir dvd5.ech8/common/ -p
	mkdir dvd6/common/ -p
	mkdir dvd7/common/ -p
	mkdir dvd8/common/ -p

	ln -sf ../common/remappings.txt dvd3/remappings.txt
	ln -sf ../common/remappings.txt dvd5.ech8/remappings.txt
	ln -sf ../common/remappings.txt dvd6/remappings.txt
	ln -sf ../common/remappings.txt dvd7/remappings.txt
	ln -sf ../common/remappings.txt dvd8/remappings.txt
	
	ln -sf ../../common/DamnValuableToken.sol dvd3/common/DamnValuableToken.sol
	ln -sf ../../common/DamnValuableToken.sol dvd5.ech8/common/DamnValuableToken.sol
	ln -sf ../../common/DamnValuableTokenSnapshot.sol dvd6/common/DamnValuableTokenSnapshot.sol
	ln -sf ../../common/DamnValuableNFT.sol dvd7/common/DamnValuableNFT.sol
	ln -sf ../../common/DamnValuableToken.sol dvd8/common/DamnValuableToken.sol

fixperm:
	sudo chmod -R a+rwX .
	sudo chmod -R g+rwX .
	sudo find . -type d -exec chmod g+s '{}' +

# Project Initialization

git_url := https://github.com/tinchoabbate/damn-vulnerable-defi.git

init:
	git init
	git submodule add $(git_url) repo

submodule-update:
	git submodule update --init
