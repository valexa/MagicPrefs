//
//  DiskFailurePreferences.m
//  DiskFailure
//
//  Created by Vlad Alexa on 9/23/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "DiskFailurePreferences.h"

//this runs under the standalone or System Preferences, standardUserDefaults must be give a domain

#if PLUGIN //set in project's GCC_PREPROCESSOR_DEFINITIONS
    #define OBSERVER_NAME_STRING @"MPPluginDiskFailurePreferencesEvent"
    #define MAIN_OBSERVER_NAME_STRING @"MPPluginDiskFailureEvent"
    #define TABLE_HEIGHT 240
    #define TABLE_WIDTH 340
#else
    #define OBSERVER_NAME_STRING @"VADiskFailurePreferencesEvent"
    #define MAIN_OBSERVER_NAME_STRING @"VADiskFailureEvent"
    #define TABLE_HEIGHT 154
    #define TABLE_WIDTH 639
#endif

#define PLUGIN_NAME_STRING @"DiskFailure"


@implementation DiskFailurePreferences

@synthesize sharedDataPath;

- (id)init
{
    self = [super init];
    if (self) {
        //this is for when the standalone loads it in code
        theList = [[NSMutableArray alloc] init];        
        sharedDataPath = [[NSMutableString alloc] init];
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    //this is for when system prefs loads it without going trough init
    if(theList == nil) theList = [[NSMutableArray alloc] init];        
    if(sharedDataPath == nil) sharedDataPath = [[NSMutableString alloc] init];    
		
    [theTable setRowHeight:32]; 
        
    NSView *scroll = [[theTable superview] superview]; 
    [scroll setFrame:NSMakeRect(0,0,TABLE_WIDTH,TABLE_HEIGHT)];
    
    if ([sharedDataPath length] == 0) {
        //we are running as plugin or on 10.6, use hardcoded path
        [sharedDataPath setString:[NSString stringWithFormat:@"/Users/%@/Library/Containers/com.vladalexa.diskfailure/Data/Documents/sharedData.plist",NSUserName()]];     
    }
    
    //register for notifications
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:OBSERVER_NAME_STRING object:nil];    

    [self getData]; 

}

-(void)dealloc{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];  
    [sharedDataPath release];    
    [theList release];
    [super dealloc];    
}

-(NSDictionary*)sharedDefaults
{
    NSDictionary *ret = [NSDictionary dictionaryWithContentsOfFile:sharedDataPath];
    if (ret == nil) NSLog(@"prefs sharedDefaults not available at %@",sharedDataPath);     
    return ret;    
}

-(void)theEvent:(NSNotification*)notif{		
	if (![[notif name] isEqualToString:OBSERVER_NAME_STRING]) {
		return;
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){
		if ([[notif object] isEqualToString:@"doRefresh"]){
            [self getData];
            [theTable reloadData]; 
		}
		if ([[notif object] isEqualToString:@"switchToAll"]){
            allMachines = YES;
            [self getData];
            [theTable reloadData]; 
		}        
		if ([[notif object] isEqualToString:@"switchToThis"]){
            allMachines = NO;            
            [self getData];
            [theTable reloadData]; 
		}                
	}	
}

