//
//  MenuImage.m
//  MagicPrefs
//
//  Created by Vlad Alexa on 12/3/09.
//  Copyright 2009 NextDesign. All rights reserved.
//

#import "MenuImage.h"


@implementation MenuImage

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		//register for live notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"menuimgEvent" object:nil];
			
		//alloc imageview
		imgView = [[NSImageView alloc] initWithFrame:[self bounds]];
		[imgView setImageFrameStyle:NSImageFrameGroove];
        [self createCompositeImage:@"default.png" rotate:nil];
		[self addSubview:imgView];		
		//NSLog(@"MenuImage loaded");		
		
    }
    return self;
}

-(void)theEvent:(NSNotification*)notif{
	//[[NSDistributedNotificationCenter defaultCenter] setSuspended:YES];
	
	NSDictionary *dict = [[notif userInfo] retain];
	
	if ( [[dict valueForKey:@"what"] isEqualToString:@"touch"] ) {
		lastTap = [[dict valueForKey:@"fingers"] copy];		
		//limit refresh rate
		NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:performTime];
		if (interval < (0.1)) {
			//NSLog(@"skipping ,too fast (%f sec)",interval);		
		}else {	
			[performTime release];
			performTime = [[NSDate date] copy];
			[self createCompositeImage:@"tap.png" rotate:nil];			
		}							
	}
	if ( [[dict valueForKey:@"what"] isEqualToString:@"click"] ) {
		if (lastTap){
			[self createCompositeImage:@"click.png" rotate:nil];			
		}else {
			NSLog(@"real time click without thouch");
		}			
	}	
	if ( [[dict valueForKey:@"what"] isEqualToString:@"hover"] ) {
		//load premade images if no finger data sent
		if ([[dict valueForKey:@"fingers"] count] > 0){			
			lastTap = [[dict valueForKey:@"fingers"] copy];
		}else {
			lastTap = nil;
		}
		[self createCompositeImage:[dict valueForKey:@"image"] rotate:[dict valueForKey:@"rotate"]];
	}	
	
	[dict release];
	
	//[[NSDistributedNotificationCenter defaultCenter] setSuspended:NO];	
}

- (void)createCompositeImage:(NSString *)file rotate:(NSString *)rotate{
	NSString *background;
	if (!lastTap){
		background = file;
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];		
	}else{		
		background = @"background.png";	
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];		
	}    
	
	NSString *bgimagePath = [[NSBundle bundleForClass:[MagicMenuMain class]] pathForImageResource:background];	
	NSString *imagePath = [[NSBundle bundleForClass:[MagicMenuMain class]] pathForImageResource:file];
	
    NSImage *compositeImage = [[NSImage alloc] initWithContentsOfFile:bgimagePath];  
	[compositeImage setCacheMode:NSImageCacheNever];
    [compositeImage lockFocus];		
	for (id key in lastTap){
		int state = [[[lastTap objectForKey:key] valueForKey:@"state"] intValue];
		float fraction;
		if (state == 1 || state == 2 || state == 3 ){
			fraction = 1.0;
		}else {
			fraction = 0.5;
		}		
		float x = [[[lastTap objectForKey:key] valueForKey:@"posx"] floatValue];
		float y = [[[lastTap objectForKey:key] valueForKey:@"posy"] floatValue];		
		NSPoint point = {x,y};		
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

- (void) drawRect:(NSRect)aRect {
	NSLog(@"nothing to do here , allready have %i subviews",[[self subviews] count]);	
}

//[view setTransform: CGAffineTransformMakeRotation((PI/180) * 1)]; // rotates 1 degree clockwise where PI/180 == 1 degree
- (NSImage*)newRotatedImage:(NSString*)imagePath byDegrees:(NSString *)deg{
	NSImage *orig = [[NSImage alloc] initWithContentsOfFile:imagePath];
	NSSize size;	
	float y;
	float x;	
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
	//NSLog(@"MenuImage releasing");	
	_compositeImage = nil;
	[lastTap release];
	[performTime release];
	[super dealloc];	
}

@end
