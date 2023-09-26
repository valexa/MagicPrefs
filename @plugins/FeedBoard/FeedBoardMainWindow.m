//
//  FeedBoardMainWindow.m
//  MagicPrefs
//
//  Created by Vlad Alexa on 4/15/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "FeedBoardMainWindow.h"

#if PLUGIN //set in project's GCC_PREPROCESSOR_DEFINITIONS
	#define OBSERVER_NAME_STRING @"MPPluginFeedBoardEvent"
#else
	#define OBSERVER_NAME_STRING @"VAFeedBoardEvent"
#endif

#define KEYCHAIN_NAME_STRING @"FeedBoard"

@implementation FeedBoardMainWindow

@synthesize action,credentials,spinner,username,password,button,imageView,keybutton,info;


- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    if (self != nil) {
		
		//register for notifications		
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:OBSERVER_NAME_STRING object:nil suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];			
		//NSLog(@"Registered %@",OBSERVER_NAME_STRING);		
		
		//get defaults
		defaults = [NSUserDefaults standardUserDefaults];		
		
		[self setLevel:NSScreenSaverWindowLevel];					
        [self setOpaque:NO];			
		[self setBackgroundColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.8]];		
		
		NSRect screen = [[NSScreen mainScreen] frame];			
		
		username = [[NSTextField alloc] initWithFrame: NSMakeRect((screen.size.width/2)-140, screen.size.height/1.5+30, 0, 22)]; 
		[username setBezelStyle:NSRoundedBezelStyle];
        [username setFocusRingType:NSFocusRingTypeNone];        
		[[self contentView] addSubview:username];
		
		password = [[NSSecureTextField alloc] initWithFrame: NSMakeRect((screen.size.width/2)-140, screen.size.height/1.5-5, 0, 22)]; 
		[password setBezelStyle:NSRoundedBezelStyle];
        [password setFocusRingType:NSFocusRingTypeNone];
        [password.cell setSendsActionOnEndEditing:NO];
        [password setTarget:self];        
        [password setAction:@selector(saveCredentials)];        
		[[self contentView] addSubview:password];				
		
		button = [[NSButton alloc] initWithFrame:NSMakeRect((screen.size.width/2)-140, screen.size.height/1.5-45, 0, 22)];										
		[button setState:NSOffState];
		[button setTarget:self]; 
		[button setAction:@selector(saveCredentials)];	
		[button setBezelStyle:NSRecessedBezelStyle];
		[button setTitle:@"Save to keychain"];
		[[self contentView] addSubview:button];
		
		imageView = [[NSImageView alloc] initWithFrame:NSMakeRect((screen.size.width/2)+70, screen.size.height/1.5-15, 0, 0)];
		NSImage *img = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"keychain.tiff"]];		
		[imageView setImage:img];
		[img release];		
		[imageView setImageScaling:NSScaleToFit];
		[[self contentView] addSubview:imageView];	
		
		keybutton = [[NSButton alloc] initWithFrame:NSMakeRect(screen.size.width-70, screen.size.height-80, 38, 38)];										
		[keybutton setTarget:self]; 
		[keybutton setAction:@selector(clearCredentials)];	
		img = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"keychain.tiff"]];
		[img setSize:NSMakeSize(38,38)];
		[keybutton setImage:img];
		[img release];
		[keybutton setBordered:NO];
		[keybutton setImagePosition: NSImageOnly];	
		[keybutton setButtonType:NSMomentaryChangeButton];	
		[keybutton.cell setRefusesFirstResponder:YES];		
		[[self contentView] addSubview:keybutton];	
        
        speakButton = [[NSButton alloc] initWithFrame:NSMakeRect((screen.size.width/2)-20, screen.size.height-80, 38, 38)];
        [speakButton setTarget:self]; 
        [speakButton setAction:@selector(speakToggle)];	
        [img setSize:NSMakeSize(38,38)];
		img = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"speak.png"]];        
        [speakButton setImage:img];
        [img release];
        [speakButton setBordered:NO];
        [speakButton setImagePosition: NSImageOnly];	
        [speakButton setButtonType:NSMomentaryChangeButton];	
        [speakButton.cell setRefusesFirstResponder:YES];		
        [[self contentView] addSubview:speakButton];     
        if ([defaults boolForKey:@"speak"] == YES) {
            [speakButton setAlphaValue:0.5];        
        }else {
            [speakButton setAlphaValue:0.2];        
        }        
		
		//spinner
		spinner = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(screen.size.width/2-16, screen.size.height/2+32, 32, 32)]; 
		[spinner setIndeterminate:YES];
		[spinner setDisplayedWhenStopped:FALSE];
		[spinner setStyle:NSProgressIndicatorSpinningStyle];
		[[self contentView] addSubview:spinner];
        
        //info
        info = [[NSTextField alloc] initWithFrame:NSMakeRect((screen.size.width/2)-250,screen.size.height/2,500,17)];
        [info setAlignment:NSCenterTextAlignment];
        [info setTextColor:[NSColor whiteColor]];
        [info setBackgroundColor:[NSColor clearColor]];        
        [info setEditable:NO];
        [info setBezeled:NO];
        [info setAlphaValue:0.1];		
        [[self contentView] addSubview:info];
		
		[password setHidden:YES];
		[username setHidden:YES];
		[button setHidden:YES];
		[imageView setHidden:YES];
		[keybutton setHidden:YES];	
					
    }
    return self;
}


