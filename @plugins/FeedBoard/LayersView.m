//
//  LayersView.m
//  MagicPrefs
//
//  Created by Vlad Alexa on 4/25/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "LayersView.h"

const int width = 450;
const int height = 50;

@implementation LayersView

@synthesize timer,source;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		
		defaults = [NSUserDefaults standardUserDefaults];	
        
        NSArray *voices =[NSSpeechSynthesizer availableVoices];
        if ([voices count] > 0) {
            NSString *voice = [defaults objectForKey:@"voice"];
            if (!voice) voice = @"com.apple.speech.synthesis.voice.Alex";
            if (![voices containsObject:voice]) voice = [voices objectAtIndex:0];            
            synth = [[NSSpeechSynthesizer alloc] initWithVoice:@"com.apple.speech.synthesis.voice.Alex"];                    
        }else {
            NSLog(@"No available voices");
        }        
		
		screen = [[NSScreen mainScreen] frame];		
				
		timer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(cycleArticles) userInfo:nil repeats:YES];	
		
		cycle = 0;
		
		scroll = 0;
		
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
}

- (void)dealloc
{
    //NSLog(@"LayersView freed");
    [synth release];     
    [super dealloc];
}


- (BOOL)acceptsFirstResponder{
	return YES;
}

- (void)readData:(NSString*)keychain{
	self.source = keychain;
	
	//save existing items
	NSArray *oldviews = [[self subviews] copy];	
	
	//make new views
	NSMutableArray *newviews = [[NSMutableArray arrayWithCapacity:1] retain];
	
	//populate newviews
	NSArray *itemsArray = [self makeSortedArray:@"date" ascending:NO];	
	int c = 0;
	int new = 0;
	for (NSDictionary *dict in itemsArray){	
		ItemView *view; 
		if ([self itemIsNew:dict subviews:oldviews]){
			new +=1;
			view = [self newItemView:dict collumn:c animate:TRUE];				
		}else {
			view = [self newItemView:dict collumn:c animate:FALSE];												
		}
		[newviews addObject:view];
		[view release];
		c +=1;			
	}	
	
	//set dock badge
	if (new > 0) {
		NSDockTile *tile = [[NSApplication sharedApplication] dockTile];
		[tile setBadgeLabel:[NSString stringWithFormat:@"%i",new]];				
	}
	
	//remove existing items	
	for (ItemView *view in oldviews){
		[view removeFromSuperview];
	}
	
	//add new subviews
	[self setSubviews:newviews];
	
	[newviews release];	
	[oldviews release];	
	
	cycle = 0;		
}

-(BOOL)itemIsNew:(NSDictionary*)dict subviews:(NSArray*)subviews{
	//if just started do not animate with cached data
	if ([subviews count] == 0) return FALSE;
	for (ItemView *view in subviews){
		if ([view.data isEqualToDictionary:dict]){
			return FALSE;
		}
	}	
	return TRUE;
}

-(ItemView *)newItemView:(NSDictionary*)dict collumn:(int)c animate:(BOOL)animate{
	ItemView *item = [[ItemView alloc] initWithFrame:NSMakeRect(width*-1,screen.size.height-(height*(c+1)),width,height)]; 
	item.data = dict;
	[item setWantsLayer:YES];	
	if (animate == TRUE) {
		[NSTimer scheduledTimerWithTimeInterval:c target:self selector:@selector(dropDown:) userInfo:[NSDictionary dictionaryWithObjectsAndKeys:item,@"object",[NSNumber numberWithInt:c],@"row",nil] repeats:NO];																		
		//NSLog(@"Animated item at %i",c);		
	}else {
		[item setFrame:NSMakeRect(0,screen.size.height-(height*(c+1)),width,height)];
		//NSLog(@"Shown item at %i",c);		
	}
	return item;
}

-(NSArray*)makeSortedArray:(NSString*)string ascending:(BOOL)ascending{
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:1];
	NSDictionary *plist = [[[defaults objectForKey:@"FeedBoard"] objectForKey:@"settings"] objectForKey:source];		
	//merge all in one
	for (id name in plist){	
		[arr addObjectsFromArray:[plist objectForKey:name]];
	}
	//sort it	
	NSSortDescriptor *pathDescriptor = [[NSSortDescriptor alloc] initWithKey:string ascending:ascending selector:@selector(compare:)];
	NSArray *sortedArr = [arr sortedArrayUsingDescriptors:[NSArray arrayWithObjects:pathDescriptor, nil]];	
	[pathDescriptor release];	
	return sortedArr;
}

