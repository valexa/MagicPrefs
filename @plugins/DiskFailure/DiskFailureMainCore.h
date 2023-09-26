//
//  DiskFailureMainCore.h
//  DiskFailure
//
//  Created by Vlad Alexa on 4/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CloudController;

@interface DiskFailureMainCore : NSObject {
    IBOutlet CloudController *cloudController;    
@private
    NSMutableString *sharedDataPath;        
    NSUserDefaults *defaults;
    NSMutableArray *migrationCache;
}

-(NSDictionary*)sharedDefaults;
-(void)saveData:(id)data forKey:(NSString*)key;
-(void)saveSetting:(id)object forKey:(NSString*)key;
-(NSDictionary*)editNestedDict:(NSDictionary*)dict setObject:(id)object forKeyHierarchy:(NSArray*)hierarchy;
-(NSDictionary*)mergePrefs:(NSDictionary*)newDisks;
-(NSDictionary*)processData:(NSDictionary*)dict;
-(NSDictionary*)cacheForDisk:(NSDictionary*)disk;
-(NSString*)naIfNil:(id)object;

-(void)parseSyslog:(NSString*)query;
//-(NSString*)readLineAsNSString:(FILE *)file;
//-(void)parseLogs:(NSURL*)url;
-(NSString *)machineSerial;

-(void)timerLoop:(id)sender;
-(void)doCheck:(id)sender;
-(NSDictionary*) parseIOBlockStorageDriver:(io_service_t)service;
-(NSString*)interfaceType:(io_service_t)device;
-(NSString*)drillUpToUSBSerial:(io_service_t)root;
-(NSString*)getPathAsStringFor:(io_service_t)service;
-(NSDictionary*)getPower:(io_service_t)root interface:(NSString*)interface;
-(BOOL)isSleeping:(NSDictionary*)dict canLie:(BOOL)canLie;
- (NSDictionary*)getDictForProperty:(NSString*)propertyName device:(io_service_t)device;
- (NSString*)getStringForProperty:(NSString*)propertyName device:(io_service_t)device;
- (int)getIntForProperty:(NSString*)propertyName device:(io_service_t)device;
-(int64_t)machineIdleTime;
    
-(BOOL)doNotifications:(NSDictionary*)dict;
-(void)sendGrowlNotification:(NSString*)desc title:(NSString*)title;
-(void)showAlert:(NSString*)desc title:(NSString*)title;

@end
