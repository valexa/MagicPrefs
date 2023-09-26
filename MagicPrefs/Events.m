//
//  Events.m
//  MagicPrefs
//
//  Created by Vlad Alexa on 11/23/09.
//  Copyright 2009 NextDesign. All rights reserved.
//

#import "Events.h"

#import "KeyCodeManager.h"
#import "SymbolicHotKeys.h"
#import "Gatherer.h"

@implementation Events

@synthesize data,fingers,frame,lastCGEvent;

float absint(float i){
	if (i < 0){
		return i*-1;
	}else{
		return i;
	}	
}

CGFloat angleBetweenLines(CGPoint line1Start, CGPoint line1End, CGPoint line2Start, CGPoint line2End) {
	
	CGFloat a = line1End.x - line1Start.x;
	CGFloat b = line1End.y - line1Start.y;
	CGFloat c = line2End.x - line2Start.x;
	CGFloat d = line2End.y - line2Start.y;
    
    CGFloat line1Slope = (line1End.y - line1Start.y) / (line1End.x - line1Start.x);
    CGFloat line2Slope = (line2End.y - line2Start.y) / (line2End.x - line2Start.x);
	
	CGFloat degs = acosf(((a*c) + (b*d)) / ((sqrt(a*a + b*b)) * (sqrt(c*c + d*d))));
	
    
	return (line2Slope > line1Slope) ? degs : -degs;	
}

CGFloat angleOfLine(CGPoint lineStart, CGPoint lineEnd) {
    
    CGFloat lineSlope = (lineEnd.y - lineStart.y) / (lineEnd.x - lineStart.x);
    
	return lineSlope;	
}

BOOL oppose(float one , float two){
	if ((one > 0 && two < 0) || (one < 0 && two > 0)) {				
		return YES;				
	}		
	return NO;	
}

CGPoint mousePos(){
	CGEventRef e = CGEventCreate(NULL);
    CGPoint curr = CGEventGetLocation(e);	
	CFRelease(e);		
	return curr;
	
	/*
	 //cocoa
	 NSPoint mouseLoc = [NSEvent mouseLocation];
	 return (CGPoint)mouseLoc;	
	 
	 //carbon
	 HIPoint p;
	 HIGetMousePosition (kHICoordSpaceScreenPixel, NULL, &p);
	 return CGPointMake(p.x,p.y);
	 */ 
}

-(NSDictionary*)loadPrefs:(NSString*)name{
        
	NSMutableDictionary *dict = nil;
	NSString *presetForApp = nil;
	NSArray	*arr = [defaults objectForKey:@"presetApps"];
	for (id app in arr){		
		if ([[app objectForKey:@"value"] isEqualToString:activeAppID] || [[app objectForKey:@"name"] isEqualToString:activeAppID]) {
			presetForApp = [app objectForKey:@"type"];			
			//NSLog(@"using %@ preset for %@",presetForApp,activeAppID);
		}
	}
	if (presetForApp) {				
		dict = [[[defaults objectForKey:@"presets"] objectForKey:presetForApp] objectForKey:name];		
	}else {
		dict = [defaults objectForKey:name];			
	}	
	//in case deleted presets left orphan binding
	if (dict == nil) {
		return [defaults objectForKey:name];		
	}else {
		return dict;		
	}	
}

-(BOOL)isinZone:(NSDictionary*)zone{
	if (zone == nil) {
		//got no zone for this gesture, enough to return true
		return YES;
	}else{
		float x = [[zone objectForKey:@"x"] floatValue];
		float w = [[zone objectForKey:@"w"] floatValue];
		float y = [[zone objectForKey:@"y"] floatValue];
		float h = [[zone objectForKey:@"h"] floatValue];
		int i;	
		for (i=0; i<fingers; i++) { 
			Touch *f = &data[i];						
			if (f->normalized.position.x > x && f->normalized.position.x < x+w && f->normalized.position.y > y && f->normalized.position.y < y+h) {
				//this finger is inside zone, carry on
			}else{
				//got one finger outside zone, enough to return false
				return NO;
			}	
			//NSLog(@"[finger %i] X is %f (min %f max %f) Y is %f (min %f max %f)",i,f->normalized.position.x,x,x+w,f->normalized.position.y,y,y+h);			
		} 
        if (fingers > 0) {
            //all fingers inside zone
            return YES;            
        }
	}
    return NO;    
}

-(void)performGestureIfInZone:(NSString*)key name:(NSString*)name zones:(NSDictionary*)zones clear:(BOOL)clear{	
	BOOL inzone = [self isinZone:[zones objectForKey:key]];
	if (inzone == YES) {	
		if (clear == YES) [taps removeAllObjects]; //empty fingers data
		[self performGestureWithName:[name cStringUsingEncoding:NSUTF8StringEncoding]];	
		//NSLog(@"%@ performed action \"%@\" with id %@",lastTouchedDev,name,key);		
	}else {
		//NSLog(@"%@ action \"%@\" with id %@ skipped as it is outside zone",lastTouchedDev,name,key);
	}	
}

-(void)sendTouchNotif:(NSString*)type{
	
	NSString *name = @"";
	
	if ([type isEqualToString:@"LiveMacbook"]) {
		name = @"gt";
	}else if ([type isEqualToString:@"LiveTrackpad"]) {
		name = @"mt";
	}else if ([type isEqualToString:@"LiveMouse"]) {		
		name = @"mm";		
	}
	
	if (![lastTouchedDev isEqualToString:name]) {
		NSLog(@"ERROR, lastTouchedDev (%@) not the same as %@ ",lastTouchedDev,name);
		return;
	}
	
	BOOL live = [defaults boolForKey:type];	
	if (live) {		
		NSMutableDictionary *fdict = [NSMutableDictionary dictionaryWithCapacity:1];
		int i; 
		for (i=0; i<fingers; i++) {
			NSString *index = [NSString stringWithFormat:@"%i",i+1];			
			Touch *f = &data[i]; 
			[fdict setObject:[NSDictionary dictionaryWithObjectsAndKeys:
							  [NSString stringWithFormat:@"%i",f->state],@"state",
							  [NSString stringWithFormat:@"%f",f->normalized.position.x],@"posx",
							  [NSString stringWithFormat:@"%f",f->normalized.position.y],@"posy",								
							  nil] forKey:index];			
		} 		
		NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:
								@"touch",@"what",
								fdict,@"fingers",	
								name,@"back",
								nil];		
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneImgEvent" object:@"remote" userInfo:object deliverImmediately:YES];
	}
	
}

-(void)synthesizedGestureStart{      
    
	if (lastGestureTime == 0) {             
        CGEventSourceRef eventSource = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);         
        CGEventRef ev = CGEventCreate(eventSource);    
        CGEventSetType(ev, NSEventTypeBeginGesture);
        CGEventSetIntegerValueField(ev, 55, 29); //type gesture
        CGEventSetIntegerValueField(ev, 110, 61); //subtype BeginGesture    
        CGEventSetIntegerValueField(ev, 115, 5); //subtype 5
        CGEventSetIntegerValueField(ev, 117, 5); //subtype 5   
        CGEventPost(kCGHIDEventTap, ev);
        CFRelease(ev);      
        CFRelease(eventSource);        
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(synthesizedGestureEnd:) userInfo:nil repeats:NO];        
    }    
        
}

-(void)synthesizeRotate:(double)rotation{
    
	if (lastGestureTime == 0) { 
        [self synthesizedGestureStart];
    }    
    
    CGEventSourceRef eventSource = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);        
    CGEventRef ev = CGEventCreate(eventSource);  
    CGEventSetType(ev, NSEventTypeRotate);   
    CGEventSetIntegerValueField(ev, 55, 29); //type gesture    
    CGEventSetIntegerValueField(ev, 59, 256); // ?        
    CGEventSetIntegerValueField(ev, 101, 4); // ?
    CGEventSetIntegerValueField(ev, 107, 1200); // ?   
    CGEventSetIntegerValueField(ev, 110, 5); //subtype rotate 
    CGEventSetDoubleValueField(ev,113,rotation); //rotation
    CGEventSetDoubleValueField(ev,114,rotation); //rotation
    CGEventSetDoubleValueField(ev,116,rotation); //rotation
    CGEventSetDoubleValueField(ev,118,rotation); //rotation   
    CGEventPost(kCGHIDEventTap, ev);     
    CFRelease(ev);                  
    CFRelease(eventSource);  
        
    lastGestureTime = CFAbsoluteTimeGetCurrent();    
}

-(void)synthesizeMagnify:(double)magnification{
    
	if (lastGestureTime == 0) { 
        [self synthesizedGestureStart];
    }    
    
    CGEventSourceRef eventSource = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);        
    CGEventRef ev = CGEventCreate(eventSource);  
    CGEventSetType(ev, NSEventTypeMagnify);    
    CGEventSetIntegerValueField(ev, 55, 29); //type gesture    
    CGEventSetIntegerValueField(ev, 59, 256); // ?        
    CGEventSetIntegerValueField(ev, 101, 4); // ?
    CGEventSetIntegerValueField(ev, 107, 1200); // ?   
    CGEventSetIntegerValueField(ev, 110, 8); //subtype magnify 
    CGEventSetDoubleValueField(ev,113,magnification); //magnification
    CGEventSetDoubleValueField(ev,114,magnification); //magnification
    CGEventSetDoubleValueField(ev,116,magnification); //magnification
    CGEventSetDoubleValueField(ev,118,magnification); //magnification  
    CGEventPost(kCGHIDEventTap, ev);     
    CFRelease(ev);                  
    CFRelease(eventSource);  
    
    lastGestureTime = CFAbsoluteTimeGetCurrent();    
}

-(void)synthesizedGestureEnd:(NSTimer*)timer{
    
	float interval = CFAbsoluteTimeGetCurrent() - lastGestureTime;    
	if (interval > 0.5) {
        lastGestureTime = 0;
        CGEventSourceRef eventSource = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);             
        CGEventRef ev = CGEventCreate(eventSource);     
        CGEventSetType(ev, NSEventTypeEndGesture);
        CGEventSetIntegerValueField(ev, 55, 29); //type gesture
        CGEventSetIntegerValueField(ev, 110, 62); //subtype EndGesture   
        CGEventSetIntegerValueField(ev, 115, 5); //subtype 5
        CGEventSetIntegerValueField(ev, 117, 5); //subtype 5   
        CGEventPost(kCGHIDEventTap, ev);   
        CFRelease(ev);
        CFRelease(eventSource);                   
    }else{
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(synthesizedGestureEnd:) userInfo:nil repeats:NO];          
    }   
    
}

//just output debug info. use it to see all the raw infos dumped to screen 
void printDebugInfos(int nFingers, Touch *data) { 	
	int i; 
	for (i=0; i<nFingers; i++) { 
		Touch *f = &data[i]; 
		NSLog(@"Finger: %d, frame: %d, timestamp: %f, ID: %d, state: %d, PosX: %f, PosY: %f, VelX: %f, VelY: %f, Angle: %f, MajorAxis: %f, MinorAxis: %f\n", i, 
			  f->frame, 
			  f->timestamp, 
			  f->identifier, 
			  f->state, 
			  f->normalized.position.x, 
			  f->normalized.position.y, 
			  f->normalized.velocity.x, 
			  f->normalized.velocity.y, 
			  f->angle, 
			  f->majorAxis, 
			  f->minorAxis); 
	} 
}

#pragma mark actions

