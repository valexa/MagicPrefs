//
//  HeatSyncPref.m
//  HeatSync
//
//  Created by Vlad Alexa on 1/12/11.
//  Copyright (c) 2011 NextDesign. All rights reserved.
//

#import "HeatSyncPref.h"
#import "smcWrapper.h"

#define PREFS_PLIST_DOMAIN @"com.vladalexa.heatsync"

@implementation HeatSyncPref

- (void) mainViewDidLoad
{
	[prefView addSubview:prefController.view];

	//launch heatsync if not running
	if ([self isAppRunning:@"HeatSync"] == NO) {
		if ([[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:PREFS_PLIST_DOMAIN] != nil){	
			NSLog(@"HeatSync not running, attempting to start.");		
			[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:PREFS_PLIST_DOMAIN options:NSWorkspaceLaunchWithoutActivation additionalEventParamDescriptor:nil launchIdentifier:nil];				
		}else{
			NSLog(@"Failed to find HeatSync.app");          
		}			
	}	
	
	NSDictionary *defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN];
	if ([[[[defaults objectForKey:@"HeatSync"] objectForKey:@"settings"] objectForKey:@"autoStart"] boolValue] == YES) {
		[startToggle setSelectedSegment:1];
	}else {
		[startToggle setSelectedSegment:0];		
	}
	if ([[[[defaults objectForKey:@"HeatSync"] objectForKey:@"settings"] objectForKey:@"hideDock"] boolValue] == YES) {
		[dockToggle setSelectedSegment:1];
	}else {
		[dockToggle setSelectedSegment:0];		
	}
	   
    //check if smc is setuid	    
	NSString *smcpath = [NSString stringWithFormat:@"%@/Library/Application Support/HeatSync/smc",NSHomeDirectory()];		    
	NSDictionary *fdict = [[NSFileManager defaultManager] attributesOfItemAtPath:smcpath error:nil];
	if ([[fdict valueForKey:@"NSFileOwnerAccountName"] isEqualToString:@"root"] && [[fdict valueForKey:@"NSFileGroupOwnerAccountName"] isEqualToString:@"admin"] && ([[fdict valueForKey:@"NSFilePosixPermissions"] intValue]==3437)) {
        [notice setHidden:YES];
        [icon setHidden:YES];        
        [download setHidden:YES];
	} else {
        //[notice setHidden:NO];
        //[icon setHidden:NO];    
        //[download setHidden:NO];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"VAHeatSyncEvent" object:@"setupHelper"];        
	}          
    
    //check if smc exists    
	if (![[NSFileManager defaultManager] fileExistsAtPath:smcpath]) {
		NSLog(@"Failed to find smc");                      
        [notice setHidden:YES];
        [icon setHidden:YES];        
        [download setHidden:YES];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"VAHeatSyncEvent" object:@"setupHelper"];
	}	    

}

-(IBAction) startToggle:(id)sender{
	if ([sender selectedSegment] == 1){
		[self saveSetting:[NSNumber numberWithBool:YES] forKey:@"autoStart"];
		[self setAutostart];
		//NSLog(@"autostart on");
	}else {
		[self saveSetting:[NSNumber numberWithBool:NO] forKey:@"autoStart"];
		[self removeAutostart];		
		//NSLog(@"autostart off");
	}	
}

-(IBAction) dockToggle:(id)sender{
	if ([sender selectedSegment] == 1){
		[self saveSetting:[NSNumber numberWithBool:YES] forKey:@"hideDock"];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"VAHeatSyncEvent" object:@"doRestart"];		
		//NSLog(@"dock icon hiden");
	}else {
		[self saveSetting:[NSNumber numberWithBool:NO] forKey:@"hideDock"];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"VAHeatSyncEvent" object:@"doRestart"];		
		//NSLog(@"dock icon shown");
	}	
}

