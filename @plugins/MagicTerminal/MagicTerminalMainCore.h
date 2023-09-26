//
//  MagicTerminalMainCore.h
//  MagicTerminal
//
//  Created by Vlad Alexa on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BonjourController;

@interface MagicTerminalMainCore : NSObject {
    
     BonjourController *bonjourController; 
    
}

-(NSArray*)getServiceInfo:(NSArray*)arr;
+(NSString*)getMachineUUID;
+(NSString *)getMachineType;
-(NSDictionary*)getTXTDict:(NSNetService *)server;

@end
