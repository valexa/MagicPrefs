//
//  iSightSnap.h
//  MagicPrefs
//
//  Created by Vlad Alexa on 4/15/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <QTKit/QTKit.h>
#import "MPPluginInterface.h"

@interface iSightSnap : NSObject<MPPluginProtocol> {

    QTCaptureSession                    *mSession;
    QTCaptureDeviceInput                *mDeviceInput;
    QTCaptureDecompressedVideoOutput    *mDecompressedVideoOutput;
    
    CVImageBufferRef                    mCurrentImageBuffer;
}

@property (nonatomic, retain, readwrite) QTCaptureSession *mSession;

- (void)openDevice;
- (NSImage*)getImage;
- (void)willClose;
- (void)snapFrame;
- (NSData *)processFrame:(CVImageBufferRef)imageBuffer;
- (NSImage*)newFlippedImage:(NSImage*)orig;
- (void)addToPbooth:(NSData*)imgdata;

@end
