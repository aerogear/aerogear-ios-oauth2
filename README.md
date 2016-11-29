# aerogear-ios-oauth2 [![Build Status](https://travis-ci.org/aerogear/aerogear-ios-oauth2.png)](https://travis-ci.org/aerogear/aerogear-ios-oauth2)

[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/AeroGearOAuth2.svg)](https://img.shields.io/cocoapods/v/AeroGearOAuth2.svg)
[![Platform](https://img.shields.io/cocoapods/p/AeroGearOAuth2.svg?style=flat)](http://cocoadocs.org/docsets/AeroGearOAuth2)

> This module currently build with Xcode 8 and supports iOS8, iOS9, iOS10.

OAuth2 Client based on [aerogear-ios-http](https://github.com/aerogear/aerogear-ios-http). 
Taking care of: 

* account manager for multiple OAuth2 accounts,
* request access and refresh token,
* grant access through secure external browser and URI schema to re-enter app,
* (implicit or explicit) refresh tokens, 
* revoke tokens,
* permanent secure storage,
* adaptable to OAuth2 specific providers. Existing extensions: Google, Facebook, [Keycloak 1.9.3.Final](http://keycloak.jboss.org/) etc...
* openID Connect login

100% Swift 3.0.

|                 | Project Info  |
| --------------- | ------------- |
| License:        | Apache License, Version 2.0  |
| Build:          | CocoaPods  |
| Documentation:  | https://aerogear.org/docs/guides/aerogear-ios-2.X/ |
| Issue tracker:  | https://issues.jboss.org/browse/AGIOS  |
| Mailing lists:  | [aerogear-users](http://aerogear-users.1116366.n5.nabble.com/) ([subscribe](https://lists.jboss.org/mailman/listinfo/aerogear-users))  |
|                 | [aerogear-dev](http://aerogear-dev.1069024.n5.nabble.com/) ([subscribe](https://lists.jboss.org/mailman/listinfo/aerogear-dev))  |

## Example Usage

#### OAuth2 grant for GET with a predefined config like Facebook
```swift
let http = Http() 						// [1]
let facebookConfig = FacebookConfig(	// [2]
    clientId: "YYY",
    clientSecret: "XXX",
    scopes:["photo_upload, publish_actions"])
let oauth2Module = AccountManager.addFacebookAccount(config: facebookConfig)  // [3]
http.authzModule = oauth2Module			// [4]
http.request(method: .get, path: "/get", completionHandler: {(response, error) in	// [5]
	// handle response
})
```
Create an instance of Http [1] from [aerogear-ios-http](https://github.com/aerogear/aerogear-ios-http) a thin layer on top of NSURLSession.

Fill-in the OAuth2 configuration in [2], here we use a predefined Config with all Facebook endpoint filled-in for us.

Create an OAuth2Module from AccountManager's factory method in [3].

Inject OAuth2Module into http object in [4] and uses the http object to GET/POST etc...

See full description in [aerogear.org](https://aerogear.org/docs/guides/aerogear-ios-2.X/Authorization/)

#### OpenID Connect with Keycloak
```swift
let http = Http()
let keycloakConfig = KeycloakConfig(
    clientId: "sharedshoot-third-party",
    host: "http://localhost:8080",
    realm: "shoot-realm",
    isOpenIDConnect: true)
let oauth2Module = AccountManager.addKeycloakAccount(config: keycloakConfig)
http.authzModule = oauth2Module
oauth2Module.login {(accessToken: AnyObject?, claims: OpenIdClaim?, error: NSError?) in // [1]
    // Do your own stuff here
}

```
Similar approach for configuration, here we want to login as Keycloak user, using ```login``` method we get some user information back in OpenIdClaim object.

> **NOTE:**  The latest version of the library works with Keycloak 1.1.0.Final. Previous version of Keycloak 1.0.x will work except for the transparent refresh of tokens (ie: after access token expires you will have to go through grant process).

### Build, test and play with aerogear-ios-oauth2

1. Clone this project

2. Get the dependencies

The project uses [CocoaPods](http://cocoapods.org) for handling its dependencies. As a pre-requisite, install CocoaPods and then install the pod. On the root directory of the project run:
```bash
pod install
```
3. open AeroGearOAuth2.xcworkspace

## Adding the library to your project 
To add the library in your project, you can either use [CocoaPods](http://cocoapods.org) or manual install in your project. See the respective sections below for instructions:

### Using [CocoaPods](http://cocoapods.org)
In your ```Podfile``` add:

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

## Documentation

For more details about the current release, please consult [our documentation](https://aerogear.org/docs/guides/aerogear-ios-2.X/).

## Development

If you would like to help develop AeroGear you can join our [developer's mailing list](https://lists.jboss.org/mailman/listinfo/aerogear-dev), join #aerogear on Freenode, or shout at us on Twitter @aerogears.

Also takes some time and skim the [contributor guide](http://aerogear.org/docs/guides/Contributing/)

## Questions?

Join our [user mailing list](https://lists.jboss.org/mailman/listinfo/aerogear-users) for any questions or help! We really hope you enjoy app development with AeroGear!

## Found a bug?

If you found a bug please create a ticket for us on [Jira](https://issues.jboss.org/browse/AGIOS) with some steps to reproduce it.
