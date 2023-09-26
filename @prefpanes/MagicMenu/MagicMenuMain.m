//
//  MagicMenuMain.m
//  MagicMenu
//
//  Created by Vlad Alexa on 2/1/10.
//  Copyright (c) 2010 NextDesign. All rights reserved.
//

#import "MagicMenuMain.h"

#define PREFS_PLIST_DOMAIN @"com.vladalexa.MagicPrefs.MagicPrefsPlugins"

@implementation MagicMenuMain

- (void) mainViewDidLoad
{

	//blank the labels	
	[topLabel setTitleWithMnemonic:@""];
	[bottomLabel setTitleWithMnemonic:@""];
	[leftLabel setTitleWithMnemonic:@""];
	[rightLabel setTitleWithMnemonic:@""];		
	
	//register for notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MPprefpaneMMMainEvent" object:nil];	
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MPprefpaneMMMainEvent" object:nil];		

	//alloc keymanager
	keyCodeManager = [[KeyCodeManager alloc] init];
	
	//sync ui	
	[self syncUI];	
}

- (void)awakeFromNib
{
	
	//NSLog(@"awakeFromNib");	
	
	NSMutableDictionary *fdict = [NSMutableDictionary dictionaryWithCapacity:1];	
	//track buttons changing image
    NSTrackingArea *area;		
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"41",@"posx",@"194",@"posy",nil] forKey:@"1"];	
    area = [[NSTrackingArea alloc] initWithRect:[topItem frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:topItem,@"object",@"select.png",@"image",[[fdict copy] autorelease],@"fingers",@"180",@"rotate",nil]];	
    [topItem addTrackingArea:area];
    [area release];
	[fdict removeAllObjects];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"41",@"posx",@"69",@"posy",nil] forKey:@"1"];	
    area = [[NSTrackingArea alloc] initWithRect:[bottomItem frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:bottomItem,@"object",@"select.png",@"image",[[fdict copy] autorelease],@"fingers",nil]];	
    [bottomItem addTrackingArea:area];
    [area release];
	[fdict removeAllObjects];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"41",@"posx",@"109",@"posy",nil] forKey:@"1"];			
    area = [[NSTrackingArea alloc] initWithRect:[leftItem frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:leftItem,@"object",@"select_.png",@"image",[[fdict copy] autorelease],@"fingers",@"90",@"rotate",nil]];	
    [leftItem addTrackingArea:area];
    [area release];
	[fdict removeAllObjects];
	
	[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"state",@"167",@"posx",@"109",@"posy",nil] forKey:@"1"];		
    area = [[NSTrackingArea alloc] initWithRect:[rightItem frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:rightItem,@"object",@"select_.png",@"image",[[fdict copy] autorelease],@"fingers",@"-90",@"rotate",nil]];	
    [rightItem addTrackingArea:area];
    [area release];
	[fdict removeAllObjects];	
	
}

-(void)saveSetting:(id)object forKey:(NSString*)key{
	NSString *pluginName = @"MagicMenu";	
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
    
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"VAUserDefaultsUpdate" object:PREFS_PLIST_DOMAIN userInfo:nil];    
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
    NSMutableDictionary* firstViewDict;
	
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
	
	[self syncMenuImage];
	
	//load image
	NSMutableDictionary *d = [(NSDictionary *)[event userData] mutableCopy];
	[d setObject:@"hover" forKey:@"what"];		
	[[NSNotificationCenter defaultCenter] postNotificationName:@"menuimgEvent" object:@"local" userInfo:d];	
	//set the gradient
	if ([[[[[d objectForKey:@"object"] superview] subviews] objectAtIndex:0] isMemberOfClass:[NSImageView class]]){
		//NSLog(@"gradient found");			
		[self animateChange:[[[[d objectForKey:@"object"] superview] subviews] objectAtIndex:0] newrect:NSMakeRect(25,[[d objectForKey:@"object"] frame].origin.y, 330, 26)];	
	}else {
		//NSLog(@"no gradient yet , wil create");
		NSImageView *aView = [[NSImageView alloc] initWithFrame:NSMakeRect(25,[[d objectForKey:@"object"] frame].origin.y, 330, 26)];	
		NSImage *gradient = [[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"gradient"]];
		[aView setImageScaling:NSScaleNone];
		[aView setImage:gradient];	
		[[[d objectForKey:@"object"] superview] addSubview:aView positioned:NSWindowBelow relativeTo:[[[[d objectForKey:@"object"] superview] subviews] objectAtIndex:0]];
		[aView release];
		[gradient release];
	}
	[d release];	
}

