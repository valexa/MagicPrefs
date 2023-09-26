//
//  LaunchButton.m
//  LaunchBoard
//
//  Created by Vlad Alexa on 12/14/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "LaunchButton.h"

static int iconSize = 64;

#if PLUGIN //set in project's GCC_PREPROCESSOR_DEFINITIONS
	#define OBSERVER_NAME_STRING @"MPPluginLaunchBoardButtonEvent"
	#define MAIN_OBSERVER_NAME_STRING @"MPPluginLaunchBoardEvent"
#else
	#define OBSERVER_NAME_STRING @"VALaunchBoardButtonEvent"
	#define MAIN_OBSERVER_NAME_STRING @"VALaunchBoardEvent"
#endif

@implementation LaunchButton

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.	
		isEditing = NO;		
		holding = NO;
		[self setWantsLayer:YES];
		[self setFocusRingType:NSFocusRingTypeNone];
		[self setButtonType:NSMomentaryChangeButton];					
		[self setImagePosition:NSImageAbove];
		[self setBordered:NO];
		[self.cell setLineBreakMode:NSLineBreakByTruncatingTail];		
		//add tracking
		NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:frame options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:nil];
		[self addTrackingArea:area];
		[area release];	
		//register for notifications
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:OBSERVER_NAME_STRING object:nil];
		//add delete button
		deleteButton = [[NSButton alloc] initWithFrame:NSMakeRect(0,0,28,28)];	
    	NSImage *x = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"delete.png"]];		
		[deleteButton setImage:x];
		[x release];
		[deleteButton setTarget:self]; 
		[deleteButton setAction:@selector(deleteIcon)];				
		[deleteButton setToolTip:@"Remove the application, to have it show again launch it manually"];									
		[deleteButton setFocusRingType:NSFocusRingTypeNone];
		[deleteButton setBordered:NO];	
		[deleteButton setButtonType:NSMomentaryChangeButton];		
		[deleteButton setHidden:YES];
		[self addSubview:deleteButton];
		[deleteButton release];		
    }
    return self;
}

-(void)dealloc{
	//NSLog(@"LaunchButton freed");
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];	
	[super dealloc];
}

- (BOOL)becomeFirstResponder{
	//NSLog (@"LaunchButton becomeFirstResponder");	
	return YES;
}

- (BOOL)resignFirstResponder{
	//NSLog (@"LaunchButton did resignFirstResponder");	
	return YES;
}

-(void)deleteIcon{
	//NSLog(@"delete %@",[self alternateTitle]);
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"deleteIcon" userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[self tag]] forKey:@"tag"]];	
}

-(void)theEvent:(NSNotification*)notif{		
	if (![[notif name] isEqualToString:OBSERVER_NAME_STRING]) {		
		return;
	}	
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]]){
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){
		if ([[notif object] isEqualToString:@"startedEditing"]){
			isEditing = YES;
			[deleteButton setHidden:NO];	
			[self animateWobble:self];
		}							
		if ([[notif object] isEqualToString:@"stoppedEditing"]){
			if (isEditing == YES) {
				isEditing = NO;	
				[deleteButton setHidden:YES];
			}
		}									
	}			
}

- (void)animateWobble:(NSView*)theView{
	
	[theView.layer removeAnimationForKey:@"rotationAnimation"];
	
	CABasicAnimation* rotationAnimation;
	rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
	rotationAnimation.fromValue = [NSNumber numberWithFloat: -M_PI * 0.01];
	rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 0.01];		
	rotationAnimation.duration = 0.2;
	rotationAnimation.cumulative = NO;      
	rotationAnimation.removedOnCompletion = YES;
	rotationAnimation.autoreverses = YES;	
	rotationAnimation.repeatCount = 1e100f; 
	rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	
	[theView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];			
}

- (void)viewDidMoveToSuperview{
	//we lose animation when moved around superviews so lets's do this
	if (isEditing == YES && [deleteButton isHidden] == NO) {
		[self animateWobble:self];
	}
}

- (void)mouseDown:(NSEvent *)theEvent{	
	if (isEditing == YES) {
		//move
		[[NSCursor closedHandCursor] set];		
		[self moveWithEvent:theEvent];			
	}else {	
		[NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(checkMouseHeld:) userInfo:[NSDictionary dictionaryWithObject:theEvent forKey:@"event"] repeats:NO];			
	}	
	holding = YES;	
}

- (void)mouseUp:(NSEvent *)theEvent{	
	if (isEditing == YES) {
		//[[NSCursor openHandCursor] set];
	}else {
		[self performClick:nil];		
	}
	holding = NO;	
}


-(void) checkMouseHeld:(NSTimer*)theTimer{
	NSEvent *theEvent = [[theTimer userInfo] objectForKey:@"event"];
	if (holding == YES) {
		//NSLog(@"Button held for 3 seconds, should start to shake and not trigger click");
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"editLaunchBoard" userInfo:nil];				
		//move
		[[NSCursor closedHandCursor] set];	
		[self moveWithEvent:theEvent];		
	}
}

