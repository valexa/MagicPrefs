//
//  Manipulator.m
//  cputhrottle
//
//  Created by Vlad Alexa on 10/16/11.
//  Copyright (c) 2011 Next Design. All rights reserved.
//

#import "Manipulator.h"

@implementation Manipulator

@synthesize max,pid;

- (id)init {
    self = [super init];
    if (self) {
        
        /*
        NSString *mode = [[NSRunLoop currentRunLoop] currentMode];
        if (mode == nil) {
            NSLog(@"NSDistributedNotification observer was added on a non running runloop");             
            NSLog(@"%@",[NSRunLoop currentRunLoop]);            
        }
        if ([NSRunLoop currentRunLoop] != [NSRunLoop mainRunLoop]) {
            NSLog(@"NSDistributedNotification observer was added on a run loop that is not the main");            
        }        
        if (![NSThread isMainThread]){
            NSLog(@"NSDistributedNotification observer was added to thread %@ which is not main", [NSThread currentThread]);            
        } 
        */ 
        
    }
    return self;
}

-(void)dealloc
{
    //NSLog(@"Manipulator freed");
    [super dealloc];
}

-(void)gracefulExit
{
    [self detach];
    exit(0);
}

-(void)theEvent:(NSNotification*)notif
{		
	if (![[notif name] isEqualToString:@"CPUThrottleEvent"]) {		
		return;
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){
		if ([[notif object] isEqualToString:@"Quit"]){
            [self gracefulExit];             
		}	
	}			
}


-(void)loop
{
    if (pid == 0 || task == 0) [self gracefulExit];
    
    if (suspended == YES) {
        //[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(loop) userInfo:nil repeats:NO]; 
        [NSThread sleepForTimeInterval:0.1];
        [self loop];
        NSLog(@"Already suspended");
        return;
    }
    
    const double period = 0.1; // max amount for us to sleep
    const double minSleepAmt = 0.02; // minimum sleep amount is 20 ms 
    double percent = [self cpuLoad];
    double error = percent - max;
    
    if(sleepTime == 0.0 && error > 0.0) sleepTime = minSleepAmt;
    sleepTime += error * minSleepAmt;            
    if(sleepTime < minSleepAmt)  sleepTime = 0;
    if(sleepTime > period) sleepTime = period;            
    
    if(sleepTime >= minSleepAmt && percent > max){
        //NSLog(@"Sleeping for %f as current CPU %f is higher than throttle %f",sleepTime,percent,max);
        [self suspendForTime:sleepTime];
    }else{
        //NSLog(@"Not Sleeping as current CPU %f is lower than throttle %f",percent,max);
    }
    
    //[NSTimer scheduledTimerWithTimeInterval:sleepTime+minSleepAmt target:self selector:@selector(loop) userInfo:nil repeats:NO];
    [NSThread sleepForTimeInterval:minSleepAmt];    
    [self loop];
}

-(void) attach
{
    if(task_for_pid(mach_task_self(), pid, &task) != KERN_SUCCESS) {
        NSLog(@"Error on task_for_pid of pid %i",pid);
        task = MACH_PORT_NULL;        
        [self gracefulExit]; 
    }
    
    [self loop];
}

-(void) detach
{
    if (suspended == YES) task_resume(task); //make sure we don't let the task hanging 
    suspended = NO;
    mach_port_deallocate(mach_task_self(), task);
    task = 0;
    pid = 0;
}

-(void) suspendForTime:(double)time
{   
    if(task_suspend(task) != KERN_SUCCESS) {
        NSLog(@"Error on task_suspend of pid %i task %i",pid,task);
    }else{
        suspended = YES;
        //[NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(resume) userInfo:nil repeats:NO];
        //NSLog(@"Suspended task for %@",pid);
        
        [NSThread sleepForTimeInterval:time];
        [self resume];
    }
}

-(void) resume
{  
    if (suspended == NO) return;
    if(task_resume(task) != KERN_SUCCESS){
        NSLog(@"Error on task_resume of pid %i task %i",pid,task);            
    }else{
        suspended = NO;
        //NSLog(@"Resumed task for %@",pid);                    
    }    
}

-(double) cpuLoad
{
    kill(pid, SIGSTOP);  //suspend while doing this to prevent race conditions   
    
    kern_return_t error;
    struct task_basic_info t_info;
    thread_array_t th_array;	
    mach_msg_type_number_t t_info_count = TASK_BASIC_INFO_COUNT, th_count;
    size_t i;
    double my_user_time = 0, my_system_time = 0, my_percent = 0;
    
    if ((error = task_info(task, TASK_BASIC_INFO, (task_info_t)&t_info, &t_info_count)) != KERN_SUCCESS)    {
        NSLog(@"Error on task_info of pid %i task %i",pid,task);
        [self gracefulExit];
    }
    
    if ((error = task_threads(task, &th_array, &th_count)) != KERN_SUCCESS)    {
        NSLog(@"Error on task_threads of pid %i task %i",pid,task);
        [self gracefulExit];        
    }
    
    // sum time for live threads
    for (i = 0; i < th_count; i++) 
    {
        double th_user_time, th_system_time, th_percent;
        
        struct thread_basic_info th_info;
        mach_msg_type_number_t th_info_count = THREAD_BASIC_INFO_COUNT;
        if ((error = thread_info(th_array[i], THREAD_BASIC_INFO, (thread_info_t)&th_info, &th_info_count)) != KERN_SUCCESS) {
            NSLog(@"Error on thread_info of pid %i task %i",pid,task);
        }
        
        th_user_time = th_info.user_time.seconds + th_info.user_time.microseconds / 1e6;
        th_system_time = th_info.system_time.seconds + th_info.system_time.microseconds / 1e6;
        th_percent = (double)th_info.cpu_usage / TH_USAGE_SCALE;
        
        
        my_user_time += th_user_time;
        my_system_time += th_system_time;
        my_percent += th_percent;
    }
    
    // destroy thread array
    for (i = 0; i < th_count; i++)    {
        mach_port_deallocate(mach_task_self(), th_array[i]);
    }
    vm_deallocate(mach_task_self(), (vm_address_t)th_array, sizeof(thread_t) * th_count);
    
    // check last error	
    if (error != KERN_SUCCESS) NSLog(@"Error collecting cpu sample of pid %i ",pid);
    
    // add time for dead threads
    //my_user_time += t_info.user_time.seconds + t_info.user_time.microseconds / 1e6;
    //my_system_time += t_info.system_time.seconds + t_info.system_time.microseconds / 1e6;
    
    //NSLog(@"%i is using %.2f%% CPU (has used %.2f%% %.2f%%,user %.2f%%,system) ",pid_,my_percent,my_user_time+my_system_time,my_user_time,my_system_time);    
    
    kill(pid, SIGCONT);    
    
    return my_percent;
}


@end
