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

## Building & Running tests

The project uses [aerogear-ios-http](https://github.com/aerogear/aerogear-ios-http) framework for its http calls, and [aerogear-ios-httpstub](https://github.com/aerogear/aerogear-ios-httpstub) framework for stubbing its http network requests.  To handle these dependencies, it uses [Cocoapods](http://cocoapods.org). On the root directory of the project run:

```bash
bundle install
bundle exec pod install
```

You are now ready to run the tests.

## Adding the library to your project 
To add the library in your project, you can either use [Cocoapods](http://cocoapods.org) or simply drag the library in your project. See the respective sections below for instructions

### Using [Cocoapods](http://cocoapods.org)
At this time, Cocoapods support for Swift frameworks is supported in a preview [branch](https://github.com/CocoaPods/CocoaPods/tree/swift). Simply [include a Gemfile](http://swiftwala.com/cocoapods-is-ready-for-swift/) in your project pointing to that branch and in your ```Podfile``` add:

```
pod 'AeroGearOAuth2'
```

and then:
```bash
bundle install
bundle exec pod install
```

to install your dependencies.

> **NOTE:**  Currently, there is a Swift compiler bug that causes abnormal behavior when  building with optimization level set to ```-Fastest```  . Therefore, it is advised a ```-None``` optimization level is used, when importing the library. To do so, include the [following block](https://github.com/aerogear/aerogear-ios-cookbook/blob/podspec/Shoot/Podfile#L9-L24) in your ```Podfile```

### Drag the library in your project

Follow these steps to add the library in your Swift project.

1. [Clone repositories](#1-clone-repositories)
2. [Add `AeroGearOAuth2.xcodeproj` to your application target](#2-add-aerogearoauth2-xcodeproj-to-your-application-target)
3. [Add `AeroGearHttp.xcodeproj` to your application target](#2-add-aerogearhttp-xcodeproj-to-your-application-target)
4. Start writing your app!

#### 1. Clone repositories

```
git clone git@github.com:aerogear/aerogear-ios-http.git
git clone git@github.com:aerogear/aerogear-ios-oauth2.git
```

#### 2. Add `AeroGearOAuth2.xcodeproj` to your application target

Right-click on the group containing your application target and select `Add Files To YourApp`
Next, select `AeroGearOAuth2.xcodeproj`, which you downloaded in step 1.

#### 3. Add `AeroGearHttp.xcodeproj` to your application target

Right-click on the group containing your application target and select `Add Files To YourApp`
Next, select `AeroGearHttp.xcodeproj`, which you downloaded in step 1.

If you run into any problems, please [file an issue](http://issues.jboss.org/browse/AEROGEAR) and/or ask our [user mailing list](https://lists.jboss.org/mailman/listinfo/aerogear-users). You can also join our [dev mailing list](https://lists.jboss.org/mailman/listinfo/aerogear-dev).  
