.PHONY: build summary install uninstall reinstall

name?=test
profile?=bookworm

build:
	./make.sh build $(name) $(profile)

summary:
	./make.sh summary $(name) $(profile)

install:
	./make.sh install $(name)

uninstall:
	./make.sh uninstall $(name)

reinstall: uninstall install
