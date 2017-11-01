TMP_FOLDER=/tmp
RELEASE_FOLDER=wllbg-release

ifndef ENV
	ENV=prod
endif

help: ## Display this help menu
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

clean: ## Clear the application cache
	rm -rf var/cache/*

install: ## Install wallabag with the latest version
	@sh scripts/install.sh $(ENV)

update: ## Update the wallabag installation to the latest version
	@sh scripts/update.sh $(ENV)

dev: ## Install the latest dev version
	@sh scripts/dev.sh

run: ## Run the wallabag built-in server
	@php bin/console server:run --env=$(ENV)

build: ## Run webpack
	@npm run build:$(ENV)

prepare: clean ## Prepare database for testsuite
ifdef DB
	cp app/config/tests/parameters_test.$(DB).yml app/config/parameters_test.yml
endif
	-php bin/console doctrine:database:drop --force --env=test
	php bin/console doctrine:database:create --env=test
ifndef DB ## make test does not define DB
	php bin/console doctrine:schema:create --env=test
endif
ifeq ($(DB), sqlite)
	php bin/console doctrine:schema:create --env=test
endif
ifeq ($(DB), mysql)
	php bin/console doctrine:database:import data/sql/mysql_base.sql --env=test
endif
ifeq ($(DB), pgsql)
	psql -h localhost -d wallabag_test -U travis -f data/sql/pgsql_base.sql
endif

fixtures: ## Load fixtures into database
	php bin/console doctrine:fixtures:load --no-interaction --env=test

test: prepare fixtures ## Launch wallabag testsuite
	bin/simple-phpunit -v

release: ## Create a package. Need a VERSION parameter (eg: `make release VERSION=master`).
ifndef VERSION
	$(error VERSION is not set)
endif
	@sh scripts/release.sh $(VERSION) $(TMP_FOLDER) $(RELEASE_FOLDER) $(ENV)

deploy: ## Deploy wallabag
	@bundle exec cap staging deploy

.PHONY: help clean prepare install update build test release deploy run dev

.DEFAULT_GOAL := install
