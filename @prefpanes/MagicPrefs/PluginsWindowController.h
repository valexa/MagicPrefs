//
//  PluginsWindowController.h
//  MagicPrefs
//
//  Created by Vlad Alexa on 9/8/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class VAUserDefaults;

@interface PluginsWindowController : NSWindowController <NSTableViewDelegate,NSTableViewDataSource,NSURLDownloadDelegate> {
	
	NSMutableArray *pluginInstances;		//	an array of all plug-in instances		
	VAUserDefaults *defaults;
	VAUserDefaults *mainDefaults;	
	NSMutableArray *pluginsArr;
	NSMutableDictionary *loadedPluginsList;	
	NSMutableString *pluginArchive;
    NSURLDownload* download;	
	IBOutlet NSTableView *listTable;
	IBOutlet NSTextField *pluginTitle;
	IBOutlet NSButton *pluginAuthor;
	IBOutlet NSTextField *pluginDesc;
	IBOutlet NSView *preferencesView;	
	IBOutlet NSImageView *pluginLogo;	
	IBOutlet NSImageView *notLoaded;
	IBOutlet NSTextField *noPreferences;	
	IBOutlet NSButton *uninstallButton;
	IBOutlet NSButton *installButton;	
	IBOutlet NSButton *updatesButton;	
	IBOutlet NSView *prefPaneView;
	IBOutlet NSButton *prefPaneButton;
	IBOutlet NSBox *grayBox;
	IBOutlet NSBox *whiteBox;
	IBOutlet NSBox *updatesBox;	
	IBOutlet NSProgressIndicator *installSpinner;
	IBOutlet NSTextField *updatesHeader;
}

-(void)notifyNewPlugin:(NSDictionary*)db;
-(void)appendNotInstalled:(NSDictionary*)db;

+(BOOL)launchAppByID:(NSString*)bid;
-(NSImage*)iconImgAtPath:(NSString*)path;

+(NSString*)execTask:(NSString*)launch args:(NSArray*)args;
+(BOOL)isAppRunning:(NSString*)appName;
-(void)makePluginsArr;
-(void)syncMe;
-(NSDictionary*)pluginsDb;
-(void)showDetailsFor:(NSInteger)row;
-(id)loadPrefs:(NSString*)path;

-(IBAction)openUrl:(id)sender;
-(IBAction)enable:(id)sender;
-(IBAction)uninstall:(id)sender;
-(IBAction)install:(id)sender;
-(IBAction)updates:(id)sender;
-(IBAction)closeMe:(id)sender;
-(IBAction)openPrefpane:(id)sender;

@end


@interface NSColor (StringOverrides)
+(NSArray *)controlAlternatingRowBackgroundColors;
@end