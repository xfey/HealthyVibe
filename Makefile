.PHONY: build icon bundle release-bundle package run clean

build:
	swift build

icon:
	./Scripts/generate_app_icon.swift

bundle:
	./Scripts/build_app_bundle.sh debug

release-bundle:
	./Scripts/build_app_bundle.sh release

package:
	./Scripts/package_release.sh

run: bundle
	open .build/HealthyVibe.app

clean:
	swift package clean