-(void) performGestureWithName:(const char *)name {
	
	performedGesture = YES;	
	//NSLog(@"Performing %s",name);
	
	//click events
	
	if (strcmp(name,"Cmd Left Click") == 0){
		//NSLog(@"<<cmd left click down");	
		
		CGEventSourceRef source = CGEventSourceCreate (kCGEventSourceStateCombinedSessionState);		
		CGEventRef ev = CGEventCreateKeyboardEvent(source, 55, YES);
		CGEventSetFlags(ev,kCGEventFlagMaskCommand);		
		CGEventPost(kCGHIDEventTap, ev);		
		CGEventRef newEvent = CGEventCreateMouseEvent(source, kCGEventLeftMouseDown, CGEventGetLocation(lastCGEvent), kCGMouseButtonLeft);
		CGEventSetFlags(newEvent,CGEventGetFlags(ev));
		CFRelease(ev);		
		CFRelease(source);		
		holdinglf = YES;
		holdingcmd = YES;		
		newCGEvent = newEvent;
		return;			
	}
	
	if (strcmp(name,"Alt Left Click") == 0){
		//NSLog(@"<<alt left click down");	
		
		CGEventSourceRef source = CGEventSourceCreate (kCGEventSourceStateCombinedSessionState);		
		CGEventRef ev = CGEventCreateKeyboardEvent(source, 61, YES);
		CGEventSetFlags(ev,kCGEventFlagMaskAlternate);		
		CGEventPost(kCGHIDEventTap, ev);
		CGEventRef newEvent = CGEventCreateMouseEvent(source, kCGEventLeftMouseDown, CGEventGetLocation(lastCGEvent), kCGMouseButtonLeft);
		CGEventSetFlags(newEvent,CGEventGetFlags(ev));		
		CFRelease(ev);		
		CFRelease(source);		
		holdinglf = YES;	
		holdingalt = YES;		
		newCGEvent = newEvent;		
		return;			
	}	
    
	if (strcmp(name,"Shift Left Click") == 0){
		//NSLog(@"<<shift left click down");	
		
		CGEventSourceRef source = CGEventSourceCreate (kCGEventSourceStateCombinedSessionState);		
		CGEventRef ev = CGEventCreateKeyboardEvent(source, 56, YES);
		CGEventSetFlags(ev,kCGEventFlagMaskShift);		
		CGEventPost(kCGHIDEventTap, ev);
		CGEventRef newEvent = CGEventCreateMouseEvent(source, kCGEventLeftMouseDown, CGEventGetLocation(lastCGEvent), kCGMouseButtonLeft);
		CGEventSetFlags(newEvent,CGEventGetFlags(ev));		
		CFRelease(ev);		
		CFRelease(source);		
		holdinglf = YES;	
		holdingshift = YES;		
		newCGEvent = newEvent;		
		return;			
	}
    
	if (strcmp(name,"Ctrl Left Click") == 0){
		//NSLog(@"<<ctrl left click down");	
		
		CGEventSourceRef source = CGEventSourceCreate (kCGEventSourceStateCombinedSessionState);		
		CGEventRef ev = CGEventCreateKeyboardEvent(source, 59, YES);
		CGEventSetFlags(ev,kCGEventFlagMaskControl);		
		CGEventPost(kCGHIDEventTap, ev);
		CGEventRef newEvent = CGEventCreateMouseEvent(source, kCGEventLeftMouseDown, CGEventGetLocation(lastCGEvent), kCGMouseButtonLeft);
		CGEventSetFlags(newEvent,CGEventGetFlags(ev));		
		CFRelease(ev);		
		CFRelease(source);		
		holdinglf = YES;	
		holdingctrl = YES;		
		newCGEvent = newEvent;		
		return;			
	}     
	
	if (strcmp(name,"Left Click") == 0){
		//NSLog(@"<<left click down");
		CGEventRef newEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, CGEventGetLocation(lastCGEvent), kCGMouseButtonLeft);
        int count = CGEventGetIntegerValueField(lastCGEvent, kCGMouseEventClickState);
        CGEventSetIntegerValueField(newEvent, kCGMouseEventClickState, count);        
		holdinglf = YES;		
		newCGEvent = newEvent;		
		return;			
	}
	
	if (strcmp(name,"Right Click") == 0){
		//NSLog(@"<<right click down");	
		CGEventRef newEvent = CGEventCreateMouseEvent(NULL, kCGEventRightMouseDown, CGEventGetLocation(lastCGEvent), kCGMouseButtonRight);
        int count = CGEventGetIntegerValueField(lastCGEvent, kCGMouseEventClickState);
        CGEventSetIntegerValueField(newEvent, kCGMouseEventClickState, count);        
		holdingrf = YES;		
		newCGEvent = newEvent;		
		return;			
	}	
	
	if (strcmp(name,"Middle Click") == 0){
		//NSLog(@"<<middle click down");		
		CGEventRef newEvent = CGEventCreateMouseEvent(NULL, kCGEventOtherMouseDown, CGEventGetLocation(lastCGEvent), kCGMouseButtonCenter);
        int count = CGEventGetIntegerValueField(lastCGEvent, kCGMouseEventClickState);
        CGEventSetIntegerValueField(newEvent, kCGMouseEventClickState, count);        
		holdingmf = YES;		
		newCGEvent = newEvent;
		return;			
	}	
	
	//toggle finger pointer on mouse
	if (strcmp(name,"Toggle Mouse Finger Cursor") == 0){	
		if (mpointer){				
			mpointer = NO;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:
			 [NSDictionary dictionaryWithObjectsAndKeys:@"doNotif",@"what",@"pointer",@"image",@"Disabled Mouse Finger Cursor",@"text",nil]
			 ];				
		}else{		
			mpointer = YES;				
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:
			 [NSDictionary dictionaryWithObjectsAndKeys:@"doNotif",@"what",@"pointer",@"image",@"Enabled Mouse Finger Cursor",@"text",nil]
			 ];										
		}		
		
		/*
		//CGAssociateMouseAndMouseCursorPosition is BUGGED, do not use
		CGError err;
		if (fpointer){			
			err = CGAssociateMouseAndMouseCursorPosition (true);
			if (err == kCGErrorSuccess){
				NSLog(@"Optical Cursor ON");				
				fpointer = NO;				
			}else{
				NSLog(@"Error %i turning cursor ON",err);
			}			
		}else{		
			err = CGAssociateMouseAndMouseCursorPosition (false);			
			if (err == kCGErrorSuccess){
				NSLog(@"Optical Cursor OFF");				
				fpointer = YES;				
			}else{
				NSLog(@"Error %i turning cursor OFF",err);
			}			
		}
		*/ 
		return;		
	}
    
	//toggle finger pointer on trackpad
	if (strcmp(name,"Toggle Trackpad Finger Cursor") == 0){	
		if (tpointer){				
			tpointer = NO;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:
			 [NSDictionary dictionaryWithObjectsAndKeys:@"doNotif",@"what",@"pointer",@"image",@"Disabled Trackpad Finger Cursor",@"text",nil]
			 ];				
		}else{		
			tpointer = YES;				
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:
			 [NSDictionary dictionaryWithObjectsAndKeys:@"doNotif",@"what",@"pointer",@"image",@"Enabled Trackpad Finger Cursor",@"text",nil]
			 ];										
		}		
		return;		
	}
    
	//toggle scrolling
	if (strcmp(name,"Toggle Scrolling") == 0){
		if (tscrolling){
			tscrolling = NO;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:
			 [NSDictionary dictionaryWithObjectsAndKeys:@"doNotif",@"what",@"scrolling",@"image",@"Disabled Scrolling",@"text",nil]
			 ];
		}else{
			tscrolling = YES;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:
			 [NSDictionary dictionaryWithObjectsAndKeys:@"doNotif",@"what",@"scrolling",@"image",@"Enabled Scrolling",@"text",nil]
			 ];
		}
		return;
	}
	
	//drag lock mode HIDDEN
	if (strcmp(name,"Toggle Drag Lock") == 0){	
		CGEventRef ev;
		if (holdinglock){
			ev = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, mousePos(), kCGMouseButtonLeft);
			CGEventPost(kCGSessionEventTap,ev);
			CFRelease(ev);
			holdinglock = NO;	
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:
			 [NSDictionary dictionaryWithObjectsAndKeys:@"doNotif",@"what",@"pointer",@"image",@"Drag Lock Disabled",@"text",nil]
			 ];								
		}else {
			ev = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, mousePos(), kCGMouseButtonLeft);
			CGEventPost(kCGSessionEventTap,ev);	
			CFRelease(ev);			
			holdinglock = YES;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:
			 [NSDictionary dictionaryWithObjectsAndKeys:@"doNotif",@"what",@"pointer",@"image",@"Drag Lock Enabled",@"text",nil]
			 ];					
		}			
		return;	
	}	
	
	if (strcmp(name,"Cut") == 0){	
		[self performAscript:@"tell application \"System Events\" to keystroke \"x\" using command down"];
		return;		
	}		
	
	if (strcmp(name,"Copy") == 0){	
		[self performAscript:@"tell application \"System Events\" to keystroke \"c\" using command down"];
		return;		
	}
	
	if (strcmp(name,"Paste") == 0){	
		[self performAscript:@"tell application \"System Events\" to keystroke \"v\" using command down"];
		return;		
	}
	
	if (strcmp(name,"Save") == 0){	
		[self performAscript:@"tell application \"System Events\" to keystroke \"s\" using command down"];
		return;		
	}	
	
	if (strcmp(name,"Close") == 0){	
		[self performAscript:@"tell application \"System Events\" to keystroke \"w\" using command down"];
		return;		
	}
	
	if (strcmp(name,"Open") == 0){	
		[self performAscript:@"tell application \"System Events\" to keystroke \"o\" using command down"];
		return;		
	}
	
	if (strcmp(name,"New") == 0){	
		[self performAscript:@"tell application \"System Events\" to keystroke \"n\" using command down"];
		return;		
	}	
	
	if (strcmp(name,"Left Double Click") == 0){
		//NSLog(@"<<left DoubleClick");	        
		CGPostMouseEvent(mousePos(),true,1,true,false);
		CGPostMouseEvent(mousePos(),true,1,false,false);
		CGPostMouseEvent(mousePos(),true,1,true,false);
		CGPostMouseEvent(mousePos(),true,1,false,false);		
		return;
	}	
		
	if (strcmp(name,"Left Click (Down+Up)") == 0){
		//NSLog(@"<<left click down+up");	
		CGPostMouseEvent(mousePos(),true,1,true,false);
		CGPostMouseEvent(mousePos(),true,1,false,false);		
		return;		
	}
	
	if (strcmp(name,"Right Click (Down+Up)") == 0){
		//NSLog(@"<<right click down+up");		
		CGPostMouseEvent(mousePos(),true,2,false,true);
		CGPostMouseEvent(mousePos(),true,2,false,false);			
		return;		
	}	
	
	if (strcmp(name,"Middle Click (Down+Up)") == 0){
		//NSLog(@"<<middle click down+up");		
		CGPostMouseEvent(mousePos(),true,3,false,false,true);
		CGPostMouseEvent(mousePos(),true,3,false,false,false);			
		return;		
	}	
	
	if (strcmp(name,"Hold Both Left&Right") == 0){
		//NSLog(@"<<holding Right&Left");			
		CGEventRef ev;		
		ev = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, CGEventGetLocation(lastCGEvent), kCGMouseButtonLeft);      				
		CGEventPost(kCGSessionEventTap,ev);	
		CFRelease(ev);
		ev = CGEventCreateMouseEvent(NULL, kCGEventRightMouseDown, CGEventGetLocation(lastCGEvent), kCGMouseButtonRight);
		CGEventPost(kCGSessionEventTap,ev);		
		CFRelease(ev);	
		holdingLR = YES;	
		return;		
	}	
    
	if (strcmp(name,"Hold Both Right&Left") == 0){
		//NSLog(@"<<holding Right&Left");			
		CGEventRef ev;		
		ev = CGEventCreateMouseEvent(NULL, kCGEventRightMouseDown, CGEventGetLocation(lastCGEvent), kCGMouseButtonRight);				
		CGEventPost(kCGSessionEventTap,ev);	
		CFRelease(ev);
		ev = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, CGEventGetLocation(lastCGEvent), kCGMouseButtonLeft);				
		CGEventPost(kCGSessionEventTap,ev);		
		CFRelease(ev);	
		holdingRL = YES;	
		return;		
	}
    
	if (strcmp(name,"Hold Both Left&Middle") == 0){
		//NSLog(@"<<holding Right&Left");			
		CGEventRef ev;		
		ev = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, CGEventGetLocation(lastCGEvent), kCGMouseButtonLeft);      				
		CGEventPost(kCGSessionEventTap,ev);	
		CFRelease(ev);
		ev = CGEventCreateMouseEvent(NULL, kCGEventOtherMouseDown, CGEventGetLocation(lastCGEvent), kCGMouseButtonCenter);
		CGEventPost(kCGSessionEventTap,ev);		
		CFRelease(ev);	
		holdingLM = YES;	
		return;		
	}  
	
	if (strcmp(name,"Screen Zoom In") == 0 || strcmp(name,"Screen Zoom Out") == 0){
		//check if toogled on, (we don't return from this function but continue) 
		NSDictionary *dict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.universalaccess"];		
		if ([[dict objectForKey:@"closeViewDriver"] boolValue] == NO) {
			[self performAscript:[symbolicHotKeys keysForAction:@"Toggle Zoom"]];
		}		
		
		/*
		//check live zooming
		if (UAZoomEnabled()){
			NSLog(@"zoomed");
		}else {
			NSLog(@"not zoomed");
		}
		*/ 
	}	
	
	if (strcmp(name,"Screen Zoom In") == 0 ){		
		[self performAscript:[symbolicHotKeys keysForAction:@"Screen Zoom In"]];				
		return;	
	}	
	
	if (strcmp(name,"Screen Zoom Out") == 0){	
		[self performAscript:[symbolicHotKeys keysForAction:@"Screen Zoom Out"]];		
		return;	
	}	
	
	//handle the events from plugins
	for (NSString *pluginName in pluginEventsList){
		NSString *notifName = [NSString stringWithFormat:@"MPPlugin%@Event",pluginName];
		NSDictionary *events = [pluginEventsList objectForKey:pluginName];
		for (NSString *eventName in events){
			NSString *eventDescription = [events objectForKey:eventName];
			//NSLog(@"Am aware of %@ event %@(%@) ",pluginName,eventName,eventDescription);			
			//magic menu is a particular case and is handled by the hardcoded routine //mm perform		
			if ([eventDescription isEqualToString:@"Magic Menu"]) continue;			
			if (strcmp(name,[eventDescription UTF8String]) == 0){
				[[NSDistributedNotificationCenter defaultCenter] postNotificationName:notifName object:eventName userInfo:nil];	
				return;					
			}			
		}			
	}
	
	//mm perform
	if (strcmp(name,"Magic Menu") == 0){
		mmshown = YES;
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPPluginMagicMenuEvent" object:@"showMMenu" userInfo:nil];
		if (lastCGEvent){
			//also select it if triggered from click
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPPluginMagicMenuEvent" object:@"fingerDown" userInfo:nil];			
		}		
		return;		
	}	
	
	//
	//following actions repeat time is limited
	//
	
	int sensitivity = 0;
	if ([lastTouchedDev isEqualToString:@"gt"]) sensitivity	= [[defaults objectForKey:@"tapSensMacbook"] intValue];
	if ([lastTouchedDev isEqualToString:@"mt"]) sensitivity	= [[defaults objectForKey:@"tapSensTrackpad"] intValue];	
	if ([lastTouchedDev isEqualToString:@"mm"]) sensitivity	= [[defaults objectForKey:@"tapSensMouse"] intValue];	
	double repeatsens = sensitivity/10.0;
	
	//limit to once every half second
	float interval = CFAbsoluteTimeGetCurrent() - performTime;
	if (interval < (0.2*repeatsens)) {
		//NSLog(@"skipping performing target ,too fast (%f/%f sec)",interval,0.2*repeatsens);		
		return;
	}else {	
		performTime = CFAbsoluteTimeGetCurrent();
	}		

	if (strcmp(name,"Lock Session") == 0){
		system("/System/Library/CoreServices/Menu\\ Extras/User.menu/Contents/Resources/CGSession -suspend");				
		return;		
	}	
	
	if (strcmp(name,"Application Windows") == 0){		
		CoreDockSendNotification(@"com.apple.expose.front.awake");	
		return;		
	}	
	
	if (strcmp(name,"Desktop") == 0){		
		CoreDockSendNotification(@"com.apple.showdesktop.awake");	
		return;		
	}		
	
	if (strcmp(name,"Spotlight") == 0){		
		[self performAscript:[symbolicHotKeys keysForAction:@"Spotlight"]];			
		return;	
	}	
	
	if (strcmp(name,"QuickLook") == 0){				
		[self performAscript:@"tell application \"System Events\" to keystroke \"y\" using command down"];
		return;		
	}	
	
	if (strcmp(name,"Switch Space Left") == 0){			
		[self performAscript:[symbolicHotKeys keysForAction:@"Switch Space Left"]];			
		return;	
	}
	
	if (strcmp(name,"Switch Space Right") == 0){
		[self performAscript:[symbolicHotKeys keysForAction:@"Switch Space Right"]];			
		return;		
	}
	
	if (strcmp(name,"Application Switcher") == 0){
		
		//crazy hack unbelievable it works, cmd order and flags are not properly done
		
		CGEventSourceRef source = CGEventSourceCreate (kCGEventSourceStatePrivate);	
		CGEventRef ev;

		ev = CGEventCreateKeyboardEvent(source, 48, YES);
		CGEventSetFlags(ev,kCGEventFlagMaskCommand);
		CGEventSetType(ev, kCGEventKeyDown);
		CGEventPost(kCGHIDEventTap, ev);		
		
		CGEventSetFlags(ev,kCGEventFlagMaskCommand);
		CGEventSetType(ev, kCGEventKeyUp);
		CGEventPost(kCGHIDEventTap, ev);			
		CFRelease(ev);		

		ev = CGEventCreateKeyboardEvent(source, 55, YES);		
		CGEventSetFlags(ev, kCGEventFlagMaskCommand);
		CGEventSetType(ev, kCGEventKeyDown);
		CGEventSetIntegerValueField(ev, kCGKeyboardEventAutorepeat, (int64_t)1);		
		CGEventPost(kCGHIDEventTap, ev);
		
		CGEventSetFlags(ev, kCGEventFlagMaskCommand);
		CGEventSetType(ev, kCGEventKeyUp);
		CGEventPost(kCGHIDEventTap, ev);		
		CFRelease(ev);	
		
		CFRelease(source);		
		
		/*
		CGEventSourceRef source = CGEventSourceCreate (kCGEventSourceStatePrivate);		
		CGEventRef ev;	
		CGEventFlags flags;		
		
		//cmd down
		ev = CGEventCreateKeyboardEvent (source, (CGKeyCode)54, true);					
		CGEventPost(kCGHIDEventTap,ev);	
		
		//get flags
		flags = CGEventGetFlags(ev); //same as: flags = kCGEventFlagMaskCommand;
		CFRelease(ev);
		 
		//tab down
		ev = CGEventCreateKeyboardEvent (source, (CGKeyCode)48, true);					
		CGEventSetFlags(ev,flags);				
		CGEventPost(kCGHIDEventTap,ev);	
 		CFRelease(ev);
		//tab up		
		ev = CGEventCreateKeyboardEvent (source, (CGKeyCode)48, false);								
		CGEventSetFlags(ev,flags);			
		CGEventPost(kCGHIDEventTap,ev);	
		CFRelease(ev);		 
		
		//tab down repeat				
		ev = CGEventCreateKeyboardEvent (source, (CGKeyCode)48, true);	
		CGEventSetFlags(ev,flags);		
		CGEventSetIntegerValueField(ev, kCGKeyboardEventAutorepeat, (int64_t)1); //does not work , could it be the timestamp ?						
		CGEventPost(kCGHIDEventTap,ev);
		CFRelease(ev);		 
		//tab up						
		ev = CGEventCreateKeyboardEvent (source, (CGKeyCode)48, false);			
		CGEventSetFlags(ev,flags);			
		CGEventPost(kCGHIDEventTap,ev);	
		CFRelease(ev);		 
		
		//cmd up
		ev = CGEventCreateKeyboardEvent (source, (CGKeyCode)54, false);					
		CGEventPost(kCGHIDEventTap,ev);		
		CFRelease(ev);		
		*/		 
				
		return;		
	}	
	
	if (strcmp(name,"Application Zoom In") == 0){
		[self performAscript:@"tell application \"System Events\" to keystroke \"+\" using command down"];				
		return;	
	}	
	
	if (strcmp(name,"Application Zoom Out") == 0){
		[self performAscript:@"tell application \"System Events\" to keystroke \"-\" using command down"];		
		return;	
	}	
	
	if (strcmp(name,"Hide All Other Applications") == 0){		
		//[[NSWorkspace sharedWorkspace] hideOtherApplications];
		[[NSApplication sharedApplication] hideOtherApplications:nil];
		return;		
	}	
	
	if (strcmp(name,"UnHide All Applications") == 0){		
		[[NSApplication sharedApplication] unhideAllApplications:nil];
		return;		
	}
	
	if (strcmp(name,"Disable MagicPrefs") == 0){	
		if (mmouseDev) [self mtdevice_stop:mmouseDev];
		if (mtrackpadDev) [self mtdevice_stop:mtrackpadDev];
		if (gtrackpadDev) [self mtdevice_stop:gtrackpadDev];
		[self tap_stop];	
		return;		
	}	
	
	//handle custom binding targets	
	BOOL matchedCustom = NO;
	NSArray *custom = [[defaults objectForKey:@"customTargets"] retain];
	NSString *nsname = [[NSString alloc] initWithCString:name encoding:NSUTF8StringEncoding];
	KeyCodeManager *keyCodeManager = [[KeyCodeManager alloc] init];
	for (id target in custom){	
		NSString *value = [[target objectForKey:@"value"] copy];
		NSString *type = [[target objectForKey:@"type"] copy];
		NSString *name = [[target objectForKey:@"name"] copy];		
		if ([type isEqualToString:@"app"]) {
			if ([[value lastPathComponent] isEqualToString:nsname]) {
				[self performTargetApp:value];
				matchedCustom = YES;
			}
		}
		if ([type isEqualToString:@"key"]) {	
			if ([[keyCodeManager shortcutToString:value] isEqualToString:nsname]) {
				[self performTargetKey:value];
				matchedCustom = YES;				
			}
		}
		if ([type isEqualToString:@"script"]) {				
			if ([name isEqualToString:nsname]) {
				[self performAscript:value];
				matchedCustom = YES;				
			}
		}
		[value release];
		[type release];
		[name release];		
	}
	[nsname release];
	[custom release];
	[keyCodeManager release];	
	if (matchedCustom == YES) return;	
		
	performedGesture = NO;
	NSLog(@"performTarget unknown target: \"%s\"",name);
	
}


