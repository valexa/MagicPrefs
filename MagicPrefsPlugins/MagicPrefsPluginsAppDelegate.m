//
//  MagicPrefsPluginsAppDelegate.m
//  MagicPrefsPlugins
//
//  Created by Vlad Alexa on 8/30/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "MagicPrefsPluginsAppDelegate.h"
#import "PluginsWindowController.h"
#import "MPPluginInterface.h"
#import "VAUserDefaults.h"
#import "VAValidation.h"

@implementation MagicPrefsPluginsAppDelegate

@synthesize window,pluginInstances;

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename{
	//NSLog(@"Opened %@",filename);
	[self handlePlugin:filename];
	return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	
	int v = [self checkSignature:[[NSBundle mainBundle] bundlePath]];		
	if (v != 0)  {		
		exit(v);
	}	
	
	[NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(magicPrefsCheck) userInfo:nil repeats:YES];		
	
	//alloc pluginswindow	
	//pluginsWindowController = [[PluginsWindowController alloc] init];
	
	//register for notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MPpluginsEvent" object:nil];	
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MPpluginsEvent" object:nil];		
	
	//register with growl
    /*
	NSArray *arr = [NSArray arrayWithObject:@"MagicPrefsPluginsGrowlNotif"]; 	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"GrowlApplicationRegistrationNotification" object:nil userInfo:
	 [NSDictionary dictionaryWithObjectsAndKeys:@"MagicPrefsPlugins",@"ApplicationName",
	  arr,@"AllNotifications",
	  arr,@"DefaultNotifications",
	  nil]
	 ];
    */ 
    
    //growl init
    NSBundle *myBundle = [NSBundle mainBundle];
    NSString *growlPath = [[myBundle privateFrameworksPath] stringByAppendingPathComponent:@"Growl.framework"];
    NSBundle *growlBundle = [NSBundle bundleWithPath:growlPath];
    if (growlBundle && [growlBundle load]) {
        // Register ourselves as a Growl delegate
        [GrowlApplicationBridge setGrowlDelegate:self];
    } else {
        NSLog(@"Could not load Growl.framework");
    }     
	
	//load sounds
	clickSound = [[NSSound soundNamed:@"click"] retain];
	clickOffSound = [[NSSound soundNamed:@"clickoff"] retain];	
	
	//set dock badge
	pluginCount = 0;	
	NSDockTile *tile = [[NSApplication sharedApplication] dockTile];
	[tile setBadgeLabel:[NSString stringWithFormat:@"%i",pluginCount]];		
			
	//alloc defaults
	defaults = [NSUserDefaults standardUserDefaults];
	mainDefaults = [[VAUserDefaults alloc] initWithPlist:@"com.vladalexa.MagicPrefs.plist"];	
	
	[self checkCapitalization:[self getPluginSearchPaths:@"MagicPrefs"]];
	
	[self checkPluginsList];
	
	pluginInstances = [[NSMutableArray alloc] init];
	pluginLocations = [[NSMutableArray alloc] init];
	pluginClasses = [[NSMutableArray alloc] init];
	      
    //check spotlight
    [self checkSpotlight];   
		
	//load plugins from known locations           
	[self findPluginsInLocations];	
    	
	//load plugins from MAS container apps
	[self findPluginsFromMAS];
       
	//find plugins systemwide (installs new ones on desktop or downloads)
	[self findPluginsSystemwide];	            
	
	//give MagicPrefs and the pref pane the events from the plugins
	NSDictionary *list = [self getLoadedPluginsEvents];		
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPcoreEventsEvent" object:nil userInfo:
	 [NSDictionary dictionaryWithObjectsAndKeys:@"thePluginEventsList",@"what",list,@"theList", nil]
	 ];		
	//give the list and paths to the pref pane main
	NSDictionary *paths = [self getLoadedPluginsPaths];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneMainEvent" object:nil userInfo:
	 [NSDictionary dictionaryWithObjectsAndKeys:@"getLoadedPluginsEventsCallback",@"what",list,@"list",paths,@"paths",nil]
	 ];	
	//refresh the list in the preferences
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPpluginsWindowEvent" object:nil userInfo:
	 [NSDictionary dictionaryWithObjectsAndKeys:@"getLoadedPluginsEventsCallback",@"what",list,@"list",nil]
	 ];		
	//tell the menu to refresh
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPcoreMenuEvent" object:@"ReloadMenu"];			
	
	NSDate *lastUpdatecheck = [mainDefaults objectForKey:@"pluginsLastUpdateCheck"];
	float hourssince = ([lastUpdatecheck timeIntervalSinceNow]*-1)/60/60;	
	if (hourssince > 24 || lastUpdatecheck == nil) {
		[NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(updateCheckPlugins) userInfo:nil repeats:NO];		
		NSLog(@"%f hours since last update check, checking in 1 minute",hourssince);
	}		
}

- (void)applicationWillTerminate:(NSNotification*)notification {
	NSEnumerator* enumerator;
	Class pclass;
	[window close];
	enumerator = [pluginClasses objectEnumerator];
	while ((pclass = [enumerator nextObject])) {
		[pclass terminateClass];
	}
	[pluginClasses release];
	pluginClasses = nil;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag{
	if( !flag ){
		//[pluginsWindowController.window makeKeyAndOrderFront:nil];
	}
	return YES;
}

-(void)dealloc{
	//[clickSound release];
	//[clickOffSound release];	
	//[pluginsWindowController release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];    
	[pluginLocations release];
	[pluginInstances release];
    [dockIconImage release];
	[super dealloc];    
}

-(int)checkSignature:(NSString*)path{
    NSString *launchPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Resources/ssccv"];
    NSArray *argsArray = [NSArray arrayWithObject:path];    
	if (launchPath && [[NSFileManager defaultManager] fileExistsAtPath:launchPath]) {	
		NSTask *task = [[NSTask alloc] init];
		[task setLaunchPath:launchPath];
		[task setArguments:argsArray];
        NSTimer *timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:task selector:@selector(terminate) userInfo:nil repeats:NO];        
		[task launch];
        [task waitUntilExit];
        [timeoutTimer invalidate];        
		[task release];	
        if (![task isRunning]) {
            //NSLog(@"%i:%@",[task terminationStatus],path);           
            return [task terminationStatus];
        }else {
            NSLog(@"Task %@ failed to complete.",launchPath);
        }        
	}else {
		NSLog(@"ssccv binary was not found at %@",launchPath);
	}    
    return -2;
}

