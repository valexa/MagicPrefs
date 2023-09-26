//
//  HeatSyncPref.h
//  HeatSync
//
//  Created by Vlad Alexa on 1/12/11.
//  Copyright (c) 2011 NextDesign. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import "HeatSyncPreferences.h"

@interface HeatSyncPref : NSPreferencePane {
	IBOutlet NSView *prefView;
 	IBOutlet HeatSyncPreferences *prefController;
	IBOutlet NSSegmentedControl *startToggle;
	IBOutlet NSSegmentedControl *dockToggle;    
	IBOutlet NSTextField *notice;
	IBOutlet NSImageView *icon;    
	IBOutlet NSButton *download;    
}

- (void) mainViewDidLoad;

-(IBAction) startToggle:(id)sender;
-(IBAction) dockToggle:(id)sender;
-(IBAction) openURL:(id)sender;

-(void)saveSetting:(id)object forKey:(NSString*)key;

- (BOOL)isAppRunning:(NSString*)appName;
- (void)setAutostart;
- (void)removeAutostart;

@end
