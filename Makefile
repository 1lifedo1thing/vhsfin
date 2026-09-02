PORT ?= 8080
PYTHON ?= python3

.PHONY: help build serve stop restart web

help:
	@echo "VHSFin web targets:"
	@echo "  make build     flutter build web --release"
	@echo "  make serve     serve build/web on :$(PORT) (proxies /ia /vc)"
	@echo "  make stop      stop serve_web.py"
	@echo "  make restart   stop → build → serve (foreground)"
	@echo "  make web       alias for restart"

build:
	flutter build web --release

serve:
	$(PYTHON) tool/serve_web.py --port $(PORT)

stop:
	-pkill -f 'tool/serve_web.py' || true

# Rebuild + run the static server. Ctrl-C stops serve; run make stop if needed.
restart: stop build serve

web: restart