CGEventFlags getFlags(int key){	
	if (key == 57) {
		return kCGEventFlagMaskAlphaShift;
	}		
	if (key == 56 || key == 60) {
		return kCGEventFlagMaskShift;
	}
	if (key == 59 || key == 62) {
		return kCGEventFlagMaskControl;
	}
	if (key == 58 || key == 61 ) {
		return kCGEventFlagMaskAlternate;
	}		
	if (key == 54 || key == 55 ) {
		return kCGEventFlagMaskCommand;
	}	
	if (key == 999) {
		return kCGEventFlagMaskHelp;
	}	
	if (key == 63) {
		return kCGEventFlagMaskSecondaryFn;
	}	
	NSLog(@"zero");	
	return 0;
}

void logFlags(CGEventFlags flags){	
	NSString *log = @"";
	if (flags & kCGEventFlagMaskAlphaShift){
		log = [log stringByAppendingString:@"⇪"];
	}
	if (flags & kCGEventFlagMaskShift){
		log = [log stringByAppendingString:@"⇧"];
	}	
	if (flags & kCGEventFlagMaskControl){
		log = [log stringByAppendingString:@"⌃"];		
	}
	if (flags & kCGEventFlagMaskAlternate){
		log = [log stringByAppendingString:@"⌥"];		
	}
	if (flags & kCGEventFlagMaskCommand){
		log = [log stringByAppendingString:@"⌘"];		
	}
	if (flags & kCGEventFlagMaskHelp){
		log = [log stringByAppendingString:@"?"];		
	}
	if (flags & kCGEventFlagMaskSecondaryFn){
		log = [log stringByAppendingString:@"fn"];		
	}
	NSLog(@"%@",log);
}

-(void) performTargetKey:(NSString*) string{
	//NSLog(@"key perform %@",string);
	KeyCodeManager *keyCodeManager = [[KeyCodeManager alloc] init];
	NSArray *arr = [keyCodeManager shortcutToKeyCodes:string];
	NSMutableArray *marr = [[NSMutableArray alloc] init];
	CGEventSourceRef source = CGEventSourceCreate (kCGEventSourceStateCombinedSessionState);		
	CGEventRef ev;		
	CGEventFlags flags = 0x100;
	for (id key in arr){	
		if ([key intValue] > 53 && [key intValue] < 64) {
			//press down the modifier key
			ev = CGEventCreateKeyboardEvent (source, (CGKeyCode)[key intValue], true);	
			if (ev != NULL){
				flags += getFlags([key intValue]);		
				CGEventSetFlags(ev,flags);
				CGEventPost(kCGHIDEventTap,ev);	
				CFRelease(ev);				
				//save modif keys for later backwards
				[marr insertObject:key atIndex:0];				
			}else {
				NSLog(@"CGEventCreateKeyboardEvent NULL");
			}
		}else {					
		    //press down			
			ev = CGEventCreateKeyboardEvent (source, (CGKeyCode)[key intValue], true);	
			if (ev != NULL){
				CGEventSetFlags(ev,flags | CGEventGetFlags(ev)); //combine flags from hardware with our own						
				CGEventPost(kCGHIDEventTap,ev);
				CFRelease(ev);				
			}else {
				NSLog(@"CGEventCreateKeyboardEvent NULL");
			}				
			//press up									
			ev = CGEventCreateKeyboardEvent (source, (CGKeyCode)[key intValue], false);						
			if (ev != NULL){
				CGEventSetFlags(ev,flags | CGEventGetFlags(ev)); //combine flags from hardware with our own						
				CGEventPost(kCGHIDEventTap,ev);	
				CFRelease(ev);				
			}else {
				NSLog(@"CGEventCreateKeyboardEvent NULL");
			}			
		}		
	}	
	for (id key in marr){
		//press up the modifier key		
		ev = CGEventCreateKeyboardEvent (source, (CGKeyCode)[key intValue], false);
		if (ev != NULL){
			flags -= getFlags([key intValue]);
			CGEventSetFlags(ev,flags);		
			CGEventPost(kCGHIDEventTap,ev);
			CFRelease(ev);			
		}else{
			NSLog(@"CGEventCreateKeyboardEvent NULL");
		}			
	}	
	[marr release];
	CFRelease(source);
	[keyCodeManager release];	
}

-(void) performTargetApp:(NSString*) string{
	//NSLog(@"app perform %@",string);
	NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:string error:NULL];
	if ([[dict objectForKey:@"NSFileType"] isEqualToString:@"NSFileTypeDirectory"]){
		[[NSWorkspace sharedWorkspace] launchApplication:string];		
	}else{
		[[NSWorkspace sharedWorkspace] openFile:string];				
	}
}

-(void) performAscript:(NSString *)string{
	//NSLog(@"script perform [%@]",string);	
    NSDictionary* errorDict;
    NSAppleEventDescriptor* returnDescriptor = NULL;
	
    NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:string];
	
    returnDescriptor = [scriptObject executeAndReturnError: &errorDict];
    [scriptObject release];
	
    if (returnDescriptor != NULL) {
        // successful execution
        if (kAENullEvent != [returnDescriptor descriptorType]) {
            // script returned an AppleScript result
            if (cAEList == [returnDescriptor descriptorType]) {
				// result is a list of other descriptors
            } else {
                // coerce the result to the appropriate ObjC type
            }
            //NSLog(@"AppleScript has no result.");			
        }
    } else {
		NSLog(@"AppleScript error: %@", [errorDict objectForKey: @"NSAppleScriptErrorMessage"]);
    }		
}

-(void) moveCursor:(float)x y:(float)y{
	if (absint(x) < 1 && absint(y) < 1){
		//skip tiny movements
		return;
	}
	CGEventRef e = CGEventCreate(NULL);
    CGPoint curr = CGEventGetLocation(e);	
	CFRelease(e);
	//CGDisplayMoveCursorToPoint(CGMainDisplayID(),currentLocation);	
	CGPoint loc = CGPointMake(curr.x + x, curr.y + (y*-1));
	NSRect screen = [[NSScreen mainScreen] frame];
	//make sure we stay within the screen
	if (loc.x < 0) loc.x = 0;
	if (loc.y < 0) loc.y = 0;
	if (loc.x > screen.size.width-10) loc.x = screen.size.width-10;
	if (loc.y > screen.size.height-10) loc.y = screen.size.height-10;
	//NSLog(@"Changed [X %f to %f] [Y %f to %f] (%fx%f)",curr.x,loc.x,curr.y,loc.y,screen.size.width,screen.size.height);
	CGEventRef event  = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, loc, kCGMouseButtonLeft);
    CGEventPost(kCGHIDEventTap, event);
    CFRelease(event);
}

-(void)invertScrolling:(CGEventRef)event{
    
    //NSEvent *nsevent = [NSEvent eventWithCGEvent:event];              
    
    /*
     int64_t type = CGEventGetIntegerValueField(event,kCGScrollWheelEventIsContinuous); 
     double pixelsPerLine = CGEventSourceGetPixelsPerLine(CGEventCreateSourceFromEvent(event));        
     if (type == 0){
     NSLog(@"Line based %f",pixelsPerLine);
     }else{
     NSLog(@"Pixel based type %lld %f",type,pixelsPerLine);            
     } 
     
     if ([[nsevent description] rangeOfString:@"scrollPhase"].location != NSNotFound) {
     NSString *type = [[[[[nsevent description] componentsSeparatedByString:@" "] lastObject] componentsSeparatedByString:@"="] lastObject];	        
     if (![type isEqualToString:@"None"]){
     //NSLog(@"Inertial scroll : %@",type);
     }    
     } 
     */
    
    //setting the event type is recomended
    CGEventSetType(event,kCGEventScrollWheel);        
    
    //in pixels, usually 10 pixels per line (CGEventSourceGetPixelsPerLine)
    double reversedYpixels = CGEventGetDoubleValueField(event, kCGScrollWheelEventPointDeltaAxis1)*-1.0; 
    double reversedXpixels = CGEventGetDoubleValueField(event, kCGScrollWheelEventPointDeltaAxis2)*-1.0;         
    
    //documented as lines or pixels but appears to be always lines (kCGScrollWheelEventIsContinuous)      
    double reversedY = CGEventGetDoubleValueField(event, kCGScrollWheelEventFixedPtDeltaAxis1)*-1.0;
    double reversedX = CGEventGetDoubleValueField(event, kCGScrollWheelEventFixedPtDeltaAxis2)*-1.0;
    
    //order 1, this works for both carbon and cocoa but is integer based and blocky in cocoa, required for carbon to work
    CGEventSetIntegerValueField(event, kCGScrollWheelEventDeltaAxis1, reversedY);
    CGEventSetIntegerValueField(event, kCGScrollWheelEventDeltaAxis2, reversedX);           
    //NSEvent *nsevent_1 = [NSEvent eventWithCGEvent:event];           
    
    //order 2, this makes no change in the scroll, merely here to set the values for the deltas nicely to floats as reported by nsevent, not exactly required
    CGEventSetDoubleValueField(event,kCGScrollWheelEventFixedPtDeltaAxis1, reversedY);
    CGEventSetDoubleValueField(event,kCGScrollWheelEventFixedPtDeltaAxis2, reversedX);                 
    //NSEvent *nsevent_2 = [NSEvent eventWithCGEvent:event];      
    
    //order 3, this does not change the deltas as reported by nsevent and is ignored by carbon (except inertial scrolls) ,required to smooth out scrolls in cocoa
    CGEventSetDoubleValueField(event,kCGScrollWheelEventPointDeltaAxis1,reversedYpixels);
    CGEventSetDoubleValueField(event,kCGScrollWheelEventPointDeltaAxis2,reversedXpixels);          
    //NSEvent *nsevent_3 = [NSEvent eventWithCGEvent:event];          
    
    //NSLog(@"Initial scroll was Y:%f X:%f (pass1: Y:%f X:%f) (pass2: Y:%f X:%f) (pass3: Y:%f X:%f)",[nsevent deltaY],[nsevent deltaX],[nsevent_1 deltaY],[nsevent_1 deltaX],[nsevent_2 deltaY],[nsevent_2 deltaX],[nsevent_3 deltaY],[nsevent_3 deltaX]);                           
}

#pragma mark callbacks

id selfContainer(id newSelf){
    static id selfPointer;	
    if(newSelf == NULL){
        //Access
        return selfPointer;
    } else {
        // Set
        selfPointer = newSelf;
        return NULL;
    }
}

//glass trackpad touches callback 
int gtrackpadTouchCallback(MTDeviceRef device, Touch *touchData, int nFingers, double timestamp, int nFrame) { 
	
	if (MTDeviceIsRunning(device) == 0){
		NSLog(@"gtrackpadTouchCallback fired after device stopped!!");		
		return 0;	
	}
		
	if (nFingers > 0){	
		Events *obj = (Events *) selfContainer(NULL);			
		obj.data = touchData; 
		obj.fingers = nFingers;	
		obj.frame = nFrame;		
		[obj performSelectorOnMainThread:@selector(mainGtrackpadTouchCallback) withObject:nil waitUntilDone:NO];
		//NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		//[self mainGtrackpadTouchCallback];
		//[pool release];
	}	
	
	return 0;	
	
}

//magic trackpad touches callback 
int mtrackpadTouchCallback(MTDeviceRef device, Touch *touchData, int nFingers, double timestamp, int nFrame) { 
	
	if (MTDeviceIsRunning(device) == 0){
		NSLog(@"mtrackpadTouchCallback fired after device stopped!!");		
		return 0;	
	}
	
	if (nFingers > 0){	
		Events *obj = (Events *) selfContainer(NULL);			
		obj.data = touchData; 
		obj.fingers = nFingers;	
		obj.frame = nFrame;		
		[obj performSelectorOnMainThread:@selector(mainMtrackpadTouchCallback) withObject:nil waitUntilDone:NO];
		//NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		//[self mainMtrackpadTouchCallback];
		//[pool release];
	}
	
	return 0;	
	
}

//magic mouse touches callback 
int mmouseTouchCallback(MTDeviceRef device, Touch *touchData, int nFingers, double timestamp, int nFrame) { 
	
	if (MTDeviceIsRunning(device) == 0){
		NSLog(@"mmouseTouchCallback fired after device stopped!!");		
		return 0;	
	}
	
	if (nFingers > 0){	
		Events *obj = (Events *) selfContainer(NULL);			
		obj.data = touchData; 
		obj.fingers = nFingers;	
		obj.frame = nFrame;		
		[obj performSelectorOnMainThread:@selector(mainMmouseTouchCallback) withObject:nil waitUntilDone:NO];
		//NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		//[self mainMmouseTouchCallback];
		//[pool release];
	}	
	
	return 0;
}	

-(void) mainGtrackpadTouchCallback{				
	
	//callback thread might fire after the device is destroyed
	if (gtrackpadDev == NULL){		
		NSLog(@"Internal Trackpad device not engaged, will not do callback.");		
		return;			
	}	
    
    //reset taps
	if (![lastTouchedDev isEqualToString:@"gt"]) [taps removeAllObjects];
	
	//save source and last touch time 
	lastTouchedDev = @"gt";		
	lastTouchTime = CFAbsoluteTimeGetCurrent(); 	

	//send notification of touch	
	[self sendTouchNotif:@"LiveMacbook"];
	
	[self touchCallback];	
}


-(void) mainMtrackpadTouchCallback{				
	
	//callback thread might fire after the device is destroyed
	if (mtrackpadDev == NULL){		
		NSLog(@"Magic Trackpad device not engaged, will not do callback.");		
		return;			
	}	
	
    //reset taps
	if (![lastTouchedDev isEqualToString:@"mt"]) [taps removeAllObjects];    
    
	//save source and last touch time 
	lastTouchedDev = @"mt";		
	lastTouchTime = CFAbsoluteTimeGetCurrent(); 	
	
	//send notification of touch	
	[self sendTouchNotif:@"LiveTrackpad"];
	
	[self touchCallback];		
}	


-(void) mainMmouseTouchCallback{				
	
	//callback thread might fire after the device is destroyed
	if (mmouseDev == NULL){		
		NSLog(@"Magic Mouse device not engaged, will not do callback.");			
		return;			
	}	
		
    //reset taps
	if (![lastTouchedDev isEqualToString:@"mm"]) [taps removeAllObjects];    
    
	//save source and last touch time 
	lastTouchedDev = @"mm";		
	lastTouchTime = CFAbsoluteTimeGetCurrent(); 
	
	//send notification of touch	
	[self sendTouchNotif:@"LiveMouse"];
	
	[self touchCallback];	
}	

