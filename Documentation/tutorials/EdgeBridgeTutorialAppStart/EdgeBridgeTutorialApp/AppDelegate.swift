//
// Copyright 2022 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

/// Imports the EdgeBridge extension and other AEP extensions that enable its functionality and power other features.
/// This makes it available to use in the code below.
//* EdgeBridge Tutorial - code section 1/3
import AEPAssurance
import AEPEdge
import AEPEdgeConsent
import AEPEdgeBridge
import AEPEdgeIdentity
import AEPLifecycle
// EdgeBridge Tutorial - code section 1/3 */
import AEPAnalytics
import AEPCore
import Compression
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // TODO: Set up the preferred Environment File ID from your mobile property configured in Data Collection UI
    private let ENVIRONMENT_FILE_ID = ""

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let appState = application.applicationState
        MobileCore.setLogLevel(.trace)
        MobileCore.configureWith(appId: ENVIRONMENT_FILE_ID)
        MobileCore.registerExtensions([
            Analytics.self,
/// Registers the newly added extensions with Core (which contains all of the baseline capabilities required to run Adobe extensions),
/// getting them ready to run in the app.
//* EdgeBridge Tutorial - code section 2/3
            EdgeBridge.self,
            Assurance.self,
            Consent.self,
            Edge.self,
            Identity.self,
            Lifecycle.self
// EdgeBridge Tutorial - code section 2/3 */
        ], {
            if appState != .background {
                // Only start lifecycle if the application is not in the background
                MobileCore.lifecycleStart(additionalContextData: nil)
            }
        })
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    // To handle deeplink on iOS versions 12 and below
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
/// Enables deep linking to connect to Assurance; this is for iOS versions 12 and below.
//* EdgeBridge Tutorial - code section 3/3
        Assurance.startSession(url: url)
// EdgeBridge Tutorial - code section 3/3 */
        return true
    }
}
