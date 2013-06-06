//
//  AppDelegate.h
//  SinK3
//
//  Created by Andrew on 2/1/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreVideo/CoreVideo.h>


@interface AppDelegate : NSObject <NSApplicationDelegate>{
    __weak NSArrayController *_arrayController;
    __weak NSTextField *_serverIP;

    __unsafe_unretained NSTabView *_appTab;
    
}

// Methods
+ (void)perFrame;


// Auto generated getter/setters
@property (unsafe_unretained) IBOutlet NSTextField *listenIP;
@property (weak) IBOutlet NSArrayController *arrayController;
@property (assign) IBOutlet NSWindow *window;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (weak) IBOutlet NSTextFieldCell *localIP;



@property (weak) IBOutlet NSTextField *serverIP;
@property (unsafe_unretained) IBOutlet NSTabView *appTab;

@property (unsafe_unretained) IBOutlet NSPanel *fullScreenView;
@property (unsafe_unretained) IBOutlet NSPanel *fullSCreenView;
@end
