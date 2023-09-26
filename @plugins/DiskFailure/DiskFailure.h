//
//  DiskFailure.h
//  DiskFailure
//
//  Created by Vlad Alexa on 9/23/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MPPluginInterface.h"

@class DiskFailurePreferences;
@class DiskFailureMainCore;

@interface DiskFailure : NSObject <MPPluginProtocol>{

	DiskFailurePreferences *preferences;
    DiskFailureMainCore *main;
	
}

@property (retain) DiskFailurePreferences *preferences;

+ (BOOL)isAppRunning:(NSString*)appName;

@end
