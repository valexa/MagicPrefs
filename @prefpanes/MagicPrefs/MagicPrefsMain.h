//
//  MagicPrefsMain.h
//  MagicPrefs
//
//  Created by Vlad Alexa on 1/3/10.
//  Copyright (c) 2010 NextDesign. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import "KeyCodeManager.h"
#import "SpeedInterface.h"
#import "VAUserDefaults.h"
#import "ScrollWindowController.h"
#import "PluginsWindowController.h"
#import <QuartzCore/CoreAnimation.h>

@interface MagicPrefsMain : NSPreferencePane <NSTableViewDelegate,NSTableViewDataSource,NSTabViewDelegate>{
	
	SpeedInterface *speedInterface;
	KeyCodeManager *keyCodeManager;
	ScrollWindowController *scrollWindowController;	
	PluginsWindowController *pluginsWindowController;		
	VAUserDefaults *defaults;
	int gestureCountMouse;
	int gestureCountTrackpad;
	int gestureCountMacbook;	
	int lastGesture;
	
	//
	//Magic Mouse checkboxes
	//	
	
	//tab  1	
	IBOutlet NSButton *onefaClick;	
	IBOutlet NSButton *twofClick;		
	IBOutlet NSButton *threefClick;
	IBOutlet NSButton *fourfClick;	
	IBOutlet NSButton *onefTapLeft;
	IBOutlet NSButton *onefTapRight;
	IBOutlet NSButton *onefTapTail;
	IBOutlet NSButton *twofTap;	
	IBOutlet NSButton *threefTap;		
	IBOutlet NSButton *fourfTap;
	//tab  2
	IBOutlet NSButton *twofSwipeLeft;
	IBOutlet NSButton *twofSwipeRight;
	IBOutlet NSButton *twofSwipeUp;
	IBOutlet NSButton *twofSwipeDown;	
	IBOutlet NSButton *threefSwipeLeft;
	IBOutlet NSButton *threefSwipeRight;
	IBOutlet NSButton *threefSwipeUp;
	IBOutlet NSButton *threefSwipeDown;		
	//tab  3
	IBOutlet NSButton *twofPinchIn;
	IBOutlet NSButton *twofPinchOut;	
	IBOutlet NSButton *threefPinchIn;
	IBOutlet NSButton *threefPinchOut;	
	IBOutlet NSButton *dragTailLeft;
	IBOutlet NSButton *dragTailRight;
	
	//
	//Magic Trackpad checkboxes
	//	
	
	//tab  1		
	IBOutlet NSButton *twofClick2;		
	IBOutlet NSButton *threefClick2;
	IBOutlet NSButton *fourfClick2;	
	IBOutlet NSButton *fiveClick2;	
	IBOutlet NSButton *onefTap2;
	IBOutlet NSButton *onefTap_2;
	IBOutlet NSButton *twofTap2;
	IBOutlet NSButton *twofTap_2;	
	IBOutlet NSButton *threefTap2;
	IBOutlet NSButton *fourfTap2;
    //tab  2
    IBOutlet NSButton *threefSwipeLeft2;
    IBOutlet NSButton *threefSwipeRight2;
    IBOutlet NSButton *threefSwipeUp2;
    IBOutlet NSButton *threefSwipeDown2;    
    IBOutlet NSButton *fourfSwipeLeft2;
    IBOutlet NSButton *fourfSwipeRight2;
    IBOutlet NSButton *fourfSwipeUp2;
    IBOutlet NSButton *fourfSwipeDown2;
    //tab  3 
	IBOutlet NSButton *twofRotateC2;
	IBOutlet NSButton *twofRotateC_2;    
	IBOutlet NSButton *twofRotateCc2;
	IBOutlet NSButton *twofRotateCc_2;    
	IBOutlet NSButton *twofPinchIn2;
	IBOutlet NSButton *twofPinchIn_2;    
	IBOutlet NSButton *twofPinchOut2;
	IBOutlet NSButton *twofPinchOut_2;    
	
	//
	//Macbook Trackpad checkboxes
	//
	
	//tab  1	
	IBOutlet NSButton *twofClick3;		
	IBOutlet NSButton *threefClick3;
	IBOutlet NSButton *fourfClick3;	
	IBOutlet NSButton *fiveClick3;	
	IBOutlet NSButton *onefTap3;
	IBOutlet NSButton *onefTap_3;
	IBOutlet NSButton *twofTap3;
	IBOutlet NSButton *twofTap_3;	
	IBOutlet NSButton *threefTap3;
	IBOutlet NSButton *fourfTap3;
    //tab  2
    IBOutlet NSButton *threefSwipeLeft3;
    IBOutlet NSButton *threefSwipeRight3;
    IBOutlet NSButton *threefSwipeUp3;
    IBOutlet NSButton *threefSwipeDown3;    
    IBOutlet NSButton *fourfSwipeLeft3;
    IBOutlet NSButton *fourfSwipeRight3;
    IBOutlet NSButton *fourfSwipeUp3;
    IBOutlet NSButton *fourfSwipeDown3;
    //tab  3 
    IBOutlet NSButton *twofRotateC3;
    IBOutlet NSButton *twofRotateC_3;    
    IBOutlet NSButton *twofRotateCc3;
    IBOutlet NSButton *twofRotateCc_3;    
    IBOutlet NSButton *twofPinchIn3;
    IBOutlet NSButton *twofPinchIn_3;    
    IBOutlet NSButton *twofPinchOut3;
    IBOutlet NSButton *twofPinchOut_3;	
	
	//end	
	
	IBOutlet NSView *parentView;	
	IBOutlet NSView *mmouseView;
	IBOutlet NSView *mtrackpadView;
	IBOutlet NSView *gtrackpadView;		
	
