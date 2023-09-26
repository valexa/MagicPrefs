//
//  DiskFailureMainCore.m
//  DiskFailure
//
//  Created by Vlad Alexa on 4/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DiskFailureMainCore.h"

#include <IOKit/storage/IOStorage.h>
#include <IOKit/storage/IOStorageDeviceCharacteristics.h>
#include <IOKit/firewire/IOFireWireLib.h>
#include <IOKit/usb/IOUSBLib.h>
#include <asl.h>

#import "CloudController.h"
#import "VASandboxFileAccess.h"

//this runs under the plugins host, no changes to prefs saving code required assuming structure is same

#if PLUGIN //set in project's GCC_PREPROCESSOR_DEFINITIONS
    #define PREF_OBSERVER_NAME_STRING @"MPPluginDiskFailurePreferencesEvent"
#else
    #define PREF_OBSERVER_NAME_STRING @"VADiskFailurePreferencesEvent"
#endif

#define MENUBAR_OBSERVER_NAME_STRING @"VADiskFailureMenuBarEvent"
#define APP_OBSERVER_NAME_STRING @"VADiskFailureEvent"
#define PLUGIN_NAME_STRING @"DiskFailure"

@implementation DiskFailureMainCore

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.      
        
		//init defaults
		defaults = [NSUserDefaults standardUserDefaults];
		        
		//set first run value settings
        NSString *frequency;
        frequency = [[[defaults dictionaryForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"checkFrequency"];        
		if (frequency == nil){
            frequency = @"150";            
			[self saveSetting:frequency forKey:@"checkFrequency"];
        }
        
        //check it is not too high or low
        if ([frequency intValue] < 100 || [frequency intValue] > 600){            
            NSLog(@"%@ frequency too high or too low, resetting to 150",frequency);
            frequency = @"150"; 
			[self saveSetting:frequency forKey:@"checkFrequency"];
        }    
        
        //migrate old settings
        migrationCache = nil;        
        NSArray *old = [[[defaults dictionaryForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"disks"];           
        if (old != nil) {
            migrationCache = [[NSMutableArray alloc] initWithArray:old];
            NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithDictionary:[[defaults dictionaryForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"]];
            [settings removeObjectForKey:@"disks"];
            [defaults setObject:[NSDictionary dictionaryWithObject:settings forKey:@"settings"] forKey:PLUGIN_NAME_STRING];
            [defaults synchronize];
        }     
        
        sharedDataPath = [[NSMutableString alloc] init];
        [sharedDataPath setString:[NSString stringWithFormat:@"/Users/%@/Library/Containers/com.vladalexa.diskfailure/Data/Documents/sharedData.plist",NSUserName()]];        
                
        //schedule run
        [NSTimer scheduledTimerWithTimeInterval:[frequency intValue] target:self selector:@selector(timerLoop:) userInfo:nil repeats:YES];         

    }
    
    return self;
}

-(void)awakeFromNib //only fires in standalone app that instantiates maincore in a nib
{
    if ([cloudController isiCloudAvailable]){
        //use icloud
        if (cloudController) [sharedDataPath setString:[[cloudController getiCloudURLFor:@"sharedData.plist" containerID:nil] path]];         
        if (cloudController == nil) {
            NSLog(@"Error getting cloudController");
            return;            
        }
        if (sharedDataPath == nil) {
            NSLog(@"Error getting sharedData iCloud path");
            return;            
        }        
    }    
}

- (void)dealloc
{    
    [migrationCache release];
    [sharedDataPath release];
    [super dealloc];    
}

-(void)timerLoop:(id)sender{        
     [[NSNotificationCenter defaultCenter] postNotificationName:APP_OBSERVER_NAME_STRING object:nil userInfo:
     [NSDictionary dictionaryWithObjectsAndKeys:@"showModal",@"what",@"Refreshing, please wait.",@"text", nil]
     ];     
    [self doCheck:nil];         
     [[NSNotificationCenter defaultCenter] postNotificationName:APP_OBSERVER_NAME_STRING object:@"dismissModal" userInfo:nil];    
}

#pragma mark core

-(NSDictionary*)sharedDefaults
{
    NSDictionary *ret = [NSDictionary dictionaryWithContentsOfFile:sharedDataPath];
    if (ret == nil) NSLog(@"prefs sharedDefaults not available at %@",sharedDataPath);    
    return ret;    
}

-(void)saveData:(id)data forKey:(NSString*)key
{
    if (data != nil && key != nil){
        NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithDictionary:[self sharedDefaults]];   
        [plist setObject:data forKey:key];
        NSURL *url = [NSURL fileURLWithPath:sharedDataPath];
        NSURL *dir = [url URLByDeletingLastPathComponent];    
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:[dir path]]) [fm createDirectoryAtPath:[dir path] withIntermediateDirectories:YES attributes:nil error:nil];
        [plist writeToURL:url atomically:YES];         
    }
}

-(void)saveSetting:(id)object forKey:(NSString*)key{   
    //this is the method for when the host application is not SytemPreferences (MagicPrefsPlugins or your standalone)    
	if (![[object class] isKindOfClass:[NSObject class]]) {
		NSLog(@"The value to be set for %@ is not a object",key); 
		return;
	}       
    NSDictionary *prefs = [defaults dictionaryForKey:PLUGIN_NAME_STRING];
    if (prefs == nil) prefs = [NSDictionary dictionary];
    if ([prefs objectForKey:@"settings"] == nil) {
        NSMutableDictionary *d = [[prefs  mutableCopy] autorelease];
        [d setObject:[[[NSDictionary alloc] init] autorelease] forKey:@"settings"];
        prefs = d;
    }
    NSDictionary *db = [self editNestedDict:prefs setObject:object forKeyHierarchy:[NSArray arrayWithObjects:@"settings",key,nil]];
    [defaults setObject:db forKey:PLUGIN_NAME_STRING];        
    [defaults synchronize];
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

-(NSDictionary*)mergePrefs:(NSDictionary*)newDisks
{    
    NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithDictionary:newDisks];
    
    NSDictionary *old = [[self sharedDefaults] objectForKey:@"disks"];    
    for (NSString *old_serial in old) {
        BOOL matched = NO;     
        for (NSString *new_serial in newDisks) {           
            if ([old_serial isEqualToString:new_serial]) {
                matched = YES;                
            }
        } 
        if (matched == NO) {
            NSMutableDictionary *mutable = [NSMutableDictionary dictionaryWithDictionary:[old objectForKey:old_serial]];
            //set value of connected to NO for drives on this machine
            if ([[self machineSerial] isEqualToString:[mutable objectForKey:@"machine"]]) {
                [mutable setObject:[NSNumber numberWithBool:NO] forKey:@"connected"];
            }
            [ret setObject:mutable forKey:old_serial];
        }
    } 
    
    return ret;    
} 

-(NSDictionary*)processData:(NSDictionary*)dict{  
    
    NSString *name = nil;
    if ([[dict objectForKey:@"Physical Interconnect Location"] isEqualToString:@"External"]) {
        name = [NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"Vendor Name"],[dict objectForKey:@"Product Name"]];       
    }else{
        name = [dict objectForKey:@"Product Name"];
    }
    
    if (name == nil) {
        NSLog(@"Failed to determine name from %@",dict);
        return nil;
    }else{
        name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        //NSLog(@"Found %@",name);
    }
    
    NSString *serial = [[dict objectForKey:@"Serial Number"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]; 
    if (serial == nil) serial = [dict objectForKey:@"USB Serial Number"];    
    if (serial == nil) serial = [[dict objectForKey:@"GUID"] stringValue];
    if (serial == nil) {
        NSLog(@"Error getting ID for %@, skipping.",name);
        return nil;        
    }
    
    if (![[dict objectForKey:@"Physical Interconnect"] isEqualToString:[dict objectForKey:@"interface"]]) {
        NSLog(@"Type inconsistency: %@ vs %@ for %@",[dict objectForKey:@"Physical Interconnect"],[dict objectForKey:@"interface"],name);
    }    
    
    NSString *type = @"";
    if ([[dict objectForKey:@"Medium Type"] isEqualToString:@"Rotational"]) {
        type = @"HDD";
    }
    if ([[dict objectForKey:@"Medium Type"] isEqualToString:@"Solid State"]) {
        type = @"SSD";
    }

    NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithCapacity:1]; 
                
    [newDict setObject:[NSNumber numberWithBool:YES] forKey:@"connected"];
    [newDict setObject:[NSDate date] forKey:@"lastCheck"];
    [newDict setObject:name forKey:@"name"];
    [newDict setObject:[dict objectForKey:@"bsd"] forKey:@"bsd"];
    [newDict setObject:[dict objectForKey:@"interface"] forKey:@"interface"];
    [newDict setObject:type forKey:@"type"];
    [newDict setObject:serial forKey:@"serial"];  
    [newDict setObject:[self machineSerial] forKey:@"machine"];
            
    [newDict setObject:[[dict objectForKey:@"Operations (Read)"] stringValue] forKey:@"readOperations"];    
    [newDict setObject:[[dict objectForKey:@"Operations (Write)"] stringValue] forKey:@"writeOperations"];  
    [newDict setObject:[[dict objectForKey:@"Latency Time (Read)"] stringValue] forKey:@"readLatency"];    
    [newDict setObject:[[dict objectForKey:@"Latency Time (Write)"] stringValue] forKey:@"writeLatency"];   
    
    [newDict setObject:[[dict objectForKey:@"Errors (Read)"] stringValue] forKey:@"read"];    
    [newDict setObject:[[dict objectForKey:@"Errors (Write)"] stringValue] forKey:@"write"];                 
    NSDictionary *cache = [self cacheForDisk:newDict];    
    int lifeRead = [[dict objectForKey:@"Errors (Read)"] intValue] + [[cache objectForKey:@"lifeRead"] intValue];
    int lifeWrite = [[dict objectForKey:@"Errors (Write)"] intValue] + [[cache objectForKey:@"lifeWrite"] intValue];           
    [newDict setObject:[NSString stringWithFormat:@"%i",lifeRead] forKey:@"lifeRead"];    
    [newDict setObject:[NSString stringWithFormat:@"%i",lifeWrite] forKey:@"lifeWrite"];     
    
    uint64_t diff = [[dict objectForKey:@"TimeSinceDeviceIdle"] intValue] / 1000ULL;    
    NSDate *lastIdle = [NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)diff*-1];
    if (lastIdle)  [newDict setObject:lastIdle forKey:@"lastIdle"];
    [newDict setObject:[dict objectForKey:@"sleeping"] forKey:@"sleeping"];
    [newDict setObject:[NSString stringWithFormat:@"%lld",[[dict objectForKey:@"IdleTimerPeriod"] intValue] / 1000ULL] forKey:@"sleepTimer"];    
    
    BOOL failing = [self doNotifications:newDict]; //notify before saving the new data
    [newDict setObject:[NSNumber numberWithBool:failing] forKey:@"failing"];
    return newDict;
    
}

