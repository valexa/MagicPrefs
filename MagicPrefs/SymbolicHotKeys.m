//
//  SymbolicHotKeys.m
//  MagicPrefs
//
//  Created by Vlad Alexa on 1/16/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "SymbolicHotKeys.h"


@implementation SymbolicHotKeys

- (id)init {
    self = [super init];
    if (self) {
		hotKeysDictionary = [[NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Library/Preferences/com.apple.symbolichotkeys.plist",NSHomeDirectory()]] retain];
        if (!hotKeysDictionary) NSLog(@"Error getting hotKeysDictionary");
    }
    return self;
}


- (void) dealloc{	
	if (hotKeysDictionary){
		[hotKeysDictionary release];
	}
	[super dealloc];
}

- (NSString *) getFlags:(CGEventFlags)flags{
	NSString *ret = @"";
	if (flags & kCGEventFlagMaskShift){
		ret = [ret stringByAppendingString:@"shift down,"];
	}
	if (flags & kCGEventFlagMaskControl){
		ret = [ret stringByAppendingString:@"control down,"];		
	}
	if (flags & kCGEventFlagMaskAlternate){
		ret = [ret stringByAppendingString:@"option down,"];		
	}
	if (flags & kCGEventFlagMaskCommand){
		ret = [ret stringByAppendingString:@"command down,"];		
	}
	if([ret length] > 1){
		//cut trailing comma
		ret = [ret substringWithRange:NSMakeRange(0,[ret length]-1)];		
	}		
	return ret;
}

- (NSString *)asciiChar:(int)i{
	char *cstr=(char *)malloc(2);
	cstr[0]=(char)i;
	cstr[1]='\0';	
	NSString *ret = [NSString stringWithCString:cstr encoding:NSASCIIStringEncoding];	
	free(cstr);
	return ret;
}

- (NSString *) makeScript:(int)key keycode:(int)keycode flags:(int)flags{
	NSString *ret = nil;
	NSString *keychar = [self asciiChar:key];
    if ([keychar length] > 0){
        NSCharacterSet *letters = [NSCharacterSet lowercaseLetterCharacterSet];
        if ([letters characterIsMember:[keychar characterAtIndex:0]] && key < 128) {
            ret = [NSString stringWithFormat:@"tell application \"System Events\" to keystroke \"%@\" using {%@}",keychar,[self getFlags:flags]];			
        }else {
            ret = [NSString stringWithFormat:@"tell application \"System Events\" to key code %i using {%@}",keycode,[self getFlags:flags]];			
        }
    }else{
        NSLog(@"No keychar for %i %i %i",key,keycode,flags);
    }
	return ret;
}

- (NSString *) keysForAction:(NSString *)action{
	NSString *ret = nil;
	NSDictionary *dict = nil;

	if ([action isEqualToString:@"Toggle Zoom"]) {
		dict = [[hotKeysDictionary objectForKey:@"AppleSymbolicHotKeys"] objectForKey:@"15"];
	}	
	if ([action isEqualToString:@"Screen Zoom In"]) {
		dict = [[hotKeysDictionary objectForKey:@"AppleSymbolicHotKeys"] objectForKey:@"17"];
	}	
	if ([action isEqualToString:@"Screen Zoom Out"]) {
		dict = [[hotKeysDictionary objectForKey:@"AppleSymbolicHotKeys"] objectForKey:@"19"];
	}		
	if ([action isEqualToString:@"Dashboard"]) {
		dict = [[hotKeysDictionary objectForKey:@"AppleSymbolicHotKeys"] objectForKey:@"62"];
	}	
	if ([action isEqualToString:@"Spotlight"]) {
		dict = [[hotKeysDictionary objectForKey:@"AppleSymbolicHotKeys"] objectForKey:@"64"];
	}	
	if ([action isEqualToString:@"Switch Space Left"]) {
		dict = [[hotKeysDictionary objectForKey:@"AppleSymbolicHotKeys"] objectForKey:@"79"];
	}	
	if ([action isEqualToString:@"Switch Space Right"]) {
		dict = [[hotKeysDictionary objectForKey:@"AppleSymbolicHotKeys"] objectForKey:@"81"];
	}			
	
	if (dict){
		if ([[dict objectForKey:@"enabled"] intValue] == 1){
			NSArray *arr = [[dict objectForKey:@"value"] objectForKey:@"parameters"];
            if (arr) {
                ret = [self makeScript:[[arr objectAtIndex:0] intValue] keycode:[[arr objectAtIndex:1] intValue] flags:[[arr objectAtIndex:2] intValue]];
            }else{
                NSLog(@"Broken enabled SymKey for action %@",action);
            }
			//NSLog(@"%@",ret);			
		}else {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:
				[NSDictionary dictionaryWithObjectsAndKeys:@"doAlert",@"what",
				action,@"title",
				[NSString stringWithFormat:@"There is no shortcut enabled for %@, you need to set one and restart MagicPrefs.",action],@"text",
				@"Open Keyboard",@"action",
				nil]
			 ];			
		}		
	}else{
		NSLog(@"Did not find SymbolicHotKeys for:%@.",action);
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:
		 [NSDictionary dictionaryWithObjectsAndKeys:@"doAlert",@"what",
		  action,@"title",		  
		  [NSString stringWithFormat:@"Your operating system is missing the %@ keyboard shortcut (different from the key printed, hardware shortcut)",action],@"text",
		  @"Open Keyboard",@"action",
		  nil]
		 ];			
	}
	
	return ret;
}

@end
