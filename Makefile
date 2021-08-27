NEXT_VERSION := $(shell bumpversion --dry-run --list minor | grep '^new_version' | sed 's/.*=//')

sync:
	@git diff --cached --exit-code
	@git diff --exit-code
	@git checkout master && git pull && git push
	@git checkout develop && git pull && git push
	@git fetch --all --prune -v
	@git branch -vv | grep 'origin/release/.*: gone]' | awk '{print $1}' | xargs git branch -d
	@git st

release: sync
	git checkout master && git pull
	git checkout develop && git pull
	git flow release start ${NEXT_VERSION}
	bumpversion minor --commit
	git flow release publish

clean:
	git remote prune origin
