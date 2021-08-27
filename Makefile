NEXT_VERSION := $(shell bumpversion --allow-dirty --dry-run --list minor | grep '^new_version' | sed 's/.*=//')

clean:
	@git fetch --all --prune -v
# 	@git branch -vv | grep 'origin/release/.*: gone]' | awk '{print $1}' | xargs git branch -d
	@git remote prune origin

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

