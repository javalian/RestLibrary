
#import <Foundation/Foundation.h>
#import "RestRequest.h"

@interface ObjectFactory : NSObject

+ (NSMutableArray *)createObjects:(NSString *)className array:(NSMutableArray *)array;
+ (id<RestObjectDelegate>)createObject:(NSString *)className dictionary:(NSDictionary *)dictionary;

@end
