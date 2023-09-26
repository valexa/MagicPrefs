//
//  LaunchBoardMainWindow.h
//  LaunchBoard
//
//  Created by Vlad Alexa on 12/6/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CommonCrypto/CommonDigest.h>

@class LaunchWindow;

@interface LaunchBoardMainWindow : NSObject <NSAnimationDelegate,NSMetadataQueryDelegate> {

	NSUserDefaults *defaults;	
	NSButton *editButton;	
	LaunchWindow *launchWindow;
	NSView *launchView;
	NSMutableDictionary *pages;
	NSNumber *currentPage;
	NSView *pagesControl;
	BOOL isEditing;
	BOOL isChangingPage;
	BOOL cmdHeld;
	int iconsPerPage;
	int wpad;
	int hpad;	
    NSMetadataQuery *query;
    NSTextField *infoText;
    NSTimer *queryTimeout;
}

@property (assign) LaunchWindow *launchWindow;
@property(retain) NSMetadataQuery *query;
@property(retain) NSTextField *infoText;

-(void)changePage:(id)sender;
-(void)disableApps;
-(void)clearAllPages;
-(void)makePages;

-(void)saveIconMovesOnPage:(NSNumber*)num;
-(void)swapIconPagesUpdate:(int)tag direction:(NSString*)direction;
-(void)swapIcon:(int)source with:(int)target;
-(void)deleteIconPagesUpdate;
-(void)deleteIcon:(int)tag;
-(void) dismiss;
-(void) dimHalf;
-(void) dimFull;

-(NSImage*)getImageFromIcon:(NSString*)path;
-(NSAttributedString*)makeTitleString:(NSString*)string;
-(BOOL)saveSetting:(id)object forKey:(NSString*)key;
-(BOOL)isSpotlightFunctional;

-(void)swipePage:(NSView*)oldPage withPage:(NSView*)newPage;
-(void)lightCurentPageDot;
-(void)animateChange:(id)theView newrect:(NSRect)newrect;

-(void)setupQuery;
- (NSArray*)filteredQueryResults;
- (void)queryNote:(NSNotification *)note;

-(void)addAppIfNew:(NSString*)appPath;
-(void)updateApps;
-(int)maxAppsDBIndex:(NSDictionary*)db;
-(int)minAppsDBIndex:(NSDictionary*)db;
-(BOOL)isGoodIcon:(NSString*)path;
-(BOOL)appWasLaunched:(NSString*)path list:(NSArray*)list;
- (NSString*)md5ForStr:(NSString*)input;
- (NSString*)md5ForData:(NSData*)input;

@end

@interface NSString (StringAdditions)
- (NSComparisonResult)numericCompare:(NSString*)str;
@end
