//
//  MPCpuGraph.h
//  MPCpuGraph
//
//  Created by Vlad Alexa on 9/23/10.
//  Copyright 2010 NextDesign.
//
//	This program is free software; you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation; either version 2 of the License, or
//	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with this program; if not, write to the Free Software
//	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#import <Cocoa/Cocoa.h>

#import "MPPluginInterface.h"

#import "CPUInfo.h"

@interface MPCpuGraph : NSObject <MPPluginProtocol>{
    
	CPUInfo				*cpuInfo; 		//cpu usage data buffer
	NSImage				*displayImage;	// image to be displayed
	NSImage				*graphImage;	// image of the graph for updates
	
}

- (void)refreshGraph;
- (void)drawDelta;

@end