-(void) dropDown:(NSTimer*)sender {
	[self setNeedsDisplay:YES];
	NSDictionary *dict = [sender userInfo];
	//do not drop it down if it is allready dropped
	if ([[dict objectForKey:@"object"] frame].origin.x < 0) {
		[[[dict objectForKey:@"object"] animator] setFrame:NSMakeRect(0,screen.size.height-(height*([[dict objectForKey:@"row"] intValue]+1)),width,height)];			
	}
}

- (void)cycleArticles
{
	NSArray *subviews = [self subviews];		
    ItemView *current = [subviews objectAtIndex:cycle];
    if (!current) {
        NSLog(@"No view at %i",cycle);
        return;
    }
    
	if ([synth isSpeaking]) {
        return;
    }else {
        if ([defaults boolForKey:@"speak"] == YES) [synth performSelector:@selector(startSpeakingString:) withObject:[current toolTip] afterDelay:1.0];
    }    
    
	//put back last cycled view
	int c = 0;
	for (ItemView *view in subviews){
		if ([[NSString stringWithFormat:@"%1.f",[view frame].origin.x] isEqualToString:@"500"]) {
			[[view layer] setOpacity:0.5];				
			[[view animator] setFrame:NSMakeRect(0,screen.size.height-(height*(c+1))-(height*scroll),width,height)];
			//hack for 10.5 compatibility			
			if ([self osxVersion] < 0x1060) {			
				[view setFrame:NSMakeRect(0,screen.size.height-(height*(c+1))-(height*scroll),width,height)];
				[view setNeedsDisplay:YES];				
			}
		}
		c +=1;
	}	
	//reset cycle after we ran out of views
	if (cycle > [subviews count] && [subviews count] > 0) {
		//reset cycle
		cycle = 0;
		//scroll up
		scroll = 0;
		[self scroll:@"up"];
		if ([subviews count] > 10) {
			//look for new data
			[self refreshArticles];			
		}		
	}
	//scroll down if we are cycling out of screen
	if (cycle > ((screen.size.height/height)+(scroll*-1))) {
		scroll = cycle*-1;
		[self scroll:@"down"];
	}
    
	//cycle front current view	
    [[current layer] setOpacity:1.0];
    [[current animator] setFrame:NSMakeRect(500,screen.size.height/2,screen.size.width-550,100)];	
    //hack for 10.5 compatibility
    if ([self osxVersion] < 0x1060) {			
        [current setFrame:NSMakeRect(500,screen.size.height/2,screen.size.width-550,100)];
        [current setNeedsDisplay:YES];				
    }			
    cycled = current;	    
    
	cycle +=1;
}

- (void)refreshArticles{
	if ([source isEqualToString:@"google"]) {
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MPPluginFeedBoardEvent" object:@"refreshGoogle" userInfo:nil];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"VAFeedBoardEvent" object:@"refreshGoogle" userInfo:nil];		
	}	
}

- (void)keyDown:(NSEvent*)event{
	if ([[event charactersIgnoringModifiers] isEqualToString:@"1"]) {
		if (cycled.data) {
			NSURL *url = [NSURL URLWithString:[cycled.data objectForKey:@"link"]];
			[[NSWorkspace sharedWorkspace] openURL:url];
			[NSApp terminate:nil];
		}		
	}
	if ([[event charactersIgnoringModifiers] isEqualToString:@"2"]) {
		if (cycled.data) {
			NSURL *url = [NSURL URLWithString:[cycled.data objectForKey:@"source"]];
			[[NSWorkspace sharedWorkspace] openURL:url];
			[NSApp terminate:nil];
		}		
	}	
}

#pragma mark scrooling

