//
//  LaunchBoardMainWindow.m
//  LaunchBoard
//
//  Created by Vlad Alexa on 12/6/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "LaunchBoardMainWindow.h"
#import "LaunchWindow.h"
#import "LaunchButton.h"

static int iconSize = 64;

#if PLUGIN //set in project's GCC_PREPROCESSOR_DEFINITIONS
	#define OBSERVER_NAME_STRING @"MPPluginLaunchBoardEvent"
	#define BUTTON_OBSERVER_NAME_STRING @"MPPluginLaunchBoardButtonEvent"
#else
	#define OBSERVER_NAME_STRING @"VALaunchBoardEvent"
	#define BUTTON_OBSERVER_NAME_STRING @"VALaunchBoardButtonEvent"
#endif

@implementation LaunchBoardMainWindow

@synthesize launchWindow,query,infoText;

- (id)init{
    self = [super init];
    if(self != nil) {		
		
		//your initialization here			
		defaults = [NSUserDefaults standardUserDefaults];		
		
		//register for notifications		
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:OBSERVER_NAME_STRING object:nil];		
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(theEvent:) name:@"NSWorkspaceDidLaunchApplicationNotification" object:nil];		
        
        //check spotlight
        BOOL boo = [self isSpotlightFunctional];
        if (boo != YES) {
            NSAlert *alert =[NSAlert alertWithMessageText:@"Spotlight check failed" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Spotlight is not functional, it required for LaunchBoard to work."];
            [alert setAlertStyle:NSCriticalAlertStyle];
            [alert runModal]; 
            return self;
        }
        
        //squedule query        
        NSDictionary *appsDict = [[[defaults objectForKey:@"LaunchBoard"] objectForKey:@"settings"] objectForKey:@"appsDB"];
        if (appsDict == nil) {
            [self setupQuery];       
        }else{
            [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(setupQuery) userInfo:nil repeats:NO];            
        } 	     
		
		NSRect screen = [[NSScreen mainScreen] frame];		
		launchWindow = [[LaunchWindow alloc] initWithContentRect:NSMakeRect(0,0,screen.size.width,screen.size.height) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];			
        [launchWindow setOpaque:NO];
		[launchWindow setReleasedWhenClosed:NO];
		[launchWindow setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
		[launchWindow setLevel:NSPopUpMenuWindowLevel];
		[launchWindow setHasShadow:NO];	
 		[launchWindow setBackgroundColor:[NSColor clearColor]];		
		[launchWindow setBackgroundColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.8]];		

		launchView = [[NSView alloc] initWithFrame:NSMakeRect(0,0,screen.size.width,screen.size.height)];			
		[[launchWindow contentView] addSubview:launchView];
        
        //add text
        infoText = [[NSTextField alloc] initWithFrame:NSMakeRect((screen.size.width/2)-190,172,380,17)];
        [infoText setAlignment:NSCenterTextAlignment];
        [infoText setTextColor:[NSColor whiteColor]];
        [infoText setBackgroundColor:[NSColor clearColor]];			
        [infoText setEditable:NO];
        [infoText setBezeled:NO];
        [infoText setAlphaValue:0.5];		
        [launchView addSubview:infoText];
        [infoText release];	          
		
		pages = [[NSMutableDictionary alloc] init];
        
    }
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];    
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];	
	[launchWindow release];	
	[launchView release];
	[pages release];
    [query release];
	[super dealloc];
}

-(void)theEvent:(NSNotification*)notif{	
	if ([[notif name] isEqualToString:@"NSWorkspaceDidLaunchApplicationNotification"]) {
		NSString *activeApp = [[notif userInfo] objectForKey:@"NSApplicationPath"];			
		//NSLog(@"%@",activeApp);
		//if launched app is unknown add it to the appsDB
		[self addAppIfNew:activeApp];
	}	
	if (![[notif name] isEqualToString:OBSERVER_NAME_STRING]) {		
		return;
	}	
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]]){
		if ([[notif object] isKindOfClass:[NSString class]]){
			if ([[notif object] isEqualToString:@"deleteIcon"]){
				[self deleteIcon:[[[notif userInfo] objectForKey:@"tag"] intValue]];			
			}
			if ([[notif object] isEqualToString:@"swapIconToLeftPage"]){
				int wantedPage = [currentPage intValue]-1;
				if (wantedPage >= 1) {				
					[self swapIconPagesUpdate:[[[notif userInfo] objectForKey:@"tag"] intValue] direction:@"left"];					
					[self changePage:[pagesControl viewWithTag:wantedPage]];					
				}				
			}
			if ([[notif object] isEqualToString:@"swapIconToRightPage"]){	
				int wantedPage = [currentPage intValue]+1;
				if (wantedPage <= [pages count]) {								
					[self swapIconPagesUpdate:[[[notif userInfo] objectForKey:@"tag"] intValue] direction:@"right"];					
					[self changePage:[pagesControl viewWithTag:wantedPage]];					
				}				
			}			
		}	
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){
		if ([[notif object] isEqualToString:@"showNextPage"]){
			int wantedPage = [currentPage intValue]+1;
			if (wantedPage <= [pages count]) {				
				[self changePage:[pagesControl viewWithTag:wantedPage]];				
			}
		}
		if ([[notif object] isEqualToString:@"showPrevPage"]){
			int wantedPage = [currentPage intValue]-1;
			if (wantedPage >= 1) {
				[self changePage:[pagesControl viewWithTag:wantedPage]];				
			}			
		}		
		if ([[notif object] isEqualToString:@"cmdOn"]){
			cmdHeld = YES;
		}
		if ([[notif object] isEqualToString:@"cmdOff"]){
			cmdHeld = NO;
		}		
		if ([[notif object] isEqualToString:@"dismissLaunchBoard"]){
			[self dismiss];
		}
		if ([[notif object] isEqualToString:@"saveLaunchBoard"]){
			[self saveIconMovesOnPage:currentPage];
		}		
		if ([[notif object] isEqualToString:@"editLaunchBoard"]){
			for (NSNumber *num in pages){
				[editButton setHidden:NO];
				isEditing = YES;				
			}
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:BUTTON_OBSERVER_NAME_STRING object:@"startedEditing" userInfo:nil];			
		}	
		if ([[notif object] isEqualToString:@"showLaunchBoard"]){
			if ([launchWindow isVisible]) { 
				//NSLog(@"LaunchBoard window is already shown");
				return; 
			}	
			//CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();			
			//make window visible
			NSRect screen = [[NSScreen mainScreen] frame];
			[launchWindow setFrame:NSMakeRect(0,0,screen.size.width,screen.size.height) display:YES animate:NO];
			[launchWindow setAlphaValue:1.0];
			[launchWindow makeKeyAndOrderFront:nil]; 
            [launchWindow makeMainWindow];
            //if (![launchWindow isMainWindow]) NSLog(@"launchWindow is not main window");
			if ([pages count] == 0) {
				[self makePages];
				//make first page visible
				currentPage = [NSNumber numberWithInt:1];
				[launchView addSubview:[pages objectForKey:currentPage]];
				[self lightCurentPageDot];				
			}	
			//disable apps that are launched allready			
			[self disableApps];
			//NSLog(@"Showing LaunchBoard took %f seconds for %lu pages",CFAbsoluteTimeGetCurrent()-startTime,[pages count]);					
		}							
	}			
}

