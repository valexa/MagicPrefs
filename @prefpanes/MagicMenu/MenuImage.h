//
//  MenuImage.h
//  MagicPrefs
//
//  Created by Vlad Alexa on 12/3/09.
//  Copyright 2009 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MagicMenuMain.h"

@interface MenuImage : NSView {
	
	NSImage * _compositeImage;	
	NSDictionary *lastTap;	
	NSImageView *imgView;
	NSDate *performTime;
	
}

- (void)createCompositeImage:(NSString *)file rotate:(NSString *)rotate;
- (NSImage*)newRotatedImage:(NSString*)imagePath byDegrees:(NSString *)deg;

@end
