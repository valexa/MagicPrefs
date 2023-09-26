//
//  ItemView.m
//  Immersee
//
//  Created by Vlad Alexa on 4/20/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "ItemView.h"

@implementation ItemView

@synthesize data;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		[self addObserver:self forKeyPath:@"data" options:NSKeyValueObservingOptionOld context:NULL];		
    }
    return self;
}


- (void)dealloc
{
    //NSLog(@"ItemView freed");
	[self removeObserver:self forKeyPath:@"data"];
	[imgcache release];
    [super dealloc];
}

- (BOOL)needsDisplayOnBoundsChange{
	return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {	
	if (imgcache == nil) {
		[self determineImageRect];	
		[self getFaviconIfNoImage];		
	}else {
		NSLog(@"Multiple image request");
	}
}

- (void)mouseUp:(NSEvent*)event{
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPPluginFeedBoardEvent" object:@"dismiss" userInfo:nil];	
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"VAFeedBoardEvent" object:@"dismiss" userInfo:nil];	       
	NSURL *url = [NSURL URLWithString:[data objectForKey:@"link"]];
	[[NSWorkspace sharedWorkspace] openURL:url];	
}

-(void)resetCursorRects{
    [self addCursorRect:self.bounds cursor:[NSCursor pointingHandCursor]];
}

- (void)drawRect:(NSRect)dirtyRect {
	//refresh image rect
	[self determineImageRect];
	if ([self subviews]) [[[self subviews] objectAtIndex:0] setFrame:imagerect];
	//draw text
	NSString *text = [NSString stringWithFormat:@"%@ %@",[data objectForKey:@"name"],[data objectForKey:@"text"]];			
    [self setToolTip:text]; //save text for text to speech
	NSRect rect = NSMakeRect(55,self.frame.size.height/10,self.frame.size.width-55,self.frame.size.height-5);
	[text drawInRect:rect withAttributes:[self makeAttrDict]]; 
}

-(void)determineImageRect{
	if ([[data objectForKey:@"image"] length] > 0) {
		imagerect = NSMakeRect(1,self.frame.size.height-49,48,48);			
	} else {
		imagerect = NSMakeRect(22,self.frame.size.height-22,16,16);	
	}
}

-(void)getFaviconIfNoImage{	
	NSString *image;
	if ([[data objectForKey:@"image"] length] < 1) {
		NSURL *host = [NSURL URLWithString:[data objectForKey:@"source"]];
		image = [NSString stringWithFormat:@"http://%@/favicon.ico",[host host]];	
		if ([[host host] isEqualToString:@"techcrunch.com"]) image = @"http://s2.wp.com/wp-content/themes/vip/tctechcrunch/images/webclips/techcrunch.png?m=1268873281g";	//techcrunch fix		
	}else {
		image = [data objectForKey:@"image"];
	}
	imgcache = [[ImageCache alloc] initWithFrame:imagerect];	
	[self addSubview:imgcache];
	[imgcache showImage:image];
}

- (NSMutableDictionary*) makeAttrDict{
	float fontSize;
	if ([[NSString stringWithFormat:@"%1.f",self.frame.size.height] isEqualToString:@"50"]) {
		fontSize = 12.0;			
	}else {
		fontSize = 24.0;
	}
	NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithObject:[NSFont fontWithName:@"Helvetica" size:fontSize] forKey:NSFontAttributeName];
	[attrsDictionary setObject:[NSColor colorWithCalibratedRed:0.6 green:0.6 blue:0.6 alpha:1.0] forKey:NSForegroundColorAttributeName];
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowOffset:NSMakeSize(0,-1)];
	[shadow setShadowColor:[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:1.0]];
	[shadow setShadowBlurRadius:1];
	[attrsDictionary setObject:shadow forKey:NSShadowAttributeName];
	[shadow release];
	return attrsDictionary;
}

/*
 
-(NSSize)maxSizesInImage:(NSImage*)img{
	NSInteger width = 0;
	NSInteger height = 0;	
	for (NSImageRep *rep in [img representations]){
		if ([rep pixelsWide] > width) width = [rep pixelsWide];		
		if ([rep pixelsHigh] > height) height = [rep pixelsHigh];
	}
	return NSMakeSize(width,height);
}

- (void)drawInContext:(CGContextRef)ctx{
	NSImage *image = [[NSImage alloc] initByReferencingURL:[NSURL URLWithString:[data objectForKey:@"image"]]];	
	if ([image isValid]) {
		CGContextDrawImage(ctx,CGRectMake(7,7,48,48),[self NewCGImageFromNSImage:image]);
		NSLog(@"drawing");
	}else {
		CGContextDrawImage(ctx,CGRectMake(7,7,48,48),[self NewCGImageFromNSImage:[NSImage imageNamed:@"NSStopProgressTemplate"]]);					
	}	
	
	CGContextShowTextAtPoint (ctx,60.0,5.0,[[data objectForKey:@"text"] UTF8String],[[data objectForKey:@"text"] length]);	
	
}
 
-(void)drawLayer:(CALayer *)l inContext:(CGContextRef)ctx {
	CIImage *_ciImage = [CIImage imageWithContentsOfURL:[NSURL URLWithString:[data objectForKey:@"image"]]]; 
	CGPoint _origin = CGPointMake(0,0); 
	CGRect _rect = CGRectMake(7,7,48,48);
	if ([_ciImage extent]) {	 
		[[CIContext contextWithCGContext:ctx options:nil] drawImage:_ciImage atPoint:_origin fromRect:_rect];
	} else {
		[[CIContext contextWithCGContext:ctx options:nil] drawImage:[self NewCIImageFromNSImage:[NSImage imageNamed:@"NSStopProgressTemplate"]] atPoint:_origin fromRect:_rect];
	}	
} 

-(CIImage*)NewCIImageFromNSImage:(NSImage*)image{
	NSData  *tiffData = [image TIFFRepresentation];
	NSBitmapImageRep *bitmap = [NSBitmapImageRep imageRepWithData:tiffData];
	return [[CIImage alloc] initWithBitmapImageRep:bitmap];	
} 

+ (CGImageRef)NewCGImageFromNSImage:(NSImage*)image{
	NSData* cocoaData = [NSBitmapImageRep TIFFRepresentationOfImageRepsInArray:[image representations]];
	CFDataRef carbonData = (CFDataRef)cocoaData;
	CGImageSourceRef imageSourceRef = CGImageSourceCreateWithData(carbonData, NULL);
	CGImageRef ret = CGImageSourceCreateImageAtIndex(imageSourceRef, 0, NULL);	
	CFRelease(imageSourceRef);
	return ret;
}

+ (NSImage*)NewNSImageFromCGImage:(CGImageRef)cgImage{
	NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
	NSImage *image = [[NSImage alloc] init];
	[image addRepresentation:bitmapRep];
	[bitmapRep release];
	return image;
}

+ (NSData*)NSImagePNGRepresentation:(NSImage*)image{
	NSBitmapImageRep *bits = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];		
	return [bits representationUsingType:NSPNGFileType properties:nil];		
}
 
*/ 

@end
