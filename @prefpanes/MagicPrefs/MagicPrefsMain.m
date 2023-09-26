//
//  MagicPrefsMain.m
//  MagicPrefs
//
//  Created by Vlad Alexa on 1/3/10.
//  Copyright (c) 2010 NextDesign. All rights reserved.
//

#import "MagicPrefsMain.h"


@implementation MagicPrefsMain

- (void) mainViewDidLoad {

	//NSLog(@"mainViewDidLoad");
	
	//alloc defaults
	defaults = [[VAUserDefaults alloc] initWithPlist:@"com.vladalexa.MagicPrefs.plist"];	
	
	//launch magicprefs if not running
	if ([PluginsWindowController isAppRunning:@"MagicPrefs"] == NO) {
        NSString *appPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.vladalexa.MagicPrefs"];        
		if (appPath != nil){	
			NSLog(@"%@",[NSString stringWithFormat:@"MagicPrefs not running, attempting to start %@.",appPath]);
           	NSURL *url = [NSURL fileURLWithPath:appPath];
            [[NSWorkspace sharedWorkspace] launchApplicationAtURL:url options:NSWorkspaceLaunchDefault configuration:nil error:nil];
		}else{
			NSLog(@"Failed to find MagicPrefs.app");
		}			
	}	
			
	//register for notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MPprefpaneMainEvent" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:NSWindowWillCloseNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:NSWindowDidBecomeKeyNotification object:nil];	
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MPprefpaneMainEvent" object:nil];	
	
	//aloc sppeedinterface
	speedInterface = [[SpeedInterface alloc] init];	
		
	//alloc keymanager
	keyCodeManager = [[KeyCodeManager alloc] init];

	//alloc scrollwindow	
	scrollWindowController = [[ScrollWindowController alloc] init];
	
	//alloc pluginswindow	
	pluginsWindowController = [[PluginsWindowController alloc] init];	
	
	//load a default device view if it exists	
	if ([defaults boolForKey:@"noMouse"] != YES) {
		[parentView addSubview:mmouseView];
		[deviceToggle setSelectedSegment:0];
	}else if ([defaults boolForKey:@"noTrackpad"] != YES) {
		[parentView addSubview:mtrackpadView];
		[deviceToggle setSelectedSegment:1];		
	}else if ([defaults boolForKey:@"noGlassTrackpad"] != YES) {	
		[parentView addSubview:gtrackpadView];
		[deviceToggle setSelectedSegment:2];		
	}else {
		[deviceToggle setSelectedSegment:0];
		[self toggleDevice:deviceToggle];
	}		
	
	//alloc list of plugins
	loadedPluginsInfo = [[NSMutableDictionary alloc] init];	
    
    //complete missing zones and bindings from default
    [self addMissingFromDefault];
	
	//sync ui
	[self syncUI];	
	
	//set default selected
	//[presets selectItemWithObjectValue:@"Default"];	
	
	//turn off live
	[defaults setBool:NO forKey:@"LiveMouse"];
	[defaults setBool:NO forKey:@"LiveTrackpad"];
	[defaults setBool:NO forKey:@"LiveMacbook"];
	
	//sync
	[defaults synchronize];
			
	//set initial image
	[self syncIMG];
	
}

- (void)dealloc{   	
	[speedInterface release];
	[defaults release];
	[keyCodeManager release];
	[scrollWindowController release];
	[pluginsWindowController release];	
	[loadedPluginsInfo release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];    
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];	
	[super dealloc];    
}

-(void)willUnselect {	
	[self turnOffLive];
}

-(void)willSelect {
	[self syncUI];
}

-(void)turnOffLive{
	//turn off live
	if ([togLiveMouse state] == 1 || [togLiveTrackpad state] == 1 || [togLiveMacbook state] == 1) {
		[togLiveMouse setState:NSOffState];
		[togLiveTrackpad setState:NSOffState];
		[togLiveMacbook setState:NSOffState];		
	}
	if ([defaults boolForKey:@"LiveMouse"] || [defaults boolForKey:@"LiveTrackpad"] || [defaults boolForKey:@"LiveMacbook"]) {
		[defaults setBool:NO forKey:@"LiveMouse"];
		[defaults setBool:NO forKey:@"LiveTrackpad"];
		[defaults setBool:NO forKey:@"LiveMacbook"];	
		[defaults synchronize];			
	}	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneMainEvent" object:@"LiveOFF" userInfo:nil];	
}

/*
 -(void)noResponderFor:(SEL)keyDown {
 NSLog(@"beep"); 
 }
 */ 

