//
//  PluginsWindowController.m
//  MagicPrefs
//
//  Created by Vlad Alexa on 9/8/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "PluginsWindowController.h"
#import "MPPluginInterface.h"
#import "VAUserDefaults.h"

@implementation PluginsWindowController

- (id)init{	    
    self = [super initWithWindowNibName:@"PluginsWindow"];
	if (self) {		
		//NSLog(@"init PluginsWindow without window");
				
		pluginsArr = [[NSMutableArray alloc] init];
		pluginInstances = [[NSMutableArray alloc] init];		
		loadedPluginsList = [[NSMutableDictionary alloc] init];
		pluginArchive = [[NSMutableString alloc] init];
		
		//alloc defaults
		mainDefaults = [[VAUserDefaults alloc] initWithPlist:@"com.vladalexa.MagicPrefs.plist"];		
		defaults = [[VAUserDefaults alloc] initWithPlist:@"com.vladalexa.MagicPrefs.MagicPrefsPlugins.plist"];	
							
		//register for notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MPpluginsWindowEvent" object:nil];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MPpluginsWindowEvent" object:nil];	

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becameKey:) name:NSWindowDidBecomeKeyNotification object:[self window]];	        
        
		[self makePluginsArr];	
		
		[listTable setRowHeight:28];
        
        if ([mainDefaults objectForKey:@"knownPlugins"] == nil){
            [mainDefaults setObject:[NSArray arrayWithObjects:@"iSightSnap",@"MagicLauncher",@"MagicMenu",nil] forKey:@"knownPlugins"];	
            [mainDefaults synchronize];
        }        
				
	}	
	
	return self;
}

- (void)dealloc{   	    
    [download cancel];
    [download release];	
	[pluginsArr release];
	[pluginInstances release];
	[loadedPluginsList release];
    [pluginArchive release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];    
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];	    
	[super dealloc];    
}

- (void) windowDidLoad {
	//NSLog(@"PluginsWindow window loaded");	
}

-(void)theEvent:(NSNotification*)notif{	
	if (![[notif name] isEqualToString:@"MPpluginsWindowEvent"]) {
		return;
	}		
	if ([[notif object] isKindOfClass:[NSString class]]){					
		if ([[notif object] isEqualToString:@"Sync"]){
			[self syncMe];			
		}		
	}
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]]){
		if ([[[notif userInfo] objectForKey:@"what"] isEqualToString:@"getLoadedPluginsEventsCallback"]){
			[loadedPluginsList setDictionary:[[notif userInfo] objectForKey:@"list"]];
			[self syncMe];
		}		
	}	
}

-(void)becameKey:(NSNotification*)notif{	
    
    //NSLog(@"PluginsWindow window shown");
    
    //launch plugins host if not running
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"LaunchPluginsHost" userInfo:nil];         
    
    //refresh
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPpluginsEvent" object:nil userInfo:
	 [NSDictionary dictionaryWithObjectsAndKeys:@"getLoadedPluginsEvents",@"what",@"MPpluginsWindowEvent",@"callback",nil]
	 ];	
	[self syncMe]; 	
    
	//check if plugins host is running
	if ([PluginsWindowController isAppRunning:@"MagicPrefsPlugins"] == NO) {
		[notLoaded setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"stop"))]];		
		[notLoaded setHidden:NO];
		[notLoaded setToolTip:@"The MagicPrefs plugins host application is not running."];	
		[loadedPluginsList removeAllObjects];
	}else {
		[notLoaded setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"caut"))]];			
		[notLoaded setHidden:YES];
		[notLoaded setToolTip:@"This plugin is enabled but could not be loaded."];		
	}    
    	
}

