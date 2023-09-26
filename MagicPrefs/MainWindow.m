//
//  MainWindow.m
//  MagicPrefs
//
//  Created by Vlad Alexa on 1/3/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "MainWindow.h"

@implementation MainWindow

- (id)init{	
	if (self) {
		//NSLog(@"Main Window init");	
		[(NSApplication*)NSApp setDelegate:self];	
		
		//register for notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MPcoreMainEvent" object:nil];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MPcoreMainEvent" object:nil suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];		
		
		//register with growl
		NSArray *arr = [NSArray arrayWithObject:@"MagicPrefsGrowlNotif"]; 	
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"GrowlApplicationRegistrationNotification" object:nil userInfo:
		 [NSDictionary dictionaryWithObjectsAndKeys:@"MagicPrefs",@"ApplicationName",
		  arr,@"AllNotifications",
		  arr,@"DefaultNotifications",
		  nil]
		 ];		
			
	}	
	return self;
}	

-(void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self]; 
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];     
	[events release]; 
    [dockIconImage release];
    [super dealloc];    
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification {

	//NSLog(@"App finished launching");	
		
	if ([self driverCheck] == FALSE) {
		[NSTimer scheduledTimerWithTimeInterval:50 target:NSApp selector:@selector(terminate:) userInfo:nil repeats:NO];
	}
		
	if ([[self getBIDOfParent] isEqualToString:@"com.apple.loginwindow"]){
		[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(appInitRoutines:) userInfo:@"com.apple.loginwindow" repeats:NO];		
	}else {
		[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(appInitRoutines:) userInfo:NSUserName() repeats:NO];				
	}	
	
}	

- (void)applicationWillTerminate:(NSNotification *)aNotification{

	//NSLog(@"App will terminate");		
	
	//restore old tracking speeds
	SpeedInterface *speedInterface = [[SpeedInterface alloc] init];						
    float mouse = [[defaults objectForKey:@"TrackingMouse_old"] floatValue];    
    [speedInterface setMouseSpeed:mouse];
    NSLog(@"Restored mouse tracking speed to %f",mouse);

    float trackpad = [[defaults objectForKey:@"TrackingTrackpad_old"] floatValue];    
    [speedInterface setTrackpadSpeed:trackpad];
    NSLog(@"Restored trackpad tracking speed to %f",trackpad);        

	[speedInterface release];	
	
	//save zero PID on clean exit
	[defaults setInteger:0 forKey:@"PID"];
    
    //clear badge so it does not remain in LaunchPad
    NSDockTile *tile = [[NSApplication sharedApplication] dockTile];
    [tile setBadgeLabel:nil];    
	
	//kill plugins
	system("killall 'MagicPrefsPlugins'");
	
}

- (void)awakeFromNib{ 
	//NSLog(@"Main Window awoke from nib");	
}	

-(void)windowDidLoad {
	//NSLog(@"Main Window loaded");
}

