//
//  MagicMenu.m
//  MagicPrefs
//
//  Created by Vlad Alexa on 12/19/09.
//  Copyright 2009 NextDesign. All rights reserved.
//

#import "MagicMenu.h"

static NSBundle* pluginBundle = nil;

@implementation MagicMenu


/*
 Plugin events : 
 showMMenu "Magic Menu"
 
 Plugin events (nondynamic):
 fingerDown, fingerUp 
 
 Plugin settings :
 mm_presets.plist
 
 Plugin preferences :
 N/A					
 */ 

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
	if (self = [super initWithWindowNibName:@"MagicMenu"]) {
		
		NSString *bundleId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];					
		if ([bundleId isEqualToString:@"com.apple.systempreferences"]) return self;		

		//your initialization here		
		//NSLog(@"MagicMenu init");
		
		//init defaults
		defaults = [NSUserDefaults standardUserDefaults];		
		
		//set your events
		NSDictionary *events = [NSDictionary dictionaryWithObjectsAndKeys:@"Magic Menu",@"showMMenu",nil];
		NSMutableDictionary *dict = [[defaults objectForKey:@"MagicMenu"] mutableCopy];
		[dict setObject:events forKey:@"events"];
		[defaults setObject:dict forKey:@"MagicMenu"];
		[defaults synchronize];
		[dict release];			

		//listen for events		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MPPluginMagicMenuEvent" object:nil];		
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MPPluginMagicMenuEvent" object:nil];			
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(theEvent:) name:@"NSWorkspaceDidActivateApplicationNotification" object:nil];		
			
		//set your settings		
		NSDictionary *settings = [[defaults objectForKey:@"MagicMenu"] objectForKey:@"settings"];
		NSDictionary *presets = [NSDictionary dictionaryWithContentsOfFile:[[pluginBundle bundlePath] stringByAppendingPathComponent:@"Contents/Resources/mm_presets.plist"]];													 		

		//copy presets from bundle to user if user has none	
		if ([settings objectForKey:@"mm_presets"] == nil){			
			[self saveSetting:presets forKey:@"mm_presets"];
			//NSLog(@"copy mm_presets");		
		}	
		
		//set default preset if nothing set yet	
		if ([settings objectForKey:@"mm_bindings"] == nil){	
			NSDictionary *def = [presets objectForKey:@"Default"];
			for (id key in def){
				[self saveSetting:[def objectForKey:key] forKey:key];		
			}
			//NSLog(@"set default preset");		
		}		
		
		//copy default preset from bundle plist to user plist on every launch		
		[self syncDefaultPreset:@"mm_presets"];
		
		//check for presetApps
		if ([settings objectForKey:@"mm_presetApps"] == nil){
			[self saveSetting:[[[NSArray alloc] init] autorelease] forKey:@"mm_presetApps"];			
		}		
		
		//check for customTargets
		if ([settings objectForKey:@"mm_customTargets"] == nil){
			[self saveSetting:[[[NSArray alloc] init] autorelease] forKey:@"mm_customTargets"];			
		}		
		
		preset = [settings objectForKey:@"mm_bindings"];	
		delay = [[settings objectForKey:@"mm_Delay"] intValue];
		sens = [[settings objectForKey:@"mm_SelectSens"] intValue];			
		
		//init self window
		[self showWindow:nil];	
		
		//set options							
		//[magicMenu setBackgroundColor:[NSColor colorWithDeviceWhite:0.5 alpha:0.1]];
		[MagicMenu blurWindow:magicMenu];				
	}	
	return self;
}

	
- (void)dealloc {
	[super dealloc];
}

