PARENT ?= ..
ISO_NAME ?= purec-test-dist

.PHONY: all iso clean distclean

all: iso

iso:
	PARENT="$(PARENT)" ISO_NAME="$(ISO_NAME)" sh ./build.sh

clean:
	rm -rf staging

distclean: clean
	rm -rf out