-(NSDictionary*)cacheForDisk:(NSDictionary*)disk
{
    NSDictionary *ret = nil;
    if (migrationCache != nil) {
        for (NSDictionary *cached in migrationCache) {
            NSString *n = [cached objectForKey:@"name"];
            NSString *b = [cached objectForKey:@"bsd"]; 
            NSString *n_ = [disk objectForKey:@"name"];
            NSString *b_ = [disk objectForKey:@"bsd"];             
            if ([n isEqualToString:n_] && [b isEqualToString:b_]) {
                ret = cached;
            }
        }        
    }
    
    if (ret == nil) {
        NSString *serial = [disk objectForKey:@"serial"];
        ret = [[[self sharedDefaults] objectForKey:@"disks"] objectForKey:serial];        
    }else {
        [migrationCache removeObject:ret];
        NSLog(@"removed cached %@",[ret objectForKey:@"name"]);
    }
    
    return ret;
}

-(NSString*)naIfNil:(id)object{
    if (object == nil) {        
        return @"N/A";
    }else{
        return [NSString stringWithFormat:@"%@",object];
    }        
    return @"ERR";
}

#pragma mark logs

-(void)parseSyslog:(NSString*)query
{
    NSString *machineSerial = [self machineSerial];
    NSDictionary *plist = [self sharedDefaults];
    NSMutableDictionary *logs = [NSMutableDictionary dictionaryWithDictionary:[plist objectForKey:@"logs"]];
    NSMutableArray *mylogs = [NSMutableArray arrayWithArray:[logs objectForKey:machineSerial]];    
    
    aslmsg q, m;
    int i;
    const char *key, *val;    
    q = asl_new(ASL_TYPE_QUERY);    
    asl_set_query(q, ASL_KEY_SENDER, [query UTF8String], ASL_QUERY_OP_EQUAL);
    aslresponse r = asl_search(NULL, q);
    while (NULL != (m = aslresponse_next(r)))
    {
        NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];               
        for (i = 0; (NULL != (key = asl_key(m, i))); i++)        
        {
            NSString *keyString = [NSString stringWithUTF8String:(char *)key];            
            val = asl_get(m, key);            
            NSString *value = [NSString stringWithUTF8String:val];
            [tmpDict setObject:value forKey:keyString];            
        }
        NSString *message = [tmpDict objectForKey:@"Message"];     
        if (message) 
        {
            if ([message rangeOfString:@"operation was aborted"].location != NSNotFound || [message rangeOfString:@"jnl"].location != NSNotFound || [message rangeOfString:@"I/O error"].location != NSNotFound || [message rangeOfString:@"DMA failure"].location != NSNotFound) 
            {
                NSDate *time = [NSDate dateWithTimeIntervalSince1970:[[tmpDict objectForKey:@"Time"] intValue]];
                NSString *timeString = [NSDateFormatter localizedStringFromDate:time dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];
                NSString *newLogLine = [NSString stringWithFormat:@"%@ %@ %@",timeString,[tmpDict objectForKey:@"Host"],message];
                if (![mylogs containsObject:newLogLine]) 
                {
                    NSString *title = @"";
                    NSArray *split = [message componentsSeparatedByString:@":"];
                    if ([split count] > 0) {
                        title = [split objectAtIndex:0];
                        message = [message stringByReplacingOccurrencesOfString:title withString:@""];
                    }
                    [self sendGrowlNotification:message title:title];
                    [mylogs addObject:newLogLine];                    
                }
            } 
        }
    }
    aslresponse_free(r);  
    
    [logs setObject:mylogs forKey:machineSerial];
    [self saveData:logs forKey:@"logs"];
}