-(void)saveSetting:(id)object forKey:(NSString*)key{
	NSString *pluginName = @"MagicMenu";
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

-(void)syncDefaultPreset:(NSString*)what{
	//overwrite default preset of user with one from bundle
	NSDictionary *pDict = [NSDictionary dictionaryWithContentsOfFile:[pluginBundle pathForResource:what ofType:@"plist"]];
	//add it to existing	
	NSMutableDictionary *dict = [[[[defaults objectForKey:@"MagicMenu"] objectForKey:@"settings"] objectForKey:what] mutableCopy];	
	[dict setObject:[pDict objectForKey:@"Default"] forKey:@"Default"];
	//save
	[self saveSetting:dict forKey:what];		
	[dict release];
}

- (void)awakeFromNib
{	
	//NSLog(@"awake magicmenu nib loaded");	
	
    NSTrackingArea *area;	
	area = [[NSTrackingArea alloc] initWithRect:[magicMenuImg frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways owner:self userInfo:nil];
	[magicMenuImg addTrackingArea:area];
	[area release];	

	//the xib loads the icon of the host app
	[magicMenuImg setImage:[[[NSImage alloc] initWithContentsOfFile:[pluginBundle pathForImageResource:@"icon"]] autorelease]];
	
	// Hack to make background cursor setting work
	CGSSetConnectionProperty(_CGSDefaultConnection(), _CGSDefaultConnection(), (CFStringRef)@"SetsCursorInBackground", kCFBooleanTrue);
}

-(void)refreshSettings{
	[defaults synchronize];	
	NSDictionary *settings = [[defaults objectForKey:@"MagicMenu"] objectForKey:@"settings"];
	NSString *presetForApp = nil;	
	NSArray	*arr = [settings objectForKey:@"mm_presetApps"];
	for (id app in arr){
		if ([[app objectForKey:@"value"] isEqualToString:activeApp]) {
			presetForApp = [app objectForKey:@"type"];			
			//NSLog(@"using %@ preset for %@",presetForApp,activeApp);
		}
	}
	if (presetForApp) {		
		preset = [[[settings objectForKey:@"mm_presets"] objectForKey:presetForApp] objectForKey:@"mm_bindings"];
		delay = [[[[settings objectForKey:@"mm_presets"] objectForKey:presetForApp] objectForKey:@"mm_Delay"] intValue];
		sens = [[[[settings objectForKey:@"mm_presets"] objectForKey:presetForApp] objectForKey:@"mm_SelectSens"] intValue];			
	}else{			
		preset = [settings objectForKey:@"mm_bindings"];	
		delay = [[settings objectForKey:@"mm_Delay"] intValue];
		sens = [[settings objectForKey:@"mm_SelectSens"] intValue];			
	}	
}

-(void)theEvent:(NSNotification*)notif{		
	if ([[notif name] isEqualToString:@"NSWorkspaceDidActivateApplicationNotification"]) {		
		activeApp = [[[notif userInfo] objectForKey:@"NSWorkspaceApplicationKey"] bundleIdentifier];				
	}		
	if (![[notif name] isEqualToString:@"MPPluginMagicMenuEvent"]) {		
		return;
	}else {
		[self refreshSettings];
	}	
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]]){
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){
		if ([[notif object] isEqualToString:@"showMMenu"]){
			//NSLog(@"showing magicmenu");				
			action = nil;
			touchdown = FALSE;
			block = FALSE;			
			[middleImg setFrame:NSMakeRect(39,40,22,21)];			
			[NSCursor setHiddenUntilMouseMoves:YES];
			//hide selects
			[selectTop setHidden:TRUE];	
			[selectBottom setHidden:TRUE];
			[selectLeft setHidden:TRUE];
			[selectRight setHidden:TRUE];			
			//set titles			
			[self syncLabels:labelTop i:@"1"];
			[self syncLabels:labelLeft i:@"2"];
			[self syncLabels:labelRight i:@"3"];
			[self syncLabels:labelBottom i:@"4"];			
			[labelTop setTextColor:[NSColor whiteColor]];	
			[labelBottom setTextColor:[NSColor whiteColor]];
			[labelLeft setTextColor:[NSColor whiteColor]];	
			[labelRight setTextColor:[NSColor whiteColor]];			
			[magicMenu setAlphaValue:0.5];			
			NSPoint mouseLoc = [NSEvent mouseLocation];			
			[magicMenu setFrame:NSMakeRect(mouseLoc.x-50, mouseLoc.y-50, 100.0, 100.0) display:YES animate:YES];			
			[magicMenu orderFront:nil];	
			[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(dimFull) userInfo:nil repeats:NO];	
		}
		if ([[notif object] isEqualToString:@"fingerDown"]){
			//NSLog(@"finger down");	
			touchdown = TRUE;
			[self animateChange:middleImg newrect:NSMakeRect(36,37,28,27)];			
		}
		if ([[notif object] isEqualToString:@"fingerUp"]){
			//NSLog(@"finger up");				
			[self performAction];		
		}		
		if (sens <= 5) {
			if ([[notif object] isEqualToString:@"pushMMenuTop"]){	
				[self selectLabel:labelTop select:selectTop];					
			}		
			if ([[notif object] isEqualToString:@"pushMMenuBottom"]){
				[self selectLabel:labelBottom select:selectBottom];							
			}		
			if ([[notif object] isEqualToString:@"pushMMenuLeft"]){
				[self selectLabel:labelLeft select:selectLeft];			
			}		
			if ([[notif object] isEqualToString:@"pushMMenuRight"]){
				[self selectLabel:labelRight select:selectRight];	
			}			
		}
		if (sens >= 5) {
			if ([[notif object] isEqualToString:@"pushMMenuTopHard"]){	
				[self selectLabel:labelTop select:selectTop hard:TRUE];	
			}		
			if ([[notif object] isEqualToString:@"pushMMenuBottomHard"]){
				[self selectLabel:labelBottom select:selectBottom hard:TRUE];		
			}		
			if ([[notif object] isEqualToString:@"pushMMenuLeftHard"]){
				[self selectLabel:labelLeft select:selectLeft hard:TRUE];					
			}		
			if ([[notif object] isEqualToString:@"pushMMenuRightHard"]){			
				[self selectLabel:labelRight select:selectRight hard:TRUE];				
			}			
		}							
	}			
}

-(void)mouseEntered:(NSEvent *)event {
	//NSLog(@"entered magicmenu");	
	
}

