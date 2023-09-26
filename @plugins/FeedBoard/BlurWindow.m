//
//  BlurWindow.m
//  FeedBoard
//
//  Created by Vlad Alexa on 1/16/11.
//  Copyright 2011 NextDesign. All rights reserved.
//

#import "BlurWindow.h"

@implementation BlurWindow

+(void)blurWindow:(NSWindow *)window{
	CGSConnection thisConnection;
	CGSWindowFilterRef compositingFilter;
	/*
	 Compositing Types
	 Under the window   = 1 <<  0
	 Over the window    = 1 <<  1
	 On the window      = 1 <<  2
	 */
	NSInteger compositingType = 1 << 0; // Under the window
	/* Make a new connection to CoreGraphics */
	CGSNewConnection(NULL, &thisConnection);
	/* Create a CoreImage filter and set it up */
	
	CGSNewCIFilterByName(thisConnection, (CFStringRef)@"CIDiscBlur", &compositingFilter); //CIMinimumComponent CIGaussianBlur
	NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:2.5] forKey:@"inputRadius"];
	CGSSetCIFilterValuesFromDictionary(thisConnection, compositingFilter, (CFDictionaryRef)options);
	CGSAddWindowFilter(thisConnection, [window windowNumber], compositingFilter, compositingType);	
}

@end
