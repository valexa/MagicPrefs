//
//  ZoneSelection.m
//  MagicPrefs
//
//  Created by Vlad Alexa on 3/10/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "ZoneSelection.h"


@implementation ZoneHandle
-(void)mouseDown:(NSEvent*)event {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneZoneEvent" object:event userInfo:nil];		
}
@end

@implementation ZoneSelection

@synthesize gesture;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.	
		
		//alloc defaults
		defaults = [[VAUserDefaults alloc] initWithPlist:@"com.vladalexa.MagicPrefs.plist"];	
		
		//register for live notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MPprefpaneZoneEvent" object:nil];		
		
		NSImage *image;
		image = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[MagicPrefsMain class]] pathForImageResource:@"leftCursor"]]; 
		leftCursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint (8,8)];		
		[image release];
		image = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[MagicPrefsMain class]] pathForImageResource:@"rightCursor"]]; 
		rightCursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint (8,8)];		
		[image release];	
                
		[self setHidden:YES];
        
        handleImages = [[NSMutableDictionary alloc] initWithCapacity:8];
		
    }
    return self;
}

- (void)awakeFromNib{ 
    collisionView = [[NSImageView alloc] initWithFrame:NSMakeRect([self frame].origin.x,[self frame].origin.y,[self frame].size.width,[self frame].size.height)];
    [collisionView setAlphaValue:0.0]; 
    [collisionView setImageScaling:NSImageScaleNone];
    [collisionView setImageAlignment:NSImageAlignBottomLeft];//allign with coords origin
    [[self superview] addSubview:collisionView positioned:NSWindowBelow relativeTo:self];
}

- (void)drawRect:(NSRect)dirtyRect {		
    // draw our selection rect
    if (!NSEqualRects(NSZeroRect, mSelectionRect)) {
		[self drawHandlesInRect:mSelectionRect];		
		//draw border
        [[NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:1.0] set];
        NSFrameRect(mSelectionRect);
        NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRect:mSelectionRect];
        CGFloat dashArray[2] = {5.0, 2.0};
        [selectionPath setLineDash:dashArray count:sizeof(dashArray) / sizeof(dashArray[0]) phase:0.0];
		[selectionPath setLineCapStyle:NSRoundLineJoinStyle];
		[selectionPath setLineJoinStyle:NSRoundLineJoinStyle];
        [selectionPath stroke];				
		//draw gradient	
		NSColor *topColor;
		NSColor *botColor;		
		if ([gesture isEqualToString:@"scrollzone"]) {		
			[[NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:0.5] set];			
			topColor = [NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:0.4];
			botColor = [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.4];			
		}else {
			topColor = [NSColor colorWithCalibratedRed:0.92 green:0.49 blue:0.34 alpha:0.9];
			botColor = [NSColor colorWithCalibratedRed:0.93 green:0.44 blue:0.46 alpha:0.9];			
		}		
		NSGradient *aGradient = [[NSGradient alloc] initWithStartingColor:topColor endingColor:botColor];
		[aGradient drawInBezierPath:selectionPath angle:90];	
		[aGradient release];		
	}
	
}

-(void)theEvent:(NSNotification*)notif{	
	if (![[notif name] isEqualToString:@"MPprefpaneZoneEvent"]) {		
		return;
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){                  
		self.gesture = [notif object];
		if ([gesture isEqualToString:@"0"]) {
			if (![[self superview] isMemberOfClass:[NSView class]]) {			
				[self setHidden:YES];			
				gesture = nil;			
			}else{
                //do not hide the scroll window zone and do not change it to zero either
                //NSLog(@"Reverting to scrollzone");
                gesture = @"scrollzone";                
            }	
		}else if ([gesture isEqualToString:@"scrollzone"]) {
			//only if called from the scroll window, not from main
			if ([[self superview] isMemberOfClass:[NSView class]]) {						
				NSDictionary *szone = [defaults objectForKey:@"scrollzone"];			
				mSelectionRect = [self zoneToRect:szone];
				[self setNeedsDisplay:YES];				
				[self setHidden:NO];				
			}else{
                //NSLog(@"Scroolbar zone request from outside scroll settings");
            }
		}else{			
			NSDictionary *zones = [defaults objectForKey:@"zones"];
			NSDictionary *zone = [zones objectForKey:gesture];
			mSelectionRect = [self zoneToRect:zone];
			[self setNeedsDisplay:YES];			
			[self setHidden:NO];		
		}
	}
	if ([[notif object] isKindOfClass:[NSEvent class]]){		
		if (activeHandle != noHandle){	
			//resize
			[self resizeWithHandle:activeHandle withEvent:[notif object]];
		}	
	}	
}

