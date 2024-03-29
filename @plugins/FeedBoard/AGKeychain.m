//
// AGKeychain.m
// Based on code from "Core Mac OS X and Unix Programming"
// by Mark Dalrymple and Aaron Hillegass
// http://borkware.com/corebook/source-code
//
// Created by Adam Gerson on 3/6/05.
// agerson@mac.com
//


#import "AGKeychain.h"

#import <Security/Security.h>
#import <CoreFoundation/CoreFoundation.h>

@implementation AGKeychain


+ (BOOL)checkForExistanceOfKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username
{
	SecKeychainSearchRef search;
	SecKeychainItemRef item;
	SecKeychainAttributeList list;
	SecKeychainAttribute attributes[3];
    OSErr result;
    int numberOfItemsFound = 0;
	
	attributes[0].tag = kSecAccountItemAttr;
    attributes[0].data = (void *)[username UTF8String];
    attributes[0].length = [username length];
    
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[1].data = (void *)[keychainItemKind UTF8String];
    attributes[1].length = [keychainItemKind length];
	
	attributes[2].tag = kSecLabelItemAttr;
    attributes[2].data = (void *)[keychainItemName UTF8String];
    attributes[2].length = [keychainItemName length];

    list.count = 3;
    list.attr = attributes;

    result = SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &list, &search);

    if (result != noErr) {
        NSLog (@"status %d from SecKeychainSearchCreateFromAttributes\n", result);
    }
    
	while (SecKeychainSearchCopyNext (search, &item) == noErr) {
        CFRelease (item);
        numberOfItemsFound++;
    }
	
	//NSLog(@"%d items found\n", numberOfItemsFound);
    CFRelease (search);
	return numberOfItemsFound;
}

+ (BOOL)deleteKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username
{
	SecKeychainAttribute attributes[3];
    SecKeychainAttributeList list;
    SecKeychainItemRef item;
	SecKeychainSearchRef search;
    OSStatus status = 0;
	int numberOfItemsFound = 0;
	
    attributes[0].tag = kSecAccountItemAttr;
    attributes[0].data = (void *)[username UTF8String];
    attributes[0].length = [username length];
    
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[1].data = (void *)[keychainItemKind UTF8String];
    attributes[1].length = [keychainItemKind length];
	
	attributes[2].tag = kSecLabelItemAttr;
    attributes[2].data = (void *)[keychainItemName UTF8String];
    attributes[2].length = [keychainItemName length];

    list.count = 3;
    list.attr = attributes;
	
	SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &list, &search);
	while (SecKeychainSearchCopyNext (search, &item) == noErr) {
        numberOfItemsFound++;
    }
	if (numberOfItemsFound) {
		status = SecKeychainItemDelete(item);
	}
	
    if (status != 0) {
        NSLog(@"Error deleting item: %d\n", (int)status);
    }
	CFRelease (item);
	CFRelease(search);
	return !status;
}

+ (BOOL)modifyKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username withNewPassword:(NSString *)newPassword
{
	SecKeychainAttribute attributes[3];
    SecKeychainAttributeList list;
    SecKeychainItemRef item;
	SecKeychainSearchRef search;
    OSStatus status;
	
    attributes[0].tag = kSecAccountItemAttr;
    attributes[0].data = (void *)[username UTF8String];
    attributes[0].length = [username length];
    
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[1].data = (void *)[keychainItemKind UTF8String];
    attributes[1].length = [keychainItemKind length];
	
	attributes[2].tag = kSecLabelItemAttr;
    attributes[2].data = (void *)[keychainItemName UTF8String];
    attributes[2].length = [keychainItemName length];

    list.count = 3;
    list.attr = attributes;
	
	SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &list, &search);
	SecKeychainSearchCopyNext (search, &item);
    status = SecKeychainItemModifyContent(item, &list, [newPassword length], [newPassword UTF8String]);
	
    if (status != 0) {
        NSLog(@"Error modifying item: %d", (int)status);
    }
	CFRelease (item);
	CFRelease(search);
	return !status;
}

+ (BOOL)addKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username withPassword:(NSString *)password
{
	SecKeychainAttribute attributes[3];
    SecKeychainAttributeList list;
    SecKeychainItemRef item;
    OSStatus status;
	
    attributes[0].tag = kSecAccountItemAttr;
    attributes[0].data = (void *)[username UTF8String];
    attributes[0].length = [username length];
    
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[1].data = (void *)[keychainItemKind UTF8String];
    attributes[1].length = [keychainItemKind length];
	
	attributes[2].tag = kSecLabelItemAttr;
    attributes[2].data = (void *)[keychainItemName UTF8String];
    attributes[2].length = [keychainItemName length];

    list.count = 3;
    list.attr = attributes;

    status = SecKeychainItemCreateFromContent(kSecGenericPasswordItemClass, &list, [password length], [password UTF8String], NULL,NULL,&item);
    if (status != 0) {
        NSLog(@"Error creating new item: %d\n", (int)status);
    }
	return !status;
}