-(void)syncMe
{
	[self makePluginsArr];
    NSDictionary *db = [self pluginsDb];
    if (db) {
        [self appendNotInstalled:db];
        [self notifyNewPlugin:db];
    }	
	[listTable reloadData];
	[self showDetailsFor:[listTable selectedRow]];
	if ([pluginsArr count] == 0) {
		[noPreferences setStringValue:@"No plugins"];		
		[grayBox setFrame:NSMakeRect(237, 306, 314, 0)];
		[whiteBox setFrame:NSMakeRect(224, 50, 340, 363)];	
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

#pragma mark server

-(void)notifyNewPlugin:(NSDictionary*)db{
    int count = 0;
    NSArray *knownPlugins = [mainDefaults objectForKey:@"knownPlugins"];    
	for (NSString *key in db){
		if ([[db objectForKey:key] isKindOfClass:[NSDictionary class]]){
            if (![knownPlugins containsObject:key]) {
                count ++;
                NSDictionary *dict = [db objectForKey:key];
                NSString *desc = [dict objectForKey:@"MPDescriptionString"];
                NSString *title = [NSString stringWithFormat:@"New plugin available: %@",key];
                [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPpluginsEvent" object:nil userInfo:
                 [NSDictionary dictionaryWithObjectsAndKeys:@"doGrowl",@"what",title,@"title",desc,@"message",nil]
                 ];	                
            }
		}
	}	
    if (count > 0){
        NSString *countString = [NSString stringWithFormat:@"%i",count];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneMainEvent" object:@"updateNewPluginsCount" userInfo:[NSDictionary dictionaryWithObject:countString forKey:@"count"]];        
    }
}

-(void)appendNotInstalled:(NSDictionary*)db{	
	for (NSString *key in db){
		if ([[db objectForKey:key] isKindOfClass:[NSDictionary class]]){	
			NSDictionary *dict = [db objectForKey:key];	
			NSDictionary *newDict = [NSDictionary dictionaryWithObjectsAndKeys:
									 [dict objectForKey:@"NSHumanReadableCopyright"],@"author",
									 [dict objectForKey:@"MPUrlString"],@"url",
									 [dict objectForKey:@"MPDescriptionString"],@"description",										 
									 @"",@"version",
									 @"",@"path",
									 key,@"name",
									 [NSNumber numberWithBool:NO],@"enabled",
									 nil];	
			BOOL installed = NO;
			for (NSDictionary *entry in pluginsArr){
				if ([[entry objectForKey:@"name"] isEqualToString:key]) {
					installed = YES;
				}
			}
			if (installed == NO) {
				[pluginsArr addObject:newDict];
			}
		}
	}	
}

#pragma mark Download

- (void)download:(NSURLDownload *)aDownload decideDestinationWithSuggestedFilename:(NSString *)filename
{
    NSString* path = [[@"~/Desktop/" stringByExpandingTildeInPath] stringByAppendingPathComponent:filename];
    [aDownload setDestination:path allowOverwrite:YES];
}

- (void)download:(NSURLDownload *)aDownload didCreateDestination:(NSString *)path
{
    [pluginArchive setString:path];
}

- (void)downloadDidFinish:(NSURLDownload *)aDownload
{
	if ([pluginArchive rangeOfString:@".MPplugin.zip"].location != NSNotFound ) {
		NSString *output = [PluginsWindowController execTask:@"/usr/bin/ditto" args:[NSArray arrayWithObjects:@"-xk",@"--sequesterRsrc",pluginArchive,[@"~/Desktop/" stringByExpandingTildeInPath],nil]];
		if (output) {
			//delete plugin archive
			if ([[NSFileManager defaultManager] fileExistsAtPath:pluginArchive]){
				if (![[NSFileManager defaultManager] removeItemAtPath:pluginArchive error:nil]) {
					NSLog(@"Failed to delete plugin archive (%@).",pluginArchive);			
				}		
			}else {
				NSLog(@"Did not find archive to delete at (%@).",pluginArchive);	
			}
            NSString *filename = [[pluginArchive lastPathComponent] substringToIndex:[[pluginArchive lastPathComponent] length]-4];
            NSString *downloadedPath = [NSString stringWithFormat:@"%@/%@",[@"~/Desktop/" stringByExpandingTildeInPath],filename];            
            BOOL success = [[NSWorkspace sharedWorkspace] openFile:downloadedPath withApplication:@"MagicPrefsPlugins"];
            if (success != YES) NSLog(@"ERROR opening downloaded plugin %@ with MagicPrefsPlugins",downloadedPath);            
            [installSpinner stopAnimation:nil];            
		}		
	}else {
		NSLog(@"Bad path to plugin archive (%@)",pluginArchive);
	}
}

- (void)download:(NSURLDownload *)aDownload didFailWithError:(NSError *)error
{
	[installSpinner stopAnimation:nil];	
    [self presentError:error modalForWindow:[self window] delegate:nil didPresentSelector:NULL contextInfo:NULL];
}

#pragma mark tools

+ (BOOL)launchAppByID:(NSString*)bid{
    if ([[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:bid] != nil){	
        NSLog(@"%@ not running, attempting to start.",bid);		
        [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:bid options:NSWorkspaceLaunchWithoutActivation additionalEventParamDescriptor:nil launchIdentifier:NULL];
        return YES;
    }else{
        NSLog(@"Failed to find %@",bid);
    }
    return NO;    
}


-(NSImage*)iconImgAtPath:(NSString*)path{
	NSImage *img = nil;	
	if ([path length] == 0) {		
		img = [NSImage imageNamed:@"NSNetwork"];			
	}else {
		NSString *ipath = [NSString stringWithFormat:@"%@/Contents/Resources/icon.png",path];
		img = [[[NSImage alloc] initWithContentsOfFile:ipath] autorelease];		
		if (img == nil) {
			img = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[PluginsWindowController class]] pathForImageResource:@"icon"]] autorelease];				
			NSLog(@"Unable to find %@",ipath);
		}		
	}
	return img;
}

