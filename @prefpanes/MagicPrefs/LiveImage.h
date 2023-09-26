//
//  LiveImage.h
//  MagicPrefs
//
//  Created by Vlad Alexa on 12/3/09.
//  Copyright 2009 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MagicPrefsMain.h"
#import "VAUserDefaults.h"

@interface LiveImage : NSView {
	
	VAUserDefaults *defaults;	
	NSImage *_compositeImage;	
	NSDictionary *lastTap;	
	NSImageView *imgView;
	NSDate *performTime;
	NSString *lastGesture;
	
}

- (NSRect)zoneRect:(NSDictionary*)zone type:(NSString*)type;
- (void)createCompositeImage:(NSString *)file background:(NSString *)background rotate:(NSString *)rotate;
- (NSImage*)newRotatedImage:(NSString*)imagePath byDegrees:(NSString *)deg;

@end
