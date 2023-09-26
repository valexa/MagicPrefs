//
//  Written by Rainer Brockerhoff for MacHack 2002.
//  Copyright (c) 2002 Rainer Brockerhoff.
//	rainer@brockerhoff.net
//	http://www.brockerhoff.net/
//
//	This is part of the sample code for the MacHack 2002 paper "Plugged-in Cocoa".
//	You may reuse this code anywhere as long as you assume all responsibility.
//	If you do so, please put a short acknowledgement in the documentation or "About" box.
//

#import <Foundation/Foundation.h>
#import "MPPluginInterface.h"

extern const CFStringRef kLSItemArchitecturesValidOnCurrentSystem;

@interface MagicLauncher : NSObject<MPPluginProtocol> {

	NSWindow *magicLauncher;
	NSUserDefaults *defaults;
	int max;
	BOOL active;
	
}

-(void)getMax;
-(float)computeX;
-(float)computeY;
-(void)animateChange:(id)theView newrect:(NSRect)newrect;
-(void)iconPush:(id)sender;
-(NSArray*)iconMatrixFive:(NSArray *)arr;
-(NSArray*)iconMatrix:(NSArray *)arr;
-(NSDictionary *)getRecentPaths;
-(NSDictionary *)listDirRec:(NSString *)path;
-(NSArray*)getRecentApps;
-(NSArray*)mdfindApps;
-(NSString *)mdinfo:(NSString *)str attrib:(CFStringRef)attrib;
-(BOOL)pathIsLaunchable:(NSString *)path;
-(BOOL)appWasLaunched:(NSString*)path;

@end