/*
-(NSString*)readLineAsNSString:(FILE *)file
{
    char buffer[4096];
    
    // tune this capacity to your liking -- larger buffer sizes will be faster, but
    // use more memory
    NSMutableString *result = [NSMutableString stringWithCapacity:256];
    
    // Read up to 4095 non-newline characters, then read and discard the newline
    int charsRead;
    do {
        if(fscanf(file, "%4095[^\n]%n%*c", buffer, &charsRead) == 1){
            [result appendFormat:@"%s", buffer];
        }else{
            break;
        }        
    } while(charsRead == 4095);
    
    return result;
}

-(void)parseLogs:(NSURL*)url
{    
    NSString *machineSerial = [self machineSerial];
    NSDictionary *plist = [self sharedDefaults];
    NSMutableDictionary *logs = [NSMutableDictionary dictionaryWithDictionary:[plist objectForKey:@"logs"]];
    NSMutableArray *mylogs = [NSMutableArray arrayWithArray:[logs objectForKey:machineSerial]];
    
    FILE *file = fopen([[url path] UTF8String], "r");
    if (file != NULL) {
        while(!feof(file)){
            NSString *line = [self readLineAsNSString:file];
            if ([line rangeOfString:@"operation was aborted"].location != NSNotFound || [line rangeOfString:@"jnl"].location != NSNotFound || [line rangeOfString:@"I/O error"].location != NSNotFound || [line rangeOfString:@"DMA failure"].location != NSNotFound) {
                if (![mylogs containsObject:line]) {
                    [mylogs addObject:line];
                    NSArray *split = [line componentsSeparatedByString:@"kernel[0]: "];
                    [self sendGrowlNotification:[split lastObject] title:[split objectAtIndex:0]];                    
                }
            }            
        }
        fclose(file);        
    }else {
        NSLog(@"ERROR opening %@",[url path]);
    }

    [logs setObject:mylogs forKey:machineSerial];
    [self saveData:logs forKey:@"logs"];
}    
*/

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

