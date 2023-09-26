//
//  LaunchButton.h
//  LaunchBoard
//
//  Created by Vlad Alexa on 12/14/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CAMediaTimingFunction.h>

@interface LaunchButton : NSButton {

	BOOL holding;
	BOOL isEditing;
	NSButton *deleteButton;
	
}

-(void)animateWobble:(NSView*)theView;
-(void)moveWithEvent:(NSEvent *)theEvent;
-(NSString*)movementDirectionFrom:(CGPoint)from to:(CGPoint)to treshold:(int)treshold max:(int)max;
-(BOOL)collideWith:(NSButton*)b;
-(void)moveView:(NSView*)view toIndex:(int)index inParent:(NSView*)parent;
-(void)switchView:(NSView*)from withView:(NSView*)into inParent:(NSView*)parent;
-(void)moveIconLeft:(NSView*)b parent:(NSView*)parent capAware:(BOOL)capAware;
-(void)moveIconRight:(NSView*)b parent:(NSView*)parent capAware:(BOOL)capAware;

@end
