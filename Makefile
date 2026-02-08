.PHONY: help setup db migrate server server-clean docker-up docker-db provoke-loop provoke-parallel perf-v1 perf-v2 perf-all perf-compare perf-matrix

WRK_TIMEOUT ?= 5

help:
	@echo "make setup    # install gems"
	@echo "make db       # create/migrate db"
	@echo "make migrate  # run db migrations"
	@echo "make server   # run rails server"
	@echo "make server-clean # remove stale Rails pid files"
	@echo "make docker-up # build and start docker services"
	@echo "make docker-db # prepare db inside docker"
	@echo "make provoke-loop # continuously call the API demo script"
	@echo "make provoke-parallel N=8 DELAY=0.2 # run N parallel loops"
	@echo "make perf-v1 # run perf tests against v1"
	@echo "make perf-v2 # run perf tests against v2"
	@echo "make perf-all # run perf tests against v1 then v2"
	@echo "make perf-compare # wrk compare v1/v2 with docker memory sampling"
	@echo "make perf-matrix # run a small perf matrix and save markdown reports"


docker-down:
	docker compose down

docker-up:
	docker compose up -d

docker-db:
	docker compose run --rm web_v1 bin/rails db:prepare

docker-migrate: 
	docker compose run --rm web_v1 bin/rails db:migrate

server-clean:
	rm -f tmp/pids/server.pid tmp/pids/server_v1.pid tmp/pids/server_v2.pid

provoke-loop:
	@while true; do ./scripts/provoke_api.sh; sleep 0.2; done

provoke-parallel:
	@N=$${N:-8}; DELAY=$${DELAY:-0.2}; \
	for i in `seq 1 $$N`; do \
		( while true; do ./scripts/provoke_api.sh; sleep $$DELAY; done ) & \
	done; \
	wait


perf-v1:
	WRK_TIMEOUT=$(WRK_TIMEOUT) BUNDLE_PATH=vendor/bundle DOCKER_SERVICE=web_v1 BASE_URL=http://localhost:3001 PERF_PATH=/api/v1/register ruby -S bundle exec rake perf:single

perf-compare-v1:
	WRK_TIMEOUT=$(WRK_TIMEOUT) BUNDLE_PATH=vendor/bundle DOCKER_SERVICE=web_v1 BASE_URL=http://localhost:3001 PERF_PATH=/api/v2/register ruby -S bundle exec rake perf:compare

perf-matrix:
	WRK_TIMEOUT=$(WRK_TIMEOUT) BUNDLE_PATH=vendor/bundle \
		DOCKER_SERVICE_V1=web_v1  DOCKER_SERVICE_V2=web_v2 \
		BASE_URL_V1=http://localhost:3001 V1_PATH=/api/v1/register \
		BASE_URL_V2=http://localhost:3002 V2_PATH=/api/v2/register \
		ruby -S bundle exec rake perf:matrix


perf-v2:
	WRK_TIMEOUT=$(WRK_TIMEOUT) BUNDLE_PATH=vendor/bundle DOCKER_SERVICE=web_v2 BASE_URL=http://localhost:3002 PERF_PATH=/api/v2/register ruby -S bundle exec rake perf:single

perf-compare-v2:
	WRK_TIMEOUT=$(WRK_TIMEOUT) BUNDLE_PATH=vendor/bundle DOCKER_SERVICE=web_v2 BASE_URL=http://localhost:3002 PERF_PATH=/api/v2/register ruby -S bundle exec rake perf:compare




await-10:
	sleep 10

clean:
	rm -rf tmp/*

perf-all:  docker-down server-clean docker-up await-10 docker-db docker-migrate perf-matrix docker-down
