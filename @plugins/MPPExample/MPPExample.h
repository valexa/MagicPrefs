//
//  MPPExample.h
//  MPPExample
//
//  Created by Vlad Alexa on 9/23/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MPPluginInterface.h"

@class MPPExamplePreferences;

@interface MPPExample : NSObject <MPPluginProtocol>{

	MPPExamplePreferences *preferences;
	NSUserDefaults *defaults;
	
}

@property (retain) MPPExamplePreferences *preferences;

-(void)saveSetting:(id)object forKey:(NSString*)key;
-(NSDictionary*)editNestedDict:(NSDictionary*)dict setObject:(id)object forKeyHierarchy:(NSArray*)hierarchy;

@end
