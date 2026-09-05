SCHEME = CutAndMove
APP_NAME = CutAndMove
BUILD_DIR = build
ARCHIVE_PATH = $(BUILD_DIR)/$(APP_NAME).xcarchive
EXPORT_PATH = $(BUILD_DIR)/export
APP_PATH = $(EXPORT_PATH)/$(APP_NAME).app
DEVELOPER_ID = Developer ID Application: MILL5, LLC (FS6453639M)
VERSION = $(shell sed -n 's/.*MARKETING_VERSION = \([^;]*\);/\1/p' CutAndMove.xcodeproj/project.pbxproj | head -1)

.PHONY: build test archive export notarize verify-release dmg zip package release publish marketing marketing-check
.NOTPARALLEL:
build:
	xcodebuild -project CutAndMove.xcodeproj -scheme $(SCHEME) -configuration Debug build
test:
	xcodebuild -project CutAndMove.xcodeproj -scheme $(SCHEME) -destination 'platform=macOS' test
marketing:
	python3 scripts/sync-marketing.py
marketing-check:
	python3 scripts/sync-marketing.py --check
archive: marketing-check
	mkdir -p $(BUILD_DIR)
	xcodebuild -project CutAndMove.xcodeproj -scheme $(SCHEME) -configuration Release -destination 'generic/platform=macOS' -archivePath $(ARCHIVE_PATH) -allowProvisioningUpdates archive
export: archive
	xcodebuild -exportArchive -archivePath $(ARCHIVE_PATH) -exportOptionsPlist scripts/ExportOptions-export.plist -exportPath $(EXPORT_PATH) -allowProvisioningUpdates
notarize: archive
	xcodebuild -exportArchive -archivePath $(ARCHIVE_PATH) -exportOptionsPlist scripts/ExportOptions-upload.plist -exportPath $(BUILD_DIR)/xcode-distribution -allowProvisioningUpdates
	bash scripts/export-notarized.sh $(ARCHIVE_PATH) $(EXPORT_PATH)
verify-release:
	test "$$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' $(APP_PATH)/Contents/Info.plist)" = "$(VERSION)"
	test "$$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' $(APP_PATH)/Contents/Info.plist)" = "M5.CutAndMove"
	codesign --verify --deep --strict --verbose $(APP_PATH)
	codesign -dvv $(APP_PATH) 2>&1 | grep -F 'Authority=$(DEVELOPER_ID)'
	xcrun stapler validate $(APP_PATH)
	spctl --assess --type execute --verbose=2 $(APP_PATH)
dmg: verify-release
	swift generate_dmg_bg.swift $(BUILD_DIR)/dmg-background.png
	test ! -e $(BUILD_DIR)/$(APP_NAME).dmg
	create-dmg --volname "$(APP_NAME)" --background $(BUILD_DIR)/dmg-background.png --window-pos 200 120 --window-size 660 400 --icon-size 100 --icon "$(APP_NAME).app" 175 190 --app-drop-link 485 190 --text-size 14 --no-internet-enable $(BUILD_DIR)/$(APP_NAME).dmg $(APP_PATH)
	codesign --sign "$(DEVELOPER_ID)" $(BUILD_DIR)/$(APP_NAME).dmg
	codesign --verify --strict $(BUILD_DIR)/$(APP_NAME).dmg
zip: verify-release
	test ! -e $(BUILD_DIR)/$(APP_NAME).zip
	ditto -c -k --sequesterRsrc --keepParent $(APP_PATH) $(BUILD_DIR)/$(APP_NAME).zip
package: dmg zip
	cd $(BUILD_DIR) && shasum -a 256 $(APP_NAME).dmg $(APP_NAME).zip > SHA256SUMS
release: notarize
	$(MAKE) package
publish: verify-release
	cd $(BUILD_DIR) && shasum -a 256 -c SHA256SUMS
	gh release create v$(VERSION) $(BUILD_DIR)/$(APP_NAME).dmg $(BUILD_DIR)/$(APP_NAME).zip $(BUILD_DIR)/SHA256SUMS LICENSE --verify-tag --title "$(APP_NAME) v$(VERSION)" --notes-file docs/RELEASE_NOTES_$(VERSION).md