#pragma mark IO

-(void)doCheck:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MENUBAR_OBSERVER_NAME_STRING object:@"progressIcon" userInfo:nil];
    
    NSString *notice = @"The log will not be available without permissions to it.";
    NSURL *secScopedUrl = [VASandboxFileAccess sandboxFileHandle:@"/private/var/log/asl" forced:NO denyNotice:notice];    
    [VASandboxFileAccess startAccessingSecurityScopedResource:secScopedUrl]; 
    [self parseSyslog:@"kernel"];  
    [VASandboxFileAccess stopAccessingSecurityScopedResource:secScopedUrl];     
    
    [self saveSetting:[NSNumber numberWithBool:NO] forKey:@"redIcon"]; //set regular icon 
    [self saveSetting:[NSNumber numberWithBool:NO] forKey:@"litIcon"]; //set regular icon     
    
    NSMutableDictionary *newDevices = [NSMutableDictionary dictionaryWithCapacity:1];
        
	io_service_t root = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleACPIPlatformExpert"));    
    if (root) {
        io_iterator_t  iter;        
        // Create an iterator across all children of the root service object passed in.
        IORegistryEntryCreateIterator(root,kIOServicePlane,kIORegistryIterateRecursively,&iter);           
        if (iter){
            io_service_t service;            
            while ( ( service = IOIteratorNext( iter ) ) )  {
                if (service) {                                     
                    if ( IOObjectConformsTo( service, "IOBlockStorageDriver") ) {                                                
                        NSDictionary *dict = [self parseIOBlockStorageDriver:service];
                        if (dict != nil) {
                           NSDictionary *data = [self processData:dict];
                            if (data != nil) {
                                [newDevices setObject:data forKey:[data objectForKey:@"serial"]];
                            }                                                    
                        }
                    }                    
                    IOObjectRelease(service);                        
                }                
            }
            IOObjectRelease(iter);            
        }else{
            NSLog(@"Error iterating AppleACPIPlatformExpert");        
        }  
        IOObjectRelease(root);        
    }else{
        NSLog(@"No AppleACPIPlatformExpert found");      
    }          
    
    //merge with non connected disks and save
    NSDictionary *plist = [self sharedDefaults];    
    NSMutableDictionary *disks = [NSMutableDictionary dictionaryWithDictionary:[plist objectForKey:@"disks"]];    
    [disks addEntriesFromDictionary:[self mergePrefs:newDevices]];
	[self saveData:disks forKey:@"disks"];   
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:PREF_OBSERVER_NAME_STRING object:@"doRefresh"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LogsController" object:@"doRefresh"];    
}

