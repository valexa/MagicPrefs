//
//  Written by Rainer Brockerhoff for MacHack 2002.
//  Copyright (c) 2002 Rainer Brockerhoff.
//	rainer@brockerhoff.net
//	http://www.brockerhoff.net/
//
//	This is part of the sample code for the MacHack 2002 paper "Plugged-in Cocoa".
//	You may reuse this code anywhere as long as you assume all responsibility.
//	If you do so, please put a short acknowledgement in the documentation or "About" box.
//

#import "MagicLauncher.h"


static NSBundle* pluginBundle = nil;

@implementation MagicLauncher

/*
 Plugin events : 
 showMLauncher "Recent Applications"
 
 Plugin events (nondynamic):
 N/A
 
 Plugin settings :
 N/A
 
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

//	terminateClass is called once when the plug-in won't be used again. NSBundle-based plug-ins
//	can't be unloaded at present, this capability may be added to Cocoa in the future.
//	Here we release the bundle's reference and zero out the pointer, just for form's sake.

+ (void)terminateClass {
	if (pluginBundle) {
		[pluginBundle release];
		pluginBundle = nil;
	}
}

- (id)init{
    self = [super init];
    if(self != nil) {
		
		NSString *bundleId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];					
		if ([bundleId isEqualToString:@"com.apple.systempreferences"]) return self;	
		
		//your initialization here		
		//NSLog(@"MagicLauncher init");
		
		defaults = [NSUserDefaults standardUserDefaults];		
		
		//set events
		NSDictionary *events = [NSDictionary dictionaryWithObjectsAndKeys:@"Recent Applications",@"showMLauncher",nil];
		NSMutableDictionary *dict = [[defaults objectForKey:@"MagicLauncher"] mutableCopy];
		[dict setObject:events forKey:@"events"];
		[defaults setObject:dict forKey:@"MagicLauncher"];
		[defaults synchronize];
		[dict release];			
		
		//register for notifications		
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MPPluginMagicLauncherEvent" object:nil];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(theEvent:) name:@"NSWorkspaceDidLaunchApplicationNotification" object:nil];			
		
		[self getMax];
		
		magicLauncher = [[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,[self computeX],[self computeY]) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];			
        [magicLauncher setOpaque:NO];			
		[magicLauncher setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
		[magicLauncher setLevel:NSPopUpMenuWindowLevel];
		[magicLauncher setHasShadow:YES];	
 		[magicLauncher setBackgroundColor:[NSColor clearColor]];		
		//[magicLauncher setBackgroundColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.4]];		
		//[MagicMenu blurWindow:magicLauncher];
		
		NSTrackingArea *area;	
		area = [[NSTrackingArea alloc] initWithRect:[magicLauncher frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways owner:self userInfo:nil];
		[[magicLauncher contentView] addTrackingArea:area];
		[area release];			
    }
    return self;
}

- (void)dealloc {
	[magicLauncher release];	
	[super dealloc];
}

-(void)theEvent:(NSNotification*)notif{	
	if ([[notif name] isEqualToString:@"NSWorkspaceDidLaunchApplicationNotification"]) {
		//NSString *activeApp = [[notif userInfo] objectForKey:@"NSApplicationPath"];			
		//NSLog(@"%@",activeApp);
	}	
	if (![[notif name] isEqualToString:@"MPPluginMagicLauncherEvent"]) {		
		return;
	}	
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]]){
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){
		if ([[notif object] isEqualToString:@"showMLauncher"]){
			if (active == YES) { 
				return; 
			}else{
				active = YES;
			}	
			//refresh max			
			[self getMax];
			//remove old icons
			NSArray *temp = [[[magicLauncher contentView] subviews] copy];
			for (id object in temp){
				[object removeFromSuperview];
			}
			[temp release];
			//defaults write com.apple.recentitems Applications -dict-add MaxAmount 50
			//NSDictionary *dict = [self getRecentPaths];
			//NSArray *arr = [self mdfindApps];
			NSArray *arr = [self getRecentApps];
			NSSortDescriptor *pathDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"path" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
			NSArray *sortedArr = [arr sortedArrayUsingDescriptors:[NSArray arrayWithObjects:pathDescriptor, nil]];
			NSArray *matrix = [self iconMatrixFive:arr];			
			//only make it as big as needed
			if ([arr count] < max) max = [arr count];  
			int n = 0;
			for (id d in sortedArr){
				//beyond matrix index bounds, bail
				if (n > max-1) continue;
				//no icons, do not show window
				if (max == 0) return;				
				//get matrix cords
				NSArray *co = [[matrix objectAtIndex:n] componentsSeparatedByString:@","];
				int x = [[co objectAtIndex:0] intValue];
				int y = [[co objectAtIndex:1] intValue];	
				//make icons
				NSButton *button;
				button = [[NSButton alloc] initWithFrame:NSMakeRect(x,y,32,32)];										
				NSImage *ico = [[NSWorkspace sharedWorkspace] iconForFile:[d objectForKey:@"path"]];				
				[button setImage:ico];					
				[button setBordered:NO];
				[button setTarget:self]; 
				[button setAction:@selector(iconPush:)];
				[button setTitle:[d objectForKey:@"path"]];				
				[button setToolTip:[[d objectForKey:@"name"] substringWithRange:NSMakeRange(0,[[d objectForKey:@"name"] length]-4)]];				
				[button setImagePosition: NSImageOnly];	
				[button setButtonType:NSMomentaryChangeButton];
				[[magicLauncher contentView] addSubview:button];
				[button release];
				n++;
			}
			//NSLog(@"showing magiclauncher");
			[magicLauncher setAlphaValue:0.5];
			[magicLauncher setHasShadow:YES];
			NSPoint mouseLoc = [NSEvent mouseLocation];				
			[magicLauncher setFrame:NSMakeRect(mouseLoc.x-[self computeX]/2, mouseLoc.y-[self computeY]/2,[self computeX],[self computeY]) display:YES animate:YES];			
			[magicLauncher makeKeyAndOrderFront:nil];		
			[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(dimFull) userInfo:nil repeats:NO];	
		}							
	}			
}

-(void)mouseEntered:(NSEvent *)event {
	//NSLog(@"entered magiclauncher");	
	
}

-(void)mouseExited:(NSEvent *)event {
	//NSLog(@"exited magiclauncher by mouse moved outside");
	[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(dimHalf) userInfo:nil repeats:NO];		
	[NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(dismissML) userInfo:nil repeats:NO];		
}

-(void) dismissML {	
	[magicLauncher orderOut:nil];
	active = NO;
}

-(void) dimHalf {
	[magicLauncher setAlphaValue:0.5];	
}

-(void) dimFull {	
	[magicLauncher setAlphaValue:1.0];	
}

-(void)iconPush:(id)sender{
	//NSLog(@"Launching %@",[sender title]);
	//remove old icons
	NSArray *temp = [[[magicLauncher contentView] subviews] copy];
	for (id object in temp){
		if (object != sender){
			[object removeFromSuperview];
		}	
	}
	[temp release];	
	[magicLauncher setHasShadow:NO];
	[[NSWorkspace sharedWorkspace] launchApplication:[sender title]];	
	[self animateChange:sender newrect:NSMakeRect([sender frame].origin.x,[sender frame].origin.y+5, 32, 32)];
	[NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(dimHalf) userInfo:nil repeats:NO];		
	[NSTimer scheduledTimerWithTimeInterval:0.6 target:self selector:@selector(dismissML) userInfo:nil repeats:NO];		
}

- (void)animateChange:(id)theView newrect:(NSRect)newrect{
    NSViewAnimation *theAnim;
    NSMutableDictionary *firstViewDict;	
    NSMutableDictionary *secondViewDict;		
	NSRect oldrect = [theView frame];
	
    //animate move up	
	firstViewDict = [NSMutableDictionary dictionaryWithCapacity:3];	
    [firstViewDict setObject:theView forKey:NSViewAnimationTargetKey];	
    [firstViewDict setObject:[NSValue valueWithRect:oldrect] forKey:NSViewAnimationStartFrameKey];
    [firstViewDict setObject:[NSValue valueWithRect:newrect] forKey:NSViewAnimationEndFrameKey];
	
    //animate move down
	secondViewDict = [NSMutableDictionary dictionaryWithCapacity:3];	
    [secondViewDict setObject:theView forKey:NSViewAnimationTargetKey];	
    [secondViewDict setObject:[NSValue valueWithRect:newrect] forKey:NSViewAnimationStartFrameKey];
    [secondViewDict setObject:[NSValue valueWithRect:oldrect] forKey:NSViewAnimationEndFrameKey];
	
    theAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:firstViewDict,secondViewDict, nil]];
    [theAnim setDuration:0.5];
    [theAnim setAnimationCurve:NSAnimationLinear];
    [theAnim startAnimation];
    [theAnim release];		
}

-(float)computeY{
	float height = 0;
	if (max < 11){
		height = 33;
	}else{
		height = ceil(max/10.0)*33;
	}
	return height;
}

-(float)computeX{
	float width = 0;
	if (max < 11){
		width = 33*max;
	}else{
		width = 33*10;
	}
	return width;
}

-(NSArray*)iconMatrixFive:(NSArray *)arr {
	NSMutableArray *ret = [NSMutableArray array];
	int x = 0;
	int y = 0;	
	int i;
	for (i = 0; i < max; i++) {	
		if (i%10 == 0 && i > 0) {		
			x = 0;
			y += 33;			
		}		
		[ret addObject:[NSString stringWithFormat:@"%i,%i",x,y]];		
		x += 33;				
	}	
	return ret;	
}

-(NSArray*)iconMatrix:(NSArray *)arr {
	NSMutableArray *ret = [NSMutableArray array];
	int loops = [arr count]/8;
	int origin = ([arr count]*15)/2-16;
	int dist = 0;
	int x = 0;
	int y = 0;
	int i;
	//center icon
	x = origin;
	y = origin;
	[ret addObject:[NSString stringWithFormat:@"%i,%i",x,y]];	
	//rest of icons
	for (i = 0; i <= loops; i++) {		
		dist += 32+1;
		
		//N
		x = origin;
		y = origin+dist;
		[ret addObject:[NSString stringWithFormat:@"%i,%i",x,y]];
		//E
		x = origin+dist;
		y = origin;
		[ret addObject:[NSString stringWithFormat:@"%i,%i",x,y]];		
		//S
		x = origin;
		y = origin-dist;
		[ret addObject:[NSString stringWithFormat:@"%i,%i",x,y]];
		//W
		x = origin-dist;
		y = origin;
		[ret addObject:[NSString stringWithFormat:@"%i,%i",x,y]];
		//NW
		x = origin-dist;
		y = origin+dist;
		[ret addObject:[NSString stringWithFormat:@"%i,%i",x,y]];
		//NE
		x = origin+dist;
		y = origin+dist;
		[ret addObject:[NSString stringWithFormat:@"%i,%i",x,y]];
		//SW		
		x = origin-dist;
		y = origin-dist;
		[ret addObject:[NSString stringWithFormat:@"%i,%i",x,y]];			
		//SE	
		x = origin+dist;
		y = origin-dist;
		[ret addObject:[NSString stringWithFormat:@"%i,%i",x,y]];		
	}	
	return ret;		
}	

#pragma mark lists

-(NSDictionary *)getRecentPaths{
	NSDictionary *list = nil;
	NSDictionary *plist = [[NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Library/Preferences/com.apple.recentitems.plist",NSHomeDirectory()]] retain];
	NSArray *arr = [[plist objectForKey:@"RecentApplications"] objectForKey:@"CustomListItems"];
	NSMutableArray *paths = [[NSMutableArray alloc] init];
	for (id item in arr){
		NSString *app = [item objectForKey:@"Name"];
		NSMutableString *path = [[[NSWorkspace sharedWorkspace] fullPathForApplication:app] mutableCopy];
		[path replaceOccurrencesOfString:app withString:@"" options:NSBackwardsSearch range:NSMakeRange(0, [path length])];
		if (![paths containsObject:path]) {
			[paths addObject:path];
		}
		[path release];
	}
	for (NSString *p in paths){				
		list = [self listDirRec:p];
		NSLog(@"%i",[list count]);
	}
	[paths release];
	[plist release];
	return list;
}

-(NSDictionary *)listDirRec:(NSString *)path{
	NSLog(@"%@",path);
	NSMutableDictionary *retDict = [NSMutableDictionary dictionaryWithCapacity:1];
	NSDirectoryEnumerator *contentsAtPath = [[NSFileManager defaultManager] enumeratorAtPath:path];
	if (contentsAtPath) {
		NSString *filename;
	    while (filename = [contentsAtPath nextObject]) {
			if ([filename rangeOfString:@".app"].location != NSNotFound) {
				[contentsAtPath skipDescendents];	
				NSString *p = [path stringByAppendingPathComponent:filename];				
				if ([self pathIsLaunchable:p]) {
					NSLog(@"found : %@",p);				
					[retDict setObject:[NSDictionary dictionaryWithObjectsAndKeys:[contentsAtPath fileAttributes],@"dfork",nil] forKey:filename];		
				}
			}							
		}
	} else {
		NSLog(@"cant read %@",path);
	}
	return retDict;
}

-(void)getMax{
	NSDictionary *apps = nil;	
	NSDictionary *plist = [[NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Library/Preferences/com.apple.recentitems.plist",NSHomeDirectory()]] retain];
	if ([plist objectForKey:@"RecentApplications"]){		
		apps = [plist objectForKey:@"RecentApplications"];
	} else if ([plist objectForKey:@"Applications"]) {
		apps = [plist objectForKey:@"Applications"];
	}else {
		NSLog(@"Failed to find recent applications");
	}
	if (apps){
		max = [[apps objectForKey:@"MaxAmount"] intValue];	
		if (max == 0 && magicLauncher != nil) {
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"remote" userInfo:
			 [NSDictionary dictionaryWithObjectsAndKeys:@"doAlert",@"what",
			  @"You have the number of recent applications set to zero.",@"title",
			  @"You need to set a selection other than None under Applications in System Preferences > Appearance > Number of recent items",@"text",
			  @"Open Appearance",@"action",
			  nil]
			 ];			
		}		
	}	
	[plist release];
}

-(NSArray*)getRecentApps{
	NSMutableArray *ret = [NSMutableArray array];	
	NSDictionary *plist = [[NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Library/Preferences/com.apple.recentitems.plist",NSHomeDirectory()]] retain];
	NSDictionary *apps = nil;
	if ([plist objectForKey:@"RecentApplications"]){		
		apps = [plist objectForKey:@"RecentApplications"];
	} else if ([plist objectForKey:@"Applications"]) {
		apps = [plist objectForKey:@"Applications"];
	}else {
		NSLog(@"Failed to find recent applications");
	}
	NSArray *arr = [apps objectForKey:@"CustomListItems"];	
	for (id item in arr) {
		NSString *name = [item objectForKey:@"Name"];
		NSString *path = [[NSWorkspace sharedWorkspace] fullPathForApplication:name];
		NSString *last = [self mdinfo:path attrib:kMDItemLastUsedDate];
		//NSLog(@"%@ %@ %@",name,path,last);
		if ([self appWasLaunched:path] == FALSE && name && path){
			[ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:name,@"name",path,@"path",last,@"time",nil]];			
		}			
	}
	[plist release];
	return ret;	
}

-(NSArray*)mdfindApps{
	NSMutableArray *ret = [NSMutableArray array];
	CFIndex i;
	MDQueryRef query;
	query = MDQueryCreate(kCFAllocatorDefault,
						  CFSTR("kMDItemContentType == 'com.apple.application-bundle'"),
						  NULL,
						  NULL);
	MDQueryExecute(query, kMDQuerySynchronous);
	
	CFIndex count = MDQueryGetResultCount(query);
	for (i = 0; i < count; i++) {
		MDItemRef item = (MDItemRef)MDQueryGetResultAtIndex(query, i);
		NSString* name = (NSString*)MDItemCopyAttribute(item, kMDItemFSName);
		NSString* path = (NSString*)MDItemCopyAttribute(item, kMDItemPath);
		NSString* last = (NSString*)MDItemCopyAttribute(item, kMDItemLastUsedDate);	
		//NSLog(@"%@ %@ %@",name,path,last);		
		if ([self appWasLaunched:path] == FALSE && name && path){
			[ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:name,@"name",path,@"path",last,@"time",nil]];			
		}
		if (name) [name release];
		if (path) [path release];
		if (last) [last release];		
	}
	return ret;
}

-(NSString *)mdinfo:(NSString *)str attrib:(CFStringRef)attrib{
	NSString *ret = @"";
	if ([str length] > 0){
		CFStringRef path = (CFStringRef)[NSString stringWithFormat:@"%@",str];
		MDItemRef item = MDItemCreate(kCFAllocatorDefault, path);
		if (item != NULL){
			CFStringRef r = MDItemCopyAttribute(item,attrib);		
			if (r == NULL){
				NSLog(@"NULL mdinfo %@ %@",str,attrib);	
			}else {
				ret = [NSString stringWithFormat:@"%@",r];			
				CFRelease(r);				
			}			
		}else {
			NSLog(@"mdinfo did not find %@",str);				
		}		
	}
	return ret;
}

- (BOOL)pathIsLaunchable:(NSString *)path {
	// Check to see if we can actually execute this file
	BOOL launchable = NO;
	NSURL *url = [NSURL fileURLWithPath:path];
	if (url) {
		FSRef fsRef;
		if (CFURLGetFSRef((CFURLRef)url, &fsRef)) {
			CFTypeRef archs;
			if (LSCopyItemAttribute(&fsRef, 
									kLSRolesAll, 
									kLSItemArchitecturesValidOnCurrentSystem, 
									&archs) == noErr) {
				if (archs) {
					launchable = CFArrayGetCount(archs) > 0;
					CFRelease(archs);
				}
			}
		}
	}
	return launchable;
}

-(BOOL)appWasLaunched:(NSString*)path{
	for (id dict in [[NSWorkspace sharedWorkspace] launchedApplications]){
		if ([path isEqualToString:[dict objectForKey:@"NSApplicationPath"]]) {
			//NSLog(@"%@",path);
			return TRUE;
		}
	}	
	return FALSE;
}


@end