-(void)getData{
    [theList removeAllObjects];
    NSDictionary *disks = [[self sharedDefaults] objectForKey:@"disks"];
    for (NSString *serial in disks) {
        NSDictionary *dict = [disks objectForKey:serial];
        if (![[dict objectForKey:@"machine"] isEqualToString:[self machineSerial]]) {
            if (allMachines == NO) continue;
        }
        NSString *name = [dict objectForKey:@"name"];
        NSString *read = [dict objectForKey:@"read"];
        NSString *write = [dict objectForKey:@"write"];
        NSString *lifeRead = [dict objectForKey:@"lifeRead"];
        NSString *lifeWrite = [dict objectForKey:@"lifeWrite"];        
        NSDate *date = [dict objectForKey:@"lastCheck"]; 
        int readOperations = [[dict objectForKey:@"readOperations"] intValue];
        int readLatency = [[dict objectForKey:@"readLatency"] intValue]; 
        int writeLatency = [[dict objectForKey:@"writeLatency"] intValue];        
        NSImage *icon = nil;
        if ([[dict objectForKey:@"failing"] boolValue] == YES || [[dict objectForKey:@"lifeRead"] intValue] > 0 || [[dict objectForKey:@"lifeWrite"] intValue] > 0 ) {
                icon = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"failing.pdf"]] autorelease];            
        }else if ( readOperations == 0 || readLatency != 0 || writeLatency != 0 ) {
            icon = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"unsure.pdf"]] autorelease];                
        }else{    
            icon = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"ok.pdf"]] autorelease];
        } 
        [theList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                            name,@"name",icon,@"icon",
                            read,@"read",write,@"write",
                            lifeRead,@"lifeRead",lifeWrite,@"lifeWrite",
                            [self humanizeDate:date],@"date",
                            [NSString stringWithFormat:@"%i",readLatency+writeLatency],@"latency",                            
                            [NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"interface"],[dict objectForKey:@"type"]],@"interface",                            
                            [dict objectForKey:@"sleeping"],@"sleeping",
                            [dict objectForKey:@"connected"],@"connected",                            
                            [dict objectForKey:@"failing"],@"failing",                            
                            nil]];
    }   

}

-(NSString *)machineSerial
{
	NSString *ret = nil;
	io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,IOServiceMatching("IOPlatformExpertDevice"));			
	if (platformExpert) {
		CFTypeRef cfstring = IORegistryEntryCreateCFProperty(platformExpert,CFSTR(kIOPlatformSerialNumberKey),kCFAllocatorDefault, 0);
        if (cfstring) {
            ret = [NSString stringWithFormat:@"%@",cfstring];        
            CFRelease(cfstring);                    
        }
		IOObjectRelease(platformExpert);        
	}		
    return ret;  
}


#pragma mark NSTableView datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView {
    return [theList count];	
}

- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)theColumn row:(NSInteger)rowIndex {
    NSDictionary *dict = [theList objectAtIndex:rowIndex];  
	NSString *ident = [theColumn identifier]; 
    id ret = [dict objectForKey:ident];
    
    if ([ret isKindOfClass:[NSString class]]){
        NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithCapacity:1];                
        
        //make bold if not sleeping    
        if ([[dict objectForKey:@"sleeping"] boolValue] == NO) {
            [attrsDictionary setObject:[NSFont boldSystemFontOfSize:12.0] forKey:NSFontAttributeName];                     
        }
        
        //make red if failing
        if ([[dict objectForKey:@"failing"] boolValue] == YES  || [[dict objectForKey:@"lifeRead"] intValue] > 0 || [[dict objectForKey:@"lifeWrite"] intValue] > 0 ) {
            [attrsDictionary setObject:[NSColor colorWithDeviceRed:0.7 green:0.0 blue:0.0 alpha:1.0] forKey:NSForegroundColorAttributeName];                     
        }
        
        //make gray if disconnected
        if ([[dict objectForKey:@"connected"] boolValue] == NO) {
            [attrsDictionary setObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
        }
                
        ret = [[[NSAttributedString alloc] initWithString:ret attributes:attrsDictionary] autorelease];       
    }  
        
    return ret;
}

#pragma mark tools

-(NSString*)humanizeCount:(NSString*)count{
    int c = [count intValue];
    if (c > 1000){
        count = [NSString stringWithFormat:@"%ik",c/1000];
    }
    if (c > 1000000){
        count = [NSString stringWithFormat:@"%.1fm",c/1000000.0];
    }        
    if (c > 1000000000){
        count = [NSString stringWithFormat:@"%.1fb",c/1000000000.0];
    }        
    return count;
}

-(NSString*)humanizeDate:(NSDate*)date{
    return [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];
}

@end

@implementation NSColor (StringOverrides)

+(NSArray *)controlAlternatingRowBackgroundColors{
	return [NSArray arrayWithObjects:[NSColor colorWithCalibratedWhite:0.95 alpha:1.0],[NSColor whiteColor],nil];
}

@end
