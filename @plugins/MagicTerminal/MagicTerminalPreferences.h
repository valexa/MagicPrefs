//
//  MagicTerminalPreferences.h
//  MagicTerminal
//
//  Created by Vlad Alexa on 9/23/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MagicTerminalPreferences : NSViewController <NSTableViewDataSource> {

	IBOutlet NSTableView	*serversTable;
	IBOutlet NSTableView	*clientsTable;	
    NSMutableArray *servers;    
    NSMutableArray *clients;
	
}

-(void)syncMe;

@end
