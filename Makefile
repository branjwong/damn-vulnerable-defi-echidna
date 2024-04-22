# Routine Tasks
report:
	docker run --rm \
       --volume "$(pwd):/data" \
       --user $(id -u):$(id -g) \
       pandoc/extra review/report.md -o review/report.pdf --template eisvogel --listings

# Local Dev Initialization

libs:
	rm -r dvd3/common
	rm -r dvd5.ech8/common
	rm -r dvd6/common
	rm -r dvd7/common
	rm -r dvd8/common

	cp -r common dvd3
	cp -r common dvd5.ech8
	cp -r common dvd6
	cp -r common dvd7
	cp -r common dvd8

	ln -sf ../common/remappings.txt dvd3/remappings.txt
	ln -sf ../common/remappings.txt dvd5.ech8/remappings.txt
	ln -sf ../common/remappings.txt dvd6/remappings.txt
	ln -sf ../common/remappings.txt dvd7/remappings.txt
	ln -sf ../common/remappings.txt dvd8/remappings.txt
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

	cp common/DamnValuableToken.sol dvd3/common/DamnValuableToken.sol