+(NSString*)execTask:(NSString*)launch args:(NSArray*)args{
	NSTask *task = [[[NSTask alloc] init] autorelease];
	[task setLaunchPath:launch];
	[task setArguments:args];
	
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardOutput:pipe];
	
	NSFileHandle *file = [pipe fileHandleForReading];
	
	[task launch];	
	[task waitUntilExit];
	
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

-(void)makePluginsArr{
	NSDictionary *defaultsCopy = [[defaults dictionaryRepresentation] copy];
	NSMutableArray *newArray = [[NSMutableArray alloc] init];
	
	for (NSString *key in defaultsCopy){
		if ([[defaults objectForKey:key] isKindOfClass:[NSDictionary class]]){	
			NSMutableDictionary *dict = [[defaults objectForKey:key] mutableCopy];			
			NSString *author = [dict objectForKey:@"author"];	
			NSString *url = [dict objectForKey:@"url"];	
			NSString *version = [dict objectForKey:@"version"];
			NSString *description = [dict objectForKey:@"description"];			
			NSString *path = [dict objectForKey:@"path"];
			id enabled = [dict objectForKey:@"enabled"];			
			if (author && url && version && description && path && enabled != nil) {
				if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
					[dict setObject:key forKey:@"name"];
					[newArray addObject:dict];						
				}			
			}	
			[dict release];			
		}
	}
	[defaultsCopy release];
	
	NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
	NSArray *sortedArr = [newArray sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
	[descriptor release];
	[newArray release];
	[pluginsArr setArray:sortedArr];
}