-(void)disableApps{
	NSArray *launchedApps = [[NSWorkspace sharedWorkspace] launchedApplications];
	for (NSButton *button in [[pages objectForKey:currentPage] subviews]){
		if ([self appWasLaunched:[button alternateTitle] list:launchedApps]) {
			[button setEnabled:NO];
		}else {
			[button setEnabled:YES];			
		}				
	}
}

-(void)clearAllPages{
    //remove pages
    for (NSNumber *num in pages) {
        NSView *page = [pages objectForKey:num];
        [page removeFromSuperview];
    }
    [pages removeAllObjects];    
    //remove dots
	int subviews = [[pagesControl subviews] count];
	if (subviews > 0){
		for (int i=0;i<=subviews;i++){
			[[[pagesControl subviews] lastObject] removeFromSuperview];
		}
	}          
	currentPage = [NSNumber numberWithInt:1];	
}

-(void)makePages{	
	//add icons
	NSRect screen = [[NSScreen mainScreen] frame];	
	int colMax = floor(screen.size.width/(iconSize*2))-2;
	int rowMax = floor(screen.size.height/(iconSize*2))-2;
	iconsPerPage = colMax*rowMax;
	NSDictionary *appsDict = [[[defaults objectForKey:@"LaunchBoard"] objectForKey:@"settings"] objectForKey:@"appsDB"];
    if (appsDict == nil) {
        [infoText setStringValue: @"No apps"];
        return;
    } 	
	NSArray *tempArray = [NSArray arrayWithArray:[appsDict allKeys]]; 
	NSArray *sortedArray = [tempArray sortedArrayUsingSelector:@selector(numericCompare:)];			
	int i = 0;
	for (NSString *key in sortedArray){	
		//skip negative ones
		if ([key intValue] < 0) continue;		
		i++;		
		//get icon
		NSString *path = [appsDict objectForKey:key];					
		NSImage *ico = [self getImageFromIcon:path];
		[ico setSize:NSMakeSize(iconSize,iconSize)];		
		NSNumber *pageNum = [NSNumber numberWithInt:ceil((i*1.0)/(colMax*rowMax))];				
		int pageIconNum = i-([pageNum intValue]*(colMax*rowMax))+(colMax*rowMax);
		int rowNumber = (pageIconNum-0.1) / colMax;
		int colNumber = (pageIconNum-1) % (int)colMax;
		//NSLog(@"%@ %@ row %i col %i page %i",key,path,rowNumber,colNumber,[pageNum intValue]);
		//add page
		if ([pages objectForKey:pageNum] == nil) {	
			int pageWidth = (colMax*iconSize*2)-(iconSize/1.5);
			int pageHeight = (rowMax*iconSize*2)-(iconSize/1.5);	
			wpad = screen.size.width-pageWidth;
			hpad = screen.size.height-pageHeight+130;			
			NSView *p = [[NSView alloc] initWithFrame:NSMakeRect(wpad/2,hpad/2,pageWidth,pageHeight)];						
			[pages setObject:p forKey:pageNum];
			[p release];
		}
		NSView *pageView = [pages objectForKey:pageNum];
		//add icon
        NSString *title = [path lastPathComponent];
        if ([title length] > 3) { 
            title = [title substringWithRange:NSMakeRange(0,[title length]-4)];
        }else{
            NSLog(@"%@",title);
        }   
		LaunchButton *button = [[LaunchButton alloc] initWithFrame:NSMakeRect(colNumber * (iconSize*2), rowNumber * (iconSize*2), iconSize+20, iconSize+20)];				
		[button setImage:ico];
		[button setTag:[key intValue]];
		[button setTarget:self]; 
		[button setAction:@selector(launchApp:)];			
		[button setAlternateTitle:path];
		[button setToolTip:@"Click to launch, hold to move or delete"];
		[button setAttributedTitle:[self makeTitleString:title]];
		[pageView addSubview:button];
		[button release];				
	}
	if (i > 1 && i-1 != [self maxAppsDBIndex:appsDict]) NSLog(@"DB error, positive indexes not consecutive");		
	//add pages dots
	pagesControl = [[NSView alloc] initWithFrame:NSZeroRect];
	int width = 0;
	int spacing = 14; //also the size of the dot
	for (NSNumber *num in pages){
		int i = [num intValue]-1;
		NSButton *dot = [[NSButton alloc] initWithFrame:NSMakeRect((spacing*2)*i,0,spacing,spacing)];
		NSImage *img = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"dot_black.png"]];			
		[dot setImage:img];
		[img release];
		[dot setFocusRingType:NSFocusRingTypeNone];
		[dot setTarget:self];
		[dot setAction:@selector(changePage:)];
		[dot setToolTip:[NSString stringWithFormat:@"Page %@ (swipe left/right to change)",num]];		
		[dot setTag:[num intValue]];					
		[dot setImagePosition:NSImageOnly];
		[dot setButtonType:NSMomentaryChangeButton];
		[dot setBordered:NO];					
		[pagesControl addSubview:dot];
		width += dot.frame.size.width+spacing;
		[dot release];
	}
	pagesControl.frame = NSMakeRect((screen.size.width/2)-((width-spacing)/2),150,width-spacing,26);				
	[launchView addSubview:pagesControl];
	[pagesControl release];
	//add edit button
	editButton = [[NSButton alloc] initWithFrame:NSMakeRect((screen.size.width/2)-(109/2),100,109,19)];
	[editButton setBezelStyle:NSRecessedBezelStyle];
	[editButton setTitle:@"Exit edit mode"];	
	[editButton setTarget:self]; 
	[editButton setAction:@selector(exitEdit:)];
	[editButton setHidden:YES];
	[launchView addSubview:editButton];	
	[launchView addSubview:[pages objectForKey:currentPage]];

	//wooble if editing
	if (isEditing == YES) {
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:BUTTON_OBSERVER_NAME_STRING object:@"startedEditing" userInfo:nil];					
	}	
		
}

