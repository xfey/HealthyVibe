.PHONY: build bundle release-bundle run clean

build:
	swift build

bundle:
	./Scripts/build_app_bundle.sh debug

release-bundle:
	./Scripts/build_app_bundle.sh release

run: bundle
	open .build/HealthyVibe.app

clean:
	swift package clean