-(void)showDetailsFor:(NSInteger)row{
	if (row < 0 || row > [pluginsArr count]) {
		return;
	}
	//NSLog(@"Showing details for %i",row);			
	NSDictionary *dict = [pluginsArr objectAtIndex:row];
    
    //mark plugin as known
    NSMutableArray *knownPlugins = [[mainDefaults objectForKey:@"knownPlugins"] mutableCopy];
    if (![knownPlugins containsObject:[dict objectForKey:@"name"]]) {
        [knownPlugins addObject:[dict objectForKey:@"name"]];
        [mainDefaults setObject:knownPlugins forKey:@"knownPlugins"];	
        [mainDefaults synchronize];        
        //remove new plugins count from button
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneMainEvent" object:@"updateNewPluginsCount" userInfo:[NSDictionary dictionaryWithObject:@"0" forKey:@"count"]];        
    }
    [knownPlugins release];    
    
    //set UI
	[pluginAuthor setTitle:[dict objectForKey:@"author"]];
	[pluginAuthor setToolTip:[dict objectForKey:@"url"]];
	if ([[dict objectForKey:@"version"] length] > 0) {
		[pluginTitle setStringValue:[NSString stringWithFormat:@"%@ v%@",[dict objectForKey:@"name"],[dict objectForKey:@"version"]]];		
	}else {
		[pluginTitle setStringValue:[dict objectForKey:@"name"]];
	}
	[pluginDesc setStringValue:[dict objectForKey:@"description"]];
	if ([[dict objectForKey:@"author"] isEqualToString:@"Vlad Alexa"]) {
		[uninstallButton setHidden:YES];			
	}else {
		[uninstallButton setHidden:NO];					
	}
	if ([[dict objectForKey:@"url"] rangeOfString:@"macappstore:"].location == NSNotFound) {
		[installButton setTitle:@"Install for free"];
	}else {
		[installButton setTitle:@"Buy from App Store"];					
	}	
	if ([[dict objectForKey:@"path"] length] == 0) {
		[uninstallButton setHidden:YES];
		[installButton setHidden:NO];			
	}else {
		[installButton setHidden:YES];		
	}	
	
	NSImage *img = [self iconImgAtPath:[dict objectForKey:@"path"]];
	if (img) [pluginLogo setImage:img];	
	
	[uninstallButton setTag:row];
	[installButton setTag:row];	
	
	for (NSView *view in [preferencesView subviews]){
		[view removeFromSuperview];
	} 	
	
	if ([[dict objectForKey:@"enabled"] boolValue] == YES) {	
		if ([loadedPluginsList count] > 0) {
			//if enabled but not loaded show notice img				
			BOOL loaded = NO;
			for (NSString *pluginName in loadedPluginsList) {
				if ([[dict objectForKey:@"name"] isEqualToString:pluginName]) {
					loaded = YES;
				}
			}		
			if (loaded == YES) {
				[notLoaded setHidden:YES];				
			}else {
				[notLoaded setHidden:NO];										
			}				
		}				
		//
		//set preferences view		
		//
		//load bundle and get preferences
		id instance = nil;
		for(id inst in pluginInstances){
			if ([[inst className] isEqualToString:[dict objectForKey:@"name"]]) {
				instance = inst;//allready loaded in pluginInstances
			}
		}
		if (instance == nil) instance = [self loadPrefs:[dict objectForKey:@"path"]];//load it to pluginInstances
		if (instance != nil){
			if ([instance respondsToSelector:@selector(preferences)]) {
				NSViewController *controller = [instance performSelector:@selector(preferences)];
				[preferencesView addSubview:controller.view];					
				[noPreferences setHidden:YES];					
			}else {
				//NSLog(@"%@ has no preferences",[dict objectForKey:@"name"]);
				[noPreferences setStringValue:@"No settings"];				
				[noPreferences setHidden:NO];
			}			
		}
		//show a button link to the pref pane
		NSString *bundlePane = [NSString stringWithFormat:@"%@/Contents/Resources/%@.prefPane",[dict objectForKey:@"path"],[dict objectForKey:@"name"]];
		NSString *installedPane = [NSString stringWithFormat:@"%@/Library/PreferencePanes/%@.prefPane",NSHomeDirectory(),[dict objectForKey:@"name"]];		
		if ([[NSFileManager defaultManager] fileExistsAtPath:bundlePane] && [[NSFileManager defaultManager] fileExistsAtPath:installedPane]){			
			[preferencesView addSubview:prefPaneView];
			[prefPaneView setFrame:NSMakeRect(84,42,168,168)];
			[noPreferences setHidden:YES];			
			NSBundle *pluginBundle = [NSBundle bundleWithPath:bundlePane];
			NSImage *img = [[[NSImage alloc] initWithContentsOfFile:[pluginBundle pathForImageResource:@"icon"]] autorelease];						
			if (img) {
				[prefPaneButton setImage:img];
				[prefPaneButton setToolTip:[dict objectForKey:@"name"]];				
			}else {
				NSLog(@"Pref pane for %@ is missing the icon",[dict objectForKey:@"name"]);	
			}			
		}		
		
	}else {
		[noPreferences setStringValue:@"Not enabled"];				
		[noPreferences setHidden:NO];		
		[notLoaded setHidden:YES];
	}	
	
}

-(IBAction)openPrefpane:(id)sender{
	[self closeMe:sender];
	[[NSWorkspace sharedWorkspace] openFile:[NSString stringWithFormat:@"%@/Library/PreferencePanes/%@.prefPane",NSHomeDirectory(),[sender toolTip]]];	
}

- (id)loadPrefs:(NSString*)path{
	//do not load if we are MagicPrefsPlugins as the instances allready exist
	NSString *bundleId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];			
	if ([bundleId isEqualToString:@"com.vladalexa.MagicPrefs.MagicPrefsPlugins"]) {
		return nil;
	}		
	NSBundle *pluginBundle = [NSBundle bundleWithPath:path];
	if (pluginBundle) {
		NSString *pluginFile = [path lastPathComponent];
		NSString *pluginName = [pluginFile substringToIndex:[pluginFile length]-9];	
		Class pluginClass = NSClassFromString(pluginName);
			if (!pluginClass) {
				pluginClass = [pluginBundle principalClass]; //also loads the bundle
				if ([pluginClass initializeClass:pluginBundle]) {
					id currInstance = [[pluginClass alloc] init];
					if(currInstance){
						[pluginInstances addObject:[currInstance autorelease]];	
						//NSLog(@"loaded prefs for %@",pluginName);				
						return currInstance;						
					}else {
						NSLog(@"Failed to get a instance of %@",pluginName);
					}
				}else {
					NSLog(@"Failed to initalize prefs from %@",path);
				}
			}else {
				NSLog(@"NSPrincipalClass of plugin %@ is a class already loaded from another plugin, you have to rename yours",pluginName);
			}
	}else {
		NSLog(@"Plugin not found at %@",path);
	}
	return nil;
}

