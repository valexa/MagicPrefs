//
//  ScrollWindowController.h
//  MagicPrefs
//
//  Created by Vlad Alexa on 2/13/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VAUserDefaults.h"

@interface ScrollWindowController : NSWindowController {

	VAUserDefaults *defaults;
		
	IBOutlet NSMatrix *oneFinger;
	IBOutlet NSMatrix *twoFinger;
	IBOutlet NSMatrix *threeFinger;
	IBOutlet NSMatrix *fourFinger;	
	
}

-(void) checkMatrix:(NSMatrix *)matrix byString:(NSString*)string;
-(IBAction)segmentChange:(id)sender;
-(IBAction)closeMe:(id)sender;
-(void)syncMe;

@end
