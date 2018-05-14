NEXT_VERSION := $(shell bumpversion --dry-run --list minor | grep '^new_version' | sed 's/.*=//')

release:
	git flow release start ${NEXT_VERSION}
	bumpversion minor
	git flow release -m "v${NEXT_VERSION}" -p finish ${NEXT_VERSION}

