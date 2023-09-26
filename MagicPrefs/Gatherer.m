//
//  Gatherer.m
//  MagicPrefs
//
//  Created by Vlad Alexa on 4/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Gatherer.h"

#import "IORegInterface.h"

@implementation Gatherer

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        
        lastTouchedDev = nil;        
        mm_battery = 0;
        mt_battery = 0;        
        
        dataBase = [[NSMutableDictionary alloc] init];        
        //each run populate ivar with empty data
        NSDictionary *zeroDict = [NSDictionary dictionaryWithObjectsAndKeys:@"0",@"clicks",@"0",@"scrolls",@"0",@"cursors",@"0",@"touches", nil];   
        NSDictionary *emptyDict = [NSDictionary dictionaryWithObjectsAndKeys:zeroDict,@"perMinute",zeroDict,@"perHour",zeroDict,@"perDay",zeroDict,@"perBattery",@"0",@"batterySteps",@"0",@"batteryLevel",[NSDate date],@"batteryLastCharge", nil];        
        [dataBase setObject:emptyDict forKey:@"mm"];
        [dataBase setObject:emptyDict forKey:@"mt"]; 
        [dataBase setObject:emptyDict forKey:@"gt"];         
        
		defaults = [NSUserDefaults standardUserDefaults];          
        if ([defaults objectForKey:@"dataBase"] == nil) {
            //first run populate defaults with empty
            [defaults setObject:dataBase forKey:@"dataBase"];
            [defaults synchronize];
        }
        
		[NSTimer scheduledTimerWithTimeInterval:59 target:self selector:@selector(refreshBattery:) userInfo:nil repeats:YES];
        
		[NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(minuteChanged:) userInfo:nil repeats:YES]; 

		[NSTimer scheduledTimerWithTimeInterval:3600 target:self selector:@selector(hourChanged:) userInfo:nil repeats:YES];

		[NSTimer scheduledTimerWithTimeInterval:86400 target:self selector:@selector(dayChanged:) userInfo:nil repeats:YES]; 
        
		//bluetooth	notification		
		[IOBluetoothDevice registerForConnectNotifications:self selector:@selector(bluetoothDidConnect:device:)];        
        
        hidController = [[BluetoothHIDDeviceController alloc] initForAppleDevices];
        //TODO, does not seem to work so far
		//[hidController registerForBatteryStateChangeNotifications:self selector:@selector(bluetoothDidChangeBattery:device:)];     
        
    }
    
    return self;
}

- (void)dealloc
{
    [hidController unregisterForAllNotifications:self];
    [NSEvent removeMonitor:nseventMonitor];    
    [dataBase release];
    [hidController release];
    [displayImage release];
    [graphImage release];    
    [super dealloc];    
}

-(void)selfMonitor{
    if (nseventMonitor != nil) return; 
    nseventMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:(NSMouseMovedMask|NSLeftMouseDraggedMask|NSRightMouseDraggedMask|NSOtherMouseDraggedMask|NSScrollWheelMask) handler:^(NSEvent *theEvent) {
        NSEventType type = [theEvent type];
        if (type == NSMouseMoved || type == NSLeftMouseDragged || type == NSRightMouseDragged || type == NSOtherMouseDragged ) {
            //NSLog(@"Cursor moved: %@", NSStringFromPoint([theEvent locationInWindow]));
            [self addNew:@"cursors"];
        }
        if (type == NSScrollWheel ) {
            //NSLog(@"Scroll"));
            [self addNew:@"scrolls"];
        }        
    }];    
}

-(void)toggleSelfMonitoring{
    if ([defaults boolForKey:@"gatherStatistics"] == NO) {
        if (nseventMonitor != nil) [NSEvent removeMonitor:nseventMonitor];    
        return;
    }else{
        if (nseventMonitor == nil) [self selfMonitor];            
    }
}

