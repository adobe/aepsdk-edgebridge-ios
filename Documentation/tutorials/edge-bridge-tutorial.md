# AEP Analytics & Edge Bridge
## Overview
This hands-on tutorial provides end-to-end instructions for Mobile SDK customers on how  Edge Bridge can help easily migrate from AEPAnalytics to AEP.

There are other beginning states the customer can be in like using ACP Analytics, v4 extension, etc. These usages can potentially be migrated to AEP and from there, this tutorial can be applied afterwards. However, this should be determined on a case-by-case basis, as for example in the v4 extension case, it may be more effective to simply implement AEP extensions itself without the need for Edge Bridge migration path.

Tutorial setup:

Initial test app that is based on prerequisites (implements Analytics)
Final test app after all the tutorial steps have been implemented (implements EdgeBridge)

Tutorial steps:

      0. Prerequisites (set up Analytics report suite, mobile property, Assurance). List out required permissions for this tutorial: Analytics, Schema creation, Data Collection (Launch tags), Datastream view and edit, Assurance.

## Data Collection config instructions
Create XDM schema   
Configure Datastream, enable Analytics - 2 paths:   
    - same rsid(s) as in Analytics extension (if using Analytics + EdgeBridge this will cause double counting).  
    - different rsid(s) if the customer wants to start new or run the migration in a comparison mode (Analytics + EdgeBridge side by side).  

Install Edge Network & Edge Identity in Launch - Edge Bridge does not have a card here  
Analytics should remain installed in Launch for production app versions.  
Publish the changes  

## Client-side implementation
### 1. Pods / SPM dependencies diff adds/removes  
On the client side, add the Edge Bridge extension to the dependency manager pods or Swift Package Manager

```

```

### 2. Imports and extension registration diff  
Run app   
TrackAction/TrackState implementation examples   

## Initial validation with Assurance
Set up the Assurance session  
Connect to the app   
Event transactions view - check for Edge Bridge events  

## Data prep mapping
Copy data blob from Assurance (hint on copy from logs)  
Add mapping in Data Prep UI  

## Validation with Assurance
Check mapping feedback in Event transactions view