//
//  Manipulator.h
//  cputhrottle
//
//  Created by Vlad Alexa on 10/16/11.
//  Copyright (c) 2011 Next Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <mach/mach.h>

@interface Manipulator : NSObject{

    BOOL suspended;
    task_t task;
    pid_t pid;
    double max;
    double sleepTime;
    
}

@property pid_t pid;
@property double max;

-(void) gracefulExit;

-(void) loop;

-(void) attach; 
-(void) detach; 

-(void) suspendForTime:(double)time; 
-(void) resume; 

-(double) cpuLoad;     

@end
