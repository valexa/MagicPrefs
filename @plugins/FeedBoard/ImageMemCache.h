//
//  ImageMemCache.h
//  FeedBoard
//
//  Created by Vlad Alexa on 5/3/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ImageMemCache : NSObject {
	NSMutableDictionary *cache;
	NSMutableDictionary *queue;	
}

-(NSImage*)imageForDict:(NSDictionary*)data;
-(void)processQueue;

@end