#pragma mark actions

-(void)saveIconMovesOnPage:(NSNumber*)num{
	NSMutableDictionary *appsDict = [[[[defaults objectForKey:@"LaunchBoard"] objectForKey:@"settings"] objectForKey:@"appsDB"] mutableCopy];
	NSMutableDictionary *appsDictChanges = [NSMutableDictionary dictionaryWithCapacity:1];
	int i = 0;
	NSView *page = [pages objectForKey:num];
	for (NSButton *b in [page subviews]){		
		int newDBid = i+(([num intValue]-1)*iconsPerPage);
		int oldDBid = [b tag];			
		if (newDBid != oldDBid) {
			//icon was moved		
			NSString *oldKey = [NSString stringWithFormat:@"%i",oldDBid];
			NSString *newKey = [NSString stringWithFormat:@"%i",newDBid];						
			NSString *appPath = [appsDict objectForKey:oldKey];			
			if (appPath) {				
				//update the change in the db				
				[appsDictChanges setObject:appPath forKey:newKey];
				//NSLog(@"Saved app %@ moved from index %@ to %@",appPath,oldKey,newKey);				
				//update the change in it's tag
				[b setTag:newDBid];
			}else {
				NSLog(@"LaunchBoard could not find app %@ in the db",oldKey);				
			}						
		}
		i++;
	}
	[appsDict addEntriesFromDictionary:appsDictChanges];
	[self saveSetting:appsDict forKey:@"appsDB"];
	[appsDict release];
}

-(void)swapIconPagesUpdate:(int)tag direction:(NSString*)direction{
	NSRect screen = [[NSScreen mainScreen] frame];
	int colMax = floor(screen.size.width/(iconSize*2))-2;	
	int targetPageNum = 0;
	int indexOffset = 0;
	if ([direction isEqualToString:@"left"]) {
		targetPageNum = [currentPage intValue]-1;		
		indexOffset = 0+colMax-1;
	}
	if ([direction isEqualToString:@"right"]) {
		targetPageNum = [currentPage intValue]+1;		
		indexOffset = 0-colMax+1;		
	}	
	NSView *targetPage = [pages objectForKey:[NSNumber numberWithInt:targetPageNum]];	
	if (targetPage != nil) {
		NSView *sourcePage = [pages objectForKey:currentPage];
		LaunchButton *sourceButton = [sourcePage viewWithTag:tag];
		int sourceIndex = [[sourcePage subviews] indexOfObject:sourceButton];
		int targetIndex = sourceIndex+indexOffset;
		LaunchButton *targetButton = [[targetPage subviews] objectAtIndex:targetIndex];		
		NSRect sourceFrame = sourceButton.frame;
		NSRect targetFrame = targetButton.frame;		
		//switch superviews
		[sourceButton retain];
		[targetButton retain];				
		[sourceButton removeFromSuperview];
		[targetButton removeFromSuperview];	
		if ([[targetPage subviews] count] == targetIndex) {
			[targetPage addSubview:sourceButton];//there is no subview after this to position by so just add it at the end				
		}else {
			[targetPage addSubview:sourceButton positioned:NSWindowBelow relativeTo:[[targetPage subviews] objectAtIndex:targetIndex]];			
		}
		if ([[sourcePage subviews] count] == sourceIndex) {
			[sourcePage addSubview:targetButton];//there is no subview after this to position by so just add it at the end	
		}else {
			[sourcePage addSubview:targetButton positioned:NSWindowBelow relativeTo:[[sourcePage subviews] objectAtIndex:sourceIndex]];
		}
		[targetButton release];		
 		[sourceButton release];		
		//switch frames
		targetButton.frame = sourceFrame;
		sourceButton.frame = targetFrame;		
		//save to db
		[self swapIcon:tag with:[targetButton tag]];
		//switch tags
		[sourceButton setTag:[targetButton tag]];
		[targetButton setTag:tag];			
		//NSLog(@"Swapped %@ (%i) with %@ (%i)",[sourceButton alternateTitle],tag,[targetButton alternateTitle],[sourceButton tag]);		
	}else {
		NSLog(@"No page on %@ of current page",direction);
	}
}