-(void) touchCallback{
	
	//check thread
	if (![NSThread isMainThread]){
		NSLog(@"touchCallback called outside main thread: %@", [NSThread currentThread]);
		return;		
	}	
	
	//printDebugInfos(fingers, data);	
	Touch *f1 = &data[0];
	Touch *f2 = &data[1];
	//Touch *f3 = &data[2];	
    
    //send to gatherer
    if ([defaults boolForKey:@"gatherStatistics"] == YES) [gatherer touch:lastTouchedDev fingers:fingers]; 
	
	//device specific extras
	if ([lastTouchedDev isEqualToString:@"gt"]) {
		//none yet
	}
	if ([lastTouchedDev isEqualToString:@"mt"]) {
		//none yet
	}	
	if ([lastTouchedDev isEqualToString:@"mm"]) {
		//finger pointer mode
		if (mpointer){	
			float mouseTrackSpeed = [[defaults valueForKey:@"TrackingMouse"] floatValue];
			[self moveCursor:f1->normalized.velocity.x*mouseTrackSpeed*3 y:f1->normalized.velocity.y*mouseTrackSpeed*3];			
		}	
		
		//mm feed touch data
		if (mmshown){
			if (fingers == 1) { 
				if (f1->state == 3 || f1->state == 2) {
					[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPPluginMagicMenuEvent" object:@"fingerDown" userInfo:nil];		
				} else if (f1->state == 7 || f1->state == 6 || f1->state == 5) {
					[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPPluginMagicMenuEvent" object:@"fingerUp" userInfo:nil];			
				}	
			} 			 			
		}		
	}		
		
	int sensitivity = 0;
	if ([lastTouchedDev isEqualToString:@"gt"]) sensitivity	= [[defaults objectForKey:@"tapSensMacbook"] intValue];
	if ([lastTouchedDev isEqualToString:@"mt"]) sensitivity	= [[defaults objectForKey:@"tapSensTrackpad"] intValue];	
	if ([lastTouchedDev isEqualToString:@"mm"]) sensitivity	= [[defaults objectForKey:@"tapSensMouse"] intValue];

	//save taps	
	int agesens = sensitivity+3;			
	NSMutableArray *old = [[NSMutableArray alloc] init];
	for (id key in taps){
		for (id item in [taps objectForKey:key]){				
			if ((frame-[item intValue]) > agesens){
				//NSLog(@"removing item with %i age",(frame-[item intValue]));
				[old addObject:item];							
			}							
		}			
		if ([old count] > 0){
			//NSLog(@"removed %i old items",[old count]);
			[[taps objectForKey:key] removeObjectsForKeys:old];				
			[old removeAllObjects];			
		}		
	}	
	[old release];
	int tapon = 0; 
	int tapoff = 0;
	int movestop = 0;	
	int i = 0; 	
	for (i=0; i<fingers; i++) { 
		NSString *index = [NSString stringWithFormat:@"%i",i+1];
		if ([taps objectForKey:index] == nil){
			[taps setObject:[[[NSMutableDictionary alloc] init] autorelease] forKey:index];					
		}
		Touch *f = &data[i]; 
		if (f->state == 3 || f->state == 2) {
			[[taps objectForKey:index] setObject:@"down" forKey:[NSString stringWithFormat:@"%i",f->frame]];		
			tapon += 1;			
		} else if (f->state == 7 || f->state == 6 || f->state == 5) {
			[[taps objectForKey:index] setObject:@"up" forKey:[NSString stringWithFormat:@"%i",f->frame]];
			tapoff += 1;			
		}
		if ( f->state == 5){
			movestop += 1;			
		}
		//add current velocity to last one
		velx += f->normalized.velocity.x;
		vely += f->normalized.velocity.y;		
	} 	
    
    float f1velx = f1->normalized.velocity.x;
    float f1vely = f1->normalized.velocity.y;
    float f2velx = f2->normalized.velocity.x;
    float f2vely = f2->normalized.velocity.y;        
    //current angle
    CGPoint curFirstFinger = CGPointMake(f1->normalized.position.x, f1->normalized.position.y);
    CGPoint curSecFinger = CGPointMake(f2->normalized.position.x, f2->normalized.position.y);               
    CGPoint nextFirstFinger = CGPointMake(f1->normalized.position.x+f1velx, f1->normalized.position.y+f1vely); 
    CGPoint nextSecFinger = CGPointMake(f2->normalized.position.x+f2velx, f2->normalized.position.y+f2vely);         
    CGFloat currentAngle = angleBetweenLines(curFirstFinger,curSecFinger,nextFirstFinger, nextSecFinger);  
    //current euclide distance between first two touches
    float dist2f_ = sqrt(((f1->normalized.position.x - f2->normalized.position.x) * (f1->normalized.position.x - f2->normalized.position.x) +
                          (f1->normalized.position.y - f2->normalized.position.y) * (f1->normalized.position.y - f2->normalized.position.y)));		     
    //current movement
    float movement = absint(dist2f_-dist2f);
    
	int rotate = 0; 
	int pinch = 0; 
    
    if (movement > 0.015) {
        //implement pinches		
        if (fingers == 2 || fingers == 3) {							
            //filter out same directions, those are swipes
            if ( oppose(f1velx,f2velx) || oppose(f1vely,f2vely) ){
                float pinchsens	= sensitivity/30.0f;                					
                if ( (absint(f1velx) > pinchsens || absint(f1vely) > pinchsens) && (absint(f2velx) > pinchsens || absint(f2vely) > pinchsens) ){//filter out insignificant
                    
                    if ([defaults boolForKey:@"generateOSXGestures"] == YES) {
                        [self synthesizeMagnify:dist2f_-dist2f];
                    }                    
                    
                    if(dist2f_ < dist2f) { 
                        //NSLog(@"pinch in (%f) magnif %f velocity %f %f | %f %f",movement,dist2f_-dist2f,f1velx,f1vely,f2velx,f2vely);                        
                        pinch = 1;		
                    }else if(dist2f_ > dist2f) { 
                        //NSLog(@"pinch out (%f) magnif %f velocity %f %f | %f %f",movement,dist2f_-dist2f,f1velx,f1vely,f2velx,f2vely);
                        pinch = 2;						
                    }	
                }
            }			
        } 
    }else if (movement > 0.0015){
        //implement rotate
        if (fingers == 2) { 
            //filter out same directions, those are swipes
            if ( oppose(f1velx,f2velx) || oppose(f1vely,f2vely) ){
                float rotatesens	= 0.1f;            
                if (absint(f1velx) > rotatesens && absint(f1vely) > rotatesens && absint(f2velx) > rotatesens && absint(f2vely) > rotatesens) { //filter out insignificant           
                     
                    if ([defaults boolForKey:@"generateOSXGestures"] == YES) {
                        [self synthesizeRotate:currentAngle];
                    }
                    
                    if (currentAngle < 0) { //this is flipped around on magic mouse!
                        //NSLog(@"rotate clockwise (%f) angle %f velocity %f %f | %f %f",movement,currentAngle,f1velx,f1vely,f2velx,f2vely); 
                        rotate = 1;                 
                    }else{
                        //NSLog(@"rotate counterclockwise (%f) angle %f velocity %f %f | %f %f",movement,currentAngle,f1velx,f1vely,f2velx,f2vely);
                        rotate = 2;
                    }            
                }           
            }           
        }                   
    }    

	
	//core
	[self loopPrefsType:@"touch" tapon:tapon tapoff:tapoff movestop:movestop pinch:pinch rotate:rotate f1:f1];	
	
	//save current finger velocity
	velx = 0;
	vely = 0;	
	for (i=0; i<fingers; i++) { 
		Touch *f = &data[i];		
		velx += f->normalized.velocity.x;
		vely += f->normalized.velocity.y;	
	}	
    
	if ( oppose(f1->normalized.velocity.x,f2->normalized.velocity.x) || oppose(f1->normalized.velocity.y,f2->normalized.velocity.y) ){   
        //save the euclide distance between the two touches            
        dist2f = dist2f_;        
    }
	
	//do not breakpoint ? really ??

} 


-(void) gtrackpadTouchGesture:(NSDictionary*)d key:(NSString*)key target:(NSString*)target zones:(NSDictionary*)z tapon:(int)tapon tapoff:(int)tapoff movestop:(int)movestop pinch:(int)pinch rotate:(int)rotate f1:(Touch*)f1{

	
	if (tapoff > 0){
		
		//4 finger tap enabled (if 4 down && 1>0 4>0 || 2>0 4>0 || 3>0 4>0)		
		if ([key isEqualToString:@"311"]) {	
			if ([[[taps objectForKey:@"4"] allKeysForObject:@"down"] count] > 0 ) {
				if (([[taps objectForKey:@"1"] count] > 0 && [[taps objectForKey:@"4"] count] > 0) || ([[taps objectForKey:@"2"] count] > 0 && [[taps objectForKey:@"4"] count] > 0) || ([[taps objectForKey:@"3"] count] > 0 && [[taps objectForKey:@"4"] count] > 0) ) {	
					[self performGestureIfInZone:key name:target zones:z clear:YES];
					return;
				}
			}				
		}	
		
		//3 finger tap enabled (if if 3 down && 4=0  1>0 2>0 || 1>0 3>0)
		if ([key isEqualToString:@"310"]) {	
			if ([[[taps objectForKey:@"3"] allKeysForObject:@"down"] count] > 0 ){ 
				if (([[taps objectForKey:@"1"] count] > 0 && [[taps objectForKey:@"3"] count] > 0) || ([[taps objectForKey:@"2"] count] > 0 && [[taps objectForKey:@"3"] count] > 0))  {
					if ([[taps objectForKey:@"4"] count] < 1 ) {								
						[self performGestureIfInZone:key name:target zones:z clear:YES];
						return;													
					}		
				}	
			}				
		}
		
		//2 finger tap enabled (if 2 down 3=0  4=0  1>0  2>0)
		if ([key isEqualToString:@"309"] || [key isEqualToString:@"308"]) {	
			if ([[[taps objectForKey:@"2"] allKeysForObject:@"down"] count] > 0){
				if ([[taps objectForKey:@"3"] count] < 1 && [[taps objectForKey:@"4"] count] < 1) {
					if ([[taps objectForKey:@"1"] count] > 0 && [[taps objectForKey:@"2"] count] > 0 ) {
						[self performGestureIfInZone:key name:target zones:z clear:YES];
						return;							
					}					
				}					
			}			
		}	
		
		//1 finger tap enabled
		if ([key isEqualToString:@"307"] || [key isEqualToString:@"306"]) {
			if ([[[taps objectForKey:@"1"] allKeysForObject:@"down"] count] > 0 && [[[taps objectForKey:@"1"] allKeysForObject:@"up"] count] > 0 ){
				if ([[taps objectForKey:@"2"] count] < 1 && [[taps objectForKey:@"3"] count] < 1 && [[taps objectForKey:@"4"] count] < 1 ) {
					[self performGestureIfInZone:key name:target zones:z clear:YES];
					return;
				}
			}				
		}			
		
	}//end taps	
	
    if (movestop > 0){				
        //
        //NSLog(@"%f %f [%i]",velx,vely,movestop); //swipes
        //	
        int swipesens = 10-[[defaults objectForKey:@"tapSensMacbook"] intValue]/2; //reversed
        if (swipesens < 1 ) swipesens = 1; //keep above 1
        
        //
        //swipes
        //	
        
        if (fingers == 3) {		
            //three finger swipe left enabled
            if ([key isEqualToString:@"320"]) {
                if (velx < 0 && absint(vely) < absint(velx) && absint(velx) > swipesens){
                    [self performGestureIfInZone:key name:target zones:z clear:NO];
                    return;							
                }
            }
            //three finger swipe right enabled
            if ([key isEqualToString:@"321"]) {	
                if (velx > 0 && absint(vely) < absint(velx) && absint(velx) > swipesens){
                    [self performGestureIfInZone:key name:target zones:z clear:NO];
                    return;															
                }	
            }	
            //three finger swipe up enabled
            if ([key isEqualToString:@"322"]) {
                if (vely > 0 && absint(vely) > absint(velx) && absint(vely) > swipesens){
                    [self performGestureIfInZone:key name:target zones:z clear:NO];
                    return;															
                }	
            }	
            //three finger swipe down enabled
            if ([key isEqualToString:@"323"]) {		
                if (vely < 0 && absint(vely) > absint(velx) && absint(vely) > swipesens){
                    [self performGestureIfInZone:key name:target zones:z clear:NO];
                    return;														
                }	
            }						
        }
        
        if (fingers == 4) {		
            //four finger swipe left enabled
            if ([key isEqualToString:@"326"]) {
                if (velx < 0 && absint(vely) < absint(velx) && absint(velx) > swipesens){
                    [self performGestureIfInZone:key name:target zones:z clear:NO];
                    return;							
                }
            }
            //four finger swipe right enabled
            if ([key isEqualToString:@"327"]) {	
                if (velx > 0 && absint(vely) < absint(velx) && absint(velx) > swipesens){
                    [self performGestureIfInZone:key name:target zones:z clear:NO];
                    return;															
                }	
            }	
            //four finger swipe up enabled
            if ([key isEqualToString:@"328"]) {
                if (vely > 0 && absint(vely) > absint(velx) && absint(vely) > swipesens){
                    [self performGestureIfInZone:key name:target zones:z clear:NO];
                    return;															
                }	
            }	
            //four finger swipe down enabled
            if ([key isEqualToString:@"329"]) {		
                if (vely < 0 && absint(vely) > absint(velx) && absint(vely) > swipesens){
                    [self performGestureIfInZone:key name:target zones:z clear:NO];
                    return;														
                }	
            }						
        }        
        
        
        //
        //rotate
        //	
        
        if (fingers == 2) {	
            //clockwise
            if ([key isEqualToString:@"330"] || [key isEqualToString:@"331"]) {	
                if (rotate == 1) {
                    NSLog(@"clockwise rotate");return;
                    [self performGestureIfInZone:key name:target zones:z clear:NO];
                    return;			
                }				
            }
            //counterclockwise            
            if ([key isEqualToString:@"332"] || [key isEqualToString:@"333"]) {	
                if (rotate == 2) {				
                    NSLog(@"counterclockwise rotate");return;                    
                    [self performGestureIfInZone:key name:target zones:z clear:NO];
                    return;							                    
                }    
            }             
        }        
        
        
        //
        //pinches
        //				
        
        if (fingers == 2) {	
            //two finger pinch in enabled
            if ([key isEqualToString:@"336"] || [key isEqualToString:@"337"]) {	
                if (pinch == 1){
                    [self performGestureIfInZone:key name:target zones:z clear:YES];
                    return;											
                }				
            }	
            
            //two finger pinch out enabled		
            if ([key isEqualToString:@"338"] || [key isEqualToString:@"339"]) {	
                if (pinch == 2){
                    [self performGestureIfInZone:key name:target zones:z clear:YES];
                    return;											
                }				
            }            
        }
        
        /*
        if (fingers == 3) {	
            //three finger pinch in enabled
            if ([key isEqualToString:@"334"]) {	
                if (pinch == 1){
                    [self performGestureIfInZone:key name:target zones:z clear:YES];
                    return;											
                }				
            }	
            
            //three finger pinch out enabled		
            if ([key isEqualToString:@"335"]) {
                if (pinch == 2){
                    [self performGestureIfInZone:key name:target zones:z clear:YES];
                    return;											
                }				
            }            
        } 
        */ 
        
        
    }//end movestop	
	
}

-(void) mtrackpadTouchGesture:(NSDictionary*)d key:(NSString*)key target:(NSString*)target zones:(NSDictionary*)z tapon:(int)tapon tapoff:(int)tapoff movestop:(int)movestop pinch:(int)pinch rotate:(int)rotate f1:(Touch*)f1{

	
	if (tapoff > 0){
		
		//4 finger tap enabled (if 4 down && 1>0 4>0 || 2>0 4>0 || 3>0 4>0)		
		if ([key isEqualToString:@"211"]) {	
			if ([[[taps objectForKey:@"4"] allKeysForObject:@"down"] count] > 0 ) {
				if (([[taps objectForKey:@"1"] count] > 0 && [[taps objectForKey:@"4"] count] > 0) || ([[taps objectForKey:@"2"] count] > 0 && [[taps objectForKey:@"4"] count] > 0) || ([[taps objectForKey:@"3"] count] > 0 && [[taps objectForKey:@"4"] count] > 0) ) {	
					[self performGestureIfInZone:key name:target zones:z clear:YES];
					return;
				}
			}				
		}	
				
		//3 finger tap enabled (if if 3 down && 4=0  1>0 2>0 || 1>0 3>0)
		if ([key isEqualToString:@"210"]) {	
			if ([[[taps objectForKey:@"3"] allKeysForObject:@"down"] count] > 0 ){ 
				if (([[taps objectForKey:@"1"] count] > 0 && [[taps objectForKey:@"3"] count] > 0) || ([[taps objectForKey:@"2"] count] > 0 && [[taps objectForKey:@"3"] count] > 0))  {
					if ([[taps objectForKey:@"4"] count] < 1 ) {								
						[self performGestureIfInZone:key name:target zones:z clear:YES];
						return;													
					}		
				}	
			}				
		}
		
		//2 finger tap enabled (if 2 down 3=0  4=0  1>0  2>0)
		if ([key isEqualToString:@"209"] || [key isEqualToString:@"208"]) {	
			if ([[[taps objectForKey:@"2"] allKeysForObject:@"down"] count] > 0){
				if ([[taps objectForKey:@"3"] count] < 1 && [[taps objectForKey:@"4"] count] < 1) {
					if ([[taps objectForKey:@"1"] count] > 0 && [[taps objectForKey:@"2"] count] > 0 ) {
						[self performGestureIfInZone:key name:target zones:z clear:YES];
						return;							
					}					
				}					
			}			
		}	
		
		//1 finger tap enabled
		if ([key isEqualToString:@"207"] || [key isEqualToString:@"206"]) {
			if ([[[taps objectForKey:@"1"] allKeysForObject:@"down"] count] > 0 && [[[taps objectForKey:@"1"] allKeysForObject:@"up"] count] > 0 ){
				if ([[taps objectForKey:@"2"] count] < 1 && [[taps objectForKey:@"3"] count] < 1 && [[taps objectForKey:@"4"] count] < 1 ) {
					[self performGestureIfInZone:key name:target zones:z clear:YES];
					return;
				}
			}				
		}		
		
		
	}// end taps	
	
	if (movestop > 0){				
		//
		//NSLog(@"%f %f [%i]",velx,vely,movestop); //swipes
		//	
		int swipesens = 10-[[defaults objectForKey:@"tapSensTrackpad"] intValue]/2; //reversed
        if (swipesens < 1 ) swipesens = 1; //keep above 1
		
		//
		//swipes
		//	
        
		if (fingers == 3) {		
			//three finger swipe left enabled
			if ([key isEqualToString:@"220"]) {
				if (velx < 0 && absint(vely) < absint(velx) && absint(velx) > swipesens){
					[self performGestureIfInZone:key name:target zones:z clear:NO];
					return;							
				}
			}
			//three finger swipe right enabled
			if ([key isEqualToString:@"221"]) {	
				if (velx > 0 && absint(vely) < absint(velx) && absint(velx) > swipesens){
					[self performGestureIfInZone:key name:target zones:z clear:NO];
					return;															
				}	
			}	
			//three finger swipe up enabled
			if ([key isEqualToString:@"222"]) {
				if (vely > 0 && absint(vely) > absint(velx) && absint(vely) > swipesens){
					[self performGestureIfInZone:key name:target zones:z clear:NO];
					return;															
				}	
			}	
			//three finger swipe down enabled
			if ([key isEqualToString:@"223"]) {		
				if (vely < 0 && absint(vely) > absint(velx) && absint(vely) > swipesens){
					[self performGestureIfInZone:key name:target zones:z clear:NO];
					return;														
				}	
			}						
		}
        
		if (fingers == 4) {		
			//four finger swipe left enabled
			if ([key isEqualToString:@"226"]) {
				if (velx < 0 && absint(vely) < absint(velx) && absint(velx) > swipesens){
					[self performGestureIfInZone:key name:target zones:z clear:NO];
					return;							
				}
			}
			//four finger swipe right enabled
			if ([key isEqualToString:@"227"]) {	
				if (velx > 0 && absint(vely) < absint(velx) && absint(velx) > swipesens){
					[self performGestureIfInZone:key name:target zones:z clear:NO];
					return;															
				}	
			}	
			//four finger swipe up enabled
			if ([key isEqualToString:@"228"]) {
				if (vely > 0 && absint(vely) > absint(velx) && absint(vely) > swipesens){
					[self performGestureIfInZone:key name:target zones:z clear:NO];
					return;															
				}	
			}	
			//four finger swipe down enabled
			if ([key isEqualToString:@"229"]) {		
				if (vely < 0 && absint(vely) > absint(velx) && absint(vely) > swipesens){
					[self performGestureIfInZone:key name:target zones:z clear:NO];
					return;														
				}	
			}						
		}        
		
        
		//
		//rotate
		//	
        
        if (fingers == 2) {	
            //clockwise
            if ([key isEqualToString:@"230"] || [key isEqualToString:@"231"]) {	
				if (rotate == 1) {
                    [self performGestureIfInZone:key name:target zones:z clear:NO];
                    return;			
                }				
            }
            //counterclockwise            
            if ([key isEqualToString:@"232"] || [key isEqualToString:@"233"]) {	
				if (rotate == 2) {				
                    [self performGestureIfInZone:key name:target zones:z clear:NO];
                    return;							                    
                }    
            }             
        }        
        
		
		//
		//pinches
		//				
        
		if (fingers == 2) {	
            //two finger pinch in enabled
            if ([key isEqualToString:@"236"] || [key isEqualToString:@"237"]) {	
                if (pinch == 1){
                    [self performGestureIfInZone:key name:target zones:z clear:YES];
                    return;											
                }				
            }	
            
            //two finger pinch out enabled		
            if ([key isEqualToString:@"238"] || [key isEqualToString:@"239"]) {	
                if (pinch == 2){
                    [self performGestureIfInZone:key name:target zones:z clear:YES];
                    return;											
                }				
            }            
        }
		
        /*
		if (fingers == 3) {	
            //three finger pinch in enabled
            if ([key isEqualToString:@"234"]) {	
                if (pinch == 1){
                    [self performGestureIfInZone:key name:target zones:z clear:YES];
                    return;											
                }				
            }	
            
            //three finger pinch out enabled		
            if ([key isEqualToString:@"235"]) {
                if (pinch == 2){
                    [self performGestureIfInZone:key name:target zones:z clear:YES];
                    return;											
                }				
            }            
        }
        */ 
	
		
	}//end movestop	
	
}

-(void)mmouseTouchGesture:(NSDictionary*)d key:(NSString*)key target:(NSString*)target zones:(NSDictionary*)z tapon:(int)tapon tapoff:(int)tapoff movestop:(int)movestop pinch:(int)pinch rotate:(int)rotate f1:(Touch*)f1{	
	
	if (tapoff > 0){
		//	
		//NSLog(@"%@",[taps description]); //taps
		//
		
		//4 finger tap enabled (if 4 down && 1>0 4>0 || 2>0 4>0 || 3>0 4>0)
		if ([key isEqualToString:@"8"]) {	
			if ([[[taps objectForKey:@"4"] allKeysForObject:@"down"] count] > 0 ) {
				if (([[taps objectForKey:@"1"] count] > 0 && [[taps objectForKey:@"4"] count] > 0) || ([[taps objectForKey:@"2"] count] > 0 && [[taps objectForKey:@"4"] count] > 0) || ([[taps objectForKey:@"3"] count] > 0 && [[taps objectForKey:@"4"] count] > 0) ) {
					[self performGestureIfInZone:key name:target zones:z clear:YES];
					return;														
				}
			}				
		}	
		
		//3 finger tap enabled (if if 3 down && 4=0  1>0 2>0 || 1>0 3>0)
		if ([key isEqualToString:@"7"]) {	
			if ([[[taps objectForKey:@"3"] allKeysForObject:@"down"] count] > 0 ){ 
				if (([[taps objectForKey:@"1"] count] > 0 && [[taps objectForKey:@"3"] count] > 0) || ([[taps objectForKey:@"2"] count] > 0 && [[taps objectForKey:@"3"] count] > 0))  {
					if ([[taps objectForKey:@"4"] count] < 1 ) {
						[self performGestureIfInZone:key name:target zones:z clear:YES];
						return;														
					}		
				}	
			}				
		}			
		
		//2 finger tap enabled (if 2 down 3=0  4=0  1>0  2>0)
		if ([key isEqualToString:@"6"]) {	
			if ([[[taps objectForKey:@"2"] allKeysForObject:@"down"] count] > 0){
				if ([[taps objectForKey:@"3"] count] < 1 && [[taps objectForKey:@"4"] count] < 1) {
					if ([[taps objectForKey:@"1"] count] > 0 && [[taps objectForKey:@"2"] count] > 0 ) {
						[self performGestureIfInZone:key name:target zones:z clear:YES];
						return;																
					}					
				}					
			}			
		}												
		
		//1 finger tap enabled
		if ([key isEqualToString:@"5"]) {	
			if ([[[taps objectForKey:@"1"] allKeysForObject:@"down"] count] > 0 && [[[taps objectForKey:@"1"] allKeysForObject:@"up"] count] > 0 ){
				if ([[taps objectForKey:@"2"] count] < 1 && [[taps objectForKey:@"3"] count] < 1 && [[taps objectForKey:@"4"] count] < 1 ) {
					[self performGestureIfInZone:key name:target zones:z clear:YES];
					return;																		
				}
			}				
		}	
		
		//1 finger tap left enabled
		if ([key isEqualToString:@"9"]) {	
			if ([[[taps objectForKey:@"1"] allKeysForObject:@"down"] count] > 0 && [[[taps objectForKey:@"1"] allKeysForObject:@"up"] count] > 0 ){
				if ([[taps objectForKey:@"2"] count] < 1 && [[taps objectForKey:@"3"] count] < 1 && [[taps objectForKey:@"4"] count] < 1 ) {					
					if ( f1->normalized.position.x > 0.05f && f1->normalized.position.x < 0.45f && f1->normalized.position.y > 0.20f && f1->normalized.position.y < 0.99f) {
						[self performGestureIfInZone:key name:target zones:z clear:YES];
						return;								
					}													
				}
			}				
		}
		
		//1 finger tap right enabled
		if ([key isEqualToString:@"10"]) {
			if ([[[taps objectForKey:@"1"] allKeysForObject:@"down"] count] > 0 && [[[taps objectForKey:@"1"] allKeysForObject:@"up"] count] > 0 ){
				if ([[taps objectForKey:@"2"] count] < 1 && [[taps objectForKey:@"3"] count] < 1 && [[taps objectForKey:@"4"] count] < 1 ) {						
					if ( f1->normalized.position.x > 0.55f && f1->normalized.position.x < 0.95f && f1->normalized.position.y > 0.20f && f1->normalized.position.y < 0.99f) {
						[self performGestureIfInZone:key name:target zones:z clear:YES];
						return;								
					}													
				}
			}				
		}	
		
		//1 finger tap tail enabled
		if ([key isEqualToString:@"11"]) {			
			if ([[[taps objectForKey:@"1"] allKeysForObject:@"down"] count] > 0 && [[[taps objectForKey:@"1"] allKeysForObject:@"up"] count] > 0 ){						
				if ([[taps objectForKey:@"2"] count] < 1 && [[taps objectForKey:@"3"] count] < 1 && [[taps objectForKey:@"4"] count] < 1 ) {						
					if ( f1->normalized.position.x > 0.25f && f1->normalized.position.x < 0.75f && f1->normalized.position.y < 0.19f) {
						[self performGestureIfInZone:key name:target zones:z clear:YES];
						return;								
					}													
				}
			}				
		}
		
	}//end taps
	
	if (movestop > 0){				
		//
		//NSLog(@"%f %f [%i]",velx,vely,movestop); //swipes
		//	
		int swipesens = 10-[[defaults objectForKey:@"tapSensMouse"] intValue]/2; //reversed
        if (swipesens < 1 ) swipesens = 1; //keep above 1
		
		//two finger
		if (fingers == 2) {		
			//two finger swipe left enabled
			if ([key isEqualToString:@"21"]) {
				if (velx < 0 && absint(vely) < absint(velx) && absint(velx) > swipesens){
					[self performGestureIfInZone:key name:target zones:z clear:NO];
					return;						
				}
			}
			//two finger swipe right enabled
			if ([key isEqualToString:@"22"]) {
				if (velx > 0 && absint(vely) < absint(velx) && absint(velx) > swipesens){
					[self performGestureIfInZone:key name:target zones:z clear:NO];
					return;														
				}	
			}	
			//two finger swipe up enabled
			if ([key isEqualToString:@"23"]) {
				if (vely > 0 && absint(vely) > absint(velx) && absint(vely) > swipesens){
					[self performGestureIfInZone:key name:target zones:z clear:NO];
					return;															
				}	
			}	
			//two finger swipe down enabled
			if ([key isEqualToString:@"24"]) {			
				if (vely < 0 && absint(vely) > absint(velx) && absint(vely) > swipesens){
					[self performGestureIfInZone:key name:target zones:z clear:NO];
					return;													
				}	
			}						
		}
		
		//three finger
		if (fingers == 3) {		
			//three finger swipe left enabled
			if ([key isEqualToString:@"25"]) {
				if (velx < 0 && absint(vely) < absint(velx) && absint(velx) > swipesens){
					[self performGestureIfInZone:key name:target zones:z clear:NO];
					return;							
				}
			}
			//three finger swipe right enabled
			if ([key isEqualToString:@"26"]) {	
				if (velx > 0 && absint(vely) < absint(velx) && absint(velx) > swipesens){
					[self performGestureIfInZone:key name:target zones:z clear:NO];
					return;															
				}	
			}	
			//three finger swipe up enabled
			if ([key isEqualToString:@"27"]) {
				if (vely > 0 && absint(vely) > absint(velx) && absint(vely) > swipesens){
					[self performGestureIfInZone:key name:target zones:z clear:NO];
					return;															
				}	
			}	
			//three finger swipe down enabled
			if ([key isEqualToString:@"28"]) {		
				if (vely < 0 && absint(vely) > absint(velx) && absint(vely) > swipesens){
					[self performGestureIfInZone:key name:target zones:z clear:NO];
					return;														
				}	
			}						
		}
		
		
		//
		//pinches
		//				
        
        if (fingers == 2) {
            //two finger pinch in enabled
            if ([key isEqualToString:@"33"]) {	
                if (pinch == 1){
                    [self performGestureIfInZone:key name:target zones:z clear:YES];
                    return;											
                }				
            }	
            
            //two finger pinch out enabled		
            if ([key isEqualToString:@"34"]) {	
                if (pinch == 2){
                    [self performGestureIfInZone:key name:target zones:z clear:YES];
                    return;											
                }				
            }            
        }
        
        if (fingers == 3) {
            //three finger pinch in enabled
            if ([key isEqualToString:@"35"]) {	
                if (pinch == 1){
                    [self performGestureIfInZone:key name:target zones:z clear:YES];
                    return;											
                }				
            }	
            
            //three finger pinch out enabled		
            if ([key isEqualToString:@"36"]) {
                if (pinch == 2){
                    [self performGestureIfInZone:key name:target zones:z clear:YES];
                    return;											
                }				
            }            
        }        
					
		
	}//end movestop	
	
	//drag
	//
	
	//drag tail left enabled
	if ([key isEqualToString:@"31"]) {						
		if (fingers == 1 && [[taps objectForKey:@"1"] count] > 0 && f1->normalized.position.x < 0.25f && f1->normalized.position.y < 0.2f) { 					
			if (velx < 0 && absint(vely) < absint(velx) && absint(velx) > 1 && vely >= -1){
				[self performGestureIfInZone:key name:target zones:z clear:YES];
				return;													
			}
		}		
	}	
	
	//drag tail right enabled
	if ([key isEqualToString:@"32"]) {									
		if (fingers == 1 && [[taps objectForKey:@"1"] count] > 0 && f1->normalized.position.x > 0.75f && f1->normalized.position.y < 0.2f) {												
			if (velx > 0 && absint(vely) < absint(velx) && absint(velx) > 1 && vely >= -1){	
				[self performGestureIfInZone:key name:target zones:z clear:YES];
				return;													
			}
		}		
	}	

	
}

-(void) gtrackpadClickGesture:(NSDictionary*)d key:(NSString*)key target:(NSString*)target zones:(NSDictionary*)z{
	
	
	if ([key isEqualToString:@"301"]) {					
		if (fingers == 2) {
			[self performGestureIfInZone:key name:target zones:z clear:NO];
			return;				
		}				
	}
	
	if ([key isEqualToString:@"302"]) {					
		if (fingers == 3) {
			[self performGestureIfInZone:key name:target zones:z clear:NO];
			return;
		}				
	}
	
	if ([key isEqualToString:@"303"]) {					
		if (fingers == 4) {
			[self performGestureIfInZone:key name:target zones:z clear:NO];
			return;	
		}				
	}
	
	if ([key isEqualToString:@"304"]) {					
		if (fingers == 5) {
			[self performGestureIfInZone:key name:target zones:z clear:NO];
			return;				
		}				
	}		
	
}

-(void) mtrackpadClickGesture:(NSDictionary*)d key:(NSString*)key target:(NSString*)target zones:(NSDictionary*)z{
	
	if ([key isEqualToString:@"201"]) {					
		if (fingers == 2) {
			[self performGestureIfInZone:key name:target zones:z clear:NO];
			return;
		}				
	}
	
	if ([key isEqualToString:@"202"]) {					
		if (fingers == 3) {
			[self performGestureIfInZone:key name:target zones:z clear:NO];
			return;
		}				
	}
	
	if ([key isEqualToString:@"203"]) {					
		if (fingers == 4) {
			[self performGestureIfInZone:key name:target zones:z clear:NO];
			return;
		}				
	}
	
	if ([key isEqualToString:@"204"]) {					
		if (fingers == 5) {
			[self performGestureIfInZone:key name:target zones:z clear:NO];
			return;
		}				
	}		
	
}

-(void) mmouseClickGesture:(NSDictionary*)d key:(NSString*)key target:(NSString*)target zones:(NSDictionary*)z{
	
	//1 finger axis click enabled
	if ([key isEqualToString:@"1"]) {				
		if (fingers == 1) {
			[self performGestureIfInZone:key name:target zones:z clear:NO];
			return;
		}				
	}	
	
	//2 finger click enabled
	if ([key isEqualToString:@"2"]) {			
		if (fingers == 2){
			[self performGestureIfInZone:key name:target zones:z clear:NO];
			return;							
		}				
	}			
	
	//3 finger click enabled
	if ([key isEqualToString:@"3"]) {			
		if (fingers == 3){	
			[self performGestureIfInZone:key name:target zones:z clear:NO];
			return;													
		}				
	}	
	
	//4 finger click enabled
	if ([key isEqualToString:@"4"]) {			
		if (fingers == 4){		
			[self performGestureIfInZone:key name:target zones:z clear:NO];
			return;														
		}				
	}	
	
}


//clicks callback
CGEventRef clickCallBack(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void* refcon){	
	
	Events *obj = (Events *) refcon;
	CGEventRef ret = [obj newClickCallBack:event type:type];
	obj.lastCGEvent = NULL;
	return ret;
	
}	

//clicks callback
-(CGEventRef) newClickCallBack:(CGEventRef)event type:(CGEventType)type{
	
	//check thread
	if (![NSThread isMainThread]){
		NSLog(@"clickCallBack called outside main thread: %@", [NSThread currentThread]);
		return NULL;		
	}		
	
	newCGEvent = NULL;	
	lastCGEvent = event;
	
	
	//handle unstandard types
	if (type == kCGEventTapDisabledByTimeout) {
		//NSLog(@"kCGEventTapDisabledByTimeout");
		if (eventTap) {
			if (!CGEventTapIsEnabled(eventTap)) {
				//NSLog(@"kCGEventTapDisabledByTimeout, Enabling Event Tap");
				CGEventTapEnable(eventTap, true);
			}
		}
		return event;		
	}	
	if (type == kCGEventTapDisabledByUserInput) {
		//NSLog(@"kCGEventTapDisabledByUserInput");
		if (eventTap) {
			if (!CGEventTapIsEnabled(eventTap)) {
				//NSLog(@"kCGEventTapDisabledByUserInput, Enabling Event Tap");
				CGEventTapEnable(eventTap, true);
			}
		}
		return event;
	}		
	
	//notify if pref pane was deleted since start
	if (type == kCGEventLeftMouseUp){	
        if (notifiedOfPrefpaneDeletion == NO){
            NSString *copyTo = [NSString stringWithFormat:@"%@/Library/PreferencePanes/MagicPrefs.prefPane",NSHomeDirectory()];
            if (![[NSFileManager defaultManager] fileExistsAtPath:copyTo]) {
                notifiedOfPrefpaneDeletion = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"PrefPaneDeleted" userInfo:nil]; 		                
            }            
        }
    }    		
	
	//skip clicks/scrolls with old touches	
	float interval = CFAbsoluteTimeGetCurrent() - lastTouchTime;
	if (type == kCGEventScrollWheel){	
		if (interval > 5) {
			//NSLog(@"Ignoring scroll from unhandled device, too old touch (%f sec)",interval);			
			return event;
		}			
	}else if (type == kCGEventLeftMouseDown || type == kCGEventRightMouseDown || type == kCGEventLeftMouseUp || type == kCGEventRightMouseUp){		
		if (interval > 5) {
			//NSLog(@"Ignoring click from unhandled device, too old touch (%f sec)",interval);			
			return event;
		}		
	}	  
    
    if (type == kCGEventMouseMoved){         
        //drop mevements
        if ([lastTouchedDev isEqualToString:@"gt"] || [lastTouchedDev isEqualToString:@"mt"]) {
            if (tpointer != YES) {
                CGWarpMouseCursorPosition(lastMousePos); 
                return event;
            }    
        }
        //send to gatherer      
        if ([defaults boolForKey:@"gatherStatistics"] == YES) [gatherer cursor:lastTouchedDev fingers:fingers];
        //save last one
        lastMousePos = mousePos();
    }
    
    if (type == kCGEventScrollWheel){
        //send to gatherer
        if ([defaults boolForKey:@"gatherStatistics"] == YES) [gatherer scroll:lastTouchedDev fingers:fingers];  

        //mm stuff, must be before other stuff
        if ([lastTouchedDev isEqualToString:@"mm"]) {
            //never disable scrolling in mmenu nor invert it
            if (mmshown) {						
                return event;	
            }		
            //disable scroll while finger cursor
            if (mpointer){						
                return NULL;				
            }
            //disable scrolling on demand
            if (tscrolling != YES){
                return NULL;
            }
            //check scroll zone
            NSDictionary *scrollzone = [self loadPrefs:@"scrollzone"];		
            if ([self isinZone:scrollzone] == NO) {
                //NSLog(@"scroll out of zone");																			
                return NULL;						
            }		
            //apply axis settings
            NSDictionary *scrolling = [self loadPrefs:@"scrolling"];            
            NSString *setting = nil;
            if (fingers == 1) setting = [scrolling objectForKey:@"one finger"];
            if (fingers == 2) setting = [scrolling objectForKey:@"two finger"];
            if (fingers == 3) setting = [scrolling objectForKey:@"three finger"];	
            if (fingers == 4) setting = [scrolling objectForKey:@"four finger"];
            //double vscrollChange = CGEventGetDoubleValueField(event, kCGScrollWheelEventFixedPtDeltaAxis1);
            //double hscrollChange = CGEventGetDoubleValueField(event, kCGScrollWheelEventFixedPtDeltaAxis2);             
            double vscroll = CGEventGetDoubleValueField(event, kCGScrollWheelEventPointDeltaAxis1);
            double hscroll = CGEventGetDoubleValueField(event, kCGScrollWheelEventPointDeltaAxis2);            
            if (setting != nil) {                
                if (vscroll == 0 && hscroll == 0) {
                    //empty scroll, probably a end marker
                }else{
                    if ([setting isEqualToString:@"Both axes"]) {
                        //NSLog(@"no change, legacy value for "Diagonal,Vertical,Horizontal" %@",setting);
                        return event;                    
                    }                
                    if ([setting rangeOfString:@"Diagonal"].location == NSNotFound){
                        if (vscroll != 0 && hscroll != 0){
                            //NSLog(@"skipped diagonal %i finger scroll %f %f",fingers,vscroll,hscroll); 									
                            return NULL;	                        
                        }               
                    }
                    if ([setting rangeOfString:@"Vertical"].location == NSNotFound){
                        if ( fabs(vscroll) > 0 && hscroll == 0) {															
                            //NSLog(@"skipped vertical %i finger scroll %f",fingers,vscroll);										
                            return NULL;					
                        }                      
                    }
                    if ([setting rangeOfString:@"Horizontal"].location == NSNotFound){
                        if ( fabs(hscroll) > 0 && vscroll == 0) {															
                            //NSLog(@"skipped horizontal %i finger scroll %f",fingers,hscroll);										
                            return NULL;					
                        }                      
                    }                     
                }
            }     		
        }
        
        //inverse scroolling
        if ([defaults boolForKey:@"inverseScrolling"] == YES) {
            [self invertScrolling:event];
        }          
        
    }  
    	
	if (type == kCGEventFlagsChanged){		
		//caps lock notification enabled	
		BOOL caps = [defaults boolForKey:@"notifCapsLock"];		
		if (caps) {
			if ((CGEventGetFlags(event) & kCGEventFlagMaskAlphaShift) != 0 && [[NSEvent eventWithCGEvent:event] keyCode] == 57){			
				//NSLog(@"caps on notification shown");	
				[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:
				 [NSDictionary dictionaryWithObjectsAndKeys:@"doNotif",@"what",@"caps",@"image",@"CapsLock Enabled",@"text",nil]
				 ];					
			} 
			if ((CGEventGetFlags(event) & kCGEventFlagMaskAlphaShift) == 0 && [[NSEvent eventWithCGEvent:event] keyCode] == 57){			
				//NSLog(@"caps off notification shown");	
				[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:
				 [NSDictionary dictionaryWithObjectsAndKeys:@"doNotif",@"what",@"caps",@"image",@"CapsLock Disabled",@"text",nil]
				 ];					
			}				
		}							
		return event;			
	}			
	
	//send notification of click
    if (type == kCGEventLeftMouseDown || type == kCGEventRightMouseDown || type == kCGEventLeftMouseUp || type == kCGEventRightMouseUp){
        //send to gatherer
        if ([defaults boolForKey:@"gatherStatistics"] == YES) [gatherer click:lastTouchedDev fingers:fingers];        
        //send to live if enabled
        if ( ([defaults boolForKey:@"LiveMouse"] && [lastTouchedDev isEqualToString:@"mm"]) || 
            ([defaults boolForKey:@"LiveTrackpad"] && [lastTouchedDev isEqualToString:@"mt"] ) ||
            ([defaults boolForKey:@"LiveMacbook"] && [lastTouchedDev isEqualToString:@"gt"] ) )
        {            
			//NSLog(@"event with %i fingers",fingers);	
			NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"click",@"what",
									lastTouchedDev,@"back",
									[NSString stringWithFormat:@"%i",type],@"type",
									[NSString stringWithFormat:@"%f",CGEventGetLocation(event).x],@"posx",								
									[NSString stringWithFormat:@"%f",CGEventGetLocation(event).y],@"posy",									
									nil];			
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneImgEvent" object:@"remote" userInfo:object deliverImmediately:YES];
        }	 
        
    }    
		
	if (type == kCGEventLeftMouseDown || type == kCGEventRightMouseDown){
        //should not have a mouse down while skipNextClickUp is true but just in case
        if (skipNextClickUp){
            skipNextClickUp = NO;
        }        
        //if a new event was generated return it, else drop the click down and the following click up
		performedGesture = NO;
		[self loopPrefsType:@"click" tapon:0 tapoff:0 movestop:0 pinch:0 rotate:0 f1:NULL];
		if (performedGesture) {
			performedGesture = NO;
			if (newCGEvent)	{
                //click up handling is managed by holding.. boleans
				return newCGEvent;		
			}else {
                skipNextClickUp = YES;
				return NULL;
			}			
		}	
	}	   	
	
	//release previous click no matter how many fingers touching or config setting
	if (type == kCGEventLeftMouseUp || type == kCGEventRightMouseUp){	
		if (holdingcmd) {
			//NSLog(@"releasing Cmd]]");		
			CGEventSourceRef source = CGEventSourceCreate (kCGEventSourceStatePrivate);			
			CGEventRef ev = CGEventCreateKeyboardEvent(source, 55, NO);		
			CGEventPost(kCGHIDEventTap, ev);			
			CFRelease(ev);		
			CFRelease(source);
			holdingcmd = NO;			
		}		
		if (holdingalt) {
			//NSLog(@"releasing Alt]]");
			CGEventSourceRef source = CGEventSourceCreate (kCGEventSourceStatePrivate);				
			CGEventRef ev = CGEventCreateKeyboardEvent(source, 61, NO);		
			CGEventPost(kCGHIDEventTap, ev);			
			CFRelease(ev);		
			CFRelease(source);
			holdingalt = NO;			
		}
		if (holdingshift) {
			//NSLog(@"releasing Shift]]");
			CGEventSourceRef source = CGEventSourceCreate (kCGEventSourceStatePrivate);				
			CGEventRef ev = CGEventCreateKeyboardEvent(source, 56, NO);		
			CGEventPost(kCGHIDEventTap, ev);			
			CFRelease(ev);		
			CFRelease(source);
			holdingshift = NO;			
		}        
		if (holdingctrl) {
			//NSLog(@"releasing Ctrl]]");
			CGEventSourceRef source = CGEventSourceCreate (kCGEventSourceStatePrivate);				
			CGEventRef ev = CGEventCreateKeyboardEvent(source, 59, NO);		
			CGEventPost(kCGHIDEventTap, ev);			
			CFRelease(ev);		
			CFRelease(source);
			holdingctrl = NO;			
		}                
		if (holdingLR){
			//NSLog(@"releasing Left&Right]]");			
			CGEventRef ev;		
			
			ev = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, CGEventGetLocation(event), kCGMouseButtonLeft);				
			CGEventPost(kCGSessionEventTap,ev);		
			CFRelease(ev);
            
			ev = CGEventCreateMouseEvent(NULL, kCGEventRightMouseUp, CGEventGetLocation(event), kCGMouseButtonRight);				
			CGEventPost(kCGSessionEventTap,ev);			
			CFRelease(ev);            
			
			holdingLR = NO;					
			return NULL;		
		}        
		if (holdingRL){
			//NSLog(@"releasing Right&Left]]");			
			CGEventRef ev;
				
			ev = CGEventCreateMouseEvent(NULL, kCGEventRightMouseUp, CGEventGetLocation(event), kCGMouseButtonRight);				
			CGEventPost(kCGSessionEventTap,ev);			
			CFRelease(ev);			
			
			ev = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, CGEventGetLocation(event), kCGMouseButtonLeft);				
			CGEventPost(kCGSessionEventTap,ev);		
			CFRelease(ev);
			
			holdingRL = NO;					
			return NULL;		
		}
		if (holdingLM){
			//NSLog(@"releasing Left&Middle]]");			
			CGEventRef ev;		
			
			ev = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, CGEventGetLocation(event), kCGMouseButtonLeft);				
			CGEventPost(kCGSessionEventTap,ev);		
			CFRelease(ev);
            
			ev = CGEventCreateMouseEvent(NULL, kCGEventOtherMouseUp, CGEventGetLocation(event), kCGMouseButtonCenter);				
			CGEventPost(kCGSessionEventTap,ev);			
			CFRelease(ev);            
			
			holdingLM = NO;					
			return NULL;		
		}        
		if(holdinglf){
			//NSLog(@"left mouse up]]");				
			CGEventRef newEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, CGEventGetLocation(event), kCGMouseButtonLeft);
            int count = CGEventGetIntegerValueField(event, kCGMouseEventClickState);
            CGEventSetIntegerValueField(newEvent, kCGMouseEventClickState, count);            
			holdinglf = NO;		
			return newEvent;				
		}
		if(holdingrf){
			//NSLog(@"right mouse up]]");				
			CGEventRef newEvent = CGEventCreateMouseEvent(NULL, kCGEventRightMouseUp, CGEventGetLocation(event), kCGMouseButtonRight);	
            int count = CGEventGetIntegerValueField(event, kCGMouseEventClickState);
            CGEventSetIntegerValueField(newEvent, kCGMouseEventClickState, count);             
			holdingrf = NO;		
			return newEvent;				
		}
		if(holdingmf){
			//NSLog(@"middle mouse up]]");				
			CGEventRef newEvent = CGEventCreateMouseEvent(NULL, kCGEventOtherMouseUp, CGEventGetLocation(event), kCGMouseButtonCenter);
            int count = CGEventGetIntegerValueField(event, kCGMouseEventClickState);
            CGEventSetIntegerValueField(newEvent, kCGMouseEventClickState, count);             
			holdingmf = NO;		
			return newEvent;				
		}	
        //if click down was dropped also drop the click up 
        if (skipNextClickUp){
            skipNextClickUp = NO;
            return NULL;
        }        
	}	
    
    int64_t onehundredone = CGEventGetIntegerValueField(event,101);
    if (type == 0 && onehundredone != 4) {      
        NSLog(@"Weird event type 0 subtype %lld",onehundredone);
    }
        		
    //NSLog(@"DO NOT BREAKPOINT THIS");	
	//NSLog(@"Returning event type (%i) unmodified.",type);	
	return event;
}

