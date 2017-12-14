
#import <UIKit/UIKit.h>
#import "RestRequest.h"
#import "ObjectFactory.h"
#import "Reachability.h"

@implementation RestRequest

@synthesize delegate;

+ (NSString *)defaultSecurityToken
{
    return @"65B07AFF-F5F3-4404-A0E6-E2071C424F6D-2BB4A233-FF5D-4495-9DC0-00E5197A7C60-B28C296C-1EAA-4E63-8CD0-6329C5990CF9-E861FBE6-F737-4C28-8F12-1B61FBEF5ACB";
}

- (id)initWithDelegate:(id<RestRequestDelegate>)restDelegate
{
    self = [super init];
    
    if (self)
    {
        //set delegate
        [self setDelegate:restDelegate];
        
        //observe the kNetworkReachabilityChangedNotification - when that notification is posted, the method "reachabilityChanged" will be called.
        [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(reachabilityChanged:) name:kReachabilityChangedNotification object: nil];
        
        //set the host name here to assign the server to be monitored
        hostReach = [Reachability reachabilityWithHostName:[restDelegate getHost]];
        
        //start it
        [hostReach startNotifier];
    }
    
    return self;
}

- (void)reachabilityChanged:(NSNotification *)notification
{
    //get reachability object
	Reachability* reach = [notification object];

    //check if no connectivity
    if([reach currentReachabilityStatus] == NotReachable)
    {
        //do not have network connection - notify delegate
        [[self delegate] networkStatusChanged:NO];
    }
    else
    {
        //do have network connection - notify delegate
        [[self delegate] networkStatusChanged:YES];
    }
}

- (id)performGet:(NSString *)requestUrl error:(NSError **)error
{
	return [self perform:requestUrl method:@"GET" jsonData:nil className:nil error:error];
}

- (id)performGetWithClassName:(NSString *)requestUrl className:(NSString *)className error:(NSError **)error
{
    return [self perform:requestUrl method:@"GET" jsonData:nil className:className error:error];
}

- (id)performPost:(NSString *)requestUrl jsonData:(NSDictionary *)jsonData error:(NSError **)error
{
	return [self perform:requestUrl method:@"POST" jsonData:jsonData className:nil error:error];
}