- (void)dealloc {
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];	
	[password release];
	[username release];
	[button release];
    [keybutton release];
    [speakButton release];
	[imageView release];
	[info release];
	[super dealloc];
}

- (BOOL)acceptsFirstResponder{
	return YES;
}

-(BOOL)canBecomeKeyWindow{
	return YES;
}

-(BOOL)canBecomeMainWindow{
	return YES;
}

- (void)mouseUp:(NSEvent*)event{
	if ([self isKeyWindow]) {
		[self dismiss];
	}		
}

-(void) dimHalf {
	[self setAlphaValue:0.5];	
}

-(void) dimFull {	
	[self setAlphaValue:1.0];	
}

-(void)theEvent:(NSNotification*)notif{	
	NSRect screen = [[NSScreen mainScreen] frame];			
	if (![[notif name] isEqualToString:OBSERVER_NAME_STRING]) {		
		return;
	}		
	if ([[notif object] isKindOfClass:[NSString class]]){	
		if ([[notif object] isEqualToString:@"refreshGoogle"]){	
			self.action = [notif object];            
            if ( credentials == nil) {
                self.credentials = [self validCredentials];	
            }
			[self getGoogle:[credentials objectAtIndex:0] password:[credentials objectAtIndex:1]];					
			return;
		}		
		if ([[notif object] isEqualToString:@"dismiss"]){	
            [self dismiss];
            return;
        }    
		if ([[notif object] isEqualToString:@"hide"]){	
			[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(dimHalf) userInfo:nil repeats:NO];			
			[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(dismiss) userInfo:nil repeats:NO];						
		}else {
			//hide it is showing
			if ([self isKeyWindow]) {
				[self dismiss];
				return;
			}
			self.action = [notif object];			
			self.credentials = [self validCredentials];			
			//show if dismissed
			//[self setAlphaValue:0.7];
			[self makeMainWindow];			
			[self makeKeyAndOrderFront:nil];	
			[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(dimFull) userInfo:nil repeats:NO];							
			if (credentials == nil) return;				
		}				
		if ([[notif object] isEqualToString:@"readGoogle"]){
			[keybutton setHidden:NO];				
			layersView = [[LayersView alloc] initWithFrame:NSMakeRect(10,10,screen.size.width,screen.size.height)];			
			[layersView readData:@"google"];
			[self makeFirstResponder:layersView];			
			[[self contentView] addSubview:layersView];				
			[self getGoogle:[credentials objectAtIndex:0] password:[credentials objectAtIndex:1]];					
		}		
	}			
}

-(void) dismiss {	
	[layersView removeFromSuperview];
	[layersView.timer invalidate];
	if (layersView != nil) [layersView release];
	layersView = nil;	
	NSRect screen = [[NSScreen mainScreen] frame];	
	[username setFrame:NSMakeRect((screen.size.width/2)-140, screen.size.height/1.5+30, 0, 22)];
	[password setFrame:NSMakeRect((screen.size.width/2)-140, screen.size.height/1.5-5, 0, 22)];
	[button setFrame:NSMakeRect((screen.size.width/2)-140, screen.size.height/1.5-45, 0, 22)];
	[imageView setFrame:NSMakeRect((screen.size.width/2)+70, screen.size.height/1.5-15, 0, 0)];
	[password setStringValue:@""];	
	[username setStringValue:@""];	
	[password setHidden:YES];
	[username setHidden:YES];
	[button setHidden:YES];
	[imageView setHidden:YES];
	[keybutton setHidden:YES];	
	[self orderOut:nil];
    NSDockTile *tile = [[NSApplication sharedApplication] dockTile];
    [tile setBadgeLabel:nil];
    newCount = 0;
}


