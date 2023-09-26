//
//  MagicTerminal.m
//  MagicTerminal
//
//  Created by Vlad Alexa on 9/23/10.
//  Copyright 2010 NextDesign. All rights reserved.
//
//  Example for a plugin with preferences, for a barebones example see magicprefs.com/plugins 

#import "MagicTerminal.h"
#import "MagicTerminalPreferences.h"
#import "MagicTerminalMainCore.h"

static NSBundle* pluginBundle = nil;

@implementation MagicTerminal

/*
 Plugin events : 
 N/A 
 
 Plugin events (nondynamic):
 N/A
 
 Plugin settings :
 N/A
 
 Plugin preferences :
 N/A					
 */ 

@synthesize preferences;

+ (BOOL)initializeClass:(NSBundle*)theBundle {
	if (pluginBundle) {
		return NO;
	}
	pluginBundle = [theBundle retain];
	return YES;
}

+ (void)terminateClass {
	if (pluginBundle) {
		[pluginBundle release];
		pluginBundle = nil;
	}
}

- (id)init{
    self = [super init];
    if(self != nil) {		
		preferences = [[MagicTerminalPreferences alloc] initWithNibName:@"MagicTerminalPreferences" bundle:pluginBundle];	
		NSString *bundleId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];					
		if ([bundleId isEqualToString:@"com.apple.systempreferences"]) return self;	
		
		//your initialization here (everything below is optional if you do not have settings nor define events)	
								
		main = [[MagicTerminalMainCore alloc] init];               
		
    }
    return self;
}

- (void)dealloc {
	[super dealloc];
	[preferences release];
	[main release];    
}


@end