-(void)swapIcon:(int)source with:(int)target{
	NSMutableDictionary *appsDict = [[[[defaults objectForKey:@"LaunchBoard"] objectForKey:@"settings"] objectForKey:@"appsDB"] mutableCopy];
	NSString *sourceKey = [NSString stringWithFormat:@"%i",source];
	NSString *targetKey =  [NSString stringWithFormat:@"%i",target];
	NSString *sourcePath = [appsDict objectForKey:sourceKey];	
	NSString *targetPath = [appsDict objectForKey:targetKey];
	[appsDict setObject:sourcePath forKey:targetKey];
	[appsDict setObject:targetPath forKey:sourceKey];	
	//NSLog(@"App %@ moved from index %@ to %@",sourcePath,sourceKey,targetKey);
	//NSLog(@"App %@ moved from index %@ to %@",targetPath,targetKey,sourceKey);	
	[self saveSetting:appsDict forKey:@"appsDB"];
	[appsDict release];
}

-(void)deleteIconPagesUpdate{	
	NSRect screen = [[NSScreen mainScreen] frame];
	NSDictionary *appsDict = [[[defaults objectForKey:@"LaunchBoard"] objectForKey:@"settings"] objectForKey:@"appsDB"];	
	int colMax = floor(screen.size.width/(iconSize*2))-2;
	int rowMax = floor(screen.size.height/(iconSize*2))-2;
	iconsPerPage = colMax*rowMax;	
	for (int pageNum = [currentPage intValue]; pageNum <= [pages count]; pageNum++){
		NSView *thisPage = [pages objectForKey:[NSNumber numberWithInt:pageNum]];
		//add as last the first icon on next page
		NSNumber *next = [NSNumber numberWithInt:pageNum+1];
		NSArray *views = [[pages objectForKey:next] subviews];
		if ([views count] > 0) {
			LaunchButton *moveicon = [views objectAtIndex:0];
			if (moveicon) {
				[moveicon retain];
				[moveicon removeFromSuperview];
				[thisPage addSubview:moveicon];
				[moveicon release];
				//NSLog(@"Moved %@ from page %i to %i",[moveicon alternateTitle],pageNum+1,pageNum);
			}			
		}else {
			//page has been emptied, remove it
			[[pages objectForKey:next] removeFromSuperview];			
			[pages removeObjectForKey:next];
			[[pagesControl viewWithTag:[next intValue]] removeFromSuperview];
		}
		//rearrange icons			
		int pageIconNum = 0;
		for (LaunchButton *button in [thisPage subviews]){			
			pageIconNum++;			
			int rowNumber = (pageIconNum-0.1) / colMax;
			int colNumber = (pageIconNum-1) % (int)colMax;			
			NSString *key = [[appsDict allKeysForObject:[button alternateTitle]] lastObject];			
			if (button.tag != [key intValue]) {
				//NSLog(@"changing %i to %@",button.tag,key);
				button.frame = NSMakeRect(colNumber * (iconSize*2), rowNumber * (iconSize*2), iconSize+20, iconSize+20);
				[button setTag:[key intValue]];				
			}			
		}		
	}	
}

-(void)deleteIcon:(int)tag{
	NSDictionary *appsDict = [[[defaults objectForKey:@"LaunchBoard"] objectForKey:@"settings"] objectForKey:@"appsDB"];
	NSString *oldKey = [NSString stringWithFormat:@"%i",tag];
	NSString *appPath = [appsDict objectForKey:oldKey];
	if (appPath) {
		//change the index in the DB to negative		
		int index = [self minAppsDBIndex:appsDict]-1;		
		NSMutableDictionary *newAppsDict = [appsDict mutableCopy];
		[newAppsDict removeObjectForKey:oldKey];
		[newAppsDict setObject:appPath forKey:[NSString stringWithFormat:@"%i",index]];
		//shift all the icons after it -1
		for (NSString *icon in appsDict){
			if ([icon intValue] > tag)	[newAppsDict setObject:[appsDict objectForKey:icon] forKey:[NSString stringWithFormat:@"%i",[icon intValue]-1]];				
		}
		//remove the last now duplicate icon
		int lastindex = [self maxAppsDBIndex:appsDict];
		[newAppsDict removeObjectForKey:[NSString stringWithFormat:@"%i",lastindex]];		
		[self saveSetting:newAppsDict forKey:@"appsDB"];		
		//NSLog(@"Moved app %@ from index %i to %i",appPath,tag,index);
		[newAppsDict release];
		//remove the icon from the view
		NSView *page = [pages objectForKey:currentPage];
		LaunchButton *button = [page viewWithTag:tag];
		[button removeFromSuperview];
		//update UI
		[self deleteIconPagesUpdate];
	} else {
		NSLog(@"Failed to delete %i",tag);		
	}	
}	