- (void)awakeFromNib
{
	
	//NSLog(@"awakeFromNib");	
	
	NSMutableDictionary *fdict = [NSMutableDictionary dictionaryWithCapacity:1];	
	//track buttons changing image
    NSTrackingArea *area;	
	
	//
	//Magic Mouse
	//
	
	//clicks
	
	area = [[NSTrackingArea alloc] initWithRect:[onefaClick frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:onefaClick,@"object",@"mm",@"back",nil]];
    [onefaClick addTrackingArea:area];
    [area release];			
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.3",@"posx",@"0.7",@"posy",nil] forKey:@"1"];	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.8",@"posx",@"0.5",@"posy",nil] forKey:@"2"];	
    area = [[NSTrackingArea alloc] initWithRect:[twofClick frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofClick,@"object",@"click.png",@"image",@"mm",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
    [twofClick addTrackingArea:area];
    [area release];
	[fdict removeAllObjects];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.8",@"posx",@"0.5",@"posy",nil] forKey:@"1"];			
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.5",@"posx",@"0.7",@"posy",nil] forKey:@"2"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.1",@"posx",@"0.6",@"posy",nil] forKey:@"3"];	
    area = [[NSTrackingArea alloc] initWithRect:[threefClick frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:threefClick,@"object",@"click.png",@"image",@"mm",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
    [threefClick addTrackingArea:area];	
    [area release];	
	[fdict removeAllObjects];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.7",@"posx",@"0.5",@"posy",nil] forKey:@"1"];			
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.5",@"posx",@"0.7",@"posy",nil] forKey:@"2"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.1",@"posx",@"0.6",@"posy",nil] forKey:@"3"];		
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.9",@"posx",@"0.3",@"posy",nil] forKey:@"4"];				
    area = [[NSTrackingArea alloc] initWithRect:[fourfClick frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:fourfClick,@"object",@"click.png",@"image",@"mm",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
    [fourfClick addTrackingArea:area];
    [area release];	
	[fdict removeAllObjects];
	
	//taps
	
	area = [[NSTrackingArea alloc] initWithRect:[onefTapLeft frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:onefTapLeft,@"object",@"mm",@"back",nil]];
    [onefTapLeft addTrackingArea:area];
    [area release];
	
	area = [[NSTrackingArea alloc] initWithRect:[onefTapRight frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:onefTapRight,@"object",@"mm",@"back",nil]];
    [onefTapRight addTrackingArea:area];
    [area release];	
	
	area = [[NSTrackingArea alloc] initWithRect:[onefTapTail frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:onefTapTail,@"object",@"mm",@"back",nil]];
    [onefTapTail addTrackingArea:area];
    [area release];		
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.3",@"posx",@"0.7",@"posy",nil] forKey:@"1"];	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.8",@"posx",@"0.5",@"posy",nil] forKey:@"2"];	
    area = [[NSTrackingArea alloc] initWithRect:[twofTap frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofTap,@"object",@"tap.png",@"image",@"mm",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
    [twofTap addTrackingArea:area];
    [area release];
	[fdict removeAllObjects];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.8",@"posx",@"0.5",@"posy",nil] forKey:@"1"];			
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.5",@"posx",@"0.7",@"posy",nil] forKey:@"2"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.1",@"posx",@"0.6",@"posy",nil] forKey:@"3"];		
    area = [[NSTrackingArea alloc] initWithRect:[threefTap frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:threefTap,@"object",@"tap.png",@"image",@"mm",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
    [threefTap addTrackingArea:area];
    [area release];
	[fdict removeAllObjects];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.7",@"posx",@"0.5",@"posy",nil] forKey:@"1"];			
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.5",@"posx",@"0.7",@"posy",nil] forKey:@"2"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.1",@"posx",@"0.6",@"posy",nil] forKey:@"3"];		
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.9",@"posx",@"0.3",@"posy",nil] forKey:@"4"];				
    area = [[NSTrackingArea alloc] initWithRect:[fourfTap frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:fourfTap,@"object",@"tap.png",@"image",@"mm",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
    [fourfTap addTrackingArea:area];
    [area release];	
	[fdict removeAllObjects];	
	
	//swipes
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.32",@"posx",@"0.64",@"posy",nil] forKey:@"1"];	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.05",@"posx",@"0.6",@"posy",nil] forKey:@"2"];	
    area = [[NSTrackingArea alloc] initWithRect:[twofSwipeLeft frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofSwipeLeft,@"object",@"swipe.png",@"image",@"mm",@"back",[[fdict copy] autorelease],@"fingers",@"180",@"rotate",nil]];	
    [twofSwipeLeft addTrackingArea:area];
    [area release];
	[fdict removeAllObjects];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.32",@"posx",@"0.64",@"posy",nil] forKey:@"1"];	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.05",@"posx",@"0.6",@"posy",nil] forKey:@"2"];	
    area = [[NSTrackingArea alloc] initWithRect:[twofSwipeRight frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofSwipeRight,@"object",@"swipe.png",@"image",@"mm",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
    [twofSwipeRight addTrackingArea:area];
    [area release];
	[fdict removeAllObjects];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.30",@"posx",@"0.30",@"posy",nil] forKey:@"1"];	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.70",@"posx",@"0.35",@"posy",nil] forKey:@"2"];		
    area = [[NSTrackingArea alloc] initWithRect:[twofSwipeUp frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofSwipeUp,@"object",@"swipe.png",@"image",@"mm",@"back",[[fdict copy] autorelease],@"fingers",@"90",@"rotate",nil]];	
    [twofSwipeUp addTrackingArea:area];
    [area release];
	[fdict removeAllObjects];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.30",@"posx",@"0.30",@"posy",nil] forKey:@"1"];	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.70",@"posx",@"0.35",@"posy",nil] forKey:@"2"];	
    area = [[NSTrackingArea alloc] initWithRect:[twofSwipeDown frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofSwipeDown,@"object",@"swipe.png",@"image",@"mm",@"back",[[fdict copy] autorelease],@"fingers",@"-90",@"rotate",nil]];	
    [twofSwipeDown addTrackingArea:area];
    [area release];
	[fdict removeAllObjects];	
	
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.32",@"posx",@"0.64",@"posy",nil] forKey:@"1"];	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.05",@"posx",@"0.6",@"posy",nil] forKey:@"2"];	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.18",@"posx",@"0.24",@"posy",nil] forKey:@"3"];	
    area = [[NSTrackingArea alloc] initWithRect:[threefSwipeLeft frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:threefSwipeLeft,@"object",@"swipe.png",@"image",@"mm",@"back",[[fdict copy] autorelease],@"fingers",@"180",@"rotate",nil]];	
    [threefSwipeLeft addTrackingArea:area];
    [area release];
	[fdict removeAllObjects];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.32",@"posx",@"0.64",@"posy",nil] forKey:@"1"];	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.05",@"posx",@"0.6",@"posy",nil] forKey:@"2"];	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.18",@"posx",@"0.24",@"posy",nil] forKey:@"3"];	
    area = [[NSTrackingArea alloc] initWithRect:[threefSwipeRight frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:threefSwipeRight,@"object",@"swipe.png",@"image",@"mm",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
    [threefSwipeRight addTrackingArea:area];
    [area release];
	[fdict removeAllObjects];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.20",@"posx",@"0.25",@"posy",nil] forKey:@"1"];	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.50",@"posx",@"0.35",@"posy",nil] forKey:@"2"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.80",@"posx",@"0.25",@"posy",nil] forKey:@"3"];		
    area = [[NSTrackingArea alloc] initWithRect:[threefSwipeUp frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:threefSwipeUp,@"object",@"swipe.png",@"image",@"mm",@"back",[[fdict copy] autorelease],@"fingers",@"90",@"rotate",nil]];	
    [threefSwipeUp addTrackingArea:area];
    [area release];
	[fdict removeAllObjects];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.20",@"posx",@"0.25",@"posy",nil] forKey:@"1"];	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.50",@"posx",@"0.35",@"posy",nil] forKey:@"2"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.80",@"posx",@"0.25",@"posy",nil] forKey:@"3"];	
    area = [[NSTrackingArea alloc] initWithRect:[threefSwipeDown frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:threefSwipeDown,@"object",@"swipe.png",@"image",@"mm",@"back",[[fdict copy] autorelease],@"fingers",@"-90",@"rotate",nil]];	
    [threefSwipeDown addTrackingArea:area];
    [area release];
	[fdict removeAllObjects];	
	
	//pinch
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.2",@"posx",@"0.6",@"posy",nil] forKey:@"1"];	
	area = [[NSTrackingArea alloc] initWithRect:[twofPinchIn frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofPinchIn,@"object",@"pinch.png",@"image",@"mm",@"back",[[fdict copy] autorelease],@"fingers",nil]];
    [twofPinchIn addTrackingArea:area];
    [area release];
	[fdict removeAllObjects];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.2",@"posx",@"0.6",@"posy",nil] forKey:@"1"];	
	area = [[NSTrackingArea alloc] initWithRect:[twofPinchOut frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofPinchOut,@"object",@"pinch.png",@"image",@"mm",@"back",[[fdict copy] autorelease],@"fingers",nil]];
    [twofPinchOut addTrackingArea:area];
    [area release];
	[fdict removeAllObjects];	
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.3",@"posx",@"0.4",@"posy",nil] forKey:@"1"];	
	area = [[NSTrackingArea alloc] initWithRect:[threefPinchOut frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:threefPinchOut,@"object",@"pinch3.png",@"image",@"mm",@"back",[[fdict copy] autorelease],@"fingers",nil]];
    [threefPinchOut addTrackingArea:area];
    [area release];	
	[fdict removeAllObjects];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.3",@"posx",@"0.4",@"posy",nil] forKey:@"1"];	
	area = [[NSTrackingArea alloc] initWithRect:[threefPinchIn frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:threefPinchIn,@"object",@"pinch3.png",@"image",@"mm",@"back",[[fdict copy] autorelease],@"fingers",nil]];
    [threefPinchIn addTrackingArea:area];
    [area release];	
	[fdict removeAllObjects];	
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.05",@"posx",@"0.06",@"posy",nil] forKey:@"1"];	
	area = [[NSTrackingArea alloc] initWithRect:[dragTailLeft frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:dragTailLeft,@"object",@"dragtail.png",@"image",@"mm",@"back",[[fdict copy] autorelease],@"fingers",nil]];
    [dragTailLeft addTrackingArea:area];
    [area release];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.50",@"posx",@"0.06",@"posy",nil] forKey:@"1"];		
	area = [[NSTrackingArea alloc] initWithRect:[dragTailRight frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:dragTailRight,@"object",@"dragtail.png",@"image",@"mm",@"back",[[fdict copy] autorelease],@"fingers",@"1",@"rotate",nil]];
    [dragTailRight addTrackingArea:area];
    [area release];	
	
	//
	//Magic Trackpad
	//	
	
	//clicks		
			
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.55",@"posx",@"0.75",@"posy",nil] forKey:@"1"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.33",@"posx",@"0.60",@"posy",nil] forKey:@"2"];
    area = [[NSTrackingArea alloc] initWithRect:[twofClick2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofClick2,@"object",@"click.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
    [twofClick2 addTrackingArea:area];
    [area release];
	[fdict removeAllObjects];	
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.75",@"posx",@"0.6",@"posy",nil] forKey:@"1"];			
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.55",@"posx",@"0.75",@"posy",nil] forKey:@"2"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.33",@"posx",@"0.60",@"posy",nil] forKey:@"3"];	
    area = [[NSTrackingArea alloc] initWithRect:[threefClick2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:threefClick2,@"object",@"click.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
    [threefClick2 addTrackingArea:area];	
    [area release];	
	[fdict removeAllObjects];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.75",@"posx",@"0.6",@"posy",nil] forKey:@"1"];			
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.55",@"posx",@"0.75",@"posy",nil] forKey:@"2"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.33",@"posx",@"0.60",@"posy",nil] forKey:@"3"];		
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.85",@"posx",@"0.3",@"posy",nil] forKey:@"4"];				
    area = [[NSTrackingArea alloc] initWithRect:[fourfClick2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:fourfClick2,@"object",@"click.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
    [fourfClick2 addTrackingArea:area];
    [area release];	
	[fdict removeAllObjects];	
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.75",@"posx",@"0.6",@"posy",nil] forKey:@"1"];			
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.55",@"posx",@"0.75",@"posy",nil] forKey:@"2"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.33",@"posx",@"0.60",@"posy",nil] forKey:@"3"];		
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.85",@"posx",@"0.3",@"posy",nil] forKey:@"4"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.2",@"posx",@"0.4",@"posy",nil] forKey:@"5"];	
    area = [[NSTrackingArea alloc] initWithRect:[fiveClick2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:fiveClick2,@"object",@"click.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
    [fiveClick2 addTrackingArea:area];
    [area release];	
	[fdict removeAllObjects];	
	
	//taps	
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.55",@"posx",@"0.75",@"posy",nil] forKey:@"1"];    
	area = [[NSTrackingArea alloc] initWithRect:[onefTap2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:onefTap2,@"object",@"tap.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",nil]];
    [onefTap2 addTrackingArea:area];
    [area release];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.55",@"posx",@"0.75",@"posy",nil] forKey:@"1"];    
	area = [[NSTrackingArea alloc] initWithRect:[onefTap_2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:onefTap_2,@"object",@"tap.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",nil]];
    [onefTap_2 addTrackingArea:area];
    [area release];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.55",@"posx",@"0.75",@"posy",nil] forKey:@"1"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.33",@"posx",@"0.60",@"posy",nil] forKey:@"2"];    
	area = [[NSTrackingArea alloc] initWithRect:[twofTap2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofTap2,@"object",@"tap.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",nil]];
    [twofTap2 addTrackingArea:area];
    [area release];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.55",@"posx",@"0.75",@"posy",nil] forKey:@"1"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.33",@"posx",@"0.60",@"posy",nil] forKey:@"2"];    
	area = [[NSTrackingArea alloc] initWithRect:[twofTap_2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofTap_2,@"object",@"tap.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",nil]];
    [twofTap_2 addTrackingArea:area];
    [area release];	
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.75",@"posx",@"0.6",@"posy",nil] forKey:@"1"];			
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.55",@"posx",@"0.75",@"posy",nil] forKey:@"2"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.33",@"posx",@"0.60",@"posy",nil] forKey:@"3"];					
    area = [[NSTrackingArea alloc] initWithRect:[threefTap2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:threefTap2,@"object",@"tap.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
    [threefTap2 addTrackingArea:area];
    [area release];	
	[fdict removeAllObjects];	
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.75",@"posx",@"0.6",@"posy",nil] forKey:@"1"];			
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.55",@"posx",@"0.75",@"posy",nil] forKey:@"2"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.33",@"posx",@"0.60",@"posy",nil] forKey:@"3"];		
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.85",@"posx",@"0.3",@"posy",nil] forKey:@"4"];				
    area = [[NSTrackingArea alloc] initWithRect:[fourfTap2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:fourfTap2,@"object",@"tap.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
    [fourfTap2 addTrackingArea:area];
    [area release];	
	[fdict removeAllObjects];	
    
    //swipes
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.20",@"posx",@"0.5",@"posy",nil] forKey:@"1"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.30",@"posx",@"0.65",@"posy",nil] forKey:@"2"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.40",@"posx",@"0.5",@"posy",nil] forKey:@"3"];	
    area = [[NSTrackingArea alloc] initWithRect:[threefSwipeLeft2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:threefSwipeLeft2,@"object",@"swipe.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",@"180",@"rotate",nil]];	
    [threefSwipeLeft2 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.20",@"posx",@"0.5",@"posy",nil] forKey:@"1"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.30",@"posx",@"0.65",@"posy",nil] forKey:@"2"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.40",@"posx",@"0.5",@"posy",nil] forKey:@"3"];		
    area = [[NSTrackingArea alloc] initWithRect:[threefSwipeRight2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:threefSwipeRight2,@"object",@"swipe.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
    [threefSwipeRight2 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.25",@"posx",@"0.25",@"posy",nil] forKey:@"1"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.50",@"posx",@"0.35",@"posy",nil] forKey:@"2"];
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.75",@"posx",@"0.25",@"posy",nil] forKey:@"3"];		
    area = [[NSTrackingArea alloc] initWithRect:[threefSwipeUp2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:threefSwipeUp2,@"object",@"swipe.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",@"90",@"rotate",nil]];	
    [threefSwipeUp2 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.25",@"posx",@"0.25",@"posy",nil] forKey:@"1"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.50",@"posx",@"0.35",@"posy",nil] forKey:@"2"];
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.75",@"posx",@"0.25",@"posy",nil] forKey:@"3"];	
    area = [[NSTrackingArea alloc] initWithRect:[threefSwipeDown2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:threefSwipeDown2,@"object",@"swipe.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",@"-90",@"rotate",nil]];	
    [threefSwipeDown2 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.20",@"posx",@"0.65",@"posy",nil] forKey:@"1"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.40",@"posx",@"0.65",@"posy",nil] forKey:@"2"];
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.20",@"posx",@"0.45",@"posy",nil] forKey:@"3"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.40",@"posx",@"0.45",@"posy",nil] forKey:@"4"];	
    area = [[NSTrackingArea alloc] initWithRect:[fourfSwipeLeft2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:fourfSwipeLeft2,@"object",@"swipe.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",@"180",@"rotate",nil]];	
    [fourfSwipeLeft2 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.20",@"posx",@"0.65",@"posy",nil] forKey:@"1"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.40",@"posx",@"0.65",@"posy",nil] forKey:@"2"];
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.20",@"posx",@"0.45",@"posy",nil] forKey:@"3"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.40",@"posx",@"0.45",@"posy",nil] forKey:@"4"];	
    area = [[NSTrackingArea alloc] initWithRect:[fourfSwipeRight2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:fourfSwipeRight2,@"object",@"swipe.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
    [fourfSwipeRight2 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.18",@"posx",@"0.25",@"posy",nil] forKey:@"1"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.38",@"posx",@"0.35",@"posy",nil] forKey:@"2"];
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.58",@"posx",@"0.25",@"posy",nil] forKey:@"3"];
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.75",@"posx",@"0.14",@"posy",nil] forKey:@"4"];		
    area = [[NSTrackingArea alloc] initWithRect:[fourfSwipeUp2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:fourfSwipeUp2,@"object",@"swipe.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",@"90",@"rotate",nil]];	
    [fourfSwipeUp2 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.18",@"posx",@"0.25",@"posy",nil] forKey:@"1"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.38",@"posx",@"0.35",@"posy",nil] forKey:@"2"];
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.58",@"posx",@"0.25",@"posy",nil] forKey:@"3"];
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.75",@"posx",@"0.14",@"posy",nil] forKey:@"4"];	
    area = [[NSTrackingArea alloc] initWithRect:[fourfSwipeDown2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:fourfSwipeDown2,@"object",@"swipe.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",@"-90",@"rotate",nil]];	
    [fourfSwipeDown2 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];    
    
    //rotate & pinch    
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.3",@"posx",@"0.3",@"posy",nil] forKey:@"1"];	
    area = [[NSTrackingArea alloc] initWithRect:[twofRotateC2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofRotateC2,@"object",@"rotate.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",nil]];
    [twofRotateC2 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.3",@"posx",@"0.3",@"posy",nil] forKey:@"1"];	
    area = [[NSTrackingArea alloc] initWithRect:[twofRotateC_2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofRotateC_2,@"object",@"rotate.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",nil]];
    [twofRotateC_2 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.3",@"posx",@"0.3",@"posy",nil] forKey:@"1"];	
    area = [[NSTrackingArea alloc] initWithRect:[twofRotateCc2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofRotateCc2,@"object",@"rotate.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",@"1",@"rotate",nil]];
    [twofRotateCc2 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.3",@"posx",@"0.3",@"posy",nil] forKey:@"1"];	
    area = [[NSTrackingArea alloc] initWithRect:[twofRotateCc_2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofRotateCc_2,@"object",@"rotate.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",@"1",@"rotate",nil]];
    [twofRotateCc_2 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];    
    
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.3",@"posx",@"0.5",@"posy",nil] forKey:@"1"];	
    area = [[NSTrackingArea alloc] initWithRect:[twofPinchIn2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofPinchIn2,@"object",@"pinch.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",nil]];
    [twofPinchIn2 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.3",@"posx",@"0.5",@"posy",nil] forKey:@"1"];	
    area = [[NSTrackingArea alloc] initWithRect:[twofPinchIn_2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofPinchIn_2,@"object",@"pinch.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",nil]];
    [twofPinchIn_2 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.3",@"posx",@"0.5",@"posy",nil] forKey:@"1"];	
    area = [[NSTrackingArea alloc] initWithRect:[twofPinchOut2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofPinchOut2,@"object",@"pinch.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",nil]];
    [twofPinchOut2 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.3",@"posx",@"0.5",@"posy",nil] forKey:@"1"];	
    area = [[NSTrackingArea alloc] initWithRect:[twofPinchOut_2 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofPinchOut_2,@"object",@"pinch.png",@"image",@"mt",@"back",[[fdict copy] autorelease],@"fingers",nil]];
    [twofPinchOut_2 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];    
    
	
	//
	//Macbook Trackpad
	//	
	
	//clicks	
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.55",@"posx",@"0.75",@"posy",nil] forKey:@"1"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.33",@"posx",@"0.60",@"posy",nil] forKey:@"2"];
	area = [[NSTrackingArea alloc] initWithRect:[twofClick3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofClick3,@"object",@"click.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
	[twofClick3 addTrackingArea:area];
	[area release];
	[fdict removeAllObjects];	
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.75",@"posx",@"0.6",@"posy",nil] forKey:@"1"];			
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.55",@"posx",@"0.75",@"posy",nil] forKey:@"2"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.33",@"posx",@"0.60",@"posy",nil] forKey:@"3"];	
	area = [[NSTrackingArea alloc] initWithRect:[threefClick3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:threefClick3,@"object",@"click.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
	[threefClick3 addTrackingArea:area];	
	[area release];	
	[fdict removeAllObjects];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.75",@"posx",@"0.6",@"posy",nil] forKey:@"1"];			
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.55",@"posx",@"0.75",@"posy",nil] forKey:@"2"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.33",@"posx",@"0.60",@"posy",nil] forKey:@"3"];		
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.85",@"posx",@"0.3",@"posy",nil] forKey:@"4"];				
	area = [[NSTrackingArea alloc] initWithRect:[fourfClick3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:fourfClick3,@"object",@"click.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
	[fourfClick3 addTrackingArea:area];
	[area release];	
	[fdict removeAllObjects];	
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.75",@"posx",@"0.6",@"posy",nil] forKey:@"1"];			
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.55",@"posx",@"0.75",@"posy",nil] forKey:@"2"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.33",@"posx",@"0.60",@"posy",nil] forKey:@"3"];		
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.85",@"posx",@"0.3",@"posy",nil] forKey:@"4"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.17",@"posx",@"0.37",@"posy",nil] forKey:@"5"];	
	area = [[NSTrackingArea alloc] initWithRect:[fiveClick3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:fiveClick3,@"object",@"click.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
	[fiveClick3 addTrackingArea:area];
	[area release];	
	[fdict removeAllObjects];	

	//taps	
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.55",@"posx",@"0.75",@"posy",nil] forKey:@"1"];    
	area = [[NSTrackingArea alloc] initWithRect:[onefTap3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:onefTap3,@"object",@"tap.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",nil]];
	[onefTap3 addTrackingArea:area];
	[area release];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.55",@"posx",@"0.75",@"posy",nil] forKey:@"1"];    
	area = [[NSTrackingArea alloc] initWithRect:[onefTap_3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:onefTap_3,@"object",@"tap.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",nil]];
	[onefTap_3 addTrackingArea:area];
	[area release];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.55",@"posx",@"0.75",@"posy",nil] forKey:@"1"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.33",@"posx",@"0.60",@"posy",nil] forKey:@"2"];    
	area = [[NSTrackingArea alloc] initWithRect:[twofTap3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofTap3,@"object",@"tap.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",nil]];
	[twofTap3 addTrackingArea:area];
	[area release];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.55",@"posx",@"0.75",@"posy",nil] forKey:@"1"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.33",@"posx",@"0.60",@"posy",nil] forKey:@"2"];    
	area = [[NSTrackingArea alloc] initWithRect:[twofTap_3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofTap_3,@"object",@"tap.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",nil]];
	[twofTap_3 addTrackingArea:area];
	[area release];	
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.75",@"posx",@"0.6",@"posy",nil] forKey:@"1"];			
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.55",@"posx",@"0.75",@"posy",nil] forKey:@"2"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.33",@"posx",@"0.60",@"posy",nil] forKey:@"3"];				
	area = [[NSTrackingArea alloc] initWithRect:[threefTap3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:threefTap3,@"object",@"tap.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
	[threefTap3 addTrackingArea:area];
	[area release];	
	[fdict removeAllObjects];	
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.75",@"posx",@"0.6",@"posy",nil] forKey:@"1"];			
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.55",@"posx",@"0.75",@"posy",nil] forKey:@"2"];
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.33",@"posx",@"0.60",@"posy",nil] forKey:@"3"];		
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.85",@"posx",@"0.3",@"posy",nil] forKey:@"4"];				
	area = [[NSTrackingArea alloc] initWithRect:[fourfTap3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:fourfTap3,@"object",@"tap.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
	[fourfTap3 addTrackingArea:area];
	[area release];	
	[fdict removeAllObjects];	
    
    //swipes
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.42",@"posx",@"0.64",@"posy",nil] forKey:@"1"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.15",@"posx",@"0.6",@"posy",nil] forKey:@"2"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.28",@"posx",@"0.24",@"posy",nil] forKey:@"3"];	
    area = [[NSTrackingArea alloc] initWithRect:[threefSwipeLeft3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:threefSwipeLeft3,@"object",@"swipe.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",@"180",@"rotate",nil]];	
    [threefSwipeLeft3 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.42",@"posx",@"0.64",@"posy",nil] forKey:@"1"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.15",@"posx",@"0.6",@"posy",nil] forKey:@"2"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.28",@"posx",@"0.24",@"posy",nil] forKey:@"3"];	
    area = [[NSTrackingArea alloc] initWithRect:[threefSwipeRight3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:threefSwipeRight3,@"object",@"swipe.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
    [threefSwipeRight3 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.20",@"posx",@"0.1",@"posy",nil] forKey:@"1"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.50",@"posx",@"0.15",@"posy",nil] forKey:@"2"];
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.80",@"posx",@"0.1",@"posy",nil] forKey:@"3"];		
    area = [[NSTrackingArea alloc] initWithRect:[threefSwipeUp3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:threefSwipeUp3,@"object",@"swipe.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",@"90",@"rotate",nil]];	
    [threefSwipeUp3 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.20",@"posx",@"0.1",@"posy",nil] forKey:@"1"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.50",@"posx",@"0.15",@"posy",nil] forKey:@"2"];
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.80",@"posx",@"0.1",@"posy",nil] forKey:@"3"];	
    area = [[NSTrackingArea alloc] initWithRect:[threefSwipeDown3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:threefSwipeDown3,@"object",@"swipe.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",@"-90",@"rotate",nil]];	
    [threefSwipeDown3 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.42",@"posx",@"0.64",@"posy",nil] forKey:@"1"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.15",@"posx",@"0.6",@"posy",nil] forKey:@"2"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.28",@"posx",@"0.24",@"posy",nil] forKey:@"3"];
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.05",@"posx",@"0.2",@"posy",nil] forKey:@"4"];	
    area = [[NSTrackingArea alloc] initWithRect:[fourfSwipeLeft3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:fourfSwipeLeft3,@"object",@"swipe.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",@"180",@"rotate",nil]];	
    [fourfSwipeLeft3 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.42",@"posx",@"0.64",@"posy",nil] forKey:@"1"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.15",@"posx",@"0.6",@"posy",nil] forKey:@"2"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.28",@"posx",@"0.24",@"posy",nil] forKey:@"3"];
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.05",@"posx",@"0.2",@"posy",nil] forKey:@"4"];	    
    area = [[NSTrackingArea alloc] initWithRect:[fourfSwipeRight3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:fourfSwipeRight3,@"object",@"swipe.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",nil]];	
    [fourfSwipeRight3 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.10",@"posx",@"0.15",@"posy",nil] forKey:@"1"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.35",@"posx",@"0.25",@"posy",nil] forKey:@"2"];
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.60",@"posx",@"0.15",@"posy",nil] forKey:@"3"];
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.90",@"posx",@"0.10",@"posy",nil] forKey:@"4"];		
    area = [[NSTrackingArea alloc] initWithRect:[fourfSwipeUp3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:fourfSwipeUp3,@"object",@"swipe.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",@"90",@"rotate",nil]];	
    [fourfSwipeUp3 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.10",@"posx",@"0.15",@"posy",nil] forKey:@"1"];	
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.35",@"posx",@"0.25",@"posy",nil] forKey:@"2"];
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.60",@"posx",@"0.15",@"posy",nil] forKey:@"3"];
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.90",@"posx",@"0.10",@"posy",nil] forKey:@"4"];	
    area = [[NSTrackingArea alloc] initWithRect:[fourfSwipeDown3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:fourfSwipeDown3,@"object",@"swipe.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",@"-90",@"rotate",nil]];	
    [fourfSwipeDown3 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    //rotate & pinch
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.2",@"posx",@"0.1",@"posy",nil] forKey:@"1"];	
    area = [[NSTrackingArea alloc] initWithRect:[twofRotateC3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofRotateC3,@"object",@"rotate.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",nil]];
    [twofRotateC3 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.2",@"posx",@"0.1",@"posy",nil] forKey:@"1"];	
    area = [[NSTrackingArea alloc] initWithRect:[twofRotateC_3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofRotateC_3,@"object",@"rotate.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",nil]];
    [twofRotateC_3 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.2",@"posx",@"0.1",@"posy",nil] forKey:@"1"];	
    area = [[NSTrackingArea alloc] initWithRect:[twofRotateCc3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofRotateCc3,@"object",@"rotate.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",@"1",@"rotate",nil]];
    [twofRotateCc3 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.2",@"posx",@"0.1",@"posy",nil] forKey:@"1"];	
    area = [[NSTrackingArea alloc] initWithRect:[twofRotateCc_3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofRotateCc_3,@"object",@"rotate.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",@"1",@"rotate",nil]];
    [twofRotateCc_3 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];    
    
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.25",@"posx",@"0.5",@"posy",nil] forKey:@"1"];	
    area = [[NSTrackingArea alloc] initWithRect:[twofPinchIn3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofPinchIn3,@"object",@"pinch.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",nil]];
    [twofPinchIn3 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.25",@"posx",@"0.5",@"posy",nil] forKey:@"1"];	
    area = [[NSTrackingArea alloc] initWithRect:[twofPinchIn_3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofPinchIn_3,@"object",@"pinch.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",nil]];
    [twofPinchIn_3 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.25",@"posx",@"0.5",@"posy",nil] forKey:@"1"];	
    area = [[NSTrackingArea alloc] initWithRect:[twofPinchOut3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofPinchOut3,@"object",@"pinch.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",nil]];
    [twofPinchOut3 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];
    
    [fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"0.25",@"posx",@"0.5",@"posy",nil] forKey:@"1"];	
    area = [[NSTrackingArea alloc] initWithRect:[twofPinchOut_3 frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:twofPinchOut_3,@"object",@"pinch.png",@"image",@"gt",@"back",[[fdict copy] autorelease],@"fingers",nil]];
    [twofPinchOut_3 addTrackingArea:area];
    [area release];
    [fdict removeAllObjects];   
	
	
}


- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem{
	//minimize and hide gradient after switching a tab
	if ([[[aTabView subviews] objectAtIndex:0] isMemberOfClass:[NSImageView class]]){
		[[[aTabView subviews] objectAtIndex:0] setFrame:NSMakeRect(0,50,0,0)];
		[[[aTabView subviews] objectAtIndex:0] setHidden:YES];		
	}	
	lastGesture = 0;	
}

#pragma mark animations

-(void)shakeWindow:(NSWindow*)w{
	
    NSRect f = [w frame];
    int c = 0; //counter variable
    int off = -8; //shake amount (offset)
    while(c<4) //shake 5 times
    {
        [w setFrame: NSMakeRect(f.origin.x + off,
                                f.origin.y,
                                f.size.width,
                                f.size.height) display: NO];
        [NSThread sleepForTimeInterval: .04]; //slight pause
        off *= -1; //back and forth
        c++; //inc counter
    }
    [w setFrame:f display: NO]; //return window to original frame
}

- (void)animateChange:(NSImageView*)theView newrect:(NSRect)newrect
{
    NSViewAnimation *theAnim;
    NSMutableDictionary *firstViewDict;
	
    {
        firstViewDict = [NSMutableDictionary dictionaryWithCapacity:3];
        [firstViewDict setObject:theView forKey:NSViewAnimationTargetKey];
        [firstViewDict setObject:[NSValue valueWithRect:[theView frame]] forKey:NSViewAnimationStartFrameKey];
        [firstViewDict setObject:[NSValue valueWithRect:newrect] forKey:NSViewAnimationEndFrameKey];	
    }
	
    // Create the view animation object.
    theAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:firstViewDict, nil]];
    [theAnim setDuration:0.2];
    [theAnim setAnimationCurve:NSAnimationEaseIn];
    [theAnim startAnimation];
    [theAnim release];	
}

#pragma mark events

-(void)mouseEntered:(NSEvent *)event {
	[self turnOffLive];
	NSMutableDictionary *d = [(NSDictionary *)[event userData] mutableCopy];
	NSButton *button = [(NSDictionary *)[event userData] objectForKey:@"object"];	
	NSTabView *tabView = (NSTabView *)[[button superview] superview];
	//save tag
	lastGesture = [button tag];
	//load image	
	[d setObject:@"hover" forKey:@"what"];
	[d setObject:[NSString stringWithFormat:@"%i",lastGesture] forKey:@"tag"];	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneImgEvent" object:@"local" userInfo:d];	
	//dismiss zone
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneZoneEvent" object:@"0" userInfo:nil];		
	//set the gradient
	if ([[[tabView subviews] objectAtIndex:0] isMemberOfClass:[NSImageView class]]){
		//NSLog(@"gradient found");	
		[[[tabView subviews] objectAtIndex:0] setHidden:NO];		
		[self animateChange:[[tabView subviews] objectAtIndex:0] newrect:NSMakeRect(20,354-[[d objectForKey:@"object"] frame].origin.y, 330, 26)];	
	}else {
		//NSLog(@"no gradient yet , wil create");
		NSImageView *aView = [[NSImageView alloc] initWithFrame:NSMakeRect(20,354-[[d objectForKey:@"object"] frame].origin.y, 330, 26)];	
		NSImage *gradient = [[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"gradient"]];
		[aView setImageScaling:NSScaleNone];
		[aView setImage:gradient];	
		[tabView addSubview:aView positioned:NSWindowBelow relativeTo:[[tabView subviews] objectAtIndex:0]];
		[aView release];
		[gradient release];
	}
	[d release];	
}

-(void)mouseExited:(NSEvent *)event {
	//CFShow([event userData]);
}

-(void)theEvent:(NSNotification*)notif{		
	if ([[notif name] isEqualToString:NSWindowWillCloseNotification]) {
		if ([[notif object] isKindOfClass:[NSPanel class]]){		
			[self turnOffLive];
		}			
	}	
	if ([[notif name] isEqualToString:NSWindowDidBecomeKeyNotification]) {			
		[self syncIMG];	
	}			
	if (![[notif name] isEqualToString:@"MPprefpaneMainEvent"]) {
		return;
	}		
	if ([[notif object] isKindOfClass:[NSString class]]){					
		if ([[notif object] isEqualToString:@"LiveOFF"]){
			[togLiveMouse setState:NSOffState];
			[togLiveTrackpad setState:NSOffState];
			[togLiveMacbook setState:NSOffState];			
		}
		if ([[notif object] isEqualToString:@"ArrowON"]){			
			[keyView setImage:[NSImage imageNamed:@"NSGoRightTemplate"]];
		}	
		if ([[notif object] isEqualToString:@"ArrowOFF"]){
			[keyView setImage:nil];
		}					
		if ([[notif object] isEqualToString:@"SyncUI"]){
			[self syncUI];		
		}
		if ([[notif object] isEqualToString:@"ZoneChanged"]){
			[self doChecks];		
		}		
		if ([[notif object] isEqualToString:@"deviceToggle"]){
			[deviceToggle setSelectedSegment:[[[notif userInfo] objectForKey:@"index"] intValue]];
			[self toggleDevice:deviceToggle];	
		}
		if ([[notif object] isEqualToString:@"updateNewPluginsCount"]){            
            int count = [[[notif userInfo] objectForKey:@"count"] intValue];
            if (count > 0) {
                [mmPluginsButton setTitle:[NSString stringWithFormat:@"Plugins (%i new)",count]];
                [mtPluginsButton setTitle:[NSString stringWithFormat:@"Plugins (%i new)",count]];
                [gtPluginsButton setTitle:[NSString stringWithFormat:@"Plugins (%i new)",count]];                
            }else{
                [mmPluginsButton setTitle:[NSString stringWithFormat:@"Plugins"]];
                [mtPluginsButton setTitle:[NSString stringWithFormat:@"Plugins"]];
                [gtPluginsButton setTitle:[NSString stringWithFormat:@"Plugins"]];                
            }            
		}		
	}			
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]]){	        
		if ([[[notif userInfo] objectForKey:@"what"] isEqualToString:@"getLoadedPluginsEventsCallback"]){
			NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
			[dict setObject:[[notif userInfo] objectForKey:@"list"] forKey:@"events"];
			[dict setObject:[[notif userInfo] objectForKey:@"paths"] forKey:@"paths"];
			[loadedPluginsInfo setDictionary:dict];			
			[self refreshButtons];
		}				
		if ([[[notif userInfo] objectForKey:@"name"] isEqualToString:@"newKeyEvent"]){
			[customSelector setTitle:@""];			
		}	
		if ([[[notif userInfo] objectForKey:@"name"] isEqualToString:@"keyEvent"]){		
			if ([customWindow isKeyWindow]){				
				NSString *key = nil;
				if ([customImage tag] == 2) {
					key = [keyCodeManager keyCodeToChar:[[[notif userInfo] objectForKey:@"value"] intValue]];					
					if ([[customSelector title] length] > 18){
						[customSelector setTitle:@""];
					}	
					if ([[customSelector title] length] > 0){
						key = [NSString stringWithFormat:@"⟶%@",key];
					}					
				}
				if ([customImage tag] == 3 && [[[notif userInfo] objectForKey:@"value"] intValue] != 36) {
					key = [[notif userInfo] objectForKey:@"char"];	
					if ([[customSelector title] length] > 40){
						[customSelector setTitle:@""];
					}						
				}				
				
				key = [[customSelector title] stringByAppendingString:key];							
				[customSelector setTitle:key];					
			}
		}
	}	
}

#pragma mark functions


-(void)syncIMG{
	if (![[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/MagicPrefs.app"] && [defaults boolForKey:@"noAppRelocation"] != YES){
		NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:@"hover",@"what",@"notfound.png",@"back",nil];	
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneImgEvent" object:@"local" userInfo:d];		
	}else{
		//is stopped
		if ([defaults integerForKey:@"PID"] == 0) {
			NSLog(@"MagicPrefs not running.");
			if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/MagicPrefs.app"]) {
                [[NSWorkspace sharedWorkspace] launchApplication:@"/Applications/MagicPrefs.app"];                
                NSLog(@"Launching MagicPrefs.");                
            }else{
                NSLog(@"MagicPrefs not found.");                            
            }
		}		
		//is disabled			
		if ([defaults boolForKey:@"isDisabled"] == YES) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneImgEvent" object:@"local" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"hover",@"what",@"disabled.png",@"back",nil]];				
		}		
		//found crash logs        
        NSString *logsPath = [@"~/Library/Logs/DiagnosticReports/" stringByExpandingTildeInPath];
        for (NSString *item in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:logsPath error:nil]) {
            if ([item rangeOfString:@"MagicPrefs"].location != NSNotFound) {  
                NSString *path = [logsPath stringByAppendingPathComponent:item];
                NSError *err = nil;
                NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&err];
                if (!err) {
                    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:[fileAttributes objectForKey:NSFileCreationDate]];
                    if (interval < 86400) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneImgEvent" object:@"local" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"hover",@"what",@"crashed.png",@"back",nil]];				
                        NSLog(@"Found MagicPrefs crash log %@.",item);                      
                    }
                    if (interval < 60) {
                        [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:nil];
                    }
                }else{
                    NSLog(@"%@ %@",item,err);
                }
            }
        }        
	}
}

