#import <Foundation/Foundation.h>

@interface ForcedHEManager : NSObject
@property (class) NSSet *_urlsForHE;
+ (bool) isWifiEnabled;
+ (bool) isCellularEnabled;
+ (bool) shouldFetchThroughCellular:(NSString *)url;
+ (NSDictionary *) openUrlThroughCellular:(NSString *)url;
+ (void) initForcedHE:(NSString *)wellKnownConfigurationEndpoint;
@end