-(void)appInitRoutines:(id)sender{
				
	NSDictionary *dict;
	
	//alloc updater (done in nib)
	//SUUpdater *updater = [SUUpdater updaterForBundle:[NSBundle mainBundle]];	
	//SUUpdater *updater = [SUUpdater sharedUpdater];	
	
	//alloc defaults
	defaults = [NSUserDefaults standardUserDefaults];	
	
	//
	////check for framework, never runs as dyld crashes on load when not finding framework even tho it is a weak link
	//
	if (![[NSFileManager defaultManager] fileExistsAtPath:@"/System/Library/PrivateFrameworks/MultitouchSupport.framework/Versions/A/MultitouchSupport"]) {	
		[alertButton setTitle:@"OK"];
		[alertMainText setTitleWithMnemonic:@"Multitouch driver missing"];
		[alertSmallText setTitleWithMnemonic:@"You need to upgrade to OSX 10.6.2+ or manually install the Wireless Mouse Update/Magic Trackpad MultiTouch Update"];			
		[alertWindow makeKeyAndOrderFront:nil];
		[NSApp arrangeInFront:alertWindow];
	}
    
    //remove login item if service exists
    NSString *plist = [@"~/Library/LaunchAgents/com.vladalexa.MagicPrefs.plist" stringByExpandingTildeInPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:plist]) [self removeLoginItem];

	//
	////move magicprefs to /Applications if it resides elsewhere
	//   
    if (![[self getBIDOfParent] isEqualToString:@"com.apple.dt.Xcode"]) {
        //do not move it if we launch it with xcode
        NSString *wantedPath = @"/Applications/MagicPrefs.app";
        NSString *appPath = [[NSBundle mainBundle] bundlePath];
        if ([appPath pathComponents] > 0){		
            if (![[[appPath pathComponents] objectAtIndex:1] isEqualToString:@"Applications"]) {
                if ([defaults boolForKey:@"noAppRelocation"] != YES) {
                    if ([self movedHelper:appPath moveTo:wantedPath] == YES) {
                        [self growlNotif:@"Application relocated" message:@"MagicPrefs was moved to /Applications"];   
                        [NSTask launchedTaskWithLaunchPath:@"/Applications/MagicPrefs.app/Contents/MacOS/MagicPrefs" arguments:[NSArray array]];
                        [NSApp terminate:self];                    
                    }				
                }
            }
        }else{
            NSLog(@"Failed to determine path for self");
        }        
    }        
    	
	//
	////copy pref pane from bundle on every run
	//
	
	[self copyPrefPane:@"MagicPrefs.prefPane"];
			
	
	//
	////CHECKS
	//
		
	//force auto update setting on	
	if ([defaults boolForKey:@"SUAutomaticallyUpdate"]) {					
		//NSLog(@"Found 'SUAutomaticallyUpdate' on");	
	}else{	
		[updater setAutomaticallyChecksForUpdates:YES];		
		//NSLog(@"seting autoupdate true");			
	}		
	
    [updater setAutomaticallyDownloadsUpdates:NO]; //disable auto installing because it just copies them to temp and never applies		
	
	//check for update
	if ([defaults boolForKey:@"noStartUpCheck"]) {					
		NSLog(@"Found 'noStartUpCheck', not checking updates on launch");			
	}else{
		[updater checkForUpdatesInBackground]; //checks and gets update but never promts the user to install it if setAutomaticallyDownloadsUpdates:YES 
		//[updater checkForUpdates:nil]; //always works but if there is no update it nags the user about it with a dialog
		//NSLog(@"checking for update at launch");		
	}		
	
	//set autostart
	if ([defaults boolForKey:@"noAutostart"]) {					
        [self setAutostart:NO];
	}else{
        [self setAutostart:YES];        
	}
	
	//copy presets from bundle to user if user has none
	if ([defaults objectForKey:@"presets"] == nil){		
		dict = [NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Resources/presets.plist"]];													 		
		[defaults setObject:dict forKey:@"presets"];		
		[welcomeWindow makeKeyAndOrderFront:nil];
		[NSApp arrangeInFront:welcomeWindow];						
		//NSLog(@"copy presets");			
	}	
	
	//copy defaults preset from bundle plist to user plist on every launch		
	[self syncDefaultPreset:@"presets"];	
	
	//set default preset if nothing set yet
	if ([defaults objectForKey:@"bindings"] == nil){		
		dict = [[defaults objectForKey:@"presets"] objectForKey:@"Default"];
		for (id key in dict){
			[defaults setObject:[dict objectForKey:key] forKey:key];		
		}	
		//NSLog(@"init defaults");				
	}
	
	//check for presetApps
	if ([defaults objectForKey:@"presetApps"] == nil){
		[defaults setObject:[[[NSArray alloc] init] autorelease] forKey:@"presetApps"];			
	}		
	
	//check for customTargets
	if ([defaults objectForKey:@"customTargets"] == nil){
		[defaults setObject:[[[NSArray alloc] init] autorelease] forKey:@"customTargets"];			
	}	
	
	//check for scrolling
	if ([defaults objectForKey:@"scrolling"] == nil){
		[defaults setObject:[[[defaults objectForKey:@"presets"] objectForKey:@"Default"] objectForKey:@"scrolling"] forKey:@"scrolling"];			
	}
	
	//check for scroll zone
	if ([defaults objectForKey:@"scrollzone"] == nil){
		[defaults setObject:[[[defaults objectForKey:@"presets"] objectForKey:@"Default"] objectForKey:@"scrollzone"] forKey:@"scrollzone"];			
	}	
	
	//check for zones
	if ([defaults objectForKey:@"zones"] == nil){
		[defaults setObject:[[[defaults objectForKey:@"presets"] objectForKey:@"Default"] objectForKey:@"zones"] forKey:@"zones"];
	}
    
    //add some default apps
    NSMutableArray *customTargets = [NSMutableArray arrayWithArray:[defaults objectForKey:@"customTargets"]];
    if (floor(NSAppKitVersionNumber) <= 1038){
        //pre 10.7      
        NSDictionary *exposeDict = [NSDictionary dictionaryWithObjectsAndKeys:@"/Applications/Utilities/Expose.app",@"name",@"/Applications/Utilities/Expose.app",@"value",@"app",@"type", nil];
        NSDictionary *spacesDict = [NSDictionary dictionaryWithObjectsAndKeys:@"/Applications/Utilities/Spaces.app",@"name",@"/Applications/Utilities/Spaces.app",@"value",@"app",@"type", nil];
        NSDictionary *dashboardDict = [NSDictionary dictionaryWithObjectsAndKeys:@"/Applications/Dashboard.app",@"name",@"/Applications/Dashboard.app",@"value",@"app",@"type", nil];
        if (![customTargets containsObject:exposeDict]) [customTargets addObject:exposeDict];
        if (![customTargets containsObject:spacesDict]) [customTargets addObject:spacesDict];
        if (![customTargets containsObject:dashboardDict]) [customTargets addObject:dashboardDict];        
    }else{
        //10.7
        NSDictionary *missionDict = [NSDictionary dictionaryWithObjectsAndKeys:@"/Applications/Mission Control.app",@"name",@"/Applications/Mission Control.app",@"value",@"app",@"type", nil];
        NSDictionary *launchpadDict = [NSDictionary dictionaryWithObjectsAndKeys:@"/Applications/Launchpad.app",@"name",@"/Applications/Launchpad.app",@"value",@"app",@"type", nil];
        NSDictionary *dashboardDict = [NSDictionary dictionaryWithObjectsAndKeys:@"/Applications/Dashboard.app",@"name",@"/Applications/Dashboard.app",@"value",@"app",@"type", nil];
        if (![customTargets containsObject:missionDict]) [customTargets addObject:missionDict];
        if (![customTargets containsObject:launchpadDict]) [customTargets addObject:launchpadDict];
        if (![customTargets containsObject:dashboardDict]) [customTargets addObject:dashboardDict];        
    }   
    [defaults setObject:customTargets forKey:@"customTargets"];
       
	SpeedInterface *speedInterface = [[SpeedInterface alloc] init];
    //set mouse tracking to current
	if ([defaults objectForKey:@"TrackingMouse"] == nil){
        [defaults setFloat:[speedInterface mouseCurrSpeed] forKey:@"TrackingMouse"];
    }
    //set trackpad tracking to current
	if ([defaults objectForKey:@"TrackingTrackpad"] == nil){
        [defaults setFloat:[speedInterface trackpadCurrSpeed] forKey:@"TrackingTrackpad"];
    }
    [speedInterface release];
      
	if ([defaults objectForKey:@"tapSensMacbook"] == nil) [defaults setInteger:10 forKey:@"tapSensMacbook"];
	if ([defaults objectForKey:@"tapSensTrackpad"] == nil) [defaults setInteger:10 forKey:@"tapSensTrackpad"];
	if ([defaults objectForKey:@"tapSensMouse"] == nil) [defaults setInteger:10 forKey:@"tapSensMouse"];    
    			
	//remove garbage	    
    [defaults removeObjectForKey:@"flaggedTaps"];        
    [defaults removeObjectForKey:@"TrackingMacbook"];    
	[defaults removeObjectForKey:@"pluginsAutoUpdate"];	    
	[defaults removeObjectForKey:@"no1FScroll"];	
	[defaults removeObjectForKey:@"oldTracking"];	
	[defaults removeObjectForKey:@"Tracking"];	
	[defaults removeObjectForKey:@"tapSens"];					
	[defaults removeObjectForKey:@"Live"];	
	[defaults removeObjectForKey:@"MagicMenuPrefPane"];
	//mm
	[defaults removeObjectForKey:@"mm_Delay"];
	[defaults removeObjectForKey:@"mm_Disabled"];
	[defaults removeObjectForKey:@"mm_SelectSens"];
	[defaults removeObjectForKey:@"mm_Trigger"];
	[defaults removeObjectForKey:@"mm_bindings"];
	[defaults removeObjectForKey:@"mm_presetApps"];	
	[defaults removeObjectForKey:@"mm_presets"];	 
	
	//set no mouse 
	[defaults setBool:YES forKey:@"noMouse"];

	//set no trackpad 
	[defaults setBool:YES forKey:@"noTrackpad"];
	
	//set no macbook 
	[defaults setBool:YES forKey:@"noGlassTrackpad"];	
	
	//turn off live
	[defaults setBool:NO forKey:@"LiveMouse"];
	[defaults setBool:NO forKey:@"LiveTrackpad"];
	[defaults setBool:NO forKey:@"LiveMacbook"];	
	
	//enable
	[defaults setBool:NO forKey:@"isDisabled"];	
    
    //statistics
	if ([defaults objectForKey:@"gatherStatistics"] == nil) [defaults setBool:NO forKey:@"gatherStatistics"];	    
	if ([defaults objectForKey:@"graphicalStatistics"] == nil) [defaults setBool:YES forKey:@"graphicalStatistics"];	    
    
    //icon
	if ([defaults objectForKey:@"menubarIcon"] == nil) [defaults setObject:@"default" forKey:@"menubarIcon"];	    
	
	//savePID
	[defaults setInteger:[[NSProcessInfo processInfo] processIdentifier] forKey:@"PID"];	
	
	//sync the defaults
	[defaults synchronize];	
	
	//sync prefpane
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneMainEvent" object:@"SyncUI" userInfo:nil];	
	
	//sync menu
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMenuEvent" object:@"ReloadMenu" userInfo:nil];		
	
	//print driver version
	NSLog(@"%@",[self driverVer]);	
		
	//aloc events deathtrap last		
	events = [[Events alloc] init];		
	
	//print my version
	NSString *msg = [NSString stringWithFormat:@"Magicprefs %@ (%@) loaded on OSX %@ by %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],[[NSProcessInfo processInfo] operatingSystemVersionString],[sender userInfo]];
	NSLog(@"%@",msg);	
	
    //register plugins
    if ([defaults objectForKey:@"knownPlugins"] == nil){
        NSString *path = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Resources/MagicPrefsPlugins.app"];	    
        NSURL *url = [NSURL fileURLWithPath:path];
        OSStatus err = LSRegisterURL((CFURLRef)url,TRUE);        
        if (err == kLSNoRegistrationInfoErr) {
            NSLog(@"Failed to LSRegisterURL '%@': The item does not contain info requiring registration",path);                    
        } else if (err == kLSDataErr) {
            NSLog(@"Failed to LSRegisterURL '%@': The item's property list info is malformed",path);                    
        } else if (err != noErr) {
            NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:(NSInteger)err userInfo:nil];
            NSLog(@"Failed to LSRegisterURL '%@': %@", path,[error description]);                    
        }else{
            NSLog(@"Registered plugins handler %@",path);        
        }          
    }  
    
	//launch plugins
	if ([MainWindow isAppRunning:@"MagicPrefsPlugins"] == NO) {	
        [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(launchPluginIfAnyEnabled) userInfo:nil repeats:NO];        
	}
	
	savedMouseTracking = NO;
	savedTrackpadTracking = NO;	
}

