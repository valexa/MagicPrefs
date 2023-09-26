//
//  MainWindow.h
//  MagicPrefs
//
//  Created by Vlad Alexa on 1/3/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <Sparkle/Sparkle.h>
#import "SpeedInterface.h"
#import "MenuBar.h"
#import "Events.h"

@interface MainWindow : NSObject <NSApplicationDelegate> {
	IBOutlet SUUpdater *updater;	
	Events *events;
	NSUserDefaults *defaults;
	IBOutlet NSWindow *aboutWindow;
	IBOutlet NSWindow *alertWindow;
	IBOutlet NSWindow *welcomeWindow;
	IBOutlet NSWindow *notifWindow;	
	IBOutlet NSButton *alertButton;	
	IBOutlet NSTextField *alertMainText;
	IBOutlet NSTextField *alertSmallText;
	IBOutlet NSTextField *notifText;
	IBOutlet NSImageView *notifImage;
	IBOutlet NSImageView *notifDisabled;
	BOOL savedMouseTracking;
	BOOL savedTrackpadTracking;	
    NSImage *dockIconImage;
}

-(void) growlNotif:(NSString*)title message:(NSString*)message;
-(void)launchPluginIfAnyEnabled;
+(void)launchPluginIfAnyEnabled;
-(void)appInitRoutines:(id)sender;
- (NSString *)driverVer;
- (NSString *)versionString;
- (SInt32) osxVersion;
- (IBAction) openWebsite:(id)sender;
- (IBAction) alertAction:(id)sender;
- (void)copyPrefPane:(NSString*)name;
-(void)syncDefaultPreset:(NSString*)what;
- (void)doUninstall;
-(BOOL) driverCheck;
- (BOOL)movedHelper:(NSString*)moveFrom moveTo:(NSString*)moveTo;

+(BOOL)appWasLaunched:(NSString*)bid;
+ (BOOL)isAppRunning:(NSString*)appName;
- (void) launchPlugins;
-(NSString*)getBIDOfParent;

- (void)setAutostart:(BOOL)set;
- (BOOL)writeServiceFile;
- (void)setLoginItem;
- (void)removeLoginItem;

@end