-(void)mouseExited:(NSEvent *)event {
	//CFShow([event userData]);
}

-(void)theEvent:(NSNotification*)notif{			
	if (![[notif name] isEqualToString:@"MPprefpaneMMMainEvent"]) {
		return;
	}		
	if ([[notif object] isKindOfClass:[NSString class]]){					
		if ([[notif object] isEqualToString:@"ArrowON"]){			
			[keyView setImage:[NSImage imageNamed:@"NSGoRightTemplate"]];
		}	
		if ([[notif object] isEqualToString:@"ArrowOFF"]){
			[keyView setImage:nil];
		}					
	}			
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]]){
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

-(void)syncUI{
	
	NSDictionary *settings = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN] objectForKey:@"MagicMenu"] objectForKey:@"settings"];	
	
	//update triggers
	NSMenu *triggerMenu = [[NSMenu alloc] initWithTitle:@"Triggers"];	
	[triggerMenu addItemWithTitle:@"Tap the apple stem" action:nil keyEquivalent:@""];
	[triggerMenu addItemWithTitle:@"Tap with 3 fingers" action:nil keyEquivalent:@""];
	[triggerMenu addItemWithTitle:@"One Finger Middle Axis Click" action:nil keyEquivalent:@""];
	[triggerMenu addItemWithTitle:@"Three Finger Click" action:nil keyEquivalent:@""];
	[theTrigger setMenu:triggerMenu];
	[triggerMenu release];	
	[theTrigger selectItemWithTitle:[settings objectForKey:@"mm_Trigger"]];
	
	//update slider	
	[delaySlider setIntValue:[[settings objectForKey:@"mm_Delay"] intValue]];
	
	//update slider	
	[sensSlider setIntValue:[[settings objectForKey:@"mm_SelectSens"] intValue]];		
	
	//update icoToggle
	BOOL boo = [[settings objectForKey:@"mm_Disabled"] boolValue];		
	if (boo) {					
		[onoffToggle setSelectedSegment:1];			
	}else{
		[onoffToggle setSelectedSegment:0];
	}	
	
	//update presets
	[self addPresets];		
	
	//loop all subviews of tabview
	for (id view in [settingsBox subviews]){
		for (id obj in [view subviews]){
			if ([obj isMemberOfClass:[NSButton class]]){
				//toggle button checks
				[self togCheck:obj];
			}
			if ([obj isMemberOfClass:[NSPopUpButton class]]){
				//add popup values
				[self addPop:obj];
			}		
		}		
	}	
	
}