-(void)shakeWindow:(NSWindow*)w{
	
    NSRect f = [w frame];
    int c = 0; //counter variable
    int off = -8; //shake amount (offset)
    while(c<4) //shake 5 times
    {
        [w setFrame: NSMakeRect(f.origin.x + off,
                                f.origin.y,
                                f.size.width,
                                f.size.height) display: NO];
        [NSThread sleepForTimeInterval: .04]; //slight pause
        off *= -1; //back and forth
        c++; //inc counter
    }
    [w setFrame:f display: NO]; //return window to original frame
}

- (void)animateChange:(id)object newrect:(NSRect)newrect
{
    NSAnimation *theAnim;
    NSMutableDictionary *firstViewDict;
	
    {
        firstViewDict = [NSMutableDictionary dictionaryWithCapacity:3];
        [firstViewDict setObject:object forKey:NSViewAnimationTargetKey];
        [firstViewDict setObject:[NSValue valueWithRect:[object frame]] forKey:NSViewAnimationStartFrameKey];
        [firstViewDict setObject:[NSValue valueWithRect:newrect] forKey:NSViewAnimationEndFrameKey];	
    }
	
    // Create the view animation object.
    theAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:firstViewDict, nil]];
    [theAnim setDuration:0.5];
    [theAnim setAnimationCurve:NSAnimationEaseIn];
    [theAnim startAnimation];
    [theAnim release];	
}

#pragma mark tts

-(void)speakToggle
{
    if ([[NSApp currentEvent] clickCount] == 1) {
        if ([defaults boolForKey:@"speak"] == YES) {
            [defaults setObject:[NSNumber numberWithBool:NO] forKey:@"speak"];
            [speakButton setAlphaValue:0.2];        
        }else {
            [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"speak"];        
            [speakButton setAlphaValue:0.5];        
        }
        [defaults synchronize];
    }else {
        //select voice TODO
    }
}

#pragma mark keychain

-(NSArray *) validCredentials{
	NSString *keychain = @"";

	if ([action rangeOfString:@"Google"].location != NSNotFound) keychain = @"google";
	
	NSArray *cred =  [AGKeychain getCredentialsFromKeychainItem:KEYCHAIN_NAME_STRING withItemKind:keychain];
	if (cred == nil) {
		NSRect screen = [[NSScreen mainScreen] frame];		
		[username.cell setPlaceholderString:[NSString stringWithFormat:@"%@ login",keychain]];		
		[password.cell setPlaceholderString:[NSString stringWithFormat:@"%@ password",keychain]];	
		[password setHidden:NO];
		[username setHidden:NO];
		[button setHidden:NO];
		[imageView setHidden:NO];		
		[[username animator] setFrame:NSMakeRect((screen.size.width/2)-140, screen.size.height/1.5+30, 200, 22)];
		[[password animator] setFrame:NSMakeRect((screen.size.width/2)-140, screen.size.height/1.5-5, 200, 22)];
		[[button animator] setFrame:NSMakeRect((screen.size.width/2)-140, screen.size.height/1.5-45, 280, 22)];
		[[imageView animator] setFrame:NSMakeRect((screen.size.width/2)+70, screen.size.height/1.5-15, 75, 68)];		
		[self makeFirstResponder:button];
		return cred;
	}else {
		//NSLog(@"Got credentials: [%@] [%@]",[cred objectAtIndex:0],[cred objectAtIndex:1]);		
		return cred;
	}		
}	

-(void) saveCredentials{
	NSString *keychain = @"";	
	if ([action rangeOfString:@"Google"].location != NSNotFound) keychain = @"google";
	
	if ([[username stringValue] isEqualToString:@""] || [[password stringValue] isEqualToString:@""]) {
		[self shakeWindow:self];
		return;
	} 
	BOOL doesItemExisit = [AGKeychain checkForExistanceOfKeychainItem:KEYCHAIN_NAME_STRING withItemKind:keychain forUsername:[username stringValue]];							
	if (doesItemExisit) {
		BOOL result = [AGKeychain modifyKeychainItem:KEYCHAIN_NAME_STRING withItemKind:keychain forUsername:[username stringValue] withNewPassword:[password stringValue]];
		if (!result) {
			NSLog(@"Failed to modify %@ keychain",keychain);
			return;				
		}	
	} else {
		BOOL result = [AGKeychain addKeychainItem:KEYCHAIN_NAME_STRING withItemKind:keychain forUsername:[username stringValue] withPassword:[password stringValue]];
		if (!result) {
			NSLog(@"Failed to create %@ keychain",keychain);
			return;
		}	
	}
	[self dismiss];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:OBSERVER_NAME_STRING object:action userInfo:nil];	
}

