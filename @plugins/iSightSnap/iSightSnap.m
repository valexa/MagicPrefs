//
//  iSightSnap.m
//  MagicPrefs
//
//  Created by Vlad Alexa on 4/15/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "iSightSnap.h"

static NSBundle* pluginBundle = nil;

@implementation iSightSnap

/*
 Plugin events : 
 doSnap "Snap Picture"
 
 Plugin events (nondynamic):
 N/A
 
 Plugin settings :
 N/A
 
 Plugin preferences :
 N/A					
 */ 

@synthesize mSession;

+ (BOOL)initializeClass:(NSBundle*)theBundle {
	if (pluginBundle) {
		return NO;
	}
	pluginBundle = [theBundle retain];
	return YES;
}

+ (void)terminateClass {
	if (pluginBundle) {
		[pluginBundle release];
		pluginBundle = nil;
	}
}

- (id)init{
    self = [super init];
    if(self != nil) {
		
		NSString *bundleId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];					
		if ([bundleId isEqualToString:@"com.apple.systempreferences"]) return self;	
		
		//your initialization here			
		//NSLog(@"iSightSnap init");
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];		
		
		//set events
		NSDictionary *events = [NSDictionary dictionaryWithObjectsAndKeys:@"Snap Picture",@"doSnap",nil];
		NSMutableDictionary *dict = [[defaults objectForKey:@"iSightSnap"] mutableCopy];
		[dict setObject:events forKey:@"events"];
		[defaults setObject:dict forKey:@"iSightSnap"];
		[defaults synchronize];
		[dict release];			
		
		//register for notifications		
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MPPluginiSightSnapEvent" object:nil];
		
    }
    return self;
}		

-(void)theEvent:(NSNotification*)notif{	
	if (![[notif name] isEqualToString:@"MPPluginiSightSnapEvent"]) {		
		return;
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){
		if ([[notif object] isEqualToString:@"doSnap"]){
			[self openDevice];
			[self snapFrame];	
		}																
	}			
}

- (void)openDevice{
	NSError *error = nil;
	
	if (!mSession) {
		// Set up a capture session that outputs raw frames
		BOOL success;
		
		mSession = [[QTCaptureSession alloc] init];
		
		// Find a video device
		QTCaptureDevice *device = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
		success = [device open:&error];
		if (!success) {
			NSLog(@"Can not create camera device (%@) [connected %d] {%@}",[device isConnected],[error localizedDescription],[device description]);
			return;
		}
		
		// Add a device input for that device to the capture session
		mDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:device];
		success = [mSession addInput:mDeviceInput error:&error];
		if (!success) {
			NSLog(@"Can not add camera input (%@)",[error localizedDescription]);
			return;
		}
		
		// Add a decompressed video output that returns raw frames to the session
		mDecompressedVideoOutput = [[QTCaptureDecompressedVideoOutput alloc] init];
		[mDecompressedVideoOutput setDelegate:self];
		success = [mSession addOutput:mDecompressedVideoOutput error:&error];
		if (!success) {
			NSLog(@"Can not add camera output (%@)",[error localizedDescription]);
			return;
		}
		
		// Start the session
		[mSession startRunning];
	}
}
		
- (void)willClose
{
	//NSLog(@"iSightSnap closing");	
    [mSession stopRunning];    
    QTCaptureDevice *device = [mDeviceInput device];
    if ([device isOpen]) [device close]; 
	
	CVBufferRelease(mCurrentImageBuffer);
	mCurrentImageBuffer = nil;
    [mSession release];
	mSession = nil;
    [mDeviceInput release];
	mDeviceInput = nil;
    [mDecompressedVideoOutput release];	
	mDecompressedVideoOutput = nil;
}


- (void)dealloc
{
	//NSLog(@"iSightSnap freed");
    
    [super dealloc];
}


// This delegate method is called whenever the QTCaptureDecompressedVideoOutput receives a frame
- (void)captureOutput:(QTCaptureOutput *)captureOutput didOutputVideoFrame:(CVImageBufferRef)videoFrame withSampleBuffer:(QTSampleBuffer *)sampleBuffer fromConnection:(QTCaptureConnection *)connection
{
    // Store the latest frame
	// This must be done in a @synchronized block because this delegate method is not called on the main thread
    CVImageBufferRef imageBufferToRelease;
    
    CVBufferRetain(videoFrame);
    
    @synchronized (self) {
        imageBufferToRelease = mCurrentImageBuffer;
        mCurrentImageBuffer = videoFrame;
    }
    
    CVBufferRelease(imageBufferToRelease);
}

