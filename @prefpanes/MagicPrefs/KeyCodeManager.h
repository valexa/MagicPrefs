//
//  KeyCodeManager.h
//  prefpane
//
//  Created by Sastira on 5/24/08.
//  Copyright 2008 Slightly Sane. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

@interface KeyCodeManager : NSObject{
	NSDictionary *keyCodeDictionary;
}

- (NSString *) keyCodeToChar: (CGKeyCode) keyCode;
- (CGKeyCode) charToKeyCode: (NSString *) keyChar;
- (NSString *) shortcutToString:(NSString *) shortcut;
- (NSString *) shortcutToArrowsString:(NSString *) shortcut;
- (NSString *) arrowsStringToChars:(NSString *) string;
- (NSArray *) shortcutToKeyCodes:(NSString *) shortcut;

@end