-(void) clearCredentials{
	NSString *keychain = @"";	
	if ([action rangeOfString:@"Google"].location != NSNotFound) keychain = @"google";
	
	BOOL doesItemExisit = [AGKeychain checkForExistanceOfKeychainItem:KEYCHAIN_NAME_STRING withItemKind:keychain forUsername:[credentials objectAtIndex:0]];		
	if (doesItemExisit) {
		[AGKeychain deleteKeychainItem:KEYCHAIN_NAME_STRING withItemKind:keychain forUsername:[credentials objectAtIndex:0]];	
		[self saveSetting:[[[NSDictionary alloc] init] autorelease] forKey:keychain];
		[self dismiss];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:OBSERVER_NAME_STRING object:action userInfo:nil];			
	}
}

-(void)saveSetting:(id)object forKey:(NSString*)key{
	NSString *pluginName = @"FeedBoard";
	if (![[object class] isKindOfClass:[NSObject class]]) {
		NSLog(@"The value to be set for %@ is not a object",key);
		return;
	}
	NSMutableDictionary *settings = [[[defaults objectForKey:pluginName] objectForKey:@"settings"] mutableCopy];
	if (settings == nil) settings = [[NSMutableDictionary alloc] initWithCapacity:1];	
	[settings setObject:object forKey:key];
	NSMutableDictionary *dict = [[defaults objectForKey:pluginName] mutableCopy];
	if (dict == nil) dict = [[NSMutableDictionary alloc] initWithCapacity:1];	
	[dict setObject:settings forKey:@"settings"];
	
	[defaults setObject:dict forKey:pluginName];
	[defaults synchronize];
	
	[settings release];		
	[dict release];
}

#pragma mark get data

-(NSString*)getGoogleCookie:(NSString*)user password:(NSString*)pass {	
    NSString *version = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];    
	NSString *content = [NSString stringWithFormat:@"accountType=GOOGLE&Email=%@&Passwd=%@&service=reader&source=vladalexa-FeedBoard-%@", user, pass, version];
	NSURL *authUrl = [NSURL URLWithString:@"https://www.google.com/accounts/ClientLogin"];
	NSMutableURLRequest *authRequest = [NSMutableURLRequest requestWithURL:authUrl];
	[authRequest setHTTPMethod:@"POST"];
	[authRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
	[authRequest setHTTPBody:[content dataUsingEncoding:NSUTF8StringEncoding]];
    [authRequest setHTTPShouldHandleCookies:YES];
	
	if ([[NSHTTPCookieStorage sharedHTTPCookieStorage] cookieAcceptPolicy] != NSHTTPCookieAcceptPolicyAlways) {
		[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];		
		NSLog(@"Making sharedHTTPCookieStorage accept cookies");
	}		
	
	NSHTTPURLResponse *response;
	NSError *error = nil;
	[spinner startAnimation:self];			    
	NSData  *authData = [NSURLConnection sendSynchronousRequest:authRequest returningResponse:&response error:&error];
	[spinner stopAnimation:self];	
	
    if(authData == nil) {
        if (error) NSLog(@"Authentication error: %@", [error localizedDescription]);
        [self clearCredentials];        
    }else if([response statusCode] != 200) {
        NSLog(@"Authentication failed with return code %ld", [response statusCode]);
        [self clearCredentials];        
    }else{
		NSString *authResponseBody = [[[NSString alloc] initWithData:authData encoding:NSASCIIStringEncoding] autorelease];
		if ([authResponseBody rangeOfString:@"Error"].location == NSNotFound) {
			NSString *ret = @"";            
            //NSLog(@"Sucessfull auth response %@: %@",[response URL],authResponseBody);                        

            //add stuff from cookie (SSID HSID and SID make it work sometimes)
			NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[response URL]];			
			if ([cookies count] > 0) {                
				for (NSHTTPCookie *cookie in cookies){
					if ([[cookie path] isEqualToString:@"/"]) {			
						ret = [NSString stringWithFormat:@"%@ %@=%@; ",ret,[cookie name],[cookie value]];
					}
				}
			}else {
				NSLog(@"Could not find cookie in existing %@",[[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies] description]);	
			}
            
            //return
            if ([ret length] > 2) {
                //remove last "; " 
                ret = [ret substringToIndex:[ret length]-2];							
                return ret;                 
            }	                                         
		}else {
            NSLog(@"%@",authResponseBody);
		}        
    }    		
	return nil;
}