-(void)launchApp:(id)sender{
	if (isChangingPage == YES) {
		//skip if a change is in progress (seems to still work)			
		return;
	}	
	if (cmdHeld == YES) {
		//open the holding directory instead
		NSString *filename = [[sender alternateTitle] lastPathComponent];
		NSString *folder = [[sender alternateTitle] stringByReplacingOccurrencesOfString:filename withString:@""];
		[[NSWorkspace sharedWorkspace] openFile:folder];
		NSLog(@"Opening %@",folder);
		[self dismiss];
	}else {
		//launch the app
		NSString *path = [sender alternateTitle];
		NSLog(@"Launching %@",path);
		[[NSWorkspace sharedWorkspace] launchApplication:[path lastPathComponent]];	
		[self animateChange:sender newrect:NSMakeRect([sender frame].origin.x,[sender frame].origin.y+5, iconSize+20, iconSize+20)];		
		[NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(dimHalf) userInfo:nil repeats:NO];		
		[NSTimer scheduledTimerWithTimeInterval:0.6 target:self selector:@selector(dismiss) userInfo:nil repeats:NO];		
	}		
}

-(void)changePage:(id)sender{
	if (isChangingPage == YES) return; //skip if a change is in progress (seems to still work)
	if ([currentPage intValue] == [sender tag]) return; //skip if wanted page is allready the current
	isChangingPage = YES;
	NSNumber *pageNum = [NSNumber numberWithInt:[sender tag]];
	NSView *oldPage = [pages objectForKey:currentPage];	
	NSView *newPage = [pages objectForKey:pageNum];		
	if (oldPage && newPage) {
		NSRect screen = [[NSScreen mainScreen] frame];	
		if ([currentPage intValue] > [pageNum intValue]) {
			//left to right
			newPage.frame = NSMakeRect(screen.size.width*-1,newPage.frame.origin.y,newPage.frame.size.width,newPage.frame.size.height);			
		}else {
			//right to left
			newPage.frame = NSMakeRect(screen.size.width,newPage.frame.origin.y,newPage.frame.size.width,newPage.frame.size.height);			
		}
		[launchView addSubview:newPage];		
		[self swipePage:oldPage withPage:newPage];
		currentPage = pageNum;
		//NSLog(@"Switching to page %i",[sender tag]);			
	}else {
		NSLog(@"Error changing pages");
	}
	/*
	//debug info
	for (NSButton *button in [[pages objectForKey:currentPage] subviews]){
		[button setTitle:[NSString stringWithFormat:@"%i %i",[button tag],[[[pages objectForKey:currentPage] subviews] indexOfObject:button]+(([currentPage intValue]-1)*iconsPerPage)]];	
	}
	*/
}

-(void)exitEdit:(id)sender{	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:BUTTON_OBSERVER_NAME_STRING object:@"stoppedEditing" userInfo:nil];	
	[editButton setHidden:YES];
	isEditing = NO;	
	for (NSNumber *num in pages){
		for (NSView *view in [[pages objectForKey:num] subviews]){
			[view.layer removeAnimationForKey:@"rotationAnimation"];
		}					
	}
}	

-(void) dismiss {
	[self exitEdit:nil];	
	[launchWindow orderOut:nil];
}

-(void) dimHalf {
	[launchWindow setAlphaValue:0.5];	
}

-(void) dimFull {	
	[launchWindow setAlphaValue:1.0];	
}

#pragma mark utils

-(NSImage*)getImageFromIcon:(NSString*)path{										
	NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:path];
    if ([[image representations] count] > 0) {
        NSImageRep *icoRep = [[image representations] objectAtIndex:0];		
        NSImage *ico = [[[NSImage alloc] initWithSize:[icoRep size]] autorelease];
        [ico addRepresentation:icoRep];										
        if (![ico isValid]) {
            NSLog(@"Image for %@ not valid",path);
            return [NSImage imageNamed:@"NSStopProgressFreestandingTemplate"];
        }
        return ico;
    }else{
        NSLog(@"Can not get icon for %@",path);
        return nil;
    }
}

-(NSAttributedString*)makeTitleString:(NSString*)string{	
	NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithObject:[NSFont fontWithName:@"Arial" size:11.0] forKey:NSFontAttributeName];
	[attrsDictionary setObject:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.7] forKey:NSForegroundColorAttributeName];
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowOffset:NSMakeSize(0,-1)];
	[shadow setShadowColor:[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.7]];
	[shadow setShadowBlurRadius:2];
	[attrsDictionary setObject:shadow forKey:NSShadowAttributeName];
	[shadow release];
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	[paragraphStyle setAlignment:NSCenterTextAlignment];
	[attrsDictionary setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
	[paragraphStyle release];
	NSMutableAttributedString *ret = [[NSMutableAttributedString alloc] initWithString:string attributes:attrsDictionary];
	NSMutableString *title = [ret mutableString];
	int i = 3;	
	while ([ret size].width+2 >= iconSize+20) {				
		[title replaceCharactersInRange:NSMakeRange([title length]-i,i) withString:@"..."];		
		i++;		
	}
	return [ret autorelease];	
}

