//
//  main.m
//  ssccv
//
//  Created by Vlad Alexa on 4/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/CodeSigning.h>

int main (int argc, const char * argv[])
{

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    
    if (argc != 2) {
        fprintf(stderr, "usage: %s <bundle path>\n", argv[0]);
        [pool drain];        
        exit(1);
    }    
    
    NSString *path = [[NSString alloc] initWithCString:argv[1] encoding:NSUTF8StringEncoding];
    NSBundle *bundle = [NSBundle bundleWithPath:path];
    [path release];
    
    if (bundle){
        //NSLog(@"Checking: %s",argv[1]);        
    }else{
        NSLog(@"Can not check: %s",argv[1]); 
        [pool drain];        
        exit(1);        
    }
    
	int ret = -1;
    SecStaticCodeRef staticCode = NULL;
	OSStatus existence = SecStaticCodeCreateWithPath((CFURLRef)[bundle bundleURL], kSecCSDefaultFlags, &staticCode);
    OSStatus validity = -1;    
    if (existence == noErr){
        //NSLog(@"Found %@",[bundle bundlePath]);        
        validity = SecStaticCodeCheckValidity(staticCode, kSecCSCheckAllArchitectures, NULL);
        CFRelease(staticCode); //apple bug rdar:9126150, SecStaticCodeCheckValidity retains staticCode under GC and 5% of the times this will crash with (SecKeychain[512]): over-retained during finalization, refcount = 1
    }else{
        ret = 2;        
        NSLog(@"SecStaticCodeCreateWithPath failed for %@",[bundle bundlePath]);
    }
	
    if (validity == noErr){
        //NSLog(@"Validated %@",[bundle bundlePath]);
    }else{
        ret = 3;
        NSLog(@"SecStaticCodeCheckValidity failed for %@",[bundle bundlePath]);        
    }
	
    if ( existence == noErr && validity == noErr ) {
        //NSLog(@"SecStaticCodeCheckValidity success for %@",[bundle bundlePath]);         
        ret = 0;
    }      

    [pool drain];
    return ret;
}


