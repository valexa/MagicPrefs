//
//  SpeedInterface.h
//  MagicPrefs
//
//  Created by Vlad Alexa on 12/1/09.
//  Copyright 2009 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <IOKit/hid/IOHIDKeys.h>
#import <IOKit/hidsystem/IOHIDShared.h>

@interface SpeedInterface : NSObject {

	io_object_t	hidDev;	
	double	currMouseSpeed;	
	double	currTrackpadSpeed;		
	
}

- (double)mouseCurrSpeed;
- (double)trackpadCurrSpeed;
- (kern_return_t)getMouseSpeed:(double*)value;
- (kern_return_t)getTrackpadSpeed:(double*)value;
- (void)setMouseSpeed:(double)value;
- (void)setTrackpadSpeed:(double)value;
- (kern_return_t) findHIDSystem;	

@end