-(BOOL)saveSetting:(id)object forKey:(NSString*)key{
	NSString *pluginName = @"LaunchBoard";
	if (![[object class] isKindOfClass:[NSObject class]]) {
		NSLog(@"The value to be set for %@ is not a object",key); 
		return NO;
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
    return YES;
}

-(BOOL)isSpotlightFunctional{
    NSString *appPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.vladalexa.MagicPrefs"];
	if (appPath != nil) return YES;
    return NO;
}

#pragma mark animations

- (void)swipePage:(NSView*)oldPage withPage:(NSView*)newPage{
	
	NSMutableDictionary *moveOld = [NSMutableDictionary dictionaryWithCapacity:3];
	[moveOld setObject:oldPage forKey:NSViewAnimationTargetKey];
	[moveOld setObject:[NSValue valueWithRect:[oldPage frame]] forKey:NSViewAnimationStartFrameKey];
	[moveOld setObject:[NSValue valueWithRect:NSMakeRect(newPage.frame.origin.x*-1,oldPage.frame.origin.y,oldPage.frame.size.width,oldPage.frame.size.height)] forKey:NSViewAnimationEndFrameKey];
	
	NSMutableDictionary *moveNew = [NSMutableDictionary dictionaryWithCapacity:3];
	[moveNew setObject:newPage forKey:NSViewAnimationTargetKey];
	[moveNew setObject:[NSValue valueWithRect:[newPage frame]] forKey:NSViewAnimationStartFrameKey];
	[moveNew setObject:[NSValue valueWithRect:[oldPage frame]] forKey:NSViewAnimationEndFrameKey];	

    NSViewAnimation *theAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:moveOld, moveNew, nil]];
    [theAnim setDelegate:self];	
    [theAnim setDuration:0.5];
    [theAnim setAnimationCurve:NSAnimationEaseIn];
    [theAnim startAnimation];
    [theAnim release];	
}

- (void)animationDidEnd:(NSAnimation *)animation{
	//remove old page from superview				
	for (NSNumber *num in pages){
		if ([num intValue] != [currentPage intValue]) {
			NSView *view = [pages objectForKey:num]; 
		    view.frame = NSMakeRect(wpad/2,hpad/2,view.frame.size.width,view.frame.size.height);			
			[view removeFromSuperview];
		}
	}
	//light coresponding dot
	[self lightCurentPageDot];
	isChangingPage = NO;
	//wooble if editing
	if (isEditing == YES) {
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:BUTTON_OBSERVER_NAME_STRING object:@"startedEditing" userInfo:nil];				
	}	
	//disable apps that are launched allready	
	[self disableApps];	
}

-(void)lightCurentPageDot{
	NSImage *blackDot = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"dot_black.png"]];
	NSImage *whiteDot = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"dot_white.png"]];	
	for (NSButton *dot in [pagesControl subviews]){
		if ([dot tag] == [currentPage intValue]){
			[dot setImage:whiteDot];
		}else {
			[dot setImage:blackDot];	
		}
	}
	[blackDot release];
	[whiteDot release];
}

- (void)animateChange:(id)theView newrect:(NSRect)newrect{	
	NSRect oldrect = [theView frame];
	
    //animate move up	
	NSMutableDictionary *firstViewDict = [NSMutableDictionary dictionaryWithCapacity:3];	
    [firstViewDict setObject:theView forKey:NSViewAnimationTargetKey];	
    [firstViewDict setObject:[NSValue valueWithRect:oldrect] forKey:NSViewAnimationStartFrameKey];
    [firstViewDict setObject:[NSValue valueWithRect:newrect] forKey:NSViewAnimationEndFrameKey];
	
    //animate move down
	NSMutableDictionary *secondViewDict = [NSMutableDictionary dictionaryWithCapacity:3];	
    [secondViewDict setObject:theView forKey:NSViewAnimationTargetKey];	
    [secondViewDict setObject:[NSValue valueWithRect:newrect] forKey:NSViewAnimationStartFrameKey];
    [secondViewDict setObject:[NSValue valueWithRect:oldrect] forKey:NSViewAnimationEndFrameKey];
	
    NSViewAnimation *theAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:firstViewDict,secondViewDict, nil]];
    [theAnim setDuration:0.5];
    [theAnim setAnimationCurve:NSAnimationLinear];
    [theAnim startAnimation];
    [theAnim release];		
}

#pragma mark query 

-(void)setupQuery{      
    self.query = [[[NSMetadataQuery alloc] init] autorelease];
    
    // To watch results send by the query, add an observer to the NSNotificationCenter
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryNote:) name:nil object:self.query];  
    
    // We want the items in the query to automatically be sorted by the file system name; this way, we don't have to do any special sorting
    [self.query setSortDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:(id)kMDItemFSName ascending:YES] autorelease]]];
    
    // For the groups, we want the first grouping by the path, and the second by the date. 
    [self.query setGroupingAttributes:[NSArray arrayWithObjects:(id)kMDItemPath, (id)kMDItemLastUsedDate, nil]];
    [self.query setDelegate:self];
    
    // Set the query predicate. If the query already is alive, it will update immediately
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(kMDItemContentType == 'com.apple.application-bundle') || (kMDItemContentType == 'com.apple.application-file')"];        
    [self.query setPredicate:predicate];               
    
    // In case the query hasn't yet started, start it.
    [self.query startQuery];    
}

