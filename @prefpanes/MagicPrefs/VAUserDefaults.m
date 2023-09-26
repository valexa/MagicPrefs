//
//  VAUserDefaults.m
//  MagicPrefs
//
//  Created by Vlad Alexa on 1/3/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "VAUserDefaults.h"

// CFPreferencesSynchronize does not also synchronize with NSUserDefaults, any we notify the app to do -synchronize
// other code using -(void)saveSetting:(id)object forKey:(NSString*)key must on a case basis call synchronize

@implementation VAUserDefaults

- (id)initWithPlist:(NSString *)plist{	
    self = [super init];
	if (self) {	
		
		domain = [[plist stringByReplacingOccurrencesOfString:@".plist" withString:@""] retain];
		
		if (domain) {
			//NSLog(@"VAUserDefaults loaded for %@",domain);					
		}else {
			NSLog(@"VAUserDefaults failed to load for %@",domain);			
		}	

	}	
	return self;
}

- (void)dealloc {
	[domain release];
	[super dealloc];
}

- (NSDictionary*)dictionaryRepresentation{	
	return [[NSUserDefaults standardUserDefaults] persistentDomainForName:domain];
}
	
- (void)notification{
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"VAUserDefaultsUpdate" object:domain userInfo:nil];
	//NSLog(@"VAUserDefaultsUpdate");	
}

- (void)synchronize{
	//NSLog(@"sync , changes will be lost if you read something between setting and synchronizing");
	CFPreferencesSynchronize((CFStringRef)domain,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);	
	[self notification];	
}

- (id)objectForKey:(NSString *)arg1{			
	NSDictionary *dict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:domain];
	return [dict objectForKey:arg1];
}
- (BOOL)boolForKey:(NSString *)arg1{
	NSDictionary *dict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:domain];
	return [[dict objectForKey:arg1] boolValue];
}
- (long long)integerForKey:(NSString *)arg1{
	NSDictionary *dict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:domain];
	return [[dict objectForKey:arg1] intValue];	
}

- (void)setObject:(id)value forKey:(NSString*)key{		
	CFPreferencesSetValue((CFStringRef)key,value,(CFStringRef)domain,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);	
}
- (void)setBool:(BOOL)value forKey:(NSString*)key{
	CFPreferencesSetValue((CFStringRef)key,[NSNumber numberWithBool:value],(CFStringRef)domain,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);	
}
- (void)setInteger:(long long)value forKey:(NSString*)key{
	CFPreferencesSetValue((CFStringRef)key,[NSNumber numberWithInt:value],(CFStringRef)domain,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);	
}

@end
