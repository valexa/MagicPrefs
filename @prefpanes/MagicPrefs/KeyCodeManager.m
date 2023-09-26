//
//  KeyCodeManager.m
//  prefpane
//
//  Created by Sastira on 5/24/08.
//  Copyright 2008 Slightly Sane. All rights reserved.
//

#import "KeyCodeManager.h"

@implementation KeyCodeManager

- (id)init
{
    self = [super init];
    if(self) {
		keyCodeDictionary = [[[NSString stringWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"KeyCode" ofType:@"plist"] encoding:NSUTF8StringEncoding error:nil] propertyList] retain];													 
    }
    return self;
}

- (void) dealloc{	
	if (keyCodeDictionary){
		[keyCodeDictionary release];
	}
	[super dealloc];
}

//is fucked
- (NSString *)translateKeyCode:(UInt16)charCode {
	UniCharCount maxStringLength = 4, actualStringLength;
	UniChar unicodeString[4];
	TISInputSourceRef keyboardLayout = TISCopyCurrentKeyboardLayoutInputSource();
	CFDataRef uchr = (CFDataRef)TISGetInputSourceProperty( keyboardLayout, kTISPropertyUnicodeKeyLayoutData); 	
	//NSString *layoutName = TISGetInputSourceProperty( keyboardLayout, kTISPropertyLocalizedName);	
	CFRelease(keyboardLayout);	
	UInt32 deadKeyState;	
	OSStatus err = UCKeyTranslate( (UCKeyboardLayout*)CFDataGetBytePtr(uchr),charCode,kUCKeyActionDown,0,LMGetKbdType(),kUCKeyTranslateNoDeadKeysBit,&deadKeyState,maxStringLength,&actualStringLength,unicodeString);
	if (err !=  noErr) NSLog(@"UCKeyTranslate failed for:%i",charCode);	
	//NSLog(@"translated %i into  (%@ layout)",charCode,[NSString stringWithCharacters:unicodeString length:1],layoutName);		
	return [NSString stringWithCharacters:unicodeString length:1];	
}

- (NSString *) keyCodeToChar: (CGKeyCode) keyCode{
	NSString *keyCodeString = nil;
	
	if ([keyCodeDictionary objectForKey:[NSString stringWithFormat: @"%i", keyCode]]){
		keyCodeString = [keyCodeDictionary objectForKey:[NSString stringWithFormat: @"%i", keyCode]];
	}
	
	if (keyCodeString == nil){
		NSLog(@"keyCodeToChar nil for %i",keyCode);
		keyCodeString = @"";
	}
	
	return keyCodeString;
}

- (CGKeyCode) charToKeyCode:(NSString *) keyChar{
	if ([keyChar length] == 0){
		return 0;
	}	
	NSArray *arr = [keyCodeDictionary allKeysForObject:keyChar];
	if ([arr count] > 0){
		return [[arr lastObject] intValue];
	}else{
		NSLog(@"charToKeyCode not found for %@",keyChar);
	}
	return 0;
}

- (NSString *) shortcutToString:(NSString *) shortcut{
	if ([shortcut length] == 0){
		return NULL;
	}	
	NSArray *split = [shortcut componentsSeparatedByString:@"⟶"];
	NSString *ret = @"";
	for (id key in split){
		ret = [ret stringByAppendingString:[self keyCodeToChar:[key intValue]]];	
	}
	return ret;
}

- (NSString *) shortcutToArrowsString:(NSString *) shortcut{
	if ([shortcut length] == 0){
		return NULL;
	}	
	NSArray *split = [shortcut componentsSeparatedByString:@"⟶"];
	NSString *ret = @"";
	for (id key in split){
		ret = [ret stringByAppendingString:[self keyCodeToChar:[key intValue]]];		
		ret = [ret stringByAppendingString:@"  ⟶  "];			
	}
	ret = [ret substringWithRange:NSMakeRange(0,[ret length]-5)];		
	return ret;
}

 - (NSString *) arrowsStringToChars:(NSString *) string{
	 if ([string length] == 0){
		 return NULL;
	 }
	 NSArray *split = [string componentsSeparatedByString:@"⟶"];
	 NSString *ret = @"";
	 for (id key in split){
		 ret = [ret stringByAppendingString:[NSString stringWithFormat:@"%i",[self charToKeyCode:key]]];
		 ret = [ret stringByAppendingString:@"⟶"];			
		
	 }
	ret = [ret substringWithRange:NSMakeRange(0,[ret length]-1)];	 
	return ret;
 }

- (NSArray *) shortcutToKeyCodes:(NSString *) shortcut{
	NSArray *split = [shortcut componentsSeparatedByString:@"⟶"];
	return split;
}

@end
