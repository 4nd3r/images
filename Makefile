.PHONY: build install uninstall reinstall

name?=dev
profile?=bookworm

build:
	./make.sh build $(name) $(profile)

install:
	./make.sh install $(name)

uninstall:
	./make.sh uninstall $(name)

reinstall: uninstall install