#pragma mark onload stuff

- (void)launchPluginIfAnyEnabled
{
    [MainWindow launchPluginIfAnyEnabled];
}

+ (void)launchPluginIfAnyEnabled{
    NSDictionary *pluginsDict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.vladalexa.MagicPrefs.MagicPrefsPlugins"];
    for (NSString *name in pluginsDict) {
        BOOL enabled = [[[pluginsDict objectForKey:name] objectForKey:@"enabled"] boolValue];
        if (enabled == YES) {             
            [[NSWorkspace sharedWorkspace] launchApplication:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Resources/MagicPrefsPlugins.app"]];
            break;
        }
    }    
}


- (SInt32) osxVersion{
	SInt32 version = 0;
	OSStatus rc0 = Gestalt(gestaltSystemVersion, &version);
	if(rc0 == 0){
		//NSLog(@"gestalt version=%x", version);						
	}else{
		//NSLog(@"Failed to get os version");
	}	
    return version;	
}

-(void)theEvent:(NSNotification*)notif{	
	if (![[notif name] isEqualToString:@"MPcoreMainEvent"]) {		
		return;
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){
		if ([[notif object] isEqualToString:@"RestartPluginsHost"]){
            if ([MainWindow isAppRunning:@"MagicPrefsPlugins"] == YES) {
                system("killall 'MagicPrefsPlugins'");                
            }             
            [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(launchPlugins) userInfo:nil repeats:NO];            
		}        
		if ([[notif object] isEqualToString:@"LaunchPluginsHost"]){
            if ([MainWindow isAppRunning:@"MagicPrefsPlugins"] == NO) {
                [self launchPlugins];
            }    
		}  
		if ([[notif object] isEqualToString:@"RestartSelf"]){
            if ([MainWindow isAppRunning:@"MagicPrefsPlugins"] == NO) {
                [[NSWorkspace sharedWorkspace] launchApplication:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Resources/MagicPrefsPlugins.app"]];
                [NSThread sleepForTimeInterval:2];                
            } 
            if ([MainWindow isAppRunning:@"MagicPrefsPlugins"] == YES) {
                [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPpluginsEvent" object:@"restartMagicPrefs" userInfo:nil];                 
            }else{
                NSLog(@"MagicPrefsPlugins took too long to start");
            }  
		}  
		if ([[notif object] isEqualToString:@"PrefPaneDeleted"]){         
           [NSThread sleepForTimeInterval:1];            
            NSInteger alertResult = [[NSAlert alertWithMessageText:@"You have deleted the MagicPrefs preferences pane" defaultButton:@"Yes" alternateButton:@"No" otherButton:nil informativeTextWithFormat:@"Do you want to also move the MagicPrefs application to trash along with all your settings and presets ?"] runModal];                
            if ( alertResult == NSAlertDefaultReturn ) {
                [self doUninstall];
            }
		}        
		if ([[notif object] isEqualToString:@"AutostartON"]){
			[self setAutostart:YES];
		}
		if ([[notif object] isEqualToString:@"AutostartOFF"]){
			[self setAutostart:NO];
		}	
		if ([[notif object] isEqualToString:@"Terminate"]){
            [NSApp terminate:nil];
		}        
		if ([[notif object] isEqualToString:@"ShowAbout"]){		
			[aboutWindow makeKeyAndOrderFront:nil];
			[NSApp arrangeInFront:aboutWindow];
		}
		if ([[notif object] isEqualToString:@"SyncSpeed"]){	
			SpeedInterface *speedInterface = [[SpeedInterface alloc] init];			
			//save the old tracking			
			if (savedMouseTracking != YES) {
				[defaults setFloat:[speedInterface mouseCurrSpeed] forKey:@"TrackingMouse_old"];		
				[defaults synchronize];
				savedMouseTracking = YES;				
			}
			if (savedTrackpadTracking != YES) {
				[defaults setFloat:[speedInterface trackpadCurrSpeed] forKey:@"TrackingTrackpad_old"];		
				[defaults synchronize];
				savedTrackpadTracking = YES;				
			}			
			//set our own tracking
			if ([defaults boolForKey:@"noMouse"] == NO) {
				[speedInterface setMouseSpeed:[[defaults objectForKey:@"TrackingMouse"] floatValue]];
				NSLog(@"Set mouse tracking speed to %@",[defaults objectForKey:@"TrackingMouse"]);
			}
			if ([defaults boolForKey:@"noTrackpad"] == NO ) {
				[speedInterface setTrackpadSpeed:[[defaults objectForKey:@"TrackingTrackpad"] floatValue]];
				NSLog(@"Set trackpad tracking speed to %@",[defaults objectForKey:@"TrackingTrackpad"]);
			}					
			[speedInterface release];
		}		
		if ([[notif object] isEqualToString:@"RestoreMouseSpeed"]){				
			SpeedInterface *speedInterface = [[SpeedInterface alloc] init];	
			[speedInterface setMouseSpeed:[[defaults objectForKey:@"TrackingMouse_old"] floatValue]];				
			NSLog(@"Restored mouse tracking speed");			
			[speedInterface release];			
			savedMouseTracking = NO;			
		}
		if ([[notif object] isEqualToString:@"RestoreTrackpadSpeed"]){				
			SpeedInterface *speedInterface = [[SpeedInterface alloc] init];	
			[speedInterface setTrackpadSpeed:[[defaults objectForKey:@"TrackingTrackpad_old"] floatValue]];								
			NSLog(@"Restored trackpad tracking speed");	
			[speedInterface release];			
			savedTrackpadTracking = NO;			
		}		
	}			
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]]){
		if ([[[notif userInfo] objectForKey:@"what"] isEqualToString:@"doAlert"]){
			[alertButton setTitle:[[notif userInfo] objectForKey:@"action"]];
			[alertMainText setTitleWithMnemonic:[[notif userInfo] objectForKey:@"title"]];
			[alertSmallText setTitleWithMnemonic:[[notif userInfo] objectForKey:@"text"]];			
			[alertWindow makeKeyAndOrderFront:nil];
			[NSApp arrangeInFront:alertWindow];	
		}	
		if ([[[notif userInfo] objectForKey:@"what"] isEqualToString:@"doNotif"]){
			[notifImage setImage:[NSImage imageNamed:[[notif userInfo] objectForKey:@"image"]]];
			[notifText setTitleWithMnemonic:[[notif userInfo] objectForKey:@"text"]];	
			[notifWindow setAlphaValue:1.0];
			[notifWindow setIgnoresMouseEvents:YES];
            [notifDisabled setHidden:YES];
            if ([[[notif userInfo] objectForKey:@"text"] rangeOfString:@"Disable" options:NSCaseInsensitiveSearch].location != NSNotFound) [notifDisabled setHidden:NO];
			[notifWindow orderFront:nil];
			[NSApp arrangeInFront:notifWindow];	
			[NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(hideNotif) userInfo:nil repeats:NO];				
		}
        if ([[[notif userInfo] objectForKey:@"what"] isEqualToString:@"doGrowl"]){	
			NSString *title = [[notif userInfo] objectForKey:@"title"];
			NSString *message = [[notif userInfo] objectForKey:@"message"];			
			[self growlNotif:title message:message];
		}
		if ([[[notif userInfo] objectForKey:@"what"] isEqualToString:@"ping"]){
            NSString *source = [[notif userInfo] objectForKey:@"source"]; 
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:source object:nil userInfo:
			 [NSDictionary dictionaryWithObjectsAndKeys:@"pong",@"what",@"MPcoreMainEvent",@"source",nil]
			 ];	            
		}  
		if ([[[notif userInfo] objectForKey:@"what"] isEqualToString:@"showDockImage"]){			
			NSString *imagePath = [[notif userInfo] objectForKey:@"path"];		
            NSImage *iconImage = [[NSImage alloc] initWithContentsOfFile:imagePath];
            int GRAPH_SIZE = 128;
            if ([iconImage isValid]) {
                //hide dock tile if it is set
                NSDockTile *tile = [[NSApplication sharedApplication] dockTile];
                if ([tile badgeLabel] != nil) [tile setBadgeLabel:nil];
                // display dock icon	
                if (dockIconImage == nil) {
                    dockIconImage = [[NSImage alloc] initWithSize:NSMakeSize(GRAPH_SIZE, GRAPH_SIZE)];                    
                    ProcessSerialNumber psn = { 0, kCurrentProcess };
                    TransformProcessType(&psn, kProcessTransformToForegroundApplication);
                }
                // set the (scaled) application icon    
                float inc = GRAPH_SIZE * (1.0 - 0.1); // icon scaling
                [iconImage lockFocus];
                [dockIconImage drawInRect:NSMakeRect(inc, inc, GRAPH_SIZE - 2 * inc, GRAPH_SIZE - 2 * inc) fromRect:NSMakeRect(0, 0, GRAPH_SIZE, GRAPH_SIZE) operation:NSCompositeCopy fraction:1.0];
                [iconImage unlockFocus];
                [NSApp setApplicationIconImage:iconImage];                 
            }else{
                NSLog(@"Invalid image at %@",imagePath);
            }                  
            [iconImage release];            
		}        
	}	
}