-(void)syncUI{
	
	//do checks
	[self doChecks];	
	
	//get plugin data
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPpluginsEvent" object:nil userInfo:
	 [NSDictionary dictionaryWithObjectsAndKeys:@"getLoadedPluginsEvents",@"what",@"MPprefpaneMainEvent",@"callback",nil]
	 ];
	
	//update tracking sliders
	if ([defaults boolForKey:@"noMouse"] == NO) {	
        [speedInterface setMouseSpeed:[[defaults objectForKey:@"TrackingMouse"] floatValue]];	
        [trackSliderMouse setFloatValue:[speedInterface mouseCurrSpeed]];	        
    }else{
        [trackSliderMouse setFloatValue:[[defaults objectForKey:@"TrackingMouse"] floatValue]];	                
    } 
	if ([defaults boolForKey:@"noTrackpad"] == NO ) {    
        [speedInterface setTrackpadSpeed:[[defaults objectForKey:@"TrackingTrackpad"] floatValue]];	
        [trackSliderTrackpad setFloatValue:[speedInterface trackpadCurrSpeed]];			        
    }else{
        [trackSliderTrackpad setFloatValue:[[defaults objectForKey:@"TrackingTrackpad"] floatValue]];			                
    }    
	
	//update tap sliders
	[sensSliderMouse setIntValue:[[defaults objectForKey:@"tapSensMouse"] intValue]];
	[sensSliderTrackpad setIntValue:[[defaults objectForKey:@"tapSensTrackpad"] intValue]];
	[sensSliderMacbook setIntValue:[[defaults objectForKey:@"tapSensMacbook"] intValue]];	
	
	//update icoToggle
	BOOL boo = [defaults boolForKey:@"noMenubarIcon"];		
	if (boo) {					
		[icoToggle setState:NSOffState];			
	}else{
		[icoToggle setState:NSOnState];
	}	
	
	//update presets
	[self addPresets];		
	
	//refresh checkboxes and dropdowns
	[self refreshButtons];
	
	//set info
	[self setInfo];	
}