-(void)loopPrefsType:(NSString*)type tapon:(int)tapon tapoff:(int)tapoff movestop:(int)movestop pinch:(int)pinch rotate:(int)rotate f1:(Touch*)f1{
	
	//loop prefs bindings and perform the enabled ones if the conditions match	
	NSMutableDictionary *dict = [[self loadPrefs:@"bindings"] mutableCopy];
	
	//Magic Menu hardcoded insert replacing existing binding
	NSDictionary *mm_settings = [[pluginDefaults objectForKey:@"MagicMenu"] objectForKey:@"settings"];			
	BOOL enabled = [[[pluginDefaults objectForKey:@"MagicMenu"] objectForKey:@"enabled"] boolValue];    
	BOOL disabled = [[mm_settings objectForKey:@"mm_Disabled"] boolValue];   
	NSString *trigger = [mm_settings objectForKey:@"mm_Trigger"];
	NSArray	*arr = [mm_settings objectForKey:@"mm_presetApps"];
	for (id app in arr){
		if ([[app objectForKey:@"value"] isEqualToString:activeAppID]) {	
			disabled = [[[[mm_settings objectForKey:@"mm_presets"] objectForKey:[app objectForKey:@"type"]] objectForKey:@"mm_Disabled"] boolValue];
			trigger = [[[mm_settings objectForKey:@"mm_presets"] objectForKey:[app objectForKey:@"type"]] objectForKey:@"mm_Trigger"];
		}
	}	
	if (disabled == NO && enabled == YES) {		
		if ([type isEqualToString:@"touch"]) {
			if ([trigger isEqualToString:@"Tap the apple stem"]) [dict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Magic Menu",@"target",@"1",@"state",nil] forKey:@"11"];
			if ([trigger isEqualToString:@"Tap with 3 fingers"]) [dict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Magic Menu",@"target",@"1",@"state",nil] forKey:@"7"];							
		}
		if ([type isEqualToString:@"click"]) {
			if ([trigger isEqualToString:@"One Finger Middle Axis Click"]) [dict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Magic Menu",@"target",@"1",@"state",nil] forKey:@"1"];
			if ([trigger isEqualToString:@"Three Finger Click"]) [dict setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Magic Menu",@"target",@"1",@"state",nil] forKey:@"3"];						
		}
	}	
	
	//get zones
    NSDictionary *z;
	float interval = CFAbsoluteTimeGetCurrent() - lastZonesCacheTime;
	if (interval > 2.5 && cachedZones != nil) {
        z = [self loadPrefs:@"zones"];
        [cachedZones setDictionary:z];
        lastZonesCacheTime = CFAbsoluteTimeGetCurrent();               
    }else{
        z = cachedZones;
    }
	
	//start loop
	for (id key in dict){
		NSDictionary *d = [dict objectForKey:key];
		NSString *target = [d objectForKey:@"target"];		
		if ([[d objectForKey:@"state"] intValue] == 1 && ![target isEqualToString:@"N/A"]){						
			
			if ([key intValue] > 300 && [key intValue] < 400) {
				//Macbook Trackpad prefs
				if ([lastTouchedDev isEqualToString:@"gt"]) {
					if ([type isEqualToString:@"touch"]) {
						[self gtrackpadTouchGesture:d key:key target:target zones:z tapon:tapon tapoff:tapoff movestop:movestop pinch:pinch rotate:rotate f1:f1];						
					}
					if ([type isEqualToString:@"click"]) {
						[self gtrackpadClickGesture:d key:key target:target zones:z];
					}						
				}
			} else if ([key intValue] > 200 && [key intValue] < 300) {
				//Magic Trackpad prefs
				if ([lastTouchedDev isEqualToString:@"mt"]) {
					if ([type isEqualToString:@"touch"]) {
						[self mtrackpadTouchGesture:d key:key target:target zones:z tapon:tapon tapoff:tapoff movestop:movestop pinch:pinch rotate:rotate f1:f1];
					}
					if ([type isEqualToString:@"click"]) {
						[self mtrackpadClickGesture:d key:key target:target zones:z];
					}                   
				}	
			}else if ([key intValue] > 0 && [key intValue] < 100) {
				//Magic Mouse prefs				
				if ([lastTouchedDev isEqualToString:@"mm"]) {
					if ([type isEqualToString:@"touch"]) {
						[self mmouseTouchGesture:d key:key target:target zones:z tapon:tapon tapoff:tapoff movestop:movestop pinch:pinch rotate:rotate f1:f1];
					}
					if ([type isEqualToString:@"click"]) {
						[self mmouseClickGesture:d key:key target:target zones:z];						
					}										
				}	
			}else {
				NSLog(@"Gesture for key %@ unknown",key);
			}
		}		
	}
	[dict release];		
}


#pragma mark startup methods

//tap clicks
-(void) tap_start{
	if (mmouseDev == NULL && mtrackpadDev == NULL && gtrackpadDev == NULL) {
		//NSLog(@"No device(s), will not tap in vain.");		
		return;
	}
	if (eventTap == NULL){
		CGEventMask mask = CGEventMaskBit(kCGEventLeftMouseDown) | CGEventMaskBit(kCGEventLeftMouseUp) | CGEventMaskBit(kCGEventRightMouseDown) | CGEventMaskBit(kCGEventRightMouseUp)| CGEventMaskBit(kCGEventScrollWheel) | CGEventMaskBit(kCGEventFlagsChanged) | CGEventMaskBit(kCGEventMouseMoved);        
		eventTap = CGEventTapCreate(kCGHIDEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, mask, clickCallBack, self);
		if(eventTap){	
			runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
			if (runLoopSource){
				CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop],runLoopSource, kCFRunLoopCommonModes);		
				CGEventTapEnable(eventTap, true);	
				NSLog(@"Event tap created %p",eventTap);				
			}else{
				CFRelease(eventTap);
				eventTap = NULL;
			}	
		}else{
			NSBeep();			
			NSLog(@"Failed to create event tap");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMenuEvent" object:@"IconERR" userInfo:nil];			
		}		
	}else{
		//NSLog(@"Tap allready running , will not start a new one");		
	}
}

-(void) tap_stop{
	if (mmouseDev || mtrackpadDev || gtrackpadDev) {
		//NSLog(@"Device(s) are still available, will not stop tapping yet");		
		return;
	}
	if (eventTap) {
		if (CGEventTapIsEnabled(eventTap)) {
			CGEventTapEnable(eventTap, false);
			CFMachPortInvalidate(eventTap);			
			if (CFRunLoopContainsSource([[NSRunLoop currentRunLoop] getCFRunLoop], runLoopSource, kCFRunLoopCommonModes)) {
				CFRunLoopRemoveSource([[NSRunLoop currentRunLoop] getCFRunLoop], runLoopSource, kCFRunLoopCommonModes);
			}
			CFRunLoopSourceInvalidate(runLoopSource);			
			NSLog(@"No more devices left, tap destroyed.");			
		}		
		if (eventTap != NULL) CFRelease(eventTap);
		if (runLoopSource != NULL) CFRelease(runLoopSource);
		eventTap = NULL;
		runLoopSource = NULL;
	}else{
		//NSLog(@"Tap not running, nothing to stop");		
	}		
}

-(NSString*) mtdevice_info:(MTDeviceRef)mtDevice what:(NSString*)what
{
    NSString *name = (NSString*)mt_CreateSavedNameForDevice(mtDevice);
    if (name) {
        NSArray *parts = [name componentsSeparatedByString:@","];
        if ([parts count] == 2) {
            NSString *guid = [parts objectAtIndex:0];
            if ([what isEqualToString:@"guid"]) {
                return guid;
            }
            NSString *type = [parts objectAtIndex:1];
            if ([what isEqualToString:@"type"]) {
                if ([type rangeOfString:@"0x6"].location != NSNotFound) { //known 0x63 0x64
                    return @"gt";
                }else if ([type rangeOfString:@"0x7"].location != NSNotFound) { //known 0x70
                    return @"mm";
                }else if ([type isEqualToString:@"0x80"]) {
                    return @"mt";
                }else if ([type isEqualToString:@"0x81"]) {
                    return @"mt2";
                }else {
                    NSLog(@"Unknown device type %@",type);
                }
            }
        }
    }
    CFStringRef desc = CFCopyDescription(mtDevice);
    NSLog(@"Error getting %@ for %@",what,desc);
    CFRelease(desc);
    return nil;
}

-(void) mtdevices_init
{
	//get devices list	
	NSArray *deviceList = (NSArray*)MTDeviceCreateList();
	for (id device in deviceList){
		NSString *type = [self mtdevice_info:device what:@"type"];
        
		if ([type isEqualToString:@"gt"] || [type isEqualToString:@"gt2"])
        {
            gtrackpadDev = device;
            CFRetain(device);
            NSLog(@"init %@ %p",type,gtrackpadDev);
		}
        else if ([type isEqualToString:@"mt"])
        {
            mtrackpadDev = device;				
            CFRetain(device);
            NSLog(@"init %@ %p",type,mtrackpadDev);
        }
        else if ([type isEqualToString:@"mt2"])
        {
            mtrackpadDev = device;
            CFRetain(device);
            NSLog(@"init %@ %p",type,mtrackpadDev);
		}
        else if ([type isEqualToString:@"mm"] || [type isEqualToString:@"mm2"])
        {
			mmouseDev = device;	
			CFRetain(device);
            NSLog(@"init %@ %p",type,mmouseDev);
		}	
	}	
	
	if (retry == 0 && [deviceList count] > 0){
		if (gtrackpadDev) {
			[defaults setBool:NO forKey:@"noGlassTrackpad"];
			[defaults synchronize];	
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneMainEvent" object:@"deviceToggle" userInfo:[NSDictionary dictionaryWithObject:@"2" forKey:@"index"]];			
			NSLog(@"+MacBook Glass Trackpad found");		
		}else {		
			[defaults setBool:YES forKey:@"noGlassTrackpad"];
			[defaults synchronize];	
			//NSLog(@"-No MacBook Glass Trackpad found");
		}		
	}
	 
	//check count
	if ([deviceList count] > 3) {					
		CFShow(deviceList);	
		NSLog(@"*Number of devices over 3.");		
	} else if ([deviceList count] == 0) {	
		NSLog(@"*Number of devices is zero.");		
	}
	
	BOOL fewDevices = NO;
	if (gtrackpadDev) {
		if ([deviceList count] == 1) fewDevices = YES;	
		if ([deviceList count] < btdevices+1) fewDevices = YES;		
	}else {
		if ([deviceList count] == 0) fewDevices = YES;		
		if ([deviceList count] < btdevices) fewDevices = YES;		
	}
	
	//release
	[deviceList release];		
	
	if (fewDevices == NO) {
		if (mmouseDev) {
			//CFStringRef mmouseRef = CFCopyDescription(mmouseDev);
			//NSLog(@"Magic Mouse device device ref created %@.",mmouseRef);
			//CFRelease(mmouseRef);
		}
		if (mtrackpadDev) {
			//CFStringRef mtrackpadRef = CFCopyDescription(mtrackpadDev);
			//NSLog(@"Magic Trackpad device ref created %@.",mtrackpadRef);
			//CFRelease(mtrackpadRef);
		}
		if (gtrackpadDev) {
			//CFStringRef gtrackpadRef = CFCopyDescription(gtrackpadDev);
			//NSLog(@"Glass Trackpad device ref created %@.",gtrackpadRef);
			//CFRelease(gtrackpadRef);
		}		
	}else if (btdevices > 0){
		if (retry < retryAttempts){	
			retry += 1;
			NSLog(@"Not all %i devices found in the multitouch driver, retrying in 1 sec (%i of %i)",btdevices,retry,retryAttempts);            
            [NSThread sleepForTimeInterval:1];
            [self mtdevices_init];				
		}else {
   			NSBeep();
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMenuEvent" object:@"IconERR" userInfo:nil];			
			NSLog(@"Gave up trying to pool the %i connected devices in the multitouch driver after %i retries.",btdevices,retryAttempts);	
		}	
	}	
}

// Start handling multitouch events
-(void) mtdevice_start:(MTDeviceRef)dev
{
	BOOL disabled = [defaults boolForKey:@"isDisabled"];	
	if (disabled) {
		NSLog(@"Magicprefs is disabled, will not start device.");
		return;
	}	
	if (dev != NULL){	
		CFStringRef desc = CFCopyDescription(dev);		
		NSLog(@"++Started tracking device %@.",desc);			
		CFRelease(desc);									
		//growl notification
		if (dev == mmouseDev) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:
             [NSDictionary dictionaryWithObjectsAndKeys:@"doGrowl",@"what",
              @"+Magic Mouse",@"title",
              @"MagicPrefs engaged for the Magic Mouse.",@"message",nil]
             ];
            //sync speed 
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"SyncSpeed" userInfo:nil];	            
            //assign callback for device            
			MTRegisterContactFrameCallback(dev, mmouseTouchCallback);			
		}
		if (dev == mtrackpadDev) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:
             [NSDictionary dictionaryWithObjectsAndKeys:@"doGrowl",@"what",
              @"+Magic Trackpad",@"title",
              @"MagicPrefs engaged for the Magic Trackpad.",@"message",nil]
             ];
            //sync speed 
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"SyncSpeed" userInfo:nil];            
            //assign callback for device            
			MTRegisterContactFrameCallback(dev, mtrackpadTouchCallback);			
		}	
		if (dev == gtrackpadDev) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:
             [NSDictionary dictionaryWithObjectsAndKeys:@"doGrowl",@"what",
              @"+Internal Trackpad",@"title",
              @"MagicPrefs engaged for the internal trackpad.",@"message",nil]
             ];			
            //assign callback for device            
			MTRegisterContactFrameCallback(dev, gtrackpadTouchCallback);			
		}		
		MTDeviceStart(dev,0);  //start sending events		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMenuEvent" object:@"IconON" userInfo:nil];			
	}else {
		//this should never happen as mtdevice_init is almost guaranteed to keep retrying until it finds the devices
		NSBeep();
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMenuEvent" object:@"IconERR" userInfo:nil];			
		NSLog(@"mtdevice start was attempted with no device.");
	}	
    [taps removeAllObjects]; //reset taps to clear orphaned leftovers 
}