- (NSImage*)getImage
{
    // Get the most recent frame
	// This must be done in a @synchronized block because the delegate method that sets the most recent frame is not called on the main thread
    CVImageBufferRef imageBuffer;
    
    @synchronized (self) {
        imageBuffer = CVBufferRetain(mCurrentImageBuffer);		
    }
    
    if (imageBuffer) {			
		NSImage *image = [[NSImage alloc] initWithData:[self processFrame:imageBuffer]];					
        CVBufferRelease(imageBuffer);
		[self willClose];		
		return [image autorelease];
    }else {
		NSLog(@"Error getting a image, no image loaded yet.");	
		[self willClose];		
		return nil;
	}
}

- (void)snapFrame
{
	if (!mCurrentImageBuffer) {
		//NSLog(@"No image loaded yet, retrying in 2 sec");
		[NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(snapFrame) userInfo:nil repeats:NO];	
		return;
	}
    // Get the most recent frame
	// This must be done in a @synchronized block because the delegate method that sets the most recent frame is not called on the main thread
    CVImageBufferRef imageBuffer;
    
    @synchronized (self) {		
        imageBuffer = CVBufferRetain(mCurrentImageBuffer);				
    }
    
    if (imageBuffer) {						
		[self addToPbooth:[self processFrame:imageBuffer]];	
        CVBufferRelease(imageBuffer);			
		[self willClose];
    }
}

- (void)addToPbooth:(NSData*)imgdata{
	//write file
	NSString *name = [NSString stringWithFormat:@"MagicPrefs %@.jpg",[[NSDate date] description]];
	[imgdata writeToFile:[NSString stringWithFormat:@"%@/Pictures/Photo Booth Library/Pictures/%@",NSHomeDirectory(),name] atomically:NO];	
	//write plist entry
	NSString *path = [NSString stringWithFormat:@"%@/Pictures/Photo Booth Library/Recents.plist",NSHomeDirectory()];	
	NSMutableArray *arr = [[NSArray arrayWithContentsOfFile:path] mutableCopy];
	if (arr == nil)	arr = [[NSMutableArray alloc] initWithCapacity:1];		
	[arr addObject:name];
	[arr writeToFile:path atomically:YES];
	[arr release];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPcoreMainEvent" object:@"remote" userInfo:
	 [NSDictionary dictionaryWithObjectsAndKeys:@"doNotif",@"what",@"cam",@"image",@"Picture Snapped",@"text",nil]
	 ];		
	NSLog(@"Saved image %@ to Photo Booth",name);	
}

- (NSData *)processFrame:(CVImageBufferRef)imageBuffer{
	// Create an NSImage
	NSCIImageRep *imageRep = [NSCIImageRep imageRepWithCIImage:[CIImage imageWithCVImageBuffer:imageBuffer]];
	NSImage *image = [[NSImage alloc] initWithSize:[imageRep size]];
	[image addRepresentation:imageRep];
	//flip the image
	NSImage *flippedImage = [self newFlippedImage:image];
	[image release];	
	//get the image data	
	NSBitmapImageRep *bits = [NSBitmapImageRep imageRepWithData:[flippedImage TIFFRepresentation]];		
	[flippedImage release];
	NSData *imgdata = [bits representationUsingType:NSJPEGFileType properties:nil];			
	return imgdata;
}

- (NSImage*)newFlippedImage:(NSImage*)orig{
	//flip horizontal	
	NSSize size;		
	size.width = [orig size].width;
	size.height = [orig size].height;
	float y = 0;
	float x = -[orig size].width;	
	//alloc new
	NSImage *rotated = [[NSImage alloc] initWithSize:size];
	[rotated lockFocus];
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform scaleXBy:-1.0 yBy:1.0];		
	[transform translateXBy:x yBy:y];	
	[transform concat];	
	[orig drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
	[rotated unlockFocus];		
	return rotated;
}

@end
