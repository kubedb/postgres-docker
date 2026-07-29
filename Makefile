SHELL=/bin/bash -o pipefail

# The KubeDB convention for Percona products is a rebuild published under
# ghcr.io/appscode-images (mirrors percona-xtradb-cluster).
REGISTRY   ?= ghcr.io/appscode-images
BIN        := percona-distribution-postgresql
IMAGE      := $(REGISTRY)/$(BIN)

# PG_MAJOR is the PostgreSQL major line. TAG should match the installed Percona
# minor; set PG_VERSION to pin it exactly (see README), otherwise the build
# tracks the latest minor of the major line and you should tag accordingly.
PG_MAJOR   ?= 17
TAG        ?= 17.9
PG_VERSION ?=

# amd64 by default; Percona publishes arm64 too.
PLATFORM   ?= linux/amd64

.PHONY: container
container:
	docker buildx build --pull --platform $(PLATFORM) --load \
		--build-arg PG_MAJOR=$(PG_MAJOR) \
		--build-arg PG_VERSION=$(PG_VERSION) \
		-t $(IMAGE):$(TAG) .

.PHONY: push
push:
	docker buildx build --pull --platform $(PLATFORM) --push \
		--build-arg PG_MAJOR=$(PG_MAJOR) \
		--build-arg PG_VERSION=$(PG_VERSION) \
		-t $(IMAGE):$(TAG) .

# Convenience: print the Percona server version baked into the built image so the
# tag can be reconciled with the actual minor.
.PHONY: version
version:
	docker run --rm --entrypoint postgres $(IMAGE):$(TAG) --version