-(void)refreshButtons{
	gestureCountMouse = 0;
	gestureCountTrackpad = 0;	
	gestureCountMacbook = 0;		
	//loop all subviews of the tabviews
	NSArray *allTabs = [NSArray arrayWithObjects:tabViewMouse,tabViewTrackpad,tabViewMacbook,nil];	
	for (NSTabView *tabView in allTabs){
		for (id tab in [tabView tabViewItems]){	
			for (id obj in [[tab view] subviews]){
				if ([obj isMemberOfClass:[NSButton class]]){
					//toggle button checks
					[self togCheck:obj];
					if ([obj state] == 1) {
						if (tabView == tabViewMouse) gestureCountMouse++;
						if (tabView == tabViewTrackpad) gestureCountTrackpad++;
						if (tabView == tabViewMacbook) gestureCountMacbook++;
					}
				}
				if ([obj isMemberOfClass:[NSPopUpButton class]]){
					//add popup values
					[self addPop:obj];
				}		
			}		
		}	
	}	

}

-(void)setInfo{		
	//add gesture count
	[self setInfoString:infoTextMouse count:gestureCountMouse];
	[self setInfoString:infoTextTrackpad count:gestureCountTrackpad];
	[self setInfoString:infoTextMacbook count:gestureCountMacbook];	
	//add appspecific preset count
	int count = 0;
	NSArray	*arr = [defaults objectForKey:@"presetApps"];
	NSDictionary *dict = [defaults objectForKey:@"presets"];
	for (id app in arr){
		if ([dict objectForKey:[app objectForKey:@"type"]] != nil) {
			count++;
		}
	}	
	if (count > 0) {
		[infoTextMouse setStringValue:[NSString stringWithFormat:@"%@, %i app specific presets",[infoTextMouse stringValue],count]];
		[infoTextTrackpad setStringValue:[NSString stringWithFormat:@"%@, %i app specific presets",[infoTextTrackpad stringValue],count]];
		[infoTextMacbook setStringValue:[NSString stringWithFormat:@"%@, %i app specific presets",[infoTextMacbook stringValue],count]];		
	}
}

-(void)setInfoString:(NSTextField*)field count:(int)count{
	[field setStringValue:[NSString stringWithFormat:@"%i gestures enabled",count]];	
	if (count > 9){
		[field setTextColor:[NSColor colorWithCalibratedRed:0.5 green:0.0 blue:0.0 alpha:0.3]];
	}else if (count > 4) {
		[field setTextColor:[NSColor colorWithCalibratedRed:0.3 green:0.0 blue:0.0 alpha:0.3]];
	}else if (count == 0) {
		[field setTextColor:[NSColor grayColor]];
	}else {
		[field setTextColor:[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.3]];
	}	
}	

-(void)addPresets{
	int count;
	NSArray	*arr = [defaults objectForKey:@"presetApps"];
	NSDictionary *dict = [defaults objectForKey:@"presets"];
	[presets removeAllItems];
	for (id key in dict){
		count = 0;
		for (id app in arr){
			if ([[app objectForKey:@"type"] isEqualToString:key]) {
				count += 1;
			}
		}	
		
		NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Helvetica Bold" size:14.0] forKey:NSFontAttributeName];
		NSAttributedString *attrString = [[[NSAttributedString alloc] initWithString:key attributes:attrsDictionary] autorelease];		
		if (count > 0){			
			[presets addItemWithObjectValue:key];			
		}else {
			[presets addItemWithObjectValue:attrString];						
		}				
	}	
}

