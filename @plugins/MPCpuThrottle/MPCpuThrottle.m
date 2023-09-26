//
//  MPCpuThrottle.m
//  MPCpuThrottle
//
//  Created by Vlad Alexa on 9/23/10.
//  Copyright 2010 NextDesign. All rights reserved.
//
//  Example for a plugin with preferences, for a barebones example see magicprefs.com/plugins 

#define PREFS_OBSERVER_NAME_STRING @"MPPluginMPCpuThrottlePreferencesEvent"
#define OBSERVER_NAME_STRING @"MPPluginMPCpuThrottleEvent"
#define PLUGIN_NAME_STRING @"MPCpuThrottle"

#import "MPCpuThrottle.h"

#import "MPCpuThrottlePreferences.h"

static NSBundle* pluginBundle = nil;

@implementation MPCpuThrottle

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
		preferences = [[MPCpuThrottlePreferences alloc] initWithNibName:@"MPCpuThrottlePreferences" bundle:pluginBundle];	
		NSString *bundleId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];					
		if ([bundleId isEqualToString:@"com.apple.systempreferences"]) return self;	
		
		//your initialization here (everything below is optional if you do not have settings nor define events)	
		
		//init defaults
		defaults = [NSUserDefaults standardUserDefaults];		
		
		//set your events 	
		
		//listen for events
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:OBSERVER_NAME_STRING object:nil];	
				
		//set your settings
		if ([[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"refreshFrequency"] == nil){
			[self saveSetting:@"31" forKey:@"refreshFrequency"];
		}        
                
        NSString *frequency = [[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"refreshFrequency"];
        if ([frequency intValue] > 30) {
            [NSTimer scheduledTimerWithTimeInterval:[frequency intValue] target:self selector:@selector(refresh:) userInfo:nil repeats:YES];            
        }else{
            NSLog(@"%@ frequency too high",frequency);
        }
        
		[self setupHelper];        
        
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
		if ([[notif object] isEqualToString:@"refresh"]) {
            [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(refresh:) userInfo:nil repeats:NO];
        }
	}
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]]){
       
	}    
}

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

-(void)refresh:(NSTimer*)timer
{  
    [defaults synchronize];
    NSDictionary *dict = [self dictWithPidAndBid];  
    NSDictionary *throttles = [[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"throttles"];
    for (NSString *bid in throttles) {
        NSString *pid = [dict objectForKey:bid];
        if (pid) {
            NSNumber *num = [throttles objectForKey:bid];            
            if ([num intValue] != last_max || [pid intValue] != last_pid) {
                [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"CPUThrottleEvent" object:@"Quit" userInfo:nil options:NSNotificationPostToAllSessions];             
                [self setThrottle:[num stringValue] forPid:pid];                
            }
        }
    }
    if ([throttles count] == 0) { 
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"CPUThrottleEvent" object:@"Quit" userInfo:nil options:NSNotificationPostToAllSessions];
        last_pid = 0;
        last_max = 0;
    }
}

-(NSDictionary*)dictWithPidAndBid
{
    NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithCapacity:1];
    NSArray *proc = [MPCpuThrottlePreferences getCarbonProcessList];    
    for (NSDictionary *dict in proc) {
        [ret setObject:[dict objectForKey:@"pid"] forKey:[dict objectForKey:@"bid"]];
    }
    return ret;
}


- (NSString*)installAndCheckHelper:(NSString*)copyFrom{
	
	NSString *folder = [NSString stringWithFormat:@"%@/Library/Application Support/MagicPrefs",NSHomeDirectory()];	
	NSString *copyTo = [NSString stringWithFormat:@"%@/cputhrottle",folder];	
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:folder]) {			
		BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:TRUE attributes:nil error:nil];
		if (success == FALSE) {
			NSLog(@"Failed to create folder (%@).",folder);			
		}else {
			//NSLog(@"Created folder (%@).",folder);
		}					
	}	
	if ([[NSFileManager defaultManager] fileExistsAtPath:copyTo]) {	
		//check md5
		NSString *output = [[self execTask:@"/sbin/md5" args:[NSArray arrayWithObjects:@"-q",copyTo,nil]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		NSString *md5 = @"adb5e935142b4f04a3163b6c572b8942";        
		if (output) {
			if ([output isEqualToString:md5]) {
				return copyTo;
			}else {
				NSLog(@"md5 does not match (%@) should be (%@)",output,md5);
				BOOL success = [[NSFileManager defaultManager] removeItemAtPath:copyTo error:nil];	
				if (success == FALSE) {
					NSLog(@"Failed to delete old helper (%@).",copyTo);	
				}				
			}
		}else {
			NSLog(@"could not get md5 hash");
		}	
	}	
	BOOL success = [[NSFileManager defaultManager] copyItemAtPath:copyFrom toPath:copyTo error:nil];
	if (success == FALSE) {
		NSString *message = [NSString stringWithFormat:@"Failed to copy helper (%@ to %@).",copyFrom,copyTo];
		NSLog(@"%@",message); //TODO
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MPpluginsEvent" object:@"local" userInfo:
		 [NSDictionary dictionaryWithObjectsAndKeys:@"doAlert",@"what",
		  @"Unable to install the helper",@"title",
		  message,@"text",
		  @"OK",@"action",
		  nil]
		 ];		
	}else {
		NSLog(@"Copied helper to %@",copyTo);
	}
	return copyTo;
}

