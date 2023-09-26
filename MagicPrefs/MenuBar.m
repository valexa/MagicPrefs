//
//  MenuBar.m
//  MagicPrefs
//
//  Created by Vlad Alexa on 11/23/09.
//  Copyright 2009 NextDesign. All rights reserved.
//

#import "MenuBar.h"
#import "MainWindow.h"
#import "IORegInterface.h"

#import "QuartzCore/CIFilter.h"

@implementation MenuBar

- (id)init{	
	if (self) {
		
		//NSLog(@"MenuBar init");	
		
		//register for notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MPcoreMenuEvent" object:nil];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MPcoreMenuEvent" object:nil suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];	
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"VAUserDefaultsUpdate" object:nil suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];		
		
		//load defaults
		defaults = [NSUserDefaults standardUserDefaults];		
              	
		BOOL boo = [defaults boolForKey:@"noMenubarIcon"];	
		if (boo) {					
			NSLog(@"Found 'noMenubarIcon', not showing icon");			
		}else{
			[self loadIcon];			
            [self loadMenu];
		}					
	
	}	
	return self;
}

-(void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self]; 
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];  
    [super dealloc];    
}

-(void)theEvent:(NSNotification*)notif{	
	if ([[notif name] isEqualToString:@"VAUserDefaultsUpdate"]) {	
		if ([[notif object] isEqualToString:@"com.vladalexa.MagicPrefs"]){	
			[defaults synchronize];	
			[self loadMenu];	
		}					
	}	
	if (![[notif name] isEqualToString:@"MPcoreMenuEvent"]) {		
		return;
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){
		if ([[notif object] isEqualToString:@"ReloadMenu"]){
			[self loadMenu];			
		}
		if ([[notif object] isEqualToString:@"RefreshBattery"]){
            [self setBatteryIcon:[defaults objectForKey:@"menubarIcon"]];			
		}
		if ([[notif object] isEqualToString:@"CritBattery"]){
            [self setBatteryIcon:@"crit"];			
		}		
		if ([[notif object] isEqualToString:@"IconOFF"]){
			[_statusItem setImage:[NSImage imageNamed:@"mbar_off"]];	
			[_statusItem setTitle:@""];	
			NSDockTile *tile = [[NSApplication sharedApplication] dockTile];
			[tile setBadgeLabel:@"off"];			
		}		
		if ([[notif object] isEqualToString:@"IconON"]){
            [_statusItem setImage:[NSImage imageNamed:@"mbar"]];
            [_statusItem setAlternateImage:[NSImage imageNamed:@"mbar_"]]; 
            [_statusItem setToolTip:@"MagicPrefs"];                
            [self setBatteryIcon:[defaults objectForKey:@"menubarIcon"]];
            [_statusItem setTitle:@""];            
			NSDockTile *tile = [[NSApplication sharedApplication] dockTile];
			[tile setBadgeLabel:@"on"];			
		}
		if ([[notif object] isEqualToString:@"IconERR"]){
			[_statusItem setImage:[NSImage imageNamed:@"mbar_err"]];
			[_statusItem setTitle:@""];	
			NSDockTile *tile = [[NSApplication sharedApplication] dockTile];
			[tile setBadgeLabel:@"err"];				
		}
		if ([[notif object] isEqualToString:@"IconZZ"]){
			[_statusItem setImage:[NSImage imageNamed:@"mbar_sleep"]];		
			[_statusItem setTitle:@""];	
			NSDockTile *tile = [[NSApplication sharedApplication] dockTile];
			[tile setBadgeLabel:@"zzZ"];			
		}
		if ([[notif object] isEqualToString:@"IconDIM"]){
			[_statusItem setImage:[NSImage imageNamed:@"mbar_dim"]];		
			[_statusItem setTitle:@""];	
			NSDockTile *tile = [[NSApplication sharedApplication] dockTile];
			[tile setBadgeLabel:@"offsync"];			
		}        
		if ([[notif object] isEqualToString:@"IconToggle"]){
			[self togMenuBar:nil];			
		}		
	}			
}

#pragma mark actions

