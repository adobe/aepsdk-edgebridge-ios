
export EXTENSION_NAME = AEPEdgeBridge
PROJECT_NAME = $(EXTENSION_NAME)
TARGET_NAME_XCFRAMEWORK = $(EXTENSION_NAME).xcframework
SCHEME_NAME_XCFRAMEWORK = $(EXTENSION_NAME)XCF
TEST_APP_IOS_SCHEME = TestAppiOS
TEST_APP_TVOS_SCHEME = TestApptvOS

CURR_DIR := ${CURDIR}
IOS_SIMULATOR_ARCHIVE_PATH = $(CURR_DIR)/build/ios_simulator.xcarchive/Products/Library/Frameworks/
IOS_SIMULATOR_ARCHIVE_DSYM_PATH = $(CURR_DIR)/build/ios_simulator.xcarchive/dSYMs/
IOS_ARCHIVE_PATH = $(CURR_DIR)/build/ios.xcarchive/Products/Library/Frameworks/
IOS_ARCHIVE_DSYM_PATH = $(CURR_DIR)/build/ios.xcarchive/dSYMs/
TVOS_SIMULATOR_ARCHIVE_PATH = $(CURR_DIR)/build/tvos_simulator.xcarchive/Products/Library/Frameworks/
TVOS_SIMULATOR_ARCHIVE_DSYM_PATH = $(CURR_DIR)/build/tvos_simulator.xcarchive/dSYMs/
TVOS_ARCHIVE_PATH = $(CURR_DIR)/build/tvos.xcarchive/Products/Library/Frameworks/
TVOS_ARCHIVE_DSYM_PATH = $(CURR_DIR)/build/tvos.xcarchive/dSYMs/

# Values with defaults
IOS_DEVICE_NAME ?= iPhone 15
# If OS version is not specified, uses the first device name match in the list of available simulators
IOS_VERSION ?=
ifeq ($(strip $(IOS_VERSION)),)
    IOS_DESTINATION = "platform=iOS Simulator,name=$(IOS_DEVICE_NAME)"
else
    IOS_DESTINATION = "platform=iOS Simulator,name=$(IOS_DEVICE_NAME),OS=$(IOS_VERSION)"
endif

TVOS_DEVICE_NAME ?= Apple TV
# If OS version is not specified, uses the first device name match in the list of available simulators
TVOS_VERSION ?=
ifeq ($(strip $(TVOS_VERSION)),)
	TVOS_DESTINATION = "platform=tvOS Simulator,name=$(TVOS_DEVICE_NAME)"
else
	TVOS_DESTINATION = "platform=tvOS Simulator,name=$(TVOS_DEVICE_NAME),OS=$(TVOS_VERSION)"
endif

setup:
	pod install

clean:
	rm -rf build

clean-ios-test-files:
	rm -rf iosresults.xcresult

pod-install:
	pod install --repo-update

open:
	open $(PROJECT_NAME).xcworkspace

pod-repo-update:
	pod repo update

pod-update: pod-repo-update
	pod update

ci-pod-repo-update:
	bundle exec pod repo update

ci-pod-update: ci-pod-repo-update
	bundle exec pod update

ci-pod-install:
	bundle exec pod install --repo-update

archive: pod-install archive

ci-archive: ci-pod-install archive

archive: pod-install _archive

_archive: clean build-ios build-tvos
	@echo "######################################################################"
	@echo "### Generating iOS and tvOS Frameworks for $(PROJECT_NAME)"
	@echo "######################################################################"
	xcodebuild -create-xcframework -framework $(IOS_SIMULATOR_ARCHIVE_PATH)$(PROJECT_NAME).framework -debug-symbols $(IOS_SIMULATOR_ARCHIVE_DSYM_PATH)$(PROJECT_NAME).framework.dSYM \
	-framework $(TVOS_SIMULATOR_ARCHIVE_PATH)$(PROJECT_NAME).framework -debug-symbols $(TVOS_SIMULATOR_ARCHIVE_DSYM_PATH)$(PROJECT_NAME).framework.dSYM \
	-framework $(IOS_ARCHIVE_PATH)$(PROJECT_NAME).framework -debug-symbols $(IOS_ARCHIVE_DSYM_PATH)$(PROJECT_NAME).framework.dSYM \
	-framework $(TVOS_ARCHIVE_PATH)$(PROJECT_NAME).framework -debug-symbols $(TVOS_ARCHIVE_DSYM_PATH)$(PROJECT_NAME).framework.dSYM -output ./build/$(PROJECT_NAME).xcframework