-(NSDictionary*) parseIOBlockStorageDriver:(io_service_t)service{
    
    NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithCapacity:1];
    //get details from itself
    NSDictionary *statistics = [self getDictForProperty:@"Statistics" device:service]; 
    [ret addEntriesFromDictionary:statistics];
    NSString *serial = [self drillUpToUSBSerial:service];
    if (serial)[ret setObject:serial forKey:@"USB Serial Number"];     
    //get details from it's child
    io_service_t child;
    IORegistryEntryGetChildEntry(service,kIOServicePlane,&child);
    if (child) {
        NSString *bsd = [self getStringForProperty:@"BSD Name" device:child];
        if (bsd == nil) {
            IOObjectRelease(child);
            //NSLog(@"Device skiped, no bsd mount point");
            return nil; //no bsd mount point = no media = card reader or something
        }                       
        IOObjectRelease(child);
        [ret setObject:bsd forKey:@"bsd"];
    }else{
        //NSLog(@"Device skiped, no children");        
        return nil; //no child
    }                        
    //get details from it's parent                        
    io_service_t parent;
    IORegistryEntryGetParentEntry(service,kIOServicePlane,&parent);
    if (parent) {
        NSString *interface = [self interfaceType:parent];
        if (interface == nil) {
            IOObjectRelease(parent);
            //NSLog(@"Device skiped, not a known disk");             
            return nil; //not a known disk
        }
        NSDictionary *pcharacteristics = [self getDictForProperty:@"Protocol Characteristics" device:parent];
        NSDictionary *dcharacteristics = [self getDictForProperty:@"Device Characteristics" device:parent];                                                       
        NSDictionary *powerstatus = [self getPower:parent interface:interface]; //get power details from parent of parent
        NSString *path = [self getPathAsStringFor:parent];        
        BOOL sleeping = [self isSleeping:powerstatus canLie:NO];  
        IOObjectRelease(parent);
        [ret setObject:path forKey:@"iopath"];        
        [ret setObject:interface forKey:@"interface"];
        [ret setObject:[NSNumber numberWithBool:sleeping] forKey:@"sleeping"];         
        [ret addEntriesFromDictionary:pcharacteristics];
        [ret addEntriesFromDictionary:dcharacteristics];
        [ret addEntriesFromDictionary:powerstatus];  
    }else{
        //NSLog(@"Device skiped, no parent");        
        return nil; //no parent
    }  

    return ret;
    
}

-(NSString*)drillUpToUSBSerial:(io_service_t)root
{       
    NSString *ret = nil;
    // Create an iterator across all parents of the service object passed in.
    io_iterator_t  iter; 
    IORegistryEntryCreateIterator(root,kIOServicePlane,kIORegistryIterateParents|kIORegistryIterateRecursively,&iter);               
    if (iter){
        io_service_t service;      
        while ( ( service = IOIteratorNext( iter ) ) )  {
            if (service) {                                     
                if ( IOObjectConformsTo( service, "IOUSBDevice") ) {                                                
                    ret = [self getStringForProperty:@"USB Serial Number" device:service];
                }                    
                IOObjectRelease(service);                        
            }                
        }
        IOObjectRelease(iter);            
    }else{
        NSLog(@"Error IORegistryEntryGetParentIterator");        
    } 
    return ret;
}

-(NSString*)getPathAsStringFor:(io_service_t)service{
    io_string_t   devicePath;
    if (IORegistryEntryGetPath(service, kIOServicePlane, devicePath) == KERN_SUCCESS)    {
        return [NSString stringWithFormat:@"%s",&devicePath];
    }else{
        NSLog(@"Error getting path");
    }
    return nil;
}

-(NSDictionary*)getPower:(io_service_t)root interface:(NSString*)interface{  
    NSDictionary *ret = nil;
    if ([interface isEqualToString:@"USB"] || [interface isEqualToString:@"FireWire"]) {
        io_service_t parent;
        IORegistryEntryGetParentEntry(root,kIOServicePlane,&parent);
        if (parent) {  
            ret = [self getDictForProperty:@"IOPowerManagement" device:parent];            
            IOObjectRelease(parent);            
        }    
        if (ret == nil) NSLog(@"ERROR getting power management info for %@ device",interface);        
    }else if ([interface isEqualToString:@"SATA"]){
        io_iterator_t  iter;        
        // Create an iterator across all parents of object passed in
        IORegistryEntryCreateIterator(root,kIOServicePlane,kIORegistryIterateParents|kIORegistryIterateRecursively,&iter);          
        if (iter){
            io_service_t service;            
            while ( ( service = IOIteratorNext( iter ) ) )  {
                if (service) {
                    if ( IOObjectConformsTo( service, "AppleAHCIPort") ) {                    
                        //descend into IOPowerConnection/AppleAHCIDiskQueueManager                        
                        io_service_t child;
                        IORegistryEntryGetChildEntry(service,kIOPowerPlane,&child);
                        if (child) {               
                            io_service_t childofchild;
                            IORegistryEntryGetChildEntry(child,kIOPowerPlane,&childofchild);
                            if (childofchild) {
                                ret = [self getDictForProperty:@"IOPowerManagement" device:childofchild];                                            
                                IOObjectRelease( childofchild );   
                            }  
                            IOObjectRelease( child );                            
                        }  
                    }   
                    IOObjectRelease( service );
                }                
            }
            IOObjectRelease( iter );            
        }else{
            NSLog(@"Error iterating root for %@ device",interface);        
        }  
        if (ret == nil) NSLog(@"ERROR getting power management info for %@ device",interface);
    }else{
        NSLog(@"Power management info is not supported for %@ device",interface);
    } 
    return ret;
}

