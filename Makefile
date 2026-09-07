PORT ?= 8080
PYTHON ?= python3

.PHONY: help build serve stop restart web demo-onboarding

help:
	@echo "VHSFin targets:"
	@echo "  make build            flutter build web --release"
	@echo "  make serve            serve build/web on :$(PORT) (proxies /ia /vc)"
	@echo "  make stop             stop serve_web.py"
	@echo "  make restart          stop → build → serve (foreground)"
	@echo "  make web              alias for restart"
	@echo "  make demo-onboarding  how to re-trigger the VHS art-grab popup"

build:
	flutter build web --release

serve:
	$(PYTHON) tool/serve_web.py --port $(PORT)

stop:
	-pkill -f 'tool/serve_web.py' || true

# Rebuild + run the static server. Ctrl-C stops serve; run make stop if needed.
restart: stop build serve

web: restart

demo-onboarding:
	@echo ""
	@echo "Demo the first-time VHS art-grab onboarding:"
	@echo "  1. Run the app (flutter run / make web)."
	@echo "  2. Connect + pick shelves so titles load."
	@echo "  3. Living room → DECK SETTINGS → REPLAY ART GRAB."
	@echo ""
	@echo "That clears SharedPreferences key:"
	@echo "  vhsfin.art_onboarding_done.v1"
	@echo "and re-runs art warm with the progress popup."
	@echo ""
