//
//  VAUserDefaults.h
//  MagicPrefs
//
//  Created by Vlad Alexa on 1/3/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface VAUserDefaults : NSObject {

	NSString *domain;
	
}

- (id)initWithPlist:(NSString *)plist;
- (NSDictionary*)dictionaryRepresentation;
- (void)notification;
- (void)synchronize;

- (id)objectForKey:(NSString *)arg1;
- (BOOL)boolForKey:(NSString *)arg1;
- (long long)integerForKey:(NSString *)arg1;

- (void)setObject:(id)value forKey:(NSString*)key;
- (void)setBool:(BOOL)value forKey:(NSString*)key;
- (void)setInteger:(long long)value forKey:(NSString*)key;

@end