-(void)checkPluginsList{
	NSDictionary *dict = [defaults persistentDomainForName:@"com.vladalexa.MagicPrefs.MagicPrefsPlugins"];	
	for (NSString *key in dict){
		if ([[dict objectForKey:key] isKindOfClass:[NSDictionary class]]) {
			if (![[dict objectForKey:key] objectForKey:@"author"]) {
				[defaults removeObjectForKey:key];					
				//NSLog(@"%@ removed pluggin setting dict with missing author",key);				
			}
		}else {
			[defaults removeObjectForKey:key];	
			NSLog(@"%@ removed plugin setting that is not dict",key);			
		}
	}
	[defaults synchronize];
}

-(void)magicPrefsCheck{
	if ([PluginsWindowController isAppRunning:@"MagicPrefs"] == NO) {
		NSLog(@"MagicPrefs not running, quitting");
		[NSApp terminate:nil];		
	}
}

-(void)theEvent:(NSNotification*)notif{	
	if (![[notif name] isEqualToString:@"MPpluginsEvent"]) {		
		return;
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){
		if ([[notif object] isEqualToString:@"doRestart"]){
            //restart it if at least one plugin is enabled, otherwise quit
            BOOL quit = YES;
            NSDictionary *pluginsDict = [defaults persistentDomainForName:@"com.vladalexa.MagicPrefs.MagicPrefsPlugins"];
            for (NSString *name in pluginsDict) {
                BOOL enabled = [[[pluginsDict objectForKey:name] objectForKey:@"enabled"] boolValue];
                if (enabled == YES) {             
                    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(restartApp) userInfo:nil repeats:NO];
                    quit = NO;
                    break;
                }
            }
            if (quit == YES) [NSTimer scheduledTimerWithTimeInterval:1 target:NSApp selector:@selector(terminate:) userInfo:nil repeats:NO]; 
		}
		if ([[notif object] isEqualToString:@"restartMagicPrefs"]){
            system("killall 'MagicPrefs'");
            [NSThread sleepForTimeInterval:1];
            //launch magicprefs if not running
            if ([PluginsWindowController isAppRunning:@"MagicPrefs"] == NO) {
                NSString *appPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.vladalexa.MagicPrefs"];        
                if (appPath != nil){	
                    NSURL *url = [NSURL fileURLWithPath:appPath];
                    [[NSWorkspace sharedWorkspace] launchApplicationAtURL:url options:NSWorkspaceLaunchDefault configuration:nil error:nil];            
                }else{
                    NSLog(@"Failed to find MagicPrefs.app");
                }			
            }           
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
		if ([[[notif userInfo] objectForKey:@"what"] isEqualToString:@"doGrowl"]){	
			NSString *title = [[notif userInfo] objectForKey:@"title"];
			NSString *message = [[notif userInfo] objectForKey:@"message"];			
			[self growlNotif:title message:message];
		}
		if ([[[notif userInfo] objectForKey:@"what"] isEqualToString:@"installPlugin"]){
			NSString *pluginPath = [[notif userInfo] objectForKey:@"path"];			
			NSLog(@"Installing %@",pluginPath);	
			[self handlePlugin:pluginPath];		
		}		
		if ([[[notif userInfo] objectForKey:@"what"] isEqualToString:@"enablePlugin"]){
			//unused, change plist and doRestart instead
			NSString *name = [[notif userInfo] objectForKey:@"name"];
			NSString *path = [[notif userInfo] objectForKey:@"path"];			
			[self enablePlugin:name];
			[self activatePlugin:path];		
		}	
		if ([[[notif userInfo] objectForKey:@"what"] isEqualToString:@"disablePlugin"]){			
			//unused, change plist and doRestart instead			
			NSString *name = [[notif userInfo] objectForKey:@"name"];
			NSString *path = [[notif userInfo] objectForKey:@"path"];			
			[self disablePlugin:name];
			[self deactivatePlugin:path];		
		}	
		if ([[[notif userInfo] objectForKey:@"what"] isEqualToString:@"getLoadedPluginsEvents"]){			
			NSString *callback = [[notif userInfo] objectForKey:@"callback"];		
			NSDictionary *list = [self getLoadedPluginsEvents];				
			NSDictionary *paths = [self getLoadedPluginsPaths];
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:callback object:nil userInfo:
			 [NSDictionary dictionaryWithObjectsAndKeys:@"getLoadedPluginsEventsCallback",@"what",list,@"list",paths,@"paths",nil]
			 ];	
		}	
		if ([[[notif userInfo] objectForKey:@"what"] isEqualToString:@"setDockIconFromFile"]){			
			NSString *imagePath = [[notif userInfo] objectForKey:@"path"];		
            NSImage *iconImage = [[NSImage alloc] initWithContentsOfFile:imagePath];
            [self setDockIconToImage:iconImage];
            [iconImage release];            
		}	
		if ([[[notif userInfo] objectForKey:@"what"] isEqualToString:@"setDockIconFromPasteboard"]){			
			NSString *pasteboardName = [[notif userInfo] objectForKey:@"name"];
            NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:pasteboardName];
            if ([pasteboard canReadObjectForClasses:[NSArray arrayWithObject:[NSImage class]] options:nil]) {
                NSArray *objectsToPaste = [pasteboard readObjectsForClasses:[NSArray arrayWithObject:[NSImage class]] options:nil];
                NSImage *iconImage = [objectsToPaste objectAtIndex:0];
                if (iconImage) [self setDockIconToImage:iconImage];
            }                        
		}        
	}	
}
	