-(void)addPop:(id)sender{	
	NSDictionary *settings = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN] objectForKey:@"MagicMenu"] objectForKey:@"settings"];		
	NSMenu *targetMenu = [[NSMenu alloc] initWithTitle:@"Targets"];
	[targetMenu addItemWithTitle:@"Cut" action:nil keyEquivalent:@""];
	[targetMenu addItemWithTitle:@"Copy" action:nil keyEquivalent:@""];
	[targetMenu addItemWithTitle:@"Paste" action:nil keyEquivalent:@""];
	[targetMenu addItem:[NSMenuItem separatorItem]];
	[targetMenu addItemWithTitle:@"Save" action:nil keyEquivalent:@""];
	[targetMenu addItemWithTitle:@"Close" action:nil keyEquivalent:@""];
	[targetMenu addItemWithTitle:@"Open" action:nil keyEquivalent:@""];
	[targetMenu addItemWithTitle:@"New" action:nil keyEquivalent:@""];	
	[targetMenu addItem:[NSMenuItem separatorItem]];		
	[targetMenu addItemWithTitle:@"Tweet" action:nil keyEquivalent:@""];
	[targetMenu addItemWithTitle:@"Read Tweets" action:nil keyEquivalent:@""];
	[targetMenu addItemWithTitle:@"Google Reader" action:nil keyEquivalent:@""];	
	[targetMenu addItem:[NSMenuItem separatorItem]];	
	
	if ([sender tag] == 1){		
		[targetMenu addItemWithTitle:@"Switch Space Up" action:nil keyEquivalent:@""];	
	}	
	if ([sender tag] == 2){		
		[targetMenu addItemWithTitle:@"Switch Space Left" action:nil keyEquivalent:@""];		
	}	
	if ([sender tag] == 3){		
		[targetMenu addItemWithTitle:@"Switch Space Right" action:nil keyEquivalent:@""];		
	}	
	if ([sender tag] == 4){		
		[targetMenu addItemWithTitle:@"Switch Space Down" action:nil keyEquivalent:@""];		
	}	
	if ([sender tag] == 1 || [sender tag] == 4){		
		[targetMenu addItemWithTitle:@"Hide All Other Applications" action:nil keyEquivalent:@""];		
		[targetMenu addItemWithTitle:@"UnHide All Applications" action:nil keyEquivalent:@""];			
	}	
	
	//custom actions submenu
	[targetMenu addItem:[NSMenuItem separatorItem]];	
	[targetMenu addItemWithTitle:@"Custom Actions" action:nil keyEquivalent:@""];		
	
	NSImage *appImg = [[[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"ico_app"]] autorelease];
	NSImage *keyImg = [[[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"ico_key"]] autorelease];
	NSImage *scriptImg = [[[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"ico_script"]] autorelease];	
	NSArray *custom = [[settings objectForKey:@"mm_customTargets"] mutableCopy];
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
	
	[[targetMenu itemWithTitle:@"Custom Actions"] setImage:[[[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"ico_custom"]] autorelease]];
	//[[targetMenu itemWithTitle:@"left"] setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"baro"))]];	
	//[[targetMenu itemWithTitle:@"right"] setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"faro"))]];	
	[[targetMenu itemWithTitle:@"Switch Space Left"] setImage:[NSImage imageNamed:@"NSMenuSubmenuLeft"]];	
	[[targetMenu itemWithTitle:@"Switch Space Right"] setImage:[NSImage imageNamed:@"NSMenuSubmenu"]];	
	[[targetMenu itemWithTitle:@"Switch Space Up"] setImage:[NSImage imageNamed:@"NSMenuScrollUp"]];	
	[[targetMenu itemWithTitle:@"Switch Space Down"] setImage:[NSImage imageNamed:@"NSMenuScrollDown"]];
	[[targetMenu itemWithTitle:@"Hide All Other Applications"] setImage:[NSImage imageNamed:@"NSStopProgressTemplate"]];
	[[targetMenu itemWithTitle:@"UnHide All Applications"] setImage:[NSImage imageNamed:@"NSRefreshTemplate"]];		
	
	[sender setMenu:targetMenu];
	[targetMenu release];
	
	NSDictionary *dict = [settings objectForKey:@"mm_bindings"];
	[sender selectItemWithTitle:[[dict objectForKey:[NSString stringWithFormat:@"%i",[sender tag]]]	objectForKey:@"target"]];
}

-(void)togCheck:(id)sender{	 
	NSDictionary *settings = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN] objectForKey:@"MagicMenu"] objectForKey:@"settings"];	
	NSString *tag = [NSString stringWithFormat:@"%i",[sender tag]];	
	NSDictionary *dict = [settings objectForKey:@"mm_bindings"];	
	[sender setState:[[[dict objectForKey:tag] objectForKey:@"state"] intValue]];	
}

-(void)addPresets{
	NSDictionary *settings = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN] objectForKey:@"MagicMenu"] objectForKey:@"settings"];	
	int count;
	NSArray	*arr = [settings objectForKey:@"mm_presetApps"];
	NSDictionary *dict = [settings objectForKey:@"mm_presets"];
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

-(void)checkItemWithTag:(int)tag{
	//loop all subviews of tabview
	for (id view in [settingsBox subviews]){
		for (id obj in [view subviews]){	
			if ([obj isMemberOfClass:[NSButton class]] && [obj tag] == tag){
				if ([obj state] == 0) {
					[obj setState:1];								
				}
			}	
		}			
	}	
}

-(void)syncMenuImage{	
	if ([topItem state] == 1) { [topLabel setTitleWithMnemonic:[topPop title]]; }else{ [topLabel setTitleWithMnemonic:@""]; }
	if ([leftItem state] == 1) { [leftLabel setTitleWithMnemonic:[leftPop title]]; }else{ [leftLabel setTitleWithMnemonic:@""]; }
	if ([rightItem state] == 1) { [rightLabel setTitleWithMnemonic:[rightPop title]]; }else{ [rightLabel setTitleWithMnemonic:@""]; }	
	if ([bottomItem state] == 1) { [bottomLabel setTitleWithMnemonic:[bottomPop title]]; }else{ [bottomLabel setTitleWithMnemonic:@""]; }		
}

#pragma mark ibactions

-(IBAction)togOnOff:(id)sender {
	if ([onoffToggle selectedSegment] == 0) {
		[self saveSetting:[NSNumber numberWithBool:NO] forKey:@"mm_Disabled"];		
	}
	if ([onoffToggle selectedSegment] == 1) {
		[self saveSetting:[NSNumber numberWithBool:YES] forKey:@"mm_Disabled"];			
	}			
}

