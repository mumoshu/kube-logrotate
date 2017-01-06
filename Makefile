KUBE_LOGROTATE_VERSION ?= 0.1.0

REPOSITORY ?= mumoshu/kube-logrotate
TAG ?= $(KUBE_LOGROTATE_VERSION)
IMAGE ?= $(REPOSITORY):$(TAG)

BUILD_ROOT ?= build/$(TAG)
DOCKERFILE ?= $(BUILD_ROOT)/Dockerfile
ROOTFS ?= $(BUILD_ROOT)/rootfs
DOCKER_CACHE ?= docker-cache
SAVED_IMAGE ?= $(DOCKER_CACHE)/image-$(KUBE_LOGROTATE_VERSION).tar

.PHONY: build
build: $(DOCKERFILE) $(ROOTFS)
	./build-confd
	cd $(BUILD_ROOT) && docker build -t $(IMAGE) .

.PHONY: clean
clean:
	rm -rf $(BUILD_ROOT)

publish:
	docker push $(IMAGE)

$(DOCKERFILE): $(BUILD_ROOT)
	cp Dockerfile.template $(DOCKERFILE)

$(ROOTFS): $(BUILD_ROOT)
	cp -R rootfs $(ROOTFS)

$(BUILD_ROOT):
	mkdir -p $(BUILD_ROOT)

travis-env:
	travis env set DOCKER_EMAIL $(DOCKER_EMAIL)
	travis env set DOCKER_USERNAME $(DOCKER_USERNAME)
	travis env set DOCKER_PASSWORD $(DOCKER_PASSWORD)

test:
	@echo There are no tests available for now. Skipping

save-docker-cache: $(DOCKER_CACHE)
	docker save $(IMAGE) $(shell docker history -q $(IMAGE) | tail -n +2 | grep -v \<missing\> | tr '\n' ' ') > $(SAVED_IMAGE)
	ls -lah $(DOCKER_CACHE)

load-docker-cache: $(DOCKER_CACHE)
	if [ -e $(SAVED_IMAGE) ]; then docker load < $(SAVED_IMAGE); fi

$(DOCKER_CACHE):
	mkdir -p $(DOCKER_CACHE)

docker-run: DOCKER_CMD ?=
docker-run:
	docker run --rm -it \
	  --privileged \
	  -v /mnt/sda1:/mnt/sda1 \
	  -v /var/lib/docker/containers:/var/lib/docker/containers \
	  -v /var/log:/var/log \
	$(IMAGE) $(DOCKER_CMD)