- (id)perform:(NSString *)requestUrl method:(NSString *)method jsonData:(NSDictionary *)jsonData className:(NSString *)className error:(NSError **)error
{
    //first of all check if host is reachable right now
    if([hostReach currentReachabilityStatus] == NotReachable)
    {
        //check if user passed error pointer or nil
        if(error)
        {
            //set error
            *error = [NSError errorWithDomain:@"org.cadencehealth.thm" code:200 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"The application cannot contact the server.  Make sure you have a WIFI or 3G connection active.", NSLocalizedDescriptionKey, nil]];
        }
        
        //send back nothing
        return nil;
    }
    
    //get protocol from delegate
    NSString *protocol = [[self delegate] getProtocol];
    
    //get security token from delegate
    NSString *host = [[self delegate] getHost];
    
    //get security token from delegate
    NSString *securityToken = [[self delegate] getSecurityToken];
    
    //get security token query key from delegate
    NSString *securityTokenQueryKey = [[self delegate] getSecurityTokenQueryKey];
    
    //create url
    NSURL *url;
    
    //if still no client token (none passed and don't have authenticted transporter) then dont send in url
    if(securityToken == nil)
    {
        //without token
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@%@", protocol, host, requestUrl]];
        
    }
    else
    {
        //include token
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@%@?%@=%@", protocol, host, requestUrl, securityTokenQueryKey, securityToken]];
    }
	
	//create request
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	
	//set up header info
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
	[request setHTTPMethod:method];
	
	//see if we have data
	if(jsonData)
	{
		//check validity
		if([NSJSONSerialization isValidJSONObject:jsonData])
		{
			//create data
			NSData *data = [NSJSONSerialization dataWithJSONObject:jsonData options:0 error:nil];
			
			//create string
			NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			
			//set request data
			[request setValue:string forHTTPHeaderField:@"json"];
			[request setHTTPBody:data];
		}
	}
	
	//set up for any errors
	NSError *responseError = nil;
	
	//set up response
	NSURLResponse *response = [[NSURLResponse alloc] init];
	
	//make the request
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&responseError];
    
    //set up response
    id results = nil;
    
	//check for error
	if(responseError)
	{
        //set up details
        NSString *errorDetails;
        
        //check data for error response
        if (data)
        {
            //get response body that will hold error details
            errorDetails = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        else
        {
            //no data response to put in generic network error
            errorDetails = @"The application cannot contact the server.  Make sure you have a WIFI or 3G connection active.";
        }
        
        //set the passed error with details
        if(error)
        {
            *error = [NSError errorWithDomain:@"org.cadencehealth.thm" code:200 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:errorDetails, NSLocalizedDescriptionKey, nil]];
        }
        
        //send back nothing
        return nil;
	}
	else 
	{
        //set up error
        NSError *jsonError = nil;
        
		//try to create json item from data
        results = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
		
        //check for error
        if(jsonError)
        {
            //can't parse data - probably just a normal string - get and check it
            NSString *stringResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            //see if it's actually anything - sometimes server returns empty string
            if([stringResult length] > 0)
            {
                //actually have something - just send it back
                return stringResult;
            }
            else
            {
                //empty string - send back nil
                return nil;
            }
        }
        else
        {
            //check what we have - can be array (list), dictionary (single item), or string
            if ([results isKindOfClass:[NSArray class]])
            {
                //check class name
                if(className)
                {
                    //create list of objects
                    return [ObjectFactory createObjects:className array:(NSMutableArray *)results];
                }
                else
                {
                    //just return the array
                    return results;
                }
            }
            else if([results isKindOfClass:[NSDictionary class]])
            {
                //check class name
                if(className)
                {
                    //create single model object from dictionary
                    return [ObjectFactory createObject:className dictionary:(NSDictionary *)results];
                }
                else
                {
                    //just return the dictionary
                    return results;
                }
            }
            else
            {
                //just send back results - whatever it is
                return results;
            }
        }
	}
}

- (BOOL)isValidDomain:(NSString *)domain transporterCode:(NSString *)transporterCode
{
    //first of all check if host is reachable right now
    if([hostReach currentReachabilityStatus] == NotReachable)
    {
        //send back false
        return nil;
    }
    
    //set request URL
    NSString *requestUrl = [NSString stringWithFormat:@"/transporter/test/%@", transporterCode];
    
    //set request method
    NSString *method = @"GET";
    
    //get protocol from delegate
    NSString *protocol = [[self delegate] getProtocol];
    
    //get security token from delegate
    NSString *host = domain;
    
    //get security token from delegate
    NSString *securityToken = [[self delegate] getSecurityToken];
    
    //get security token query key from delegate
    NSString *securityTokenQueryKey = [[self delegate] getSecurityTokenQueryKey];
    
    //create url
    NSURL *url;
    
    //if still no client token (none passed and don't have authenticted transporter) then dont send in url
    if(securityToken == nil)
    {
        //without token
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@%@", protocol, host, requestUrl]];
        
    }
    else
    {
        //include token
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@%@?%@=%@", protocol, host, requestUrl, securityTokenQueryKey, securityToken]];
    }
	
	//create request
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	
	//set up header info
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
	[request setHTTPMethod:method];
	
	//set up for any errors
	NSError *responseError = nil;
	
	//set up response
	NSURLResponse *response = [[NSURLResponse alloc] init];
	
	//make the request
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&responseError];
    
    //set up response
    id results = nil;
    
	//check for error
	if(responseError)
	{
        //send back nothing
        return FALSE;
	}
	else
	{
        //set up error
        NSError *jsonError = nil;
        
		//try to create json item from data
        results = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
		
        //check for error
        if(jsonError)
        {
            //empty string - send back nil
            return FALSE;
        }
        else
        {
            return TRUE;
        }
	}
}

@end
