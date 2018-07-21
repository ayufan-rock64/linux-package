export RELEASE ?= 1
export RELEASE_NAME ?= $(shell cat VERSION)-$(RELEASE)
export RELEASE_VERSION ?= $(RELEASE_NAME)-g$(shell git rev-parse --short HEAD)

ifeq (,$(wildcard root-$(BOARD_TARGET)))
$(error Unsupported BOARD_TARGET)
endif

all: board-package

version:
	@echo $(RELEASE_NAME)

release:
	@echo $(RELEASE_VERSION)

board-package-$(BOARD_TARGET)-$(RELEASE_NAME)_all.deb:
	fpm -s dir -t deb -n board-package-$(BOARD_TARGET)-$(RELEASE_NAME) -v $(RELEASE_NAME) \
		-p $@ \
		--deb-priority optional --category admin \
		--force \
		--depends figlet \
		--depends cron \
		--depends gdisk \
		--depends parted \
		--depends device-tree-compiler \
		--depends linux-base \
		--deb-compression bzip2 \
		--deb-field "Provides: linux-package-virtual, board-package-virtual, linux-$(BOARD_TARGET)-package, board-package-$(BOARD_TARGET)" \
		--deb-field "Replaces: linux-package-virtual, board-package-virtual, linux-$(BOARD_TARGET)-package, board-package-$(BOARD_TARGET)" \
		--deb-field "Conflicts: linux-package-virtual, board-package-virtual, linux-$(BOARD_TARGET)-package, board-package-$(BOARD_TARGET)" \
		--deb-field "Multi-Arch: foreign" \
		--after-install scripts/postinst.deb \
		--before-remove scripts/prerm.deb \
		--url https://gitlab.com/ayufan-rock64/linux-build \
		--description "Rock64 Linux support package" \
		--config-files /boot/efi/extlinux/ \
		-m "Kamil Trzciński <ayufan@ayufan.eu>" \
		--license "MIT" \
		--vendor "Kamil Trzciński" \
		-a all \
		root/=/ \
		root-$(BOARD_TARGET)/=/

.PHONY: board-package		# compile board compatibility package
board-package: board-package-$(BOARD_TARGET)-$(RELEASE_NAME)_all.deb
