//
//  MagicPrefsPluginsAppDelegate.h
//  MagicPrefsPlugins
//
//  Created by Vlad Alexa on 8/30/10.
//  Copyright 2010 NextDesign. All rights reserved.
//


#import <Cocoa/Cocoa.h>

#import "VAUrlConnection.h"

#include <Growl/Growl.h>

@class VAUserDefaults;
@class PluginsWindowController;

@interface MagicPrefsPluginsAppDelegate : NSObject <NSApplicationDelegate,VAUrlConnectionDelegate,NSURLDownloadDelegate,GrowlApplicationBridgeDelegate> {
	
	PluginsWindowController *pluginsWindowController;	
	
	IBOutlet NSWindow *alertWindow;	
	IBOutlet NSButton *alertButton;	
	IBOutlet NSTextField *alertMainText;
	IBOutlet NSTextField *alertSmallText;	
	
    NSWindow *window;
	
	NSUserDefaults *defaults;	
	VAUserDefaults *mainDefaults;
	
	NSSound *clickSound;
	NSSound *clickOffSound;	
	
	NSMutableArray *pluginClasses;			//	an array of all plug-in classes
	NSMutableArray *pluginInstances;		//	an array of all plug-in instances	
	NSMutableArray *pluginLocations;		//  an array of all plug-in paths
	
	int pluginCount;
    
    NSImage *dockIconImage;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) NSMutableArray *pluginInstances;

-(int)checkSignature:(NSString*)path;
-(void)updateCheckPlugins;
-(void)checkPluginsList;
-(void)magicPrefsCheck;

-(NSDictionary*)getLoadedPluginsEvents;
-(NSDictionary*)getLoadedPluginsPaths;
-(NSArray*)pluginClassesStrings;
-(void) growlNotif:(NSString*)title message:(NSString*)message;
-(void) restartApp;
-(IBAction) alertAction:(id)sender;

-(BOOL)appWasLaunched:(NSString*)bid;
-(NSArray*)getPluginSearchPaths:(NSString*)appSupportSubpath;
-(NSArray*)mdfindQuery:(NSString*)query;
-(NSString*)execTask:(NSString*)launch args:(NSArray*)args;
-(NSString *)versionFromBundle:(NSString*)path;
-(NSDictionary *)dictFromBundle:(NSString*)path;
-(void)checkCapitalization:(NSArray*)paths;
-(void)setDockIconToImage:(NSImage*)iconImage;

-(void)initPluginSettings:(NSString*)pluginPath;
-(void)enablePlugin:(NSString*)pluginName;
-(void)disablePlugin:(NSString*)pluginName;
-(BOOL)pluginChecksOK:(NSString*)path;
-(BOOL)savePluginInfo:(NSString*)pluginName path:(NSString*)path;

-(void)upgradePlugin:(NSString*)from into:(NSString*)into oldVersion:(NSString*)oldVersion newVersion:(NSString*)newVersion;
-(void)handlePlugin:(NSString*)copyFrom;
-(void)putInDefaultLoc:(NSString*)moveFrom;

-(void)checkSpotlight;
-(void)findPluginsSystemwide;
-(NSDictionary*)pluginsDb;
-(void)findPluginsFromMAS;
-(void)findPluginsInLocations;

-(void)activatePlugin:(NSString*)path;
-(void)deactivatePlugin:(NSString*)path;
-(void)allocOnThread:(id)arg;
-(void)copyPrefPane:(NSString*)path;
-(void)deletePrefPane:(NSString*)name;

@end
