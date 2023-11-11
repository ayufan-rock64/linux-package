export RELEASE ?= 1
export RELEASE_NAME ?= $(shell cat VERSION)-$(RELEASE)
export RELEASE_VERSION ?= $(RELEASE_NAME)-g$(shell git rev-parse --short HEAD)

all:

version:
	@echo $(RELEASE_NAME)

release:
	@echo $(RELEASE_VERSION)

ifeq (,$(BOARD_TARGET))

all: $(patsubst root-%,%-board,$(wildcard root-*))

boards:
	@echo $(patsubst root-%,%,$(wildcard root-*))

%-board:
	make BOARD_TARGET=$(patsubst %-board,%,$@)

else

board-package-$(BOARD_TARGET)-$(RELEASE_NAME)_all.deb: root-$(BOARD_TARGET)
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