-(void)mouseEntered:(NSEvent *)event {	
	if (isEditing == YES) {
		[[NSCursor openHandCursor] set];		
	} else if (![self isEnabled]) {
		[[NSCursor operationNotAllowedCursor] set];			
	}else {
		[[NSCursor pointingHandCursor] set];				
	}
}

-(void)mouseExited:(NSEvent *)event {
	[[NSCursor arrowCursor] set];	
}

- (void)moveWithEvent:(NSEvent *)theEvent {	
	NSRect screen = [[NSScreen mainScreen] frame];	
	int size = [self frame].size.width;
	NSRect oldframe = [self frame];	
	NSView *parent = [self superview];	
	NSRect parentRect = [parent frame];	
    NSPoint lastPoint, curPoint;
    lastPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];

    while (1) {
        theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
		NSPoint windowPoint = [theEvent locationInWindow];
		if (windowPoint.x >= screen.size.width-100) {
			holding = NO;			
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"swapIconToRightPage" userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[self tag]] forKey:@"tag"]];			
			break;				
		}
		if (windowPoint.x <= 100) {
			holding = NO;			
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"swapIconToLeftPage" userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[self tag]] forKey:@"tag"]];			
			break;				
		}		
        curPoint = [parent convertPoint:windowPoint fromView:nil];
		if (!NSEqualPoints(lastPoint, curPoint)) {			
			//factor the change to origin			
			float x = curPoint.x-(size/2);
			float y = curPoint.y-(size/2);					
			//change values as to not push it off view
			if (y < 0) y = 0;
			if (x < 0) x = 0;				
			if (x+size > parentRect.size.width) x = parentRect.size.width-size;
			if (y+size > parentRect.size.height) y = parentRect.size.height-size;
			NSPoint hitTestPoint = [[parent superview] convertPoint:curPoint fromView:parent];
			NSButton *hit = (NSButton*)[parent hitTest:hitTestPoint];			
			if (hit != nil && hit != self && [hit isKindOfClass:[LaunchButton class]]) {
				NSRect tmpframe = hit.frame;				
				if ([self collideWith:hit]) {
					oldframe = tmpframe;					
					self.frame = tmpframe;	
				}				
			}else {
				if (abs(oldframe.origin.x-x) < 40 && abs(oldframe.origin.y-y) < 40){
					self.frame = NSMakeRect(x,y,size,size);					
				}				
			}		
			lastPoint = curPoint;			
		}
        if ([theEvent type] == NSLeftMouseUp) {
			holding = NO;			
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:MAIN_OBSERVER_NAME_STRING object:@"saveLaunchBoard" userInfo:nil];			
            break;			
        }
    }
}


-(BOOL)collideWith:(NSButton*)b{
	NSRect screen = [[NSScreen mainScreen] frame];
	int colMax = floor(screen.size.width/(iconSize*2))-2;	
	NSMutableArray *switchWith = [NSMutableArray arrayWithCapacity:1];
	NSView *parent = [self superview];
	NSArray *parentViews = [parent subviews];	
	int count = [parentViews indexOfObject:b];
	NSString *dir = [self movementDirectionFrom:CGPointMake(self.frame.origin.x,self.frame.origin.y) to:CGPointMake(b.frame.origin.x,b.frame.origin.y) treshold:iconSize max:150];
	if (dir) {
		//move the icons around
		if ([dir isEqualToString:@"top"]) {
			//NSLog(@"%@ collision with %@, move this and next %i right ",dir,[[b attributedTitle] string],colMax-1);
			for (int i = count; i<count+colMax; i++){
				NSButton *b1 = [parentViews objectAtIndex:i];
				[self moveIconRight:b1 parent:parent capAware:YES];																
				[switchWith addObject:b1];
			}					
		}
		if ([dir isEqualToString:@"bottom"]) {
			//NSLog(@"%@ collision with %@, move this and previous %i left",dir,[[b attributedTitle] string],colMax-1);
			for (int i = count; i>count-colMax; i--){
				NSButton *b1 = [parentViews objectAtIndex:i];
				[self moveIconLeft:b1 parent:parent capAware:YES];
				[switchWith addObject:b1];
			}						
		}
		if ([dir isEqualToString:@"right"]) {
			[self moveIconRight:b parent:parent capAware:NO];
			[switchWith addObject:b];
			//NSLog(@"%@ collision with %@, move just this one to left",dir,[[b attributedTitle] string]);			
		}
		if ([dir isEqualToString:@"left"]) {					
			[self moveIconLeft:b parent:parent capAware:NO];
			[switchWith addObject:b];
			//NSLog(@"%@ collision with %@, move just this one to left",dir,[[b attributedTitle] string]);			
		}					
	}else {
		return NO;
	}
	//update the ordering inside the subviews of the parent	
	if ([switchWith count] > 0) {
		if ([switchWith count] == 1) {
			//switch with self
			[self switchView:self withView:[switchWith lastObject] inParent:parent];			
		}else {
			//put self before the first (this reorders everything)
			int index = [parentViews indexOfObject:[switchWith objectAtIndex:0]];
			[self moveView:self toIndex:index inParent:parent];				
		}
	}
	return YES;
}