-(NSString*)getGoogleAuth:(NSString*)user password:(NSString*)pass {	
    NSString *version = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];    
	NSString *content = [NSString stringWithFormat:@"accountType=GOOGLE&Email=%@&Passwd=%@&service=reader&source=vladalexa-FeedBoard-%@", user, pass, version];
	NSURL *authUrl = [NSURL URLWithString:@"https://www.google.com/accounts/ClientLogin"];
	NSMutableURLRequest *authRequest = [NSMutableURLRequest requestWithURL:authUrl];
	[authRequest setHTTPMethod:@"POST"];
	[authRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
	[authRequest setHTTPBody:[content dataUsingEncoding:NSUTF8StringEncoding]];
    [authRequest setHTTPShouldHandleCookies:NO];	
	
	NSHTTPURLResponse *response;
	NSError *error = nil;
	[spinner startAnimation:self];			    
	NSData  *authData = [NSURLConnection sendSynchronousRequest:authRequest returningResponse:&response error:&error];
	[spinner stopAnimation:self];	
	
    if(authData == nil) {
        if (error) NSLog(@"Authentication error: %@", [error localizedDescription]);
        [self clearCredentials];        
    }else if([response statusCode] != 200) {
        NSLog(@"Authentication failed with return code %ld", [response statusCode]);
        [self clearCredentials];        
    }else{
		NSString *authResponseBody = [[[NSString alloc] initWithData:authData encoding:NSASCIIStringEncoding] autorelease];
		if ([authResponseBody rangeOfString:@"Error"].location == NSNotFound) {
            //NSLog(@"Sucessfull auth response %@: %@",[response URL],authResponseBody);             
            if ([authResponseBody rangeOfString:@"Auth"].location != NSNotFound) {
                for (NSString *auth in [authResponseBody componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]){
                    if ([auth length] > 10) {                        
                        if([auth rangeOfString:@"Auth="].location != NSNotFound) {
                            return [auth stringByReplacingOccurrencesOfString:@"Auth=" withString:@"GoogleLogin auth="];
                        }
                    }
                }
			}else {
				NSLog(@"Could not find auth in existing %@",authResponseBody);	
			}  
		}else {
            NSLog(@"%@",authResponseBody);
		}        
    }    		
	return nil;
}

-(void)getGoogle:(NSString*)user password:(NSString*)pass {	    
    [info setStringValue:@"Fetching data.."];
    [info setAlignment:NSCenterTextAlignment];            
    [info setFrame:NSMakeRect(([[NSScreen mainScreen] frame].size.width/2)-250,[[NSScreen mainScreen] frame].size.height/2,500,17)];       
	NSString *auth = [self getGoogleAuth:user password:pass];	
	if (auth != nil) {
        NSArray *header = [NSArray arrayWithObjects:@"Authorization",auth, nil];        
		NSString *url = @"http://www.google.com/reader/atom/?n=40";
		UrlConnection *conn = [[UrlConnection alloc] initWithURL:url andHeader:header delegate:self];
		conn.name = @"reader";
		[conn release];
	} else {
        [info setStringValue:@"Error authenticating"];        
		NSLog(@"Failed to get cookie");
	}
}

//TODO
-(void)getGoogleList:(NSString*)user password:(NSString*)pass {	
    [info setStringValue:@"Fetching data.."];    
    [info setAlignment:NSCenterTextAlignment];                  
    [info setFrame:NSMakeRect(([[NSScreen mainScreen] frame].size.width/2)-250,[[NSScreen mainScreen] frame].size.height/2,500,17)];     
	NSString *cookie = [self getGoogleCookie:user password:pass];	
	if (cookie != nil) {
        NSArray *header = [NSArray arrayWithObjects:@"Cookie",cookie, nil];         
		NSString *url = @"http://www.google.com/reader/api/0/unread-count?all=true&output=xml";			
		UrlConnection *conn = [[UrlConnection alloc] initWithURL:url andHeader:header delegate:self];	
		conn.name = @"list";
		[conn release];		
	} else {
        [info setStringValue:@"Error authenticating"];         
		NSLog(@"Failed to get cookie");
	}		
}