-(void) hideNotif{
	[notifWindow setAlphaValue:0.9];	
	[NSThread sleepForTimeInterval:0.1];	
	[notifWindow setAlphaValue:0.8];		
	[NSThread sleepForTimeInterval:0.1];
	[notifWindow setAlphaValue:0.7];	
	[NSThread sleepForTimeInterval:0.1];	
	[notifWindow setAlphaValue:0.6];	
	[NSThread sleepForTimeInterval:0.1];		
	[notifWindow setAlphaValue:0.5];	
	[NSThread sleepForTimeInterval:0.1];
	[notifWindow setAlphaValue:0.4];	
	[NSThread sleepForTimeInterval:0.1];	
	[notifWindow setAlphaValue:0.3];	
	[NSThread sleepForTimeInterval:0.1];	
	[notifWindow setAlphaValue:0.2];	
	[notifWindow orderOut:nil];	
}

-(void) growlNotif:(NSString*)title message:(NSString*)message
{
    if (!title || !message) {
        NSLog(@"Growl with empty %@ / %@",title,message);
        return;
    }
    NSUserNotification *notif = [[NSUserNotification alloc] init];
    if (notif) {
        [notif setTitle:title];
        [notif setInformativeText:message];
        NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
        [center deliverNotification:notif];
        [notif release];
    }else {
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"GrowlNotification" object:nil userInfo:
         [NSDictionary dictionaryWithObjectsAndKeys:@"MagicPrefs",@"ApplicationName",@"MagicPrefsGrowlNotif",@"NotificationName",title,@"NotificationTitle",message,@"NotificationDescription",nil]
         ];
    }
}