-(void)addPop:(id)sender{
	int addition = 0; //magic mouse
	if ([sender tag] > 200) addition = 200; //trackpad
	if ([sender tag] > 300) addition = 300; //macbook trackpad	
	NSMenu *targetMenu = [[NSMenu alloc] initWithTitle:@"Targets"];
	if ([sender tag] <= 4+addition){		
		//[targetMenu addItemWithTitle:@"Disable MagicPrefs" action:nil keyEquivalent:@""];		
		[targetMenu addItemWithTitle:@"Left Click" action:nil keyEquivalent:@""];
		[targetMenu addItemWithTitle:@"Cmd Left Click" action:nil keyEquivalent:@""];
		[targetMenu addItemWithTitle:@"Alt Left Click" action:nil keyEquivalent:@""];
		[targetMenu addItemWithTitle:@"Shift Left Click" action:nil keyEquivalent:@""];
		[targetMenu addItemWithTitle:@"Ctrl Left Click" action:nil keyEquivalent:@""];		
		[targetMenu addItemWithTitle:@"Right Click" action:nil keyEquivalent:@""];		
		[targetMenu addItemWithTitle:@"Middle Click" action:nil keyEquivalent:@""];			
		[targetMenu addItemWithTitle:@"Hold Both Left&Right" action:nil keyEquivalent:@""];	        
		[targetMenu addItemWithTitle:@"Hold Both Right&Left" action:nil keyEquivalent:@""];	
		[targetMenu addItemWithTitle:@"Hold Both Left&Middle" action:nil keyEquivalent:@""];			
	}
	if ([sender tag] > 4+addition && [sender tag] < 20+addition){			
		[targetMenu addItemWithTitle:@"Left Click (Down+Up)" action:nil keyEquivalent:@""];			
		[targetMenu addItemWithTitle:@"Right Click (Down+Up)" action:nil keyEquivalent:@""];
		[targetMenu addItemWithTitle:@"Middle Click (Down+Up)" action:nil keyEquivalent:@""];											
	}
	if ([sender tag] < 20+addition){					
		[targetMenu addItemWithTitle:@"Left Double Click" action:nil keyEquivalent:@""];									
	}	
	if ([sender tag] > 19+addition && [sender tag] < 30+addition){			
		[targetMenu addItemWithTitle:@"Switch Space Left" action:nil keyEquivalent:@""];
		[targetMenu addItemWithTitle:@"Switch Space Right" action:nil keyEquivalent:@""];					
	}	
	[targetMenu addItemWithTitle:@"Screen Zoom In" action:nil keyEquivalent:@""];
	[targetMenu addItemWithTitle:@"Screen Zoom Out" action:nil keyEquivalent:@""];		
	[targetMenu addItemWithTitle:@"Application Zoom In" action:nil keyEquivalent:@""];
	[targetMenu addItemWithTitle:@"Application Zoom Out" action:nil keyEquivalent:@""];				
	[targetMenu addItem:[NSMenuItem separatorItem]];	
	[targetMenu addItemWithTitle:@"Application Windows" action:nil keyEquivalent:@""];		
	[targetMenu addItemWithTitle:@"Desktop" action:nil keyEquivalent:@""];      
	[targetMenu addItemWithTitle:@"Spotlight" action:nil keyEquivalent:@""];	
	[targetMenu addItemWithTitle:@"QuickLook" action:nil keyEquivalent:@""];    
	[targetMenu addItemWithTitle:@"Hide All Other Applications" action:nil keyEquivalent:@""];		
	[targetMenu addItemWithTitle:@"UnHide All Applications" action:nil keyEquivalent:@""];  
	[targetMenu addItemWithTitle:@"Lock Session" action:nil keyEquivalent:@""];	
	[targetMenu addItemWithTitle:@"Application Switcher" action:nil keyEquivalent:@""];
	[targetMenu addItemWithTitle:@"Toggle Mouse Finger Cursor" action:nil keyEquivalent:@""];
	[targetMenu addItemWithTitle:@"Toggle Trackpad Finger Cursor" action:nil keyEquivalent:@""];
	[targetMenu addItemWithTitle:@"Toggle Scrolling" action:nil keyEquivalent:@""];      
	
	//load ones from plugins
	NSMutableDictionary *headerOnes = [[NSMutableDictionary alloc] init];
	NSDictionary *loadedPluginsEvents = [loadedPluginsInfo objectForKey:@"events"];
	NSDictionary *loadedPluginsPaths = [loadedPluginsInfo objectForKey:@"paths"];
	if ([loadedPluginsEvents count] > 0) {
        //add separator
        [targetMenu addItem:[NSMenuItem separatorItem]];                    
    }
	for (NSString *pluginName in loadedPluginsEvents) {
		if ([pluginName isEqualToString:@"MagicMenu"]) continue; //MagicMenu actions are handled in it's own pref pane	
		NSDictionary *events = [loadedPluginsEvents objectForKey:pluginName];		
		if ([events count] > 1) {
			[headerOnes setObject:events forKey:pluginName];
			continue;
		}
		for (NSString *eventName in events) {
			NSString *eventDescription = [events objectForKey:eventName];
			[targetMenu addItemWithTitle:eventDescription action:nil keyEquivalent:@""];
			NSBundle *pluginBundle = [NSBundle bundleWithPath:[loadedPluginsPaths objectForKey:pluginName]];
			NSImage *img = [[[NSImage alloc] initWithContentsOfFile:[pluginBundle pathForImageResource:eventName]] autorelease];						
			if (img) [[targetMenu itemWithTitle:eventDescription] setImage:img];
		}
	}	
	for (NSString *pluginName in headerOnes) {
		NSDictionary *events = [headerOnes objectForKey:pluginName];		
		[targetMenu addItem:[NSMenuItem separatorItem]];
		for (NSString *eventName in events) {
			NSString *eventDescription = [events objectForKey:eventName];
			[targetMenu addItemWithTitle:eventDescription action:nil keyEquivalent:@""];
			NSBundle *pluginBundle = [NSBundle bundleWithPath:[loadedPluginsPaths objectForKey:pluginName]];
			NSImage *img = [[[NSImage alloc] initWithContentsOfFile:[pluginBundle pathForImageResource:eventName]] autorelease];						
			if (img) [[targetMenu itemWithTitle:eventDescription] setImage:img];			
		}
	}	
	[headerOnes release];	
	
	//custom actions submenu
	[targetMenu addItem:[NSMenuItem separatorItem]];	
	[targetMenu addItemWithTitle:@"Custom Actions" action:nil keyEquivalent:@""];	
	
	NSImage *appImg = [[[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"ico_app"]] autorelease];
	NSImage *keyImg = [[[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"ico_key"]] autorelease];
	NSImage *scriptImg = [[[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"ico_script"]] autorelease];	
	NSArray *custom = [[defaults objectForKey:@"customTargets"] mutableCopy];
	NSMenuItem *item;
	for (id target in custom){
		if ([[target objectForKey:@"type"] isEqualToString:@"app"]) {
			item = [targetMenu addItemWithTitle:[[target objectForKey:@"value"] lastPathComponent] action:nil keyEquivalent:@""];			
			[item setImage:appImg];
		}
		if ([[target objectForKey:@"type"] isEqualToString:@"key"]) {				
			item = [targetMenu addItemWithTitle:[keyCodeManager shortcutToString:[target objectForKey:@"value"]] action:nil keyEquivalent:@""];			
			[item setImage:keyImg];
		}
		if ([[target objectForKey:@"type"] isEqualToString:@"script"]) {				
			item = [targetMenu addItemWithTitle:[target objectForKey:@"name"] action:nil keyEquivalent:@""];			
			[item setImage:scriptImg];
		}		
	}
	[custom release];
	
	NSMenu *subMenu = [[NSMenu alloc] initWithTitle:@"Custom Actions"];
	item = [subMenu addItemWithTitle:@"Manage Application Actions" action:@selector(customAppPane:) keyEquivalent:@""];			
	[item setImage:appImg];	
	[item setTarget:self];	
	item = [subMenu addItemWithTitle:@"Manage Keyboard Actions" action:@selector(customKeyPane:) keyEquivalent:@""];			
	[item setImage:keyImg];	
	[item setTarget:self];	
	item = [subMenu addItemWithTitle:@"Manage AppleScript Actions" action:@selector(customScriptPane:) keyEquivalent:@""];			
	[item setImage:scriptImg];	
	[item setTarget:self];	
	[[targetMenu itemWithTitle:@"Custom Actions"] setSubmenu:subMenu];
	[subMenu release];			
	 
	//[[targetMenu itemWithTitle:@"Disable MagicPrefs"] setImage:[[[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"mbar_off"]] autorelease]];	
	[[targetMenu itemWithTitle:@"Custom Actions"] setImage:[[[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"ico_custom"]] autorelease]];	
	[[targetMenu itemWithTitle:@"Application Windows"] setImage:[[[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"ico_windows"]] autorelease]];	
	[[targetMenu itemWithTitle:@"Desktop"] setImage:[[[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"ico_desktop"]] autorelease]];		
	[[targetMenu itemWithTitle:@"Toggle Mouse Finger Cursor"] setImage:[[[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"ico_pointer"]] autorelease]];
	[[targetMenu itemWithTitle:@"Toggle Trackpad Finger Cursor"] setImage:[[[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"ico_pointer"]] autorelease]];
	[[targetMenu itemWithTitle:@"Toggle Scrolling"] setImage:[[[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"scroll"]] autorelease]];
	[[targetMenu itemWithTitle:@"QuickLook"] setImage:[NSImage imageNamed:@"NSQuickLookTemplate"]];
	[[targetMenu itemWithTitle:@"Hide All Other Applications"] setImage:[NSImage imageNamed:@"NSStopProgressTemplate"]];
	[[targetMenu itemWithTitle:@"UnHide All Applications"] setImage:[NSImage imageNamed:@"NSRefreshTemplate"]];		
	[[targetMenu itemWithTitle:@"Spotlight"] setImage:[NSImage imageNamed:@"NSRevealFreestandingTemplate"]];	
	[[targetMenu itemWithTitle:@"Switch Space Left"] setImage:[NSImage imageNamed:@"NSMenuSubmenuLeft"]];	
	[[targetMenu itemWithTitle:@"Switch Space Right"] setImage:[NSImage imageNamed:@"NSMenuSubmenu"]];	
	[[targetMenu itemWithTitle:@"Screen Zoom In"] setImage:[NSImage imageNamed:@"NSExitFullScreenTemplate"]];	
	[[targetMenu itemWithTitle:@"Screen Zoom Out"] setImage:[NSImage imageNamed:@"NSEnterFullScreenTemplate"]];	
	[[targetMenu itemWithTitle:@"Application Zoom In"] setImage:[NSImage imageNamed:@"NSAddTemplate"]];	
	[[targetMenu itemWithTitle:@"Application Zoom Out"] setImage:[NSImage imageNamed:@"NSRemoveTemplate"]];	
	[[targetMenu itemWithTitle:@"Lock Session"] setImage:[NSImage imageNamed:@"NSLockLockedTemplate"]];	
	[[targetMenu itemWithTitle:@"Application Switcher"] setImage:[NSImage imageNamed:@"NSColumnViewTemplate"]];	

	[sender setMenu:targetMenu];
	[targetMenu release];
	
	NSDictionary *dict = [defaults objectForKey:@"bindings"];
	[sender selectItemWithTitle:[[dict objectForKey:[NSString stringWithFormat:@"%i",[sender tag]]]	objectForKey:@"target"]];
}

-(void)togCheck:(id)sender{	 
	NSString *tag = [NSString stringWithFormat:@"%i",[sender tag]];	
	NSDictionary *dict = [defaults objectForKey:@"bindings"];
	[sender setState:[[[dict objectForKey:tag] objectForKey:@"state"] intValue]];	
}

-(void)disableAndTurnOff:(NSButton*)button{
    
    if (button == twofRotateC2 || button == twofRotateC_2 || button == twofRotateCc2 || button == twofRotateCc_2 ||
        button == twofRotateC3 || button == twofRotateC_3 || button == twofRotateCc3 || button == twofRotateCc_3 ||        
        button == twofPinchIn2 || button == twofPinchIn_2 || button == twofPinchOut2 || button == twofPinchOut_2 ||
        button == twofPinchIn3 || button == twofPinchIn_3 || button == twofPinchOut3 || button == twofPinchOut_3         
        ) {
        if ([defaults boolForKey:@"generateOSXGestures"] != YES)  {
            return;
        }
    }
    
    if ([button state] == NSOnState) {
        [button setState:NSOffState];
        [self checkClick:button];		
    }		
    [button setEnabled:NO];

}

-(NSButton*)checkItemWithTag:(int)tag{
	//loop all subviews of the tabviews
	NSArray *allTabs = [NSArray arrayWithObjects:tabViewMouse,tabViewTrackpad,tabViewMacbook,nil];	
	for (NSTabView *tabView in allTabs){
		for (id tab in [tabView tabViewItems]){	
			for (id obj in [[tab view] subviews]){
				if ([obj isMemberOfClass:[NSButton class]] && [obj tag] == tag){
					if ([obj state] == NSOffState) {
						[obj setState:NSOnState];
                        return obj;				
					}
				}	
			}		
		}		
	}
    return nil;
}

-(void)doWarnings:(int)tag{
	if (tag == 2){
		[self showMsg:@"Natively 2 finger click does a left click, overriding it probably means up to 50% of your left clicks will be gone, use with caution."];
		return;		
	}
	if (tag == 6){
		[self showMsg:@"Be carefull with enabling two finger taps, usual handling of the mouse usually involves brief tapping with two fingers."];
		return;		
	}	
	if (tag == 9 || tag == 10){
		[self showMsg:@"Be carefull with enabling one finger taps, usual movements of the finger over the surface of the mouse can easily involve brief taps with one finger."];
		return;		
	}	
}