-(void)choseIcon:(id)sender{
    if ([[sender title] isEqualToString:@"Display MagicPrefs logo"]) {
        [defaults setObject:@"default" forKey:@"menubarIcon"];
    }
    if ([[sender title] isEqualToString:@"Display Magic Mouse battery"]) {
        [defaults setObject:@"mm" forKey:@"menubarIcon"];
        int mm_battery_new = [[IORegInterface mm_getStringForProperty:@"BatteryPercent"] intValue];
        if (mm_battery_new > 0) {
            NSDictionary *db = [self editNestedDict:[defaults objectForKey:@"dataBase"] setObject:[NSString stringWithFormat:@"%i",mm_battery_new] forKeyHierarchy:[NSArray arrayWithObjects:@"mm",@"batteryLevel",nil]];
            [defaults setObject:db forKey:@"dataBase"];        
        }
    }
    if ([[sender title] isEqualToString:@"Display Magic Trackpad battery"]) {
        [defaults setObject:@"mt" forKey:@"menubarIcon"];        
        int mt_battery_new = [[IORegInterface mt_getStringForProperty:@"BatteryPercent"] intValue];  
        if (mt_battery_new > 0) {
            NSDictionary *db = [self editNestedDict:[defaults objectForKey:@"dataBase"] setObject:[NSString stringWithFormat:@"%i",mt_battery_new] forKeyHierarchy:[NSArray arrayWithObjects:@"mt",@"batteryLevel",nil]];
            [defaults setObject:db forKey:@"dataBase"];        
        }        
    }       
    [defaults synchronize];    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMenuEvent" object:@"IconON" userInfo:nil];
}

- (void) loadPrefPane:(id)sender{
	NSString *pathToPrefPaneBundle = [NSString stringWithFormat:@"%@/Library/PreferencePanes/MagicPrefs.prefPane",NSHomeDirectory()];
	NSBundle *prefBundle = [NSBundle bundleWithPath: pathToPrefPaneBundle];
	Class prefPaneClass = [prefBundle principalClass];
	NSPreferencePane *prefPaneObject = [[prefPaneClass alloc] initWithBundle:prefBundle];
	
	if ( [prefPaneObject loadMainView] ) {
		[prefPaneObject willSelect];
		[[[NSApp keyWindow] contentView] addSubview:[prefPaneObject mainView]];
		[prefPaneObject didSelect];
	} else {
		NSLog(@"Error loading main view from %@",pathToPrefPaneBundle);
	}
	[prefPaneObject release];
}

