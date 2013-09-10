//
//  MIDIConfigController.h
//  SyMix
//
//  Created by Andrew on 9/1/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
@class FRMIDIMapping;
@class FRMIDIInput;

@interface FRMIDIConfigController : NSView
@property BOOL settingsWindowOpen;
@property (weak) IBOutlet NSCollectionView *collectionView;
@property FRMIDIInput *midiInput;

@property (weak) IBOutlet NSArrayController *MIDIMapping_arrayController;

-(void)initializeMappings;

-(void)incomingMidiMessage:(NSString*)deviceName
                 onChannel:(NSString*)channel
               messageType:(NSString*)messageType
                  signalID:(NSString*)signalID
                     value:(NSString*)value
                     mappingExists:(BOOL)mappingExists;

@end
