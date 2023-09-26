//
//  VAUrlConnection.h
//  MagicPrefs
//
//  Created by Vlad Alexa on 4/25/10.
//  Copyright 2010 NextDesign. All rights reserved.
//


@protocol VAUrlConnectionDelegate;

@interface VAUrlConnection : NSObject {
	id <VAUrlConnectionDelegate> delegate;
	NSString *url;
	NSMutableData *receivedData;
	NSURLConnection *theConnection;		
	NSString *name;
	int statusCode;
}

@property (nonatomic, retain) NSString *url;
@property (nonatomic, assign) id<VAUrlConnectionDelegate> delegate;
@property (nonatomic, retain) NSMutableData *receivedData;
@property (nonatomic, retain) NSURLConnection *theConnection;
@property (nonatomic, assign) NSString *name;
@property (nonatomic, assign) int statusCode;

- (id) initWithURL:(NSString*)theURL delegate:(id<VAUrlConnectionDelegate>)theDelegate;

@end


@protocol VAUrlConnectionDelegate<NSObject>

@required
- (void) connectionDidFinish:(VAUrlConnection *)theConnection;

@optional
- (void) connectionDidFail:(VAUrlConnection *)theConnection;

@end

	
	
