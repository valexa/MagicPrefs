//
//  ImageMemCache.m
//  FeedBoard
//
//  Created by Vlad Alexa on 5/3/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "ImageMemCache.h"

@implementation ImageMemCache

- (id)init{
    self = [super init];
    if(self != nil) {
		cache = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
		queue = [[NSMutableDictionary dictionaryWithCapacity:1] retain];			
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"ImageMemCache freed");
	[cache release];
	[queue release];
    [super dealloc];
}


-(NSImage*)imageForDict:(NSDictionary*)data{
	NSImage *image;
	NSURL *url;
	if ([[data objectForKey:@"image"] length] > 0) {
		url = [NSURL URLWithString:[data objectForKey:@"image"]];			
	}else {
		NSURL *host = [NSURL URLWithString:[data objectForKey:@"source"]];
		NSString *string = [NSString stringWithFormat:@"http://%@/favicon.ico",[host host]];
		if ([[host host] isEqualToString:@"techcrunch.com"]) string = @"http://s2.wp.com/wp-content/themes/vip/tctechcrunch/images/webclips/techcrunch.png?m=1268873281g";	//techcrunch fix
		url = [NSURL URLWithString:string];
	}
	
	image = [cache objectForKey:[url absoluteString]];
	
	if (image) {
		//NSLog(@"using %@ from cache",[url absoluteString]);
		return [cache objectForKey:[url absoluteString]];		
	}else {
		//NSLog(@"adding %@ to queue",[url absoluteString]);	
		[queue setObject:url forKey:[url absoluteString]];	
		[self processQueue];	
		return [NSImage imageNamed:@"NSRefreshTemplate"];
	}
	return nil;	
}

- (void)processQueue{	
	NSDictionary *copy = [queue copy];
	for (NSString *key in copy){
		NSURL *url = [NSURL URLWithString:key];
		//NSLog(@"downloading %@",[url absoluteString]);
		NSImage *image = [[NSImage alloc] initByReferencingURL:url];
		[cache setObject:image forKey:[url absoluteString]];
		[queue removeObjectForKey:[url absoluteString]];
		[image release];			
	}
	[copy release];
}


@end
