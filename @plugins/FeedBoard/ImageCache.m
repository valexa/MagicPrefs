//
//  ImageCache.m
//  Immersee
//
//  Created by Vlad Alexa on 5/17/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "ImageCache.h"

#define TMP NSTemporaryDirectory()

@implementation ImageCache

@synthesize spinner;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.

		spinner = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect((self.frame.size.width/2)-16, (self.frame.size.height/2)-16, 32, 32)]; 
		[spinner setIndeterminate:YES];
		[spinner setDisplayedWhenStopped:YES];
		[spinner setDoubleValue:YES];
		[spinner setStyle:NSProgressIndicatorSpinningStyle];		
		[self addSubview:spinner];		
		
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
}

- (void)dealloc
{
    //NSLog(@"ImageCache freed");	
	[urlConnection.theConnection cancel];	
	[urlConnection release];	
	[spinner release];
    [super dealloc];
}

- (void)waitTimer:(NSTimer*)theTimer{
	[self showImage:[theTimer userInfo]];
}

-(void)showImage:(NSString *)ImageURLString {
	
    NSString *filename = [ImageURLString stringByReplacingOccurrencesOfString:@"/" withString:@""];
    NSString *uniquePath = [TMP stringByAppendingPathComponent:filename];
    NSString *uniquePathDownloading = [uniquePath stringByAppendingString:@".downloadinprogresspart"];	
	
    // if a download is in progress wait 1 second and retry
    if([[NSFileManager defaultManager] fileExistsAtPath:uniquePathDownloading] )    {
		
		NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:uniquePathDownloading error:nil];				
		NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:[dict objectForKey:NSFileCreationDate]];		
		if (interval > 120) {
			//delete the file, it's too old
			BOOL success = [[NSFileManager defaultManager] removeItemAtPath:uniquePathDownloading error:nil];	
			if (success == NO) NSLog(@"Failed to delete %@.",uniquePathDownloading);				
		}else{
			//NSLog(@"%@ exists, retrying in 1 second",uniquePathDownloading);
			[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(waitTimer:) userInfo:ImageURLString repeats:NO];
			return;			
		}
		
	}	

    // Check for a cached version
    if([[NSFileManager defaultManager] fileExistsAtPath:uniquePath] )    {
		NSImage *image = [[NSImage alloc] initWithContentsOfFile:uniquePath]; 
		if ([image isValid]) {
			//NSLog(@"Got %@ from cache.",uniquePath);					
			NSImageView *imageView = [[NSImageView alloc] initWithFrame:self.bounds];
			[imageView setImage:image];	
			[self addSubview:imageView];		
			[imageView release];	
		}else {
			//NSLog(@"Downloading %@",ImageURLString);		
			urlConnection = [[UrlConnection alloc] initWithURL:ImageURLString andHeader:nil delegate:self];
			[[[[NSData alloc] init] autorelease] writeToFile:uniquePathDownloading atomically:YES];			
		}		
		[image release];		
    }else {
		//NSLog(@"Downloading %@",ImageURLString);		
		urlConnection = [[UrlConnection alloc] initWithURL:ImageURLString andHeader:nil delegate:self];		
		[[[[NSData alloc] init] autorelease] writeToFile:uniquePathDownloading atomically:YES];		
	}
}

- (void) connectionDidFinish:(UrlConnection *)theConnection{
	//NSLog(@"Got %@",theConnection.url);
	
	NSString *filename = [theConnection.url stringByReplacingOccurrencesOfString:@"/" withString:@""];
	NSString *uniquePath = [TMP stringByAppendingPathComponent:filename];
	NSString *uniquePathDownloading = [uniquePath stringByAppendingString:@".downloadinprogresspart"];	
	
	//delete part file
	if ([[NSFileManager defaultManager] fileExistsAtPath:uniquePathDownloading]) {
		BOOL success = [[NSFileManager defaultManager] removeItemAtPath:uniquePathDownloading error:nil];	
		if (success == NO) 	NSLog(@"Failed to delete %@.",uniquePathDownloading);			
	}
	
	//save image
	NSImage *image = [[NSImage alloc] initWithData:theConnection.receivedData];		
	if ([image isValid]) {		
		if (![[NSFileManager defaultManager] fileExistsAtPath:uniquePath]) {
			//save image
			NSImage *round = [self newRoundedImage:image];				
			[[self NSImagePNGRepresentation:round] writeToFile:uniquePath atomically:YES];			
			//NSLog(@"Cached %@.",uniquePath);					
			//add to subviews			
			NSImageView *imageView = [[NSImageView alloc] initWithFrame:self.bounds];
			[imageView setImage:round];
			[round release];
			[self addSubview:imageView];
			[imageView release];		
		}
	}else {
		NSLog(@"Image for %@ is invalid",theConnection.url);
	}
	[image release];	
}

- (void) connectionDidFail:(UrlConnection *)theConnection{
		//do not delete the part file, leave it there
}

static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight)
{
    float fw, fh;
    if (ovalWidth == 0 || ovalHeight == 0)
    {
		CGContextAddRect(context, rect);
		return;
    }
    CGContextSaveGState(context);
    CGContextTranslateCTM (context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM (context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth (rect) / ovalWidth;
    fh = CGRectGetHeight (rect) / ovalHeight;
    CGContextMoveToPoint(context, fw, fh/2);
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

- (NSImage *)newRoundedImage:(NSImage*) img
{
    int w = self.frame.size.width;
    int h = self.frame.size.height;
	
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
	
    CGContextBeginPath(context);
    CGRect rect = CGRectMake(0, 0, w, h);
    addRoundedRectToPath(context, rect, 5, 5);
    CGContextClosePath(context);
    CGContextClip(context);
	
	CGImageRef imgref = [self newCGImageFromNSImage:img];
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), imgref);
	CFRelease(imgref);
	
    CGImageRef imageMasked = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
	
	NSImage *ret = [self newNSImageFromCGImage:imageMasked];
	CFRelease(imageMasked);
    return ret;
}

- (CGImageRef)newCGImageFromNSImage:(NSImage*)image{
	NSData* cocoaData = [NSBitmapImageRep TIFFRepresentationOfImageRepsInArray:[image representations]];
	CFDataRef carbonData = (CFDataRef)cocoaData;
	CGImageSourceRef imageSourceRef = CGImageSourceCreateWithData(carbonData, NULL);
	CGImageRef ret = CGImageSourceCreateImageAtIndex(imageSourceRef, 0, NULL);	
	CFRelease(imageSourceRef);
	return ret;
}

- (NSImage*)newNSImageFromCGImage:(CGImageRef)cgImage{
	NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
	NSImage *image = [[NSImage alloc] init];
	[image addRepresentation:bitmapRep];
	[bitmapRep release];
	return image;
}

- (NSData*)NSImagePNGRepresentation:(NSImage*)image{
	NSBitmapImageRep *bits = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];		
	return [bits representationUsingType:NSPNGFileType properties:nil];		
}

@end
