//
//  MPSafeguard.h
//  MPSafeguard
//
//  Created by Vlad Alexa on 9/23/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MPPluginInterface.h"

@class MPSafeguardPreferences;

@interface MPSafeguard : NSObject <MPPluginProtocol>{

	MPSafeguardPreferences *preferences;
	NSUserDefaults *defaults;
    BOOL pingReply;
	BOOL selfWasHanged;
}

@property (retain) MPSafeguardPreferences *preferences;

-(void)saveSetting:(id)object forKey:(NSString*)key;

-(void)notifyIfNew:(NSString*)name;

-(NSArray*)deviceData:(NSString*)deviceName;
-(NSArray*)clientsForDevice:(NSString*)name;

- (NSDictionary *)getTaps;
- (BOOL)pidIsTapping:(pid_t)pid;
- (NSDictionary *)infoForPID:(pid_t)pid;

+ (BOOL)isAppRunning:(NSString*)appName;

@end