#pragma mark about window stuff

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key { 
    if ([key isEqualToString: @"versionString"]) return YES; 
    return NO; 
} 

- (NSString *)versionString {
	NSString *sv = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	NSString *v = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];	
	return [NSString stringWithFormat:@"version %@ (%@)",sv,v];	
}

- (IBAction) openWebsite:(id)sender{
	NSURL *url = [NSURL URLWithString:@"http://magicprefs.com"];
	[[NSWorkspace sharedWorkspace] openURL:url];
	[[NSApp keyWindow] close];
}

- (NSString *)driverVer{
	NSDictionary *dict = [[NSString stringWithContentsOfFile:@"/System/Library/PrivateFrameworks/MultitouchSupport.framework/Versions/A/Resources/version.plist" encoding:NSUTF8StringEncoding error:nil] propertyList];													 
	NSString *ret = [NSString stringWithFormat: @"Driver version %@ - %@ (%@)",[dict objectForKey:@"CFBundleShortVersionString"],[dict objectForKey:@"CFBundleVersion"],[dict objectForKey:@"SourceVersion"]];
	return ret;
}

#pragma mark alert window stuff

- (IBAction) alertAction:(id)sender{
	if ([[sender title] isEqualToString:@"Open Bluetooth"]) {
		[[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/Bluetooth.prefPane"];	
	}
	if ([[sender title] isEqualToString:@"Open Keyboard"]) {
		[[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/Keyboard.prefPane"];	
	}	
	if ([[sender title] isEqualToString:@"Open Appearance"]) {
		[[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/Appearance.prefPane"];	
	}		
	[[NSApp keyWindow] close];
}

#pragma mark main app start actions

- (void)copyPrefPane:(NSString*)name{
	//quit system preferences (if running bugs ensue)
	if ([MainWindow appWasLaunched:@"com.apple.systempreferences"]){
		system("killall 'System Preferences'");
	}	
	NSString *folder = [NSString stringWithFormat:@"%@/Library/PreferencePanes",NSHomeDirectory()];	
	NSString *copyFrom = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:name];	
	NSString *copyTo = [NSString stringWithFormat:@"%@/%@",folder,name];	
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:folder]) {			
		BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:TRUE attributes:nil error:nil];
		if (success == FALSE) {
			NSLog(@"Failed to create folder (%@).",folder);
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMenuEvent" object:@"IconERR" userInfo:nil];			
		}else {
			NSLog(@"Created folder (%@).",folder);
		}					
	}	
	if ([[NSFileManager defaultManager] fileExistsAtPath:copyTo]) {	
		BOOL success = [[NSFileManager defaultManager] removeItemAtPath:copyTo error:nil];	
		if (success == FALSE) {
			NSLog(@"Failed to delete old preferences pane (%@).",copyTo);
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMenuEvent" object:@"IconERR" userInfo:nil];			
		}		
	}	
	BOOL success = [[NSFileManager defaultManager] copyItemAtPath:copyFrom toPath:copyTo error:nil];
	if (success == FALSE) {
		NSLog(@"Failed to copy preferences pane (%@ to %@).",copyFrom,copyTo);
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMenuEvent" object:@"IconERR" userInfo:nil];		
		[alertButton setTitle:@"OK"];
		[alertMainText setTitleWithMnemonic:@"MagicPrefs was unable to install the preferences pane"];
		[alertSmallText setTitleWithMnemonic:@"You will not have access to the MagicPrefs preferences, make sure ~/Library/PreferencePanes is writable then restart MagicPrefs."];			
		[alertWindow makeKeyAndOrderFront:nil];
		[NSApp arrangeInFront:alertWindow];		
	}
}

-(void)syncDefaultPreset:(NSString*)what{
	//overwrite default preset of user with one from bundle
	NSDictionary *pDict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:what ofType:@"plist"]];
	//add it to existing	
	NSMutableDictionary *dict = [[defaults objectForKey:what] mutableCopy];	
	[dict setObject:[pDict objectForKey:@"Default"] forKey:@"Default"];
	//save
	[defaults setObject:dict forKey:what];		
	[defaults synchronize];
	[dict release];
}