-(IBAction)updateTrigger:(id)sender {		
	[self saveSetting:[sender title] forKey:@"mm_Trigger"];				
}

-(IBAction)updateDelay:(id)sender {	
	[self saveSetting:[NSNumber numberWithInt:[delaySlider intValue]] forKey:@"mm_Delay"];		
}

-(IBAction)updateSens:(id)sender {	
	[self saveSetting:[NSNumber numberWithInt:[sensSlider intValue]] forKey:@"mm_SelectSens"];		
}

-(IBAction) selectedPop:(id) sender{
	NSDictionary *settings = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN] objectForKey:@"MagicMenu"] objectForKey:@"settings"];	
	NSString *tag = [NSString stringWithFormat:@"%i",[sender tag]];
	NSMutableDictionary *dict = [[settings objectForKey:@"mm_bindings"] mutableCopy];
	NSMutableDictionary *d = [[[dict objectForKey:tag] mutableCopy] autorelease];
	if (d == nil){
		d = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"0",@"state",@"N/A",@"target",nil];
	}	
	[d setObject:[sender title] forKey:@"target"];
	[dict setObject:d forKey:tag];	
	[self saveSetting:dict forKey:@"mm_bindings"];
	[dict release];	
	//also check coresponding button	
	[self checkItemWithTag:[sender tag]];
	[self checkClick:sender];
} 

-(IBAction) checkClick:(id) sender{	
	NSDictionary *settings = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN] objectForKey:@"MagicMenu"] objectForKey:@"settings"];	
	NSString *tag = [NSString stringWithFormat:@"%i",[sender tag]];
	NSMutableDictionary *dict = [[settings objectForKey:@"mm_bindings"] mutableCopy];
	NSMutableDictionary *d = [[[dict objectForKey:tag] mutableCopy] autorelease];
	if (d == nil){
		d = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"0",@"state",@"N/A",@"target",nil];
	}
	[d setObject:[NSString stringWithFormat:@"%i",[sender state]] forKey:@"state"];
	[dict setObject:d forKey:tag];	
	[self saveSetting:dict forKey:@"mm_bindings"];	
	[dict release];	
	[self syncMenuImage];	
}


-(IBAction) helpPressed:(id) sender{
	[topLabel setTitleWithMnemonic:@""];
	[bottomLabel setTitleWithMnemonic:@""];
	[leftLabel setTitleWithMnemonic:@""];
	[rightLabel setTitleWithMnemonic:@""];	
	NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:@"hover",@"what",@"default.png",@"image",nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"menuimgEvent" object:@"local" userInfo:d];	
} 

-(IBAction) loadPreset:(id) sender{	
	NSDictionary *settings = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN] objectForKey:@"MagicMenu"] objectForKey:@"settings"];	
	if ([[presets stringValue] length] < 1){
		[self shakeWindow:[[self mainView] window]];		
		return;
	}		
	NSDictionary *dict = [[settings objectForKey:@"mm_presets"] objectForKey:[presets stringValue]];
	for (id key in dict){
		[self saveSetting:[dict objectForKey:key] forKey:key];
	}	
	NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:@"hover",@"what",@"background.png",@"image",nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"menuimgEvent" object:@"local" userInfo:d];		
	[self syncUI];
	[self syncMenuImage];	
}

-(IBAction) savePreset:(id) sender{	
	NSDictionary *settings = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN] objectForKey:@"MagicMenu"] objectForKey:@"settings"];	
	if ([[presets stringValue] isEqualToString:@"Default"]){
		[self showMsg:@"The Default preset can not be overwritten."];
		return;
	}	
	if ([[presets stringValue] length] < 1){
		[self shakeWindow:[[self mainView] window]];
		return;
	}		
	//dict with live settings
	NSMutableDictionary *preset = [NSMutableDictionary dictionaryWithCapacity:1];	
	[preset setObject:[settings objectForKey:@"mm_bindings"] forKey:@"mm_bindings"];		
	[preset setObject:[settings objectForKey:@"mm_Disabled"] forKey:@"mm_Disabled"];	
	[preset setObject:[settings objectForKey:@"mm_Delay"] forKey:@"mm_Delay"];
	[preset setObject:[settings objectForKey:@"mm_SelectSens"] forKey:@"mm_SelectSens"];	
	[preset setObject:[settings objectForKey:@"mm_Trigger"] forKey:@"mm_Trigger"];	
	//add it to existing	
	NSMutableDictionary *dict = [[settings objectForKey:@"mm_presets"] mutableCopy];	
	[dict setObject:preset forKey:[presets stringValue]];
	//save
	[self saveSetting:dict forKey:@"mm_presets"];	
	[dict release];
	[self addPresets];		
}