#pragma mark actions

-(NSDictionary*)getLoadedPluginsEvents{
	NSMutableDictionary *list = [NSMutableDictionary dictionaryWithCapacity:1];	
	for (NSString *pluginName in [self pluginClassesStrings]){
		id dict = [defaults objectForKey:pluginName];
		if ([dict isKindOfClass:[NSDictionary class]]) {
			NSDictionary *d = [NSDictionary dictionaryWithDictionary:[dict objectForKey:@"events"]];
			[list setObject:d forKey:pluginName];
		}		
	}
	return list;
}

-(NSDictionary*)getLoadedPluginsPaths{
	NSMutableDictionary *list = [NSMutableDictionary dictionaryWithCapacity:1];	
	for (NSString *pluginName in [self pluginClassesStrings]){
		id dict = [defaults objectForKey:pluginName];
		if ([dict isKindOfClass:[NSDictionary class]]) {
			NSString *path = [dict objectForKey:@"path"];
			if (path) {
				[list setObject:path forKey:pluginName];				
			}
		}		
	}
	return list;
}

-(NSArray*)pluginClassesStrings{
	NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
	for (Class class in pluginClasses) {
		[ret addObject:NSStringFromClass(class)];
	}
	return ret;
}	

-(void) growlNotif:(NSString*)title message:(NSString*)message{
    /*
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"GrowlNotification" object:nil userInfo:
	 [NSDictionary dictionaryWithObjectsAndKeys:@"MagicPrefsPlugins",@"ApplicationName",@"MagicPrefsPluginsGrowlNotif",@"NotificationName",
	  title,@"NotificationTitle",
	  message,@"NotificationDescription",
	  nil]
	 ];		
    */
    
    NSUserNotification *notif = [[NSUserNotification alloc] init];
    if (notif) {
        [notif setTitle:title];
        [notif setInformativeText:message];
        NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
        [center deliverNotification:notif];
        [notif release];
    }else {
        NSImage *icon = [NSImage imageNamed:@"icon"];
        [GrowlApplicationBridge notifyWithTitle:title description:message notificationName:@"MagicPrefsPluginsGrowlNotif" iconData:[icon TIFFRepresentation] priority:1 isSticky:NO clickContext:nil]; 	        
    }    
}	

-(NSDictionary *)registrationDictionaryForGrowl{
    NSArray *notifications = [NSArray arrayWithObject:@"MagicPrefsPluginsGrowlNotif"];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          notifications, GROWL_NOTIFICATIONS_ALL,
                          notifications, GROWL_NOTIFICATIONS_DEFAULT, nil];    
    return (dict);
}

-(void) restartApp{
    //use Magicprefs to restart ourselves
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"RestartPluginsHost" userInfo:nil]; 
    /*
	//ignores plist launch settings and freezes if launched from xcode
	NSString *fullPath = [[NSBundle mainBundle] executablePath];
	[NSTask launchedTaskWithLaunchPath:fullPath arguments:[NSArray arrayWithObjects:nil]];
	[NSApp terminate:self];
    */ 
}

- (IBAction) alertAction:(id)sender{
	if ([[sender title] isEqualToString:@"Open Bluetooth"]) {
		[[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/Bluetooth.prefPane"];	
	}	
	[[NSApp keyWindow] close];
}

#pragma mark update

-(void)updateCheckPlugins{
	[mainDefaults setObject:[NSDate date] forKey:@"pluginsLastUpdateCheck"];
	[mainDefaults synchronize];
    //update local copy of the db
    NSString *pluginsDb = [NSString stringWithFormat:@"%@/Library/Application Support/MagicPrefs/PlugIns/pluginsdb.plist",NSHomeDirectory()];
    NSDictionary *db = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:@"http://magicprefs.com/plugins/pluginsdb.plist"]];
    [db writeToFile:pluginsDb atomically:YES];    
    //check each plugin
	NSDictionary *dict = [defaults persistentDomainForName:@"com.vladalexa.MagicPrefs.MagicPrefsPlugins"];	
	for (NSString *key in dict){
		NSString *curVersion = [[dict objectForKey:key] objectForKey:@"version"];
		NSString *url = [NSString stringWithFormat:@"%@%@.plist",[[dict objectForKey:key] objectForKey:@"url"],key];
		if ([url rangeOfString:@"http://"].location != NSNotFound) {
			//NSLog(@"Update checking %@ for a update to v%@",url,curVersion);
			VAUrlConnection *conn = [[VAUrlConnection alloc] initWithURL:url delegate:self];	
			conn.name = curVersion;
			[conn release];				
		}
	}
}

- (void) connectionDidFinish:(VAUrlConnection *)theConnection{
	//NSLog(@"Got %@",theConnection.url);
	NSString *string = [[[NSString alloc] initWithData:theConnection.receivedData encoding:NSUTF8StringEncoding] autorelease];
	if (theConnection.statusCode < 400){
		id dict = [string propertyList];
		if ([dict isKindOfClass:[NSDictionary class]]) {
			for (NSString *ver in dict){
				if ([ver floatValue] > [theConnection.name floatValue]) {					
					NSString *urlString = [theConnection.url stringByReplacingOccurrencesOfString:@".plist" withString:@".MPplugin.zip"];
					NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];      
					NSURLDownload *download = [[NSURLDownload alloc] initWithRequest:request delegate:self];						
					NSLog(@"Found update from %@ to %@ at %@, downloading %@",theConnection.name,ver,theConnection.url,urlString);
					[download release];
                    return;
				}
			}
		}else {
			NSLog(@"Data at %@ is not a valid plist",theConnection.url);
		}		
	}else {
		NSLog(@"HTTP %i for %@",theConnection.statusCode,theConnection.url);
	}
}