// Stop handling multitouch events
-(void) mtdevice_stop:(MTDeviceRef)dev
{	
	if (dev != NULL){	
		CFStringRef desc = CFCopyDescription(dev);		
		NSLog(@"--Stopped tracking device %@.",desc);			
		CFRelease(desc);				
		//growl notification		
		if (dev == mmouseDev) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:
             [NSDictionary dictionaryWithObjectsAndKeys:@"doGrowl",@"what",
              @"-Magic Mouse",@"title",
              @"MagicPrefs disengaged for the Magic Mouse.",@"message",nil]
             ];
			MTUnregisterContactFrameCallback(dev, mmouseTouchCallback); //unassign callback for device
			MTDeviceStop(dev); //stop sending events			
			MTDeviceRelease(dev);
			mmouseDev = NULL;
			//restore speed
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"RestoreMouseSpeed" userInfo:nil];								
		}
		if (dev == mtrackpadDev) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:
             [NSDictionary dictionaryWithObjectsAndKeys:@"doGrowl",@"what",
              @"-Magic Trackpad",@"title",
              @"MagicPrefs disengaged for the Magic Trackpad.",@"message",nil]
             ];			
			MTUnregisterContactFrameCallback(dev, mtrackpadTouchCallback); //unassign callback for device
			MTDeviceStop(dev); //stop sending events			
			MTDeviceRelease(dev);	
			mtrackpadDev = NULL;
			//restore speed
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"RestoreTrackpadSpeed" userInfo:nil];			
		}
		if (dev == gtrackpadDev) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:
         [NSDictionary dictionaryWithObjectsAndKeys:@"doGrowl",@"what",
          @"-Internal Trackpad",@"title",
          @"MagicPrefs disengaged for the internal Trackpad.",@"message",nil]
         ];
			MTUnregisterContactFrameCallback(dev, gtrackpadTouchCallback); //unassign callback for device							
			MTDeviceStop(dev); //stop sending events			
			MTDeviceRelease(dev);
			gtrackpadDev = NULL;		
		}					
		if (mmouseDev == NULL && mtrackpadDev == NULL && gtrackpadDev == NULL) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMenuEvent" object:@"IconOFF" userInfo:nil];				
		}
	}else {
		NSBeep();        
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMenuEvent" object:@"IconERR" userInfo:nil];        
		NSLog(@"mtdevice stop was attempted with no device.");		
	}	
    [taps removeAllObjects]; //reset taps to clear orphaned leftovers    
}