-(void)refreshBattery:(id)sender{   
        
    //mm    
    if ([defaults boolForKey:@"noMouse"] == NO) {     
        int mm_battery_new = [[IORegInterface mm_getStringForProperty:@"BatteryPercent"] intValue]; 
        if (mm_battery == 0) {
            ////check if battery was charged while not being monitored
            int mm_battery_old = [[[[defaults objectForKey:@"dataBase"] objectForKey:@"mm"] objectForKey:@"batteryLevel"] intValue];  
            if (mm_battery_new > mm_battery_old && mm_battery_new > 0) {
                [self batteryCharging:@"mm" step:mm_battery_new-mm_battery_old level:mm_battery_new];
            }
            mm_battery = mm_battery_new;        
        }else if (mm_battery > 0){
            ////battery monitoring
            int mm_diff = mm_battery_new - mm_battery;  
            if (mm_diff != 0) {
                mm_battery = mm_battery_new;         
                if (mm_diff > 0) {
                    //charging
                    [self batteryCharging:@"mm" step:mm_diff level:mm_battery];            
                }else{
                    //draining 
                    [self batteryDraining:@"mm" step:mm_diff level:mm_battery];
                }               
            }        
        }  
        [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(checkBatteryPanic:) userInfo:@"mm" repeats:NO];
    }   
    
    //mt
    if ([defaults boolForKey:@"noTrackpad"] == NO) {    
        int mt_battery_new = [[IORegInterface mt_getStringForProperty:@"BatteryPercent"] intValue];    
        if (mt_battery == 0) {
            ////check if battery was charged while not being monitored        
            int mt_battery_old = [[[[defaults objectForKey:@"dataBase"] objectForKey:@"mt"] objectForKey:@"batteryLevel"] intValue]; 
            if (mt_battery_new > mt_battery_old && mt_battery_new > 0) {
                [self batteryCharging:@"mt" step:mt_battery_new-mt_battery_old level:mt_battery_new];               
            } 
            mt_battery = mt_battery_new;        
        }else if (mt_battery > 0){
            ////battery monitoring 
            int mt_diff = mt_battery_new - mt_battery;
            if (mt_diff != 0) {
                mt_battery = mt_battery_new;        
                if (mt_diff > 0) {
                    //charging
                    [self batteryCharging:@"mt" step:mt_diff level:mt_battery];             
                }else{
                    //draining        
                    [self batteryDraining:@"mt" step:mt_diff level:mt_battery];            
                }        
            }         
        } 
        [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(checkBatteryPanic:) userInfo:@"mt" repeats:NO];    
    }       
     
    //NSLog(@"mm:%i mt:%i",mm_battery,mt_battery); 
}

- (void)touch:(NSString*)type fingers:(int)fingers{
    if (type == nil) return; //sent before touch init
    //NSLog(@"Touched %@ with %i fingers",type,fingers);    
    lastTouchedDev = [NSString stringWithString:type];
    [self addNew:@"touches"];
}

- (void)click:(NSString*)type fingers:(int)fingers{         
    if (type == nil) return; //sent before touch init     
    //NSLog(@"Clicked %@ with %i fingers",type,fingers);
    lastTouchedDev = [NSString stringWithString:type];    
    [self addNew:@"clicks"];    
    //CAREFULL HERE, THIS RUNS INSIDE THE CGTAP CALLBACK
}

- (void)scroll:(NSString*)type fingers:(int)fingers{     
    if (type == nil) return; //sent before touch init 
    //NSLog(@"Scrolled %@ with %i fingers",type,fingers);
    lastTouchedDev = [NSString stringWithString:type];    
    [self addNew:@"scrolls"];    
    //CAREFULL HERE, THIS RUNS INSIDE THE CGTAP CALLBACK
}

- (void)cursor:(NSString*)type fingers:(int)fingers{ 
    if (type == nil) return; //sent before touch init 
    //NSLog(@"Moved %@ with %i fingers",type,fingers);
    lastTouchedDev = [NSString stringWithString:type];    
    [self addNew:@"cursors"];    
    //CAREFULL HERE, THIS RUNS INSIDE THE CGTAP CALLBACK
}

#pragma mark updates

-(void)batteryDraining:(NSString*)type step:(int)step level:(int)level{ 
    if (step == 0) return; //whoa there, we dont want this
    if (level == 0) return; //most likely no actual battery data could be found
    //add to batterySteps and set batteryLevel in plist
    NSMutableDictionary *d = [[defaults objectForKey:@"dataBase"] mutableCopy];
    NSMutableDictionary *t = [[d objectForKey:type] mutableCopy];  
    [t setObject:[NSString stringWithFormat:@"%i",[[t objectForKey:@"batterySteps"] intValue]+step] forKey:@"batterySteps"];
    [t setObject:[NSString stringWithFormat:@"%i",level] forKey:@"batteryLevel"];    
    [d setObject:t forKey:type];
    [t release];
    [defaults setObject:d forKey:@"dataBase"];        
    [d release];
    [defaults synchronize];     
    //notify
    [self checkBatteryLow:type];
    [self notifyBatteryDiff:type step:step level:level];    
}