-(NSString*)interfaceType:(io_service_t)device{
    if (IOObjectConformsTo(device,"IOATABlockStorageDevice")) return @"ATA";    
    if (IOObjectConformsTo(device,"IOAHCIBlockStorageDevice")) return @"SATA"; 
    if (IOObjectConformsTo(device,"IOBlockStorageServices")) return @"USB"; //IOSCSIPeripheralDeviceType00
    if (IOObjectConformsTo(device,"IOReducedBlockServices")) return @"FireWire"; //IOSCSIPeripheralDeviceType0E
    CFStringRef class = IOObjectCopyClass(device);
    if (class) {
        NSLog(@"Unknown device type %@",(NSString*)class);
        CFRelease(class);
    }
    return nil;
}

-(BOOL)isSleeping:(NSDictionary*)dict canLie:(BOOL)canLie
{ 
    if (canLie == YES) {
        //first check if IdleTimerPeriod is not biger than checkFrequency
        int64_t checkFrequency = [[[[defaults dictionaryForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"checkFrequency"] intValue];    
        int64_t IdleTimerPeriod = [[dict objectForKey:@"IdleTimerPeriod"] intValue] / 1000ULL;
        if (IdleTimerPeriod > checkFrequency && [[dict objectForKey:@"DevicePowerState"] intValue] > 1) {
            NSLog(@"Drive is not sleeping and checkFrequency %lld is higher than IdleTimerPeriod %lld, will lie about the drive being asleep as to not prevent it from falling asleep",checkFrequency,IdleTimerPeriod);
            return YES;
        }        
    }    

    if ([[dict objectForKey:@"DevicePowerState"] intValue] > 1) {
        return NO;
    }else{
        return YES;    
    }
    
    return NO;
}

- (NSDictionary*)getDictForProperty:(NSString*)propertyName device:(io_service_t)device{
	NSDictionary *ret = nil;		
    CFTypeRef theCFProperty = IORegistryEntryCreateCFProperty(device, (CFStringRef)propertyName, kCFAllocatorDefault, 0);        
    if (theCFProperty) {
        if (CFGetTypeID(theCFProperty) != CFDictionaryGetTypeID()){
            NSLog(@"Value for %@ is not a dict",propertyName);                    
        }else{
            ret = [NSDictionary dictionaryWithDictionary:(NSDictionary *)theCFProperty];
        }        
        CFRelease(theCFProperty);           
	}else{
        NSLog(@"Could not get %@",propertyName);
    }    
	return ret;
}

- (NSString*)getStringForProperty:(NSString*)propertyName device:(io_service_t)device{
	NSString *ret = nil;    
    CFTypeRef theCFProperty = IORegistryEntryCreateCFProperty(device, (CFStringRef)propertyName, kCFAllocatorDefault, 0);        
    if (theCFProperty) {
        if (CFGetTypeID(theCFProperty) != CFStringGetTypeID()){
            NSLog(@"Value for %@ is not a string",propertyName);                    
        }else{
            ret = [NSString stringWithString:(NSString*)theCFProperty];            
        }
        CFRelease(theCFProperty);            
	}else{
        NSLog(@"Could not get %@",propertyName);
    }    
	return ret;
}

- (int)getIntForProperty:(NSString*)propertyName device:(io_service_t)device{
	int ret = 0;    
    CFTypeRef theCFProperty = IORegistryEntryCreateCFProperty(device, (CFStringRef)propertyName, kCFAllocatorDefault, 0);        
    if (theCFProperty) {
        if (CFGetTypeID(theCFProperty) != CFNumberGetTypeID()){
            NSLog(@"Value for %@ is not a number",propertyName);                    
        }else{
            CFNumberGetValue(theCFProperty, kCFNumberIntType,&ret);
        }   
        CFRelease(theCFProperty);            
	}else{
        NSLog(@"Could not get %@",propertyName);
    }    
	return ret;
}

-(int64_t)machineIdleTime{
    int64_t idlesecs = -1;
    io_iterator_t iter = 0;
    if (IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IOHIDSystem"), &iter) == KERN_SUCCESS) {
        io_registry_entry_t entry = IOIteratorNext(iter);
        if (entry) {
            CFMutableDictionaryRef dict = NULL;
            if (IORegistryEntryCreateCFProperties(entry, &dict, kCFAllocatorDefault, 0) == KERN_SUCCESS) {
                CFNumberRef obj = CFDictionaryGetValue(dict, CFSTR("HIDIdleTime"));
                if (obj) {
                    int64_t nanoseconds = 0;
                    if (CFNumberGetValue(obj, kCFNumberSInt64Type, &nanoseconds)) {
                        idlesecs = nanoseconds / 1000ULL;
                    }
                }
                CFRelease(dict);
            }
            IOObjectRelease(entry);
        }
        IOObjectRelease(iter);
    }
    return idlesecs;
}


#pragma mark notifs

-(BOOL)doNotifications:(NSDictionary*)dict{
    BOOL ret = NO;   
    NSString *name = [dict objectForKey:@"name"];
    NSString *read = [dict objectForKey:@"read"];
    NSString *write = [dict objectForKey:@"write"];
    NSString *lifeRead = [dict objectForKey:@"lifeRead"];
    NSString *lifeWrite = [dict objectForKey:@"lifeWrite"];        
    NSString *smart = [dict objectForKey:@"smart"];
    NSString *badSectors = [dict objectForKey:@"badSectors"];
    NSString *loadCycles = [dict objectForKey:@"loadCycles"];         
    NSString *startStops = [dict objectForKey:@"startStops"];                 
    NSString *temp = [dict objectForKey:@"temp"];
    NSDictionary *cache = [self cacheForDisk:dict];         
    int readOperations = [[dict objectForKey:@"readOperations"] intValue];
    int writeOperations =  [[dict objectForKey:@"writeOperations"] intValue];
    int readLatency = [[dict objectForKey:@"readLatency"] intValue]; 
    int writeLatency = [[dict objectForKey:@"writeLatency"] intValue];
    
    if ([[dict objectForKey:@"type"] isEqualToString:@"SSD"]){
        //for SSD
        if ([read intValue] > 0 || [write intValue] > 0 || [lifeRead intValue] > 1000 || [lifeWrite intValue] > 1000 || [smart isEqualToString:@"Failing"] || [badSectors intValue] > 1000 || [temp intValue] > 68) {
            [self saveSetting:[NSNumber numberWithBool:YES] forKey:@"redIcon"]; //set red icon
            ret = YES;
        }   
        if ( readOperations == 0 || readLatency != 0 || writeLatency != 0) {
            [self saveSetting:[NSNumber numberWithBool:YES] forKey:@"litIcon"]; //lit icon
        }         
    }else{
        //for rest
        if ([read intValue] > 0 || [write intValue] > 0 || [lifeRead intValue] > 100 || [lifeWrite intValue] > 100 || [smart isEqualToString:@"Failing"] || [badSectors intValue] > 10 || [temp intValue] > 68 || [loadCycles intValue] > 500000 || [startStops intValue] > 5000 ) {
            [self saveSetting:[NSNumber numberWithBool:YES] forKey:@"redIcon"]; //set red icon
            ret = YES;            
        }     
        if ( readOperations == 0 || readLatency != 0 || writeLatency != 0) {
            [self saveSetting:[NSNumber numberWithBool:YES] forKey:@"litIcon"]; //lit icon
        }                 
        if ([loadCycles intValue] == 500000 || [loadCycles intValue] == 410000 || [loadCycles intValue] == 420000 || [loadCycles intValue] == 430000  || [loadCycles intValue] == 440000 || [loadCycles intValue] == 450000 || [loadCycles intValue] == 460000 || [loadCycles intValue] == 470000 || [loadCycles intValue] == 480000 || [loadCycles intValue] == 490000){
            NSString *title = [NSString stringWithFormat:@"Disk %@ load cycles nearing maximum.",name];
            NSString *desc = @"Typically a drive is near the end of it's life if it nears 500000, this value is incremented every time the drive parks it's needles.";
            [self sendGrowlNotification:[title stringByAppendingString:desc] title:@"DiskFailure"];
        }   
        if ([startStops intValue] == 5000 || [startStops intValue] == 4100 || [startStops intValue] == 4200 || [startStops intValue] == 4300  || [startStops intValue] == 4400 || [startStops intValue] == 4500 || [startStops intValue] == 4600 || [startStops intValue] == 4700 || [startStops intValue] == 4800 || [startStops intValue] == 4900){
            NSString *title = [NSString stringWithFormat:@"Disk %@ start/stops nearing maximum.",name];
            NSString *desc = @"Typically a drive is near the end of it's life if it nears 5000, this value is incremented every time the drive spins up/down.";
            [self sendGrowlNotification:[title stringByAppendingString:desc] title:@"DiskFailure"];
        }        
    }   
    //for all
    int readwrite = [read intValue]+[write intValue];
    if ( readwrite > 0){
        if ( readwrite > 0 && readwrite == ([lifeRead intValue]+[lifeWrite intValue])){
            NSString *title = [NSString stringWithFormat:@"Disk %@ experiencing read/write errors.",name];
            NSString *desc = @"This is a strong indicator for iminent failure and was detected for the first time on this drive.";                
            [self showAlert:desc title:title];                
        } else {
            NSString *title = [NSString stringWithFormat:@"Disk %@ read/write errors.",name];
            NSString *desc = @"This is a strong indicator for iminent failure and it is not the first time this drive is experiencing it.";                
            [self sendGrowlNotification:[title stringByAppendingString:desc] title:@"DiskFailure"];                
        }           
    }
    if ([temp intValue] > 68 && [temp intValue] > [[cache objectForKey:@"highestTemp"] intValue]){
        NSString *title = [NSString stringWithFormat:@"Disk %@ temperature over 68°C/155°F.",name];
        NSString *desc = @"This is above recomended operating temperature and there is strong evidence that it can lead to degradation of the drive.";
        [self showAlert:desc title:title];
    }
    if ([smart isEqualToString:@"Failing"] && [[cache objectForKey:@"smart"] isEqualToString:@"Verified"]){
        NSString *title = [NSString stringWithFormat:@"Disk %@ SMART status changed to failing.",name];
        NSString *desc = @"This means the drive is reporting one or more conditions have exceeded normal values which means imminent failure.";
        [self showAlert:desc title:title];
    }  
    int newBads  = [badSectors intValue] - [[cache objectForKey:@"badSectors"] intValue];
    if (newBads > 0){
        if ([[cache objectForKey:@"badSectors"] intValue] == 0) {
            NSString *title = [NSString stringWithFormat:@"Disk %@ reporting %i bad sectors.",name,newBads];
            NSString *desc = @"This is a strong indicator for iminent failure and was detected for the first time on this drive.";                
            [self showAlert:desc title:title];             
        }else{
            NSString *title = [NSString stringWithFormat:@"Disk %@ reporting %i new bad sectors.",name,newBads];
            NSString *desc = @"This is a strong indicator for iminent failure and it is not the first time this drive is experiencing it.";               
            [self sendGrowlNotification:[title stringByAppendingString:desc] title:@"DiskFailure"];            
        }
    }else if (newBads < 0){
        NSString *title = [NSString stringWithFormat:@"Disk %@ count of bad sectors decreased by %i.",name,newBads*-1];
        NSString *desc = @"The disk could genuinely have succeeded to recover previously corrupted areas or had them marked in error to begin with.";
        [self sendGrowlNotification:[title stringByAppendingString:desc] title:@"DiskFailure"];
    }
    //these ones are less definitive
    if ( readOperations == 0 ){
        NSString *title = [NSString stringWithFormat:@"Disk %@ reports zero read operations.",name];
        NSString *desc = @"This could signal drive failure, typically even drives without partitions are read for low level information.";                
        [self sendGrowlNotification:[title stringByAppendingString:desc] title:@"DiskFailure"];              
    }
    if ( writeOperations == 0 ){
        NSString *title = [NSString stringWithFormat:@"Disk %@ reports zero write operations.",name];
        NSString *desc = @"This could be fine if the disk has no partitions or they are mounted read only, otherwise it could signal drive failure.";                
        NSLog(@"%@,%@",title,desc);        
    }   
    if ( readLatency != 0 || writeLatency != 0 ){
        NSString *title = [NSString stringWithFormat:@"Disk %@ reports latency (%i/read %i/write).",name,readLatency,writeLatency];
        NSString *desc = @"This is not a definitive indication of probelms but it should not normally hapen on healthy drives.";                
        [self sendGrowlNotification:[title stringByAppendingString:desc] title:@"DiskFailure"];              
    }    
    [[NSNotificationCenter defaultCenter] postNotificationName:MENUBAR_OBSERVER_NAME_STRING object:@"refreshIcon" userInfo:nil];	     
    return ret;
}

-(void)sendGrowlNotification:(NSString*)desc title:(NSString*)title{
    NSLog(@"Notified with growl:%@,%@",title,desc);
    if ([PREF_OBSERVER_NAME_STRING rangeOfString:@"MPPlugin"].location != NSNotFound) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MPpluginsEvent" object:nil userInfo:
         [NSDictionary dictionaryWithObjectsAndKeys:@"doGrowl",@"what",title,@"title",desc,@"message",nil]
         ];   
    }else{        
        [[NSNotificationCenter defaultCenter] postNotificationName:APP_OBSERVER_NAME_STRING object:nil userInfo:
         [NSDictionary dictionaryWithObjectsAndKeys:@"doGrowl",@"what",title,@"title",desc,@"message",nil]
         ];               
    }    
}

-(void)showAlert:(NSString*)desc title:(NSString*)title{
    if (desc == nil) {
        NSLog(@"Empty alert %@",title);
        desc = @"";        
    }
    NSAlert *alert =[NSAlert alertWithMessageText:title defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:desc];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert runModal]; 
}


@end
