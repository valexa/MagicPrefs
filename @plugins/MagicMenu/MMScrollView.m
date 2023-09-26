//
//  MMScrollView.m
//  MagicPrefs
//
//  Created by Vlad Alexa on 12/19/09.
//  Copyright 2009 NextDesign. All rights reserved.
//

#import "MMScrollView.h"

@implementation MMScrollView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        NSDictionary *dict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:NSGlobalDomain]; /// ~/Library/Preferences/.GlobalPreferences.plist
        if ([dict objectForKey:@"com.apple.swipescrolldirection"] == nil) {
            natural = YES;
        } else {
            natural = [[dict objectForKey:@"com.apple.swipescrolldirection"] boolValue];            
        }
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.	
}

- (void)scrollWheel:(NSEvent *)event {
	if ([event type] == 22){
		NSString *phase;
		if ([[event description] rangeOfString:@"scrollPhase"].location == NSNotFound) {
			phase = @"None";
		}else{
			NSString *object = [[[event description] componentsSeparatedByString:@" "] lastObject];				
			phase = [object substringWithRange:NSMakeRange(12,[object length]-12)];			
		}		
		if ([phase isEqualToString:@"None"]){
			if ( ([event deltaY] > 0 && natural == NO) || ([event deltaY] < 0 && natural == YES) ) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"MPPluginMagicMenuEvent" object:@"pushMMenuTop"];			
			} 
			if ( ([event deltaY] < 0 && natural == NO) || ([event deltaY] > 0 && natural == YES) ) {	
				[[NSNotificationCenter defaultCenter] postNotificationName:@"MPPluginMagicMenuEvent" object:@"pushMMenuBottom"];				
			} 	
			if ( ([event deltaX] > 0  && natural == NO) || ([event deltaX] < 0  && natural == YES) ) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"MPPluginMagicMenuEvent" object:@"pushMMenuLeft"];			
			} 
			if ( ([event deltaX] < 0  && natural == NO) || ([event deltaX] > 0  && natural == YES) ) {	
				[[NSNotificationCenter defaultCenter] postNotificationName:@"MPPluginMagicMenuEvent" object:@"pushMMenuRight"];				
			} 			
		}
		if ([phase isEqualToString:@"Begin"]){
			if ( ([event deltaY] > 0 && natural == NO) || ([event deltaY] < 0 && natural == YES) ) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"MPPluginMagicMenuEvent" object:@"pushMMenuTopHard"];			
			} 
			if ( ([event deltaY] < 0 && natural == NO) || ([event deltaY] > 0 && natural == YES) ) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"MPPluginMagicMenuEvent" object:@"pushMMenuBottomHard"];				
			} 	
			if ( ([event deltaX] > 0  && natural == NO) || ([event deltaX] < 0  && natural == YES) ) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"MPPluginMagicMenuEvent" object:@"pushMMenuLeftHard"];			
			} 
			if ( ([event deltaX] < 0  && natural == NO) || ([event deltaX] > 0  && natural == YES) ) {	
				[[NSNotificationCenter defaultCenter] postNotificationName:@"MPPluginMagicMenuEvent" object:@"pushMMenuRightHard"];				
			} 			
		}			
	}	
}


@end