- (void) openMouse:(id)sender {
	[[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/Mouse.prefPane"];
}

- (void) openPrefs:(id)sender {		
	[[NSWorkspace sharedWorkspace] openFile:[NSString stringWithFormat:@"%@/Library/PreferencePanes/MagicPrefs.prefPane",NSHomeDirectory()]];
}

- (void) checkUpdate:(id)sender {
	//alloc updater (done in nib)	
	//SUUpdater *updater = [SUUpdater updaterForBundle:[NSBundle mainBundle]];
	//SUUpdater *updater = [SUUpdater sharedUpdater];
	[updater checkForUpdates:nil];
}

- (void) actionQuit:(id)sender {
	[[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
	[NSApp terminate:sender];
}

- (void) loadPreset:(id)sender {	
	NSString *title = [[sender title] stringByReplacingOccurrencesOfString:@" ❖" withString:@""];
	NSDictionary *dict = [[defaults objectForKey:@"presets"] objectForKey:title];
	for (id key in dict){
		[defaults setObject:[dict objectForKey:key] forKey:key];		
	}	
	[defaults synchronize];	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"SyncSpeed" userInfo:nil];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneMainEvent" object:@"SyncUI" userInfo:nil];	
}

- (void) togglePlugin:(id)sender {	
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"LaunchPluginsHost" userInfo:nil];    
	NSArray *disable = [[sender title] componentsSeparatedByString:@"✔ Disable "];
	NSArray *enable = [[sender title] componentsSeparatedByString:@"✘ Enable "];
	NSString *pluginName = nil;
	NSNumber *state = nil;
	NSString *action = nil;	
	if ([enable count] == 2) {
		pluginName = [enable objectAtIndex:1];
		state = [NSNumber numberWithBool:YES];
		action = @"enabled";
	}else if ([disable count] == 2) {
		pluginName = [disable objectAtIndex:1];		
		state = [NSNumber numberWithBool:NO];		
		action = @"disabled";		
	}
	if (pluginName) {
		//save the settings ourselves and just tell the plugins app to restart instead of sending (enablePlugin) or (disablePlugin)		
		NSMutableDictionary *dict = [[[defaults persistentDomainForName:@"com.vladalexa.MagicPrefs.MagicPrefsPlugins"] objectForKey:pluginName] mutableCopy];
		[dict setObject:state forKey:@"enabled"];
		
		CFStringRef appID = CFSTR("com.vladalexa.MagicPrefs.MagicPrefsPlugins");
		CFPreferencesSetValue((CFStringRef)pluginName,dict,appID,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);
		CFPreferencesSynchronize(appID,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);		
		
		[dict release];	
        
        //launch if not running (and any plugins enabled) or restart (quit if no plugins enabled) if allready running        
        if ([MainWindow isAppRunning:@"MagicPrefsPlugins"] == NO) {	
            [MainWindow launchPluginIfAnyEnabled];
            sleep(1);
        }else{
            [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPpluginsEvent" object:@"doRestart" userInfo:nil];            
        }         

		//notify		
		NSString *growlTitle = [NSString stringWithFormat:@"Plugin %@",action];
		NSString *growlMessage = [NSString stringWithFormat:@"The %@ plugin was %@",pluginName,action];	
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPpluginsEvent" object:nil userInfo:
		 [NSDictionary dictionaryWithObjectsAndKeys:@"doGrowl",@"what",growlTitle,@"title",growlMessage,@"message",nil]
		 ];	

		//reload itself		
		[defaults synchronize];	
		[self loadMenu];
	}else {
		NSLog(@"Failed to determine plugin name for %@",[sender title]);
	}	
}

- (void) showAbout:(id)sender {		
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"ShowAbout" userInfo:nil];
}

- (void) togMenuBar:(id)sender {		
	BOOL boo = [defaults boolForKey:@"noMenubarIcon"];	
	if (boo) {					
		//NSLog(@"setting 'noMenuBar' FALSE");	
		[defaults setBool:NO forKey:@"noMenubarIcon"];
		[self loadIcon];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMenuEvent" object:@"IconON" userInfo:nil];		
	}else{
		//NSLog(@"setting 'noMenuBar' TRUE");		
		[defaults setBool:YES forKey:@"noMenubarIcon"];	
		[[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
	}	
	
	[defaults synchronize];	
	[self loadMenu];	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneMainEvent" object:@"SyncUI" userInfo:nil];	
}

- (void) togCtrlZoom:(id)sender {   
    /*   
    NSString *accessPlist = [NSString stringWithFormat:@"%@/Library/Preferences/com.apple.universalaccess.plist",NSHomeDirectory()];         
    NSString *trackpadPlist = [NSString stringWithFormat:@"%@/Library/Preferences/com.apple.driver.AppleBluetoothMultitouch.trackpad.plist",NSHomeDirectory()];      
	NSMutableDictionary	*access = [NSMutableDictionary dictionaryWithContentsOfFile:accessPlist];
	NSMutableDictionary	*trackpad = [NSMutableDictionary dictionaryWithContentsOfFile:trackpadPlist];    
    if ([[access objectForKey:@"closeViewScrollWheelToggle"] boolValue] == NO) {
        [access setObject:[NSNumber numberWithBool:YES] forKey:@"closeViewScrollWheelToggle"];
        [access setObject:[NSNumber numberWithInt:262144] forKey:@"closeViewScrollWheelModifiersInt"];
        [trackpad setObject:[NSNumber numberWithInt:262144] forKey:@"HIDScrollZoomModifierMask"];        
        [access writeToFile:accessPlist atomically:YES];
        [trackpad writeToFile:trackpadPlist atomically:YES];        
    }else{
        [access setObject:[NSNumber numberWithBool:NO] forKey:@"closeViewScrollWheelToggle"];
        [access setObject:[NSNumber numberWithInt:0] forKey:@"closeViewScrollWheelModifiersInt"];
        [trackpad setObject:[NSNumber numberWithInt:0] forKey:@"HIDScrollZoomModifierMask"];        
        [access writeToFile:accessPlist atomically:YES];
        [trackpad writeToFile:trackpadPlist atomically:YES];                
    }
    */
    NSString *accessPlist = [NSString stringWithFormat:@"%@/Library/Preferences/com.apple.universalaccess.plist",NSHomeDirectory()];     
    if ([[[NSDictionary dictionaryWithContentsOfFile:accessPlist] objectForKey:@"closeViewScrollWheelToggle"] boolValue] == NO) {
        [self saveCFPrefs:[NSNumber numberWithBool:YES] forKey:@"closeViewScrollWheelToggle" domain:@"com.apple.universalaccess"];
        [self saveCFPrefs:[NSNumber numberWithInt:262144] forKey:@"closeViewScrollWheelModifiersInt" domain:@"com.apple.universalaccess"]; 
        [self saveCFPrefs:[NSNumber numberWithInt:262144] forKey:@"HIDScrollZoomModifierMask" domain:@"com.apple.driver.AppleBluetoothMultitouch.trackpad"];           
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"UniversalAccessDomainCloseViewSettingsDidChangeNotification" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1],@"closeViewScrollWheelToggle",nil]];        
    }else{
        [self saveCFPrefs:[NSNumber numberWithBool:NO] forKey:@"closeViewScrollWheelToggle" domain:@"com.apple.universalaccess"];
        [self saveCFPrefs:[NSNumber numberWithInt:0] forKey:@"closeViewScrollWheelModifiersInt" domain:@"com.apple.universalaccess"]; 
        [self saveCFPrefs:[NSNumber numberWithInt:0] forKey:@"HIDScrollZoomModifierMask" domain:@"com.apple.driver.AppleBluetoothMultitouch.trackpad"];                
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"UniversalAccessDomainCloseViewSettingsDidChangeNotification" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0],@"closeViewScrollWheelToggle",nil]];        
    }    						    
	[self loadMenu];		
}

