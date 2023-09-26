//
//  LayersView.h
//  MagicPrefs
//
//  Created by Vlad Alexa on 4/25/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>
#import "ItemView.h"

@interface LayersView : NSView {
	ItemView *cycled;
	NSString *source;	
	NSUserDefaults *defaults;
	NSRect screen;
	NSTimer *timer;
	int cycle;
	int scroll;
    NSSpeechSynthesizer *synth;    
}

@property (nonatomic, assign) NSString *source;
@property (nonatomic, assign) NSTimer *timer;

-(NSArray*)makeSortedArray:(NSString*)string ascending:(BOOL)ascending;
- (void)readData:(NSString*)keychain;
-(BOOL)itemIsNew:(NSDictionary*)dict subviews:(NSArray*)subviews;
-(ItemView *)newItemView:(NSDictionary*)dict collumn:(int)c animate:(BOOL)animate;
- (void)refreshArticles;
- (BOOL)scroll:(NSString*)dir;
- (SInt32) osxVersion;

@end
