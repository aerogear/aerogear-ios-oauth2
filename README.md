# connect-ios-sdk

OAuth2 Client based on [aerogear-ios-http](https://github.com/aerogear/aerogear-ios-http). 

## Features

* account manager for multiple OAuth2 accounts,
* request access and refresh token,
* grant access through secure browser and URI schema to re-enter app,
* (implicit or explicit) refresh tokens, 
* revoke tokens,
* permanent secure storage,

Swift 4.0

Please use the GitHub _Watch_ feature to get notified on new releases of the SDK.

## Hello World app using the SDK

The easiest way to get started is looking at the _Hello World_ example app.

https://github.com/telenordigital/TelenorConnectIosHelloWorld.

Implements the API's for http://docs.telenordigital.com/apis/connect/id/authentication.html.

Documentation on the project forked from can be found at https://aerogear.org/docs/guides/aerogear-ios-2.X/

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
pod 'TDConnectIosSdk'
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

## Advanced Usage

### Confidential Client

To set the SDK to **Confidential Client** mode set the optional init parameter in the `Config` object named `isPublicClient` to `false`. Otherwise it will default to a **public client**.
A confidential client will not exchange the authorization code but simply return this to the client through the callback. The app code can then send this to the server-side component of the client.

See [http://docs.telenordigital.com/connect/id/native_apps.html](http://docs.telenordigital.com/connect/id/native_apps.html) for more information.

```swift
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    let config = TelenorConnectConfig(clientId: "telenordigital-connectexample-ios",
                                      redirectUrl: "telenordigital-connectexample-ios://oauth2callback",
                                      useStaging: true,
                                      scopes: ["profile", "openid", "email"],
                                      accountId: "telenor-connect-ios-hello-world",
                                      isPublicClient: false) // this variable needs to be present
    
    let oauth2Module = AccountManager.getAccountBy(config: config)
        ?? AccountManager.addAccountWith(config: self.config, moduleClass: TelenorConnectOAuth2Module.self)
    
    oauth2Module.requestAuthorizationCode { (authorizationCode: AnyObject?, error: NSError?) in
        if (error != nil) {
            // handle error
            return
        }
        
        // use authorizationCode
    }
}
```