- (void)doUninstall{
    NSString *path = [NSString stringWithFormat:@"%@/MagicPrefsUninstall.sh",NSTemporaryDirectory()];
    NSString *runcmd = [NSString stringWithFormat:@"/usr/bin/nohup %@ &",path];
    NSString *chmodcmd = [NSString stringWithFormat:@"/bin/chmod +x %@",path];  
    NSString *supportPath = [NSString stringWithFormat:@"%@/Library/Application Support/MagicPrefs",NSHomeDirectory()];
    NSString *pref1Path = [NSString stringWithFormat:@"%@/Library/Preferences/com.vladalexa.MagicPrefs.plist",NSHomeDirectory()];
    NSString *pref2Path = [NSString stringWithFormat:@"%@/Library/Preferences/com.vladalexa.MagicPrefs.MagicPrefsPlugins.plist",NSHomeDirectory()];    
    NSString *str = [NSString stringWithFormat:@"#!/bin/sh\nsleep 5\n /usr/bin/osascript -e 'tell application \"Finder\" to delete POSIX file \"%@\"\n tell application \"Finder\" to delete POSIX file \"%@\"\n tell application \"Finder\" to delete POSIX file \"%@\"\n tell application \"Finder\" to delete POSIX file \"%@\" '",[[NSBundle mainBundle] bundlePath],supportPath,pref1Path,pref2Path];
	BOOL success = [str writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
	if (success) {
        [self setAutostart:NO];
        system([chmodcmd UTF8String]);        
        system([runcmd UTF8String]);
        [NSApp terminate:nil]; 	
	}else{
        NSLog(@"Failed to run uninstaller at %@",[NSString stringWithFormat:@"%@/MagicPrefsUninstall.sh",NSTemporaryDirectory()]);
    }    
}

-(BOOL) driverCheck{
	//get driver version
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/PrivateFrameworks/MultitouchSupport.framework/Versions/A/Resources/version.plist"];
	NSString *ver = [dict objectForKey:@"CFBundleVersion"];
	BOOL known = NO;
	BOOL bad = NO;	
	//10.5:19x 10.6:20x 10.7:22x 10.8:23x
	if ([ver isEqualToString:@"194.28"] || //10.5 driver version
		[ver isEqualToString:@"204.9"] ||  //jan 2010
		[ver isEqualToString:@"204.12.1"] || //mar 2010
		[ver isEqualToString:@"204.13"] ||   //apr 2010
		[ver isEqualToString:@"205.34"] || //aug 2010 (trackpad support from 205.34 on)
		[ver isEqualToString:@"207.10"] || //nov 2010
		[ver isEqualToString:@"207.11"] || //jul 2011		
		[ver isEqualToString:@"220.62"] || //jan 2011  
		[ver isEqualToString:@"220.62.1"] ||  //oct 2011
		[ver isEqualToString:@"231.4"] ||  //10.7.4 jun 2012
		[ver isEqualToString:@"235.12"] ||  //10.8 DP1
		[ver isEqualToString:@"235.16"] || //10.8 DP2 (broke tyler's routine)
        [ver isEqualToString:@"235.20"] || //10.8 DP3
        [ver isEqualToString:@"235.27"] || //10.8 GM
        [ver isEqualToString:@"235.28"] || //10.8.2
        [ver isEqualToString:@"304.10"]  //10.11.2
        ) {
		known = YES; 
	}
	if ([ver isEqualToString:@"189.32"] || [ver isEqualToString:@"189.35"] || [ver isEqualToString:@"200.20"] ) {
		bad = YES;
	}	
	
	if (bad == YES) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:
		 [NSDictionary dictionaryWithObjectsAndKeys:@"doAlert",@"what",
		  [NSString stringWithFormat:@"The apple driver version %@ found is not supported",ver],@"title",
		  @"The Magic Mouse requires 10.5.8 or later with Wireless Mouse Software Update 1.0 (http://support.apple.com/kb/DL951), the Magic Trackpad 10.6.5 or the Magic Trackpad MultiTouch Update",@"text",
		  @"Ok",@"action",
		  nil]
		 ];	
		return NO;		
	}else {
		if (known == NO) {
			//NSLog(@"Unseen before driver version (%@)",ver);
		}		
	}	
	
	return YES;
}

