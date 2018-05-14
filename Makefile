NEXT_VERSION := $(shell bumpversion --dry-run --list minor | grep '^new_version' | sed 's/.*=//')

release:
	git flow feature start ${NEXT_VERSION}
	bumpversion minor
	git flow feature finish ${NEXT_VERSION}