-(NSRect)zoneToRect:(NSDictionary*)zone{
	if (zone == nil){
		return NSMakeRect(HandleHalf+0.5,HandleHalf+0.5,[self frame].size.width-HandleSize-3,[self frame].size.height-HandleSize-3);		
	}else {
		float x = [[zone objectForKey:@"x"] floatValue];
		float w = [[zone objectForKey:@"w"] floatValue];
		float y = [[zone objectForKey:@"y"] floatValue];
		float h = [[zone objectForKey:@"h"] floatValue];
		float width = [self frame].size.width-HandleSize;
		float height = [self frame].size.height-HandleSize;
		return NSMakeRect(width*x+HandleHalf,height*y+HandleHalf,width*w,height*h);				
	}
}

-(void)saveZone{
	NSString *x = [[NSString stringWithFormat:@"%f",(mSelectionRect.origin.x-HandleHalf)/[self frame].size.width] substringWithRange:NSMakeRange(0,4)];
	NSString *y = [[NSString stringWithFormat:@"%f",(mSelectionRect.origin.y-HandleHalf)/[self frame].size.height] substringWithRange:NSMakeRange(0,4)];
	NSString *w = [[NSString stringWithFormat:@"%f",(mSelectionRect.size.width+HandleSize)/[self frame].size.width] substringWithRange:NSMakeRange(0,4)];
	NSString *h = [[NSString stringWithFormat:@"%f",(mSelectionRect.size.height+HandleSize)/[self frame].size.height] substringWithRange:NSMakeRange(0,4)];	
	if ([gesture isEqualToString:@"scrollzone"]) {
		[defaults setObject:[NSDictionary dictionaryWithObjectsAndKeys:x,@"x",y,@"y",w,@"w",h,@"h",nil] forKey:@"scrollzone"];
		[defaults synchronize];		
	}else {
		//add it to existing	
		NSMutableDictionary *dict = [[defaults objectForKey:@"zones"] mutableCopy];	
		[dict setObject:[NSDictionary dictionaryWithObjectsAndKeys:x,@"x",y,@"y",w,@"w",h,@"h",nil] forKey:gesture];
		//save
		[defaults setObject:dict forKey:@"zones"];
		[defaults synchronize];
		[dict release];		
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MPprefpaneMainEvent" object:@"ZoneChanged" userInfo:nil];	
	//NSLog(@"saved zone for %@ (%f,%f,%f,%f)",gesture,mSelectionRect.origin.x,mSelectionRect.origin.y,mSelectionRect.size.width,mSelectionRect.size.height);
}

- (void)drawHandlesInRect:(NSRect)bounds {
	if ([[self subviews] count] == 0){
		//make them
		[self drawHandleAtPoint:NSMakePoint(NSMinX(bounds), NSMinY(bounds)) tag:1];
		[self drawHandleAtPoint:NSMakePoint(NSMidX(bounds), NSMinY(bounds)) tag:2];
		[self drawHandleAtPoint:NSMakePoint(NSMaxX(bounds), NSMinY(bounds)) tag:3];
		[self drawHandleAtPoint:NSMakePoint(NSMinX(bounds), NSMidY(bounds)) tag:4];
		[self drawHandleAtPoint:NSMakePoint(NSMaxX(bounds), NSMidY(bounds)) tag:5];
		[self drawHandleAtPoint:NSMakePoint(NSMinX(bounds), NSMaxY(bounds)) tag:6];
		[self drawHandleAtPoint:NSMakePoint(NSMidX(bounds), NSMaxY(bounds)) tag:7];
		[self drawHandleAtPoint:NSMakePoint(NSMaxX(bounds), NSMaxY(bounds)) tag:8];		
	}else {
		//move them
		[[[self subviews] objectAtIndex:0] setFrame:NSMakeRect(NSMinX(bounds)-HandleHalf,NSMinY(bounds)-HandleHalf,HandleSize,HandleSize)];
		[[[self subviews] objectAtIndex:1] setFrame:NSMakeRect(NSMidX(bounds)-HandleHalf,NSMinY(bounds)-HandleHalf,HandleSize,HandleSize)];
		[[[self subviews] objectAtIndex:2] setFrame:NSMakeRect(NSMaxX(bounds)-HandleHalf,NSMinY(bounds)-HandleHalf,HandleSize,HandleSize)];
		[[[self subviews] objectAtIndex:3] setFrame:NSMakeRect(NSMinX(bounds)-HandleHalf,NSMidY(bounds)-HandleHalf,HandleSize,HandleSize)];
		[[[self subviews] objectAtIndex:4] setFrame:NSMakeRect(NSMaxX(bounds)-HandleHalf,NSMidY(bounds)-HandleHalf,HandleSize,HandleSize)];
		[[[self subviews] objectAtIndex:5] setFrame:NSMakeRect(NSMinX(bounds)-HandleHalf,NSMaxY(bounds)-HandleHalf,HandleSize,HandleSize)];
		[[[self subviews] objectAtIndex:6] setFrame:NSMakeRect(NSMidX(bounds)-HandleHalf,NSMaxY(bounds)-HandleHalf,HandleSize,HandleSize)];
		[[[self subviews] objectAtIndex:7] setFrame:NSMakeRect(NSMaxX(bounds)-HandleHalf,NSMaxY(bounds)-HandleHalf,HandleSize,HandleSize)];
	}	
}

- (void)drawHandleAtPoint:(NSPoint)point tag:(int)tag{
    //get a rectangle that's centered on the point but lined up with device pixels.
    NSRect handleBounds;
    handleBounds.origin.x = point.x - HandleHalf;
    handleBounds.origin.y = point.y - HandleHalf;
    handleBounds.size.width = HandleSize;
    handleBounds.size.height = HandleSize;
	//make imgview
	ZoneHandle *imgView = [[[ZoneHandle alloc] initWithFrame:handleBounds] autorelease];
    [handleImages setObject:imgView forKey:[NSNumber numberWithInt:tag]];
	[imgView setImageFrameStyle:NSImageFrameNone];
	//add image
    NSImage *handle = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[MagicPrefsMain class]] pathForImageResource:@"handle"]];
	[imgView setImage:handle];
	[handle release];
	//add tracking
    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:handleBounds options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%i",tag],@"tag",nil]];
    [imgView addTrackingArea:area];
    [area release];
	//add to view
	[self addSubview:imgView];	
}