- (BOOL)movedHelper:(NSString*)moveFrom moveTo:(NSString*)moveTo{
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:@"/Applications"]) {			
		NSLog(@"/Applications/ folder does not exist");
		return NO;
	}	
	if ([[NSFileManager defaultManager] fileExistsAtPath:moveTo]) {	
		BOOL success = [[NSFileManager defaultManager] removeItemAtPath:moveTo error:nil];	
		if (success == NO) {
			NSLog(@"Failed to delete old (%@).",moveTo);
			return NO;	
		}		
	}	
    NSError *err = nil;
	BOOL success = [[NSFileManager defaultManager] moveItemAtPath:moveFrom toPath:moveTo error:&err];
	if (success == NO) {
		NSLog(@"Failed to move (%@ to %@) %@.",moveFrom,moveTo,err);
		return NO;
	}else{
		NSLog(@"Moved (%@ to %@).",moveFrom,moveTo);        
    }   
    
	return YES;
}

#pragma mark process code

+(BOOL)appWasLaunched:(NSString*)bid{
	for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]){
		if ([bid isEqualToString:[app bundleIdentifier]]) {
			//NSLog(@"%@",path);
			return YES;
		}
	}	
	return NO;
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

- (void) launchPlugins{
    BOOL success = [[NSWorkspace sharedWorkspace] launchApplication:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Resources/MagicPrefsPlugins.app"]];
    if (success == NO) {
        NSLog(@"ERROR:Failed to launch MagicPrefsPlugins");                    
    }else{
        NSLog(@"Launched MagicPrefsPlugins");
    }
}

-(NSString*)getBIDOfParent
{
    ProcessSerialNumber myPSN;
    GetCurrentProcess(&myPSN);    
    NSDictionary *myInfo = (NSDictionary*)ProcessInformationCopyDictionary(&myPSN,kProcessDictionaryIncludeAllInformationMask);
    ProcessSerialNumber parentPSN = { 0, [[myInfo objectForKey:@"ParentPSN"] intValue] };  
    [myInfo release];
    NSDictionary *parentInfo = (NSDictionary*)ProcessInformationCopyDictionary(&parentPSN,kProcessDictionaryIncludeAllInformationMask);
    NSString *ret = (NSString*)[parentInfo objectForKey:@"CFBundleIdentifier"];
    [parentInfo release];
    return ret;
}

#pragma mark autostart

- (void)setAutostart:(BOOL)set
{
    NSString *plist = [@"~/Library/LaunchAgents/com.vladalexa.MagicPrefs.plist" stringByExpandingTildeInPath];    
        
    if (set == YES) {
        if (![self writeServiceFile]) {
            NSLog(@"Error creating service");
            [self setLoginItem];
            return;
        }
        //[NSTask launchedTaskWithLaunchPath:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"load",plist, nil]]; not actually neded, it gets auto loaded next restart and if we do this we spawn multiples 
    }else{     
        [[NSFileManager defaultManager] removeItemAtPath:plist error:nil];
    }
}

- (BOOL)writeServiceFile
{
    NSString *path = @"/Applications/MagicPrefs.app/Contents/MacOS/MagicPrefs";
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.vladalexa.MagicPrefs"];
        if (path) path = [path stringByAppendingString:@"/Contents/MacOS/MagicPrefs"];
    }
    
    if (path == nil) {
        NSLog(@"MagicPrefs not found");
        return NO;
    }
    
    NSDictionary *plist = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"com.vladalexa.MagicPrefs",@"Label",
                           path,@"Program",
                           [NSNumber numberWithBool:YES],@"RunAtLoad",
                           [NSNumber numberWithInt:1],@"ThrottleInterval",
                           nil];    
    
    return [plist writeToFile:[@"~/Library/LaunchAgents/com.vladalexa.MagicPrefs.plist" stringByExpandingTildeInPath] atomically:YES];
}

