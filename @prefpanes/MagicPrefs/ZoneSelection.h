//
//  ZoneSelection.h
//  MagicPrefs
//
//  Created by Vlad Alexa on 3/10/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MagicPrefsMain.h"
#import "VAUserDefaults.h"

// The value that is returned by -handleUnderPoint: to indicate that no selection handle is under the point.
const int noHandle = 0;
const CGFloat HandleSize = 8.0f;
const CGFloat HandleHalf = 8.0f / 2.0f;

enum {
    theUpperLeftHandle = 1,
    theUpperMiddleHandle = 2,
    theUpperRightHandle = 3,
    theMiddleLeftHandle = 4,
    theMiddleRightHandle = 5,
    theLowerLeftHandle = 6,
    theLowerMiddleHandle = 7,
    theLowerRightHandle = 8,
};

@interface ZoneHandle : NSImageView {
}	
@end

@interface ZoneSelection : NSView {

	VAUserDefaults *defaults;
	NSString *gesture;
	NSCursor *leftCursor;
	NSCursor *rightCursor;	
	NSRect mSelectionRect;
	int activeHandle;
    NSImageView *collisionView;
    NSMutableDictionary *handleImages;
	
}

@property (retain) NSString *gesture;

-(void)saveZone;
-(NSRect)zoneToRect:(NSDictionary*)zone;
- (void)drawHandleAtPoint:(NSPoint)point tag:(int)tag;
- (void)drawHandlesInRect:(NSRect)bounds;
- (void)resizeWithHandle:(NSInteger)handle withEvent:(NSEvent *)event;
- (BOOL)resizeToPoint:(NSPoint)point;
- (void)moveWithEvent:(NSEvent *)theEvent;
-(BOOL)zoneMakesSence:(NSRect)rect;
-(BOOL)rect:(NSRect)container containsRect:(NSRect)containee inverse:(BOOL)inverse;

@end
