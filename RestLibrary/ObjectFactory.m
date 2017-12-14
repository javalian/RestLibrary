
#import "ObjectFactory.h"
#import "RestRequest.h"

@implementation ObjectFactory

+ (NSMutableArray *)createObjects:(NSString *)className array:(NSMutableArray *)array
{
    //create temp array to send back
    NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:[array count]];
    
    //loop passed array
    for (NSDictionary *dictionary in array)
    {
        //create object and add to temp array
        [tempArray addObject:[ObjectFactory createObject:className dictionary:dictionary]];
    }
    
    //send it back
    return tempArray;
}

+ (id<RestObjectDelegate>)createObject:(NSString *)className dictionary:(NSDictionary *)dictionary
{
    //create object
    id<RestObjectDelegate> object = [[NSClassFromString(className) alloc] initWithDictionary:dictionary];
    
    //send it back
    return object;
}
@end