-(void)saveSetting:(id)object forKey:(NSString*)key{
	NSString *pluginName = @"HeatSync";	
	if (![[object class] isKindOfClass:[NSObject class]]) {
		NSLog(@"The value to be set for %@ is not a object",key);
		return;
	}		
	NSDictionary *defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN];	
	NSMutableDictionary *settings = [[[defaults objectForKey:pluginName] objectForKey:@"settings"] mutableCopy];	
	[settings setObject:object forKey:key];	
	NSMutableDictionary *dict = [[defaults objectForKey:pluginName] mutableCopy];	
	[dict setObject:settings forKey:@"settings"];	
	
	CFPreferencesSetValue((CFStringRef)pluginName,dict,(CFStringRef)PREFS_PLIST_DOMAIN,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);
	CFPreferencesAppSynchronize((CFStringRef)PREFS_PLIST_DOMAIN);
	
	[settings release];		
	[dict release];
}

- (BOOL)isAppRunning:(NSString*)appName {
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

- (void)setAutostart{
	UInt32 seedValue;
	CFURLRef thePath;
	CFURLRef currentPath = (CFURLRef)[NSURL fileURLWithPath:[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:PREFS_PLIST_DOMAIN]];	
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);	
	if (loginItems) {
		//add it to startup list
		LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemLast, NULL, NULL, currentPath, NULL, NULL);		
		if (item){
			NSLog(@"Added login item %@",CFURLGetString(currentPath));			
			CFRelease(item);		
		}else{
			NSLog(@"Failed to set to autostart from %@",CFURLGetString(currentPath));
		}
		//remove entries of same app with different paths	
		NSArray  *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
		for (id item in loginItemsArray) {		
			LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
			CFStringRef currentPathComponent = CFURLCopyLastPathComponent(currentPath);
			if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
				CFStringRef thePathComponent = CFURLCopyLastPathComponent(thePath);
				if (CFStringCompare(thePathComponent,currentPathComponent,0) == kCFCompareEqualTo
					&& CFStringCompare(CFURLGetString(thePath),CFURLGetString(currentPath),0) != kCFCompareEqualTo	){
					LSSharedFileListItemRemove(loginItems, itemRef);
					//NSLog(@"Deleting duplicate login item at %@",CFURLGetString(thePath));				
				}
				CFRelease(thePathComponent);
				CFRelease(thePath);				
			}else{
				CFStringRef displayNameComponent = LSSharedFileListItemCopyDisplayName(itemRef);				
				//also remove those with path that do not resolve
				if (CFStringCompare(displayNameComponent,currentPathComponent,0) == kCFCompareEqualTo) {
					LSSharedFileListItemRemove(loginItems, itemRef);	
					//NSLog(@"Deleting duplicate and broken login item %@",LSSharedFileListItemCopyDisplayName(itemRef));	
				}
				CFRelease(displayNameComponent);				
			}
			CFRelease(currentPathComponent);
			//CFRelease(itemRef);			
		}
		[loginItemsArray release];		
		CFRelease(loginItems);		
	}else{
		NSLog(@"Failed to get login items");
	}
	//CFRelease(currentPath);
}

- (void)removeAutostart{
	UInt32 seedValue;
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);	
	if (loginItems) {
		//remove entries of same app	
		NSArray  *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
		for (id item in loginItemsArray) {		
			LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
			CFStringRef name = LSSharedFileListItemCopyDisplayName(itemRef);
			if (CFStringCompare(name,CFSTR("HeatSync.app"),0) == kCFCompareEqualTo){
				LSSharedFileListItemRemove(loginItems, itemRef);
				NSLog(@"Deleted login item %@",name);				
			}
			//CFRelease(itemRef);	
			CFRelease(name);							
		}
		[loginItemsArray release];	
		CFRelease(loginItems);		
	}else{
		NSLog(@"Failed to get login items");
	}
}

-(IBAction) openURL:(id)sender{
    NSURL *url = [NSURL URLWithString:@"http://vladalexa.com/apps/osx/SmcInstaller.app.zip"];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

@end
