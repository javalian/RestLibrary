
#import <Foundation/Foundation.h>
#import "Reachability.h"

@protocol RestRequestDelegate <NSObject>
@required
- (NSString *)getProtocol;
- (NSString *)getHost;
- (NSString *)getSecurityToken;
- (NSString *)getSecurityTokenQueryKey;
- (void)networkStatusChanged:(BOOL)networkIsAvailable;
@end

@protocol RestObjectDelegate <NSObject>
@required
- (id)initWithDictionary:(NSDictionary *)dictionary;
@end

@interface RestRequest : NSObject
{
    Reachability* hostReach;
}

@property (nonatomic, weak) id <RestRequestDelegate> delegate;

+ (NSString *)defaultSecurityToken;

- (id)initWithDelegate:(id<RestRequestDelegate>)restDelegate;

- (id)performGet:(NSString *)requestUrl error:(NSError **)error;
- (id)performGetWithClassName:(NSString *)requestUrl className:(NSString *)className error:(NSError **)error;
- (id)performPost:(NSString *)requestUrl jsonData:(NSDictionary *)jsonData error:(NSError **)error;
- (id)perform:(NSString *)requestUrl method:(NSString *)method jsonData:(NSDictionary *)jsonData className:(NSString *)className error:(NSError **)error;
- (BOOL)isValidDomain:(NSString *)domain transporterCode:(NSString *)transporterCode;


@end


