//
//  FeedBoard.h
//  FeedBoard
//
//  Created by Vlad Alexa on 4/25/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "MPPluginInterface.h"

@class FeedBoardMainWindow;

@interface FeedBoard : NSObject<MPPluginProtocol> {

	NSUserDefaults *defaults;
	FeedBoardMainWindow *window;
}

-(void)allocOnNewThread;
-(void)saveSetting:(id)object forKey:(NSString*)key;

@end
