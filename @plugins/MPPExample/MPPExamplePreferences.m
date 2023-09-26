//
//  MPPExamplePreferences.m
//  MPPExample
//
//  Created by Vlad Alexa on 9/23/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "MPPExamplePreferences.h"

//this runs under the standalone or System Preferences, standardUserDefaults must be give a domain

#if PLUGIN //set in project's GCC_PREPROCESSOR_DEFINITIONS
    #define PREFS_PLIST_DOMAIN @"com.vladalexa.MagicPrefs.MagicPrefsPlugins"
#else
    #define PREFS_PLIST_DOMAIN @"com.yourcompany.MPPExample"
#endif

#define PLUGIN_NAME_STRING @"MPPExample"

@implementation MPPExamplePreferences

- (void)loadView {
    [super loadView];
	
	NSDictionary *defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN];	
	NSDictionary *settings = [[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"];	
	
	if ([[settings objectForKey:@"squarePopup"] boolValue] == YES) {
		[squareButton setState:1];
	}else {
		[squareButton setState:0];		
	}	

}

-(void)saveSetting:(id)object forKey:(NSString*)key{
    //this is the method for when the host application is not MagicPrefsPlugins (SytemPreferences or your standalone)    
	if (![[object class] isKindOfClass:[NSObject class]]) {
		NSLog(@"The value to be set for %@ is not a object",key);
		return;
	}    
	NSDictionary *defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN];	
	NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithDictionary:[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"]];
	[settings setObject:object forKey:key];	
	NSMutableDictionary *dict = [[defaults objectForKey:PLUGIN_NAME_STRING] mutableCopy];	
	[dict setObject:settings forKey:@"settings"];	
	
	CFStringRef appID = (CFStringRef)PREFS_PLIST_DOMAIN;
	CFPreferencesSetValue((CFStringRef)PLUGIN_NAME_STRING,dict,appID,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);
	CFPreferencesSynchronize(appID,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);
	
	[dict release];
}

-(IBAction)squareToggle:(id)sender{
	
	if ([sender state] == 1){
		[self saveSetting:[NSNumber numberWithBool:YES] forKey:@"squarePopup"];
	}else {
		[self saveSetting:[NSNumber numberWithBool:NO] forKey:@"squarePopup"];
	}	
}

@end
