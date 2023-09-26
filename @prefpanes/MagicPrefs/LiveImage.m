//
//  LiveImage.m
//  MagicPrefs
//
//  Created by Vlad Alexa on 12/3/09.
//  Copyright 2009 NextDesign. All rights reserved.
//

#import "LiveImage.h"


@implementation LiveImage

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		
		//alloc defaults
		defaults = [[VAUserDefaults alloc] initWithPlist:@"com.vladalexa.MagicPrefs.plist"];		
		
		//register for live notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MPprefpaneImgEvent" object:nil];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MPprefpaneImgEvent" object:nil];					
			
		//alloc imageview
		imgView = [[NSImageView alloc] initWithFrame:[self bounds]];
		[imgView setImageFrameStyle:NSImageFrameNone];
        [self createCompositeImage:nil background:@"default.png" rotate:nil];
		[self addSubview:imgView];		
		//NSLog(@"LiveImage loaded");		
		
    }
    return self;
}

-(void)theEvent:(NSNotification*)notif{
	//[[NSDistributedNotificationCenter defaultCenter] setSuspended:YES];
	
	NSDictionary *dict = [[notif userInfo] retain];
	lastGesture = nil;
	
	if ( [[dict valueForKey:@"what"] isEqualToString:@"touch"] ) {
		lastTap = [[dict valueForKey:@"fingers"] copy];		
		//limit refresh rate
		NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:performTime];
		if (interval < (0.1)) {
			//NSLog(@"skipping ,too fast (%f sec)",interval);		
		}else {	
			[performTime release];
			performTime = [[NSDate date] copy];
			[self createCompositeImage:@"tap.png" background:[dict valueForKey:@"back"] rotate:nil];			
		}							
	}
	if ( [[dict valueForKey:@"what"] isEqualToString:@"click"] ) {
		if (lastTap){
			[self createCompositeImage:@"click.png" background:[dict valueForKey:@"back"] rotate:nil];			
		}else {
			NSLog(@"real time click without thouch");
		}			
	}	
	if ( [[dict valueForKey:@"what"] isEqualToString:@"hover"] ) {
		//save tag
		lastGesture = [dict valueForKey:@"tag"];		
		//load premade images if no finger data sent
		if ([[dict valueForKey:@"fingers"] count] > 0){			
			lastTap = [[dict valueForKey:@"fingers"] copy];
		}else {
			lastTap = nil;
		}
		[self createCompositeImage:[dict valueForKey:@"image"] background:[dict valueForKey:@"back"] rotate:[dict valueForKey:@"rotate"]];
	}	
	
	[dict release];
	
	//[[NSDistributedNotificationCenter defaultCenter] setSuspended:NO];	
}

- (void)createCompositeImage:(NSString *)file background:(NSString *)background rotate:(NSString *)rotate{
	int xscale = 0;
	int yscale = 0;
	int xoffset = 0;
	int yoffset = 0;
	
	if ([background isEqualToString:@"mm"]) {
		background = @"background_magic_mouse.png";
		xscale = 125;
		yscale = 205;
		xoffset = 58;
		yoffset = 95;
	}
	if ([background isEqualToString:@"mt"]) {
		background = @"background_magic_trackpad.png";
		xscale = 207;
		yscale = 167;
		xoffset = 16;
		yoffset = 55;		
	}
	if ([background isEqualToString:@"gt"]) {
		background = @"background_mbp_trackpad.png";
		xscale = 160;
		yscale = 110;
		xoffset = 40;
		yoffset = 110;		
	}
	
	if (!lastTap){
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];		
	}else{		
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationLow];		
	}    
	
	NSString *bgimagePath = [[NSBundle bundleForClass:[MagicPrefsMain class]] pathForImageResource:background];	
	NSString *imagePath = [[NSBundle bundleForClass:[MagicPrefsMain class]] pathForImageResource:file];
	
    NSImage *compositeImage = [[NSImage alloc] initWithContentsOfFile:bgimagePath];  
	[compositeImage setCacheMode:NSImageCacheNever];
    [compositeImage lockFocus];
	//draw zones	
	NSDictionary *zone = [[defaults objectForKey:@"zones"] objectForKey:lastGesture];
	if (zone != nil){
		NSColor *topColor = [NSColor colorWithCalibratedRed:0.92 green:0.49 blue:0.34 alpha:0.8];
		NSColor *botColor = [NSColor colorWithCalibratedRed:0.93 green:0.44 blue:0.46 alpha:0.8];		
		NSGradient *aGradient = [[NSGradient alloc] initWithStartingColor:topColor endingColor:botColor];		
		NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRoundedRect:[self zoneRect:zone type:background] xRadius:25.0 yRadius:25.0];	
		[aGradient drawInBezierPath:selectionPath angle:90];	
		[aGradient release];
	}		
	//draw fingers
	for (id key in lastTap){
		int state = [[[lastTap objectForKey:key] valueForKey:@"state"] intValue];
		float fraction;
		if (state == 1 || state == 2 || state == 3 ){
			fraction = 1.0;
		}else {
			fraction = 0.5;
		}		
		float x = [[[lastTap objectForKey:key] valueForKey:@"posx"] floatValue]*xscale;
		float y = [[[lastTap objectForKey:key] valueForKey:@"posy"] floatValue]*yscale;		
		NSPoint point = {x+xoffset,y+yoffset};		
		NSImage *image;
		if (rotate) {
			//NSLog(@"rotating by %@",rotate);						
			image = [self newRotatedImage:imagePath byDegrees:rotate];	
		}else {
			image = [[NSImage alloc] initWithContentsOfFile:imagePath];						
		}				
		[image drawAtPoint:point fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:fraction];				
		[image release];
		image = nil;		
	}    
    [compositeImage unlockFocus];    
    _compositeImage = compositeImage;
	[imgView setImage:_compositeImage];	
    [compositeImage release];  	
}	

