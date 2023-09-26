//
//  Copyright (c) 2011 Vlad Alexa.
//	valexa@gmail.com
//	http://magicprefs.com/
//

#import <Cocoa/Cocoa.h>

@protocol MPPluginProtocol

+ (BOOL)initializeClass:(NSBundle*)theBundle;

+ (void)terminateClass;

@end

