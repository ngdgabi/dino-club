XCODEBUILD=/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild

.PHONY: all macos ios release run clean

all: release

macos:
	$(XCODEBUILD) -project DinoClub.xcodeproj -scheme DinoClub -configuration Release -destination "generic/platform=macOS" -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build

ios:
	$(XCODEBUILD) -project DinoClub.xcodeproj -scheme DinoClubMobile -configuration Release -destination "generic/platform=iOS" -derivedDataPath build/DerivedDataMobile CODE_SIGNING_ALLOWED=NO build

release:
	chmod +x package_release.sh
	./package_release.sh

run: release
	open "dist/Dino Club.app"

clean:
	rm -rf build/universal_pkg build/DerivedData
