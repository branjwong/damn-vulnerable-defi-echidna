# Routine Tasks
report:
	docker run --rm \
       --volume "$(pwd):/data" \
       --user $(id -u):$(id -g) \
       pandoc/extra review/report.md -o review/report.pdf --template eisvogel --listings

# Local Dev Initialization

libs:
	cp -r common dvd3
	cp -r common dvd5.ech8
	cp -r common dvd6
	cp -r common dvd7
	cp -r common dvd8
	cp -r common dvd9
	cp -r common dvd10
	cp -r common dvd11

	ln -sf ../common/remappings.txt dvd3/remappings.txt
	ln -sf ../common/remappings.txt dvd5.ech8/remappings.txt
	ln -sf ../common/remappings.txt dvd6/remappings.txt
	ln -sf ../common/remappings.txt dvd7/remappings.txt
	ln -sf ../common/remappings.txt dvd8/remappings.txt
	ln -sf ../common/remappings.txt dvd9/remappings.txt
	ln -sf ../common/remappings.txt dvd10/remappings.txt
	ln -sf ../common/remappings.txt dvd11/remappings.txt

fixperm:
	sudo chmod -R a+rwX .
	sudo chmod -R g+rwX .
	sudo find . -type d -exec chmod g+s '{}' +

# Project Initialization

init:
	git init
	git submodule add $(GITURL) repo

submodule-update:
	git submodule update --init

	cp common/DamnValuableToken.sol dvd3/common/DamnValuableToken.sol

new-dvd:
	forge init $(DIR) --no-commit
	rm -r $(DIR)/script $(DIR)/src $(DIR)/test
	mkdir $(DIR)/src
	cp -r test-dvd $(DIR)/test
	make libs