	IBOutlet NSSlider *trackSliderMouse;
	IBOutlet NSSlider *trackSliderTrackpad;
	
	IBOutlet NSSlider *sensSliderMouse;
	IBOutlet NSSlider *sensSliderTrackpad;
	IBOutlet NSSlider *sensSliderMacbook;	
	
	IBOutlet NSButton *togLiveMouse;
	IBOutlet NSButton *togLiveTrackpad;
	IBOutlet NSButton *togLiveMacbook;	
	
	IBOutlet NSTabView *tabViewMouse;
	IBOutlet NSTabView *tabViewTrackpad;
	IBOutlet NSTabView *tabViewMacbook;	
	
    IBOutlet NSTextField *infoTextMouse;
    IBOutlet NSTextField *infoTextTrackpad;
    IBOutlet NSTextField *infoTextMacbook;	
		
    IBOutlet NSWindow *messageWindow;
    IBOutlet NSTextField *messageText;	
	
	IBOutlet NSWindow *customWindow;
	IBOutlet NSImageView *customImage;	
	IBOutlet NSButton *customSelector;
	IBOutlet NSTableView *customTable;
	IBOutlet NSImageView *keyView;	
	
	IBOutlet NSImageView *leftSwipeImg;
	IBOutlet NSImageView *rightSwipeImg;	
    IBOutlet NSImageView *gtTapToClickImg;	
    IBOutlet NSImageView *gtRotateImg;
    IBOutlet NSImageView *gtPinchImg;    
    IBOutlet NSImageView *gtRotateOverlapImg;
    IBOutlet NSImageView *gtRotateCCOverlapImg;     
    IBOutlet NSImageView *gtPinchInOverlapImg;
    IBOutlet NSImageView *gtPinchOutOverlapImg;       
    IBOutlet NSImageView *gt1fTapOverlapImg;
	IBOutlet NSImageView *gt2fTapOverlapImg;		
	IBOutlet NSImageView *gt2fTapToClickImg;    
	IBOutlet NSImageView *gt3fvSwipeImg;
	IBOutlet NSImageView *gt3fhSwipeImg;    
	IBOutlet NSImageView *gt4fvSwipeImg;
	IBOutlet NSImageView *gt4fhSwipeImg;        
    IBOutlet NSImageView *mtTapToClickImg;
    IBOutlet NSImageView *mtRotateImg;
    IBOutlet NSImageView *mtPinchImg;	
    IBOutlet NSImageView *mtRotateOverlapImg;
    IBOutlet NSImageView *mtRotateCCOverlapImg;     
    IBOutlet NSImageView *mtPinchInOverlapImg;
    IBOutlet NSImageView *mtPinchOutOverlapImg;   
    IBOutlet NSImageView *mt1fTapOverlapImg;
	IBOutlet NSImageView *mt2fTapOverlapImg;
    IBOutlet NSImageView *mt2fTapToClickImg;	    
    IBOutlet NSImageView *mt3fvSwipeImg;
    IBOutlet NSImageView *mt3fhSwipeImg;
    IBOutlet NSImageView *mt4fvSwipeImg;
    IBOutlet NSImageView *mt4fhSwipeImg;    
	
    IBOutlet NSButton *mmPluginsButton;
    IBOutlet NSButton *mtPluginsButton;
    IBOutlet NSButton *gtPluginsButton;    
	
	IBOutlet NSComboBox *presets;
	IBOutlet NSButton *icoToggle;		
	IBOutlet NSSegmentedControl *deviceToggle;	
	IBOutlet NSBox *presetsBox;
	
	NSMutableDictionary *loadedPluginsInfo;		
}

-(void)turnOffLive;
-(void)theEvent:(NSNotification*)notif;
-(void)syncIMG;
-(void)syncUI;
-(void)refreshButtons;
-(void)setInfo;
-(void)setInfoString:(NSTextField*)field count:(int)count;
-(void)addPresets;
-(void)addPop:(id)sender;
-(void)togCheck:(id)sender;
-(void)disableAndTurnOff:(NSButton*)button;
-(NSButton*)checkItemWithTag:(int)tag;
-(void)doWarnings:(int)tag;
-(void)doChecks;
-(id)targetAtIndex:(int)index field:(NSString *)field;
-(void)overlapTest:(id)sender zone1:(NSString*)zone1 zone2:(NSString*)zone2;
-(void)addMissingFromDefault;
-(IBAction)toggleIcon:(id)sender;
-(IBAction)toggleDevice:(id)sender;
-(IBAction)updateMouseTapSens:(id)sender;
-(IBAction)updateMouseSpeed:(id)sender;
-(IBAction)updateTrackpadTapSens:(id)sender;
-(IBAction)updateTrackpadSpeed:(id)sender;
-(IBAction)updateMacbookTapSens:(id)sender;
-(IBAction) togLive:(id) sender;
-(IBAction) helpPressed:(id) sender;
-(IBAction) zonePressed:(id) sender;
-(IBAction) selectedPop:(id) sender;
-(IBAction) checkClick:(id) sender;
-(IBAction) loadPreset:(id) sender;
-(IBAction) savePreset:(id) sender;	
-(IBAction) deletePreset:(id) sender;
-(IBAction) showPlugins:(id)sender;
-(IBAction) showScroll:(id)sender;
-(void) showMsg:(NSString *)msg;
-(IBAction) closeMsg:(id) sender;
-(IBAction)customClick:(id)sender;
-(void)runAppIfNotRunning:(NSString*)app;
-(IBAction)fileDialog:(id)sender;
-(BOOL)validateAscript:(NSString *)string;
-(IBAction)addCustom:(id)sender;
-(IBAction)delCustom:(id)sender;
-(SInt32)osxVersion;
-(IBAction)presetAppPane:(id)sender;
@end