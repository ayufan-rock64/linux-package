export RELEASE_NAME ?= $(shell git describe --tags)
export RELEASE ?= 1

all: build

linux-rock64-package-$(RELEASE_NAME).deb:
	fpm -s dir -t deb -n linux-rock64-package -v $(RELEASE_NAME) \
		-p $@ \
		--deb-priority optional --category admin \
		--force \
		--deb-compression bzip2 \
		--after-install scripts/postinst.deb \
		--before-remove scripts/prerm.deb \
		--url https://gitlab.com/ayufan-rock64/linux-build \
		--description "Rock64 Linux support package" \
		--config-files /boot/extlinux/ \
		-m "Kamil Trzciński <ayufan@ayufan.eu>" \
		--license "MIT" \
		--vendor "Kamil Trzciński" \
		-a all \
		root/=/

.PHONY: build
build: linux-rock64-package-$(RELEASE_NAME).deb

.PHONY: upload
upload: linux-rock64-package-$(RELEASE_NAME).deb
		github-release release \
			--tag "${RELEASE_NAME}" \
			--name "${RELEASE_NAME}: ${BUILD_TAG}" \
			--description "${BUILD_URL}" \
			--draft

		for file in $^; do \
			github-release upload \
				--tag "${RELEASE_NAME}" \
				--name "\$(basename "${file}")" \
				--file "${file}"; \
		done

		if git describe --tags --exact-match &>/dev/null; then \
			github-release edit \
				--tag "${RELEASE_NAME}" \
				--name "${RELEASE_NAME}: ${BUILD_TAG}" \
				--description "${BUILD_URL}"; \
		else \
			github-release edit \
				--tag "${RELEASE_NAME}" \
				--name "${RELEASE_NAME}: ${BUILD_TAG}" \
				--description "${BUILD_URL}"; \
				--pre-release; \
		fi
