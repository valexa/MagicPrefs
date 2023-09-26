//
//  MPSafeguardPreferences.h
//  MPSafeguard
//
//  Created by Vlad Alexa on 9/23/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MPSafeguardPreferences : NSViewController <NSTableViewDataSource,NSTableViewDelegate> {

	IBOutlet NSTableView	*appsTable;	    
    NSMutableArray *appsList;    
	
}

-(void)saveSetting:(id)object forKey:(NSString*)key;

-(void)getData;

@end