- (void)download:(NSURLDownload *)aDownload decideDestinationWithSuggestedFilename:(NSString *)filename
{
    NSString* path = [[@"~/Desktop/" stringByExpandingTildeInPath] stringByAppendingPathComponent:filename];
    [aDownload setDestination:path allowOverwrite:YES];
}

- (void)downloadDidFinish:(NSURLDownload *)aDownload
{
	NSString *filename = [[[aDownload request] URL] lastPathComponent];
    NSString *pluginArchive = [[@"~/Desktop/" stringByExpandingTildeInPath] stringByAppendingPathComponent:filename];	
	//NSLog(@"Finished downloading %@ to %@",[[[aDownload request] URL] absoluteString],pluginArchive);	
	
	if ([pluginArchive rangeOfString:@".MPplugin.zip"].location != NSNotFound ) {
		NSString *output = [self execTask:@"/usr/bin/ditto" args:[NSArray arrayWithObjects:@"-xk",@"--sequesterRsrc",pluginArchive,[@"~/Desktop/" stringByExpandingTildeInPath],nil]];
		if (output) {
			//NSLog(@"Extracted %@",pluginArchive);
			//delete plugin archive
			if ([[NSFileManager defaultManager] fileExistsAtPath:pluginArchive]){
				if (![[NSFileManager defaultManager] removeItemAtPath:pluginArchive error:nil]) {
					NSLog(@"Failed to delete plugin archive (%@).",pluginArchive);			
				}		
			}else {
				NSLog(@"Did not find archive to delete at (%@).",pluginArchive);	
			}	
			[NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(restartApp) userInfo:nil repeats:NO];				
		}		
	}else {
		NSLog(@"Bad path to plugin archive (%@)",pluginArchive);
	}	
}

- (void)download:(NSURLDownload *)aDownload didFailWithError:(NSError *)error
{
	NSLog(@"Download failed (%@)",[error localizedDescription]);	
}

#pragma mark utils

-(BOOL)appWasLaunched:(NSString*)bid{
	for (id dict in [[NSWorkspace sharedWorkspace] launchedApplications]){
		if ([bid isEqualToString:[dict objectForKey:@"NSApplicationBundleIdentifier"]]) {
			//NSLog(@"%@",path);
			return YES;
		}
	}	
	return NO;
}

-(NSArray*)getPluginSearchPaths:(NSString*)appName{
	
	NSMutableArray *bundleSearchPaths = [NSMutableArray array];
	
	//add the path in the app itself
	NSString *plugInsPath = [NSString stringWithFormat:@"%@",[[NSBundle mainBundle] builtInPlugInsPath]];	
	[bundleSearchPaths addObject:plugInsPath];	
	
	// Find Library directories in all domains except /System
	NSString *appSupportSubpath = [NSString stringWithFormat:@"Application Support/%@/PlugIns",appName];	
	NSArray *librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES);
	
	// Copy each discovered path into an array after adding the appSupportSubpath subpath
	NSEnumerator *searchPathEnum = [librarySearchPaths objectEnumerator];	
	NSString *currPath;	
	while((currPath = [searchPathEnum nextObject])){
		[bundleSearchPaths addObject:[currPath stringByAppendingPathComponent:appSupportSubpath]];
	}	
	
	return bundleSearchPaths;
}

-(NSArray*)mdfindQuery:(NSString*)string{
	NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
	CFIndex i;
	MDQueryRef query = MDQueryCreate(kCFAllocatorDefault,(CFStringRef)string,NULL,NULL);
	Boolean started = MDQueryExecute(query, kMDQuerySynchronous);
	
	if (started == TRUE) {
		CFIndex count = MDQueryGetResultCount(query);
		for (i = 0; i < count; i++) {
			MDItemRef item = (MDItemRef)MDQueryGetResultAtIndex(query, i);
			CFStringRef path = MDItemCopyAttribute(item, kMDItemPath);			
            if (path) {
                //NSLog(@"Found %@",path);                
                [ret addObject:(NSString*)path];
            }else{
                CFStringRef name = MDItemCopyAttribute(item, kMDItemFSName);			                
                NSLog(@"Null path querying %@ : %@",string,name); //was moved ?
                if(name != NULL) CFRelease(name); 
            }
            if(path != NULL) CFRelease(path);
		}		
	}else {
		NSLog(@"Spotlight query %@ failed to start",string);
	}
    
	CFRelease(query);
    if ([ret count] > 0) {
        return ret;        
    }else{
		NSLog(@"Spotlight query %@ did not find anything",string);        
        return nil;
    }
}

-(NSString*)execTask:(NSString*)launch args:(NSArray*)args{
	NSTask *task = [[[NSTask alloc] init] autorelease];
	[task setLaunchPath:launch];
	[task setArguments:args];
	
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardOutput:pipe];
	
	NSFileHandle *file = [pipe fileHandleForReading];
	
    //set a timer to terminate the task if not done in a timely manner
    NSTimer *timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:task selector:@selector(terminate) userInfo:nil repeats:NO];    
    
	[task launch];	
	[task waitUntilExit];
    [timeoutTimer invalidate];    
	
	if (![task isRunning]) {	
		if ([task terminationStatus] == 0){
			//NSLog(@"Task %@ succeeded.",launch);
			NSData *data = [file readDataToEndOfFile];	
			NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			return [string autorelease];		
		}else{
			NSLog(@"Task %@ failed.",launch);	
		}		
	}else {
        NSLog(@"Task %@ failed to complete.",launch);
	}
	
	return nil;		
}

