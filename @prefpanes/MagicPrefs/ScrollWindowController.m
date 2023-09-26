//
//  ScrollWindowController.m
//  MagicPrefs
//
//  Created by Vlad Alexa on 2/13/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "ScrollWindowController.h"


@implementation ScrollWindowController

- (id)init{	
    self = [super initWithWindowNibName:@"ScrollWindow"];    
	if (self) {		
	
		//alloc defaults
		defaults = [[VAUserDefaults alloc] initWithPlist:@"com.vladalexa.MagicPrefs.plist"];	
			
	}	
	
	return self;
}

- (void) windowDidLoad {
	[self syncMe];   
}	

-(void) checkMatrix:(NSMatrix *)matrix byString:(NSString *)string
{    
    for (NSButtonCell *cell in [matrix cells]) {
        if ([string rangeOfString:[cell title]].location != NSNotFound){
            [cell setState:NSOnState];
        }else{
            [cell setState:NSOffState];            
        }
    }
}
 
-(IBAction)segmentChange:(id)sender
{   
    NSArray *cells = [(NSMatrix *)sender cells];
    
    NSMutableString *value = [NSMutableString stringWithCapacity:1];
    
    for (NSButtonCell *cell in cells) {
        if ([cell state] == NSOnState ) {
            [value appendFormat:@",%@",[cell title]];
        }
    }
    
	NSString *str = nil;	
	if (sender == oneFinger) str = @"one finger";
	if (sender == twoFinger) str = @"two finger";
	if (sender == threeFinger) str = @"three finger";
	if (sender == fourFinger) str = @"four finger";	
	
	if (str){
		NSMutableDictionary *dict = [[defaults objectForKey:@"scrolling"] mutableCopy];	
		[dict setObject:value forKey:str];
		[defaults setObject:dict forKey:@"scrolling"];
		[defaults synchronize];
		[dict release];	
	}	

}	

-(IBAction)closeMe:(id)sender{
	[NSApp endSheet:[sender window]];
	//[[sender window] close];
	[[sender window] orderOut:self];	
}

-(void)syncMe{
	NSDictionary *scroll = [defaults objectForKey:@"scrolling"];
	[self checkMatrix:oneFinger byString:[scroll objectForKey:@"one finger"]];
	[self checkMatrix:twoFinger byString:[scroll objectForKey:@"two finger"]];
	[self checkMatrix:threeFinger byString:[scroll objectForKey:@"three finger"]];
	[self checkMatrix:fourFinger byString:[scroll objectForKey:@"four finger"]];		
}

@end