-(void)batteryCharging:(NSString*)type step:(int)step level:(int)level{
    if (step == 0) return; //whoa there, we dont want this
    if (step == 1) return; //most likely false positive from rounding, not always an actual charge 
    //reset ivar and plist
    [self saveUpdateReset:@"perBattery" type:type]; 
    //reset batterySteps and set batteryLevel and batteryLastCharge in plist
    NSMutableDictionary *d = [[defaults objectForKey:@"dataBase"] mutableCopy];
    NSMutableDictionary *t = [[d objectForKey:type] mutableCopy];  
    [t setObject:[NSString stringWithFormat:@"%i",(100-level)*-1] forKey:@"batterySteps"];
    [t setObject:[NSString stringWithFormat:@"%i",level] forKey:@"batteryLevel"];
    [t setObject:[NSDate date] forKey:@"batteryLastCharge"];    
    [d setObject:t forKey:type];
    [t release];
    [defaults setObject:d forKey:@"dataBase"];        
    [d release];
    [defaults synchronize];     
    //notify
    double date = [[[[defaults objectForKey:@"dataBase"] objectForKey:type] objectForKey:@"batteryLastCharge"] timeIntervalSinceNow]*-1;
    if (date > 3600){
        [self notifyBatteryCharge:type]; //new charging cycle       
    }else{
        [self notifyBatteryDiff:type step:step level:level]; //minor charge change                   
    }    
}

-(void)minuteChanged:(id)sender{
    [self refreshGraph];
    //[self toggleSelfMonitoring]; not neeeded, we get events from main    
    if ([defaults boolForKey:@"noMouse"] == NO) {
        [self saveUpdateAdding:@"perBattery" type:@"mm"]; 
        [self saveUpdateReplacing:@"perMinute" type:@"mm"];
    }
    if ([defaults boolForKey:@"noTrackpad"] == NO) {
        [self saveUpdateAdding:@"perBattery" type:@"mt"];             
        [self saveUpdateReplacing:@"perMinute" type:@"mt"];          
    }   
    if ([defaults boolForKey:@"noGlassTrackpad"] == NO) {
        [self saveUpdateAdding:@"perBattery" type:@"gt"];             
        [self saveUpdateReplacing:@"perMinute" type:@"gt"];          
    }       
}

-(void)hourChanged:(id)sender{ 
    if ([defaults boolForKey:@"noMouse"] == NO) {
        [self saveUpdateReplacing:@"perHour" type:@"mm"];        
    }
    if ([defaults boolForKey:@"noTrackpad"] == NO) {
        [self saveUpdateReplacing:@"perHour" type:@"mt"];  
    }  
    if ([defaults boolForKey:@"noGlassTrackpad"] == NO) {
        [self saveUpdateReplacing:@"perHour" type:@"gt"];  
    }      
}

-(void)dayChanged:(id)sender{
    if ([defaults boolForKey:@"noMouse"] == NO) {
        [self saveUpdateReplacing:@"perDay" type:@"mm"];
    }
    if ([defaults boolForKey:@"noTrackpad"] == NO) {
        [self saveUpdateReplacing:@"perDay" type:@"mt"];     
    } 
    if ([defaults boolForKey:@"noGlassTrackpad"] == NO) {
        [self saveUpdateReplacing:@"perDay" type:@"gt"];     
    }    
}

#pragma mark tools

