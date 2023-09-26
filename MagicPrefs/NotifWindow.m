//
//  NotifWindow.m
//  MagicPrefs
//
//  Created by Vlad Alexa on 1/25/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "NotifWindow.h"


@implementation NotifWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    if (self != nil) {
        [self setOpaque:NO];			
		[self setBackgroundColor:[NSColor clearColor]];	
		[self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
		[self setLevel:NSPopUpMenuWindowLevel];
    }
    return self;
}

@end
