//
//  MagicTerminalPreferences.m
//  MagicTerminal
//
//  Created by Vlad Alexa on 9/23/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "MagicTerminalPreferences.h"

#define OBSERVER_NAME_STRING @"MPPluginMagicTerminalPreferencesEvent"
#define MAIN_OBSERVER_NAME_STRING @"MPPluginMagicTerminalEvent"


@implementation MagicTerminalPreferences

- (void)loadView {
    [super loadView];
	
    //register for notifications
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:OBSERVER_NAME_STRING object:nil];

    servers = [[NSMutableArray alloc] init];    
    clients = [[NSMutableArray alloc] init];
    
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:nil userInfo:
	 [NSDictionary dictionaryWithObjectsAndKeys:@"getNearbyServices",@"what",OBSERVER_NAME_STRING,@"callback",nil]
	 ];	    
    
}

- (void)dealloc {
    [super dealloc];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];     
    [servers release];
    [clients release];
}

-(void)theEvent:(NSNotification*)notif{		
	if (![[notif name] isEqualToString:OBSERVER_NAME_STRING]) {
		return;
	}		
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]]){
		if ([[[notif userInfo] objectForKey:@"what"] isEqualToString:@"getNearbyServicesCallback"]){
			[servers setArray:[[notif userInfo] objectForKey:@"servers"]];
			[clients setArray:[[notif userInfo] objectForKey:@"clients"]];            
			[self syncMe];
		}		
	}	
}


-(void)syncMe{	   
    [serversTable reloadData];
    [clientsTable reloadData];    
}    

#pragma mark NSTableView datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView {
	if ( theTableView == serversTable ) return [servers count];
	if ( theTableView == clientsTable ) return [clients count];
	return 0;	
}


- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)theColumn row:(NSInteger)rowIndex {
	if ( theTableView == serversTable ) {
        NSDictionary *item = [servers objectAtIndex:rowIndex];            
        if ([[item objectForKey:@"hostname"] length] > 1) {
            if ([[item objectForKey:@"username"] length] > 1) {
                return [NSString stringWithFormat:@"%@@%@%@",[item objectForKey:@"username"],[item objectForKey:@"hostname"],[item objectForKey:@"model"]];                
            }else{
                return [NSString stringWithFormat:@"%@%@",[item objectForKey:@"hostname"],[item objectForKey:@"model"]];                
            }
        }else{
            return [item objectForKey:@"servicename"];            
        }                
    }    
	if ( theTableView == clientsTable ) {
        NSDictionary *item = [clients objectAtIndex:rowIndex];             
        if ([[item objectForKey:@"hostname"] length] > 1) {
            if ([[item objectForKey:@"username"] length] > 1) {
                return [NSString stringWithFormat:@"%@@%@%@",[item objectForKey:@"username"],[item objectForKey:@"hostname"],[item objectForKey:@"model"]];                
            }else{
                return [NSString stringWithFormat:@"%@%@",[item objectForKey:@"hostname"],[item objectForKey:@"model"]];                
            }
        }else{
            return [item objectForKey:@"servicename"];            
        }                
    }       
	return nil;
}


@end