#pragma mark actions

-(IBAction)closeMe:(id)sender{
	[NSApp endSheet:[sender window]];
	//[[sender window] close];
	[[sender window] orderOut:self];	
}

- (IBAction) openUrl:(id)sender{
	NSURL *url = [NSURL URLWithString:[sender toolTip]];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

-(IBAction)enable:(id)sender{		
	NSInteger index = [listTable selectedRow];	
	NSMutableDictionary *dict = [[pluginsArr objectAtIndex:index] mutableCopy];
	BOOL previous = [[dict objectForKey:@"enabled"] boolValue];	
	NSString *pluginName = [dict objectForKey:@"name"];
	NSNumber *current;
	NSString *action;
	if (previous == YES) {
		current = [NSNumber numberWithBool:NO];
		action = @"disabled";
	}else {
		current = [NSNumber numberWithBool:YES];
		action = @"enabled";		
	}
	
	//save it in local data	
	[dict setObject:current forKey:@"enabled"];
	[pluginsArr replaceObjectAtIndex:index withObject:dict];
	[dict release];
	
	//save the settings ourselves and just tell the plugins app to restart instead of sending (enablePlugin) or (disablePlugin)
	NSMutableDictionary *d = [[defaults objectForKey:pluginName] mutableCopy];
	[d setObject:current forKey:@"enabled"];
	[defaults setObject:d forKey:pluginName];
	[defaults synchronize];
	[d release];

    //launch if not running (and any plugins enabled) or restart (quit if no plugins enabled) if allready running 
    if ([PluginsWindowController isAppRunning:@"MagicPrefsPlugins"] == NO) {	
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"LaunchPluginsHost" userInfo:nil];
    }else{
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPpluginsEvent" object:@"doRestart" userInfo:nil];            
    }      
    
    //notify
	NSString *growlTitle = [NSString stringWithFormat:@"Plugin %@",action];
	NSString *growlMessage = [NSString stringWithFormat:@"The %@ plugin was %@",pluginName,action];	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPpluginsEvent" object:nil userInfo:
	 [NSDictionary dictionaryWithObjectsAndKeys:@"doGrowl",@"what",growlTitle,@"title",growlMessage,@"message",nil]
	 ];	
	
	[listTable reloadData];
	
	//NSLog(@"%@  %@",pluginName,action);	
}

-(IBAction)install:(id)sender{ 
	NSDictionary *dict = [pluginsArr objectAtIndex:[sender tag]];
	if ([[dict objectForKey:@"url"] rangeOfString:@"macappstore:"].location == NSNotFound) {
        [installButton setHidden:YES];
        [installSpinner startAnimation:sender];        
        NSString *urlString = [NSString stringWithFormat:@"%@%@.MPplugin.zip",[dict objectForKey:@"url"],[dict objectForKey:@"name"]];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];      
        download = [[NSURLDownload alloc] initWithRequest:request delegate:self];		
        NSLog(@"Started downloading %@",urlString);        
    } else{
       	[[NSWorkspace sharedWorkspace] launchApplication:@"App Store"];	
        sleep(5);//hack to let it finish launching, not great
        NSURL *url = [NSURL fileURLWithPath:[dict objectForKey:@"url"]];
        [[NSWorkspace sharedWorkspace] openURL:url];        
    }      	
}

