# aerogear-ios-http  [![Build Status](https://travis-ci.org/aerogear/aerogear-ios-http.png)](https://travis-ci.org/aerogear/aerogear-ios-http)

> This module currently build with Xcode 8 and supports iOS8, iOS9, iOS10.

Thin layer to take care of your http requests working with NSURLSession. 
Taking care of: 

* Json serializer
* Multipart upload 
* HTTP Basic/Digest authentication support
* Pluggable object serialization
* background processing support

100% Swift 3.0.

|                 | Project Info  |
| --------------- | ------------- |
| License:        | Apache License, Version 2.0  |
| Build:          | CocoaPods  |
| Documentation:  | http://aerogear.org/ios/  |
| Issue tracker:  | https://issues.jboss.org/browse/AGIOS  |
| Mailing lists:  | [aerogear-users](http://aerogear-users.1116366.n5.nabble.com/) ([subscribe](https://lists.jboss.org/mailman/listinfo/aerogear-users))  |
|                 | [aerogear-dev](http://aerogear-dev.1069024.n5.nabble.com/) ([subscribe](https://lists.jboss.org/mailman/listinfo/aerogear-dev))  |

## Example Usage

To perform an HTTP request use the convenient methods found in the Http object. Here is an example usage:

```swift
let http = Http(baseURL: "http://server.com")

http.request(.get, path: "/get", completionHandler: {(response, error) in
     // handle response
})

http.request(.post, path: "/post",  parameters: ["key": "value"], 
                    completionHandler: {(response, error) in
     // handle response
})
...
```

### Authentication

The library also leverages the build-in foundation support for http/digest authentication and exposes a convenient interface by allowing the credential object to be passed on the request. Here is an example:

> **NOTE:**  It is advised that HTTPS should be used when performing authentication of this type

```swift
let credential = URLCredential(user: "john", 
                                 password: "pass", 
                                 persistence: .none)

http.request(.get, path: "/protected/endpoint", credential: credential, 
                                completionHandler: {(response, error) in
   // handle response
})
```

You can also set a credential per protection space, so it's automatically picked up once http challenge is requested by the server, thus omitting the need to pass the credential on each request. In this case, you must initialize the ```Http``` object with a custom session configuration object, that has its credentials storage initialized with your credentials:

```swift
// create a protection space
let protectionSpace = URLProtectionSpace(host: "httpbin.org",
                        port: 443,
                        protocol: NSURLProtectionSpaceHTTP,
                        realm: "me@kennethreitz.com",
                        authenticationMethod: NSURLAuthenticationMethodHTTPDigest)
        
// setup credential
// notice that we use '.ForSession' type otherwise credential storage will discard and
// won't save it when doing 'credentialStorage.setDefaultCredential' later on
let credential = URLCredential(user: "user",
                        password: "password",
                        persistence: .forSession)
// assign it to credential storage
let credentialStorage = URLCredentialStorage.shared
credentialStorage.setDefaultCredential(credential, for: protectionSpace);
        
// set up default configuration and assign credential storage
let configuration = URLSessionConfiguration.default
configuration.urlCredentialStorage = credentialStorage
        
// assign custom configuration to Http
let http = Http(baseURL: "http://httpbin.org", sessionConfig: configuration)
http.request(.get, path: "/protected/endpoint", completionHandler: {(response, error) in
    // handle response
})
```

### OAuth2 Protocol Support

To support the OAuth2 protocol, we have created a separate library [aerogear-ios-oauth2](https://github.com/aerogear/aerogear-ios-oauth2) that can be easily integrated, in order to provide  out-of-the-box support for communicated with OAuth2 protected endpoints. Please have a look at the "Http and OAuth2Module" section on our [documentation page](http://aerogear.org/docs/guides/aerogear-ios-2.X/Authorization/) for more information. 

Do you want to try it on your end? Follow next section steps.

### Build, test and play with aerogear-ios-http

1. Clone this project

2. Get the dependencies

The project uses [OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs) framework for stubbing its http network requests and utilizes [CocoaPods](http://cocoapods.org) release for handling its dependencies. As a pre-requisite, install [CocoaPods](https://guides.cocoapods.org/using/getting-started.html) and then install the pod. On the root directory of the project run:
```bash
pod install
```
3. open AeroGearHttp.xcworkspace

## Adding the library to your project 
To add the library in your project, you can either use [CocoaPods](http://cocoapods.org) or manual install in your project. See the respective sections below for instructions:

### Using [CocoaPods](http://cocoapods.org)
We recommend you use[CocoaPods-1.1.0.beta.1 release](https://github.com/CocoaPods/CocoaPods/releases/tag/1.1.0.beta.1). In your ```Podfile``` add:

```
pod 'AeroGearHttp'
```

and then:

```bash
pod install
```
to install your dependencies

## Documentation

For more details about the current release, please consult [our documentation](http://aerogear.org/ios/).

## Development

If you would like to help develop AeroGear you can join our [developer's mailing list](https://lists.jboss.org/mailman/listinfo/aerogear-dev), join #aerogear on Freenode, or shout at us on Twitter @aerogears.

Also takes some time and skim the [contributor guide](http://aerogear.org/docs/guides/Contributing/)

## Questions?

Join our [user mailing list](https://lists.jboss.org/mailman/listinfo/aerogear-users) for any questions or help! We really hope you enjoy app development with AeroGear!

## Found a bug?

If you found a bug please create a ticket for us on [Jira](https://issues.jboss.org/browse/AGIOS) with some steps to reproduce it.