- (NSString *)versionFromBundle:(NSString*)path {
	NSBundle *bundle = [NSBundle bundleWithPath:path];
	if (bundle) {
		NSString *version = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];		
		if (version) {
			return version;
		}else {
			NSLog(@"Bundle at %@ has no CFBundleShortVersionString",path);			
		}
	}else {
		NSLog(@"Bundle at %@ can not be loaded",path);
	}
	return nil;
}

- (NSDictionary *)dictFromBundle:(NSString*)path {
	NSBundle *bundle = [NSBundle bundleWithPath:path];
	if (bundle) {
		NSDictionary *ret = [bundle infoDictionary];	
        if ([ret count] == 2) {
            //TODO report with sample and refferencing http://www.cocoabuilder.com/archive/cocoa/198133-trouble-loading-bundles-at-runtime.html
            NSLog(@"NSBundle \"let's only return 2 objects for the heck of it\" bug.");
            return nil;
        }			
        return ret;
	}else {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) { 
            NSLog(@"Bundle at %@ exists but can not be loaded",path);
        }else{
            NSLog(@"Bundle at %@ can not be loaded as it does not exist",path);            
        } 
	}
	return nil;
}


-(void)checkCapitalization:(NSArray*)paths{	
	for (NSString *path in paths){
		NSString *displayName = [[NSFileManager defaultManager] displayNameAtPath:path];
		if (![displayName isEqualToString:@"PlugIns"]) { 
			NSString *actualPath = [NSString stringWithFormat:@"%@%@",[path substringToIndex:[path length]-7],displayName];
			NSString *message = [NSString stringWithFormat:@"The capitalization of the %@ directory is wrong, please rename it to PlugIns (note the capitalization)",actualPath];
			NSLog(@"%@",message);
			[alertButton setTitle:@"OK"];
			[alertMainText setTitleWithMnemonic:@"Directory capitalization inconsistency"];
			[alertSmallText setTitleWithMnemonic:message];			
			[alertWindow makeKeyAndOrderFront:nil];
			[NSApp arrangeInFront:alertWindow];				
		}		
	}
}

-(void)setDockIconToImage:(NSImage*)iconImage{
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
        NSLog(@"Invalid image to set to dock icon");
    } 
}

#pragma mark plugin tools

-(void)initPluginSettings:(NSString*)pluginPath{
	NSString *pluginFile = [pluginPath lastPathComponent];
	NSString *pluginName = [pluginFile substringToIndex:[pluginFile length]-9];
	if ([defaults objectForKey:pluginName] == nil){
		[defaults setObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"enabled"] forKey:pluginName];
		[defaults synchronize];
	}
}

-(void)enablePlugin:(NSString*)pluginName{
	NSMutableDictionary *dict = [[defaults objectForKey:pluginName] mutableCopy];
	if (dict == nil) dict = [[NSMutableDictionary alloc] init];
	[dict setObject:[NSNumber numberWithBool:YES] forKey:@"enabled"];
	[defaults setObject:dict forKey:pluginName];
	[defaults synchronize];
	[dict release];
}

-(void)disablePlugin:(NSString*)pluginName{
	NSMutableDictionary *dict = [[defaults objectForKey:pluginName] mutableCopy];
	if (dict == nil) dict = [[NSMutableDictionary alloc] init];
	[dict setObject:[NSNumber numberWithBool:NO] forKey:@"enabled"];
	[defaults setObject:dict forKey:pluginName];
	[defaults synchronize];
	[dict release];
}

-(BOOL)pluginChecksOK:(NSString*)path{
	NSString *pluginFile = [path lastPathComponent];	
	NSBundle *pluginBundle = [NSBundle bundleWithPath:path];
	NSDictionary *pluginDict = [pluginBundle infoDictionary];	
	//check signature for all plugins
	if ([self checkSignature:path] != 0)  {		
		NSLog(@"Signature invalid for %@",path);
		return NO;
	}
	//if plugin is from MAS check sig and receipt of container
	if ([[pluginDict objectForKey:@"MPUrlString"] rangeOfString:@"macappstore:"].location != NSNotFound) {			
		NSString *containerAppPath = [path stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"/Contents/PlugIns/%@",pluginFile] withString:@""];
		NSBundle *containerAppBundle = [NSBundle bundleWithPath:containerAppPath];				
		if (containerAppBundle && ![containerAppPath isEqualToString:path]) {
			//check bundle id correspondence
			NSString *pluginID = [pluginBundle bundleIdentifier];			
			NSString *containerID = [containerAppBundle bundleIdentifier];
			NSString *lastPart = [[containerID componentsSeparatedByString:@"."] lastObject]; 
			NSString *firstPart = [containerID stringByReplacingOccurrencesOfString:lastPart withString:@""];
			NSString *compareTo = [NSString stringWithFormat:@"%@MagicPrefs.%@",firstPart,lastPart];
			if ([pluginID caseInsensitiveCompare:compareTo] != NSOrderedSame) {
				NSLog(@"Invalid container %@",containerID);
				return NO;
			}			
			//check signature
			if ([self checkSignature:containerAppPath] != 0)  {		
				NSLog(@"Signature invalid for %@",containerAppPath);
				return NO;
			}
			//check receipt
			if ([VAValidation a:containerAppBundle] != 0)  {		
				NSLog(@"Receipt invalid for %@",containerAppPath);
				return NO;
			}				
		}else {
			NSLog(@"Error getting container %@",containerAppPath);
			return NO;				
		}			
	}
	return YES;
}

