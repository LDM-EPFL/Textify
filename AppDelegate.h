//
//  AppDelegate.h
//  SinK3
//
//  Created by Andrew on 2/1/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreVideo/CoreVideo.h>
@class MIDIController;

@interface AppDelegate : NSObject <NSApplicationDelegate,NSTabViewDelegate>{
    MIDIController *midiController;
    __strong NSArrayController *_slicedText;
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
@end
