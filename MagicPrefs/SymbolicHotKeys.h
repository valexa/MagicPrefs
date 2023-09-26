//
//  SymbolicHotKeys.h
//  MagicPrefs
//
//  Created by Vlad Alexa on 1/16/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

@interface SymbolicHotKeys : NSObject {

	NSDictionary *hotKeysDictionary;
	
}


- (NSString *) asciiChar:(int)i;
- (NSString *) getFlags:(CGEventFlags)flags;
- (NSString *) keysForAction:(NSString *)action;
- (NSString *) makeScript:(int)key keycode:(int)keycode flags:(int)flags;

@end
