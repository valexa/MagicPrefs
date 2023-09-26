//
//  BonjourController.h
//  MagicTerminal
//
//  Created by Vlad Alexa on 3/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

@interface BonjourController : NSObject <NSNetServiceBrowserDelegate,NSNetServiceDelegate>{
	NSNetServiceBrowser		*serverBrowser;
	NSNetServiceBrowser		*clientBrowser;
    NSMutableArray *servers;
    NSMutableArray *clients;    
    BOOL    serviceStarted;
    NSFileHandle	*listeningSocket;  
	NSNetService	*netService;    
    IBOutlet NSPanel *pairScreen;
    NSString *serviceName;
}

@property (nonatomic, retain) NSMutableArray *servers;
@property (nonatomic, retain) NSMutableArray *clients;

-(void) toggleBonService;

-(void) sendOutput:(NSString*)string clientID:(int)clientID;
-(NSString*)execTask:(NSString*)launch args:(NSArray*)args path:(NSString*)path;
-(NSString*)generatePairCode;
-(int)getIdOfServiceNamed:(NSString*)name;

@end