-(NSArray*)parseGoogleXml:(NSData*)xmlData{	
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:1];
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithData:xmlData options:0 error:nil];	
	if (document) {
		NSArray *xmlItems = [document nodesForXPath:@"/feed/entry" error:nil];
        if (xmlItems){
			for(NSXMLNode* item in xmlItems){	
				NSMutableDictionary *entry = [NSMutableDictionary dictionaryWithCapacity:1];	
				NSDate *date = [self dateFromZulu:[[[item nodesForXPath:@"./published" error:nil] objectAtIndex:0] stringValue]];
				[entry setObject:date forKey:@"date"];				
				[entry setObject:[[[item nodesForXPath:@"./source/title" error:nil] objectAtIndex:0] objectValue] forKey:@"name"];
				[entry setObject:@"" forKey:@"image"];					
				[entry setObject:[[[item nodesForXPath:@"./title" error:nil] objectAtIndex:0] objectValue] forKey:@"text"];	
				[entry setObject:[[[[item nodesForXPath:@"./link" error:nil] objectAtIndex:0] attributeForName:@"href"] objectValue] forKey:@"link"];	
				[entry setObject:[[[[item nodesForXPath:@"./source/link" error:nil] objectAtIndex:0] attributeForName:@"href"] objectValue] forKey:@"source"];					
				[arr addObject:entry];
			}
        }
	}else {
        [info setStringValue:@"Error fetching data"];        
		NSLog(@"Error getting google xml structure (%lu data).",[xmlData length]);       
	}	
	[document release];
	return arr;
}

-(NSArray*)getXmlData:(NSData*)xmlData type:(NSString*)type{
	if ([xmlData length] == 0) {
		NSLog(@"Got empty data");
	}
	if ([type isEqualToString:@"google"]) {
		return [self parseGoogleXml:xmlData];
	}	
	return nil;
}

- (void) connectionDidFinish:(UrlConnection *)theConnection{
	//NSLog(@"Got %@",theConnection.url);
	NSString *string = [[[NSString alloc] initWithData:theConnection.receivedData encoding:NSUTF8StringEncoding] autorelease];
	//in case of error google returns "There was an error in your request"
	if ([string rangeOfString:@"There was an error in your request"].location != NSNotFound){
        [info setStringValue:@"Error requesting data"];        
		NSLog(@"Bad google request.");		
	}else {
        NSString *keychain = @"";	
        if ([action rangeOfString:@"Google"].location != NSNotFound) keychain = @"google";		        
        NSArray *feeds = [self getXmlData:theConnection.receivedData type:keychain];        
        if ([feeds count] > 0) {
            NSMutableDictionary *plist = [[[[defaults objectForKey:@"FeedBoard"] objectForKey:@"settings"] objectForKey:keychain] mutableCopy];
            [self setDockBadge:[plist objectForKey:theConnection.name] versus:feeds];
            if (plist == nil) plist = [[NSMutableDictionary alloc] init];            
            [plist setObject:feeds forKey:theConnection.name];
            [self saveSetting:plist forKey:keychain];
            [plist release];
            [layersView readData:keychain];			            
            //show info
            NSDateFormatter *f = [[NSDateFormatter alloc] init];
            [f setDateFormat:@"HH:mm MMM dd"];
            NSString *refresh = [NSString stringWithFormat:@"Refreshed at %@",[f stringFromDate:[NSDate date]]];
            [f release];        
            [info setStringValue:refresh];           
        }
        [info setAlignment:NSRightTextAlignment];        
        NSRect screen = [[NSScreen mainScreen] frame];        
        [self animateChange:info newrect:NSMakeRect(screen.size.width-530,30,500,17)];           
	}	
}

-(NSDate*)dateFromZulu:(NSString*)str {
	if (str == nil) {
		NSLog(@"Error getting google date");
		return [NSDate date];
	}
	
	NSDateFormatter *f = [[NSDateFormatter alloc] init];
	[f setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss Z"];
	NSDate *ret = [f dateFromString:[str stringByReplacingOccurrencesOfString:@"Z" withString:@" +0000"]];
	[f release];
	
	if (ret == nil) {
		ret = [NSDate date];
		NSLog(@"Error formatting google date (%@)",str);		
	}	
	return ret;		
}

- (void)setDockBadge:(NSArray*)old versus:(NSArray*)new{
    for (id object in new) {
        if (![old containsObject:object]) newCount++;
    }

	//set dock badge
	if (newCount > 0) {
		NSDockTile *tile = [[NSApplication sharedApplication] dockTile];
		[tile setBadgeLabel:[NSString stringWithFormat:@"%i",newCount]];				
	}
}

@end
