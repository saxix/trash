NEXT_VERSION := $(shell bumpversion --dry-run --list minor | grep '^new_version' | sed 's/.*=//')

pull:
	@git checkout master && git pull
	@git checkout develop && git pull
	@git push --all
	@git fetch --all
	@git st

release: pull
	git checkout master && git pull
	git checkout develop && git pull
	git flow release start ${NEXT_VERSION}
	bumpversion minor --commit
	git flow release publish
	git checkout develop && git prune-merged-branches -fur origin develop

clean:
	git remote prune origin
# 	git branch --merged | xargs git branch -d
