build:
	docker-compose build

run:
	docker-compose up

test:
	docker-compose run web bundle exec rspec

bash:
	docker-compose run web bash

.PHONY: build run test bash