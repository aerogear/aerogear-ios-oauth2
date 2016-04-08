# connect-ios-sdk

> This module currently build with Xcode 7 and supports iOS8, iOS9.

OAuth2 Client based on [aerogear-ios-http](https://github.com/aerogear/aerogear-ios-http). 
Taking care of: 

* account manager for multiple OAuth2 accounts,
* request access and refresh token,
* grant access through secure external browser and URI schema to re-enter app,
* (implicit or explicit) refresh tokens, 
* revoke tokens,
* permanent secure storage,
* adaptable to OAuth2 specific providers. Existing extensions: Google, Facebook, [Keycloak 1.5.0.Final](http://keycloak.jboss.org/) etc...
* openID Connect login

100% Swift 2.0.

Documentation on forked project: https://aerogear.org/docs/guides/aerogear-ios-2.X/

## Hello World app using the SDK

https://github.com/telenordigital/TelenorConnectIosHelloWorld.

Implements the API's for http://docs.telenordigital.com/apis/connect/id/authentication.html.

### Build, test and play with connect-ios-sdk

1. Clone this project

2. Get the dependencies

The project uses [CocoaPods](http://cocoapods.org) for handling its dependencies. As a pre-requisite, install CocoaPods and then install the pod. On the root directory of the project run:
```bash
pod install
```
3. open TDConnectIosSdk.xcworkspace

## Adding the library to your project 
To add the library in your project, you can either use [CocoaPods](http://cocoapods.org) or manual install in your project. See the respective sections below for instructions:

### Using [CocoaPods](http://cocoapods.org)
In your ```Podfile``` add:

```
pod 'TDConnectIosSdk', :git => 'https://github.com/telenordigital/connect-ios-sdk'
```

and then:

```bash
pod install
```

to install your dependencies

### Manual Installation
Follow these steps to add the library in your Swift project:

1. Add TDConnectIosSdk as a [submodule](http://git-scm.com/docs/git-submodule) in your project. Open a terminal and navigate to your project directory. Then enter:
```bash
git submodule add https://github.com/telenordigital/connect-ios-sdk.git
```
2. Open the `connect-ios-sdk` folder, and drag the `TDConnectIosSdk.xcodeproj` into the file navigator in Xcode.
3. In Xcode select your application target  and under the "Targets" heading section, ensure that the 'iOS  Deployment Target'  matches the application target of TDConnectIosSdk.framework (Currently set to 8.0).
5. Select the  "Build Phases"  heading section,  expand the "Target Dependencies" group and add  `TDConnectIosSdk.framework`.
7. Click on the `+` button at the top left of the panel and select "New Copy Files Phase". Rename this new phase to "Copy Frameworks", set the "Destination" to "Frameworks", and add `TDConnectIosSdk.framework`.