- (void)saveUpdateReplacing:(NSString*)what type:(NSString*)type{
    NSDictionary *dict = [[dataBase objectForKey:type] objectForKey:what];    
    int clicks = [[dict objectForKey:@"clicks"] intValue];
    int cursors = [[dict objectForKey:@"cursors"] intValue];
    int touches = [[dict objectForKey:@"touches"] intValue];
    int scrolls = [[dict objectForKey:@"scrolls"] intValue];    
    if (clicks > 0 || scrolls > 0 || cursors > 0 || touches > 0) {
        //NSLog(@"Statistics %@ for %@: %i clicks, %i scrolls, %i cursors, %i touches",type,what,clicks,scrolls,cursors,touches); 
        //save ivar to plist
        NSDictionary *db = [self editNestedDict:[defaults objectForKey:@"dataBase"] setObject:dict forKeyHierarchy:[NSArray arrayWithObjects:type,what,nil]];
        [defaults setObject:db forKey:@"dataBase"];        
        [defaults synchronize];              
        //reset ivar
        NSDictionary *zeroDict = [NSDictionary dictionaryWithObjectsAndKeys:@"0",@"clicks",@"0",@"scrolls",@"0",@"cursors",@"0",@"touches", nil];        
        NSMutableDictionary *m = [[dataBase objectForKey:type] mutableCopy];
        [m setObject:zeroDict forKey:what];
        [dataBase setObject:m forKey:type];
        [m release];
    }else{
        //one time save of zero values to prevent older ones sticking around
        NSDictionary *db = [[[defaults objectForKey:@"dataBase"] objectForKey:type] objectForKey:what]; 
        if ([[db objectForKey:@"touches"] intValue] != 0) {
            //reset db
            NSDictionary *zeroDict = [NSDictionary dictionaryWithObjectsAndKeys:@"0",@"clicks",@"0",@"scrolls",@"0",@"cursors",@"0",@"touches", nil];            
            NSDictionary *db = [self editNestedDict:[defaults objectForKey:@"dataBase"] setObject:zeroDict forKeyHierarchy:[NSArray arrayWithObjects:type,what,nil]];
            [defaults setObject:db forKey:@"dataBase"];        
            [defaults synchronize];
        }
    } 
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMenuEvent" object:@"RefreshBattery" userInfo:nil];//refresh menubar icon      
}

- (void)saveUpdateReset:(NSString*)what type:(NSString*)type{
    NSLog(@"Resetting %@ for %@",type,what);        
    //reset ivar
    NSDictionary *zeroDict = [NSDictionary dictionaryWithObjectsAndKeys:@"0",@"clicks",@"0",@"scrolls",@"0",@"cursors",@"0",@"touches", nil];        
    NSMutableDictionary *m = [[dataBase objectForKey:type] mutableCopy];
    [m setObject:zeroDict forKey:what];
    [dataBase setObject:m forKey:type];
    [m release];    
    //save ivar to plist
    NSDictionary *db = [self editNestedDict:[defaults objectForKey:@"dataBase"] setObject:[[dataBase objectForKey:type] objectForKey:what] forKeyHierarchy:[NSArray arrayWithObjects:type,what,nil]];
    [defaults setObject:db forKey:@"dataBase"];        
    [defaults synchronize];  
}

- (void)saveUpdateAdding:(NSString*)what type:(NSString*)type{
    NSMutableDictionary *dict = [[[dataBase objectForKey:type] objectForKey:what] mutableCopy];    
    int clicks = [[dict objectForKey:@"clicks"] intValue];
    int cursors = [[dict objectForKey:@"cursors"] intValue];
    int touches = [[dict objectForKey:@"touches"] intValue];
    int scrolls = [[dict objectForKey:@"scrolls"] intValue];    
    if (clicks > 0 || scrolls > 0 || cursors > 0 || touches > 0) {
        //NSLog(@"Adding statistics %@ for %@: %i clicks, %i scrolls, %i cursors, %i touches",type,what,clicks,scrolls,cursors,touches); 
        //addition of ivar values with the plist ones
        NSDictionary *plist = [[[defaults objectForKey:@"dataBase"] objectForKey:type] objectForKey:what];           
        int p_clicks = [[plist objectForKey:@"clicks"] intValue];
        int p_cursors = [[plist objectForKey:@"cursors"] intValue];
        int p_touches = [[plist objectForKey:@"touches"] intValue];
        int p_scrolls = [[plist objectForKey:@"scrolls"] intValue];      
        [dict setObject:[NSString stringWithFormat:@"%i",clicks+p_clicks] forKey:@"clicks"];
        [dict setObject:[NSString stringWithFormat:@"%i",cursors+p_cursors] forKey:@"cursors"];
        [dict setObject:[NSString stringWithFormat:@"%i",touches+p_touches] forKey:@"touches"];
        [dict setObject:[NSString stringWithFormat:@"%i",scrolls+p_scrolls] forKey:@"scrolls"];
        //save ivar to plist
        NSDictionary *db = [self editNestedDict:[defaults objectForKey:@"dataBase"] setObject:dict forKeyHierarchy:[NSArray arrayWithObjects:type,what,nil]];
        [defaults setObject:db forKey:@"dataBase"];        
        [defaults synchronize]; 
        //reset ivar
        NSDictionary *zeroDict = [NSDictionary dictionaryWithObjectsAndKeys:@"0",@"clicks",@"0",@"scrolls",@"0",@"cursors",@"0",@"touches", nil];        
        NSMutableDictionary *m = [[dataBase objectForKey:type] mutableCopy];
        [m setObject:zeroDict forKey:what];
        [dataBase setObject:m forKey:type];
        [m release];        
    }  
    [dict release];
}