-(void)mouseExited:(NSEvent *)event {
	//NSLog(@"exited magicmenu by mouse moved outside");
	block = TRUE;	
	[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(dimHalf) userInfo:nil repeats:NO];			
	[NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(dismissMM) userInfo:nil repeats:NO];		
}

-(void) selectLabel:(id)label select:(id)select {
	[self selectLabel:label select:select hard:FALSE];
}	

-(void) selectLabel:(id)label select:(id)select hard:(BOOL)hard{
	if (block == TRUE) return;
	
	//skip if same selection
	if ([[label stringValue] isEqualToString:action]){
		return;
	}	
	
	//select middle first if switching selection
	if (action != nil){
		action = nil;
		[selectTop setHidden:TRUE];	
		[selectBottom setHidden:TRUE];
		[selectLeft setHidden:TRUE];
		[selectRight setHidden:TRUE];		
		[self animateChange:middleImg newrect:NSMakeRect(36,37,28,27)];	
		return;
	}
	
	[self animateChange:middleImg newrect:NSMakeRect(39,40,22,21)];	
	action = [label stringValue];	
	
	[labelTop setTextColor:[NSColor whiteColor]];
	[labelBottom setTextColor:[NSColor whiteColor]];
	[labelLeft setTextColor:[NSColor whiteColor]];
	[labelRight setTextColor:[NSColor whiteColor]];	
	if (hard == TRUE) {
		[label setTextColor:[NSColor blackColor]];			
	}				 	
	
	[selectTop setHidden:TRUE];	
	[selectBottom setHidden:TRUE];
	[selectLeft setHidden:TRUE];
	[selectRight setHidden:TRUE];
	[select setHidden:FALSE];	
	
}

-(void) performAction{
	if (touchdown == FALSE) return;	
	
	if (block == TRUE) return;
	
	if (action != nil) {
		block = TRUE;
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPcoreEventsEvent" object:@"remote" userInfo:
		 [NSDictionary dictionaryWithObjectsAndKeys:@"doAction",@"what",action,@"action",nil]
		 ];		
		[NSTimer scheduledTimerWithTimeInterval:delay/10.0 target:self selector:@selector(dimHalf) userInfo:nil repeats:NO];			
		[NSTimer scheduledTimerWithTimeInterval:delay/10.0*2 target:self selector:@selector(dismissMM) userInfo:nil repeats:NO];		
	}else {
		[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(dimHalf) userInfo:nil repeats:NO];			
		[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(dismissMM) userInfo:nil repeats:NO];				
	}		 	
}

-(void) dismissMM {	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPcoreEventsEvent" object:@"dismissedMMenu"];	
	[NSCursor setHiddenUntilMouseMoves:NO];	
	[magicMenu orderOut:nil];
	block = FALSE;	
}

-(void) dimHalf {
	[magicMenu setAlphaValue:0.5];	
}

-(void) dimFull {	
	[magicMenu setAlphaValue:1.0];	
}

-(void) syncLabels:(id)obj i:(NSString*)i{	

	if ([[[preset objectForKey:i] objectForKey:@"state"] intValue] == 1) {
		[obj setTitleWithMnemonic:[[preset objectForKey:i] objectForKey:@"target"]];			
	}else{
		[obj setTitleWithMnemonic:@""];		
	}

}

+(void)blurWindow:(NSWindow *)window{
	CGSConnection thisConnection;
	CGSWindowFilterRef compositingFilter;
	/*
	 Compositing Types
	 Under the window   = 1 <<  0
	 Over the window    = 1 <<  1
	 On the window      = 1 <<  2
	 */
	NSInteger compositingType = 1 << 0; // Under the window
	/* Make a new connection to CoreGraphics */
	CGSNewConnection(NULL, &thisConnection);
	/* Create a CoreImage filter and set it up */
	CGSNewCIFilterByName(thisConnection, (CFStringRef)@"CIGaussianBlur", &compositingFilter);
	NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.5] forKey:@"inputRadius"];
	CGSSetCIFilterValuesFromDictionary(thisConnection, compositingFilter, (CFDictionaryRef)options);
	/* Now apply the filter to the window */
	CGSAddWindowFilter(thisConnection, [window windowNumber], compositingFilter, compositingType);
}

- (void)animateChange:(NSImageView*)theView newrect:(NSRect)newrect{
	
    NSViewAnimation *theAnim;
    NSMutableDictionary* firstViewDict;
	
    {
        firstViewDict = [NSMutableDictionary dictionaryWithCapacity:3];
        [firstViewDict setObject:theView forKey:NSViewAnimationTargetKey];
        [firstViewDict setObject:[NSValue valueWithRect:[theView frame]] forKey:NSViewAnimationStartFrameKey];
        [firstViewDict setObject:[NSValue valueWithRect:newrect] forKey:NSViewAnimationEndFrameKey];	
    }
	
    // Create the view animation object.
    theAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:firstViewDict, nil]];
    [theAnim setDuration:0.1];
    [theAnim setAnimationCurve:NSAnimationLinear];
    [theAnim startAnimation];
    [theAnim release];	
}

@end
