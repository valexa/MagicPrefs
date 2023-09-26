//
//  SpeedInterface.m
//  MagicPrefs
//
//  Created by Vlad Alexa on 12/1/09.
//  Copyright 2009 NextDesign. All rights reserved.
//

#import "SpeedInterface.h"

@implementation SpeedInterface

-(id) init {
	self = [super init];
	if (self) {
        
		[self findHIDSystem];
	}
	return self;
}

- (double)mouseCurrSpeed
{
	[self getMouseSpeed:&currMouseSpeed];
	//NSLog(@"%f mouse speed",currMouseSpeed);	
	return currMouseSpeed;
}

- (double)trackpadCurrSpeed
{
	[self getTrackpadSpeed:&currTrackpadSpeed];	
	//NSLog(@"%f trackpad speed",currTrackpadSpeed);
	return currTrackpadSpeed;
}


// mouseSpeed - use the IOHIDGetMouseAcceleration to obtain the current cursor speed setting.
- (kern_return_t)getMouseSpeed:(double*)value
{
    kern_return_t		kernResult; 	
	CFStringRef			acclCFString = CFSTR(kIOHIDMouseAccelerationType);
	
	if (hidDev){
		kernResult = IOHIDGetAccelerationWithKey( hidDev, acclCFString, &currMouseSpeed );
		if (kernResult == KERN_SUCCESS){
			*value = currMouseSpeed;
		}else{
			*value = 0.0;
			NSLog(@"IOHIDGetAccelerationWithKey returned nil for kIOHIDMouseAccelerationType");
		}
	}else {
		NSLog(@"SpeedInterface found no mouse device");
		kernResult = KERN_FAILURE;
	}
	return kernResult;	
}

- (kern_return_t)getTrackpadSpeed:(double*)value
{
    kern_return_t		kernResult; 	
	CFStringRef			acclCFString = CFSTR(kIOHIDTrackpadAccelerationType);
	
	if (hidDev){
		kernResult = IOHIDGetAccelerationWithKey( hidDev, acclCFString, &currTrackpadSpeed );
		if (kernResult == KERN_SUCCESS){
			*value = currTrackpadSpeed;
		}else{
			*value = 0.0;
			NSLog(@"IOHIDGetAccelerationWithKey returned nil for kIOHIDTrackpadAccelerationType");
		}
	}else {
		NSLog(@"SpeedInterface found no trackpad device");
		kernResult = KERN_FAILURE;
	}
	return kernResult;	
}


// setMouseSpeed - use the IOHIDSetMouseAcceleration to set the  cursor speed to the desired input value.
- (void)setMouseSpeed:(double)value 
{		
	if (value == 0){
        NSLog(@"Not restoring mouse tracking speed to %f",value);                
        return;
    }     
	[self getMouseSpeed:&currMouseSpeed];
	kern_return_t		kernResult; 
	CFStringRef			acclCFString = CFSTR(kIOHIDMouseAccelerationType);
	
    if (currMouseSpeed != value){
		kernResult = IOHIDSetAccelerationWithKey( hidDev, acclCFString, value );
		if (kernResult == KERN_SUCCESS){		
			//NSLog(@"Set kIOHIDMouseAccelerationType from %f to %f",currMouseSpeed,value);				
			currMouseSpeed = value;				
		}else{
			NSLog(@"kIOHIDMouseAccelerationType returned %d", kernResult);
		}	
    }else{
		//NSLog(@"Set kIOHIDMouseAccelerationType skipped, speed is allready %f",value);		
	}

}

- (void)setTrackpadSpeed:(double)value 
{		    
	if (value == 0){
        NSLog(@"Not restoring trackpad tracking speed to %f",value);                
        return;
    }    
	[self getTrackpadSpeed:&currTrackpadSpeed];
	kern_return_t		kernResult; 
	CFStringRef			acclCFString = CFSTR(kIOHIDTrackpadAccelerationType);
	
    if (currTrackpadSpeed != value){
		kernResult = IOHIDSetAccelerationWithKey( hidDev, acclCFString, value );
		if (kernResult == KERN_SUCCESS){		
			//NSLog(@"Set IkIOHIDTrackpadAccelerationType from %f to %f",currMouseSpeed,value);				
			currTrackpadSpeed = value;				
		}else{
			NSLog(@"IkIOHIDTrackpadAccelerationType returned %d", kernResult);
		}	
    }else{
		//NSLog(@"Set IkIOHIDTrackpadAccelerationType skipped, speed is allready %f",value);		
	}
	
}

// findHIDSystem -  finds the IOHIDSystem object in the IORegistry and opens the object for use by the sample program.
- (kern_return_t) findHIDSystem
{
	io_iterator_t			matchingServices;
    io_object_t				intfService;
    kern_return_t			kernResult; 
    mach_port_t				masterPort;
    CFMutableDictionaryRef	classesToMatch;
	Boolean					done = FALSE;
	
	
    kernResult = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if (KERN_SUCCESS != kernResult)
        NSLog(@"IOMasterPort returned %d", kernResult);
	
	// define the matching class to look for as IOHIDSystem.
	classesToMatch = IOServiceMatching("IOHIDSystem");
	
    if (classesToMatch == NULL)
	{
        NSLog(@"IOServiceMatching returned a NULL dictionary.");
		return KERN_FAILURE;
	}
	// find all IOHIDSystem class devices, which will include pointing and 
	// keyboard devices.
    kernResult = IOServiceGetMatchingServices(masterPort, classesToMatch, &matchingServices);    
    if (kernResult != KERN_SUCCESS)
		// if no such matching devices was found, the print the error and exit
        NSLog(@"IOServiceGetMatchingServices returned %d", kernResult);
	if ((intfService = IOIteratorNext(matchingServices)))
	{
		/* open a connection to the HIDSystem User client so that we can make the 
		 IOHIDGetAcceleration/IOHIDGetAccelerationWithKey call. The HID system is a gate for all 
		 supported HID devices, keyboards and mice. You can use the IOHIDLib.h function to manipulate 
		 the general settings which apply to all devices. You cannot use the IOHIDLib.h calls to manipulate the
		 settings for a specific device.
		 */
		
		kernResult = IOServiceOpen( intfService, mach_task_self(), kIOHIDParamConnectType, &hidDev);
		// have accessed the user client so make the call to get the current acceleration setting
		if (kernResult == 0)
		{
			if ([self getMouseSpeed:&currMouseSpeed] == KERN_SUCCESS || [self getTrackpadSpeed:&currTrackpadSpeed] == KERN_SUCCESS)
				done = TRUE;	// we have found a mouse or trackpad, so no need to iterate further, stop the while loop
			else
			{
				// we have a problem so cleanup
				(void) IOServiceClose(hidDev);
				(void) IOObjectRelease(hidDev);				
			}
		}
		else
		{
			NSLog(@"IOServiceOpen returned error 0x%X", kernResult);
			(void) IOObjectRelease(hidDev);
		}
		
	}
	
	if (!done)
	{
		NSLog(@"ERROR: No cursor device found");
		kernResult = KERN_FAILURE;
	}
    return kernResult;
}

@end
