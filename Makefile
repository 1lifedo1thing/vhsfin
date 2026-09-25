PORT ?= 8080
PYTHON ?= python3

.PHONY: help build serve stop restart web demo demo-onboarding

help:
	@echo "VHSFin targets:"
	@echo "  make build            flutter build web --release"
	@echo "  make serve            serve build/web on :$(PORT) (proxies /ia /vc)"
	@echo "  make stop             stop serve_web.py"
	@echo "  make restart          stop → build → serve (foreground)"
	@echo "  make web              alias for restart"
	@echo "  make demo             build + serve with open-movie demo shelves (no server)"
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

# Sample shelves from open-licensed films; no Jellyfin account required.
demo: stop
	flutter build web --release --dart-define=VHSFIN_DEMO=true
	$(PYTHON) tool/serve_web.py --port $(PORT)

demo-onboarding:
	@echo ""
	@echo "Demo the first-time VHS art-grab onboarding:"
	@echo "  1. Run the app (flutter run / make web)."
	@echo "  2. Connect + pick shelves so titles load."
	@echo "  3. Clear SharedPreferences key:"
	@echo "       vhsfin.art_onboarding_done.v1"
	@echo "     (Chrome: Application → Local Storage / site data for the origin,"
	@echo "      or wipe app prefs on device/desktop.)"
	@echo "  4. Reload — the warm pass + popup runs again."
	@echo ""
