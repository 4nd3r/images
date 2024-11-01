.PHONY: build info install uninstall reinstall

image?=dev
machine?=$(image)

build:
	./make.sh build $(image)

info:
	./make.sh info $(image)

install:
	./make.sh install $(image) $(machine)

uninstall:
	./make.sh uninstall $(image) $(machine)

reinstall: uninstall install
