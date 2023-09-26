//
//  BonjourController.m
//  MagicTerminal
//
//  Created by Vlad Alexa on 3/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BonjourController.h"
#import "MagicTerminalMainCore.h"

//Service name must be 1-63 characters
#if PLUGIN //set in project's GCC_PREPROCESSOR_DEFINITIONS
    #define SERVICE_NAME	@"MagicTerminal Server[p]"
#else
    #define SERVICE_NAME	@"MagicTerminal Server[s]"
#endif

//Application protocol name must be underscore plus 1-15 characters. See <http://www.dns-sd.org/ServiceTypes.html> 
#define SERVICE_CLIENT	@"_mtermc._tcp."
#define SERVICE_SERVER	@"_mterms._tcp."

@implementation BonjourController

@synthesize servers,clients;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        
        serviceName = [[NSString alloc] initWithFormat:@"%@ %f",SERVICE_NAME,CFAbsoluteTimeGetCurrent()];       
        if ([serviceName length] > 63) {
            int diff = [serviceName length] - 63;
            NSLog(@"Service name \"%@\" %i chars too long",serviceName,diff);
            return self;
        }
                 
        if (![NSBundle loadNibNamed:@"PairScreen" owner:self]) NSLog(@"Error loading Nib");
                
        //start app server
        serviceStarted = NO;
        [self toggleBonService];         
        
        servers = [[NSMutableArray alloc] init];
        serverBrowser = [[NSNetServiceBrowser alloc] init];
        [serverBrowser setDelegate:self];
        [serverBrowser searchForServicesOfType:SERVICE_SERVER inDomain:@""];
        
        clients = [[NSMutableArray alloc] init];
        clientBrowser = [[NSNetServiceBrowser alloc] init];
        [clientBrowser setDelegate:self];
        [clientBrowser searchForServicesOfType:SERVICE_CLIENT inDomain:@""];        
        
    }
    
    return self;
}

- (void)dealloc
{
    [serviceName release];
    [servers release];
    [clients release];
    [serverBrowser release];
    [clientBrowser release];    
    [super dealloc];    
}


#pragma mark Action Handler

-(IBAction) discoverAction:(id) sender {
	[servers removeAllObjects];	
	[serverBrowser stop];
	[serverBrowser searchForServicesOfType:SERVICE_SERVER inDomain:@""];
}

-(IBAction) appdiscoverAction:(id) sender {
	[clients removeAllObjects];	
	[clientBrowser stop];
	[clientBrowser searchForServicesOfType:SERVICE_CLIENT inDomain:@""];
}


-(void) toggleBonService {
	uint16_t chosenPort = 0;
    
    if(!listeningSocket) {
        // Here, create the socket from traditional BSD socket calls, and then set up an NSFileHandle with that to listen for incoming connections.
        int fdForListening;
        struct sockaddr_in serverAddress;
        socklen_t namelen = sizeof(serverAddress);
		
        // In order to use NSFileHandle's acceptConnectionInBackgroundAndNotify method, we need to create a file descriptor that is itself a socket, bind that socket, and then set it up for listening. At this point, it's ready to be handed off to acceptConnectionInBackgroundAndNotify.
        if((fdForListening = socket(AF_INET, SOCK_STREAM, 0)) > 0) {
            memset(&serverAddress, 0, sizeof(serverAddress));
            serverAddress.sin_family = AF_INET;
            serverAddress.sin_addr.s_addr = htonl(INADDR_ANY);
            serverAddress.sin_port = 0; // allows the kernel to choose the port for us.
			
            if(bind(fdForListening, (struct sockaddr *)&serverAddress, sizeof(serverAddress)) < 0) {
                close(fdForListening);
                return;
            }
			
            // Find out what port number was chosen for us.
            if(getsockname(fdForListening, (struct sockaddr *)&serverAddress, &namelen) < 0) {
                close(fdForListening);
                return;
            }
			
            chosenPort = ntohs(serverAddress.sin_port);
            
            if(listen(fdForListening, 1) == 0) {
                listeningSocket = [[NSFileHandle alloc] initWithFileDescriptor:fdForListening closeOnDealloc:YES];
            }
        }
    }
    
    if(!netService) {
        // lazily instantiate the NSNetService object that will advertise on our behalf.
        netService = [[NSNetService alloc] initWithDomain:@"local." type:SERVICE_SERVER name:serviceName port:chosenPort];
        [netService setDelegate:self];
        NSDictionary *txtDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [MagicTerminalMainCore getMachineType],@"machine",
                                 [MagicTerminalMainCore getMachineUUID],@"uuid", 
                                 NSUserName(),@"user",                                 
                                 nil];
        [netService setTXTRecordData:[NSNetService dataFromTXTRecordDictionary:txtDict]];
    }
    
    if(netService && listeningSocket) {
        if(!serviceStarted) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionReceived:) name:NSFileHandleConnectionAcceptedNotification object:listeningSocket];
            [listeningSocket acceptConnectionInBackgroundAndNotify];
            [netService publish];
            NSLog(@"Published :%@,%@",SERVICE_SERVER,serviceName);   	
        } else {
            [netService stop];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleConnectionAcceptedNotification object:listeningSocket];
            // There is at present no way to get an NSFileHandle to -stop- listening for events, so we'll just have to tear it down and recreate it the next time we need it.
            [listeningSocket release];
            listeningSocket = nil;
			serviceStarted = NO;
            NSLog(@"Stopped :%@,%@",SERVICE_SERVER,serviceName);            
        }
    }
	
}


