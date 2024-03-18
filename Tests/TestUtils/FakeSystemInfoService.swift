//
// Copyright 2024 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import AEPServices

class FakeSystemInfoService: SystemInfoService {

    var applicationName: String?
    var applicationBuildNumber: String?
    var applicationVersionNumber: String?

    var deviceName: String = "device name"
    var mobileCarrierName: String = "carrier"
    var runMode: String = "app"
    var operatingSystemName: String = "os name"
    var operatingSystemVersion: String = "os version"
    var cannonicalPlatformName: String = "platform"

    var displayWidth: Int = 10
    var displayHeight: Int = 10

    var defaultUserAgent: String = ""
    var activeLocalName: String = "en-US"
    var systemLocalName: String = "en-US"

    var currentOrientation: AEPServices.DeviceOrientation = .PORTRAIT
    var deviceType: AEPServices.DeviceType = .PHONE
    var applicationBundleId: String?
    var applicationVersion: String?
    var deviceModelNumber: String = ""

    func getProperty(for key: String) -> String? {
        nil
    }

    func getAsset(fileName: String, fileType: String) -> String? {
        nil
    }

    func getAsset(fileName: String, fileType: String) -> [UInt8]? {
        nil
    }

    func getDeviceName() -> String {
        deviceName
    }

    func getMobileCarrierName() -> String? {
        mobileCarrierName
    }

    func getRunMode() -> String {
        runMode
    }

    func getApplicationName() -> String? {
        applicationName
    }

    func getApplicationBuildNumber() -> String? {
        applicationBuildNumber
    }

    func getApplicationVersionNumber() -> String? {
        applicationVersionNumber
    }

    func getOperatingSystemName() -> String {
        operatingSystemName
    }

    func getOperatingSystemVersion() -> String {
        operatingSystemVersion
    }

    func getCanonicalPlatformName() -> String {
        cannonicalPlatformName
    }

    func getDisplayInformation() -> (width: Int, height: Int) {
        (width: displayWidth, height: displayHeight)
    }

    func getDefaultUserAgent() -> String {
        defaultUserAgent
    }

    func getActiveLocaleName() -> String {
        activeLocalName
    }

    func getSystemLocaleName() -> String {
        systemLocalName
    }

    func getDeviceType() -> AEPServices.DeviceType {
        deviceType
    }

    func getApplicationBundleId() -> String? {
        applicationBundleId
    }

    func getApplicationVersion() -> String? {
        applicationVersion
    }

    func getCurrentOrientation() -> AEPServices.DeviceOrientation {
        currentOrientation
    }

    func getDeviceModelNumber() -> String {
        deviceModelNumber
    }

}
