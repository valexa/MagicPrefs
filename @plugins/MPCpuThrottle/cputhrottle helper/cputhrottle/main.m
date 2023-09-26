//
//  main.m
//  cputhrottle
//
//  Created by Vlad Alexa on 10/16/11.
//  Copyright (c) 2011 Next Design. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Manipulator.h"

Manipulator *manipulator;

static void control_c(int sig);
static void notifCallback(CFNotificationCenterRef  center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);

void control_c(int sig)
{
    [manipulator detach];
    CFRunLoopStop(CFRunLoopGetCurrent());        
}

void notifCallback(CFNotificationCenterRef  center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    if (!CFStringCompare(object, CFSTR("Quit"), kCFCompareCaseInsensitive)) {
        [manipulator detach];        
        CFNotificationCenterRemoveObserver(center, observer, NULL, NULL);
        CFRunLoopStop(CFRunLoopGetCurrent());
    }
}

int main (int argc, const char * argv[])
{
    if(argc < 3)  {
        NSLog(@"usage: cputhrottle [PID] [0-100]");        
        return -1;
    }    
    
    signal(SIGINT, control_c);    
    
    CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(),CFSTR("cputhrottle"),notifCallback,CFSTR("CPUThrottleEvent"),NULL,CFNotificationSuspensionBehaviorDeliverImmediately);    
    
    @autoreleasepool {                
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            pid_t pid = [[NSString stringWithFormat:@"%s",argv[1]] intValue];
            double max = [[NSString stringWithFormat:@"%s",argv[2]] intValue] / 100.0; 
            
            NSString *msg = [NSString stringWithFormat:@"Throttling %i to %.1f%%",pid,max];
            NSLog(@"%@",msg);   
            [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"CPUThrottleEvent" object:msg userInfo:nil options:NSNotificationPostToAllSessions]; 
            
            manipulator = [[[Manipulator alloc] init] autorelease];       
            manipulator.max = max;
            manipulator.pid = pid;        
            [manipulator attach];
        });                 
        
    }    
    
    [[NSRunLoop currentRunLoop] run];             
    
    // not reached
    return 0;
}