-(void)moveView:(NSView*)view toIndex:(int)index inParent:(NSView*)parent{
	if (index == 0) {
		//special case at 0 with no view before this
		NSView *after_into = [[parent subviews] objectAtIndex:index];
		[parent addSubview:view positioned:NSWindowBelow relativeTo:after_into];		
	}else {
		NSView *before_into = [[parent subviews] objectAtIndex:index-1];
		[parent addSubview:view positioned:NSWindowAbove relativeTo:before_into];		
	}	
}

-(void)switchView:(NSView*)from withView:(NSView*)into inParent:(NSView*)parent{
	int index_from = [[parent subviews] indexOfObject:from];
	int index_into = [[parent subviews] indexOfObject:into];
	int diff = index_from-index_into;
	int temp_index_from = index_into+diff;
	int temp_index_into = index_from-diff;
		
	if (temp_index_into == 0) {
		//special case at 0 with no view before this
		NSView *after_into = [[parent subviews] objectAtIndex:temp_index_into];
		[parent addSubview:from positioned:NSWindowBelow relativeTo:after_into];				
	}else {
		NSView *before_into = [[parent subviews] objectAtIndex:temp_index_into-1];
		[parent addSubview:from positioned:NSWindowAbove relativeTo:before_into];		
	}
	
	if (temp_index_from == 0) {
		//special case at 0 with no view before this
		NSView *after_from = [[parent subviews] objectAtIndex:temp_index_from];	
		[parent addSubview:into positioned:NSWindowBelow relativeTo:after_from];		
	}else {
		NSView *before_from = [[parent subviews] objectAtIndex:temp_index_from-1];	
		[parent addSubview:into positioned:NSWindowAbove relativeTo:before_from];		
	}
	
	int new_index_from = [[parent subviews] indexOfObject:from];
	int new_index_into = [[parent subviews] indexOfObject:into];	
	if (new_index_from != index_into || new_index_into != index_from) {
		NSLog(@"Error switching view at %i (now %i) with the one at %i (now %i)",index_from,new_index_from,index_into,new_index_into);
	}else {
		//NSLog(@"Switched view at %i with the one at %i",index_from,index_into);		
	}	
}

-(void)moveIconLeft:(NSView*)b parent:(NSView*)parent capAware:(BOOL)capAware{
	NSRect parentRect = [parent frame];	 
	float x;
	float y;	
	if (b.frame.origin.x < iconSize && capAware == YES) {		
		//if it's the first in the row move one column down as last	
		x = parentRect.size.width-iconSize-20;	
		y = b.frame.origin.y-(iconSize*2)+4;				
	}else {		
		//move to the left
		x = b.frame.origin.x-(iconSize*2)+4;		
		y = b.frame.origin.y;						
	}		
	b.frame = NSMakeRect(x,y,b.frame.size.width,b.frame.size.height);			
}

-(void)moveIconRight:(NSView*)b parent:(NSView*)parent capAware:(BOOL)capAware{
	NSRect parentRect = [parent frame];	
	float x;
	float y;	
	if (b.frame.origin.x > parentRect.size.width-iconSize*3 && capAware == YES) {
		//if it's the last in the row move one column up as first	
		x = 0;		
		y = b.frame.origin.y+(iconSize*2)-4;		
	}else {
		//move to the right
		x = b.frame.origin.x+(iconSize*2)-4;		
		y = b.frame.origin.y;
	}	
	b.frame = NSMakeRect(x,y,b.frame.size.width,b.frame.size.height);			
}

-(NSString*)movementDirectionFrom:(CGPoint)from to:(CGPoint)to treshold:(int)treshold max:(int)max{
	NSString *dir = nil;
	float xdiff = to.x-from.x;
	float ydiff = to.y-from.y;	
	
	if (CGPointEqualToPoint(from,to)) {
		NSLog(@"There is no movement");
		return nil;
	}	
	
	if (abs(xdiff) < treshold && abs(ydiff) < treshold) {
		//NSLog(@"No movement in either direction above treshold (x:%f y:%f)",xdiff,ydiff);		
		return nil;		
	}
	
	if (abs(xdiff) + abs(ydiff) > max) {
		//NSLog(@"Movement above max (x:%f y:%f)",xdiff,ydiff);		
		return nil;		
	}	
	
	if (abs(xdiff) == abs(ydiff)) {
		NSLog(@"Movement from two directions of equal strengths (x:%f y:%f)",xdiff,ydiff);
	}else {	
		if (abs(xdiff) > abs(ydiff)) {
			//x movement is greatest
			if (xdiff > 0) {
				dir = @"left";				
			}else {
				dir = @"right";
			}
		}else {
			//y movement is greatest			
			if (ydiff > 0) {
				dir = @"bottom";				
			}else {
				dir = @"top";
			}			
		}		
	}	
	
	return dir;
}

@end