-(void)mouseEntered:(NSEvent *)event {	
	activeHandle = [[(NSDictionary *)[event userData] objectForKey:@"tag"] intValue];	
	if (activeHandle == theMiddleLeftHandle || activeHandle == theMiddleRightHandle) [[NSCursor resizeLeftRightCursor] set];	
	if (activeHandle == theUpperMiddleHandle || activeHandle == theLowerMiddleHandle) [[NSCursor resizeUpDownCursor] set];
	if (activeHandle == theUpperLeftHandle || activeHandle == theLowerRightHandle) [leftCursor set];
	if (activeHandle == theUpperRightHandle || activeHandle == theLowerLeftHandle) [rightCursor set];		
}

-(void)mouseExited:(NSEvent *)event {
	activeHandle = noHandle;
	[self saveZone];	
	[[NSCursor arrowCursor] set];	
}

-(void)mouseDown:(NSEvent*)event {	
    NSPoint curPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	if ([self mouse:curPoint inRect:mSelectionRect]) {			
		//move
		[[NSCursor closedHandCursor] set];		
		[self moveWithEvent:event];		
	}
}

- (void)resizeWithHandle:(NSInteger)handle withEvent:(NSEvent *)event {
    while (1) {
        event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
		if ([event type] != NSLeftMouseUp) {            
			NSPoint newPoint = [self convertPoint:[event locationInWindow] fromView:nil];
            NSRect parentRect = [self frame];   
            //do not get stuck if the pointer gets outside the zone           
			if (newPoint.x > parentRect.size.width-HandleHalf) {                
                newPoint.x = parentRect.size.width-HandleHalf;
            }
			if (newPoint.y > parentRect.size.height-HandleHalf) {
                newPoint.y = parentRect.size.height-HandleHalf;               
            }            
            if (newPoint.x < HandleHalf) {
                newPoint.x = HandleHalf;
            }
            if (newPoint.y < HandleHalf) {
                newPoint.y = HandleHalf;
            }
            BOOL ok = [self resizeToPoint:newPoint];
            //update handle images
            NSString *handleImage = @"handle";
            if (ok) {
                handleImage = @"handle";
            }else{
                handleImage = @"handle_red";
            }
            ZoneHandle *imgView = [handleImages objectForKey:[NSNumber numberWithInt:activeHandle]];
            NSImage *handle = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[MagicPrefsMain class]] pathForImageResource:handleImage]];
            [imgView setImage:handle];
            [handle release];
            [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(restoreGrayHandle:) userInfo:imgView repeats:NO];
            [self setNeedsDisplay:YES];
		}else{
			break;		
		}
    }	
}