- (void)scrollWheel:(NSEvent *)event {
	if ([event type] == 22){
		NSString *phase;
		if ([[event description] rangeOfString:@"scrollPhase"].location == NSNotFound) {
			phase = @"None";
		}else{
			NSString *object = [[[event description] componentsSeparatedByString:@" "] lastObject];				
			phase = [object substringWithRange:NSMakeRange(12,[object length]-12)];			
		}		
		if ([phase isEqualToString:@"None"]){
			if ([event deltaY] > 0) {
				//NSLog(@"Scrolling Top");
				//[self insertTop];
				[self scroll:@"up"];
			} 
			if ([event deltaY] < 0) {	
				//NSLog(@"Scrolling Bottom");	
				//[self insertBottom];				
				[self scroll:@"down"];				
			} 	
			if ([event deltaX] > 0) {
				//NSLog(@"Scrolling Left");			
			} 
			if ([event deltaX] < 0) {	
				//NSLog(@"Scrolling Right");				
			} 			
		}
		if ([phase isEqualToString:@"Begin"]){
			if ([event deltaY] > 0) {
				//NSLog(@"Scrolling TopHard");
				scroll = 0;
				[self scroll:@"up"];				
			} 
			if ([event deltaY] < 0) {	
				//NSLog(@"Scrolling BottomHard");
				scroll = ([[self subviews] count]-(screen.size.height/height))*-1;
				[self scroll:@"down"];
			} 	
			if ([event deltaX] > 0) {
				//NSLog(@"Scrolling LeftHard");			
			} 
			if ([event deltaX] < 0) {	
				//NSLog(@"Scrolling RightHard");				
			} 			
		}			
	}	
}

- (BOOL)scroll:(NSString*)dir{
	if ([[self subviews] count] == 0 || (screen.size.height/height) > [[self subviews] count]) return FALSE;
	//reset cycle to first on screen
	cycle = scroll*-1;
	//save scroll
	int s = scroll;
	NSArray *subviews = [self subviews];	
	if (scroll < 0) {
		if ([dir isEqualToString:@"up"]) scroll +=1;	
	}
	if (scroll > ([subviews count]-(screen.size.height/height))*-1) {
		if ([dir isEqualToString:@"down"]) scroll -=1;				
	}
	int r = 0;		
	for (ItemView *view in subviews){
		[[subviews objectAtIndex:r] setFrame:NSMakeRect(0,screen.size.height-(height*(r+1))-(height*scroll),width,height)];						
		r +=1;
	}	
	if (s != scroll) {
		return TRUE;		
	}else {
		return FALSE;
	}
}

- (SInt32) osxVersion{
	SInt32 version = 0;
	OSStatus rc0 = Gestalt(gestaltSystemVersion, &version);
	if(rc0 == 0){
		//NSLog(@"gestalt version=%x", version);						
	}else{
		//NSLog(@"Failed to get os version");
	}	
    return version;	
}

/*
- (BOOL)insertTop{
	if ([[self subviews] count] == 0) return FALSE; 
	//reset cycle
	cycle = 0;	
	NSUInteger index = [self indexOfItemBefore:[[self subviews] objectAtIndex:0]];
	if (index != NSNotFound) {
		//remove bottom item
		ItemView *bottom = [[self subviews] lastObject];	
		[bottom removeFromSuperview];			
		//add top item		
		[self createItemView:[itemsArray objectAtIndex:index] collumn:0 insert:TRUE animate:FALSE];					
		//rearange items
		NSArray *subviews = [self subviews];	
		int r = 0;		
		for (ItemView *view in subviews){
			[[subviews objectAtIndex:r] setFrame:NSMakeRect(0,screen.size.height-(height*(r+1)),width,height)];			
			r +=1;
		}		
	}else {
		//look for new data
		[self refreshArticles];		
		return FALSE;
	}	
	return TRUE;	
}

- (BOOL)insertBottom{
	if ([[self subviews] count] == 0) return FALSE;	
	//reset cycle
	cycle = 0;	
	NSUInteger index = [self indexOfItemAfter:[[self subviews] lastObject]];
	if (index != NSNotFound) {
		//remove top item
		ItemView *top = [[self subviews] objectAtIndex:0];			
		[top removeFromSuperview];			
		//add bottom item		
		[self createItemView:[itemsArray objectAtIndex:index] collumn:[[self subviews] count] insert:FALSE animate:FALSE];						
		//rearange items
		NSArray *subviews = [self subviews];	
		int r = 0;		
		for (ItemView *view in subviews){
			[[subviews objectAtIndex:r] setFrame:NSMakeRect(0,screen.size.height-(height*(r+1)),width,height)];				
			r +=1;		
		}		
	}else {
		//look for new data
		[self refreshArticles];		
		return FALSE;
	}	
	return TRUE;
}

-(NSUInteger)indexOfItemBefore:(ItemView*)view{
	NSUInteger index = [itemsArray indexOfObject:view.data];
	if (index != NSNotFound) {		
		if (index > 0) {
			return index-1;
		}else {
			//NSLog(@"Reached first item in array");
		}
	}else {
		NSLog(@"Index of item not found");
	}
	return NSNotFound;
}

-(NSUInteger)indexOfItemAfter:(ItemView*)view{
	NSUInteger index = [itemsArray indexOfObject:view.data];
	if (index != NSNotFound) {
		if (index < ([itemsArray count]-1)) {
			return index+1;
		}else {
			//NSLog(@"Reached last item in array");
		}
	}else {
		NSLog(@"Index of item not found");
	}
	return NSNotFound;
}
*/

