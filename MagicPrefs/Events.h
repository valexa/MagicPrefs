//
//  Events.h
//  MagicPrefs
//
//  Created by Vlad Alexa on 11/23/09.
//  Copyright 2009 NextDesign. All rights reserved.
//

#import <Foundation/Foundation.h> 

#include <unistd.h> 
#include <CoreFoundation/CoreFoundation.h> 
#include <ApplicationServices/ApplicationServices.h> 
#include <HIToolbox/CarbonEventsCore.h>
#include <IOBluetooth/IOBluetooth.h>

/* 
 These structs are required, in order to handle some parameters returned from the 
 MultiTouchSupport.framework 
 */ 
typedef struct { 
	float x; 
	float y; 
}mtPoint; 

typedef struct { 
	mtPoint position; 
	mtPoint velocity; 
}mtReadout; 

/* 
 Some reversed engineered informations from MultiTouchSupport.framework 
 */ 
typedef struct 
{ 
	int frame; //the current frame 
	double timestamp; //event timestamp 
	int identifier; //identifier guaranteed unique for life of touch per device 
	int state; //the current state (not sure what the values mean) 
	int unknown1; 
	int unknown2; 
	mtReadout normalized; //the normalized position and vector of the touch (0,0 to 1,1) 
	float size; //the size of the touch (the area of your finger being tracked) 
	int zero1;  
	float angle; //the angle of the touch -| 
	float majorAxis; //the major axis of the touch -|-- an ellipsoid. you can track the angle of each finger! 
	float minorAxis; //the minor axis of the touch -| 
	mtReadout unknown3;
	int zero2[2];  
	float unknown4;  
}Touch; 

/* states:
 2 touch down slightly
 3 touch down solid
 4 touching
 5 touching stoped moving
 6 touch off rare
 7 touch off 
 */

//a reference pointer for the multitouch device 
typedef void *MTDeviceRef; 

//the prototype for the callback functions
typedef int (*MTContactCallbackFunction)(MTDeviceRef,Touch*,int,double,int);
typedef int (*MTNotificationCallbackFunction)(int,int); //not right will crash
typedef int (*MTProximityCallbackFunction)(int,int); //not right will crash

void MTRegisterNotificationEventCallback(MTDeviceRef, MTNotificationCallbackFunction);
void MTUnregisterNotificationEventCallback(MTDeviceRef, MTNotificationCallbackFunction);

void MTRegisterOpticalProximityChangedCallback(MTDeviceRef, MTProximityCallbackFunction);
void MTUnregisterOpticalProximityChangedCallback(MTDeviceRef, MTProximityCallbackFunction);

void MTRegisterContactFrameCallback(MTDeviceRef, MTContactCallbackFunction); 
void MTUnregisterContactFrameCallback(MTDeviceRef, MTContactCallbackFunction);
int MTDeviceIsAvailable(void);
void MTDeviceStart(MTDeviceRef, int);
int MTDeviceIsRunning(MTDeviceRef);
void MTDeviceStop(MTDeviceRef);
void MTDeviceRelease(MTDeviceRef);

CFArrayRef MTDeviceCreateList(void);
CFStringRef mt_CreateSavedNameForDevice(MTDeviceRef);

//interesting
//
//int MTDeviceIsBuiltIn(MTDeviceRef); //started missbehaving with 235.16
//mt_ForwardOpticalProximity
//mt_ForwardFarfieldProximity
//CFDictionaryRef mt_CachePropertiesForDevice(MTDeviceRef);
//MTDeviceCreateListForDriverType
//MTDeviceGetVersion
//MTDeviceGetFamilyID
//MTDeviceGetGUID
//MTDeviceGetDeviceID
//CFNumberRef MTDeviceGetTypeID
//MTDeviceGetActualType
//MTDeviceGetSerialNumber
//MTDeviceGetTransportMethod
//MTDeviceGetDriverType
//mt_DeviceDispatchKeyboardEvent
//MTDeviceDispatchKeyboardEvent
//MTDeviceDispatchMomentumScrollStartStopEvent
//MTRegisterALSChangedCallback:
//MTUnregisterALSChangedCallback:
//MTDeviceGetAdvancedNoiseAvoidanceEnabled
//MTDeviceSetAdvancedNoiseAvoidanceEnabled

@class SymbolicHotKeys;
@class Gatherer;