- (void)addNew:(NSString*)kind{
    if (lastTouchedDev != nil){
        //NSLog(@"Adding to %@ %@",lastTouchedDev,kind);
        NSMutableDictionary *data = [[dataBase objectForKey:lastTouchedDev] mutableCopy];        
        if (data) {
            int minute = [[[data objectForKey:@"perMinute"] objectForKey:kind] intValue];
            int hour = [[[data objectForKey:@"perHour"] objectForKey:kind] intValue];
            int day = [[[data objectForKey:@"perDay"] objectForKey:kind] intValue];
            int battery = [[[data objectForKey:@"perBattery"] objectForKey:kind] intValue];    
            
            NSMutableDictionary *perMinute = [[data objectForKey:@"perMinute"] mutableCopy];
            NSMutableDictionary *perHour = [[data objectForKey:@"perHour"] mutableCopy];
            NSMutableDictionary *perDay = [[data objectForKey:@"perDay"] mutableCopy];
            NSMutableDictionary *perBattery = [[data objectForKey:@"perBattery"] mutableCopy]; 
            
            [perMinute setObject:[NSString stringWithFormat:@"%i",minute+1] forKey:kind];
            [perHour setObject:[NSString stringWithFormat:@"%i",hour+1] forKey:kind];
            [perDay setObject:[NSString stringWithFormat:@"%i",day+1] forKey:kind];
            [perBattery setObject:[NSString stringWithFormat:@"%i",battery+1] forKey:kind]; 
            
            [data setObject:perMinute forKey:@"perMinute"];
            [data setObject:perHour forKey:@"perHour"];
            [data setObject:perDay forKey:@"perDay"];
            [data setObject:perBattery forKey:@"perBattery"];    
            
            [perMinute release];
            [perHour release];
            [perDay release];
            [perBattery release];
            
            [dataBase setObject:data forKey:lastTouchedDev];
            [data release];            
        }
    }         
}

-(NSString*)humanizeTimeInterval:(double)time{
	int d = 0;
	int h = 0;
	int m = 0;
	NSString *ret = @"";
	
	if (time < 60) {
		return @"less than a minute";
	}
	if (time >= 86400) {
		d = floor(time / 60 / 60 / 24);		
		ret = [ret stringByAppendingFormat:@"%d day", d];
		if (d >= 2) ret = [ret stringByAppendingString:@"s"];
		ret = [ret stringByAppendingString:@", "];		
	} 
	if (time >= 3600 ) {
		h = floor((time-(d*86400)) / 60 / 60);
		ret = [ret stringByAppendingFormat:@"%d hour",h];
		if (h >= 2) ret = [ret stringByAppendingString:@"s"];			
		ret = [ret stringByAppendingString:@", "];		
	}
	if (time >= 60) {
		m = floor((time-(d*86400)-(h*3600)) / 60);
		ret = [ret stringByAppendingFormat:@"%d minute",m];		
		if (m >= 2) ret = [ret stringByAppendingString:@"s"];			
	} 
	return ret;
}