-(BOOL)savePluginInfo:(NSString*)pluginName path:(NSString*)path{
    NSDictionary *pluginDict = [self dictFromBundle:path];
    if (pluginDict != nil) {
        NSString *author = [pluginDict objectForKey:@"NSHumanReadableCopyright"];	
        NSString *url = [pluginDict objectForKey:@"MPUrlString"];	
        NSString *description = [pluginDict objectForKey:@"MPDescriptionString"];	
        NSString *version = [pluginDict objectForKey:@"CFBundleShortVersionString"];
        NSString *bid = [pluginDict objectForKey:@"CFBundleIdentifier"];	
        if (!author || !url || !version || !description || !bid) {
            NSLog(@"The author, url, id, description or version information is missing in %@",path);
        }else{
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[defaults objectForKey:pluginName]];        
            [dict setObject:author forKey:@"author"];
            [dict setObject:url forKey:@"url"];	
            [dict setObject:description forKey:@"description"];	
            [dict setObject:version forKey:@"version"];	
            [dict setObject:path forKey:@"path"];
            [dict setObject:bid forKey:@"bid"];        
            [defaults setObject:dict forKey:pluginName];
            [defaults synchronize];       
            return YES;
        }        
    }
    return NO;
}

#pragma mark handle plugin file

- (void)handlePlugin:(NSString*)moveFrom{
	
	NSString *name = [moveFrom lastPathComponent];
	NSString *newVersion = [self versionFromBundle:moveFrom];	
	NSString *existingPath = nil;
	NSString *existingFullPath = nil;	
	
	for (NSString *folderPath in [self getPluginSearchPaths:@"MagicPrefs"]){
		NSString *fullPath = [NSString stringWithFormat:@"%@/%@",folderPath,name];		
		if ([pluginLocations containsObject:fullPath]) {
			existingPath = folderPath;
			existingFullPath = fullPath;			
		}		
	}
	if (existingPath && existingFullPath) {		
		NSString *existingVersion = [self versionFromBundle:existingFullPath];
		if (existingVersion && newVersion) {
			if ([newVersion floatValue] > [existingVersion floatValue] ) {
				[self upgradePlugin:moveFrom into:existingFullPath oldVersion:existingVersion newVersion:newVersion];					
			}else {
				NSString *message = [NSString stringWithFormat:@"The same version (%@) of the %@ plugin is already instaled in %@",newVersion,name,existingPath];
				NSLog(@"%@",message);
				[alertButton setTitle:@"OK"];
				[alertMainText setTitleWithMnemonic:@"Already installed"];
				[alertSmallText setTitleWithMnemonic:message];			
				[alertWindow makeKeyAndOrderFront:nil];
				[NSApp arrangeInFront:alertWindow];							
			}				
		}
	}else {
		[self putInDefaultLoc:moveFrom];
	}
}

-(void)upgradePlugin:(NSString*)from into:(NSString*)into oldVersion:(NSString*)oldVersion newVersion:(NSString*)newVersion{
    NSLog(@"Upgrading v%@ %@ with v%@ %@",oldVersion,into,newVersion,from);
	NSString *name = [from lastPathComponent];	
	//delete the old one
	if ([[NSFileManager defaultManager] removeItemAtPath:into error:nil]) {
		if ([[NSFileManager defaultManager] moveItemAtPath:from toPath:into error:nil]) {
			NSString *message = [NSString stringWithFormat:@"Upgraded %@ v%@ to v%@",name,oldVersion,newVersion]; 
			NSLog(@"%@",message);
           	[clickSound play];	
			[self growlNotif:@"Plugin Upgraded" message:message];
			[self savePluginInfo:[name substringToIndex:[name length]-9] path:into];			
			[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(restartApp) userInfo:nil repeats:NO];					
		}else {	
			NSLog(@"Failed to copy plugin (%@ to %@).",from,into);	
		}				
	}else {
		NSLog(@"Failed to delete old plugin (%@).",into);							
	}
}

- (void)putInDefaultLoc:(NSString*)moveFrom{
	//give options to put systemwide TODO ??
	
	NSString *name = [moveFrom lastPathComponent];	
	NSString *version = [self versionFromBundle:moveFrom];
	
	NSString *pluginsPath = [NSString stringWithFormat:@"%@/Library/Application Support/MagicPrefs/PlugIns",NSHomeDirectory()];		
	NSString *pluginsFullPath = [NSString stringWithFormat:@"%@/%@",pluginsPath,name];	
	
	//create destination folder if it does not exist
	if (![[NSFileManager defaultManager] fileExistsAtPath:pluginsPath]) {			
		BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:pluginsPath withIntermediateDirectories:TRUE attributes:nil error:nil];
		if (success == NO) {
			NSLog(@"Failed to create folder (%@).",pluginsPath);			
		}else {
			NSLog(@"Created folder (%@).",pluginsPath);
		}					
	}	
	
	//move the plugin to the system location
	if ([[NSFileManager defaultManager] moveItemAtPath:moveFrom toPath:pluginsFullPath error:nil]) {
		[self initPluginSettings:pluginsFullPath];
		NSString *message = [NSString stringWithFormat:@"Installed %@ v%@",[name substringToIndex:[name length]-9],version]; 
		NSLog(@"%@",message);
       	[clickSound play];        
		[self growlNotif:@"Plugin Installed" message:message];
		[self savePluginInfo:[name substringToIndex:[name length]-9] path:pluginsFullPath];	        
		[self enablePlugin:[name substringToIndex:[name length]-9]];
		[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(restartApp) userInfo:nil repeats:NO];	
	    [[NSWorkspace sharedWorkspace] openFile:[NSString stringWithFormat:@"%@/Library/PreferencePanes/MagicPrefs.prefPane",NSHomeDirectory()]];		
	}else {	
		NSLog(@"Failed to move plugin (%@ to %@).",moveFrom,pluginsFullPath);				
	}	
}

#pragma mark find plugins

-(void)checkSpotlight{
    NSString *appPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.vladalexa.MagicPrefs"];
	if (appPath == nil){
        NSString *finderPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.apple.systempreferences"];        
        NSString *details = @"Spotlight is required to be functional for the operating system to be able to register plugin files as MagicPrefs plugins.";
        if (finderPath == nil){
            NSString *title = @"Spotlight is broken, disabled or otherwise nonfunctional.";
            NSLog(@"%@",title);            
            [self growlNotif:@"Plugin Installed" message:details];            
        }else{
            NSString *title = @"Spotlight might not be functional.";            
            NSLog(@"%@",title);
            [self growlNotif:@"Plugin Installed" message:details];                                   
        }    
    }
}

