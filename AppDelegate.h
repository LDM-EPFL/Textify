//
//  AppDelegate.h
//  SinK3
//
//  Created by Andrew on 2/1/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreVideo/CoreVideo.h>
@class FRMIDIInput;
@class FRMIDIConfigController;

@interface AppDelegate : NSObject <NSApplicationDelegate,NSTabViewDelegate>{
    __strong NSArrayController *_slicedText;
    
    // MIDI
    FRMIDIInput *midiInput;
    
     IBOutlet NSWindow *prefsWindow;
}

+(void)saveSliceFile;
+(void)loadSliceFileFromPath:(NSString*)path;
// Auto generated getter/setters
@property (strong) IBOutlet NSCollectionView *slicedTextCollection;
@property (assign) IBOutlet NSWindow *window;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property  (strong) IBOutlet NSArrayController *slicedText;

@property (weak) IBOutlet FRMIDIConfigController *midiConfigController;
@property (unsafe_unretained) IBOutlet NSProgressIndicator *progressBar;
@property (unsafe_unretained) IBOutlet NSButton *cancelLoad;
@end
