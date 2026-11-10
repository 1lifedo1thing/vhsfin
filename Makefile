PORT ?= 8081
# VHSCOLLECTOR=true compiles in the optional VHSCollector sleeve lookup.
VHSCOLLECTOR ?= false
DEFINES = --dart-define=VHSFIN_VHSCOLLECTOR=$(VHSCOLLECTOR)
PYTHON ?= python3

.PHONY: help build serve stop restart web demo demo-onboarding \
	gems ios-beta ios-listing ios-release android-internal android-listing android-ship android-production \
	store-screenshots site-film site jellyfin-compat

help:
	@echo "VHSFin targets:"
	@echo "  make build            flutter build web --release"
	@echo "  make serve            serve build/web on :$(PORT) (proxies /ia /vc)"
	@echo "  make stop             stop serve_web.py"
	@echo "  make restart          stop → build → serve (foreground)"
	@echo "  make web              alias for restart"
	@echo "  make demo             build + serve with open-movie demo shelves (no server)"
	@echo "  make demo-onboarding  how to re-trigger the VHS art-grab popup"
	@echo "  make jellyfin-compat  run the client against Jellyfin in Docker (JELLYFIN=10.10.7)"
	@echo ""
	@echo "Release (secrets in .env; see .env.example):"
	@echo "  make gems             install Fastlane (Homebrew Ruby, into vendor/bundle)"
	@echo "  make ios-beta         build and upload to TestFlight"
	@echo "  make ios-listing      upload App Store text and screenshots"
	@echo "  make ios-release      build, upload, and submit for review"
	@echo "  make android-ship     Play listing + images + internal-track draft"
	@echo "  make android-production  signed AAB to production review"
	@echo "  make store-screenshots   capture and frame store screenshots"
	@echo "  make site-film        re-record and re-cut the website film"
	@echo "  make site             build the website into site/vhsfin/dist"

build:
	flutter build web --release $(DEFINES)

serve:
	$(PYTHON) tool/serve_web.py --port $(PORT)

stop:
	-pkill -f 'tool/serve_web.py' || true

# Rebuild + run the static server. Ctrl-C stops serve; run make stop if needed.
restart: stop build serve

web: restart

# Sample shelves from open-licensed films; no Jellyfin account required.
demo: stop
	flutter build web --release --dart-define=VHSFIN_DEMO=true $(DEFINES)
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

# The Jellyfin client against a real server in Docker. JELLYFIN is an image tag
# (10.8.13, 10.11, latest, unstable, ...); CI runs the same matrix.
JELLYFIN ?= latest
JELLYFIN_PORT ?= 18096

jellyfin-compat:
	tool/jellyfin_server.sh up jellyfin/jellyfin:$(JELLYFIN) $(JELLYFIN_PORT)
	JELLYFIN_TEST_URL=http://localhost:$(JELLYFIN_PORT) flutter test test/jellyfin_server_compat_test.dart; \
		status=$$?; tool/jellyfin_server.sh down; exit $$status

# --- Release -----------------------------------------------------------------
# Fastlane needs Ruby >= 3.1; macOS ships 2.6, so use Homebrew's (brew install ruby).
RUBY_PATH := /opt/homebrew/opt/ruby/bin:/opt/homebrew/bin
BUNDLE := PATH="$(RUBY_PATH):$$PATH" BUNDLE_PATH="$(CURDIR)/vendor/bundle" bundle
# Pillow for the screenshot and film scripts.
PY_TOOLS ?= python3

gems:
	$(BUNDLE) install

ios-beta: gems
	$(BUNDLE) exec fastlane ios beta

ios-listing: gems
	$(BUNDLE) exec fastlane ios listing

ios-release: gems
	$(BUNDLE) exec fastlane ios release

android-internal: gems
	$(BUNDLE) exec fastlane android internal

android-listing: gems
	$(BUNDLE) exec fastlane android listing

android-ship: gems
	$(BUNDLE) exec fastlane android ship

android-production: gems
	$(BUNDLE) exec fastlane android production

store-screenshots:
	tool/store_screenshots.sh "iPhone 18 Pro Max" iphone
	tool/store_screenshots.sh "iPad Pro 13-inch (M5)" ipad
	$(PY_TOOLS) tool/frame_screenshots.py

site-film:
	tool/site_film.sh
	$(PY_TOOLS) tool/encode_site_film.py

site:
	cd site/vhsfin && python3 build.py
