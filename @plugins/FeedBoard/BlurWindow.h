//
//  BlurWindow.h
//  FeedBoard
//
//  Created by Vlad Alexa on 1/16/11.
//  Copyright 2011 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void * CGSConnection;
OSStatus CGSNewConnection(const void **attributes, CGSConnection * id);
typedef void *CGSWindowFilterRef;
typedef int CGSWindowID;
CGError CGSNewCIFilterByName(CGSConnection cid, CFStringRef filterName, CGSWindowFilterRef *outFilter);
CGError CGSSetCIFilterValuesFromDictionary(CGSConnection cid, CGSWindowFilterRef filter, CFDictionaryRef filterValues);
CGError CGSAddWindowFilter(CGSConnection cid, CGSWindowID wid, CGSWindowFilterRef filter, int flags);

@interface BlurWindow : NSObject {

}

+(void)blurWindow:(NSWindow *)window;

@end
