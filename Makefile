.PHONY: help setup db migrate server docker-up docker-db provoke-loop provoke-parallel perf-compare perf-matrix

help:
	@echo "make setup    # install gems"
	@echo "make db       # create/migrate db"
	@echo "make migrate  # run db migrations"
	@echo "make server   # run rails server"
	@echo "make docker-up # build and start docker services"
	@echo "make docker-db # prepare db inside docker"
	@echo "make provoke-loop # continuously call the API demo script"
	@echo "make provoke-parallel N=8 DELAY=0.2 # run N parallel loops"
	@echo "make perf-compare # wrk compare v1/v2 with docker memory sampling"
	@echo "make perf-matrix # run a small perf matrix and save markdown reports"

setup:
	BUNDLE_PATH=vendor/bundle bundle install

db:
	BUNDLE_PATH=vendor/bundle bin/rails db:prepare

migrate:
	docker compose run --rm web bin/rails db:migrate

server:
	BUNDLE_PATH=vendor/bundle bin/rails s -b 0.0.0.0 -p 3000

docker-up:
	docker compose up --build

docker-db:
	docker compose run --rm web bin/rails db:prepare

provoke-loop:
	@while true; do ./scripts/provoke_api.sh; sleep 0.2; done

provoke-parallel:
	@N=$${N:-8}; DELAY=$${DELAY:-0.2}; \
	for i in `seq 1 $$N`; do \
		( while true; do ./scripts/provoke_api.sh; sleep $$DELAY; done ) & \
	done; \
	wait

perf-compare:
	BUNDLE_PATH=vendor/bundle DOCKER_SERVICE=web BASE_URL=http://localhost:3000 /Users/luizamboni/.rvm/rubies/ruby-3.3.0/bin/ruby -S bundle exec rake perf:compare

perf-matrix:
	BUNDLE_PATH=vendor/bundle DOCKER_SERVICE=web BASE_URL=http://localhost:3000 /Users/luizamboni/.rvm/rubies/ruby-3.3.0/bin/ruby -S bundle exec rake perf:matrix
