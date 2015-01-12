# aerogear-ios-oauth2 [![Build Status](https://travis-ci.org/aerogear/aerogear-ios-oauth2.png)](https://travis-ci.org/aerogear/aerogear-ios-oauth2)
OAuth2 Client based on [aerogear-ios-http](https://github.com/aerogear/aerogear-ios-http). 
Taking care of: 

* account manager for multiple OAuth2 accounts,
* request access and refresh token,
* grant access through secure external browser and URI schema to re-enter app,
* (implicit or explicit) refresh tokens, 
* revoke tokens,
* permanent secure storage,
* adaptable to OAuth2 specific providers. Existing extensions: Google, Facebook, Keycloak etc...
* openID Connect login

100% Swift.

## Example Usage

#### OAuth2 grant for GET with a predefined config like Facebook
```swift
var Http = Http() 						// [1]
let facebookConfig = FacebookConfig(	// [2]
    clientId: "YYY",
    clientSecret: "XXX",
    scopes:["photo_upload, publish_actions"])
var oauth2Module = AccountManager.addFacebookAccount(facebookConfig)  // [3]
http.authzModule = oauth2Module			// [4]
http.GET("/get", completionHandler: {(response, error) in	// [5]
	// handle response
})
```
Create an instance of Http [1] from [aerogear-ios-http](https://github.com/aerogear/aerogear-ios-http) a thin layer on top of NSURLSession.

Fill-in the OAuth2 configuration in [2], here we use a predefined Config with all Facebook endpoint filled-in for us.

Create an OAuth2Module from AccountManager's factory method in [3].

Inject OAuth2Module into http object in [4] and uses the http object to GET/POST etc...

See full description in [aerogear.org](https://aerogear.org/docs/guides/aerogear-ios-2.X/Authorization/)

#### OpenID Connect 
```swift
var Http = Http()
let keycloakConfig = KeycloakConfig(
    clientId: "sharedshoot-third-party",
    host: "http://localhost:8080",
    realm: "shoot-realm",
    isOpenIDConnect: true)
var oauth2Module = AccountManager.addKeycloakAccount(keycloakConfig)
http.authzModule = oauth2Module
oauth2Module.login {(accessToken: AnyObject?, claims: OpenIDClaim?, error: NSError?) in // [1]
    // Do your own stuff here
}

```
Similar approach for configuration, here we want to login as Keycloak user, using ```login``` method we get some user information back in OpenIDClaim object.

### Build, test and play with aerogear-ios-jsonsz

1. Clone this project

2. Get the dependencies

The project uses [cocoapods](http://cocoapods.org) 0.36.0 pre-release for handling its dependencies. As a pre-requisite, install [cocoapods pre-release](http://blog.cocoapods.org/Pod-Authors-Guide-to-CocoaPods-Frameworks/) and then install the pod. On the root directory of the project run:
```bash
pod install
```
3. open AeroGearOAuth2.xcworkspace

## Adding the library to your project 
To add the library in your project, you can either use [Cocoapods](http://cocoapods.org) or manual install in your project. See the respective sections below for instructions:

### Using [Cocoapods](http://cocoapods.org)
At this time, Cocoapods support for Swift frameworks is supported in a [pre-release](http://blog.cocoapods.org/Pod-Authors-Guide-to-CocoaPods-Frameworks/). In your ```Podfile``` add:

```
pod 'AeroGearOAuth2'
```

and then:

```bash
pod install
```

to install your dependencies

### Manual Installation
Follow these steps to add the library in your Swift project:

1. Add AeroGearOAuth2 as a [submodule](http://git-scm.com/docs/git-submodule) in your project. Open a terminal and navigate to your project directory. Then enter:
```bash
git submodule add https://github.com/aerogear/aerogear-ios-oauth2.git
```
2. Open the `aerogear-ios-oauth2` folder, and drag the `AeroGearOAuth2.xcodeproj` into the file navigator in Xcode.
3. In Xcode select your application target  and under the "Targets" heading section, ensure that the 'iOS  Deployment Target'  matches the application target of AeroGearOAuth2.framework (Currently set to 8.0).
5. Select the  "Build Phases"  heading section,  expand the "Target Dependencies" group and add  `AeroGearOAuth2.framework`.
7. Click on the `+` button at the top left of the panel and select "New Copy Files Phase". Rename this new phase to "Copy Frameworks", set the "Destination" to "Frameworks", and add `AeroGearOAuth2.framework`.


If you run into any problems, please [file an issue](http://issues.jboss.org/browse/AEROGEAR) and/or ask our [user mailing list](https://lists.jboss.org/mailman/listinfo/aerogear-users). You can also join our [dev mailing list](https://lists.jboss.org/mailman/listinfo/aerogear-dev).  
