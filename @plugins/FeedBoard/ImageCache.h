//
//  ImageCache.h
//  Immersee
//
//  Created by Vlad Alexa on 5/17/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UrlConnection.h"

@interface ImageCache : NSView <UrlConnectionDelegate> {
    NSProgressIndicator *spinner;
	UrlConnection *urlConnection;
}

-(void)showImage:(NSString *)ImageURLString;
- (NSImage *)newRoundedImage:(NSImage*) img;
- (CGImageRef)newCGImageFromNSImage:(NSImage*)image;
- (NSImage*)newNSImageFromCGImage:(CGImageRef)cgImage;
- (NSData*)NSImagePNGRepresentation:(NSImage*)image;
@end
