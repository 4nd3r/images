.PHONY: build summary install uninstall reinstall

image?=dev
profile?=$(image)
machine?=$(image)

build:
	./make.sh build $(image) $(profile)

summary:
	./make.sh summary $(image) $(profile)

install:
	./make.sh install $(image) $(machine)

uninstall:
	./make.sh uninstall $(image) $(machine)

reinstall: uninstall install
