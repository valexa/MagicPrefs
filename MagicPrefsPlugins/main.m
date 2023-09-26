//
//  main.m
//  MagicPrefsPlugins
//
//  Created by Vlad Alexa on 8/30/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
	
	if(getenv("NSZombieEnabled")) {
		NSLog(@"NSZombieEnabled enabled!!");
	}
	if(getenv("NSAutoreleaseFreedObjectCheckEnabled")) {
		NSLog(@"NSAutoreleaseFreedObjectCheckEnabled enabled!!");
	}		
	if(getenv("NSTraceEvents")) {
		NSLog(@"NSTraceEvents enabled!!");
	}			
	if(getenv("MallocStackLogging")) {
		NSLog(@"MallocStackLogging enabled!!");
	}	
	
    return NSApplicationMain(argc,  (const char **) argv);
}
