PREFIX ?= /usr/local
VERSION ?= $(shell git describe --tags --dirty --always | sed -e 's/^v//')
IS_SNAPSHOT = $(if $(findstring -, $(VERSION)),true,false)
MAJOR_VERSION = $(word 1, $(subst ., ,$(VERSION)))
MINOR_VERSION = $(word 2, $(subst ., ,$(VERSION)))
PATCH_VERSION = $(word 3, $(subst ., ,$(word 1,$(subst -, , $(VERSION)))))
NEW_VERSION ?= $(MAJOR_VERSION).$(MINOR_VERSION).$(shell echo $$(( $(PATCH_VERSION) + 1)) )

NEXT_VERSION := $(shell bumpversion --allow-dirty --dry-run --list minor | grep '^new_version' | sed 's/.*=//')

info:
	@echo "VERSION     : ${VERSION}"
	@echo "IS_SNAPSHOT : ${IS_SNAPSHOT}"
	@echo "MAJOR       : ${MAJOR_VERSION}"
	@echo "MINOR       : ${MINOR_VERSION}"
	@echo "PATCH       : ${PATCH_VERSION}"
	@echo "NEW_VERSION : ${NEW_VERSION}"
	@echo "NEXT_VERSION: ${NEXT_VERSION}"


clean:
	@echo "Clean"
	@git fetch --all --prune -v
	@git remote prune origin
	@git branch -vv

sync: clean
	@echo "Sync"
	@git diff --cached --exit-code
	@git diff --exit-code
	@git checkout master && git pull && git push
	@git checkout develop && git pull && git push
	@git st
# 	@git branch -vv | grep "origin/release/.*: gone]" | awk '{print $1}' | xargs git branch -D

release: sync
	git checkout master && git pull
	git checkout develop && git pull
	NEXT_VERSION=`bumpversion --dry-run --list minor | grep '^new_version' | sed 's/.*=//'` git flow release start ${NEXT_VERSION}
	bumpversion minor --commit
	git flow release publish
	git checkout develop

