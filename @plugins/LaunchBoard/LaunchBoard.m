//
//  LaunchBoard.m
//  LaunchBoard
//
//  Created by Vlad Alexa on 12/6/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "LaunchBoard.h"
#import "LaunchBoardMainWindow.h"
#import "BlurWindow.h"
#import "LaunchBoardPreferences.h"

static NSBundle* pluginBundle = nil;

@implementation LaunchBoard

@synthesize preferences;

/*
 Plugin events : 
 showLaunchBoard "LaunchBoard"
 
 Plugin events (nondynamic):
 N/A
 
 Plugin settings :
 N/A
 
 Plugin preferences :
 N/A					
 */

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
		preferences = [[LaunchBoardPreferences alloc] initWithNibName:@"LaunchBoardPreferences" bundle:pluginBundle];	        
		NSString *bundleId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];					
		if ([bundleId isEqualToString:@"com.apple.systempreferences"]) return self;	
		
		//your initialization here	
		
		defaults = [NSUserDefaults standardUserDefaults];		
		
		//set events
		NSDictionary *events = [NSDictionary dictionaryWithObjectsAndKeys:@"LaunchBoard",@"showLaunchBoard",nil];
		NSMutableDictionary *dict = [[defaults objectForKey:@"LaunchBoard"] mutableCopy];
		[dict setObject:events forKey:@"events"];
		[defaults setObject:dict forKey:@"LaunchBoard"];
		[defaults synchronize];
		[dict release];			
		
		window = [[LaunchBoardMainWindow alloc] init];
		//[BlurWindow blurWindow:(NSWindow*)window.launchWindow];		

    }
    return self;
}

-(void)dealloc{
    [preferences release];
	[window release];
	[super dealloc];    
}


@end

