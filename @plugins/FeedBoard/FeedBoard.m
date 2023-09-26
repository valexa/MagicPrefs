//
//  FeedBoard.m
//  FeedBoard
//
//  Created by Vlad Alexa on 4/25/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "FeedBoard.h"
#import "FeedBoardMainWindow.h"
#import "BlurWindow.h"

static NSBundle* pluginBundle = nil;

@implementation FeedBoard

/*
 Plugin events : 
 readGoogle "Google Reader Feed" 
 
 Plugin events (nondynamic):
 N/A
 
 Plugin settings :
 google
 
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
		
		NSString *bundleId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];					
		if ([bundleId isEqualToString:@"com.apple.systempreferences"]) return self;	
		
		//your initialization here		
		//NSLog(@"FeedBoard init");
		
		defaults = [NSUserDefaults standardUserDefaults];		
		
		//set events
		NSDictionary *events = [NSDictionary dictionaryWithObjectsAndKeys:@"Google Reader Feed",@"readGoogle",nil];
		NSMutableDictionary *dict = [[defaults objectForKey:@"FeedBoard"] mutableCopy];
		[dict setObject:events forKey:@"events"];
		[defaults setObject:dict forKey:@"FeedBoard"];
		[defaults synchronize];
		[dict release];		
		
		//set settings
		NSDictionary *settings = [[defaults objectForKey:@"FeedBoard"] objectForKey:@"settings"];
		if ([settings objectForKey:@"google"] == nil) [self saveSetting:[[[NSDictionary alloc] init] autorelease] forKey:@"google"];		
		
		//aloc FeedBoardMainWindow
		NSRect screen = [[NSScreen mainScreen] frame];
		window = [[FeedBoardMainWindow alloc] initWithContentRect:NSMakeRect(-10,-10,screen.size.width+20,screen.size.height+20) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];						
		[BlurWindow blurWindow:window];
		//[NSThread detachNewThreadSelector:@selector(allocOnNewThread) toTarget:self withObject:nil];	
		
    }
    return self;
}

- (void)allocOnNewThread{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	if ([NSThread isMainThread]){
		NSLog(@"Alloced on main thread: %@", [NSThread currentThread]);
	}else {
		NSLog(@"Alloced on secondary thread: %@", [NSThread currentThread]);			
	}		
	[pool drain];
}

- (void)dealloc {
	[window release];	
	[super dealloc];
}

-(void)saveSetting:(id)object forKey:(NSString*)key{
	NSString *pluginName = @"FeedBoard";
	if (![[object class] isKindOfClass:[NSObject class]]) {
		NSLog(@"The value to be set for %@ is not a object",key);
		return;
	}
	NSMutableDictionary *settings = [[[defaults objectForKey:pluginName] objectForKey:@"settings"] mutableCopy];
	if (settings == nil) settings = [[NSMutableDictionary alloc] initWithCapacity:1];	
	[settings setObject:object forKey:key];
	NSMutableDictionary *dict = [[defaults objectForKey:pluginName] mutableCopy];
	if (dict == nil) dict = [[NSMutableDictionary alloc] initWithCapacity:1];	
	[dict setObject:settings forKey:@"settings"];
	
	[defaults setObject:dict forKey:pluginName];
	[defaults synchronize];
	
	[settings release];		
	[dict release];
}

@end
