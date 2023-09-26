//
//  IORegInterface.m
//  MagicPrefs
//
//  Created by Vlad Alexa on 4/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "IORegInterface.h"

#define MM_IONAME "BNBMouseDevice"
#define MT_IONAME "BNBTrackpadDevice"

@implementation IORegInterface

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

+ (NSString*)mm_getStringForProperty:(NSString*)propertyName{
    return [IORegInterface getStringForProperty:propertyName service:MM_IONAME];
}

+ (NSString*)mt_getStringForProperty:(NSString*)propertyName{
    return [IORegInterface getStringForProperty:propertyName service:MT_IONAME];    
}

+ (BOOL)mm_getBoolForProperty:(NSString*)propertyName{
    return [IORegInterface getBoolForProperty:propertyName service:MM_IONAME];
}

+ (BOOL)mt_getBoolForProperty:(NSString*)propertyName{
    return [IORegInterface getBoolForProperty:propertyName service:MT_IONAME];    
}

+ (NSString*)getStringForProperty:(NSString*)propertyName service:(const char *)serviceName{
	CFTypeRef	theCFProperty;
	NSString	*ret = nil;
	
	io_service_t serviceForClass = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching(serviceName));
	
	if (serviceForClass) {
		theCFProperty = IORegistryEntryCreateCFProperty(serviceForClass, (CFStringRef)propertyName, kCFAllocatorDefault, 0);        
        if (theCFProperty) {
            ret = [NSString stringWithFormat:@"%@",theCFProperty];//works for any object type
            CFRelease(theCFProperty);           
        }
		IOObjectRelease(serviceForClass);
	}	
	return ret;
}

+ (BOOL)getBoolForProperty:(NSString*)propertyName service:(const char *)serviceName{
	CFBooleanRef	theCFProperty;
	BOOL            ret = NO;
	
	io_service_t serviceForClass = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching(serviceName));
	
	if (serviceForClass) {
		theCFProperty = IORegistryEntryCreateCFProperty(serviceForClass, (CFStringRef)propertyName, kCFAllocatorDefault, 0);        
        ret = CFBooleanGetValue(theCFProperty) ? YES : NO;
        CFRelease(theCFProperty);
		IOObjectRelease(serviceForClass);
	}	
	return ret;
}

@end