-(NSDictionary*)editNestedDict:(NSDictionary*)dict setObject:(id)object forKeyHierarchy:(NSArray*)hierarchy{
    if (dict == nil) return dict;
    if (![dict isKindOfClass:[NSDictionary class]]) return dict;    
    NSMutableDictionary *parent = [[dict mutableCopy] autorelease];
    
    //drill down mutating each dict along the way
    NSMutableArray *structure = [NSMutableArray arrayWithCapacity:1];    
    NSMutableDictionary *prev = parent;
    for (id key in hierarchy) {
        if (key != [hierarchy lastObject]) {
            prev = [[[prev objectForKey:key] mutableCopy] autorelease];                            
            if (![prev isKindOfClass:[NSDictionary class]]) return dict;              
            [structure addObject:prev];
            //NSLog(@"loading %@",key); 
        }else{
            //NSLog(@"changing %@",key);
        }
    }   
    
    //do the change
    [[structure lastObject] setObject:object forKey:[hierarchy lastObject]];    
    
    //drill back up saving the changes each step along the way   
    for (int c = [structure count]-1; c >= 0; c--) {
        if (c == 0) {
            [parent setObject:[structure objectAtIndex:c] forKey:[hierarchy objectAtIndex:c]];                                
        }else{
            [[structure objectAtIndex:c-1] setObject:[structure objectAtIndex:c] forKey:[hierarchy objectAtIndex:c]];                                
        }
        //NSLog(@"saving %@",[hierarchy objectAtIndex:c]);        
    }
    
    return parent;
}

#pragma mark battery checks and notices

-(void)checkBatteryLow:(NSString*)type{
    if ([defaults boolForKey:@"gatherStatistics"] == NO) return;    
    BOOL battery_low = NO;
    NSString *message = nil;
    if ([type isEqualToString:@"mm"]) {
        battery_low = [IORegInterface mm_getBoolForProperty:@"BatteryLow"];
        message = @"Magic Mouse batteries low";
    }
    if ([type isEqualToString:@"mt"]) {
        battery_low = [IORegInterface mt_getBoolForProperty:@"BatteryLow"];
        message = @"Magic Trackpad batteries low";
    }
    
    if (battery_low == YES) {
        double date = [[[[defaults objectForKey:@"dataBase"] objectForKey:type] objectForKey:@"batteryLastCharge"] timeIntervalSinceNow]*-1;   
        NSString *details = [NSString stringWithFormat:@"They will be depleted soon, last charge was %@ ago.",[self humanizeTimeInterval:date]];            
        NSLog(@"%@ battery low (%f) %@",type,date,details);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:
         [NSDictionary dictionaryWithObjectsAndKeys:@"doGrowl",@"what",message,@"title",details,@"message",nil]
         ];       
    }
}

-(void)checkBatteryPanic:(NSTimer*)timer{
    if ([defaults boolForKey:@"gatherStatistics"] == NO) return;    
    NSString *type = [timer userInfo];    
    BOOL battery_panic = NO;
    if ([type isEqualToString:@"mm"]) battery_panic = [IORegInterface mm_getBoolForProperty:@"BatteryPanic"];        
    if ([type isEqualToString:@"mt"]) battery_panic = [IORegInterface mt_getBoolForProperty:@"BatteryPanic"];            
    
    if (battery_panic == YES) {
        double date = [[[[defaults objectForKey:@"dataBase"] objectForKey:type] objectForKey:@"batteryLastCharge"] timeIntervalSinceNow]*-1;         
        NSLog(@"%@ battery panic (%f)",type,date);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMenuEvent" object:@"CritBattery" userInfo:nil];//crit menubar icon         
    }    
}

-(void)notifyBatteryDiff:(NSString*)type step:(int)step level:(int)level{ 
    if ([defaults boolForKey:@"gatherStatistics"] == NO) return;
    NSString *devName = @"";
    if ([type isEqualToString:@"mm"]) devName = @"Magic Mouse";
    if ([type isEqualToString:@"mt"]) devName = @"Magic Trackpad";    
    NSString *details = [NSString stringWithFormat:@"%@ battery changed from %i to %i",devName,level-step,level];    
    NSLog(@"%@",details);    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:
	 [NSDictionary dictionaryWithObjectsAndKeys:@"doGrowl",@"what",@"Battery change",@"title",details,@"message",nil]
	];
}

