//
//  MagicTerminal.h
//  MagicTerminal
//
//  Created by Vlad Alexa on 9/23/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MPPluginInterface.h"

@class MagicTerminalPreferences;
@class MagicTerminalMainCore;

@interface MagicTerminal : NSObject <MPPluginProtocol>{

	MagicTerminalPreferences *preferences;
    MagicTerminalMainCore *main;
	
}

@property (retain) MagicTerminalPreferences *preferences;


@end
