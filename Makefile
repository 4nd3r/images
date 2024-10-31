.PHONY: build summary install uninstall reinstall

image?=dev
machine?=$(image)

build:
	./make.sh build $(image)

summary:
	./make.sh summary $(image)

install:
	./make.sh install $(image) $(machine)

uninstall:
	./make.sh uninstall $(image) $(machine)

reinstall: uninstall install
