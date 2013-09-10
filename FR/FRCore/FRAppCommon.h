//
//  FRAppCommon.h
//  SyMix
//
//  Created by Andrew on 6/14/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//
//////////////////////////////////////////////////////////
//  Singleton used to store shared variables
//////////////////////////////////////////////////////////
#import "CWLSynthesizeSingleton.h"
#import <Cocoa/Cocoa.h>
@class StageViewController;
@class FRMIDIConfigController;
@class BigFontView;


@interface FRAppCommon : NSObject{}
CWL_DECLARE_SINGLETON_FOR_CLASS(FRAppCommon)



// These are needed for FRMIDI Support
@property FRMIDIConfigController *midiConfigController;
@property NSMutableDictionary *midiMappings;
@property NSMutableDictionary *midiMappings_byMethod;


// Custom
@property NSImage * screenShot;
@property bool isFullscreen;
@property bool externalModeAvailable;
@property bool slicerModeAvailable;
@property BigFontView *fontViewController;
@property NSWindow* mainWindow;



@end


