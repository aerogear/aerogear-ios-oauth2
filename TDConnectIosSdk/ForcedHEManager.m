#import "ForcedHEManager.h"

#import <arpa/inet.h>
#import <ifaddrs.h>
#import <net/if.h>
#import <netinet/in.h>
#import <ifaddrs.h>
#import <netdb.h>

#include "libs/curl/include/curl/curl.h"

int MAX_REDIRECTS_TO_FOLLOW_FOR_HE = 5;

@implementation ForcedHEManager

static NSSet *_urlsForHE = nil;

+ (void) initForcedHE:(NSString *)wellKnownConfigurationEndpoint {
    curl_global_init(CURL_GLOBAL_DEFAULT);

    [self fetchWellknown:wellKnownConfigurationEndpoint];
}

+ (void) fetchWellknown:(NSString *)wellKnownConfigurationEndpoint {
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:wellKnownConfigurationEndpoint]];

    __block NSDictionary *json;
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               json = [NSJSONSerialization JSONObjectWithData:data
                                                                      options:0
                                                                        error:nil];
                               @synchronized(self) {
                                   _urlsForHE = json[@"network_authentication_target_urls"];
                               }
                           }];
}

+ (bool) isInterfaceEnabled:(NSString *)iface {
    struct ifaddrs *interfaces = nil;
    struct ifaddrs *current_interface = nil;
    NSInteger success = getifaddrs(&interfaces);
    if (success != 0) {
        return false;
    }
    current_interface = interfaces;
    while(current_interface != nil) {
        if(current_interface->ifa_addr->sa_family == AF_INET) {
            NSString* ifaName = [NSString stringWithUTF8String:current_interface->ifa_name];
            if ([ifaName isEqualToString:iface]) {
                return true;
            }
        }
        current_interface = current_interface->ifa_next;
    }

    return false;
}

+ (bool) isWifiEnabled {
    return [self isInterfaceEnabled:@"en0"];
}

+ (bool) isCellularEnabled {
    return [self isInterfaceEnabled:@"pdp_ip0"];
}


+ (bool) shouldFetchThroughCellular:(NSString *)url {
    @synchronized(self) {
        for (NSString *urlForHE in _urlsForHE) {
            if ([url containsString:urlForHE]) {
                return true;
            }
        }
        return false;
    }
}

static curl_socket_t opensocket(void *clientp,
                                curlsocktype purpose,
                                struct curl_sockaddr *address)
{
    curl_socket_t sockfd;
    sockfd = *(curl_socket_t *)clientp;
    /* the actual externally set socket is passed in via the OPENSOCKETDATA
     option */
    return sockfd;
}

static int sockopt_callback(void *clientp, curl_socket_t curlfd,
                            curlsocktype purpose)
{
    /* This return code was added in libcurl 7.21.5 */
    return CURL_SOCKOPT_OK;
}

struct MemoryStruct {
    char *memory;
    size_t size;
};

static size_t WriteMemoryCallback(void *contents, size_t size, size_t nmemb, void *userp) {
    size_t realsize = size * nmemb;
    struct MemoryStruct *mem = (struct MemoryStruct *)userp;

    mem->memory = realloc(mem->memory, mem->size + realsize + 1);
    if (mem->memory == NULL) {
        /* out of memory! */
        exit(EXIT_FAILURE);
    }

    memcpy(&(mem->memory[mem->size]), contents, realsize);
    mem->size += realsize;
    mem->memory[mem->size] = 0;

    return realsize;
}

+ (NSDictionary*) openUrlThroughCellular:(NSString *)url {
    bool useCellular = true;
    CURL *curl;
    NSString *newUrl = url;
    NSDictionary *resDict = @{};
    int attempts = 0;

    do {
        curl = curl_easy_init();
        if (!curl) {
            return @{};
        }

        curl_easy_setopt(curl, CURLOPT_OPENSOCKETFUNCTION, opensocket);
        curl_easy_setopt(curl, CURLOPT_SOCKOPTFUNCTION, sockopt_callback);
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 0L);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteMemoryCallback);

        //socket
        int socketfd = socket(AF_INET, SOCK_STREAM, 0);
        int interfaceIndex;
        if (useCellular) {
            interfaceIndex = if_nametoindex("pdp_ip0");
        } else {
            interfaceIndex = if_nametoindex("en0");
        }
        setsockopt(socketfd, IPPROTO_IP, IP_BOUND_IF, &interfaceIndex, sizeof(interfaceIndex));
        curl_easy_setopt(curl, CURLOPT_OPENSOCKETDATA, &socketfd);


        // memory
        struct MemoryStruct chunk;
        chunk.memory = malloc(1);
        chunk.size = 0;
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&chunk);

        // request
        curl_easy_setopt(curl, CURLOPT_URL, [newUrl UTF8String]);
        CURLcode res = curl_easy_perform(curl);
        attempts += 1;

        // free memory
        NSData *data = [NSData dataWithBytes:chunk.memory length:chunk.size];
        if(chunk.memory) {
            free(chunk.memory);
            chunk.memory = NULL;
        }

        if (res != CURLE_OK) {
            NSLog(@"curl_easy_perform() failed: %s\n", curl_easy_strerror(res));
            break;
        }

        long responseCode;
        curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &responseCode);

        if (responseCode != 303 && responseCode != 302 && responseCode != 301) {
            char *pszContentType;
            curl_easy_getinfo(curl, CURLINFO_CONTENT_TYPE, &pszContentType);
            resDict =  @{@"responseCode" : [NSNumber numberWithLong:responseCode], @"contentType" : [NSString stringWithUTF8String:pszContentType], @"data": data};
            break;
        }

        if (attempts > MAX_REDIRECTS_TO_FOLLOW_FOR_HE) {
            break;
        }

        char *location;
        curl_easy_getinfo(curl, CURLINFO_REDIRECT_URL, &location);
        newUrl = [NSString stringWithUTF8String:location];
        if (res != CURLE_OK || [newUrl length] == 0) {
            break;
        }
        useCellular = [self shouldFetchThroughCellular:newUrl];

        curl_easy_cleanup(curl);
    } while (1);

    curl_easy_cleanup(curl);
    return resDict;
}

@end