#pragma mark NSNetServiceBrowser delegates

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    //NSLog(@"Found service %@",aNetService.name);   
	if (aNetServiceBrowser == serverBrowser) {
        [self willChangeValueForKey:@"servers"];
		[servers addObject:aNetService];		
		if(!moreComing) [self didChangeValueForKey:@"servers"]; 
	}
	if (aNetServiceBrowser == clientBrowser) {
        [self willChangeValueForKey:@"clients"];		
		[clients addObject:aNetService];		
		if(!moreComing) [self didChangeValueForKey:@"clients"]; 
	}	
    [aNetService resolveWithTimeout:5.0];
    [aNetService setDelegate:self];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    //NSLog(@"Lost service %@",aNetService.name);     
	if (aNetServiceBrowser == serverBrowser) {
        [self willChangeValueForKey:@"servers"];        
		[servers removeObject:aNetService];
		if(!moreComing) [self didChangeValueForKey:@"servers"];	
	}
	if (aNetServiceBrowser == clientBrowser) {	
        [self willChangeValueForKey:@"clients"];        
		[clients removeObject:aNetService];
		if(!moreComing) [self didChangeValueForKey:@"clients"];	
	}	
}

#pragma mark NSNetService delegates

- (void)netServiceDidPublish:(NSNetService *)sender{
    //NSLog(@"Service published: %@",[sender name]);
    serviceStarted = YES;     
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict{
    NSString *err = @"";
    if([[errorDict objectForKey:NSNetServicesErrorCode] intValue] == NSNetServicesCollisionError) err = @"NSNetServicesCollisionError";  
    if([[errorDict objectForKey:NSNetServicesErrorCode] intValue] == NSNetServicesNotFoundError) err = @"NSNetServicesNotFoundError";   
    if([[errorDict objectForKey:NSNetServicesErrorCode] intValue] == NSNetServicesActivityInProgress) err = @"NSNetServicesActivityInProgress";
    if([[errorDict objectForKey:NSNetServicesErrorCode] intValue] == NSNetServicesBadArgumentError) err = @"NSNetServicesBadArgumentError"; 
    if([[errorDict objectForKey:NSNetServicesErrorCode] intValue] == NSNetServicesTimeoutError) err = @"NSNetServicesTimeoutError";     
    [[NSAlert alertWithMessageText:[NSString stringWithFormat:@"%@ error publishing service",err] defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:[sender name]] runModal];    
    NSLog(@"ERROR publishing service: %@ (%@)",[sender name],err);    
    [listeningSocket release];
    listeningSocket = nil;
    [netService release];
    netService = nil;     
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender{
    //NSLog(@"Service resolved: %@ to %@",[sender name],[sender hostName]);
    //fake notificatons just to trigger the refresh of whoever is monitoring
    [self willChangeValueForKey:@"servers"];
    [self willChangeValueForKey:@"clients"];     
    [self didChangeValueForKey:@"servers"]; 
    [self didChangeValueForKey:@"clients"];    
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict{
    NSLog(@"ERROR resolving service: %@",[sender name]);
    CFShow(errorDict);    
}

#pragma mark connections

// When an incoming connection is seen by the listeningSocket object, we get the NSFileHandle representing the near end of the connection.
- (void)connectionReceived:(NSNotification *)aNotification {
    NSFileHandle *otherEndSocket = [[aNotification userInfo] objectForKey:NSFileHandleNotificationFileHandleItem];
    if (listeningSocket != [aNotification object]) {
        NSLog(@"Socket Error");
        return;
    }    
    
    /*
    //read all data chunks as they come in
    NSData *inData = nil;
    NSMutableString *inString = [[[NSMutableString alloc] init] autorelease];    
    while ( (inData = [otherEndSocket availableData]) && [inData length] ) {
        NSString *str = [[NSString alloc] initWithFormat:@"%.*s", [inData length], [inData bytes]];
        [inString appendString: str];
        [str release];
    } 
    */ 
    
    //only read the last chunk of data
    NSData *inData = [otherEndSocket availableData];
    NSString *inString = [[[NSString alloc] initWithData:inData encoding:NSASCIIStringEncoding] autorelease];
    
    NSArray *pieces = [inString componentsSeparatedByString:@":"];
    if ([pieces count] < 4) {
        NSLog(@"Unhandled message %@",inString);
    }else{
        NSString *client = [pieces objectAtIndex:0];        
        NSString *type = [pieces objectAtIndex:1];         
        if ([type isEqualToString:@"MagicTerminalPairRequest"]) {  
            [pairScreen makeKeyAndOrderFront:self];                       
            NSString *output = [self generatePairCode];
            [self sendOutput:output clientID:[self getIdOfServiceNamed:client]];             
        } else if ([type isEqualToString:@"MagicTerminalExecRequest"]) { 
            [pairScreen orderOut:self];          
            NSString *path = [pieces objectAtIndex:2];            
            int index = [client length] + [type length] + [path length] + 4 - 1;
            if ([inString length] > index) {
                NSString *request = [inString substringFromIndex:index];
                //NSLog(@"Got request : %@ %@",path,request);
                NSArray *args = [NSArray arrayWithObjects:@"-c",[NSString stringWithFormat:@"''%@''",request],nil];  
                NSString *output = [self execTask:@"/bin/bash" args:args path:path];
                NSString *reply = [NSString stringWithFormat:@"%@:MagicTerminalExecReply:%@",serviceName,output];
                //NSLog(@"Replying : %@",reply);
                [self sendOutput:reply clientID:[self getIdOfServiceNamed:client]];
            }else{
                NSLog(@"Empty request : %@",inString);
            }                     
        } else {
            NSLog(@"Unknown message type %@ in %@",type,inString);
        }                 
    }      
    
    [listeningSocket acceptConnectionInBackgroundAndNotify]; //recycle the socket   	
}

-(void) sendOutput:(NSString*)string clientID:(int)clientID {
	NSNetService *service = [clients objectAtIndex:clientID];    	
	if(service) {
        NSData *appData = [string dataUsingEncoding:NSUTF8StringEncoding];        
        NSOutputStream *outStream;
        [service getInputStream:nil outputStream:&outStream];
        [outStream open];
        int bytes = [outStream write:[appData bytes] maxLength:[appData length]];
        [outStream close];	
        if (bytes != [appData length]) {
            NSLog(@"ERROR Wrote %i bytes but should have written %lu",bytes,[appData length]);     
        }else{
            //NSLog(@"Wrote %i bytes (%@)",bytes,string);             
        }
	}else{
        NSLog(@"ERROR getting client");
    }
}

-(int)getIdOfServiceNamed:(NSString*)name{
    int ret = 0;
    for (NSNetService *service in clients) {
        if ([[service name] isEqualToString:name]) return ret;
        ret++;
    }
    NSLog(@"Failed to get id for service: %@",name);
    return -1;
}

-(NSString*)execTask:(NSString*)launch args:(NSArray*)args path:(NSString*)path{   
    
    if ([[NSFileManager defaultManager] isReadableFileAtPath:path] != YES){
       NSString *msg = [NSString stringWithFormat:@"path %@ not found\n",path];
        NSLog(@"%@",msg);
        return msg;
    }       
    
    if ([[NSFileManager defaultManager] isExecutableFileAtPath:launch] != YES){
        NSString *msg = [NSString stringWithFormat:@"executable %@ not found\n",launch];
        NSLog(@"%@",msg);
        return msg;
    }      
    
	NSPipe *stdout_pipe = [[NSPipe alloc] init];
    if (stdout_pipe == nil) {
        NSLog(@"ERROR ran out of file descriptors at %@ %@",launch,[args lastObject]);
        return nil;
    }      
    
	NSTask *task = [[[NSTask alloc] init] autorelease];
	[task setLaunchPath:launch];
	[task setArguments:args];
   
    [task setCurrentDirectoryPath:path];
	
    //get the stdout
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardOutput:pipe];
    
    //get the stderr
	NSPipe *errPipe = [NSPipe pipe];    
    [task setStandardError:errPipe];
    
    //keeps your subsequent nslogs from being redirected
    [task setStandardInput:[NSPipe pipe]];    
	
	NSFileHandle *file = [pipe fileHandleForReading];
	NSFileHandle *err = [errPipe fileHandleForReading];    
    NSMutableString *output = [[[NSMutableString alloc] initWithString:@""] autorelease];        
	
    //set a timer to terminate the task if not done in a timely manner
    NSTimer *timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:task selector:@selector(terminate) userInfo:nil repeats:NO];    
	[task launch];
    
    //read all data chunks as they come in
    NSData *inData = nil;   
    while ( (inData = [file availableData]) && [inData length] ) {
        NSString *str = [[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding];
        [output appendString:str];
        [str release];      
        if ([output length] > 80000) {
            NSLog(@"Data exceeds maximum, terminating");            
            [output appendString:@"\n**Data exceeds maximum, remaining output skipped"];
            [task terminate];
            break;            
        }
    }      
    
	[task waitUntilExit];
    [timeoutTimer invalidate];	
    
	if (![task isRunning]) {	
		if ([task terminationStatus] == 0){
			//NSLog(@"Task %@ succeeded.",launch);
		}else{
			//NSLog(@"Task %@ failed.",launch);   
		}           
        //only read the last 16384 chunk of err data        
        NSData *errData = [err readDataToEndOfFile];   
        NSString *errAdd = [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding];
        [output appendString:errAdd];
        [errAdd release];                
		
        return output;
	}else {
        NSLog(@"Task %@ failed to complete.",launch);
	}
	
	return nil;		
}

-(NSString*)generatePairCode{
    NSString *string =[NSString stringWithFormat:@"%f",CFAbsoluteTimeGetCurrent()]; 
    NSString *code = @"00000";
    if ([string length] > 5){
        NSString *one = [string substringWithRange:NSMakeRange([string length]-1,1)];  
        NSString *two = [string substringWithRange:NSMakeRange([string length]-2,1)];  
        NSString *three = [string substringWithRange:NSMakeRange([string length]-3,1)];  
        NSString *four = [string substringWithRange:NSMakeRange([string length]-4,1)];  
        NSString *five = [string substringWithRange:NSMakeRange([string length]-5,1)];  
        code = [NSString stringWithFormat:@"%@%@%@%@%@",three,one,five,two,four];
        for (NSTextField *field in [[pairScreen contentView] subviews]) {
            NSString *number = [NSString stringWithFormat: @"%C",[code characterAtIndex:[field tag]]];
            [field setStringValue:number];
        }
    }else{
        NSLog(@"Error generating pair code (%lu:%@)",[string length],string);
    }
    return [NSString stringWithFormat:@"%@:MagicTerminalPairReply:%@",serviceName,code];    
}

@end