-(void)notifyBatteryCharge:(NSString*)type{ 
    if ([defaults boolForKey:@"gatherStatistics"] == NO) return;    
    NSDictionary *db = [[defaults objectForKey:@"dataBase"] objectForKey:type];
    double date = [[db objectForKey:@"batteryLastCharge"] timeIntervalSinceNow]*-1;    
    int clicks = [[[db objectForKey:@"perBattery"] objectForKey:@"clicks"] intValue];
    int cursors = [[[db objectForKey:@"perBattery"] objectForKey:@"cursors"] intValue];
    int touches = [[[db objectForKey:@"perBattery"] objectForKey:@"touches"] intValue];
    int scrolls = [[[db objectForKey:@"perBattery"] objectForKey:@"scrolls"] intValue];    
    NSString *details = [NSString stringWithFormat:@"%i clicks, %i scrolls, %i cursors, %i touches since the previous charge %@ ago.",clicks,scrolls,cursors,touches,[self humanizeTimeInterval:date]];    
    NSLog(@"%@",details);    

    [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:
     [NSDictionary dictionaryWithObjectsAndKeys:@"doAlert",@"what",
      @"Battery charged",@"title",
      details,@"text",
      @"OK",@"action",
      nil]
     ];	   
}

#pragma mark bluetooth

- (void)bluetoothDidChangeBattery:(IOBluetoothUserNotification *)aNotification device:(IOBluetoothDevice *)device {
    NSLog(@"%@ bchange",[device description]);
	if ([self isMagicMouse:device] == YES){	
        int mm_battery_new = [[IORegInterface mm_getStringForProperty:@"BatteryPercent"] intValue]; 
        AppleBluetoothHIDDevice *appleDevice = [BluetoothHIDDevice withBluetoothDevice:device];
		NSLog(@"Magic Mouse %@ battery change (%.2f %i)",[device nameOrAddress],[appleDevice batteryPercent],mm_battery_new);		
	}
	if ([self isMagicTrackpad:device] == YES){
        int mt_battery_new = [[IORegInterface mt_getStringForProperty:@"BatteryPercent"] intValue];  
        AppleBluetoothHIDDevice *appleDevice = [BluetoothHIDDevice withBluetoothDevice:device];        
		NSLog(@"Magic Trackpad %@ battery change (%.2f %i)",[device nameOrAddress],[appleDevice batteryPercent],mt_battery_new);		
	}	
}

- (void)bluetoothDidConnect:(IOBluetoothUserNotification *)aNotification device:(IOBluetoothDevice *)device {
    //force refresh when device is connected
    if ([self isMagicMouse:device] == YES || [self isMagicTrackpad:device] == YES){
		[NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(refreshBattery:) userInfo:nil repeats:NO];        
		[NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(minuteChanged:) userInfo:nil repeats:NO];        
    }         
}

- (BOOL)isMagicMouse:(IOBluetoothDevice *)device {
	if (![device getLastServicesUpdate]) {
		NSLog(@"No service update, can not determine device type");
		return NO;	
	}	
	BOOL magicmouse = NO;
	NSArray *services = [device services];
	NSUInteger idx = 0;
	for (idx = 0; idx < [services count] && !magicmouse; idx++) {
		IOBluetoothSDPServiceRecord *record = [services objectAtIndex:idx];
		NSDictionary *attrs = [record attributes];
		IOBluetoothSDPDataElement *vendor = [attrs objectForKey:[NSNumber numberWithLong:kBluetoothSDPAttributeDeviceIdentifierVendorID]];
		IOBluetoothSDPDataElement *product = [attrs objectForKey:[NSNumber numberWithLong:kBluetoothSDPAttributeDeviceIdentifierProductID]];
		if (vendor && product) {
			if ([vendor containsValue:[NSNumber numberWithLong:0x05AC]] && [product containsValue:[NSNumber numberWithLong:0x030D]]) {
				magicmouse = YES;
			}
		}
	}
	return magicmouse;
}

- (BOOL)isMagicTrackpad:(IOBluetoothDevice *)device {
	if (![device getLastServicesUpdate]) {
		NSLog(@"No service update, can not determine device type");
		return NO;	
	}	
	BOOL magictrackpad = NO;
	NSArray *services = [device services];
	NSUInteger idx = 0;
	for (idx = 0; idx < [services count] && !magictrackpad; idx++) {
		IOBluetoothSDPServiceRecord *record = [services objectAtIndex:idx];
		NSDictionary *attrs = [record attributes];
		IOBluetoothSDPDataElement *vendor = [attrs objectForKey:[NSNumber numberWithLong:kBluetoothSDPAttributeDeviceIdentifierVendorID]];
		IOBluetoothSDPDataElement *product = [attrs objectForKey:[NSNumber numberWithLong:kBluetoothSDPAttributeDeviceIdentifierProductID]];
		if (vendor && product) {
			if ([vendor containsValue:[NSNumber numberWithLong:0x05AC]] && [product containsValue:[NSNumber numberWithLong:0x030E]]) {
				magictrackpad = YES;
			}
		}
	}
	return magictrackpad;
}

