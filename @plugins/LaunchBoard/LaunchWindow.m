//
//  LaunchWindow.m
//  LaunchBoard
//
//  Created by Vlad Alexa on 12/14/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "LaunchWindow.h"

#if PLUGIN //set in project's GCC_PREPROCESSOR_DEFINITIONS
	#define MAIN_OBSERVER_NAME_STRING @"MPPluginLaunchBoardEvent"
#else
	#define MAIN_OBSERVER_NAME_STRING @"VALaunchBoardEvent"
#endif

@implementation LaunchWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    if (self != nil) {

    }
    return self;
}

-(void)dealloc{
	[super dealloc];
}

-(BOOL)canBecomeKeyWindow{
	return YES;
}

-(BOOL)canBecomeMainWindow{
	return YES;
}

- (void)mouseUp:(NSEvent *)theEvent{
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"dismissLaunchBoard" userInfo:nil deliverImmediately:YES];		
}

- (void)swipeWithEvent:(NSEvent *)theEvent {
	if ([theEvent type] == 31 && [theEvent deltaX] == -1.0) {
		//NSLog(@"Swipe left to right");
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"showPrevPage" userInfo:nil];		
	} 
	if ([theEvent type] == 31 && [theEvent deltaX] == 1.0) {
		//NSLog(@"Swipe right to left");
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"showNextPage" userInfo:nil];		
	} 
}

- (void)flagsChanged:(NSEvent *)theEvent{	
	if ([theEvent modifierFlags] & NSCommandKeyMask) {
		//NSLog(@"cmd on");		
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"cmdOn" userInfo:nil];		
	}else {
		//NSLog(@"cmd off");		
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"cmdOff" userInfo:nil];		
	}	 
}

@end
