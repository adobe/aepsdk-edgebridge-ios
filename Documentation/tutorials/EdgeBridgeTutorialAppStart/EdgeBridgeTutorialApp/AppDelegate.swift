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

import AEPAssurance
import AEPCore
import AEPEdge
import AEPEdgeConsent
import AEPEdgeIdentity
import AEPLifecycle

/* EdgeBridge Tutorial - code section (1/2)
import AEPEdgeBridge
// EdgeBridge Tutorial - code section (1/2) */

// EdgeBridge Tutorial - remove section (1/2)
import AEPAnalytics
// EdgeBridge Tutorial - remove section (1/2)

// EdgeBridge Tutorial - remove section depending on use of Solution extensions (1/2)
import AEPIdentity
// EdgeBridge Tutorial - remove section depending on use of Solution extensions (1/2)

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
/* EdgeBridge Tutorial - code section (2/2)
            EdgeBridge.self,
// EdgeBridge Tutorial - code section (2/2) */

// EdgeBridge Tutorial - remove section (2/2)
            Analytics.self,
// EdgeBridge Tutorial - remove section (2/2)

// EdgeBridge Tutorial - remove section depending on use of Solution extensions (2/2)
            AEPIdentity.Identity.self,
// EdgeBridge Tutorial - remove section depending on use of Solution extensions (2/2)
            Assurance.self,
            Consent.self,
            Edge.self,
            AEPEdgeIdentity.Identity.self,
            Lifecycle.self
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
        Assurance.startSession(url: url)
        return true
    }
}
