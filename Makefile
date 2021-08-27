NEXT_VERSION := $(shell bumpversion --dry-run --list minor | grep '^new_version' | sed 's/.*=//')

release:
	git push --all
	git checkout master && git pull
	git checkout develop && git pull
	git flow release start ${NEXT_VERSION}
	bumpversion minor --commit
	git flow release publish

clean:
	git remote prune origin
# 	git branch --merged | xargs git branch -d