@interface Events : NSObject {
	Touch *data;
	int fingers;	
	int frame;		
	MTDeviceRef mmouseDev;
	MTDeviceRef mtrackpadDev;
	MTDeviceRef gtrackpadDev;	
	CFMachPortRef eventTap;
	CFRunLoopSourceRef runLoopSource;
	CFTimeInterval performTime;
	CFTimeInterval lastTouchTime;
	CFTimeInterval lastGestureTime;
	CFTimeInterval lastZonesCacheTime;
	CGEventRef lastCGEvent;
	CGEventRef newCGEvent;	
	NSString *lastTouchedDev;	
	NSMutableDictionary *taps;
	int retry;
    int retryAttempts;
	int btdevices;
	float vely;
	float velx;
	float dist2f;	
	BOOL holdinglf;
	BOOL holdingrf;
	BOOL holdingmf;
	BOOL holdingLR;    
	BOOL holdingRL;
	BOOL holdingLM;    
	BOOL holdinglock;
	BOOL holdingcmd;	
	BOOL holdingalt;
	BOOL holdingshift;
	BOOL holdingctrl;	
	BOOL mpointer;
	BOOL tpointer;
    BOOL tscrolling;
	BOOL mmshown;	
	BOOL performedGesture;
    BOOL skipNextClickUp;
    BOOL notifiedOfPrefpaneDeletion;
	NSUserDefaults *defaults;
	SymbolicHotKeys *symbolicHotKeys;
    Gatherer *gatherer;
	NSString *activeAppID;	
	NSMutableDictionary *pluginEventsList;
    NSMutableDictionary *cachedZones;
    NSDictionary *pluginDefaults;
    CGPoint lastMousePos;
}

@property (nonatomic, assign, readwrite) Touch *data;
@property (nonatomic, assign, readwrite) int fingers;
@property (nonatomic, assign, readwrite) int frame;
@property (nonatomic, assign, readwrite) CGEventRef lastCGEvent;

-(NSDictionary*)loadPrefs:(NSString*)name;
-(BOOL)isinZone:(NSDictionary*)zone;
-(void)performGestureIfInZone:(NSString*)key name:(NSString*)name zones:(NSDictionary*)zones clear:(BOOL)clear;
-(void)sendTouchNotif:(NSString*)type;

-(void)synthesizedGestureStart;
-(void)synthesizeRotate:(double)rotation;
-(void)synthesizeMagnify:(double)magnification;
-(void)synthesizedGestureEnd:(NSTimer*)timer;

-(void) performGestureWithName:(const char *)name;
-(void) performTargetKey:(NSString*) string;
-(void) performTargetApp:(NSString*) string;
-(void) performAscript:(NSString *)string;

-(void) moveCursor:(float)x y:(float)y;
-(void)invertScrolling:(CGEventRef)event;

-(void) mainGtrackpadTouchCallback;
-(void) mainMtrackpadTouchCallback;
-(void) mainMmouseTouchCallback;

-(void) touchCallback;
-(void) gtrackpadTouchGesture:(NSDictionary*)d key:(NSString*)key target:(NSString*)target zones:(NSDictionary*)z tapon:(int)tapon tapoff:(int)tapoff movestop:(int)movestop pinch:(int)pinch rotate:(int)rotate f1:(Touch*)f1;
-(void) mtrackpadTouchGesture:(NSDictionary*)d key:(NSString*)key target:(NSString*)target zones:(NSDictionary*)z tapon:(int)tapon tapoff:(int)tapoff movestop:(int)movestop pinch:(int)pinch rotate:(int)rotate f1:(Touch*)f1;
-(void) mmouseTouchGesture:(NSDictionary*)d key:(NSString*)key target:(NSString*)target zones:(NSDictionary*)z tapon:(int)tapon tapoff:(int)tapoff movestop:(int)movestop pinch:(int)pinch rotate:(int)rotate f1:(Touch*)f1;
-(void) gtrackpadClickGesture:(NSDictionary*)d key:(NSString*)key target:(NSString*)target zones:(NSDictionary*)z;
-(void) mtrackpadClickGesture:(NSDictionary*)d key:(NSString*)key target:(NSString*)target zones:(NSDictionary*)z;
-(void) mmouseClickGesture:(NSDictionary*)d key:(NSString*)key target:(NSString*)target zones:(NSDictionary*)z;
-(CGEventRef) newClickCallBack:(CGEventRef)event type:(CGEventType)type;
-(void)loopPrefsType:(NSString*)type tapon:(int)tapon tapoff:(int)tapoff movestop:(int)movestop pinch:(int)pinch rotate:(int)rotate f1:(Touch*)f1;

-(void) tap_start;
-(void) tap_stop;
-(NSString*) mtdevice_info:(MTDeviceRef)mtDevice what:(NSString*)what;
-(void) mtdevices_init;
-(void) mtdevice_start:(MTDeviceRef)dev;
-(void) mtdevice_stop:(MTDeviceRef)dev;

- (BOOL) pairedCheck;
- (BOOL)isMagicTrackpad:(IOBluetoothDevice *)device;
- (BOOL)isMagicMouse:(IOBluetoothDevice *)device;
	
- (void) syncSpeed;

/* 
old methods
 */ 
float absint(float i);
CGFloat angleBetweenLines(CGPoint line1Start, CGPoint line1End, CGPoint line2Start, CGPoint line2End);
CGFloat angleOfLine(CGPoint lineStart, CGPoint lineEnd);
BOOL oppose(float one , float two);
CGPoint mousePos();
void printDebugInfos(int nFingers, Touch *data);
CGEventFlags getFlags(int key);
void logFlags(CGEventFlags flags);

//pointer trick
id selfContainer(id newSelf);

//notification stuff
void CoreDockSendNotification(NSString *notificationName);


@end


