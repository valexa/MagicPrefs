//
//  FeedBoardMainWindow.h
//  MagicPrefs
//
//  Created by Vlad Alexa on 4/15/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import "UrlConnection.h"
#import "AGKeychain.h"
#import "LayersView.h"

@interface FeedBoardMainWindow : NSWindow <UrlConnectionDelegate>{
		NSUserDefaults *defaults;
		NSString *action;	
		NSArray *credentials;
        NSProgressIndicator *spinner;		
		NSTextField *username;
		NSSecureTextField *password;
		NSButton *button;
		NSImageView *imageView;
		NSButton *keybutton;
		NSButton *speakButton;    
		LayersView *layersView;
        NSTextField *info;
        int newCount;
}

@property (nonatomic, retain, readwrite) NSString *action;
@property (nonatomic, retain, readwrite) NSArray *credentials;
@property (nonatomic, assign, readwrite) NSTextField *username;
@property (nonatomic, assign, readwrite) NSSecureTextField *password;
@property (nonatomic, assign, readwrite) NSButton *button;
@property (nonatomic, assign, readwrite) NSImageView *imageView;
@property (nonatomic, assign, readwrite) NSButton *keybutton;
@property (nonatomic, retain, readwrite) NSTextField *info;

- (void) shakeWindow:(NSWindow*)w;
- (void)animateChange:(id)object newrect:(NSRect)newrect;
-(NSArray *) validCredentials;
-(void)saveSetting:(id)object forKey:(NSString*)key;
-(void) dismiss;

-(NSString*)getGoogleCookie:(NSString*)user password:(NSString*)pass;
-(NSString*)getGoogleAuth:(NSString*)user password:(NSString*)pass;
-(void)getGoogle:(NSString*)user password:(NSString*)pass;
-(void)getGoogleList:(NSString*)user password:(NSString*)pass;
-(NSArray*)getXmlData:(NSData*)xmlData type:(NSString*)type;
-(NSDate*)dateFromZulu:(NSString*)str;
- (void)setDockBadge:(NSArray*)old versus:(NSArray*)new;
@end
