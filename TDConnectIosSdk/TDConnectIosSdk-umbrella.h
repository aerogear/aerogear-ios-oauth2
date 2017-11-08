#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "ForcedHEManager.h"
#import "TDConnectIosSdk.h"
#import "curl.h"
#import "curlbuild.h"
#import "curlrules.h"
#import "curlver.h"
#import "easy.h"
#import "mprintf.h"
#import "multi.h"
#import "stdcheaders.h"
#import "system.h"
#import "typecheck-gcc.h"

FOUNDATION_EXPORT double TDConnectIosSdkVersionNumber;
FOUNDATION_EXPORT const unsigned char TDConnectIosSdkVersionString[];