-(void)doChecks{
	NSDictionary *mmPrefs = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.driver.AppleBluetoothMultitouch.mouse"];	
	if ([[mmPrefs objectForKey:@"MouseHorizontalSwipe"] intValue] == 2){
		[leftSwipeImg setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"caut"))]];
		[leftSwipeImg setToolTip:@"Two Fingers Swipe Left/Right to Navigate conflicts with this gesture"];
		[leftSwipeImg setHidden:NO];	
		[rightSwipeImg setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"caut"))]];	
		[rightSwipeImg setToolTip:@"Two Fingers Swipe Left/Right to Navigate conflicts with this gesture"];	
		[rightSwipeImg setHidden:NO];		
	}else {
		[leftSwipeImg setHidden:YES];
		[rightSwipeImg setHidden:YES];				
	}
	NSDictionary *mtPrefs = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.driver.AppleBluetoothMultitouch.trackpad"];	
	if ([[mtPrefs objectForKey:@"Clicking"] boolValue] == YES){
		//taps gestures
		[mtTapToClickImg setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"caut"))]];
		[mtTapToClickImg setToolTip:@"Turn Tap To Click off in the system's trackpad preferences in order to assign custom actions for tap gestures"];
		[mtTapToClickImg setHidden:NO];			
		[self disableAndTurnOff:onefTap2];		
		[self disableAndTurnOff:onefTap_2];	
		[self disableAndTurnOff:twofTap2];	
		[self disableAndTurnOff:twofTap_2];
		[self disableAndTurnOff:threefTap2];	
		[self disableAndTurnOff:fourfTap2];	
		//2f click gesture
		[mt2fTapToClickImg setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"caut"))]];
		[mt2fTapToClickImg setToolTip:@"Tap To Click is on in the system's trackpad preferences so if you do not immediately raise your fingers after doing a right click by tapping it also triggers this gesture"];		
		[mt2fTapToClickImg setHidden:NO];
	}else {
		//taps gestures		
		[mtTapToClickImg setHidden:YES];		
		[onefTap2 setEnabled:YES];		
		[onefTap_2 setEnabled:YES];	
		[twofTap2 setEnabled:YES];		
		[twofTap_2 setEnabled:YES];		
		[threefTap2 setEnabled:YES];		
		[fourfTap2 setEnabled:YES];
		//2f click gesture
		[mt2fTapToClickImg setHidden:YES];		
	}
	NSDictionary *gtPrefs = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.driver.AppleBluetoothMultitouch.trackpad"];	
	if ([[gtPrefs objectForKey:@"Clicking"] boolValue] == YES){
		//taps gestures		
		[gtTapToClickImg setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"caut"))]];
		[gtTapToClickImg setToolTip:@"Turn Tap To Click off in the system's trackpad preferences in order to assign custom actions for tap gestures"];
		[gtTapToClickImg setHidden:NO];	
		[self disableAndTurnOff:onefTap3];		
		[self disableAndTurnOff:onefTap_3];	
		[self disableAndTurnOff:twofTap3];	
		[self disableAndTurnOff:twofTap_3];	
		[self disableAndTurnOff:threefTap3];	
		[self disableAndTurnOff:fourfTap3];	
		//2f click gesture
		[gt2fTapToClickImg setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"caut"))]];
		[gt2fTapToClickImg setToolTip:@"Tap To Click is on in the system's trackpad preferences so if you do not immediately raise your fingers after doing a right click by tapping it also triggers this gesture"];		
		[gt2fTapToClickImg setHidden:NO];		
	}else {
		//taps gestures
		[gtTapToClickImg setHidden:YES];
		[onefTap3 setEnabled:YES];		
		[onefTap_3 setEnabled:YES];	
		[twofTap3 setEnabled:YES];		
		[twofTap_3 setEnabled:YES];		
		[threefTap3 setEnabled:YES];		
		[fourfTap3 setEnabled:YES];
		//2f click gesture		
		[gt2fTapToClickImg setHidden:YES];		
	}	    
    //rotate
	if ([[mtPrefs objectForKey:@"TrackpadRotate"] boolValue] == YES){
		[mtRotateImg setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"caut"))]];
		[mtRotateImg setToolTip:@"The Rotate gesture is also assigned a action in the trackpad's preference pane"];
		[mtRotateImg setHidden:NO];
		[self disableAndTurnOff:twofRotateC2];
		[self disableAndTurnOff:twofRotateC_2];    
		[self disableAndTurnOff:twofRotateCc2];
		[self disableAndTurnOff:twofRotateCc_2];
	}else {
		[mtRotateImg setHidden:YES];
		[twofRotateC2 setEnabled:YES];
		[twofRotateC_2 setEnabled:YES];    
		[twofRotateCc2 setEnabled:YES];
		[twofRotateCc_2 setEnabled:YES]; 
	}    
	if ([[gtPrefs objectForKey:@"TrackpadRotate"] boolValue] == YES){
		[gtRotateImg setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"caut"))]];
		[gtRotateImg setToolTip:@"The Rotate gesture is also assigned a action in the trackpad's preference pane"];
		[gtRotateImg setHidden:NO];	
        [self disableAndTurnOff:twofRotateC3];
        [self disableAndTurnOff:twofRotateC_3];    
        [self disableAndTurnOff:twofRotateCc3];
        [self disableAndTurnOff:twofRotateCc_3];        
	}else {
		[gtRotateImg setHidden:YES];
        [twofRotateC3 setEnabled:YES];
        [twofRotateC_3 setEnabled:YES];    
        [twofRotateCc3 setEnabled:YES];
        [twofRotateCc_3 setEnabled:YES];        
	}
    //pinch
	if ([[mtPrefs objectForKey:@"TrackpadPinch"] boolValue] == YES){
		[mtPinchImg setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"caut"))]];
		[mtPinchImg setToolTip:@"The Pinch gesture is also assigned a action in the trackpad's preference pane"];
		[mtPinchImg setHidden:NO];
		[self disableAndTurnOff:twofPinchIn2];
		[self disableAndTurnOff:twofPinchIn_2];    
		[self disableAndTurnOff:twofPinchOut2];
		[self disableAndTurnOff:twofPinchOut_2];		
	}else {
		[mtPinchImg setHidden:YES];
		[twofPinchIn2 setEnabled:YES];
		[twofPinchIn_2 setEnabled:YES];    
		[twofPinchOut2 setEnabled:YES];
		[twofPinchOut_2 setEnabled:YES];        
	}    
	if ([[gtPrefs objectForKey:@"TrackpadPinch"] boolValue] == YES){
		[gtPinchImg setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"caut"))]];
		[gtPinchImg setToolTip:@"The Pinch gesture is also assigned a action in the trackpad's preference pane"];
		[gtPinchImg setHidden:NO];
        [self disableAndTurnOff:twofPinchIn3];
        [self disableAndTurnOff:twofPinchIn_3];    
        [self disableAndTurnOff:twofPinchOut3];
        [self disableAndTurnOff:twofPinchOut_3];				
	}else {
		[gtPinchImg setHidden:YES];
        [twofPinchIn3 setEnabled:YES];
        [twofPinchIn_3 setEnabled:YES];    
        [twofPinchOut3 setEnabled:YES];
        [twofPinchOut_3 setEnabled:YES];        
	}  
    
    //3fswipes horiz
	if ([[mtPrefs objectForKey:@"TrackpadThreeFingerHorizSwipeGesture"] intValue] != 0){
		[mt3fhSwipeImg setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"caut"))]];
		[mt3fhSwipeImg setToolTip:@"The 3 finger swipe left/right gesture is also assigned a action in the trackpad's preference pane"];
		[mt3fhSwipeImg setHidden:NO];
		[self disableAndTurnOff:threefSwipeLeft2];
		[self disableAndTurnOff:threefSwipeRight2];       
	}else {
		[mt3fhSwipeImg setHidden:YES];
		[threefSwipeLeft2 setEnabled:YES];
		[threefSwipeRight2 setEnabled:YES];       
	} 
	if ([[gtPrefs objectForKey:@"TrackpadThreeFingerHorizSwipeGesture"] intValue] != 0){
		[gt3fhSwipeImg setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"caut"))]];
		[gt3fhSwipeImg setToolTip:@"The 3 finger swipe left/right gesture is also assigned a action in the trackpad's preference pane"];
		[gt3fhSwipeImg setHidden:NO];
        [self disableAndTurnOff:threefSwipeLeft3];
        [self disableAndTurnOff:threefSwipeRight3];       
	}else {
		[gt3fhSwipeImg setHidden:YES];
        [threefSwipeLeft3 setEnabled:YES];
        [threefSwipeRight3 setEnabled:YES];       
	} 
    //3fswipes vert
	if ([[mtPrefs objectForKey:@"TrackpadThreeFingerVertSwipeGesture"] intValue] != 0){
		[mt3fvSwipeImg setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"caut"))]];
		[mt3fvSwipeImg setToolTip:@"The 3 finger swipe up/down gesture is also assigned a action in the trackpad's preference pane"];
		[mt3fvSwipeImg setHidden:NO];
		[self disableAndTurnOff:threefSwipeUp2];
		[self disableAndTurnOff:threefSwipeDown2];        
	}else {
		[mt3fvSwipeImg setHidden:YES];
		[threefSwipeUp2 setEnabled:YES];
		[threefSwipeDown2 setEnabled:YES];        
	} 
	if ([[gtPrefs objectForKey:@"TrackpadThreeFingerVertSwipeGesture"] intValue] != 0){
		[gt3fvSwipeImg setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"caut"))]];
		[gt3fvSwipeImg setToolTip:@"The 3 finger swipe up/down gesture is also assigned a action in the trackpad's preference pane"];
		[gt3fvSwipeImg setHidden:NO];
        [self disableAndTurnOff:threefSwipeUp3];
        [self disableAndTurnOff:threefSwipeDown3];        
	}else {
		[gt3fvSwipeImg setHidden:YES];
        [threefSwipeUp3 setEnabled:YES];
        [threefSwipeDown3 setEnabled:YES];        
	} 
    
    //4fswipes horiz
    if ([[mtPrefs objectForKey:@"TrackpadFourFingerHorizSwipeGesture"] intValue] != 0){
        [mt4fhSwipeImg setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"caut"))]];
        [mt4fhSwipeImg setToolTip:@"The 4 finger swipe left/right gesture is also assigned a action in the trackpad's preference pane"];
        [mt4fhSwipeImg setHidden:NO];
        [self disableAndTurnOff:fourfSwipeLeft2];
        [self disableAndTurnOff:fourfSwipeRight2];       
    }else {
        [mt4fhSwipeImg setHidden:YES];
        [fourfSwipeLeft2 setEnabled:YES];
        [fourfSwipeRight2 setEnabled:YES];       
    } 
    if ([[gtPrefs objectForKey:@"TrackpadFourFingerHorizSwipeGesture"] intValue] != 0){
        [gt4fhSwipeImg setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"caut"))]];
        [gt4fhSwipeImg setToolTip:@"The 4 finger swipe left/right gesture is also assigned a action in the trackpad's preference pane"];
        [gt4fhSwipeImg setHidden:NO];
        [self disableAndTurnOff:fourfSwipeLeft3];
        [self disableAndTurnOff:fourfSwipeRight3];       
    }else {
        [gt4fhSwipeImg setHidden:YES];
        [fourfSwipeLeft3 setEnabled:YES];
        [fourfSwipeRight3 setEnabled:YES];       
    } 
    //4fswipes vert
    if ([[mtPrefs objectForKey:@"TrackpadFourFingerVertSwipeGesture"] intValue] != 0){
        [mt4fvSwipeImg setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"caut"))]];
        [mt4fvSwipeImg setToolTip:@"The 4 finger swipe up/down gesture is also assigned a action in the trackpad's preference pane"];
        [mt4fvSwipeImg setHidden:NO];
        [self disableAndTurnOff:fourfSwipeUp2];
        [self disableAndTurnOff:fourfSwipeDown2];        
    }else {
        [mt4fvSwipeImg setHidden:YES];
        [fourfSwipeUp2 setEnabled:YES];
        [fourfSwipeDown2 setEnabled:YES];        
    } 
    if ([[gtPrefs objectForKey:@"TrackpadFourFingerVertSwipeGesture"] intValue] != 0){
        [gt4fvSwipeImg setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"caut"))]];
        [gt4fvSwipeImg setToolTip:@"The 4 finger swipe up/down gesture is also assigned a action in the trackpad's preference pane"];
        [gt4fvSwipeImg setHidden:NO];
        [self disableAndTurnOff:fourfSwipeUp3];
        [self disableAndTurnOff:fourfSwipeDown3];        
    }else {
        [gt4fvSwipeImg setHidden:YES];
        [fourfSwipeUp3 setEnabled:YES];
        [fourfSwipeDown3 setEnabled:YES];        
    }    

	//MT zone overlap checks	
    [self overlapTest:mt1fTapOverlapImg zone1:@"206" zone2:@"207"]; 
    [self overlapTest:mt2fTapOverlapImg zone1:@"208" zone2:@"209"];    
    [self overlapTest:mtRotateOverlapImg zone1:@"230" zone2:@"231"];    
    [self overlapTest:mtRotateCCOverlapImg zone1:@"232" zone2:@"233"];     
    [self overlapTest:mtPinchInOverlapImg zone1:@"236" zone2:@"237"];    
    [self overlapTest:mtPinchOutOverlapImg zone1:@"238" zone2:@"239"];  
	//GT zone overlap checks    
    [self overlapTest:gt1fTapOverlapImg zone1:@"306" zone2:@"307"]; 
    [self overlapTest:gt2fTapOverlapImg zone1:@"308" zone2:@"309"];    
    [self overlapTest:gtRotateOverlapImg zone1:@"330" zone2:@"331"];    
    [self overlapTest:gtRotateCCOverlapImg zone1:@"332" zone2:@"333"];     
    [self overlapTest:gtPinchInOverlapImg zone1:@"336" zone2:@"337"];    
    [self overlapTest:gtPinchOutOverlapImg zone1:@"338" zone2:@"339"];
    
}

-(void)overlapTest:(id)sender zone1:(NSString*)zone1 zone2:(NSString*)zone2{
	//HFSTypeCode note=white caut=yellow stop=red    
	NSDictionary *bindings = [defaults objectForKey:@"bindings"];
	NSDictionary *zones = [defaults objectForKey:@"zones"];     
	NSDictionary *zone;
	CGRect rect1;
	CGRect rect2;    
    if ([[[bindings objectForKey:zone1] objectForKey:@"state"] intValue] == 1 && [[[bindings objectForKey:zone2] objectForKey:@"state"] intValue] == 1){
        zone = [zones objectForKey:zone1];
        rect1 = CGRectMake([[zone objectForKey:@"x"] floatValue], [[zone objectForKey:@"y"] floatValue], [[zone objectForKey:@"w"] floatValue], [[zone objectForKey:@"h"] floatValue]);
        zone = [zones objectForKey:zone2];
        rect2 = CGRectMake([[zone objectForKey:@"x"] floatValue], [[zone objectForKey:@"y"] floatValue], [[zone objectForKey:@"w"] floatValue], [[zone objectForKey:@"h"] floatValue]);	
        if (CGRectIntersectsRect(rect1,rect2) == YES || CGRectIsEmpty(rect1) || CGRectIsEmpty(rect2) ) {
            [sender setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"stop"))]];	
            [sender setHidden:NO];		
        }else {
            [sender setHidden:YES];
        }			
    }else {
        [sender setHidden:YES];
    }     
}