-(IBAction) deletePreset:(id) sender{
	NSDictionary *settings = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN] objectForKey:@"MagicMenu"] objectForKey:@"settings"];	
	if ([[presets stringValue] isEqualToString:@"Default"]){
		[self showMsg:@"The Default preset can not be deleted."];		
		return;		
	}
	if ([[presets stringValue] length] < 1){
		[self shakeWindow:[[self mainView] window]];
		return;
	}	
	//remove from existing	
	NSMutableDictionary *dict = [[settings objectForKey:@"mm_presets"] mutableCopy];	
	[dict removeObjectForKey:[presets stringValue]];
	//save	
	[self saveSetting:dict forKey:@"mm_presets"];	
	[dict release];	
	[self addPresets];
	[presets setStringValue:@""];	
}

#pragma mark message methods

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
		key = @"mm_presetApps";
	}else{
		key = @"mm_customTargets";		
	}		
	NSInteger count = 0;
	NSDictionary *settings = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN] objectForKey:@"MagicMenu"] objectForKey:@"settings"];	
	NSArray *custom = [[settings objectForKey:key] mutableCopy];	
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
		key = @"mm_presetApps";
	}else{
		key = @"mm_customTargets";		
	}	
	NSMutableArray *arr = [[[NSMutableArray alloc] init] autorelease];
	NSDictionary *settings = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN] objectForKey:@"MagicMenu"] objectForKey:@"settings"];	
	NSArray *custom = [[[settings objectForKey:key] mutableCopy] autorelease];	
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
		NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:[customSelector title] error:NULL];
		if (![[dict objectForKey:@"NSFileType"] isEqualToString:@"NSFileTypeDirectory"]){
			[self shakeWindow:customWindow];			
			return;				
		}		
		NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Contents/Info.plist",[customSelector title]]];		
		type = [presets stringValue];				
		name = [[customSelector title]  lastPathComponent];			
		value = [info objectForKey:@"CFBundleIdentifier"];	
	}		
	
	//check text
	if ([[customSelector title] isEqualToString:@"Click here to set a new target, then (+) to save it"] || 
		[[customSelector title] isEqualToString:@"Press a key combination, then press (+) to save it"] || 
		[[customSelector title] isEqualToString:@"Type a name, copy a script to clipboard,(+) to save"] ||
		[[customSelector title] isEqualToString:@"Click here to select a app, then (+) to add it"] || 		
		[[customSelector title] length] == 0 || [value length] == 0 || [name length] == 0){
		//NSLog(@"will not create %@ %@",type,value);
		[self shakeWindow:customWindow];
		return;
	}		
	
	NSString *key;	
	if ([customImage tag] == 9) {
		key = @"mm_presetApps";
	}else{
		key = @"mm_customTargets";		
	}

	NSDictionary *settings = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN] objectForKey:@"MagicMenu"] objectForKey:@"settings"];	
	NSMutableArray *a = [[[settings objectForKey:key] mutableCopy] autorelease];	
	NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:name,@"name",type,@"type",value,@"value",nil];
	//check duplicate
	if ([a containsObject:d]) {
		NSLog(@"will not create duplicate %@ %@",type,value);
		[self shakeWindow:customWindow];		
		return;
	}
	[a addObject:d];
	[self saveSetting:a forKey:key];	
	//NSLog(@"created %@ %@",type,value);	
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
		key = @"mm_presetApps";
	}else{
		key = @"mm_customTargets";		
	}	
	
	NSDictionary *settings = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN] objectForKey:@"MagicMenu"] objectForKey:@"settings"];	
	NSMutableArray *custom = [[settings objectForKey:key] mutableCopy];	
	for (id target in custom){
		if ([[target objectForKey:@"type"] isEqualToString:type] && [[target objectForKey:field] isEqualToString:value]) {
			delete = target;
		}	
	}	
	if (delete){
		[custom removeObjectIdenticalTo:delete];
		//NSLog(@"deleted %@ %@",type,value);		
	}	
	[self saveSetting:custom forKey:key];
	[custom release];	
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
    NSDictionary* errorDict;
    NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:string];
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
	NSOpenPanel* openDlg = [NSOpenPanel openPanel];
	[openDlg setCanChooseFiles:YES];
	[openDlg setCanChooseDirectories:NO];
	[openDlg setAllowsMultipleSelection:NO];
	if ([openDlg runModalForDirectory:nil file:nil] == NSOKButton){
		[customSelector setTitleWithMnemonic:[[openDlg filenames] objectAtIndex:0]];		
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
