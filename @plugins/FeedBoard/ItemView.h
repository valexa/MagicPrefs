//
//  ItemView.h
//  Immersee
//
//  Created by Vlad Alexa on 4/20/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>
#import "ImageCache.h"

@interface ItemView : NSView {
	NSDictionary *data;
	ImageCache *imgcache;
	NSRect imagerect;
}

@property (nonatomic, retain, readwrite) NSDictionary *data;

-(NSMutableDictionary*) makeAttrDict;
-(void)determineImageRect;
-(void)getFaviconIfNoImage;

@end
