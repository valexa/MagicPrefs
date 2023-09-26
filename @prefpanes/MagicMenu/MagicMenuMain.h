//
//  MagicMenuMain.h
//  MagicMenu
//
//  Created by Vlad Alexa on 2/1/10.
//  Copyright (c) 2010 NextDesign. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import "KeyCodeManager.h"

@interface MagicMenuMain : NSPreferencePane 
{	
	
	KeyCodeManager *keyCodeManager;	
		
	IBOutlet NSButton *topItem;
	IBOutlet NSButton *leftItem;
	IBOutlet NSButton *rightItem;
	IBOutlet NSButton *bottomItem;	
	IBOutlet NSPopUpButton *topPop;
	IBOutlet NSPopUpButton *leftPop;
	IBOutlet NSPopUpButton *rightPop;
	IBOutlet NSPopUpButton *bottomPop;	
	IBOutlet NSTextField *topLabel;
	IBOutlet NSTextField *leftLabel;
	IBOutlet NSTextField *rightLabel;	
	IBOutlet NSTextField *bottomLabel;	
	
	IBOutlet NSBox *settingsBox;	
	IBOutlet NSPopUpButton *theTrigger;
	IBOutlet NSSegmentedControl *onoffToggle;		
	IBOutlet NSSlider *delaySlider;
	IBOutlet NSSlider *sensSlider;	
	IBOutlet NSComboBox *presets;
	
    IBOutlet NSWindow *messageWindow;
    IBOutlet NSTextField *messageText;	
	
	IBOutlet NSWindow *customWindow;
	IBOutlet NSImageView *customImage;	
	IBOutlet NSButton *customSelector;
	IBOutlet NSTableView *customTable;
	IBOutlet NSImageView *keyView;	
}

-(void)saveSetting:(id)object forKey:(NSString*)key;
-(void)shakeWindow:(NSWindow*)w;
-(void)animateChange:(NSImageView*)theView newrect:(NSRect)newrect;
-(void) mainViewDidLoad;
-(void)syncUI;
-(void)addPresets;
-(void)addPop:(id)sender;
-(void)togCheck:(id)sender;
-(void)checkItemWithTag:(int)tag;
-(void)syncMenuImage;
-(IBAction)updateTrigger:(id)sender;
-(IBAction)togOnOff:(id)sender;
-(IBAction)updateDelay:(id)sender;
-(IBAction)updateSens:(id)sender;
-(IBAction) selectedPop:(id) sender;
-(IBAction) checkClick:(id) sender;
-(IBAction) helpPressed:(id) sender;
-(IBAction) loadPreset:(id) sender;
-(IBAction) savePreset:(id) sender;	
-(IBAction) deletePreset:(id) sender;
-(void) showMsg:(NSString *)msg;
-(IBAction) closeMsg:(id) sender;
-(id)targetAtIndex:(int)index field:(NSString *)field;
-(IBAction)customClick:(id)sender;
-(void)runAppIfNotRunning:(NSString*)app;
-(IBAction)fileDialog:(id)sender;
-(BOOL)validateAscript:(NSString *)string;
-(IBAction)addCustom:(id)sender;
-(IBAction)delCustom:(id)sender;
-(SInt32)osxVersion;
-(IBAction)presetAppPane:(id)sender;

@end