- (void) togEnabled:(id)sender {		
	BOOL boo = [defaults boolForKey:@"isDisabled"];	
	if (boo) {					
		//NSLog(@"setting 'isDisabled' FALSE");	
		[defaults setBool:NO forKey:@"isDisabled"];		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"SyncSpeed" userInfo:nil];			
		[_statusItem setImage:[NSImage imageNamed:@"mbar"]];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreEventsEvent" object:@"Enable" userInfo:nil];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneImgEvent" object:@"remote" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"default.png",@"back",@"hover",@"what",nil]];						
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"doNotif",@"what",@"square",@"image",@"MagicPrefs enabled",@"text",nil]];			
	}else{
		//NSLog(@"setting 'isDisabled' TRUE");		
		[defaults setBool:YES forKey:@"isDisabled"];
		[_statusItem setImage:[NSImage imageNamed:@"mbar_off"]];		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"RestoreMouseSpeed" userInfo:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"RestoreTrackpadSpeed" userInfo:nil];		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreEventsEvent" object:@"Disable" userInfo:nil];		
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneImgEvent" object:@"remote" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"disabled.png",@"back",@"hover",@"what",nil]];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"doNotif",@"what",@"square",@"image",@"MagicPrefs disabled",@"text",nil]];		
	}	
	
	[defaults synchronize];	
	[self loadMenu];	
}

- (void) togAutostart:(id)sender {			
	BOOL noAutostart = [defaults boolForKey:@"noAutostart"];	
	if (noAutostart) {					
		//NSLog(@"setting 'noAutostart' FALSE");	
		[defaults setBool:NO forKey:@"noAutostart"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"AutostartON" userInfo:nil];		
	}else{
		//NSLog(@"setting 'noAutostart' TRUE");
		[defaults setBool:YES forKey:@"noAutostart"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"AutostartOFF" userInfo:nil];				
	}	
	
	[defaults synchronize];	
	[self loadMenu];
}

- (void) togCapsLock:(id)sender {			
	BOOL boo = [defaults boolForKey:@"notifCapsLock"];	
	if (boo) {					
		//NSLog(@"setting 'notifCapsLock' FALSE");	
		[defaults setBool:NO forKey:@"notifCapsLock"];		
	}else{
		//NSLog(@"setting 'notifCapsLock' TRUE");
		[defaults setBool:YES forKey:@"notifCapsLock"];				
	}	
	
	[defaults synchronize];	
	[self loadMenu];
}

- (void) togStatistics:(id)sender {			
	BOOL boo = [defaults boolForKey:@"gatherStatistics"];	
	if (boo) {						
		[defaults setBool:NO forKey:@"gatherStatistics"];		
	}else{
		[defaults setBool:YES forKey:@"gatherStatistics"];				
	}	
	
	[defaults synchronize];	
	[self loadMenu];
}

- (void) togStatisticsGraph:(id)sender {			
	BOOL boo = [defaults boolForKey:@"graphicalStatistics"];	
	if (boo) {						
		[defaults setBool:NO forKey:@"graphicalStatistics"];
        [defaults synchronize];	        
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"RestartSelf" userInfo:nil];		
	}else{
		[defaults setBool:YES forKey:@"graphicalStatistics"];				
        [defaults synchronize];	
        [self loadMenu];        
	}	
}