-(void)setupHelper{	
	//copy it if it does not exist or if md5 does not match	
	NSString *bundlePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"cputhrottle" ofType:@""];
	NSString *helperPath = [self installAndCheckHelper:bundlePath];
	
	//check if the helper allready has the proper settings
	NSDictionary *fdict = [[NSFileManager defaultManager] attributesOfItemAtPath:helperPath error:nil];
	if ([[fdict valueForKey:@"NSFileOwnerAccountName"] isEqualToString:@"root"] && [[fdict valueForKey:@"NSFileGroupOwnerAccountName"] isEqualToString:@"admin"] && ([[fdict valueForKey:@"NSFilePosixPermissions"] intValue]==3437)) {
		return;
	} else {
		//NSLog(@"Setting rights for %@",helperPath);
	}
	
	//set them
	OSStatus status;
	AuthorizationRef authorizationRef;	
	AuthorizationFlags myFlags = kAuthorizationFlagExtendRights | kAuthorizationFlagInteractionAllowed;	
	AuthorizationItem myItems = {kAuthorizationRightExecute,0,NULL, 0};
	AuthorizationRights myRights = {1, &myItems};	
	status = AuthorizationCreate(&myRights,  kAuthorizationEmptyEnvironment, myFlags, &authorizationRef);
    
    if (status == errAuthorizationSuccess){
		char *pathChar = (char *)[helperPath cStringUsingEncoding:NSUTF8StringEncoding];
		//set owner
		char *chownPath = "/usr/sbin/chown";
		char *chownArgs[] = { "root:admin", pathChar , NULL };
		status = AuthorizationExecuteWithPrivileges(authorizationRef,chownPath,kAuthorizationFlagDefaults,chownArgs,NULL);
		if (status != errAuthorizationSuccess) {
			//NSLog(@"Set owner failed");			
		}
		//set suid-bit		
		char *chmodPath = "/bin/chmod";
		char *chmodArgs[] = { "6555", pathChar , NULL };		
		status = AuthorizationExecuteWithPrivileges(authorizationRef,chmodPath,kAuthorizationFlagDefaults,chmodArgs,NULL);
		if (status != errAuthorizationSuccess) {
			//NSLog(@"Set suid failed");			
		}	
	}else {
		NSLog(@"Authorization failed");
	}
}

-(NSString*)execTask:(NSString*)launch args:(NSArray*)args{
    //NSLog(@"Exec: %@",launch);
	NSTask *task = [[[NSTask alloc] init] autorelease];
	[task setLaunchPath:launch];
	[task setArguments:args];
	
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardOutput:pipe];
	
	NSFileHandle *file = [pipe fileHandleForReading];
	
	[task launch];
	
	NSData *data = [file readDataToEndOfFile];
	
	NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	return [string autorelease];
}

-(void)setThrottle:(NSString *)num forPid:(NSString *)pid{
	NSString *launchPath = [NSString stringWithFormat:@"%@/Library/Application Support/MagicPrefs/cputhrottle",NSHomeDirectory()];	
    NSArray *argsArray = [NSArray arrayWithObjects:pid,num,nil];    
	if (launchPath && [[NSFileManager defaultManager] fileExistsAtPath:launchPath]) {	
		NSTask *task = [[NSTask alloc] init];
		[task setLaunchPath:launchPath];
		[task setArguments:argsArray];
		[task launch];
		[task release];	
        last_pid = [pid intValue];
        last_max = [num intValue];
		NSLog(@"Throttling %@ %@",pid,num);			
	}else {
		NSLog(@"Helper binary was not found at %@",launchPath);
	}
}

@end
