//
//  VAUrlConnection.m
//  MagicPrefs
//
//  Created by Vlad Alexa on 4/25/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "VAUrlConnection.h"


@implementation VAUrlConnection

@synthesize delegate,url,receivedData,theConnection,name,statusCode;


- (id) initWithURL:(NSString*)theURL delegate:(id<VAUrlConnectionDelegate>)theDelegate
{
    self = [super init];
	if (self) {		
		self.delegate = theDelegate;
		self.url = [theURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

		NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:30];
		receivedData = [[NSMutableData alloc] initWithLength:0];	
		/* Create the connection with the request and start loading the data. The connection object is owned both by the creator and the loading system. */
		NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self startImmediately:YES];
		if (conn){
			//NSLog(@"UrlConnection for %@ started",url);			
		}else {
			NSLog(@"The NSURLConnection could not be made!...");
		}	
		self.theConnection = conn;
		[conn release];			
	}
	
	return self;
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    /* This method is called when the server has determined that it has
	 enough information to create the NSURLResponse. It can be called
	 multiple times, for example in the case of a redirect, so each time
	 we reset the data. */
    [self.receivedData setLength:0];
	self.statusCode = [((NSHTTPURLResponse *)response) statusCode];
	//NSLog(@"Got response %i for %@",statusCode,[response URL]);
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    /* Append the new data to the received data. */
    [self.receivedData appendData:data];		
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	NSLog(@"UrlConnection failed (%@)",[error localizedDescription]);		
    if ( self.delegate != nil && [self.delegate respondsToSelector:@selector(connectionDidFail:)] ) {			
		[self.delegate connectionDidFail:self];			
	}		
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    if ( self.delegate != nil && [self.delegate respondsToSelector:@selector(connectionDidFinish:)] ) {			
		[self.delegate connectionDidFinish:self];		
	}	
}

- (NSCachedURLResponse *) connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	/* this application does not use a NSURLCache disk or memory cache */
    return nil;
}

- (void)dealloc
{	
	NSLog(@"UrlConnection for %@ freed",url);
    [theConnection cancel];
    [theConnection release];	
	[receivedData release];
	[super dealloc];
}


@end
