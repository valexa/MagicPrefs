//
//  HyperlinkButton.m
//  MagicPrefs
//
//  Created by Vlad Alexa on 9/8/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "HyperlinkButton.h"

@implementation HyperlinkButton

- (void) awakeFromNib {
	[self setBordered:NO];
	[self setBezelStyle:NSRegularSquareBezelStyle];
	[self setButtonType:NSMomentaryLightButton];
	
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSNumber numberWithInt:NSUnderlineStyleSingle], NSUnderlineStyleAttributeName,
								self.title, NSLinkAttributeName,
								[NSFont systemFontOfSize:12.0],  NSFontAttributeName,
								[NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:1.0], NSForegroundColorAttributeName,
								nil];
	self.attributedTitle = [[[NSAttributedString alloc] initWithString:self.title attributes:attributes] autorelease];	
	[self sizeToFit]; // only needed if the size isn't determined at compile time, e.g., you get the URL string from NSUserDefaults		
	
}

- (void)setTitle:(NSString*)title{
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSNumber numberWithInt:NSUnderlineStyleSingle], NSUnderlineStyleAttributeName,
								title, NSLinkAttributeName,
								[NSFont systemFontOfSize:12.0],  NSFontAttributeName,
								[NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:1.0], NSForegroundColorAttributeName,
								nil];
	self.attributedTitle = [[[NSAttributedString alloc] initWithString:title attributes:attributes] autorelease];	
	[self sizeToFit]; // only needed if the size isn't determined at compile time, e.g., you get the URL string from NSUserDefaults	
}

- (void)resetCursorRects {
	[self addCursorRect:[self bounds] cursor:[NSCursor pointingHandCursor]];
}

@end