-(void)addMissingFromDefault{
	NSDictionary *defaultBindings = [[[defaults objectForKey:@"presets"] objectForKey:@"Default"] objectForKey:@"bindings"];  
    NSMutableDictionary *bindings = [[defaults objectForKey:@"bindings"] mutableCopy];    
    for (NSString *key in defaultBindings) {
        if ([bindings objectForKey:key] == nil) {
            NSDictionary *defaultBinding = [defaultBindings objectForKey:key];            
            [bindings setObject:defaultBinding forKey:key];
        }
    }
    [defaults setObject:bindings forKey:@"bindings"];
    [bindings release];

	NSDictionary *defaultZones = [[[defaults objectForKey:@"presets"] objectForKey:@"Default"] objectForKey:@"zones"];      
    NSMutableDictionary *zones = [[defaults objectForKey:@"zones"] mutableCopy];            
    for (NSString *key in defaultZones) {
        if ([zones objectForKey:key] == nil) {
            NSDictionary *defaultZone = [defaultZones objectForKey:key];            
            [zones setObject:defaultZone forKey:key];
        }
    }
    [defaults setObject:zones forKey:@"zones"];
    [zones release];

    [defaults synchronize];   
}

#pragma mark ibactions

-(IBAction)toggleIcon:(id)sender {	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPcoreMenuEvent" object:@"IconToggle" userInfo:nil];	
}

-(IBAction)toggleDevice:(id)sender {
	//[self turnOffLive];
	[presetsBox setHidden:NO];
	//remove "missing" imageviews
	for (id obj in [parentView subviews]){
		if ([obj isMemberOfClass:[NSImageView class]]){
			[obj removeFromSuperview];
		}	
	}		
	
	if ([sender selectedSegment] == 0) {
		[mtrackpadView removeFromSuperview];		
		[gtrackpadView removeFromSuperview];
		if ([defaults boolForKey:@"noMouse"] == YES) {
			[mmouseView removeFromSuperview];			
			NSImageView *imgView = [[NSImageView alloc] initWithFrame:NSMakeRect(0,20,630,480)];
			NSImage *img = [[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"nomouse"]];
			[imgView setImage:img];
			[img release];
			[parentView addSubview:imgView];
			[imgView release];
			[presetsBox setHidden:YES];
		}else {
			[parentView addSubview:mmouseView];			
		}				
	}else if ([sender selectedSegment] == 1) {
		[mmouseView removeFromSuperview];		
		[gtrackpadView removeFromSuperview];	
		if ([defaults boolForKey:@"noTrackpad"] == YES) {
			[mtrackpadView removeFromSuperview];			
			NSImageView *imgView = [[NSImageView alloc] initWithFrame:NSMakeRect(0,20,630,480)];
			NSImage *img = [[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"notrackpad"]];
			[imgView setImage:img];
			[img release];
			[parentView addSubview:imgView];
			[imgView release];
			[presetsBox setHidden:YES];			
		}else {
			[parentView addSubview:mtrackpadView];	
		}			
	}else if ([sender selectedSegment] == 2) {
		[mmouseView removeFromSuperview];		
		[mtrackpadView removeFromSuperview];
		if ([defaults boolForKey:@"noGlassTrackpad"] == YES) {
			[gtrackpadView removeFromSuperview];			
			NSImageView *imgView = [[NSImageView alloc] initWithFrame:NSMakeRect(0,20,630,480)];
			NSImage *img = [[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"notmacbook"]];
			[imgView setImage:img];
			[img release];
			[parentView addSubview:imgView];
			[imgView release];
			[presetsBox setHidden:YES];			
		}else {
			[parentView addSubview:gtrackpadView];
		}				
	}else {
		NSLog(@"No Device Selected");
	}
	[self helpPressed:nil];
}

-(IBAction)updateMouseTapSens:(id)sender {
	int value = [sensSliderMouse intValue];	
	[defaults setInteger:value forKey:@"tapSensMouse"];
	[defaults synchronize];		
}

-(IBAction)updateMouseSpeed:(id)sender {
	float value = [trackSliderMouse floatValue];
	[speedInterface setMouseSpeed:value];	
	[defaults setInteger:value forKey:@"TrackingMouse"];
	[defaults synchronize];		
}

-(IBAction)updateTrackpadTapSens:(id)sender{
	int value = [sensSliderTrackpad intValue];	
	[defaults setInteger:value forKey:@"tapSensTrackpad"];
	[defaults synchronize];	
}

-(IBAction)updateTrackpadSpeed:(id)sender{
	float value = [trackSliderTrackpad floatValue];
	[speedInterface setTrackpadSpeed:value];	
	[defaults setInteger:value forKey:@"TrackingTrackpad"];
	[defaults synchronize];		
}

-(IBAction)updateMacbookTapSens:(id)sender{
	int value = [sensSliderMacbook intValue];	
	[defaults setInteger:value forKey:@"tapSensMacbook"];
	[defaults synchronize];	
}


-(IBAction) togLive:(id) sender{
	NSString *type = nil;
	if ([sender tag] == 1) type = @"LiveMouse";
	if ([sender tag] == 2) type = @"LiveTrackpad";
	if ([sender tag] == 3) type = @"LiveMacbook";	
	if (type) {
		if ([sender state] == 1) {
			[defaults setBool:YES forKey:type];		
		}
		if ([sender state] == 0) {
			[defaults setBool:NO forKey:type];
		}	
		[defaults synchronize];		
	}else {
		NSLog(@"Error getting live button tag");
	}
} 

-(IBAction) helpPressed:(id)sender{
	//minimize and hide gradient
	NSView *device = nil;
	if ([mmouseView superview] != nil) device = tabViewMouse;	
	if ([mtrackpadView superview] != nil) device = tabViewTrackpad;
	if ([gtrackpadView superview] != nil) device = tabViewMacbook;	
	if ([[[device subviews] objectAtIndex:0] isMemberOfClass:[NSImageView class]]){
		[[[device subviews] objectAtIndex:0] setFrame:NSMakeRect(0,50,0,0)];
		[[[device subviews] objectAtIndex:0] setHidden:YES];		
	}	
	lastGesture = 0;	
	[self turnOffLive];	
	//dismiss zone
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneZoneEvent" object:@"0" userInfo:nil];
	//show help	
	NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:@"hover",@"what",@"default.png",@"back",nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneImgEvent" object:@"local" userInfo:d];	
	//override if more important messages
	[self syncIMG];
} 

-(IBAction) zonePressed:(id) sender{	
	if (lastGesture == 0){
		[self shakeWindow:[[self mainView] window]];		
		return;
	}		
	NSString *device = nil;
	if ([mmouseView superview] != nil) device = @"mm";	
	if ([mtrackpadView superview] != nil) device = @"mt";
	if ([gtrackpadView superview] != nil) device = @"gt";
	if (device) {
		NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:@"hover",@"what",device,@"back",nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneImgEvent" object:@"local" userInfo:d];	
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneZoneEvent" object:[NSString stringWithFormat:@"%i",lastGesture] userInfo:nil];			
	}else{
		NSLog(@"Can't determine the device");
	}
} 

-(IBAction) selectedPop:(id) sender{
	//skip if the coresponding button is disabled	
	id obj = [parentView viewWithTag:[sender tag]];
	if ([obj isMemberOfClass:[NSButton class]]) {
		if ([(NSButton*)obj isEnabled] == NO) {
			return; 		
		}	
	}
	
	NSString *tag = [NSString stringWithFormat:@"%i",[sender tag]];
	NSMutableDictionary *dict = [[defaults objectForKey:@"bindings"] mutableCopy];
	NSMutableDictionary *d = [[[dict objectForKey:tag] mutableCopy] autorelease];
	if (d == nil){
		d = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"0",@"state",@"N/A",@"target",nil];
	}	
	[d setObject:[sender title] forKey:@"target"];
	[dict setObject:d forKey:tag];	
	[defaults setObject:dict forKey:@"bindings"];
	[defaults synchronize];
	[dict release];	
	//also check coresponding button	
	NSButton *button = [self checkItemWithTag:[sender tag]];
    if (button) {
        [self checkClick:button];
    }
} 

-(IBAction) checkClick:(id) sender{	
	if ([sender state] == NSOnState){
		[self doWarnings:[sender tag]];	
		if ([sender tag] < 199) gestureCountMouse++;
		if ([sender tag] > 200 && [sender tag] < 299) gestureCountTrackpad++;
		if ([sender tag] > 300 && [sender tag] < 399) gestureCountMacbook++;		
	}else {
		if ([sender tag] < 199) gestureCountMouse--;
		if ([sender tag] > 200 && [sender tag] < 299) gestureCountTrackpad--;
		if ([sender tag] > 300 && [sender tag] < 399) gestureCountMacbook--;
	}
	[self setInfo];
	NSString *tag = [NSString stringWithFormat:@"%i",[sender tag]];
	NSMutableDictionary *dict = [[defaults objectForKey:@"bindings"] mutableCopy];
	NSMutableDictionary *d = [[[dict objectForKey:tag] mutableCopy] autorelease];
	if (d == nil){
		d = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"0",@"state",@"N/A",@"target",nil];
	}
	[d setObject:[NSString stringWithFormat:@"%i",[sender state]] forKey:@"state"];
	[dict setObject:d forKey:tag];	
	[defaults setObject:dict forKey:@"bindings"];
	[defaults synchronize];	
	[dict release];	
} 

-(IBAction) loadPreset:(id) sender{	
	if ([[presets stringValue] length] < 1){
		[self shakeWindow:[[self mainView] window]];		
		return;
	}		
	NSDictionary *dict = [[defaults objectForKey:@"presets"] objectForKey:[presets stringValue]];
	for (id key in dict){
		[defaults setObject:[dict objectForKey:key] forKey:key];		
	}	
	[defaults synchronize];	
	[self syncUI];		
}

-(IBAction) savePreset:(id) sender{	
	if ([[presets stringValue] isEqualToString:@"Default"]){
		[self showMsg:@"The Default preset is read only, settings can not be exported into it."];
		return;
	}	
	if ([[presets stringValue] length] < 1){
		[self shakeWindow:[[self mainView] window]];
		return;
	}		
	//dict with live settings
	NSMutableDictionary *preset = [NSMutableDictionary dictionaryWithCapacity:1];	
	[preset setObject:[defaults objectForKey:@"zones"] forKey:@"zones"];	
	[preset setObject:[defaults objectForKey:@"scrollzone"] forKey:@"scrollzone"];		
	[preset setObject:[defaults objectForKey:@"scrolling"] forKey:@"scrolling"];
	[preset setObject:[defaults objectForKey:@"bindings"] forKey:@"bindings"];		
	[preset setObject:[defaults objectForKey:@"TrackingMouse"] forKey:@"TrackingMouse"];
	[preset setObject:[defaults objectForKey:@"TrackingTrackpad"] forKey:@"TrackingTrackpad"];	
	[preset setObject:[defaults objectForKey:@"tapSensMouse"] forKey:@"tapSensMouse"];
	[preset setObject:[defaults objectForKey:@"tapSensTrackpad"] forKey:@"tapSensTrackpad"];
	[preset setObject:[defaults objectForKey:@"tapSensMacbook"] forKey:@"tapSensMacbook"];	
	
	//add it to existing	
	NSMutableDictionary *dict = [[defaults objectForKey:@"presets"] mutableCopy];	
	[dict setObject:preset forKey:[presets stringValue]];
	//save
	[defaults setObject:dict forKey:@"presets"];
	[defaults synchronize];
	[dict release];
	[self addPresets];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPcoreMenuEvent" object:@"ReloadMenu" userInfo:nil];		
}

-(IBAction) deletePreset:(id) sender{	
	if ([[presets stringValue] isEqualToString:@"Default"]){
		[self showMsg:@"The Default preset can not be deleted."];		
		return;		
	}
	if ([[presets stringValue] length] < 1){
		[self shakeWindow:[[self mainView] window]];
		return;
	}	
	//remove from existing
	NSMutableDictionary *dict = [[defaults objectForKey:@"presets"] mutableCopy];	
	[dict removeObjectForKey:[presets stringValue]];	
	//save
	[defaults setObject:dict forKey:@"presets"];
	[defaults synchronize];
	[dict release];	
	[self addPresets];
	[presets setStringValue:@""];	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPcoreMenuEvent" object:@"ReloadMenu" userInfo:nil];		
}

#pragma mark message methods