- (NSArray*)filteredQueryResults{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
  
    for (NSMetadataItem *item in query.results) {
        NSString* name = [item valueForAttribute:(NSString*)kMDItemFSName];
        NSString* path = [item valueForAttribute:(NSString*)kMDItemPath];
        NSString* last = [item valueForAttribute:(NSString*)kMDItemLastUsedDate];	
        if ([path rangeOfString:@"/System/Library/CoreServices/"].location == NSNotFound &&
            [path rangeOfString:@"/System/Library/Image Capture/"].location == NSNotFound &&
            [path rangeOfString:@"/Library/Printers/"].location == NSNotFound &&
            [path rangeOfString:@"/Developer/Shared/Archived Applications/"].location == NSNotFound					
            ) {
            if ([self isGoodIcon:(NSString*)path] == YES) {
                [ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:name,@"name",path,@"path",last,@"time",nil]];	
            }else {
                //NSLog(@"Skipped (icon) %@",path);					
            }			
        }else {
            //NSLog(@"Skipped (path) %@",path);
        }        
    }

    return ret;
}

- (void)queryNote:(NSNotification *)note {
    // The NSMetadataQuery will send back a note when updates are happening. By looking at the [note name], we can tell what is happening
    if ([[note name] isEqualToString:NSMetadataQueryDidStartGatheringNotification]) {
        // The gathering phase has just started!
        //NSLog(@"LaunchBoard query Started gathering");
        [infoText setStringValue: @"Searching apps .."]; 
		queryTimeout = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(queryTimeout) userInfo:nil repeats:NO];         
    } else if ([[note name] isEqualToString:NSMetadataQueryDidFinishGatheringNotification]) {
        // At this point, the gathering phase will be done. You may recieve an update later on.
        //NSLog(@"LaunchBoard query Finished gathering");
        [queryTimeout invalidate];
		[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateApps) userInfo:nil repeats:NO];         
    } else if ([[note name] isEqualToString:NSMetadataQueryGatheringProgressNotification]) {
        // The query is still gatherint results...
        //NSLog(@"LaunchBoard query Progressing...");
        [infoText setStringValue: @"Searching apps ...."];        
    } else if ([[note name] isEqualToString:NSMetadataQueryDidUpdateNotification]) {
        // An update will happen when Spotlight notices that a file as added, removed, or modified that affected the search results.
        //NSLog(@"An LaunchBoard query update happened.");
		[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateApps) userInfo:nil repeats:NO];
    }
}

- (void)queryTimeout{
    if ([query isGathering]) {
        [query stopQuery];
        NSLog(@"Query timed out after 60 seconds, stoped.");
    }
}

#pragma mark update

-(void)addAppIfNew:(NSString*)appPath{
	NSDictionary *appsDict = [[[defaults objectForKey:@"LaunchBoard"] objectForKey:@"settings"] objectForKey:@"appsDB"];
	NSArray *appIndexes = [appsDict allKeysForObject:appPath];
	int index = [self maxAppsDBIndex:appsDict]+1;		
	if ([appIndexes count] < 1) {	
    	NSMutableDictionary *newAppsDict = [appsDict mutableCopy];			
		[newAppsDict setObject:appPath forKey:[NSString stringWithFormat:@"%i",index]];
		BOOL success = [self saveSetting:newAppsDict forKey:@"appsDB"];		
        if (success == YES) NSLog(@"Added new app %@ at index %i",appPath,index);            
		[newAppsDict release];
		[self clearAllPages];
	}else {	
		//unhide if negative
		if ([[appIndexes objectAtIndex:0] intValue] < 0) {
        	NSMutableDictionary *newAppsDict = [appsDict mutableCopy];	
			[newAppsDict removeObjectForKey:[appIndexes objectAtIndex:0]];			
			[newAppsDict setObject:appPath forKey:[NSString stringWithFormat:@"%i",index]];
			BOOL success = [self saveSetting:newAppsDict forKey:@"appsDB"];
	        if (success == YES) NSLog(@"Unhidden app %@ at index %i",appPath,index);
			[newAppsDict release];
			[self clearAllPages];			
		}		
	}
}

