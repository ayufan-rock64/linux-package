export RELEASE ?= 1
export RELEASE_NAME ?= $(shell cat VERSION)-$(RELEASE)
export RELEASE_VERSION ?= $(RELEASE_NAME)-g$(shell git rev-parse --short HEAD)

SHELL := /bin/bash

all:

version:
	@echo $(RELEASE_NAME)

release:
	@echo $(RELEASE_VERSION)

ifeq (,$(BOARD_TARGET))

all: $(patsubst root-%,%-board,$(wildcard root-*))
clean: $(patsubst root-%,%-clean,$(wildcard root-*))

list:
	@echo $(patsubst root-%,%-board,$(wildcard root-*))

%-board:
	make BOARD_TARGET=$(patsubst %-board,%,$@) &> >(ts "[$(patsubst %-board,%,$@)]")

%-clean:
	make clean BOARD_TARGET=$(patsubst %-clean,%,$@) &> >(ts "[$(patsubst %-clean,%,$@)]")

else

root-$(BOARD_TARGET)/etc/board-package:
	mkdir -p root-$(BOARD_TARGET)/etc
	echo "BOARD=$(BOARD_TARGET)" > root-$(BOARD_TARGET)/etc/board-package

board-package-$(BOARD_TARGET)-$(RELEASE_NAME)_all.deb: root-$(BOARD_TARGET)/etc/board-package
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
		--deb-field "Provides: linux-package-virtual, board-package-virtual, linux-$(BOARD_TARGET)-package, board-package-$(BOARD_TARGET)" \
		--deb-field "Replaces: linux-package-virtual, board-package-virtual, linux-$(BOARD_TARGET)-package, board-package-$(BOARD_TARGET)" \
		--deb-field "Conflicts: linux-package-virtual, board-package-virtual, linux-$(BOARD_TARGET)-package, board-package-$(BOARD_TARGET)" \
		--deb-field "Multi-Arch: foreign" \
		--after-install scripts/postinst.deb \
		--before-remove scripts/prerm.deb \
		--url https://gitlab.com/ayufan-rock64/linux-build \
		--description "Rock64 Linux support package" \
		--config-files /var/lib/alsa/asound.state \
		-m "Kamil Trzciński <ayufan@ayufan.eu>" \
		--license "MIT" \
		--vendor "Kamil Trzciński" \
		-a all \
		root/=/ \
		root-$(BOARD_TARGET)/=/

.PHONY: clean
clean:
	rm -f board-package-$(BOARD_TARGET)-$(RELEASE_NAME)_all.deb

all: board-package

.PHONY: board-package		# compile board compatibility package
board-package: board-package-$(BOARD_TARGET)-$(RELEASE_NAME)_all.deb

.PHONY: deploy
deploy: clean board-package
	scp -4 board-package-$(BOARD_TARGET)-$(RELEASE_NAME)_all.deb root@$(DEPLOY_HOST):/tmp
	ssh -4 root@$(DEPLOY_HOST) apt -y --reinstall install /tmp/board-package-$(BOARD_TARGET)-$(RELEASE_NAME)_all.deb

endif
