.PHONY: build bundle release-bundle package run icon clean

build:
	swift build

bundle:
	./Scripts/build_app_bundle.sh debug

release-bundle:
	./Scripts/build_app_bundle.sh release

package:
	./Scripts/package_release.sh

run: bundle
	open .build/HealthyVibe.app

icon:
	swift Scripts/generate_icons.swift

clean:
	swift package clean