-(void)findPluginsInLocations{
	NSString *folderPath;
	for (folderPath in [self getPluginSearchPaths:@"MagicPrefs"]){		
		NSEnumerator *enumerator = [[NSBundle pathsForResourcesOfType:@"MPplugin" inDirectory:folderPath] objectEnumerator];
		NSString *pluginPath;
		while ((pluginPath = [enumerator nextObject])) {			
			//delete if it is a duplicate
			BOOL duplicate = NO;
			NSString *name = [pluginPath lastPathComponent];
			for (NSString *item in pluginLocations){
				NSString *itemName = [item lastPathComponent];
				if ([itemName isEqualToString:name]) {					
					if ([[NSFileManager defaultManager] removeItemAtPath:pluginPath error:nil]) {
						NSString *message = [NSString stringWithFormat:@"Deleted duplicate plugin %@ of %@",pluginPath,item]; 
						NSLog(@"%@",message);
                        [clickSound play];                        
						[self growlNotif:@"Plugin Deleted" message:message];						
					}else {
						NSLog(@"Failed to deleted duplicate plugin %@",pluginPath);						
					}
					duplicate = YES;
				}
			}	
			if (duplicate != YES) {
				//NSLog(@"Plugin locations found plugin %@",pluginPath);
				[self initPluginSettings:pluginPath];
				[pluginLocations addObject:pluginPath];
				[self activatePlugin:pluginPath];				
			}			
		}
	}	
}

-(NSDictionary*)pluginsDb
{
    NSString *pluginsDb = [NSString stringWithFormat:@"%@/Library/Application Support/MagicPrefs/PlugIns/pluginsdb.plist",NSHomeDirectory()];
    NSDictionary *db = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:pluginsDb]) {
        db = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:@"http://magicprefs.com/plugins/pluginsdb.plist"]];
        [db writeToFile:pluginsDb atomically:YES];
    }else{
        db = [NSDictionary dictionaryWithContentsOfFile:pluginsDb];        
    }
	if (db == nil) {
		NSLog(@"Error reading db %@",pluginsDb);
	}
    return db;
}

-(void)findPluginsFromMAS
{
    NSDictionary *db = [self pluginsDb];
	for (NSString *key in db){
		NSDictionary *pluginDict = [db objectForKey:key];		
		if ([pluginDict isKindOfClass:[NSDictionary class]]){		
			if ([[pluginDict objectForKey:@"MPUrlString"] rangeOfString:@"macappstore:"].location != NSNotFound) {
				NSString *containerID;
				if ([[pluginDict objectForKey:@"NSHumanReadableCopyright"] isEqualToString:@"Vlad Alexa"]) {
					containerID = [NSString stringWithFormat:@"com.vladalexa.%@",key];
				}else {
					containerID = [[pluginDict objectForKey:@"CFBundleIdentifier"] stringByReplacingOccurrencesOfString:@".MagicPrefs" withString:@""];
				}
				NSString *appPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:containerID];	
				if (appPath) {
					NSString *pluginPath = [NSString stringWithFormat:@"%@/Contents/PlugIns/%@.MPplugin",appPath,key];
					if ([[NSFileManager defaultManager] fileExistsAtPath:pluginPath]) {
						//NSLog(@"Plugin container found plugin %@",pluginPath);
						[self initPluginSettings:pluginPath];
						[pluginLocations addObject:pluginPath];
						[self activatePlugin:pluginPath];					
					}else {
						NSLog(@"Plugin container empty %@",appPath);					
					}					
				}else {
					//NSLog(@"Plugin %@ not installed from MAS",key);
				}				
			}			
		}
	}	
}

-(void)findPluginsSystemwide{
    //mdfind "kMDItemKind == 'MagicPrefs Plug-in'"
    //NSArray *paths = [[self execTask:@"/usr/bin/mdfind" args:[NSArray arrayWithObjects:@"-name",@".MPplugin",nil]] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];    
    NSArray *paths = [self mdfindQuery:@"kMDItemDisplayName == '*.MPplugin'"];		
    for (NSString *pluginPath in paths){           
        if ([[pluginPath pathExtension] isEqualToString:@"MPplugin"]) {
            if ([pluginLocations containsObject:pluginPath]) {
                //NSLog(@"Already known %@",pluginPath);
            }else if ([pluginPath rangeOfString:@"/Desktop/"].location != NSNotFound || [pluginPath rangeOfString:@"/Downloads/"].location != NSNotFound) {
                NSLog(@"Installing %@",pluginPath);	
                [self handlePlugin:pluginPath];					
            }else {
                //NSLog(@"Found plugin not installed %@",pluginPath);					
            }				
        }
    }
}

#pragma mark plugin actions

//	This is called to activate each plug-in, meaning that each candidate bundle is checked,
//	loaded if it seems to contain a valid plug-in, and the plug-in's class' initiateClass
//	method is called. If this returns YES, it means that the plug-in agrees to run and the
//	class is added to the pluginClass array. Some plug-ins might refuse to be activated
//	depending on some external condition.