-(void)restoreGrayHandle:(NSTimer*)timer
{
    ZoneHandle *imgView = [timer userInfo];
    NSImage *handle = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[MagicPrefsMain class]] pathForImageResource:@"handle"]];
    [imgView setImage:handle];
    [handle release];
}

- (BOOL)resizeToPoint:(NSPoint)point {
	
    NSRect bounds = mSelectionRect;
	NSInteger handle = activeHandle; 
	
    // Is the user changing the width of the graphic?
    if (handle==theUpperLeftHandle || handle==theMiddleLeftHandle || handle==theLowerLeftHandle) {		
		// Change the left edge of the graphic.
        bounds.size.width = NSMaxX(bounds) - point.x;
        bounds.origin.x = point.x;		
    } else if (handle==theUpperRightHandle || handle==theMiddleRightHandle || handle==theLowerRightHandle) {		
		// Change the right edge of the graphic.
        bounds.size.width = point.x - bounds.origin.x;		
    }
	    
    // Is the user changing the height of the graphic?
    if (handle==theUpperLeftHandle || handle==theUpperMiddleHandle || handle==theUpperRightHandle) {		
		// Change the top edge of the graphic.
        bounds.size.height = NSMaxY(bounds) - point.y;
        bounds.origin.y = point.y;		
    } else if (handle==theLowerLeftHandle || handle==theLowerMiddleHandle || handle==theLowerRightHandle) {
		// Change the bottom edge of the graphic.
		bounds.size.height = point.y - bounds.origin.y;		
    }

	//dissalow flips and tiny zones
    if (bounds.size.width<25.0) {
        //NSLog(@"low width %f",bounds.size.width);        
		return NO;
    }	
    if (bounds.size.height<25.0) {
        //NSLog(@"low height %f",bounds.size.height);        
		return NO;
    }	
	
	if ([self zoneMakesSence:NSMakeRect(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height)] == FALSE) {
        //NSLog(@"no sence");
		return NO;
	}
	
    // Done.
    mSelectionRect = bounds;
    return YES;
}

- (void)moveWithEvent:(NSEvent *)theEvent {
    NSPoint lastPoint, curPoint;
    lastPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
    while (1) {
        theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
        curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		if (!NSEqualPoints(lastPoint, curPoint)) {
			//factor the change to origin
			float x = mSelectionRect.origin.x+curPoint.x-lastPoint.x;
			float y = mSelectionRect.origin.y+curPoint.y-lastPoint.y;
			//get maximum origin as to not push it off view
			float w = [self frame].size.width-mSelectionRect.size.width-HandleHalf;
			float h = [self frame].size.height-mSelectionRect.size.height-HandleHalf;
			if (x > HandleHalf && x < w && y > HandleHalf && y < h){
				NSRect newRect = NSMakeRect(x,y,mSelectionRect.size.width,mSelectionRect.size.height);
				if ([self zoneMakesSence:newRect] == TRUE) {
					mSelectionRect = newRect;
					[self setNeedsDisplay:YES];						
				}						
			}
			lastPoint = curPoint;			
		}
        if ([theEvent type] == NSLeftMouseUp) {
			[self saveZone];
			[[NSCursor arrowCursor] set];			
            break;
        }
    }
}

