NEXT_VERSION := $(shell bumpversion --dry-run --list minor | grep '^new_version' | sed 's/.*=//')

clean:
	@git fetch --all --prune -v
	@git remote prune origin
	git branch -vv | grep "origin/release/.*: gone]" | awk '{print $1}' | xargs git branch -d
	@git branch -vv

sync: clean
	@git diff --cached --exit-code
	@git diff --exit-code
	@git checkout master && git pull && git push
	@git checkout develop && git pull && git push
	@git st

release: sync
	git checkout master && git pull
	git checkout develop && git pull
	git flow release start ${NEXT_VERSION}
	bumpversion minor --commit
	git flow release publish
	git checkout develop