- (void) togOSXGestures:(id)sender {			
	BOOL boo = [defaults boolForKey:@"generateOSXGestures"];	
	if (boo) {						
		[defaults setBool:NO forKey:@"generateOSXGestures"];	        	
	}else{
		[defaults setBool:YES forKey:@"generateOSXGestures"];				    
	}	
    [defaults synchronize];	
    [self loadMenu];        
}

# pragma mark functions

-(void)loadIcon{
	//init icon
	_statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
	[_statusItem setHighlightMode:YES];
	[_statusItem setToolTip:@"MagicPrefs"];
	[_statusItem setImage:[NSImage imageNamed:@"mbar_off"]];
	[_statusItem setAlternateImage:[NSImage imageNamed:@"mbar_"]];	
	[_statusItem setDoubleAction:@selector(openPrefs:)]; //ignored if there is a menu
	[_statusItem setTarget:self];    
}

-(void)setBatteryIcon:(NSString*)type{
    
    if ([type isEqualToString:@"default"]) return;
    
    if ([type isEqualToString:@"crit"]) {
        NSImage *batt = [self NSImageFromPDF:@"battery.pdf" size:CGSizeMake(13,18) page:6];
        [_statusItem setImage:batt];
        [_statusItem setAlternateImage:[self applyCIFilter:@"CIColorInvert" toImage:batt]];
        return;
    }
    
    NSString *level = [[[defaults objectForKey:@"dataBase"] objectForKey:type] objectForKey:@"batteryLevel"];    
    
    if (level) {
        int page = 5;
        if ([level intValue] > 15) page = 4;        
        if ([level intValue] > 25) page = 3;        
        if ([level intValue] > 50) page = 2;
        if ([level intValue] > 75) page = 1;
        NSImage *batt = [self NSImageFromPDF:@"battery.pdf" size:CGSizeMake(13,18) page:page];
        [_statusItem setImage:batt];
        [_statusItem setAlternateImage:[self applyCIFilter:@"CIColorInvert" toImage:batt]];
        [_statusItem setToolTip:[NSString stringWithFormat:@"~%@%%",level]];         
    }else{
        NSLog(@"Unable to create battery icon for %@",type);
    }       
}

-(void)loadMenu{
    lastRefresh = CFAbsoluteTimeGetCurrent();   
	NSMenu *menu = [self newMenu];
    menu.delegate = self;
	[_statusItem setMenu:menu];
	[menu release]; 
}

