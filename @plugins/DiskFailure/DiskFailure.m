//
//  DiskFailure.m
//  DiskFailure
//
//  Created by Vlad Alexa on 9/23/10.
//  Copyright 2010 NextDesign. All rights reserved.
//
//  Example for a plugin with preferences, for a barebones example see magicprefs.com/plugins 

#import "DiskFailure.h"
#import "DiskFailurePreferences.h"
#import "DiskFailureMainCore.h"

static NSBundle* pluginBundle = nil;

@implementation DiskFailure

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
		preferences = [[DiskFailurePreferences alloc] initWithNibName:@"DiskFailurePreferences" bundle:pluginBundle];	
		NSString *bundleId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];					
		if ([bundleId isEqualToString:@"com.apple.systempreferences"]) return self;	
		
		//your initialization here (everything below is optional if you do not have settings nor define events)	
        
        if ([DiskFailure isAppRunning:@"DiskFailure"] == NO) {
            main = [[DiskFailureMainCore alloc] init]; 		
        }else{
            NSLog(@"DiskFailure standalone already running."); 
            [[NSAlert alertWithMessageText:@"DiskFailure standalone already running." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"You need to stop the standalone version of DiskFailure in order to load this plugin."] runModal];             
        }     
		
    }
    return self;
}

- (void)dealloc {
	[super dealloc];
	[preferences release];
	[main release];     
}

+ (BOOL)isAppRunning:(NSString*)appName {
	BOOL ret = NO;
	ProcessSerialNumber psn = { kNoProcess, kNoProcess };
	while (GetNextProcess(&psn) == noErr) {
		CFDictionaryRef cfDict = ProcessInformationCopyDictionary(&psn,  kProcessDictionaryIncludeAllInformationMask);
		if (cfDict) {
			NSString *name = [(NSDictionary *)cfDict objectForKey:(id)kCFBundleNameKey];
			if (name) {
				if ([appName isEqualToString:name]) {
					ret = YES;
				}
			}
			CFRelease(cfDict);			
		}
	}
	return ret;
}


@end
