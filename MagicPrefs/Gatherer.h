//
//  Gatherer.h
//  MagicPrefs
//
//  Created by Vlad Alexa on 4/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <IOBluetooth/IOBluetooth.h>

@class BluetoothHIDDeviceController;

@interface Gatherer : NSObject {
    id nseventMonitor;
    int mm_battery;    
    int mt_battery;  
    NSMutableDictionary *dataBase;
	NSUserDefaults *defaults;   
	NSString *lastTouchedDev; 
    BluetoothHIDDeviceController *hidController;  
	NSImage	*displayImage;
	NSImage	*graphImage;     
}

-(void)selfMonitor;
-(void)toggleSelfMonitoring;
    
-(void)refreshBattery:(id)sender;
- (void)touch:(NSString*)type fingers:(int)fingers;
- (void)click:(NSString*)type fingers:(int)fingers;
- (void)scroll:(NSString*)type fingers:(int)fingers;
- (void)cursor:(NSString*)type fingers:(int)fingers;
    
-(void)batteryDraining:(NSString*)type step:(int)step level:(int)level;
-(void)batteryCharging:(NSString*)type step:(int)step level:(int)level;

-(void)minuteChanged:(id)sender;
-(void)hourChanged:(id)sender;
-(void)dayChanged:(id)sender;

- (void)saveUpdateReplacing:(NSString*)what type:(NSString*)type;
- (void)saveUpdateReset:(NSString*)what type:(NSString*)type;
- (void)saveUpdateAdding:(NSString*)what type:(NSString*)type;
- (void)addNew:(NSString*)kind;

-(NSString*)humanizeTimeInterval:(double)time;
-(NSDictionary*)editNestedDict:(NSDictionary*)dict setObject:(id)object forKeyHierarchy:(NSArray*)hierarchy;

-(void)checkBatteryLow:(NSString*)type;
-(void)checkBatteryPanic:(NSTimer*)timer;
-(void)notifyBatteryDiff:(NSString*)type step:(int)step level:(int)level;
-(void)notifyBatteryCharge:(NSString*)type;

- (BOOL)isMagicMouse:(IOBluetoothDevice *)device;
- (BOOL)isMagicTrackpad:(IOBluetoothDevice *)device;

- (void)refreshGraph;
- (void)drawIcon:(NSString*)type;

@end

@interface BluetoothHIDDevice : NSObject{
}

+ (id)withHIDDevice:(unsigned int)arg1;
+ (id)withBluetoothDevice:(id)arg1;
- (id)initWithHIDDevice:(unsigned int)arg1;
- (id)initWithBluetoothDevice:(id)arg1;

@end

@interface AppleBluetoothHIDDevice : BluetoothHIDDevice{
}

- (id)initWithHIDDevice:(unsigned int)arg1;
- (float)batteryPercent;
- (BOOL)batteryLow;
- (BOOL)batteryDangerouslyLow;
@end

@interface BluetoothHIDDeviceController : NSObject{
}

- (id)initForAllDevices;
- (id)initForAppleDevices;
- (IOBluetoothUserNotification *)registerForConnectNotifications:(id)arg1 selector:(SEL)arg2;
- (IOBluetoothUserNotification *)registerForDisconnectNotifications:(id)arg1 selector:(SEL)arg2;
- (IOBluetoothUserNotification *)registerForNameChangeNotifications:(id)arg1 selector:(SEL)arg2;
- (IOBluetoothUserNotification *)registerForActivityNotifications:(id)arg1 selector:(SEL)arg2;
- (IOBluetoothUserNotification *)registerForBatteryStateChangeNotifications:(id)arg1 selector:(SEL)arg2;
- (IOBluetoothUserNotification *)registerForLowBatteryNotifications:(id)arg1 selector:(SEL)arg2;
- (IOBluetoothUserNotification *)registerForDangerouslyLowBatteryNotifications:(id)arg1 selector:(SEL)arg2;
- (void)unregisterForAllNotifications:(id)arg1;


@end