- (NSMenu *) newMenu
{
	NSZone *menuZone = [NSMenu menuZone];
	NSMenu *menu = [[NSMenu allocWithZone:menuZone] init];
	[menu setAutoenablesItems:NO];
	NSMenuItem *menuItem;
	NSMenu *presetsSubMenu;
	NSMenu *pluginsSubMenu;
	NSMenu *statsSubMenu; 
	NSMenu *iconSubMenu;     
	
	menuItem = [menu addItemWithTitle:@"Preferences" action:@selector(openPrefs:) keyEquivalent:@""];
	[menuItem setTarget:self];

	presetsSubMenu = [self newPresetsMenu];
	menuItem = [menu addItemWithTitle:@"Import preset" action:nil keyEquivalent:@""];	
	[menuItem setSubmenu:presetsSubMenu];
	[presetsSubMenu release];

	pluginsSubMenu = [self newPluginsMenu];
	menuItem = [menu addItemWithTitle:@"Plugins" action:nil keyEquivalent:@""];	
	[menuItem setSubmenu:pluginsSubMenu];	
	[pluginsSubMenu release];
	
    statsSubMenu = [self newStatsMenu];
	menuItem = [menu addItemWithTitle:@"Statistics" action:nil keyEquivalent:@""];	
	[menuItem setSubmenu:statsSubMenu];	
	[statsSubMenu release];
    
    iconSubMenu = [self newIconMenu];
	menuItem = [menu addItemWithTitle:@"Configure Icon" action:nil keyEquivalent:@""];	
	[menuItem setSubmenu:iconSubMenu];	
	[iconSubMenu release];    
	
	// Add Separator
	[menu addItem:[NSMenuItem separatorItem]];	
		
	NSString *title;
	BOOL boo;	
	boo = [defaults boolForKey:@"isDisabled"];		
	if (boo) {					
		  title = @"Enable MagicPrefs";			
	}else{
		  title = @"Disable MagicPrefs";	
	}	
	menuItem = [menu addItemWithTitle:title action:@selector(togEnabled:)	keyEquivalent:@""];	
	[menuItem setTarget:self];
		
	boo = [defaults boolForKey:@"noAutostart"];	
	if (boo) {					
		title = @"Enable autostart";
	}else{
		title = @"Disable autostart";		
	}	
	menuItem = [menu addItemWithTitle:title action:@selector(togAutostart:)	keyEquivalent:@""];		
	[menuItem setTarget:self];	
	
	boo = [defaults boolForKey:@"notifCapsLock"];	
	if (boo) {					
		title = @"Disable capslock notification";
	}else{
		title = @"Enable capslock notification";		
	}	
	menuItem = [menu addItemWithTitle:title action:@selector(togCapsLock:)	keyEquivalent:@""];	
	[menuItem setTarget:self];	
    
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.universalaccess"];		
    if ([[dict objectForKey:@"closeViewScrollWheelToggle"] boolValue] == NO) { 								
		title = @"Enable Ctrl+scroll to zoom screen";        
	}else{
		title = @"Disable Ctrl+scroll to zoom screen";        	
	}	
	menuItem = [menu addItemWithTitle:title action:@selector(togCtrlZoom:)	keyEquivalent:@""];	
	[menuItem setTarget:self];	    
    
	boo = [defaults boolForKey:@"generateOSXGestures"];	
	if (boo) {					
		title = @"Do not also generate native pinch/rotates";        
	}else{		
		title = @"Also generate native pinch/rotates";        
	}	
	menuItem = [menu addItemWithTitle:title action:@selector(togOSXGestures:)	keyEquivalent:@""];	
	[menuItem setTarget:self];    
		
	// Add Separator
	[menu addItem:[NSMenuItem separatorItem]];		
	
	menuItem = [menu addItemWithTitle:@"Update Check" action:@selector(checkUpdate:) keyEquivalent:@""];		
	[menuItem setTarget:self];			
	
	menuItem = [menu addItemWithTitle:@"About" action:@selector(showAbout:) keyEquivalent:@""];
	NSString *toolTip = [NSString stringWithFormat:@"%@(%@)",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
	[menuItem setToolTip:toolTip];	
	[menuItem setTarget:self];	
	
	menuItem = [menu addItemWithTitle:@"Quit MagicPrefs" action:@selector(actionQuit:) keyEquivalent:@""];
	[menuItem setTarget:self];	
	
	//menuItem = [menu addItemWithTitle:@"[Debug Run Prefpane Directly]" action:@selector(loadPrefPane:) keyEquivalent:@""];
	//[menuItem setTarget:self];	
	
	return menu;
}

-(NSMenu *)newIconMenu{
	NSMenu *subMenu = [[NSMenu alloc] initWithTitle:@"Configure Icon"];	
    
    NSMenuItem *menuItem = [subMenu addItemWithTitle:@"Display MagicPrefs logo" action:@selector(choseIcon:) keyEquivalent:@""];
    [menuItem setTarget:self];	
    
    if ([defaults boolForKey:@"noMouse"] == NO) {
		NSMenuItem *menuItem = [subMenu addItemWithTitle:@"Display Magic Mouse battery" action:@selector(choseIcon:) keyEquivalent:@""];
		[menuItem setTarget:self];	        
    }
    if ([defaults boolForKey:@"noTrackpad"] == NO) {
		NSMenuItem *menuItem = [subMenu addItemWithTitle:@"Display Magic Trackpad battery" action:@selector(choseIcon:) keyEquivalent:@""];
		[menuItem setTarget:self];	        
    } 
    
	return subMenu;
}

-(NSMenu *)newPresetsMenu{
	NSMenu *subMenu = [[NSMenu alloc] initWithTitle:@"Presets"];	
	NSDictionary *dict = [defaults objectForKey:@"presets"];
	NSString *title;
	for (NSString *key in dict){
		title = key;
		for (NSDictionary *p in [defaults objectForKey:@"presetApps"]){
			if ([[p objectForKey:@"type"] isEqualToString:key]){
				title = [NSString stringWithFormat:@"%@ ❖",key];
			}
		}
		NSMenuItem *menuItem = [subMenu addItemWithTitle:title action:@selector(loadPreset:) keyEquivalent:@""];
		[menuItem setTarget:self];		
	}	
	return subMenu;
}

-(NSMenu *)newPluginsMenu{
	NSMenu *subMenu = [[NSMenu alloc] initWithTitle:@"Plugins"];	
	NSDictionary *dict = [defaults persistentDomainForName:@"com.vladalexa.MagicPrefs.MagicPrefsPlugins"];
	NSString *title = nil;	
	for (NSString *key in dict){
		NSDictionary *d = [dict objectForKey:key];
		if ([d isKindOfClass:[NSDictionary class]]) {
            if ([self doesPluginExist:key dict:d] != YES) continue;            
			BOOL enabled = [[d objectForKey:@"enabled"] boolValue];            
			if (enabled) {
				title = [NSString stringWithFormat:@"✔ Disable %@",key];
			}else {
				title = [NSString stringWithFormat:@"✘ Enable %@",key];			
			}
			NSMenuItem *menuItem = [subMenu addItemWithTitle:title action:@selector(togglePlugin:) keyEquivalent:@""];
			[menuItem setTarget:self];					
		}	
	}	
	return subMenu;
}

-(NSMenu *)newStatsMenu{
	NSMenu *subMenu = [[NSMenu alloc] initWithTitle:@"Statistics"];	
    NSString *title;
    NSString *graphtitle = @"Disable statistics graph in dock";    
	if ([defaults boolForKey:@"gatherStatistics"]) {					
        if ([defaults boolForKey:@"noMouse"] == NO) {
            [self makeStatsSubmenu:subMenu device:@"mm" name:@"Magic Mouse"];
        }
        if ([defaults boolForKey:@"noTrackpad"] == NO) {
            [self makeStatsSubmenu:subMenu device:@"mt" name:@"Magic Trackpad"];  
        }        
        if ([defaults boolForKey:@"noGlassTrackpad"] == NO) {
            [self makeStatsSubmenu:subMenu device:@"gt" name:@"Trackpad"];  
        }                  
        if ([defaults boolForKey:@"graphicalStatistics"] == NO) {
                graphtitle = @"Enable statistics graph in dock";
        }        
        NSMenuItem *menuItem = [subMenu addItemWithTitle:graphtitle action:@selector(togStatisticsGraph:)	keyEquivalent:@""];	
        [menuItem setTarget:self];        
		title = @"Disable";		
	}else{
		title = @"Enable";        
	}	
	NSMenuItem *menuItem = [subMenu addItemWithTitle:title action:@selector(togStatistics:)	keyEquivalent:@""];	
	[menuItem setTarget:self];                

	return subMenu;
}

-(void)makeStatsSubmenu:(NSMenu*)subMenu device:(NSString*)device name:(NSString*)name{
    NSDictionary *d = [[defaults objectForKey:@"dataBase"] objectForKey:device];        
    if (d && [d isKindOfClass:[NSDictionary class]]) {
        NSMenuItem *menuItem = [subMenu addItemWithTitle:name action:nil keyEquivalent:@""];	
        NSMenu *subSubMenu = [[[NSMenu alloc] initWithTitle:device] autorelease];            
        [subMenu setSubmenu:subSubMenu forItem:menuItem];            
        for (NSString *kind in d) {
            NSDictionary *k = [d objectForKey:kind];        
            if ([k isKindOfClass:[NSDictionary class]]) {
                NSMenuItem *menuItem = [subSubMenu addItemWithTitle:[self humanizeKind:kind steps:[d objectForKey:@"batterySteps"]] action:nil keyEquivalent:@""];	 
                NSMenu *subSubSubMenu = [[[NSMenu alloc] initWithTitle:kind] autorelease];                     
                [subSubMenu setSubmenu:subSubSubMenu forItem:menuItem];  
                for (NSString *value in k) {
                    NSString *title = [NSString stringWithFormat:@"%@:%@",value,[self humanizeCount:[k objectForKey:value]]];
                    [subSubSubMenu addItemWithTitle:title action:nil keyEquivalent:@""];	                             
                }                    
            }                                
        }             
        
    }
}

-(NSString*)humanizeCount:(NSString*)count{
    int c = [count intValue];
    if (c > 1000){
        count = [NSString stringWithFormat:@"%ik",c/1000];
    }
    if (c > 1000000){
        count = [NSString stringWithFormat:@"%.1fm",c/1000000.0];
    }        
    if (c > 1000000000){
        count = [NSString stringWithFormat:@"%.1fb",c/1000000000.0];
    }        
    return count;
}

-(NSString*)humanizeKind:(NSString*)kind steps:(NSString*)steps{
    if ([kind isEqualToString:@"perMinute"]) return @"Per Minute";
    if ([kind isEqualToString:@"perHour"]) return @"Per Hour";
    if ([kind isEqualToString:@"perDay"]) return @"Per Day";
    if ([kind isEqualToString:@"perBattery"]) return [NSString stringWithFormat:@"Per Battery (%i%% accuracy)",[steps intValue]*-1];    
    return kind;
}

-(BOOL)doesPluginExist:(NSString*)name dict:(NSDictionary*)pluginDict{
        
    NSString *pluginPath = [pluginDict objectForKey:@"path"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:pluginPath]) {
        //NSLog(@"Plugin found at %@",pluginPath);
        return YES;
    }    
    //NSLog(@"Plugin %@ not found at %@",name,pluginPath);    
    return NO;
}