-(IBAction) showPlugins:(id)sender{   			
	//load modal
	[NSApp beginSheet:[pluginsWindowController window] modalForWindow:[[self mainView] window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}	

-(IBAction) showScroll:(id)sender{
    //dismiss zone
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneZoneEvent" object:@"0" userInfo:nil];
    //sync
    [scrollWindowController syncMe];
    //load modal
    [NSApp beginSheet:[scrollWindowController window] modalForWindow:[[self mainView] window] modalDelegate:nil didEndSelector:nil contextInfo:nil];        
    //load zone
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneZoneEvent" object:@"scrollzone" userInfo:nil];       
}	

- (void)showMsg:(NSString *)msg{
	//make sure window alloced first
	//[[self window] makeKeyAndOrderFront:self];	
	//set text
	[messageText setStringValue:msg];
	//run with it
	[NSApp beginSheet:messageWindow modalForWindow:[[self mainView] window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

-(IBAction)closeMsg:(id)sender{
	[NSApp endSheet:[sender window]];
	//[[sender window] close];
	[[sender window] orderOut:self];	
}

#pragma mark custom actions

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView {	
	NSString *key;	
	if ([customImage tag] == 9) {
		key = @"presetApps";
	}else{
		key = @"customTargets";		
	}		
	NSInteger count = 0;
	NSArray *custom = [[defaults objectForKey:key] mutableCopy];	
	for (id target in custom){
		if ([[target objectForKey:@"type"] isEqualToString:@"app"] && [customImage tag] == 1) {
			count += 1;		
		}
		if ([[target objectForKey:@"type"] isEqualToString:@"key"] && [customImage tag] == 2) {
			count += 1;					
		}
		if ([[target objectForKey:@"type"] isEqualToString:@"script"] && [customImage tag] == 3) {
			count += 1;	
		}	
		if ([[target objectForKey:@"type"] isEqualToString:[presets stringValue]] && [customImage tag] == 9) {
			count += 1;	
		}		
	}	
	[custom release];
	return count;	
}

- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)theColumn row:(NSInteger)rowIndex {
	NSString *ident = [theColumn identifier];
	if (ident == nil){
		//got button column
		return 0;
	}
	if ([ident isEqualToString:@"value"]) {
		if ([customImage tag] == 1) {
			return [self targetAtIndex:rowIndex field:@"value"];
		}
		if ([customImage tag] == 2) {		
			return [keyCodeManager shortcutToArrowsString:[self targetAtIndex:rowIndex field:@"value"]];
		}
		if ([customImage tag] == 3) {		
			return [self targetAtIndex:rowIndex field:@"value"];
		}
		if ([customImage tag] == 9) {		
			return [self targetAtIndex:rowIndex field:@"value"];
		}		
	}
	if ([ident isEqualToString:@"name"]) {
		if ([customImage tag] == 1) {
			return [[self targetAtIndex:rowIndex field:@"value"] lastPathComponent];
		}
		if ([customImage tag] == 2) {		
			return [keyCodeManager shortcutToString:[self targetAtIndex:rowIndex field:@"value"]];
		}
		if ([customImage tag] == 3) {		
			return [self targetAtIndex:rowIndex field:@"name"];
		}		
		if ([customImage tag] == 9) {		
			return [self targetAtIndex:rowIndex field:@"name"];
		}		
	}	
	return 0;
}

- (id)targetAtIndex:(int)index field:(NSString *)field{
	NSString *key;	
	if ([customImage tag] == 9) {
		key = @"presetApps";
	}else{
		key = @"customTargets";		
	}	
	NSMutableArray *arr = [[[NSMutableArray alloc] init] autorelease];
	NSArray *custom = [[[defaults objectForKey:key] mutableCopy] autorelease];	
	for (id target in custom){
		if ([[target objectForKey:@"type"] isEqualToString:@"app"] && [customImage tag] == 1) {
			[arr addObject:[target objectForKey:field]];
		}
		if ([[target objectForKey:@"type"] isEqualToString:@"key"] && [customImage tag] == 2) {
			[arr addObject:[target objectForKey:field]];		
		}	
		if ([[target objectForKey:@"type"] isEqualToString:@"script"] && [customImage tag] == 3) {
			[arr addObject:[target objectForKey:field]];		
		}
		if ([[target objectForKey:@"type"] isEqualToString:[presets stringValue]] && [customImage tag] == 9) {
			[arr addObject:[target objectForKey:field]];		
		}		
	}	
	return [arr objectAtIndex:index];	
}

-(IBAction)customClick:(id)sender{
	if ([customImage tag] == 1) {	
		[self fileDialog:sender];
		[customSelector setToolTip:@"Click to select a new file"];		
	}
	if ([customImage tag] == 2) {
		[sender setTitle:@""];
		[customSelector setToolTip:@"Click to clear or focus"];		
		//set first reponder	
		[customWindow makeFirstResponder:keyView];
	}
	if ([customImage tag] == 3) {
		[sender setTitle:@""];		
		[customSelector setToolTip:@"Click to clear or focus"];
		//set first reponder	
		[customWindow makeFirstResponder:keyView];		
		[self runAppIfNotRunning:@"AppleScript Editor"];
	}	
	if ([customImage tag] == 9) {	
		[self fileDialog:sender];
		[customSelector setToolTip:@"Click to select a application"];		
	}	
}

-(IBAction)addCustom:(id)sender{	
	NSString *type = nil;
	NSString *value = nil;
	NSString *name = nil;	
	if ([customImage tag] == 1) {
		//NSLog(@"adding app");
		type = @"app";	
		value = [customSelector title];
		name = value;
	}
	if ([customImage tag] == 2) {
		//NSLog(@"adding key");		
		type = @"key";		
		value = [keyCodeManager arrowsStringToChars:[customSelector title]];
		name = value;		
		//set first reponder	
		[customWindow makeFirstResponder:keyView];		
	}
	if ([customImage tag] == 3) {
		//NSLog(@"adding script");
		type = @"script";
		name = [customSelector title];		
		value = [[NSPasteboard generalPasteboard] stringForType: NSStringPboardType];				
		if ([self validateAscript:value] == NO){
			[self shakeWindow:customWindow];			
			return;
		}
		//set first reponder	
		[customWindow makeFirstResponder:keyView];		
	}	
	if ([customImage tag] == 9) {
		//NSLog(@"preset app add");		
		NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Contents/Info.plist",[customSelector title]]];		
		NSDictionary *attribs = [[NSFileManager defaultManager] attributesOfItemAtPath:[customSelector title] error:nil];		
		type = [presets stringValue];				
		name = [[customSelector title] lastPathComponent];			
		value = [info objectForKey:@"CFBundleIdentifier"];		
		if (value == nil) {
			value = @"plist.less.app";
			if (![[attribs objectForKey:@"NSFileType"] isEqualToString:@"NSFileTypeRegular"]){
				[self shakeWindow:customWindow];			
				return;				
			}				
		}else {
			if (![[attribs objectForKey:@"NSFileType"] isEqualToString:@"NSFileTypeDirectory"]){
				[self shakeWindow:customWindow];			
				return;				
			}				
		}	
	}		
	
	//check text
	if ([[customSelector title] isEqualToString:@"Click here to set a new target, then (+) to save it"] || 
		[[customSelector title] isEqualToString:@"Press a key combination, then press (+) to save it"] || 
		[[customSelector title] isEqualToString:@"Type a name, copy a script to clipboard,(+) to save"] ||
		[[customSelector title] isEqualToString:@"Click here to select a app, then (+) to add it"] || 		
		[[customSelector title] length] == 0 || [value length] == 0 || [name length] == 0){
		NSLog(@"will not create %@-%@-%@",type,value,name);
		[self shakeWindow:customWindow];
		return;
	}		
	
	NSString *key;	
	if ([customImage tag] == 9) {
		key = @"presetApps";
	}else{
		key = @"customTargets";		
	}
	
	NSMutableArray *a = [[[defaults objectForKey:key] mutableCopy] autorelease];	
	NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:name,@"name",type,@"type",value,@"value",nil];
	//check duplicate
	if ([a containsObject:d]) {
		NSLog(@"will not create duplicate %@ %@",type,value);
		[self shakeWindow:customWindow];		
		return;
	}
	[a addObject:d];
	[defaults setObject:a forKey:key];	
	//NSLog(@"created %@ %@",type,value);	
	[defaults synchronize];
	[customTable reloadData];
	[self syncUI];
	[customSelector setTitle:@""];	
}

-(IBAction)delCustom:(id)sender{
	NSString *type = nil;
	NSString *field = nil;	
	if ([customImage tag] == 1) {
		type = @"app";	
		field = @"value";
	}
	if ([customImage tag] == 2) {
		type = @"key";	
		field = @"value";		
		//set first reponder	
		[customWindow makeFirstResponder:keyView];		
	}	
	if ([customImage tag] == 3) {
		type = @"script";	
		field = @"name";		
		//set first reponder	
		[customWindow makeFirstResponder:keyView];		
	}
	if ([customImage tag] == 9) {
		type = [presets stringValue];	
		field = @"value";
	}	
	id delete = nil;
	NSString *value = [self targetAtIndex:[sender selectedRow] field:field];
	
	NSString *key;	
	if ([customImage tag] == 9) {
		key = @"presetApps";
	}else{
		key = @"customTargets";		
	}	
	
	NSMutableArray *custom = [[defaults objectForKey:key] mutableCopy];	
	for (id target in custom){
		if ([[target objectForKey:@"type"] isEqualToString:type] && [[target objectForKey:field] isEqualToString:value]) {
			delete = target;
		}	
	}	
	if (delete){
		[custom removeObjectIdenticalTo:delete];
		//NSLog(@"deleted %@ %@",type,value);		
	}	
	[defaults setObject:custom forKey:key];
	[custom release];	
	[defaults synchronize];
	[customTable reloadData];
	[self syncUI];	
}

#pragma mark custom actions : Keys

-(void)customKeyPane:(id)sender{
	[customImage setImage:[[[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"ico_key"]] autorelease]];
	[customImage setTag:2];	
	[customTable reloadData];	
	[customSelector setTitle:@"Press a key combination, then press (+) to save it"];	
	[NSApp beginSheet:customWindow modalForWindow:[[self mainView] window] modalDelegate:nil didEndSelector:nil contextInfo:nil];	
	[customWindow makeFirstResponder:keyView];
}

#pragma mark custom actions : Scripts

-(void)customScriptPane:(id)sender{
	[customImage setImage:[[[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"ico_script"]] autorelease]];
	[customImage setTag:3];	
	[customTable reloadData];	
	[customSelector setTitle:@"Type a name, copy a script to clipboard,(+) to save"];	
	[NSApp beginSheet:customWindow modalForWindow:[[self mainView] window] modalDelegate:nil didEndSelector:nil contextInfo:nil];	
	[customWindow makeFirstResponder:keyView];
}

-(void)runAppIfNotRunning:(NSString*)name{
	NSArray *arr = [[NSWorkspace sharedWorkspace] launchedApplications];
	for (id app in arr){
		if ([[app valueForKey:@"NSApplicationName"] isEqualToString:name]) {
			NSLog(@"%@ is running , will not run",name);
			return;
		}
	}
	[[NSWorkspace sharedWorkspace] launchApplication:name];	
}

-(BOOL)validateAscript:(NSString *)string{
	//NSLog(@"testing [%@]",string);	
    NSDictionary *errorDict;
    NSAppleScript *scriptObject = [[NSAppleScript alloc] initWithSource:string];
    BOOL returnDescriptor = [scriptObject compileAndReturnError: &errorDict];
    [scriptObject release];
    if (returnDescriptor == NO) {
		NSLog(@"AppleScript error: %@", [errorDict objectForKey: @"NSAppleScriptErrorMessage"]);
    }	
	return returnDescriptor;			
}

#pragma mark custom actions : Apps

-(void)customAppPane:(id)sender{
	[customImage setImage:[[[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"ico_app"]] autorelease]];
	[customImage setTag:1];
	[customTable reloadData];
	[customSelector setTitle:@"Click here to set a new target, then (+) to save it"];	
	[NSApp beginSheet:customWindow modalForWindow:[[self mainView] window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[customWindow makeFirstResponder:customSelector];	
}

-(IBAction)fileDialog:(id)sender{
	NSOpenPanel *openDlg = [NSOpenPanel openPanel];
	[openDlg setCanChooseFiles:YES];
	[openDlg setCanChooseDirectories:NO];
	[openDlg setAllowsMultipleSelection:NO];
	if ([openDlg runModal] == NSOKButton){
        NSString *file = [[[openDlg URLs] objectAtIndex:0] path];
		[customSelector setTitleWithMnemonic:file];		
	}
}

#pragma mark custom actions : presetApps

-(SInt32)osxVersion{
	SInt32 version = 0;
	OSStatus rc0 = Gestalt(gestaltSystemVersion, &version);
	if(rc0 == 0){
		//NSLog(@"gestalt version=%x", version);						
	}else{
		//NSLog(@"Failed to get os version");
	}	
    return version;	
}

-(IBAction)presetAppPane:(id)sender{
	if ([self osxVersion] < 0x1060){
		[self showMsg:@"Application specific presets require OSX 10.6+ (Snow Leopard or later)."];		
		return;		
	}	
	if ([[presets stringValue] isEqualToString:@"Default"]){
		[self showMsg:@"The Default preset can not be set as application specific."];		
		return;		
	}
	if ([[presets stringValue] length] < 1){
		[self shakeWindow:[[self mainView] window]];
		return;
	}	
	[customImage setImage:[[[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"ico_window"]] autorelease]];
	[customImage setTag:9];
	[customTable reloadData];
	[customSelector setTitle:@"Click here to select a app, then (+) to add it"];	
	[NSApp beginSheet:customWindow modalForWindow:[[self mainView] window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[customWindow makeFirstResponder:customSelector];	
}

@end
