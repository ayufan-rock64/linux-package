export RELEASE ?= 1
export RELEASE_NAME ?= $(shell cat VERSION)-$(RELEASE)-g$(shell git rev-parse --short HEAD)

LATEST_UBOOT_VERSION ?= $(shell curl --fail -s https://api.github.com/repos/ayufan-rock64/linux-u-boot/releases | jq -r ".[0].tag_name")
LATEST_KERNEL_VERSION ?= $(shell curl --fail -s https://api.github.com/repos/ayufan-rock64/linux-kernel/releases | jq -r '.[0] | (.tag_name + "-g" + (.target_commitish | .[0:12]))')

ifeq (,$(wildcard root-$(BOARD_TARGET)))
$(error Unsupported BOARD_TARGET)
endif

all: linux-virtual \
	linux-package

linux-$(BOARD_TARGET)-$(RELEASE_NAME)_arm64.deb:
	fpm -s empty -t deb -n linux-$(BOARD_TARGET) -v $(RELEASE_NAME) \
		-p $@ \
		--deb-priority optional --category admin \
		--depends "linux-$(BOARD_TARGET)-package (= $(RELEASE_NAME))" \
		--depends "u-boot-rockchip-$(BOARD_TARGET) (= $(LATEST_UBOOT_VERSION))" \
		--depends "linux-image-$(LATEST_KERNEL_VERSION)" \
		--depends "linux-headers-$(LATEST_KERNEL_VERSION)" \
		--force \
		--url https://gitlab.com/ayufan-rock64/linux-build \
		--description "Rock64 Linux virtual package: depends on kernel and compatibility package" \
		-m "Kamil Trzciński <ayufan@ayufan.eu>" \
		--license "MIT" \
		--vendor "Kamil Trzciński" \
		-a arm64

linux-$(BOARD_TARGET)-package-$(RELEASE_NAME)_all.deb:
	fpm -s dir -t deb -n linux-$(BOARD_TARGET)-package -v $(RELEASE_NAME) \
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

.PHONY: linux-package		# compile linux compatibility package
linux-package: linux-$(BOARD_TARGET)-package-$(RELEASE_NAME)_all.deb

.PHONY: linux-virtual		# compile linux package tying compatiblity package and kernel package
linux-virtual: linux-$(BOARD_TARGET)-$(RELEASE_NAME)_arm64.deb
