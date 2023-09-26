//
//  MPSafeguard.m
//  MPSafeguard
//
//  Created by Vlad Alexa on 9/23/10.
//  Copyright 2010 NextDesign. All rights reserved.
//
//  Example for a plugin with preferences, for a barebones example see magicprefs.com/plugins 

#define PREFS_OBSERVER_NAME_STRING @"MPPluginMPSafeguardPreferencesEvent"
#define OBSERVER_NAME_STRING @"MPPluginMPSafeguardEvent"
#define PLUGIN_NAME_STRING @"MPSafeguard"

#import "MPSafeguard.h"

#import "MPSafeguardPreferences.h"

static NSBundle* pluginBundle = nil;

@implementation MPSafeguard

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
		preferences = [[MPSafeguardPreferences alloc] initWithNibName:@"MPSafeguardPreferences" bundle:pluginBundle];	
		NSString *bundleId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];					
		if ([bundleId isEqualToString:@"com.apple.systempreferences"]) return self;	
		
		//your initialization here (everything below is optional if you do not have settings nor define events)	
		
		//init defaults
		defaults = [NSUserDefaults standardUserDefaults];		
		
		//set your events 	
		
		//listen for events
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:OBSERVER_NAME_STRING object:nil];	
				
		//set your settings
		if ([[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"systemCheckFrequency"] == nil){
			[self saveSetting:@"30" forKey:@"systemCheckFrequency"];
		}
		if ([[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"deviceCheckFrequency"] == nil){
			[self saveSetting:@"30" forKey:@"deviceCheckFrequency"];
		}        
		if ([[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"pingFrequency"] == nil){
			[self saveSetting:@"30" forKey:@"pingFrequency"];
		}	        
                
        NSString *frequency = [[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"systemCheckFrequency"];
        if ([frequency intValue] > 5) {
            [NSTimer scheduledTimerWithTimeInterval:[frequency intValue] target:self selector:@selector(systemCheck:) userInfo:nil repeats:YES];            
        }else{
            NSLog(@"%@ frequency too high",frequency);
        }
        
        frequency = [[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"deviceCheckFrequency"];        
        if ([frequency intValue] > 5) {
            [NSTimer scheduledTimerWithTimeInterval:[frequency intValue] target:self selector:@selector(deviceCheck:) userInfo:nil repeats:YES];                    
        }else{
            NSLog(@"%@ frequency too high",frequency);
        }        
        
        frequency = [[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"pingFrequency"];        
        if ([frequency intValue] > 5) {
            [NSTimer scheduledTimerWithTimeInterval:[frequency intValue] target:self selector:@selector(ping:) userInfo:nil repeats:YES];            
        }else{
            NSLog(@"%@ frequency too high",frequency);
        }                
		
    }
    return self;
}

- (void)dealloc {
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];       
	[super dealloc];    
}

-(void)theEvent:(NSNotification*)notif{			
	if (![[notif name] isEqualToString:OBSERVER_NAME_STRING]) {		
		return;
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){			
	}
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]]){
		if ([[[notif userInfo] objectForKey:@"what"] isEqualToString:@"pong"]){
            NSString *source = [[notif userInfo] objectForKey:@"source"]; 
            if ([source isEqualToString:@"MPcoreMainEvent"]) {
                pingReply = YES;
            }         
		}        
	}    
}