+ (NSString *)getPasswordFromKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username
{
    SecKeychainSearchRef search;
    SecKeychainItemRef item;
    SecKeychainAttributeList list;
    SecKeychainAttribute attributes[3];
    OSErr result;

	attributes[0].tag = kSecAccountItemAttr;
    attributes[0].data = (void *)[username UTF8String];
    attributes[0].length = [username length];
    
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[1].data = (void *)[keychainItemKind UTF8String];
    attributes[1].length = [keychainItemKind length];
	
	attributes[2].tag = kSecLabelItemAttr;
    attributes[2].data = (void *)[keychainItemName UTF8String];
    attributes[2].length = [keychainItemName length];

    list.count = 3;
    list.attr = attributes;

    result = SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &list, &search);

    if (result != noErr) {
        NSLog (@"status %d from SecKeychainSearchCreateFromAttributes\n", result);
    }
	
	NSString *password = @"";
    if (SecKeychainSearchCopyNext (search, &item) == noErr) {
		password = [self getPasswordFromSecKeychainItemRef:item];
		CFRelease(item);
		CFRelease (search);
	}
	return password;
}

+ (NSArray *)getCredentialsFromKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind 
{
	NSArray *ret = nil;		
    SecKeychainSearchRef search;
    SecKeychainItemRef item;
    SecKeychainAttributeList list;
    SecKeychainAttribute attributes[3];
    OSErr result;
	  
	attributes[0].tag = kSecLabelItemAttr;
    attributes[0].data = (void *)[keychainItemName UTF8String];
    attributes[0].length = [keychainItemName length];	
	
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[1].data = (void *)[keychainItemKind UTF8String];
    attributes[1].length = [keychainItemKind length];
	
    list.count = 2;
    list.attr = attributes;
	
    result = SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &list, &search);
	
    if (result != noErr) {
        NSLog (@"status %d from SecKeychainSearchCreateFromAttributes\n", result);
    }
	
    if (SecKeychainSearchCopyNext (search, &item) == noErr) {
		ret = [self getCredentialsFromSecKeychainItemRef:item];
		CFRelease(item);
		CFRelease (search);
	}		
	return ret;
}

+ (NSArray *)getCredentialsFromSecKeychainItemRef:(SecKeychainItemRef)item
{
	NSArray *ret = nil;
    SecKeychainAttribute attributes[8];
    SecKeychainAttributeList list;
    OSStatus didFind;
	
    attributes[0].tag = kSecAccountItemAttr;
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[2].tag = kSecLabelItemAttr;
    attributes[3].tag = kSecModDateItemAttr;
	
    list.count = 4;
    list.attr = attributes;
	
    didFind = SecKeychainItemCopyContent (item, NULL, &list, NULL, NULL);
	if (didFind == noErr) {
		
		SecKeychainAttribute		attr;
		SecKeychainAttributeList	attrList;
		UInt32						length; 
		void						*outData;
		
		// We want the account name attribute
		attr.tag = kSecAccountItemAttr;
		attr.length = 0;
		attr.data = NULL;
		
		attrList.count = 1;
		attrList.attr = &attr;
				
		if (SecKeychainItemCopyContent(item, NULL, &attrList, &length, &outData) == noErr) {
			// attr.data is the account (username) and outdata is the password
			CFStringRef username = CFStringCreateWithBytes(kCFAllocatorDefault, attr.data, attr.length, kCFStringEncodingUTF8, false);
			CFStringRef password = CFStringCreateWithBytes(kCFAllocatorDefault, outData, length, kCFStringEncodingUTF8, false);		
			ret = [NSArray arrayWithObjects:(NSString*)username,(NSString*)password,nil];			
			CFRelease(username);
			CFRelease(password);
			SecKeychainItemFreeContent (&attrList, outData);			
		}	
		SecKeychainItemFreeContent (&list, NULL);			
	}
	return ret;
}

+ (NSString *)getPasswordFromSecKeychainItemRef:(SecKeychainItemRef)item
{
	NSString *ret = @"";
    UInt32 length;
    char *password;
    SecKeychainAttribute attributes[8];
    SecKeychainAttributeList list;
	
    attributes[0].tag = kSecAccountItemAttr;
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[2].tag = kSecLabelItemAttr;
    attributes[3].tag = kSecModDateItemAttr;
 
    list.count = 4;
    list.attr = attributes;
   
    // make it clear that this is the beginning of a new keychain item
    if (SecKeychainItemCopyContent (item, NULL, &list, &length, (void **)&password) == noErr) {
        if (password != NULL) {

            // copy the password into a buffer so we can attach a
            // trailing zero byte in order to be able to print
            // it out with printf
            char passwordBuffer[1024];

            if (length > 1023) {
                length = 1023; // save room for trailing \0
            }
            strncpy (passwordBuffer, password, length);

            passwordBuffer[length] = '\0';
			//printf ("passwordBuffer = %s\n", passwordBuffer);
			ret = [NSString stringWithUTF8String:passwordBuffer];
        }
        SecKeychainItemFreeContent (&list, password);
    }
	
	return ret;
}


@end
