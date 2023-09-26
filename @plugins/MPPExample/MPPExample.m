//
//  MPPExample.m
//  MPPExample
//
//  Created by Vlad Alexa on 9/23/10.
//  Copyright 2010 NextDesign. All rights reserved.
//
//  Example for a plugin with preferences, for a barebones example see magicprefs.com/plugins 

#import "MPPExample.h"

#import "MPPExamplePreferences.h"

//this runs under the plugins host, no changes to prefs saving code required assuming structure is same

#if PLUGIN //set in project's GCC_PREPROCESSOR_DEFINITIONS
    #define OBSERVER_NAME_STRING @"MPPluginMPPExampleEvent"
    #define PREF_OBSERVER_NAME_STRING @"MPPluginMPPExamplePreferencesEvent"
#else
    #define OBSERVER_NAME_STRING @"StandaloneMPPExampleEvent"
    #define PREF_OBSERVER_NAME_STRING @"StandaloneMPPExamplePreferencesEvent"
#endif

#define PLUGIN_NAME_STRING @"MPPExample"

static NSBundle* pluginBundle = nil;

@implementation MPPExample

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
		preferences = [[MPPExamplePreferences alloc] initWithNibName:@"MPPExamplePreferences" bundle:pluginBundle];	
		NSString *bundleId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];					
		if ([bundleId isEqualToString:@"com.apple.systempreferences"]) return self;	
		
		//your initialization here (everything below is optional if you do not have settings nor define events)	
		
		//init defaults
		defaults = [NSUserDefaults standardUserDefaults];		
		
		//set your events (only 1 in this case)
		NSDictionary *events = [NSDictionary dictionaryWithObjectsAndKeys:@"Show a notice",@"showNotice",nil];    
		NSMutableDictionary *dict = [[defaults objectForKey:PLUGIN_NAME_STRING] mutableCopy];
		[dict setObject:events forKey:@"events"];
		[defaults setObject:dict forKey:PLUGIN_NAME_STRING];
		[defaults synchronize];
		[dict release];	
		
		//listen for the events you set
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:OBSERVER_NAME_STRING object:nil];	
				
		//set your settings (only 1 in this case)
		if ([[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"squarePopup"] == nil){
			[self saveSetting:[NSNumber numberWithBool:NO] forKey:@"squarePopup"];
		}		
		
    }
    return self;
}

- (void)dealloc {
    [preferences release];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];       
	[super dealloc];    
}

-(void)theEvent:(NSNotification*)notif{			
	if (![[notif name] isEqualToString:OBSERVER_NAME_STRING]) {		
		return;
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){	
		if ([[notif object] isEqualToString:@"showNotice"]){			
			
			//
			//what to do when the gesture is triggered, we show some notifications as a example
			//
			
			//show a dialog
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MPpluginsEvent" object:nil userInfo:
			 [NSDictionary dictionaryWithObjectsAndKeys:@"doAlert",@"what",@"A dialog title.",@"title",@"A dialog message",@"text",@"OK",@"action",nil]
			 ];				
			
			//send a growl notification			
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MPpluginsEvent" object:nil userInfo:
			 [NSDictionary dictionaryWithObjectsAndKeys:@"doGrowl",@"what",@"A growl title",@"title",@"A growl message",@"message",nil]
			 ];						
					
			NSDictionary *settings = [[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"];				
			if ([[settings objectForKey:@"squarePopup"] boolValue] == YES){
				//also show square notification				
				[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"remote" userInfo:
				 [NSDictionary dictionaryWithObjectsAndKeys:@"doNotif",@"what",@"square",@"image",@"Some Text",@"text",nil]
				 ];								
			}			
			
		}			
	}			
}

#pragma mark handy code for one line preferences saving

-(void)saveSetting:(id)object forKey:(NSString*)key{   
    //this is the method for when the host application is not SytemPreferences (MagicPrefsPlugins or your standalone)      
	if (![[object class] isKindOfClass:[NSObject class]]) {
		NSLog(@"The value to be set for %@ is not a object",key); 
		return;
	}     
    NSDictionary *prefs = [NSDictionary dictionaryWithDictionary:[defaults objectForKey:PLUGIN_NAME_STRING]];    
    if ([prefs objectForKey:@"settings"] == nil) {
        NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:prefs];
        [d setObject:[[[NSDictionary alloc] init] autorelease] forKey:@"settings"];
        prefs = d;
    }
    NSDictionary *db = [self editNestedDict:prefs setObject:object forKeyHierarchy:[NSArray arrayWithObjects:@"settings",key,nil]];
    [defaults setObject:db forKey:PLUGIN_NAME_STRING];        
    [defaults synchronize];
}

-(NSDictionary*)editNestedDict:(NSDictionary*)dict setObject:(id)object forKeyHierarchy:(NSArray*)hierarchy{
    if (dict == nil) return dict;
    if (![dict isKindOfClass:[NSDictionary class]]) return dict;    
    NSMutableDictionary *parent = [[dict mutableCopy] autorelease];
    
    //drill down mutating each dict along the way
    NSMutableArray *structure = [NSMutableArray arrayWithCapacity:1];    
    NSMutableDictionary *prev = parent;
    for (id key in hierarchy) {
        if (key != [hierarchy lastObject]) {
            prev = [[[prev objectForKey:key] mutableCopy] autorelease];                            
            if (![prev isKindOfClass:[NSDictionary class]]) return dict;              
            [structure addObject:prev];
        }
    }   
    
    //do the change
    [[structure lastObject] setObject:object forKey:[hierarchy lastObject]];    
    
    //drill back up saving the changes each step along the way   
    for (int c = [structure count]-1; c >= 0; c--) {
        if (c == 0) {
            [parent setObject:[structure objectAtIndex:c] forKey:[hierarchy objectAtIndex:c]];                                
        }else{
            [[structure objectAtIndex:c-1] setObject:[structure objectAtIndex:c] forKey:[hierarchy objectAtIndex:c]];                                
        }       
    }
    
    return parent;
}


@end
