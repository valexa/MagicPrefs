//
//  BatteryInterface.h
//  MagicPrefs
//
//  Created by Vlad Alexa on 4/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <IOKit/hid/IOHIDKeys.h>
#import <IOKit/hidsystem/IOHIDShared.h>

@interface IORegInterface : NSObject {
@private
    
}

+ (NSString*)mm_getStringForProperty:(NSString*)propertyName;
+ (NSString*)mt_getStringForProperty:(NSString*)propertyName;
+ (NSString*)getStringForProperty:(NSString*)propertyName service:(const char *)serviceName;

+ (BOOL)mm_getBoolForProperty:(NSString*)propertyName;
+ (BOOL)mt_getBoolForProperty:(NSString*)propertyName;
+ (BOOL)getBoolForProperty:(NSString*)propertyName service:(const char *)serviceName;

@end
