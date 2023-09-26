//
//  MenuBar.h
//  MagicPrefs
//
//  Created by Vlad Alexa on 11/23/09.
//  Copyright 2009 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <PreferencePanes/PreferencePanes.h>
#import <Sparkle/Sparkle.h>

@interface MenuBar : NSObject <NSMenuDelegate> {	
	
	NSUserDefaults *defaults;
	IBOutlet SUUpdater *updater;
    CFTimeInterval lastRefresh;    
	
@private
	NSStatusItem *_statusItem;	
	
}

-(void)loadIcon;
-(void)setBatteryIcon:(NSString*)type;
-(void)loadMenu;
- (NSMenu *) newMenu;
- (NSMenu *)newIconMenu;
- (NSMenu *) newPresetsMenu;
- (NSMenu *)newPluginsMenu;
- (NSMenu *)newStatsMenu;
-(void)makeStatsSubmenu:(NSMenu*)subMenu device:(NSString*)device name:(NSString*)name;
- (void) togMenuBar:(id)sender;	
- (void) togCtrlZoom:(id)sender;
- (void) togEnabled:(id)sender;		
- (void) togAutostart:(id)sender;	
- (void) togStatistics:(id)sender;
- (void) togOSXGestures:(id)sender;
-(NSString*)humanizeCount:(NSString*)count;
-(NSString*)humanizeKind:(NSString*)kind steps:(NSString*)steps;
-(BOOL)doesPluginExist:(NSString*)name dict:(NSDictionary*)pluginDict;

-(NSImage *)NSImageFromPDF:(NSString*)fileName size:(CGSize)size page:(size_t)pageNum;
-(NSImage*)newNSImageFromCGImage:(CGImageRef)cgImage;
-(NSImage*)applyCIFilter:(NSString*)name toImage:(NSImage*)source;

-(NSDictionary*)editNestedDict:(NSDictionary*)dict setObject:(id)object forKeyHierarchy:(NSArray*)hierarchy;

-(void)saveCFPrefs:(id)object forKey:(NSString*)key domain:(NSString*)domain;

@end