#pragma mark bluetooth

-(BOOL) pairedCheck{
    NSArray *devices = [IOBluetoothDevice pairedDevices];
    int mmouseCount = 0;
    int mtrackpadCount = 0;
    for (IOBluetoothDevice *device in devices){
        if ([device getLastServicesUpdate]) {
            
            if (![device name]) [device remoteNameRequest:nil];
            if (![device name]) {
                NSLog(@"No device name for %@",[device nameOrAddress]);
            }
            
            if ([self isMagicMouse:device]) {
                NSLog(@"      named '%@' at %@ with (root %i) (minor %i) (major %i)",[device name],[device addressString],[device classOfDevice],[device deviceClassMinor],[device deviceClassMajor]);
                mmouseCount +=1;
            }
            
            if ([self isMagicTrackpad:device]) {
                NSLog(@"      named '%@' at %@ with (root %i) (minor %i) (major %i)",[device name],[device addressString],[device classOfDevice],[device deviceClassMinor],[device deviceClassMajor]);
                mtrackpadCount +=1;
            }
            
        }else {
            //NSLog(@"No service update for %@",[device nameOrAddress]);
        }
    }
    
    if (mmouseCount == 1) {
        //NSLog(@"Found one Magic Mouse paired OK.");
    } else if (mmouseCount == 0) {
        //NSLog(@"There is no Magic Mouse paired on this machine");
    } else {
        NSLog(@"There are multiple Magic Mice paired on this machine");
    }
    
    if (mtrackpadCount == 1) {
        //NSLog(@"Found one Magic Trackpad paired OK.");
    } else if (mtrackpadCount == 0) {
        NSLog(@"There is no Magic Trackpad paired on this machine");
     } else {
        NSLog(@"There are multiple Magic Trackpads paired on this machine");
    }
    
    if (mmouseCount == 0 && mtrackpadCount == 0) {
        return NO;
    }
    
    return YES;
}


