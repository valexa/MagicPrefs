//
//  KeyView.m
//  MagicPrefs
//
//  Created by Vlad Alexa on 1/1/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "KeyView.h"


@implementation KeyView

- (void)awakeFromNib
{
		modifiers = [[NSMutableDictionary dictionaryWithCapacity:1] retain];	
}	

- (BOOL)becomeFirstResponder{
	//NSLog (@"KeyView becomeFirstResponder");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneMainEvent" object:@"ArrowON" userInfo:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneMMMainEvent" object:@"ArrowON" userInfo:nil];	
	return YES;
}

- (BOOL)acceptsFirstResponder{
	//NSLog (@"KeyView acceptsFirstResponder");	
	return YES;
}

- (BOOL)resignFirstResponder{
	//NSLog (@"KeyView did resignFirstResponder");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneMainEvent" object:@"ArrowOFF" userInfo:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneMMMainEvent" object:@"ArrowOFF" userInfo:nil];	
	return YES;
}

- (BOOL)showsFirstResponder{
	//NSLog (@"KeyView will showsFirstResponder");	
	return YES;
}

- (void)keyUp:(NSEvent*)event{
	//CFShow(event);
}

- (void)keyDown:(NSEvent*)event{
	//CFShow(event);	
	NSString *code = [NSString stringWithFormat:@"%i",[event keyCode]];		
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[event characters],@"char",code,@"value",@"keyEvent",@"name",nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneMainEvent" object:@"local" userInfo:dict];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneMMMainEvent" object:@"local" userInfo:dict];	
}

- (void)flagsChanged:(NSEvent*)event{
	//CFShow(event);	
	if ([event keyCode] == 0){
		//NSLog(@"Got zero modifier keycode");
		return;
	}
	NSString *code = [NSString stringWithFormat:@"%i",[event keyCode]];		
	int count = [[modifiers objectForKey:code] intValue];
	count += 1;		
	if (count == 1){		
		[modifiers setObject:@"1" forKey:code];			
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:code,@"value",@"keyEvent",@"name",nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneMainEvent" object:@"local" userInfo:dict];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneMMMainEvent" object:@"local" userInfo:dict];		
	}		
	if (count == 2){
		[modifiers setObject:@"0" forKey:code];
	}	
}

@end