-(void)saveSetting:(id)object forKey:(NSString*)key{
	NSString *pluginName = PLUGIN_NAME_STRING;
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

-(void)notifyIfNew:(NSString*)name{
	NSDictionary *settings = [[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"];    
    NSMutableArray *arr = [NSMutableArray arrayWithArray:[settings objectForKey:@"system"]];
    [arr addObjectsFromArray:[settings objectForKey:@"mm"]];
    [arr addObjectsFromArray:[settings objectForKey:@"mt"]];    
    for (NSDictionary *dict in arr) {
        if ([[dict objectForKey:@"name"] isEqualToString:name]) {
            return;
        }
    }
    NSString *details = [NSString stringWithFormat:@"Application %@ matches some conflict vectors with MagicPrefs",name];
    NSLog(@"%@",details);
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"GrowlNotification" object:nil userInfo:
     [NSDictionary dictionaryWithObjectsAndKeys:@"MagicPrefs",@"ApplicationName",@"MagicPrefsGrowlNotif",@"NotificationName",
      @"Potential conflict detected",@"NotificationTitle",
      details,@"NotificationDescription",
      nil]
     ];             
}

#pragma mark system check

-(void)systemCheck:(id)sender{
    NSMutableArray *system = [NSMutableArray arrayWithCapacity:1];
	NSDictionary *taps = [self getTaps];
	for (NSString *pid in taps){
		NSDictionary *dict = [self infoForPID:[pid intValue]];
        if ([[dict objectForKey:@"BundlePath"] isEqualToString:@"/System/Library/CoreServices/Dock.app"]) continue; 
        if ([[dict objectForKey:@"BundlePath"] isEqualToString:@"/Applications/MagicPrefs.app"]) continue;        	
        NSString *bid = [dict objectForKey:@"CFBundleIdentifier"];
        if ([bid length] > 0) {
            if ([[taps objectForKey:pid] isEqualToString:@"active"]) {
                NSString *name = [dict objectForKey:@"CFBundleName"];
                NSString *path = [dict objectForKey:@"BundlePath"];
                NSDate *date = [dict objectForKey:@"LSLaunchTime"];
                //NSLog(@"Found %@ tap by %@ since %@",type,path,date);
                [self notifyIfNew:name];
                [system addObject:[NSDictionary dictionaryWithObjectsAndKeys:pid,@"pid",bid,@"id",name,@"name",path,@"path",date,@"date", nil]];                              
            }
        }else{
            NSLog(@"Can't get info on pid %@ (different session or orphan)",[dict objectForKey:@"pid"]);			
        }
	}	
    [self saveSetting:system forKey:@"system"];	
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:PREFS_OBSERVER_NAME_STRING object:@"doRefresh" userInfo:nil];  
}

- (NSDictionary *)getTaps{
	NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithCapacity:1];
	uint32_t preCount;
    CGError err;
	err = CGGetEventTapList(0, NULL, &preCount);
    if (err == kCGErrorSuccess){		
		CGEventTapInformation *list = (CGEventTapInformation *)calloc(preCount,sizeof(CGEventTapInformation));
		uint32_t postCount;
		err = CGGetEventTapList(preCount, list, &postCount);
		if (err == kCGErrorSuccess) {		
			int i;
			int count = 0;
			for (i = 0; i < postCount; i++) {	
				NSString *pid = [NSString stringWithFormat:@"%i",list[i].tappingProcess];
				count = [[ret objectForKey:pid] intValue]+1;
				if (list[i].options == 0x00000000){
					[ret setObject:@"active" forKey:pid];					
				}else {
					[ret setObject:@"passive" forKey:pid];					
				}
                
			}	
			free(list);				
		}				
	}	
	return ret;
}

-(BOOL)pidIsTapping:(pid_t)pid{
	uint32_t preCount;
    CGError err;
	err = CGGetEventTapList(0, NULL, &preCount);
    if (err == kCGErrorSuccess){		
		CGEventTapInformation *list = (CGEventTapInformation *)calloc(preCount,sizeof(CGEventTapInformation));
		uint32_t postCount;
		err = CGGetEventTapList(preCount, list, &postCount);
		if (err == kCGErrorSuccess) {		
			int i;
			for (i = 0; i < postCount; i++) {	
				//ignore passive taps
				if (list[i].options == 0x00000000){
					if (list[i].tappingProcess == pid) {
						return TRUE;
					}
				}
			}	
			free(list);				
		}				
	}	
	return FALSE;
}

- (NSDictionary *)infoForPID:(pid_t)pid {
    NSDictionary *ret = nil;
	ProcessSerialNumber psn;
	if (GetProcessForPID(pid, &psn) == noErr) {
		CFDictionaryRef cfDict = ProcessInformationCopyDictionary(&psn,kProcessDictionaryIncludeAllInformationMask); 
        ret = [NSDictionary dictionaryWithDictionary:(NSDictionary *)cfDict];
        CFRelease(cfDict);
	}
	return ret;
}

#pragma mark device check

-(void)deviceCheck:(id)sender{   
    [self saveSetting:[self deviceData:@"BNBMouseDevice"] forKey:@"mm"];     
    [self saveSetting:[self deviceData:@"BNBTrackpadDevice"] forKey:@"mt"];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:PREFS_OBSERVER_NAME_STRING object:@"doRefresh" userInfo:nil];     
}