-(NSImage *)NSImageFromPDF:(NSString*)fileName size:(CGSize)size page:(size_t)pageNum{
	CFURLRef pdfURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), (CFStringRef)fileName, NULL, NULL);	
	if (pdfURL) {		
		CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL(pdfURL);
		CFRelease(pdfURL);				
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, size.width, size.height, 8, 4 * size.width, colorSpace, kCGImageAlphaPremultipliedFirst);
		if (context == NULL) {			
			NSLog(@"Could not create context for %@",fileName);			
			return nil;				
		}   
		//translate the context to NSImage coords (0,0 from upper left corner to bottom left corner)
		CGContextTranslateCTM(context, 0, size.height);	
		CGContextScaleCTM(context, 1, -1);		
		CGContextSaveGState(context);	
		//scale to our desired size
		CGPDFPageRef page = CGPDFDocumentGetPage(pdf, pageNum); 
		CGAffineTransform pdfTransform = CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, CGRectMake(0, 0, size.width, size.height), 180, true);
		CGContextConcatCTM(context, pdfTransform);
		CGContextDrawPDFPage(context, page);	
		//return autoreleased NSImage 
        CGImageRef img = CGBitmapContextCreateImage(context);  
		NSImage *ret = [self newNSImageFromCGImage:img]; 
        CFRelease(img);
		CGContextRestoreGState(context);        
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
		CGPDFDocumentRelease(pdf);   		
		return [ret autorelease];		
	}else {
		NSLog(@"Could not load %@",fileName);
	}
	return nil;	
}

