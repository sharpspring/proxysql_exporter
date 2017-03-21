.PHONY: all binary binary-in-docker build tag release test test-in-docker copy-to-gopath

repo=proxysql_exporter
shorthash=`git rev-parse --short HEAD`
image=us.gcr.io/sharpspring-us/$(repo):$(shorthash)
branchimage=us.gcr.io/sharpspring-us/$(repo):`git rev-parse --abbrev-ref HEAD`
GOPATH ?= $(HOME)/go

# Make sure to remove proto as a dependency if your repo doesn't use a protobuf file
all: binary build

copy-to-gopath:
	[ "$$PWD" = "$(GOPATH)/src/github.com/sharpspring/$(repo)" ] \
		|| ( \
			mkdir -p $(GOPATH)/src/github.com/sharpspring \
			&& rm -rf $(GOPATH)/src/github.com/sharpspring/$(repo) \
			&& cp -R . $(GOPATH)/src/github.com/sharpspring/$(repo) \
		)

binary: copy-to-gopath
	cd $(GOPATH)/src/github.com/sharpspring/$(repo) \
		&& GOPATH=$(GOPATH) go get \
		&& GOPATH=$(GOPATH) CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo --ldflags '-extldflags "-static"' -v -o ${CURDIR}/${repo}

# Seem like magic? Check here to learn more about what's actually going on:
# https://github.com/sharpspring/Dockerfiles/tree/master/golang
binary-in-docker:
	gcloud docker -- pull us.gcr.io/sharpspring-us/golang:build
	echo "FROM us.gcr.io/sharpspring-us/golang:build" > Dockerfile.build
	docker build -f Dockerfile.build -t tmp-image-$(repo) --build-arg repo=$(repo) . \
		&& docker run --name tmp-image-$(repo) --rm tmp-image-$(repo) > $(repo) \
		&& chmod +x $(repo) \
		&& docker rmi -f tmp-image-$(repo)

test: copy-to-gopath
	cd $(GOPATH)/src/github.com/sharpspring/$(repo) \
		&& GOPATH=$(GOPATH) go get \
		&& GOPATH=$(GOPATH) go test -v

# Seem like magic? Check here to learn more about what's actually going on:
# https://github.com/sharpspring/Dockerfiles/tree/master/golang
test-in-docker:
	gcloud docker -- pull us.gcr.io/sharpspring-us/golang:test
	echo "FROM us.gcr.io/sharpspring-us/golang:test" > Dockerfile.test
	docker build -f Dockerfile.test -t tmp-image-$(repo) --build-arg repo=$(repo) . \
		&& docker rmi tmp-image-$(repo)

build:
	docker build -t $(image) .

release:
	gcloud docker -- push $(image)

deploy:
	if [ -n "$(context)" ]; then kubectl --context=$(context) patch deployment $(repo) -p \
		'{"spec":{"template":{"spec":{"containers":[{"name":"$(repo)", "image": "us.gcr.io/sharpspring-us/$(repo):'$(shorthash)'"}]}}}}'; \
		fi

template:
	rm -rf tmp-k8s
	mkdir -p tmp-k8s
	for file in k8s/*.yaml; do \
		cat $$file | sed "s/DIFF_ID/$(shorthash)/g" > tmp-k8s/$$(basename $$file); \
	done

tag:
	docker tag $(image) $(branchimage)
	gcloud docker -- push $(branchimage)
