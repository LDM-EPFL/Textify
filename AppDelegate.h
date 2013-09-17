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

@interface AppDelegate : NSObject <NSApplicationDelegate,NSTabViewDelegate,NSSplitViewDelegate,NSTextFieldDelegate>{
    __strong NSArrayController *_slicedText;
    FRMIDIInput *midiInput;
    IBOutlet NSWindow *prefsWindow;
}
-(void)doubleClickSettings;
- (IBAction)refreshSettingsDir:(id)sender;
- (IBAction)watchfile_clear:(id)sender;
-(void)saveSliceFile;
-(void)loadSliceFileFromPath:(NSString*)path;

@property (strong) IBOutlet NSCollectionView *slicedTextCollection;
@property (assign) IBOutlet NSWindow *window;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property  (strong) IBOutlet NSArrayController *slicedText;
@property  (strong) IBOutlet NSArrayController *settingsFiles;
@property (weak) IBOutlet FRMIDIConfigController *midiConfigController;

// Progress bar
@property float progressAmount;
@property BOOL isLoading;
@property BOOL cancelLoad;

@end