-(void)updateApps{
    [infoText setStringValue: @""];            
    NSDictionary *settings = [[defaults objectForKey:@"LaunchBoard"] objectForKey:@"settings"];		
    NSDate *lastUpdatecheck = [settings objectForKey:@"appsLastUpdate"];
    float minutessince = ([lastUpdatecheck timeIntervalSinceNow]*-1)/60;	
    if (minutessince > 1 || minutessince == 0) {	
        //NSLog(@"LaunchBoard %f minutes since last apps DB update, updating",minutessince);
    }else{
        //NSLog(@"LaunchBoard not updating, only %f minutes since last apps DB update",minutessince);        
        return;
    } 
    
	BOOL relaunch = NO;
	if ([launchWindow isVisible]) relaunch = YES;	
	[self exitEdit:nil];       
	CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();    
	NSArray *apps = [self filteredQueryResults];
    if (apps == nil) {
        NSLog(@"No apps found");
        [infoText setStringValue: @"No apps found"];
        return;
    }
	NSDictionary *appsDict = [[[defaults objectForKey:@"LaunchBoard"] objectForKey:@"settings"] objectForKey:@"appsDB"];   
	NSMutableDictionary *newAppsDict = [NSMutableDictionary dictionaryWithCapacity:1];
	int maxIndex = [self maxAppsDBIndex:appsDict];
	if (maxIndex == 0) maxIndex = -1; //properly start at 0 in case of empty db	
	for (NSDictionary *appInfo in apps){
		NSString *appPath = [appInfo objectForKey:@"path"];
		//self.lastFoundPath = appPath;	//needs async search to update UI	
		NSArray *appIndexes = [appsDict allKeysForObject:appPath];
		if ([appIndexes count] < 1) {
			//app is new, add and increment max index			
			maxIndex += 1;
			[newAppsDict setObject:appPath forKey:[NSString stringWithFormat:@"%i",maxIndex]];							
			//NSLog(@"Added new app %@ at index %i",appPath,maxIndex);
		}else if ([appIndexes count] == 1) {
			//app is known, add at old index
			[newAppsDict setObject:appPath forKey:[appIndexes objectAtIndex:0]];			
		}else {
			for (NSString *key in appIndexes){
				if (key == [appIndexes objectAtIndex:0]) continue;
				NSLog(@"Deleted app %@ from duplicate index of %@ (%@)",appPath,[appIndexes objectAtIndex:0],key);				
			}
		}
	}	

	if (appsDict != nil){
		//reorder the indexes
		NSMutableDictionary *reorderedNewAppsDict = [NSMutableDictionary dictionaryWithCapacity:1];	
		NSArray *tempArray = [NSArray arrayWithArray:[newAppsDict allKeys]]; 
		NSArray *sortedArray = [tempArray sortedArrayUsingSelector:@selector(numericCompare:)];	
		int i = 0;
		for (NSString *key in sortedArray){	
			if ([key intValue] < 0) {
				[reorderedNewAppsDict setObject:[newAppsDict objectForKey:key] forKey:key];			
			}else{
				[reorderedNewAppsDict setObject:[newAppsDict objectForKey:key] forKey:[NSString stringWithFormat:@"%i",i]];						
				i++;
			}
		}		
		[self saveSetting:reorderedNewAppsDict forKey:@"appsDB"];
	}else if (newAppsDict != nil) {
		[self saveSetting:newAppsDict forKey:@"appsDB"];				
	}else{
        NSLog(@"Error saving applications database."); 
        [infoText setStringValue: @"Error saving applications database."];        
        return;        
    }
	[self saveSetting:[NSDate date] forKey:@"appsLastUpdate"];	
	NSLog(@"LaunchBoard db save took %f seconds for %lu apps",CFAbsoluteTimeGetCurrent()-startTime,[apps count]);	
	if ([launchWindow isVisible]) [self dismiss];	    
	[self clearAllPages];
	if (relaunch) [[NSDistributedNotificationCenter defaultCenter] postNotificationName:OBSERVER_NAME_STRING object:@"showLaunchBoard" userInfo:nil];
}

-(int)maxAppsDBIndex:(NSDictionary*)db{
	int ret = 0;
	for (NSString *key in db){
		if ([key intValue] > ret) {
			ret = [key intValue];
		}
	}
	return ret;
}

-(int)minAppsDBIndex:(NSDictionary*)db{
	int ret = 0;
	for (NSString *key in db){
		if ([key intValue] < ret) {
			ret = [key intValue];
		}
	}
	return ret;
}

-(BOOL)appWasLaunched:(NSString*)path list:(NSArray*)list{
	if (list == nil) {
		list = [[NSWorkspace sharedWorkspace] launchedApplications];
	}
	for (id dict in list){
		if ([path isEqualToString:[dict objectForKey:@"NSApplicationPath"]]) {
			//NSLog(@"%@",path);
			return TRUE;
		}
	}	
	return FALSE;
}

-(BOOL)isGoodIcon:(NSString*)path{										
	NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:path];
    NSArray *reps = [image representations];
    if ([reps count] < 1) return NO;
	NSImageRep *icoRep = [reps objectAtIndex:0];		
	NSImage *ico = [[[NSImage alloc] initWithSize:[icoRep size]] autorelease];
	[ico addRepresentation:icoRep];										
	//check the md5 of a predefined range against a precalculated md5
	NSData *alldata = [ico TIFFRepresentation];
	if ([alldata length] > 25000) {
		NSData *chunk = [alldata subdataWithRange:NSMakeRange(25000,500)];							
		NSString *md5 = [self md5ForData:chunk];
		if ([md5 isEqualToString:@"b524cd4b59704d18e6844822b62b629f"]) return NO; //skip if app has generic app icon
		if ([md5 isEqualToString:@"7d624e0dee9a35070c0a56990a0b343d"]) return NO; //skip if app has invalid binary icon
		if ([md5 isEqualToString:@"e15066f4284a1bf09282a3833151cb9a"]) return NO; //skip if app has automator icon						
	}
	return YES;
}

- (NSString*)md5ForStr:(NSString*)input {
    const char* str = [input UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, strlen(str), result);
	
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}

- (NSString*)md5ForData:(NSData*)input {
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5([input bytes],[input length],result);
	
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}


@end


@implementation NSString (StringAdditions)

- (NSComparisonResult)numericCompare:(NSString*)str{
    return [self compare:str options:NSNumericSearch];
}

@end
