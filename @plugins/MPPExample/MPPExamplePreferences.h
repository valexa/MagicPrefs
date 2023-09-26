//
//  MPPExamplePreferences.h
//  MPPExample
//
//  Created by Vlad Alexa on 9/23/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MPPExamplePreferences : NSViewController {

	IBOutlet NSButton *squareButton;
	
}

-(void)saveSetting:(id)object forKey:(NSString*)key;

-(IBAction)squareToggle:(id)sender;

@end