-(BOOL)zoneMakesSence:(NSRect)rect{
	//check if selection is within a acceptable rectangle and optionally if it contains a hotspot retangle

	//middle axis
	if ([gesture isEqualToString:@"1"]) {        
		if ([self rect:NSMakeRect(35,15,105,208) containsRect:rect inverse:NO] && [self rect:NSMakeRect(62,93,27,36) containsRect:rect inverse:YES]) {
			return YES;
		}else {			
			return NO;			
		}
	}	

	//left tap
	if ([gesture isEqualToString:@"9"]) {
		if ([self rect:NSMakeRect(5,39,70,180) containsRect:rect inverse:NO]) {
			return YES;
		}else {
			return NO;			
		}
	}	

	//right tap
	if ([gesture isEqualToString:@"10"]) {
		if ([self rect:NSMakeRect(75,39,70,180) containsRect:rect inverse:NO]) {
			return YES;
		}else {
			return NO;			
		}
	}		
	
	//stem tap
	if ([gesture isEqualToString:@"11"]) {
		if ([self rect:NSMakeRect(15,2,125,55) containsRect:rect inverse:NO] && [self rect:NSMakeRect(60,10,25,25) containsRect:rect inverse:YES]) {
			return YES;
		}else {		
			return NO;			
		}
	}
	
	//2 finger clicks & taps
	if ([gesture isEqualToString:@"2"] || [gesture isEqualToString:@"6"]) {
		if (rect.size.height > 75 && rect.size.width > 75) {
			return YES;
		}else {
			return NO;			
		}
	}	
	
	//3 finger clicks & taps
	if ([gesture isEqualToString:@"3"] || [gesture isEqualToString:@"7"]) {
		if (rect.size.height > 100 && rect.size.width > 100) {
			return YES;
		}else {
			return NO;			
		}
	}
	
	//4 finger clicks & taps
	if ([gesture isEqualToString:@"4"] || [gesture isEqualToString:@"8"]) {
		if (rect.size.height > 140 && rect.size.width > 140) {
			return YES;
		}else {		
			return NO;			
		}
	}	
	
	//2 finger swipes & pinches
	if ([gesture isEqualToString:@"21"] || [gesture isEqualToString:@"22"] || [gesture isEqualToString:@"23"] || [gesture isEqualToString:@"24"] || [gesture isEqualToString:@"33"] || [gesture isEqualToString:@"34"]) {
		if (rect.size.height > 75 && rect.size.width > 120) {
			return YES;
		}else {
			return NO;			
		}
	}	
	
	//3 finger swipes & pinches
	if ([gesture isEqualToString:@"25"] || [gesture isEqualToString:@"26"] || [gesture isEqualToString:@"27"] || [gesture isEqualToString:@"28"] || [gesture isEqualToString:@"35"] || [gesture isEqualToString:@"36"]) {
		if (rect.size.height > 140 && rect.size.width > 140) {
			return YES;
		}else {
			return NO;			
		}
	}	
	
	//apple stem drag left
	if ([gesture isEqualToString:@"31"]) {
		if ([self rect:NSMakeRect(3,4,91.5,75) containsRect:rect inverse:NO] && [self rect:NSMakeRect(4,5,87,36) containsRect:rect inverse:YES]) {        
			return YES;
		}else {			
			return NO;			
		}
	}	

	//apple stem drag right
	if ([gesture isEqualToString:@"32"]) {
		if ([self rect:NSMakeRect(58,4,91.5,75) containsRect:rect inverse:NO] && [self rect:NSMakeRect(58,5,87,36) containsRect:rect inverse:YES]) {        
			return YES;
		}else {			
			return NO;			
		}
	}
	
	//scrolling zone
	if ([gesture isEqualToString:@"scrollzone"]) {
		if (rect.size.height > 50 && rect.size.width > 50) {
			return YES;
		}else {		
			return NO;			
		}
	}		
	
	return YES;
}

-(BOOL)rect:(NSRect)container containsRect:(NSRect)containee inverse:(BOOL)inverse{
    BOOL ret;    
    NSColor *topColor;
    NSColor *botColor;	    
    if (inverse == NO) {
        ret = NSContainsRect(container,containee);               
		topColor = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.5];
        botColor = [NSColor colorWithCalibratedRed:0.8 green:0.8 blue:0.8 alpha:0.7];	        
    }else{
        ret = NSContainsRect(containee,container);
		topColor = [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:1.0];
        botColor = [NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:0.5];	    
    }
    if (ret == NO) {
        NSImage *compositeImage = [[NSImage alloc] initWithSize:NSMakeSize(collisionView.frame.size.width,collisionView.frame.size.height)];  
        [compositeImage setCacheMode:NSImageCacheNever];
        [compositeImage lockFocus];
        //draw
        NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRoundedRect:container xRadius:15.0 yRadius:15.0];        		
		NSGradient *aGradient = [[NSGradient alloc] initWithStartingColor:topColor endingColor:botColor];
		[aGradient drawInBezierPath:selectionPath angle:90];	
		[aGradient release];
        //end draw
        [compositeImage unlockFocus];    
        [collisionView setImage:compositeImage];	
        [compositeImage release];        
        [[collisionView animator] setAlphaValue:1.0];         
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(hideCollision:) userInfo:nil repeats:NO];
        //NSLog(@"Colide %i with %f %f %f %f",inverse,container.origin.x,container.origin.y,container.size.width, container.size.height);
        if (inverse == NO) {
            //also reset the zone in case it was stuck
            NSRect inter = NSIntersectionRect(container,containee);
            int diff = (containee.size.width-inter.size.width)+(containee.size.height-inter.size.height);
            if (diff > 10){                
                mSelectionRect = NSMakeRect(container.origin.x,container.origin.y,container.size.width-HandleHalf,container.size.height-HandleHalf);                 
                //NSLog(@"Unstuck zone with %i diff",diff);
            }  
        }        
    }
    return ret;
} 

-(void)hideCollision:(NSTimer*)timer{
       [[collisionView animator] setAlphaValue:0.0];             
}

@end
