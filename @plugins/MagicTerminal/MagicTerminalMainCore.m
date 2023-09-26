//
//  MagicTerminalMainCore.m
//  MagicTerminal
//
//  Created by Vlad Alexa on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MagicTerminalMainCore.h"
#import "BonjourController.h"
#include "sys/sysctl.h"

#if PLUGIN //set in project's GCC_PREPROCESSOR_DEFINITIONS
    #define OBSERVER_NAME_STRING @"MPPluginMagicTerminalEvent"
    #define PREF_OBSERVER_NAME_STRING @"MPPluginMagicTerminalPreferencesEvent"
#else
    #define OBSERVER_NAME_STRING @"VAMagicTerminalEvent"
    #define PREF_OBSERVER_NAME_STRING @"VAMagicTerminalMenubarEvent"
#endif

@implementation MagicTerminalMainCore

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        
        bonjourController = [[BonjourController alloc] init];
        [bonjourController addObserver:self forKeyPath:@"servers" options:NSKeyValueObservingOptionOld context:NULL]; 
        [bonjourController addObserver:self forKeyPath:@"clients" options:NSKeyValueObservingOptionOld context:NULL];    
        
		//listen for events
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:OBSERVER_NAME_STRING object:nil];	  
                
    }
    
    return self;
}

- (void)dealloc
{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];     
    [bonjourController release];
    [super dealloc];      
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (object == bonjourController){	
        if ([keyPath isEqualToString:@"servers"] || [keyPath isEqualToString:@"clients"]) {
            [[NSDistributedNotificationCenter defaultCenter] postNotificationName:PREF_OBSERVER_NAME_STRING object:nil userInfo:
             [NSDictionary dictionaryWithObjectsAndKeys:@"getNearbyServicesCallback",@"what",[self getServiceInfo:bonjourController.servers],@"servers",[self getServiceInfo:bonjourController.clients],@"clients",nil]
             ];           
        }
	}	
}

-(void)theEvent:(NSNotification*)notif{			
	if (![[notif name] isEqualToString:OBSERVER_NAME_STRING]) {		
		return;
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){	
        
	}	
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]]){
        if ([[[notif userInfo] objectForKey:@"what"] isEqualToString:@"getNearbyServices"]){			
            NSString *callback = [[notif userInfo] objectForKey:@"callback"];		
            [[NSDistributedNotificationCenter defaultCenter] postNotificationName:callback object:nil userInfo:
             [NSDictionary dictionaryWithObjectsAndKeys:@"getNearbyServicesCallback",@"what",[self getServiceInfo:bonjourController.servers],@"servers",[self getServiceInfo:bonjourController.clients],@"clients",nil]
             ];	
        }        
    }    	
}

-(NSArray*)getServiceInfo:(NSArray*)arr{
	NSMutableArray *list = [NSMutableArray arrayWithCapacity:1];	
	for (NSNetService *service in arr){
        if ([service hostName]){
            [list addObject:[self getTXTDict:service]];
        }else{
            [list addObject:[NSDictionary dictionaryWithObject:[service name] forKey:@"servicename"]];            
        }
	}
	return list;
}

-(NSDictionary*)getTXTDict:(NSNetService *)server{
    NSDictionary *dict = [NSNetService dictionaryFromTXTRecordData:server.TXTRecordData];
    NSString *username = [[[NSString alloc] initWithData:[dict objectForKey:@"user"] encoding:NSASCIIStringEncoding] autorelease];
    NSString *uuid = [[[NSString alloc] initWithData:[dict objectForKey:@"uuid"] encoding:NSASCIIStringEncoding] autorelease];
    NSString *model = [[[NSString alloc] initWithData:[dict objectForKey:@"machine"] encoding:NSASCIIStringEncoding] autorelease];    
    return [NSDictionary dictionaryWithObjectsAndKeys:username,@"username",server.hostName,@"hostname",uuid,@"uuid",model,@"model",server.name,@"servicename", nil];
}

+ (NSString*)getMachineUUID
{
	NSString *ret = nil;
	io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"));	
	if (platformExpert) {
		CFTypeRef cfstring = IORegistryEntryCreateCFProperty(platformExpert, CFSTR(kIOPlatformUUIDKey), kCFAllocatorDefault, 0);
        if (cfstring) {
            ret = [NSString stringWithFormat:@"%@",cfstring];        
            CFRelease(cfstring);                    
        }
		IOObjectRelease(platformExpert);        
	}	
	return ret;
}

+ (NSString *)getMachineType{
    NSString * modelString  = @"";
    int        modelInfo[2] = { CTL_HW, HW_MODEL };
    size_t     modelSize;
    
    if (sysctl(modelInfo,2,NULL,&modelSize, NULL, 0) == 0) {
        void * modelData = malloc(modelSize);
        
        if (modelData) {
            if (sysctl(modelInfo,2,modelData,&modelSize,NULL, 0) == 0) {
                modelString = [NSString stringWithUTF8String:modelData];
            }            
            free(modelData);
        }
    }
    NSCharacterSet *charset = [[NSCharacterSet letterCharacterSet] invertedSet];
    return [modelString stringByTrimmingCharactersInSet:charset];
}

@end