- (BOOL)isMagicMouse:(IOBluetoothDevice *)device
{
    //MOUSE
    //kBluetoothSDPAttributeDeviceIdentifierVendorID    273 1452
    //kBluetoothSDPAttributeDeviceIdentifierProductID   128 781
    //TRACKPAD
    //kBluetoothSDPAttributeDeviceIdentifierVendorID    273 1452 76
    //kBluetoothSDPAttributeDeviceIdentifierProductID   148 782 613
    
    if (![device getLastServicesUpdate]) {
        NSLog(@"No service update, can not determine device type");
        return NO;
    }
    
    for (IOBluetoothSDPServiceRecord *record in [device services]){
        if ([record getServiceName]){
            NSDictionary *attrs = [record attributes];
            NSString *model = [record getServiceName]; //or [[attrs objectForKey:[NSNumber numberWithLong:0x0100]] getStringValue];
            NSString *class = [[attrs objectForKey:[NSNumber numberWithLong:0x0101]] getStringValue];
            NSString *apple = [[attrs objectForKey:[NSNumber numberWithLong:0x0102]] getStringValue];
            if (model && [apple isEqualToString:@"Apple Inc."]) {
                if ([class isEqualToString:@"Mouse"] || [class isEqualToString:@"Apple Wireless Mouse"] || [class isEqualToString:@"Apple Magic Mouse"] ){
                    NSLog(@"Found paired %@",model);
                    return YES;
                }
            }
        }
        
    }
    return NO;
}

- (BOOL)isMagicTrackpad:(IOBluetoothDevice *)device
{
    
    NSString *name = [self getMagicTrackpadName:device];
    
    if (!name) return NO;
    
    if ([name isEqualToString:@"Magic Trackpad 2"]) {
        return YES;
    }
    
    if ([name isEqualToString:@"Apple Wireless Trackpad"] || [name isEqualToString:@"Apple Magic Trackpad"]) {
        return YES;
    }
    
    return NO;
}

- (NSString*)getMagicTrackpadName:(IOBluetoothDevice *)device
{
    
    if (![device getLastServicesUpdate]) {
        NSLog(@"No service update, can not determine device type");
        return nil;
    }
    
    for (IOBluetoothSDPServiceRecord *record in [device services]){
        if ([record getServiceName]){
            NSDictionary *attrs = [record attributes];
            NSString *model = [record getServiceName]; //or [[attrs objectForKey:[NSNumber numberWithLong:0x0100]] getStringValue];
            NSString *class = [[attrs objectForKey:[NSNumber numberWithLong:0x0101]] getStringValue];
            NSString *apple = [[attrs objectForKey:[NSNumber numberWithLong:0x0102]] getStringValue];
            if (model && [apple isEqualToString:@"Apple Inc."]) {
                if ([class isEqualToString:@"Trackpad"] || [class isEqualToString:@"Apple Wireless Trackpad"] || [class isEqualToString:@"Apple Magic Trackpad"] ){
                    NSLog(@"Found paired %@",model);
                    return model;
                }
            }
        }
        
    }
    return nil;
}

- (void)bluetoothDidConnect:(IOBluetoothUserNotification *)aNotification device:(IOBluetoothDevice *)device {
	if ([self isMagicMouse:device] == YES){		
		NSLog(@"+%@ connected",[device nameOrAddress]);		
		[device registerForDisconnectNotification:self selector:@selector(bluetoothDisconnected:device:)];
        [NSThread sleepForTimeInterval:1.0]; //give the device 1 second to load into driver, if BluetoothSystemWakeEnable is off it will be slow
		[defaults setBool:NO forKey:@"noMouse"];
		[defaults synchronize];			
		btdevices +=1;		
		retry = 0;	
		if (mmouseDev == NULL) [self mtdevices_init];
		[self mtdevice_start:mmouseDev];
		[self tap_start];							
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneMainEvent" object:@"deviceToggle" userInfo:[NSDictionary dictionaryWithObject:@"0" forKey:@"index"]];				
	}
	if ([self isMagicTrackpad:device] == YES){
		NSLog(@"+%@ connected",[device nameOrAddress]);		
		[device registerForDisconnectNotification:self selector:@selector(bluetoothDisconnected:device:)];
        [NSThread sleepForTimeInterval:1.0]; //give the device 1 second to load into driver, if BluetoothSystemWakeEnable is off it will be slow        
		[defaults setBool:NO forKey:@"noTrackpad"];
		[defaults synchronize];			
		btdevices +=1;		
		retry = 0;	
		if (mtrackpadDev == NULL) [self mtdevices_init];			
		[self mtdevice_start:mtrackpadDev];
		[self tap_start];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneMainEvent" object:@"deviceToggle" userInfo:[NSDictionary dictionaryWithObject:@"1" forKey:@"index"]];							
	}	
}

- (void)bluetoothDisconnected:(IOBluetoothUserNotification *)aNotification device:(IOBluetoothDevice *)device {
	if ([self isMagicMouse:device] == YES){
		[defaults setBool:YES forKey:@"noMouse"];
		[defaults synchronize];	
        [aNotification unregister]; 		
		if (mmouseDev != NULL) {
            btdevices -=1;		            
            [self mtdevice_stop:mmouseDev];
            [self tap_stop];	
            [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneMainEvent" object:@"deviceToggle" userInfo:[NSDictionary dictionaryWithObject:@"0" forKey:@"index"]];				
            NSLog(@"-%@ disconnected",[device nameOrAddress]);		            
        }
	}
	if ([self isMagicTrackpad:device] == YES){	
		[defaults setBool:YES forKey:@"noTrackpad"];
		[defaults synchronize];
        [aNotification unregister];         
		if (mtrackpadDev != NULL) {
            btdevices -=1;		            
            [self mtdevice_stop:mtrackpadDev];
            [self tap_stop];		
            [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneMainEvent" object:@"deviceToggle" userInfo:[NSDictionary dictionaryWithObject:@"1" forKey:@"index"]];				
            NSLog(@"-%@ disconnected",[device nameOrAddress]);		            
        }
	}	
}

#pragma mark sleep/wake

- (void) sleepNote: (NSNotification*) note {
    [taps removeAllObjects]; //reset taps to clear orphaned leftovers     
    //NSLog(@"receiveSleepNote: %@", [note name]);
    //destroy all devices from the driver as it resets them on wakeup anyway
    if (gtrackpadDev) [self mtdevice_stop:gtrackpadDev];    
    CFPropertyListRef ref = CFPreferencesCopyValue (CFSTR("BluetoothSystemWakeEnable"),CFSTR("com.apple.Bluetooth"),kCFPreferencesCurrentUser,kCFPreferencesCurrentHost);       
    if (ref) {
        if (CFBooleanGetValue(ref)) {
            NSLog(@"*BluetoothSystemWakeEnable on, stopping manually");
            if (mmouseDev) [self mtdevice_stop:mmouseDev];        
            if (mtrackpadDev) [self mtdevice_stop:mtrackpadDev];		
        }else{
            NSLog(@"*sleep with BluetoothSystemWakeEnable off");
        }
        CFRelease(ref);          
    }  
	[self tap_stop];    
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMenuEvent" object:@"IconZZ" userInfo:nil];	   
}

- (void) wakeNote: (NSNotification*) note {  
    //NSLog(@"receiveWakeNote: %@", [note name]);    
    //rebuild all devices from driver as they were reset on wakeup, wait 10 seconds as the macbook trackpad takes a while to be initialized    
	[NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(wakeDelayed:) userInfo:nil repeats:NO];          
}

- (void) wakeDelayed: (NSTimer*) timer {
	retry = 0;
	[self mtdevices_init];	
    if (gtrackpadDev) [self mtdevice_start:gtrackpadDev];    
    //if "allow bluetooth devices to wake this computer" is enabled we can not rely on bluetoothDidConnect to start the devices so we do it manually
    CFPropertyListRef ref = CFPreferencesCopyValue (CFSTR("BluetoothSystemWakeEnable"),CFSTR("com.apple.Bluetooth"),kCFPreferencesCurrentUser,kCFPreferencesCurrentHost);
    if (ref) {
        if (CFBooleanGetValue(ref)) {
            NSLog(@"*BluetoothSystemWakeEnable on, starting manually");
            if (mmouseDev) [self mtdevice_start:mmouseDev];
            if (mtrackpadDev) [self mtdevice_start:mtrackpadDev];
        }else{
            NSLog(@"*wakeup with BluetoothSystemWakeEnable off");
        }
        CFRelease(ref);        
    }
	[self tap_start];    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMenuEvent" object:@"IconON" userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"RestartPluginsHost" userInfo:nil];      
}

#pragma mark user switch

- (void) sessionResigned:(NSNotification*) notif{
    [taps removeAllObjects]; //reset taps to clear orphaned leftovers     
    //NSLog(@"sessionResigned, cursor speed will be reset to default when we get back: %@", [notif name]);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMenuEvent" object:@"IconDIM" userInfo:nil];    
}

- (void) sessionActive:(NSNotification*) notif{ 
    //NSLog(@"sessionActive, cursor speed was reset to default, we have to resync it: %@", [notif name]);
    //schedule sync speed after 10 seconds, osx has a deleay in resseting it and if we sync it too soon it gets overriden
	[NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(syncSpeed) userInfo:nil repeats:NO];        
}

- (void) syncSpeed{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"SyncSpeed" userInfo:nil];  
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMenuEvent" object:@"IconON" userInfo:nil];    
}

#pragma mark main

-(void)theEvent:(NSNotification*)notif{	
	if ([[notif name] isEqualToString:@"VAUserDefaultsUpdate"]) {	
		if ([[notif object] isEqualToString:@"com.vladalexa.MagicPrefs"]){	
			[defaults synchronize]; //not sure if needed		
		}
		if ([[notif object] isEqualToString:@"com.vladalexa.MagicPrefs.MagicPrefsPlugins"]){
            [pluginDefaults release];
            pluginDefaults = [[defaults persistentDomainForName:@"com.vladalexa.MagicPrefs.MagicPrefsPlugins"] retain];	
		}        
	}		
	if (![[notif name] isEqualToString:@"MPcoreEventsEvent"]) {		
		return;
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){
		//mm sync dismiss
		if ([[notif object] isEqualToString:@"dismissedMMenu"]) {		
			mmshown = NO;
		}			
		if ([[notif object] isEqualToString:@"Enable"]){
			retry = 0;
			[self mtdevices_init];			
			if (mmouseDev) [self mtdevice_start:mmouseDev];
			if (mtrackpadDev) [self mtdevice_start:mtrackpadDev];
			if (gtrackpadDev) [self mtdevice_start:gtrackpadDev];
			[self tap_start];				
		}		
		if ([[notif object] isEqualToString:@"Disable"]){
			if (mmouseDev) [self mtdevice_stop:mmouseDev];
			if (mtrackpadDev) [self mtdevice_stop:mtrackpadDev];
			if (gtrackpadDev) [self mtdevice_stop:gtrackpadDev];		
			[self tap_stop];				
		}		
	}
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]]){
		if ([[[notif userInfo] objectForKey:@"what"] isEqualToString:@"doAction"]){
			//NSLog(@"Performing : %@",[[notif userInfo] objectForKey:@"action"]);
			[self performGestureWithName:[[[notif userInfo] objectForKey:@"action"] cStringUsingEncoding:NSUTF8StringEncoding]];	
		}
		if ([[[notif userInfo] objectForKey:@"what"] isEqualToString:@"thePluginEventsList"]){
			[pluginEventsList setDictionary:[[notif userInfo] objectForKey:@"theList"]];
		}		
	}	
}

-(void)workspaceDidActivateApplicationNotification:(NSNotification*)notif{	
	if ([[notif name] isEqualToString:@"NSWorkspaceDidActivateApplicationNotification"]) {
		[activeAppID release];
		activeAppID = [[[[notif userInfo] objectForKey:@"NSWorkspaceApplicationKey"] bundleIdentifier] retain];	
		if (activeAppID == nil){
			activeAppID = [[[[notif userInfo] objectForKey:@"NSWorkspaceApplicationKey"] localizedName] retain];			
		}
        
		//do growl notice
		NSArray	*arr = [defaults objectForKey:@"presetApps"];
		NSString *presetForApp = nil;
		for (id app in arr){		
			if ([[app objectForKey:@"value"] isEqualToString:activeAppID] || [[app objectForKey:@"name"] isEqualToString:activeAppID]) {
				presetForApp = [app objectForKey:@"type"];			
			}
		}
		if (presetForApp) {
            //ignore orphaned presetApps with a deleted preset
            if ([[defaults objectForKey:@"presets"] objectForKey:presetForApp] == nil) {
                //NSLog(@"%@ is a orphan presetApp",presetForApp);
            }else{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"local" userInfo:
                 [NSDictionary dictionaryWithObjectsAndKeys:@"doGrowl",@"what",
                  [NSString stringWithFormat:@"%@ preset loaded",presetForApp],@"title",
                  [NSString stringWithFormat:@"Automatically loaded the %@ preset for %@",presetForApp,activeAppID],@"message",nil]
                 ];
            }
		}
	}			
}

- (id)init{
    self = [super init];
    if(self != nil) {
		//register for notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MPcoreEventsEvent" object:nil];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MPcoreEventsEvent" object:nil suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];	
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"VAUserDefaultsUpdate" object:nil suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];        
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(workspaceDidActivateApplicationNotification:) name:@"NSWorkspaceDidActivateApplicationNotification" object:nil];              
		
		defaults = [NSUserDefaults standardUserDefaults];		
        pluginDefaults = [[defaults persistentDomainForName:@"com.vladalexa.MagicPrefs.MagicPrefsPlugins"] retain];		
        
		pluginEventsList = [[NSMutableDictionary alloc] init];
		taps = [[NSMutableDictionary alloc] init];
        
        cachedZones = [[NSMutableDictionary alloc] init];
		
		eventTap = NULL;
		runLoopSource = NULL;
		
		mmouseDev = NULL;		
		mtrackpadDev = NULL;
		gtrackpadDev = NULL;		
		
		symbolicHotKeys = [[SymbolicHotKeys alloc] init];
		gatherer = [[Gatherer alloc] init];        
		
		activeAppID = @"com.Foo.Bar";
        
        lastMousePos = mousePos();        
		
		btdevices = 0;
		retry = 0;
        lastGestureTime = 0;
        lastZonesCacheTime = 0;

        mpointer = NO;
        tpointer = YES; //trackpad pointer enabled by default
        tscrolling = YES; //scrolling enabled by default
		
		selfContainer(self);
        
		//run pair check
		BOOL pairedDevices = [self pairedCheck];
        if (pairedDevices == YES) {
            retryAttempts = 10;
        }else{
            retryAttempts = 1;            
        }        
		
		//since the glass trackpad does not connect or disconnect we only detect it once here
		[self mtdevices_init];	
		if (gtrackpadDev) [self mtdevice_start:gtrackpadDev];	
		[self tap_start];		
		
		//sleep notifications 
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(sleepNote:) name: NSWorkspaceWillSleepNotification object: NULL];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(wakeNote:) name: NSWorkspaceDidWakeNotification object: NULL];	
		
		//fast user switching notifications
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(sessionActive:) name:NSWorkspaceSessionDidBecomeActiveNotification object:nil];	
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(sessionResigned:) name:NSWorkspaceSessionDidResignActiveNotification object:nil];		
		
		//bluetooth	notification		
		[IOBluetoothDevice registerForConnectNotifications:self selector:@selector(bluetoothDidConnect:device:)];	
		        
	}	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self]; 
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self]; 
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    [cachedZones release];
    [pluginDefaults release];
	[pluginEventsList release];
	[taps release];		
	[symbolicHotKeys release];
    [gatherer release];
	[super dealloc];    
}

@end
