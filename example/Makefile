PID_FILE := /tmp/example_phoenix_server.pid

start:
	mix phx.server & echo $$! > $(PID_FILE)

stop:
	@if [ -f $(PID_FILE) ]; then \
		kill $$(cat $(PID_FILE)) 2>/dev/null && rm -f $(PID_FILE); \
	else \
		lsof -ti:4000 | xargs kill -9 2>/dev/null; \
	fi

restart: stop start

.PHONY: start stop restart