build-ios:
	@echo "######################################################################"
	@echo "### Building iOS archive"
	@echo "######################################################################"
	xcodebuild archive -workspace $(PROJECT_NAME).xcworkspace -scheme $(PROJECT_NAME) -archivePath "./build/ios.xcarchive" -sdk iphoneos -destination="iOS" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
	xcodebuild archive -workspace $(PROJECT_NAME).xcworkspace -scheme $(PROJECT_NAME) -archivePath "./build/ios_simulator.xcarchive" -sdk iphonesimulator -destination="iOS Simulator" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

build-tvos:
	@echo "######################################################################"
	@echo "### Building tvOS archive"
	@echo "######################################################################"
	xcodebuild archive -workspace $(PROJECT_NAME).xcworkspace -scheme $(SCHEME_NAME_XCFRAMEWORK) -archivePath "./build/tvos.xcarchive" -sdk appletvos -destination="tvOS" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES ADB_SKIP_LINT=YES
	xcodebuild archive -workspace $(PROJECT_NAME).xcworkspace -scheme $(SCHEME_NAME_XCFRAMEWORK) -archivePath "./build/tvos_simulator.xcarchive" -sdk appletvsimulator -destination="tvOS Simulator" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES ADB_SKIP_LINT=YES

zip:
	cd build && zip -r $(EXTENSION_NAME).xcframework.zip $(EXTENSION_NAME).xcframework/
	swift package compute-checksum build/$(EXTENSION_NAME).xcframework.zip

build-app: setup
	@echo "######################################################################"
	@echo "### Building $(TEST_APP_IOS_SCHEME)"
	@echo "######################################################################"
	xcodebuild clean build -workspace $(PROJECT_NAME).xcworkspace -scheme $(TEST_APP_IOS_SCHEME) -destination 'generic/platform=iOS Simulator'

	@echo "######################################################################"
	@echo "### Building $(TEST_APP_TVOS_SCHEME)"
	@echo "######################################################################"
	xcodebuild clean build -workspace $(PROJECT_NAME).xcworkspace -scheme $(TEST_APP_TVOS_SCHEME) -destination 'generic/platform=tvOS Simulator'

test: unit-test-ios functional-test-ios unit-test-tvos functional-test-tvos

unit-test-ios:
	@echo "######################################################################"
	@echo "### Unit Testing iOS"
	@echo "######################################################################"
	rm -rf build/reports/iosUnitResults.xcresult
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme "UnitTests" -destination $(IOS_DESTINATION) -derivedDataPath build/out -resultBundlePath build/reports/iosUnitResults.xcresult -enableCodeCoverage YES ADB_SKIP_LINT=YES

functional-test-ios:
	@echo "######################################################################"
	@echo "### Functional Testing iOS"
	@echo "######################################################################"
	rm -rf build/reports/iosFunctionalResults.xcresult
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme "FunctionalTests" -destination $(IOS_DESTINATION) -derivedDataPath build/out -resultBundlePath build/reports/iosFunctionalResults.xcresult -enableCodeCoverage YES ADB_SKIP_LINT=YES

unit-test-tvos:
	@echo "######################################################################"
	@echo "### Unit Testing tvOS"
	@echo "######################################################################"
	rm -rf build/reports/tvosUnitResults.xcresult
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme "UnitTests" -destination $(TVOS_DESTINATION) -derivedDataPath build/out -resultBundlePath build/reports/tvosUnitResults.xcresult -enableCodeCoverage YES ADB_SKIP_LINT=YES

functional-test-tvos:
	@echo "######################################################################"
	@echo "### Functional Testing tvOS"
	@echo "######################################################################"
	rm -rf build/reports/tvosFunctionalResults.xcresult
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme "FunctionalTests" -destination $(TVOS_DESTINATION) -derivedDataPath build/out -resultBundlePath build/reports/tvosFunctionalResults.xcresult -enableCodeCoverage YES ADB_SKIP_LINT=YES

install-githook:
	git config core.hooksPath .githooks

lint-autocorrect:
	./Pods/SwiftLint/swiftlint --fix

lint:
	./Pods/SwiftLint/swiftlint lint Sources TestApps/

test-SPM-integration:
	sh ./Script/test-SPM.sh

test-podspec:
	sh ./Script/test-podspec.sh