-(IBAction)uninstall:(id)sender{
		
	NSDictionary *dict = [pluginsArr objectAtIndex:[sender tag]];	
	NSString *name = [dict objectForKey:@"name"];
	NSString *path = [dict objectForKey:@"path"];	
	
	//delete plugin settings
	//TODO
	
	//delete plugin bundle
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]){
		if (![[NSFileManager defaultManager] removeItemAtPath:path error:nil]) {
			NSLog(@"Failed to delete plugin (%@).",path);			
		}		
	}else {
			NSLog(@"Did not find plugin to delete at (%@).",path);	
	}	
		
	//delete pref pane
	NSString *bundlePane = [NSString stringWithFormat:@"%@/Contents/Resources/%@.prefPane",path,name];
	NSString *installedPane = [NSString stringWithFormat:@"%@/Library/PreferencePanes/%@.prefPane",NSHomeDirectory(),name];		
	if ([[NSFileManager defaultManager] fileExistsAtPath:bundlePane] && [[NSFileManager defaultManager] fileExistsAtPath:installedPane]){
		if (![[NSFileManager defaultManager] removeItemAtPath:installedPane error:nil]) {
			NSLog(@"Failed to delete preferences pane (%@).",installedPane);			
		}		
	}	
	
	//notify and restart
	NSString *growlTitle = @"Plugin installed";
	NSString *growlMessage = [NSString stringWithFormat:@"The %@ plugin was installed",name];	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPpluginsEvent" object:nil userInfo:
	 [NSDictionary dictionaryWithObjectsAndKeys:@"doGrowl",@"what",growlTitle,@"title",growlMessage,@"message",nil]
	 ];	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPpluginsEvent" object:@"doRestart" userInfo:nil];
	
	//update ui
	for (NSView *view in [preferencesView subviews]){
		[view removeFromSuperview];
	} 	
	[pluginsArr removeObjectAtIndex:[sender tag]];
	[listTable reloadData];	
	[self showDetailsFor:0];	
}

-(IBAction)updates:(id)sender{	
	for (NSView *view in [preferencesView subviews]){
		[view removeFromSuperview];
	} 	
	[listTable setAllowsEmptySelection:TRUE];	
	[listTable deselectAll:sender];	
	[grayBox setHidden:YES];
	[whiteBox setHidden:YES];
	[updatesBox	setHidden:NO];
}


#pragma mark tableview

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
	//NSLog(@"Selected row %i",[listTable selectedRow]);
		
	if ([listTable selectedRow] > -1){
		[updatesBox	setHidden:YES];		
		[grayBox setHidden:NO];
		[whiteBox setHidden:NO];			
		[self showDetailsFor:[listTable selectedRow]];
		[updatesButton setState:0];			
		NSDictionary *dict = [pluginsArr objectAtIndex:[listTable selectedRow]];
		if ([[dict objectForKey:@"path"] length] == 0) {
			//install mode			
			[[grayBox animator] setFrame:NSMakeRect(237, 50, 314, 325)];
			[[whiteBox animator] setFrame:NSMakeRect(224, 326, 340, 87)];
		}else {
			//normal mode
			[[grayBox animator] setFrame:NSMakeRect(237, 306, 314, 107)];
			[[whiteBox animator] setFrame:NSMakeRect(224, 50, 340, 294)];							
		}		
	}	
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView {	
	return [pluginsArr count];	
}

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)theColumn row:(NSInteger)rowIndex{
	NSString *ident = [theColumn identifier];
	NSDictionary *dict = [pluginsArr objectAtIndex:rowIndex];	
	if ([ident isEqualToString:@"checkbox"] && [[dict objectForKey:@"path"] length] == 0){
		//NSLog(@"Returning empty cell for %@",[dict objectForKey:@"name"]);
		return [[[NSCell alloc] init] autorelease];
	}
	return [theColumn dataCellForRow:rowIndex];
}

- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)theColumn row:(NSInteger)rowIndex {
	NSString *ident = [theColumn identifier];
	NSDictionary *dict = [pluginsArr objectAtIndex:rowIndex];
	if ([ident isEqualToString:@"checkbox"]){
		if ([[dict objectForKey:@"enabled"] boolValue] == YES) {
			return [NSNumber numberWithBool:YES];
		}else {
			return [NSNumber numberWithBool:NO];			
		}
	}
	if ([ident isEqualToString:@"icon"]) {
		NSImage *img = [self iconImgAtPath:[dict objectForKey:@"path"]];	
		return img;
	}
	if ([ident isEqualToString:@"name"]) {
		return [dict objectForKey:@"name"];
	}	
	return nil;
}

@end

@implementation NSColor (StringOverrides)

+(NSArray *)controlAlternatingRowBackgroundColors{
	return [NSArray arrayWithObjects:[NSColor colorWithCalibratedWhite:0.95 alpha:1.0],[NSColor whiteColor],nil];
}

@end
