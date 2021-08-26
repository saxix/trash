NEXT_VERSION := $(shell bumpversion --dry-run --list minor | grep '^new_version' | sed 's/.*=//')

release:
	git checkout master
	git push master

	git checkout develop
	git push develop

	git flow release start ${NEXT_VERSION}
	bumpversion minor --commit
	git flow release publish
	git checkout develop
	git prune-merged-branches -fur origin develop