#pragma mark graphs

- (void)refreshGraph{
    if ([defaults boolForKey:@"graphicalStatistics"] == NO) return;     
    if ([defaults boolForKey:@"gatherStatistics"] == NO) return; 
    if ([[defaults objectForKey:@"menubarIcon"] isEqualToString:@"default"]) return;
    
    if (displayImage == nil) displayImage = [[NSImage alloc] initWithSize:NSMakeSize(128, 128)];
    if (graphImage == nil) graphImage = [[NSImage alloc] initWithSize:NSMakeSize(128, 128)];       
    
    NSString *type = [defaults objectForKey:@"menubarIcon"];
    if (type == nil || [type isEqualToString:@"default"]) return;    
	[self drawIcon:type];    
    
    NSString *path = [NSString stringWithFormat:@"%@MagicPrefs_StatsGraph.png",NSTemporaryDirectory()];
	NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:[graphImage TIFFRepresentation]];		
	NSData *imgdata = [rep representationUsingType:NSPNGFileType properties:nil];    
	[imgdata writeToFile:path atomically:YES];   
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"showDockImage",@"what",path,@"path",nil]];    
}

- (void)drawIcon:(NSString*)type
{
    
	float			width = 128.0;
	float			ybottom = 0.0;
	float           barWidth = 6.0;
    float           middle = width/2;
    
    NSDictionary *dict = [[dataBase objectForKey:type] objectForKey:@"perMinute"];    
    float clicks = [[dict objectForKey:@"clicks"] floatValue];
    float scrolls = [[dict objectForKey:@"scrolls"] floatValue]/2;     
    float cursors = [[dict objectForKey:@"cursors"] floatValue]/4;
    float touches = [[dict objectForKey:@"touches"] floatValue]/10;
    
    if (touches > 110) touches = 110;
    if (cursors > 80) cursors = 80;
    if (scrolls > 60) scrolls = 60;
    if (clicks > 40) clicks = 40;    
	
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];    
    
	[graphImage lockFocus];
    
	// offset the old graph image
	[graphImage compositeToPoint:NSMakePoint(-barWidth, 0) operation:NSCompositeCopy];
            
    //clear previous
    [[NSColor clearColor] set];
    NSRectFill (NSMakeRect(width - barWidth, ybottom, barWidth, width));    
    
    // draw chronological graph into graph image		
    int count = 4;    
    NSRectArray myRects = calloc(count, sizeof(NSRect));
    const NSColor **myColors = calloc(count, sizeof(NSColor*));
  
    myColors[3] = [NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:0.7];
    myRects[3] = NSMakeRect(width - barWidth, middle-(clicks/2), barWidth, clicks);
    
    myColors[2] = [NSColor colorWithCalibratedRed:1 green:1 blue:0 alpha:0.8];
    myRects[2] = NSMakeRect(width - barWidth, middle-(scrolls/2), barWidth, scrolls);
    
    myColors[1] = [NSColor colorWithCalibratedRed:0 green:1 blue:0 alpha:0.9];
    myRects[1] = NSMakeRect(width - barWidth, middle-(cursors/2), barWidth, cursors);
    
    myColors[0] = [NSColor colorWithCalibratedRed:0 green:0 blue:1 alpha:1.0];
    myRects[0] = NSMakeRect(width - barWidth, middle-(touches/2), barWidth, touches);
    
    NSRectFillListWithColorsUsingOperation(myRects, myColors , count, NSCompositeSourceOver);
    
	free(myColors); 
    free(myRects);
    
	// transfer graph image to icon image
	[graphImage unlockFocus];
	[displayImage lockFocus];
	[graphImage compositeToPoint:NSMakePoint(0.0, 0.0) operation:NSCompositeCopy];    
	[displayImage unlockFocus];
}

@end
