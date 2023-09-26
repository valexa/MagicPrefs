//
//  MPCpuThrottle.h
//  MPCpuThrottle
//
//  Created by Vlad Alexa on 9/23/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MPPluginInterface.h"

@class MPCpuThrottlePreferences;

@interface MPCpuThrottle : NSObject <MPPluginProtocol>{

	MPCpuThrottlePreferences *preferences;
	NSUserDefaults *defaults;
    int last_pid;
    int last_max;
}

@property (retain) MPCpuThrottlePreferences *preferences;

-(void)saveSetting:(id)object forKey:(NSString*)key;
-(NSDictionary*)editNestedDict:(NSDictionary*)dict setObject:(id)object forKeyHierarchy:(NSArray*)hierarchy;

-(void)refresh:(NSTimer*)timer;
-(NSDictionary*)dictWithPidAndBid;

+ (BOOL)isAppRunning:(NSString*)appName;

- (NSString*)installAndCheckHelper:(NSString*)copyFrom;
-(void)setupHelper;
-(NSString*)execTask:(NSString*)launch args:(NSArray*)args;
-(void)setThrottle:(NSString *)num forPid:(NSString *)pid;

@end
