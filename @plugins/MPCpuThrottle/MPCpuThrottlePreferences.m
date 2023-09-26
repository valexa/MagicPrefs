//
//  MPCpuThrottlePreferences.m
//  MPCpuThrottle
//
//  Created by Vlad Alexa on 9/23/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "MPCpuThrottlePreferences.h"

#define OBSERVER_NAME_STRING @"MPPluginMPCpuThrottlePreferencesEvent"
#define MAIN_OBSERVER_NAME_STRING @"MPPluginMPCpuThrottleEvent"
#define PLUGIN_NAME_STRING @"MPCpuThrottle"
#define PREFS_PLIST_DOMAIN @"com.vladalexa.MagicPrefs.MagicPrefsPlugins"

@implementation MPCpuThrottlePreferences

- (void)loadView {
    [super loadView];
    
    [appsTable setRowHeight:23];    
    
    throttles = [[NSMutableDictionary alloc] init];
    appsList = [[NSMutableArray alloc] init];    
    
    //register for notifications
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:OBSERVER_NAME_STRING object:nil];   
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(syncUI) name:NSWorkspaceDidLaunchApplicationNotification object:nil];	
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(syncUI) name:NSWorkspaceDidTerminateApplicationNotification object:nil];    
    
	[self syncUI];    
	
}

-(void)dealloc{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];     
    [appsList release];
    [throttles release];
    [super dealloc];    
}

-(void)theEvent:(NSNotification*)notif{		
	if (![[notif name] isEqualToString:OBSERVER_NAME_STRING]) {
		return;
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){
	}	
}

-(void)syncUI
{
	NSDictionary *defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN];
    [throttles setDictionary:[[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"throttles"]];
    [appsList setArray:[MPCpuThrottlePreferences getCarbonProcessList]]; 
    [appsTable reloadData];
}

+ (NSArray*)getCarbonProcessList{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
	ProcessSerialNumber psn = { kNoProcess, kNoProcess };
	while (GetNextProcess(&psn) == noErr) {
		CFDictionaryRef cfDict = ProcessInformationCopyDictionary(&psn,  kProcessDictionaryIncludeAllInformationMask);
		if (cfDict) {
			NSDictionary *dict = (NSDictionary *)cfDict;
            NSString *name = [NSString stringWithFormat:@"%@",[dict objectForKey:(id)kCFBundleNameKey]];
            NSString *pid = [NSString stringWithFormat:@"%@",[dict objectForKey:@"pid"]];
            NSString *bid = [NSString stringWithFormat:@"%@",[dict objectForKey:(id)kCFBundleIdentifierKey]];
            NSString *path = [NSString stringWithFormat:@"%@",[dict objectForKey:@"BundlePath"]];
            if (![path isEqualToString:@"(null)"] && ![bid isEqualToString:@"(null)"] && name && pid && bid && path) {
                [ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:name,@"name",pid,@"pid",bid,@"bid",path,@"path",                            
                                //[NSString stringWithFormat: @"%s",proc->kp_proc.p_nice],@"nice",                        
                                nil]];                 
            }else{
                //NSLog(@"Skipped process %@ %@ %@ %@",name,pid,bid,path);
            }
			CFRelease(cfDict);			
		}
	}
	return ret;
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

-(IBAction)changeSlider:(id)sender{
	//NSDictionary *defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN];      
    //NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"throttles"]];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];//only allow one app to be trottled at a time    
    NSDictionary *item = [appsList objectAtIndex:[appsTable selectedRow]];     
    if ([sender intValue] != 100) [dict setObject:[NSNumber numberWithInt:[sender intValue]] forKey:[item objectForKey:@"bid"]];
    [self saveSetting:dict forKey:@"throttles"];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"refresh"]; 
    [self syncUI];
}

#pragma mark NSTableView datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView {
    return [appsList count];	
}

- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)theColumn row:(NSInteger)rowIndex {
    NSDictionary *item = [appsList objectAtIndex:rowIndex];
	NSString *ident = [theColumn identifier]; 
	if ([ident isEqualToString:@"slider"]){
        NSNumber *num = [throttles objectForKey:[item objectForKey:@"bid"]];
        if (num == nil) num = [NSNumber numberWithInt:100];        
        return num;
	}    
    if ([ident isEqualToString:@"icon"]) {
        return [[NSWorkspace sharedWorkspace] iconForFile:[item objectForKey:@"path"]];        
    }
    return [item objectForKey:ident];
}

@end
