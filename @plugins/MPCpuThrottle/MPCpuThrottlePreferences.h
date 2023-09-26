//
//  MPCpuThrottlePreferences.h
//  MPCpuThrottle
//
//  Created by Vlad Alexa on 9/23/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MPCpuThrottlePreferences : NSViewController <NSTableViewDataSource,NSTableViewDelegate> {

	IBOutlet NSTableView	*appsTable;	    
    NSMutableArray *appsList; 
    NSMutableDictionary *throttles;    
	
}

-(void)saveSetting:(id)object forKey:(NSString*)key;

-(void)syncUI;

+ (NSArray*)getCarbonProcessList;

-(IBAction)changeSlider:(id)sender;

@end