- (void)activatePlugin:(NSString*)path{
	if ([self pluginChecksOK:path] == NO) return;	
	NSString *protocolName = @"MPPluginProtocol";
	NSBundle *pluginBundle = [NSBundle bundleWithPath:path];
	if (pluginBundle) {
		NSDictionary *pluginDict = [pluginBundle infoDictionary];
		NSString *pluginFile = [path lastPathComponent];		
		NSString *pluginClassName = [pluginDict objectForKey:@"NSPrincipalClass"];
		NSString *pluginName = [pluginFile substringToIndex:[pluginFile length]-9];			
		//check main class versus name
		if (![pluginClassName isEqualToString:pluginName]) {
			NSLog(@"Main plugin class does not match plugin's name (%@ != %@)",pluginName,pluginClassName);
			return;
		}
		if (pluginClassName) {
			BOOL saved = [self savePluginInfo:pluginName path:path];
            if (saved != YES) {
                NSLog(@"The author, url, id, description or version information is missing in %@",path);			
                return;
            }
			//check if plugin is enabled
			BOOL isEnabled = [[[defaults objectForKey:pluginName] objectForKey:@"enabled"] boolValue];
			if (isEnabled) {			
				//NSLog(@"will load %@ plugin",pluginName);	
			}else {
				NSString *installedPane = [NSString stringWithFormat:@"%@/Library/PreferencePanes/%@.prefPane",NSHomeDirectory(),pluginName];				
				if ([[NSFileManager defaultManager] fileExistsAtPath:installedPane]) [self deletePrefPane:installedPane];					
				//NSLog(@"%@ plugin is not enabled, skipping",pluginName);				
				return;
			}
			//load plugin if everything checks out
			Class pluginClass = NSClassFromString(pluginClassName);
			if (!pluginClass) {
				pluginClass = [pluginBundle principalClass]; //also loads the bundle
				if ([pluginClass conformsToProtocol: NSProtocolFromString(protocolName)] && [pluginClass isKindOfClass:[NSObject class]] && [pluginClass initializeClass:pluginBundle]) {                    
                    //[NSThread detachNewThreadSelector:@selector(allocOnThread:) toTarget:self withObject:pluginClass];        //new thread
                    [self allocOnThread:pluginClass];                                                                       //main thread
                    [pluginClasses addObject:pluginClass];	
                    //NSLog(@"loaded %@ plugin",pluginName);					
                    pluginCount++;
                    //copy pref pane if plugin has one
                    NSString *bundlePane = [[pluginBundle resourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.prefPane",pluginName]];						
                    if ([[NSFileManager defaultManager] fileExistsAtPath:bundlePane]) [self copyPrefPane:bundlePane];						
                    //set dock badge        
                    NSDockTile *tile = [[NSApplication sharedApplication] dockTile];
                    [tile setBadgeLabel:[NSString stringWithFormat:@"%i",pluginCount]];                    
				}else {
					NSLog(@"%@ plugin did not conform to %@, skipped",pluginFile,protocolName);
				}
			}else {
				NSLog(@"NSPrincipalClass of plugin %@ is a class already loaded from another plugin, you have to rename yours",pluginClassName);
			}
		}else {
			NSLog(@"Plugin NSPrincipalClass is blank for %@",path);
		}
	}
}

- (void)allocOnThread:(id)arg{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    id currInstance = [[arg alloc] init]; 
    if(currInstance){        
        if ([NSThread isMainThread]){
            //NSLog(@"Alloced on main thread: %@", [NSThread currentThread]);
            [pluginInstances addObject:[currInstance autorelease]];            
        }else {
            //NSLog(@"Alloced on secondary thread: %@", [NSThread currentThread]);
            [pluginInstances performSelectorOnMainThread:@selector(addObject:) withObject:[currInstance autorelease] waitUntilDone:NO];        
        }                
    }else {       
        NSLog(@"Failed to get a instance of %@",NSStringFromClass(arg));
    }
    		
	[pool drain];
}

- (void)deactivatePlugin:(NSString*)path{
	NSBundle *pluginBundle = [NSBundle bundleWithPath:path];
	if (pluginBundle) {
		NSDictionary *pluginDict = [pluginBundle infoDictionary];
		NSString *pluginName = [pluginDict objectForKey:@"NSPrincipalClass"];
		if (pluginName){
			Class pluginClass = [pluginBundle principalClass];
			if ([pluginClasses containsObject:pluginClass]) {
				[pluginClass terminateClass];
				[pluginClasses removeObjectAtIndex:[pluginClasses indexOfObject:pluginClass]];
				NSLog(@"unloaded %@ plugin",pluginName);
				pluginCount--;
				NSDockTile *tile = [[NSApplication sharedApplication] dockTile];
				[tile setBadgeLabel:[NSString stringWithFormat:@"%i",pluginCount]];						
			}
		}		
	}	 	
}

- (void)copyPrefPane:(NSString*)path{
	NSString *name = [path lastPathComponent];
	NSString *folder = [NSString stringWithFormat:@"%@/Library/PreferencePanes",NSHomeDirectory()];		
	NSString *copyTo = [NSString stringWithFormat:@"%@/%@",folder,name];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:folder]) {			
		BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:TRUE attributes:nil error:nil];
		if (success == FALSE) {
			NSLog(@"Failed to create folder (%@).",folder);			
		}else {
			NSLog(@"Created folder (%@).",folder);
		}					
	}	
	if ([[NSFileManager defaultManager] fileExistsAtPath:copyTo]) {	
		BOOL success = [[NSFileManager defaultManager] removeItemAtPath:copyTo error:nil];	
		if (success == FALSE) {
			NSLog(@"Failed to delete old preferences pane (%@).",copyTo);		
		}		
	}	
	BOOL success = [[NSFileManager defaultManager] copyItemAtPath:path toPath:copyTo error:nil];
	if (success == FALSE) {
		NSLog(@"Failed to copy preferences pane (%@ to %@).",path,copyTo);		
	}
}

- (void)deletePrefPane:(NSString*)path{
	//quit system preferences (pane remains)	
	if ([self appWasLaunched:@"com.apple.systempreferences"]){
		system("killall 'System Preferences'");
	}	

	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {	
		BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:nil];	
		if (success == FALSE) {
			NSLog(@"Failed to delete preferences pane (%@).",path);			
		}		
	}	
}

@end