#pragma mark foo

/*
 
-(void) centerAndBack:(id)sender{
	CAKeyframeAnimation *movement = [CAKeyframeAnimation animation];	
	movement.values = [NSArray arrayWithObjects:						   
					   [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(500, screen.size.height/2, 0.0f)],	
					   [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0.0f, 0.0f, 0.0f)],nil];
	
	movement.duration = 20;
	movement.delegate = sender;		
	[[sender layer] addAnimation:movement forKey:@"transform"];	
}

-(void) scaleIt:(id)sender {
	CAKeyframeAnimation *movement = [CAKeyframeAnimation animation];	
	movement.values = [NSArray arrayWithObjects:						   
					   [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.5f, 0.5f,1.0f)],nil];	
	
	movement.duration = 2;
	movement.delegate = sender;		
	[[sender layer] addAnimation:movement forKey:@"transform"];
}
 
-(void) flipIt:(id)sender direction:(NSString*)direction{
	NSTimeInterval duration = 0.5;
	CAKeyframeAnimation *rotation = [CAKeyframeAnimation animation];
	if ([direction isEqualToString:@"left"]) {
		rotation.values = [NSArray arrayWithObjects:
						   [NSValue valueWithCATransform3D:CATransform3DMakeRotation(0.0f, 0.0f, 1.0f, 0.0f)],
						   [NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI, 0.0f, 1.0f, 0.0f)],nil];
	} else if ([direction isEqualToString:@"right"]) {
		rotation.values = [NSArray arrayWithObjects:
						   [NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI, 0.0f, 1.0f, 0.0f)],
						   [NSValue valueWithCATransform3D:CATransform3DMakeRotation(0.0f, 0.0f, 1.0f, 0.0f)],nil];
	} else {
		//left and right
		rotation.values = [NSArray arrayWithObjects:
						   [NSValue valueWithCATransform3D:CATransform3DMakeRotation(0.0f, 0.0f, 1.0f, 0.0f)],
						   [NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI, 0.0f, 1.0f, 0.0f)],
						   [NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI * 2, 0.0f, 1.0f, 0.0f)],nil];
		duration *= 2;
	}
	
	rotation.duration = duration;
	rotation.delegate = sender;	
	[[sender layer] addAnimation:rotation forKey:@"transform"];
	
}

-(void)rotateIt:(id)sender{
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
	animation.values = [NSArray arrayWithObjects:           // i.e., Rotation values for the 3 keyframes, in RADIANS
						[NSNumber numberWithFloat:0.0 * M_PI], 
						[NSNumber numberWithFloat:1.0 * M_PI], 
						[NSNumber numberWithFloat:2.0 * M_PI], nil]; 
	animation.keyTimes = [NSArray arrayWithObjects:     // Relative timing values for the 3 keyframes
						  [NSNumber numberWithFloat:0], 
						  [NSNumber numberWithFloat:.5], 
						  [NSNumber numberWithFloat:1.0], nil]; 
	animation.timingFunctions = [NSArray arrayWithObjects:
								 [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],        // from keyframe 1 to keyframe 2
								 [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn], nil]; // from keyframe 2 to keyframe 3
	
	animation.removedOnCompletion = NO;	
	animation.fillMode = kCAFillModeForwards;	
	animation.duration = 2.5;
	animation.cumulative = YES;
	animation.repeatCount = 1;	
	[[sender layer] addAnimation:animation forKey:nil];
}
*/


@end