- (NSRect)zoneRect:(NSDictionary*)zone type:(NSString*)type{	
	float x = [[zone objectForKey:@"x"] floatValue];
	float w = [[zone objectForKey:@"w"] floatValue];
	float y = [[zone objectForKey:@"y"] floatValue];
	float h = [[zone objectForKey:@"h"] floatValue];
	//hardcoded sizes of the ZoneSelection nswiev	
	int width = 0;
	int height = 0;
	//hardcoded origins of the ZoneSelection nswiev	
	int xofset = 0;
	int yofset = 0;
	if ([type isEqualToString:@"background_magic_mouse.png"]) {
		width = 150;
		height = 225;
		xofset = 63;
		yofset = 102;		
	}
	if ([type isEqualToString:@"background_magic_trackpad.png"]) {
		width = 238;
		height = 199;
		xofset = 19;
		yofset = 57;		
	}
	if ([type isEqualToString:@"background_mbp_trackpad.png"]) {
		width = 190;
		height = 137;
		xofset = 44;
		yofset = 115;		
	}	
	return NSMakeRect(width*x+xofset,height*y+yofset,width*w,height*h);				
}

- (void) drawRect:(NSRect)aRect {
	//NSLog(@"nothing to do here , allready have %i subviews",[[self subviews] count]);	
}

//[view setTransform: CGAffineTransformMakeRotation((PI/180) * 1)]; // rotates 1 degree clockwise where PI/180 == 1 degree
- (NSImage*)newRotatedImage:(NSString*)imagePath byDegrees:(NSString *)deg{
	NSImage *orig = [[NSImage alloc] initWithContentsOfFile:imagePath];
	NSSize size = NSZeroSize;	
	float y = 0.0;
	float x = 0.0;	
	if ([deg isEqualToString:@"90"]){
		size.width = [orig size].height;
		size.height = [orig size].width;
		y = -[orig size].height;
		x = 0.0;		
	}
	if ([deg isEqualToString:@"-90"]){
		size.width = [orig size].height;
		size.height = [orig size].width;
		y = 0.0;
		x = -[orig size].width;
	}	
	if ([deg isEqualToString:@"180"]){
		size.width = [orig size].width;
		size.height = [orig size].height;
		y = -[orig size].height;
		x = -[orig size].width;		
	}
	//flip vertical
	if ([deg isEqualToString:@"0"]){
		size.width = [orig size].width;
		size.height = [orig size].height;
		y = -[orig size].height;
		x = 0.0;		
	}
	//flip horizontal	
	if ([deg isEqualToString:@"1"]){
		size.width = [orig size].width;
		size.height = [orig size].height;
		y = 0.0;
		x = -[orig size].width;		
	}	
	NSImage *rotated = [[NSImage alloc] initWithSize:size];
	[rotated lockFocus];
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform rotateByDegrees:[deg floatValue]];
	if ([deg isEqualToString:@"0"]){
		[transform scaleXBy:1.0 yBy:-1.0];		
	}	
	if ([deg isEqualToString:@"1"]){
		[transform scaleXBy:-1.0 yBy:1.0];		
	}	
	[transform translateXBy:x yBy:y];	
	[transform concat];	
	[orig drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
	[rotated unlockFocus];		
	[orig release];
	return rotated;
}

- (void)dealloc
{   
	//NSLog(@"Liveimage releasing");	
	_compositeImage = nil;
	[lastTap release];
	[performTime release];
	[super dealloc];	
}

@end
