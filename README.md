# aerogear-ios-oauth2 

![Maintenance](https://img.shields.io/maintenance/yes/2017.svg)
[![circle-ci](https://img.shields.io/circleci/project/github/aerogear/aerogear-ios-oauth2/master.svg)](https://circleci.com/gh/aerogear/aerogear-ios-oauth2)
[![License](https://img.shields.io/badge/-Apache%202.0-blue.svg)](https://opensource.org/s/Apache-2.0)
[![GitHub release](https://img.shields.io/github/release/aerogear/aerogear-ios-oauth2.svg)](https://github.com/aerogear/aerogear-ios-oauth2/releases)
[![CocoaPods](https://img.shields.io/cocoapods/v/AeroGearOAuth2.svg)](https://cocoapods.org/pods/AeroGearOAuth2)
[![Platform](https://img.shields.io/cocoapods/p/AeroGearOAuth2.svg)](https://cocoapods.org/pods/AeroGearOAuth2)

OAuth2 Client based on [aerogear-ios-http](https://github.com/aerogear/aerogear-ios-http).

|                 | Project Info                                 |
| --------------- | -------------------------------------------- |
| License:        | Apache License, Version 2.0                  |
| Build:          | CocoaPods                                    |
| Languague:      | Swift 4                                      |
| Documentation:  | http://aerogear.org/ios/                     |
| Issue tracker:  | https://issues.jboss.org/browse/AGIOS        |
| Mailing lists:  | [aerogear-users](http://aerogear-users.1116366.n5.nabble.com/) ([subscribe](https://lists.jboss.org/mailman/listinfo/aerogear-users))                            |
|                 | [aerogear-dev](http://aerogear-dev.1069024.n5.nabble.com/) ([subscribe](https://lists.jboss.org/mailman/listinfo/aerogear-dev))                              |

## Table of Content

* [Features](#features)
* [Installation](#installation)
   * [CocoaPods](#cocoapods)
* [Usage](#usage)
   * [Grant for GET with a predefined config like Facebook](#grant-for-get-with-a-predefined-config-like-facebook)
   * [OpenID Connect with Keycloak](#openid-connect-with-keycloak)
* [Documentation](#documentation)
* [Demo apps](#demo-apps)
* [Development](#development)
* [Questions?](#questions)
* [Found a bug?](#found-a-bug)

## Features

* Account manager for multiple OAuth2 accounts,
* Request access and refresh token,
* Grant access through secure external browser and URI schema to re-enter app,
* (implicit or explicit) refresh tokens,
* Revoke tokens,
* Permanent secure storage,
* Adaptable to OAuth2 specific providers. Existing extensions: Google, Facebook, [Keycloak](http://keycloak.jboss.org/)
* OpenID Connect login

## Installation

### CocoaPods

In your `Podfile` add:

```bash
pod 'AeroGearOAuth2'
```

and then:

```bash
pod install
```

to install your dependencies

## Usage

### Grant for GET with a predefined config like Facebook

```swift
let facebookConfig = FacebookConfig(
    clientId: "YYY",
    clientSecret: "XXX",
    scopes:["photo_upload, publish_actions"]
)
let oauth2Module = AccountManager.addFacebookAccount(config: facebookConfig)

let http = Http()
http.authzModule = oauth2Module
http.request(method: .get, path: "/get", completionHandler: {(response, error) in
	// handle response
})
```

#### OpenID Connect with Keycloak

```swift
let keycloakConfig = KeycloakConfig(
    clientId: "sharedshoot-third-party",
    host: "http://localhost:8080",
    realm: "shoot-realm",
    isOpenIDConnect: true
)
let oauth2Module = AccountManager.addKeycloakAccount(config: keycloakConfig)

let http = Http()
http.authzModule = oauth2Module
oauth2Module.login {(accessToken: AnyObject?, claims: OpenIdClaim?, error: NSError?) in // [1]
    // Do your own stuff here
}

```

## Documentation

For more details about that please consult [our documentation](http://aerogear.org/ios/).

## Demo apps

Take a look in our demo apps:

* [Shoot and Share](https://github.com/aerogear/aerogear-ios-cookbook/blob/master/SharedShoot)
* [Shoot](https://github.com/aerogear/aerogear-ios-cookbook/blob/master/Shoot)

## Development

If you would like to help develop AeroGear you can join our [developer's mailing list](https://lists.jboss.org/mailman/listinfo/aerogear-dev), join #aerogear on Freenode, or shout at us on Twitter @aerogears.

Also takes some time and skim the [contributor guide](http://aerogear.org/docs/guides/Contributing/)

## Questions?

Join our [user mailing list](https://lists.jboss.org/mailman/listinfo/aerogear-users) for any questions or help! We really hope you enjoy app development with AeroGear!

## Found a bug?

If you found a bug please create a ticket for us on [Jira](https://issues.jboss.org/browse/AGIOS) with some steps to reproduce it.