- (void)setLoginItem
{
	CFURLRef currentPath = (CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems) {
		//remove entries of same app name
        UInt32 seedValue;
		NSArray  *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
		for (id item in loginItemsArray) {
			LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
			CFStringRef currentPathComponent = CFURLCopyLastPathComponent(currentPath);
            CFStringRef displayNameComponent = LSSharedFileListItemCopyDisplayName(itemRef);
            if (CFStringCompare(displayNameComponent,currentPathComponent,0) == kCFCompareEqualTo) {
                LSSharedFileListItemRemove(loginItems, itemRef);
                //NSLog(@"Deleting old login item %@",LSSharedFileListItemCopyDisplayName(itemRef));
            }
            CFRelease(displayNameComponent);
			CFRelease(currentPathComponent);
		}
		[loginItemsArray release];
		//add it
		LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemLast, NULL, NULL, currentPath, NULL, NULL);
		if (item){
			NSLog(@"Added login item %@",CFURLGetString(currentPath));
			CFRelease(item);
		}else{
			NSLog(@"Failed to set to autostart from %@",CFURLGetString(currentPath));
		}
		CFRelease(loginItems);
	}else{
		NSLog(@"Failed to get login items");
	}
}

- (void)removeLoginItem
{
	UInt32 seedValue;
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems) {
		//remove entries of same app
		NSArray  *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
		for (id item in loginItemsArray) {
			LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
			CFStringRef name = LSSharedFileListItemCopyDisplayName(itemRef);
			if (CFStringCompare(name,CFSTR("MagicPrefs.app"),0) == kCFCompareEqualTo){
				LSSharedFileListItemRemove(loginItems, itemRef);
				NSLog(@"Deleted login item %@",name);
			}
			CFRelease(name);
		}
		[loginItemsArray release];
		CFRelease(loginItems);
	}else{
		NSLog(@"Failed to get login items");
	}
}

@end
