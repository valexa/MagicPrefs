//
//  MPSafeguardPreferences.m
//  MPSafeguard
//
//  Created by Vlad Alexa on 9/23/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "MPSafeguardPreferences.h"

#define OBSERVER_NAME_STRING @"MPPluginMPSafeguardPreferencesEvent"
#define MAIN_OBSERVER_NAME_STRING @"MPPluginMPSafeguardEvent"

@implementation MPSafeguardPreferences

- (void)loadView {
    [super loadView];
    
    [appsTable setRowHeight:22];    
    
    appsList = [[NSMutableArray alloc] init];
    
    //register for notifications
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:OBSERVER_NAME_STRING object:nil];    
	
    [self getData];
}

-(void)dealloc{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];     
    [appsList release];
    [super dealloc];    
}

-(void)theEvent:(NSNotification*)notif{		
	if (![[notif name] isEqualToString:OBSERVER_NAME_STRING]) {
		return;
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){
		if ([[notif object] isEqualToString:@"doRefresh"]){
            [self getData];
            [appsTable reloadData]; 
		}
	}	
}

-(void)getData{
    [appsList removeAllObjects];
	NSDictionary *defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.vladalexa.MagicPrefs.MagicPrefsPlugins"];	
	NSDictionary *settings = [[defaults objectForKey:@"MPSafeguard"] objectForKey:@"settings"];	
    NSMutableDictionary *dicts = [NSMutableDictionary dictionaryWithCapacity:1];
    for (NSDictionary *system in [settings objectForKey:@"system"]) {
        NSString *name = [system objectForKey:@"path"];
        int count = [[dicts objectForKey:name] intValue];
        if (count > 0) {
            [dicts setValue:[NSString stringWithFormat:@"%i",count+1] forKey:name];
        }else {
            [dicts setValue:@"1" forKey:name];            
        }
    }
    for (NSDictionary *system in [settings objectForKey:@"mm"]) {
        NSString *name = [system objectForKey:@"path"];
        int count = [[dicts objectForKey:name] intValue];
        if (count > 0) {
            [dicts setValue:[NSString stringWithFormat:@"%i",count+1] forKey:name];
        }else {
            [dicts setValue:@"1" forKey:name];            
        }
    }
    for (NSDictionary *system in [settings objectForKey:@"mt"]) {
        NSString *name = [system objectForKey:@"path"];
        int count = [[dicts objectForKey:name] intValue];
        if (count > 0) {
            [dicts setValue:[NSString stringWithFormat:@"%i",count+1] forKey:name];
        }else {
            [dicts setValue:@"1" forKey:name];            
        }
    } 
    //save the values
    for (NSString *path in dicts ) {        
        [appsList addObject:[NSDictionary dictionaryWithObjectsAndKeys:[path lastPathComponent],@"name",[dicts objectForKey:path],@"count",[[NSWorkspace sharedWorkspace] iconForFile:path],@"icon", nil]];
    }
}


-(void)saveSetting:(id)object forKey:(NSString*)key{
	NSString *pluginName = @"MPSafeguard";	
	if (![[object class] isKindOfClass:[NSObject class]]) {
		NSLog(@"The value to be set for %@ is not a object",key);
		return;
	}		
	NSDictionary *defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.vladalexa.MagicPrefs.MagicPrefsPlugins"];	
	NSMutableDictionary *settings = [[[defaults objectForKey:pluginName] objectForKey:@"settings"] mutableCopy];	
	[settings setObject:object forKey:key];	
	NSMutableDictionary *dict = [[defaults objectForKey:pluginName] mutableCopy];	
	[dict setObject:settings forKey:@"settings"];	
	
	CFStringRef appID = CFSTR("com.vladalexa.MagicPrefs.MagicPrefsPlugins");
	CFPreferencesSetValue((CFStringRef)pluginName,dict,appID,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);
	CFPreferencesSynchronize(appID,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);

	[settings release];		
	[dict release];
}

#pragma mark NSTableView datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView {
    return [appsList count];	
}

- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)theColumn row:(NSInteger)rowIndex {
    NSDictionary *item = [appsList objectAtIndex:rowIndex];  
	NSString *ident = [theColumn identifier];    
    return [item objectForKey:ident];
}

@end