- (NSImage*)newNSImageFromCGImage:(CGImageRef)cgImage{
	NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
	NSImage *image = [[NSImage alloc] init];
	[image addRepresentation:bitmapRep];
	[bitmapRep release];
	return image;
}

-(NSImage*)applyCIFilter:(NSString*)name toImage:(NSImage*)source{
    NSImage *ret = nil;
    CIImage *image = [CIImage imageWithData:[source TIFFRepresentation]];    
    
    //apply the filter
    CIFilter *filter = [CIFilter filterWithName:name];
    [filter setValue:image forKey:@"inputImage"];
    image = [filter valueForKey:@"outputImage"];
    
    //make the output
    NSCIImageRep *imageRep = [NSCIImageRep imageRepWithCIImage:image];    
    ret = [[NSImage alloc] initWithSize:[imageRep size]];
    [ret addRepresentation:imageRep];
    
    return [ret autorelease];
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
            //NSLog(@"loading %@",key); 
        }else{
            //NSLog(@"changing %@",key);
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
        //NSLog(@"saving %@",[hierarchy objectAtIndex:c]);        
    }
    
    return parent;
}

-(void)saveCFPrefs:(id)object forKey:(NSString*)key domain:(NSString*)domain{
	if (![[object class] isKindOfClass:[NSObject class]]) {
		NSLog(@"The value to be set for %@ is not a object",key);
		return;
	}  	
	
	CFPreferencesSetValue((CFStringRef)key,object,(CFStringRef)domain,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);
	CFPreferencesSynchronize((CFStringRef)domain,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);
}

#pragma mark NSMenuDelegate

- (void)menuNeedsUpdate:(NSMenu *)oldMenu{ 
    //prevent overupdating and MenuMaster loop bug
    float interval = CFAbsoluteTimeGetCurrent() - lastRefresh;
    if (interval > 1) {       
        [self loadMenu];        
    }
}

@end
