//
//  UrlConnection.h
//  MagicPrefs
//
//  Created by Vlad Alexa on 4/25/10.
//  Copyright 2010 NextDesign. All rights reserved.
//


@protocol UrlConnectionDelegate;

@interface UrlConnection : NSObject {
	id <UrlConnectionDelegate> delegate;
	NSString *url;
	NSMutableData *receivedData;
	NSURLConnection *theConnection;		
	NSString *name;
}

@property (nonatomic, retain) NSString *url;
@property (nonatomic, assign) id<UrlConnectionDelegate> delegate;
@property (nonatomic, retain) NSMutableData *receivedData;
@property (nonatomic, retain) NSURLConnection *theConnection;
@property (nonatomic, assign) NSString *name;

- (id) initWithURL:(NSString*)theURL andHeader:(NSArray*)header delegate:(id<UrlConnectionDelegate>)theDelegate;
- (void)debugCookies:(NSURLResponse *)response;

@end


@protocol UrlConnectionDelegate<NSObject>

@required

@property (nonatomic, assign) NSProgressIndicator *spinner;

- (void) connectionDidFinish:(UrlConnection *)theConnection;

@optional
- (void) connectionDidFail:(UrlConnection *)theConnection;

@end

	
	
