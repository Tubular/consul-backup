VERSION := $(shell awk -F\" '/^const Version/ { print $$2; exit }' version.go)
NAME := consul-bak
PKG := github.com/Tubular/${NAME}

GIT_COMMIT := $(shell git rev-parse --short HEAD)
GIT_DESCRIBE := $(shell git describe --tags --always)


XC_ARCH := "amd64"
XC_OS := "darwin linux"

# Prepend our _vendor directory to the system GOPATH
# so that import path resolution will prioritize
# our third party snapshots.
GOPATH := ${PWD}/_vendor:${GOPATH}
export GOPATH

default: build

build: vet
	# add -i?
	@echo "Building consul-bak ${VERSION}"
	@gox \
		-os=${XC_OS} \
		-arch=${XC_ARCH} \
		-ldflags "-X main.GitCommit=${GIT_COMMIT} -X main.GitDescribe=${GIT_DESCRIBE}" \
		-output build/${NAME}-v${VERSION}-{{.OS}}_{{.Arch}} \
		${PKG}

doc:
	godoc ${PKG} -http=:6060 -index

# http://golang.org/cmd/go/#hdr-Run_gofmt_on_package_sources
fmt:
	go fmt .

# https://github.com/golang/lint
# go get github.com/golang/lint/golint
lint:
	golint .

run: build
	./build/${NAME}-v${VERSION}

test:	vendor_get
	go test ./tests

vendor_clean:
	rm -rf ./vendor

# We have to set GOPATH to just the _vendor
# directory to ensure that `go get` doesn't
# update packages in our primary GOPATH instead.
# This will happen if you already have the package
# installed in GOPATH since `go get` will use
# that existing location as the destination.
vendor_get:	 vendor_clean
	glide install

vendor_update:	vendor_get
	glide up

vet:
	go vet .


.PHONY: build doc fmt lint run test vendor_clean vendor_get vendor_update vet
