//
//  MagicMenu.h
//  MagicPrefs
//
//  Created by Vlad Alexa on 2/3/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "MPPluginInterface.h"

//hide cursor stuff
CGError CGSSetConnectionProperty(int foo, int bar, CFStringRef key, CFTypeRef value);
int _CGSDefaultConnection(void);
//blur stuff
typedef void * CGSConnection;
OSStatus CGSNewConnection(const void **attributes, CGSConnection * id);
typedef void *CGSWindowFilterRef;
typedef int CGSWindowID;
CGError CGSNewCIFilterByName(CGSConnection cid, CFStringRef filterName, CGSWindowFilterRef *outFilter);
CGError CGSSetCIFilterValuesFromDictionary(CGSConnection cid, CGSWindowFilterRef filter, CFDictionaryRef filterValues);
CGError CGSAddWindowFilter(CGSConnection cid, CGSWindowID wid, CGSWindowFilterRef filter, int flags);


@interface MagicMenu : NSWindowController<MPPluginProtocol> {
		
	NSUserDefaults *defaults;	
	NSString *action;
	NSString *activeApp;
	BOOL block;
	BOOL touchdown;
	
	NSDictionary *preset;
	int delay;
	int sens;
		
	IBOutlet NSWindow *magicMenu;
	IBOutlet NSImageView *magicMenuImg;
	IBOutlet NSImageView *middleImg;	
    IBOutlet NSTextField *labelTop;
    IBOutlet NSTextField *labelBottom;
    IBOutlet NSTextField *labelLeft;
    IBOutlet NSTextField *labelRight;	
	IBOutlet NSImageView *selectTop;	
	IBOutlet NSImageView *selectBottom;
	IBOutlet NSImageView *selectLeft;
	IBOutlet NSImageView *selectRight;	
}

-(void)refreshSettings;
-(void)saveSetting:(id)object forKey:(NSString*)key;
-(void)syncDefaultPreset:(NSString*)what;
-(void) selectLabel:(id)label select:(id)select;
-(void) selectLabel:(id)label select:(id)select hard:(BOOL)hard;
-(void) syncLabels:(id)obj i:(NSString*)i;
+(void)blurWindow:(NSWindow *)window;
-(void) performAction;
-(void)animateChange:(NSImageView*)theView newrect:(NSRect)newrect;

@end

