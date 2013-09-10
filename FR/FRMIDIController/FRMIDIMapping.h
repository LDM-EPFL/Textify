//
//  MIDIMapping.h
//  SyMix
//
//  Created by Andrew on 9/1/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FRMIDIMapping : NSObject

@property NSString* method;
@property NSString* name;
@property NSString* type;
@property NSString* mapping;
@property NSImage* icon;
@property BOOL showWarning;
@property BOOL disableClear;
@property NSString* warningMessage;

@end
