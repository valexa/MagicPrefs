//
//  LaunchBoard.h
//  LaunchBoard
//
//  Created by Vlad Alexa on 12/6/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPPluginInterface.h"

@class LaunchBoardMainWindow;
@class LaunchBoardPreferences;

@interface LaunchBoard : NSObject <MPPluginProtocol> {

	NSUserDefaults *defaults;	
	LaunchBoardMainWindow *window;
    LaunchBoardPreferences *preferences;
    
}

@property (retain) LaunchBoardPreferences *preferences;

@end