-(NSArray*)deviceData:(NSString*)deviceName{ 
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];    
    for (NSString *str in [self clientsForDevice:deviceName]) {
        if ([[[str componentsSeparatedByString:@","] objectAtIndex:1] isEqualToString:@" hidd"]) continue;
        if ([[[str componentsSeparatedByString:@","] objectAtIndex:1] isEqualToString:@" MagicPrefs"]) continue;               
        NSString *pid = [[[[str componentsSeparatedByString:@","] objectAtIndex:0] componentsSeparatedByString:@" "] objectAtIndex:1];
        NSDictionary *dict = [self infoForPID:[pid intValue]];
        NSString *bid = [dict objectForKey:@"CFBundleIdentifier"];
        if ([bid length] > 0) {
            NSString *name = [dict objectForKey:@"CFBundleName"];
            NSString *path = [dict objectForKey:@"BundlePath"];
            NSDate *date = [dict objectForKey:@"LSLaunchTime"];            
            //NSLog(@"Found %@ mtd by %@ since %@",deviceName,path,date);
            [self notifyIfNew:name];
            [ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:pid,@"pid",bid,@"id",name,@"name",path,@"path",date,@"date", nil]];               
        }else{
            NSLog(@"Can't get info on pid %@ (different session or orphan)",pid);			
        }               
    }
    return ret;    
}

-(NSArray*)clientsForDevice:(NSString*)name{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
	io_service_t parent = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching([name UTF8String]));	
	if (parent) {
        io_iterator_t  iter;        
        // Create an iterator across all children of the service object passed in.
        IORegistryEntryCreateIterator(parent,kIOServicePlane,kIORegistryIterateRecursively,&iter);          
        if (iter){
            io_service_t service;            
            while ( ( service = IOIteratorNext( iter ) ) )  {
                if ( IOObjectConformsTo( service, "AppleMultitouchDeviceUserClient") ) {
                    if (service) {
                        CFTypeRef	uuidAsCFString;                        
                        uuidAsCFString = IORegistryEntryCreateCFProperty(service, CFSTR(kIOUserClientCreatorKey), kCFAllocatorDefault, 0);
                        IOObjectRelease(service);
                        [ret addObject:[[[NSString alloc] initWithFormat:@"%@",uuidAsCFString] autorelease]];
                        CFRelease(uuidAsCFString);
                    }
                }
                IOObjectRelease( service );
            }
            IOObjectRelease( parent );
        }else{
            NSLog(@"Error iterating from %@",name);        
        }         
    }else{
        //NSLog(@"No service for %@, probably none connected",name);
    }    
    return ret;
}

#pragma mark ping

-(void)ping:(id)sender{
	if ([MPSafeguard isAppRunning:@"MagicPrefs"] == NO) return; //only attempt to ping it if it's running   
    pingReply = NO; 
    selfWasHanged = YES;    
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"remote" userInfo:
     [NSDictionary dictionaryWithObjectsAndKeys:@"ping",@"what",OBSERVER_NAME_STRING,@"source",nil]
     ];
	[NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(selfIsAlive:) userInfo:nil repeats:NO]; 
	[NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(killMagicPrefs:) userInfo:nil repeats:NO];     
}

-(void)selfIsAlive:(id)sender{
    selfWasHanged = NO;
}

-(void)killMagicPrefs:(id)sender{
    if (pingReply == NO && selfWasHanged == NO) {
        system("killall 'MagicPrefs'");
        [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(startMagicPrefs:) userInfo:nil repeats:NO];         
    }
}

-(void)startMagicPrefs:(id)sender{
	if ([MPSafeguard isAppRunning:@"MagicPrefs"] == NO) {
        NSString *appPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.vladalexa.MagicPrefs"];        
		if (appPath != nil){	
			NSLog(@"%@",[NSString stringWithFormat:@"MagicPrefs hanged and was restarted by MPSafeguard from %@.",appPath]);
            [[NSWorkspace sharedWorkspace] launchApplicationAtURL:[NSURL URLWithString:appPath] options:NSWorkspaceLaunchDefault configuration:nil error:nil];            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MPpluginsEvent" object:nil userInfo:
             [NSDictionary dictionaryWithObjectsAndKeys:@"doAlert",@"what",@"MagicPrefs hanged and was restarted by MPSafeguard.",@"title",@"This most likely means there are conflicts with other software, see MPSafeguard's preferences.",@"text",@"OK",@"action",nil]
             ];            
		}else{
			NSLog(@"Failed to find MagicPrefs.app");
		}			
	}else{
        NSLog(@"MPSafeguard failed to kill MagicPrefs");
    }   	            
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
