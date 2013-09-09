//
//  AppDelegate.m
//  SinK3
//
//  Created by Andrew on 2/1/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import "AppDelegate.h"
#import "AppController.h"
#import "MIDIController.h"
#import "TextSlice.h"

/////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////

@implementation AppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

//////////////////////////////////////////////////////////////////////

- (IBAction)FontButton:(id)sender {
    
    NSFont *fontToUse=(NSFont *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"fontSelected"]];
    //NSFont* fontToUse=[NSFont fontWithName:@"Helvetica" size:20];
    NSFontManager * fontManager = [NSFontManager sharedFontManager];
    [fontManager setTarget:self];
    [fontManager setSelectedFont:fontToUse isMultiple:NO];
    [fontManager orderFrontFontPanel:self];

}
- (void)changeFont:(id)sender{
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    NSFont *panelFont = [fontManager convertFont:[fontManager selectedFont]];
    [panelFont setValue:@"20" forKey:@"size"];

    NSData *fontSelected = [NSArchiver archivedDataWithRootObject:panelFont];
    [[NSUserDefaults standardUserDefaults] setValue:fontSelected forKey:@"fontSelected"];
}
- (unsigned int)validModesForFontPanel:(NSFontPanel *)fontPanel{
    return NSFontPanelFaceModeMask | NSFontPanelCollectionModeMask;// | NSFontPanelSizeModeMask;
}
- (void)applicationDidFinishLaunching:(NSNotification *)notification{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *file = [[NSBundle mainBundle] pathForResource:@"default_prefs" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:file];
    [preferences registerDefaults:dict];
    
    // Replaced with Syphon
    //[[AppDistributed sharedInstance] setNamespace:@"sinlab.ch" andApplicationID:[[NSUserDefaults standardUserDefaults] valueForKey:@"publishID"]];
    
    // MIDI controller
    //midiController = [[MIDIController alloc] init];

}

- (BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:
(NSTabViewItem *)tabViewItem{
    
    int requestedIndex = (int)[tabView indexOfTabViewItem:tabViewItem];
    if (requestedIndex == 0){
        [self ensmallen];
    }else if (requestedIndex == 1){
         [self embiggen];
         int selectionIndex = (int)[[[(AppDelegate *)[[NSApplication sharedApplication] delegate] slicedTextCollection] selectionIndexes] firstIndex];        int arrayCount = (int)[[[(AppDelegate *)[[NSApplication sharedApplication] delegate] slicedText] arrangedObjects] count];
        if(selectionIndex < 0 || arrayCount < selectionIndex || arrayCount==0){
            [AppController alertUser:@"Text Slicer Mode" info:@"To activate, drag a text file onto the TextSlicer to the right."];
           
            return NO;
        }
    }else if (requestedIndex == 2){
        [self ensmallen];
        if([[[NSUserDefaults standardUserDefaults] valueForKey:@"externalFilename"] length] ==0){
            [AppController alertUser:@"External File Mode" info:@"To activate, drag a text file onto the display below."];
            return NO;
        }
    }
    
    
    return YES;
    
}

-(void)awakeFromNib{
    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"textSliceFilename"]){
        [AppDelegate loadSliceFileFromPath:[[NSUserDefaults standardUserDefaults] valueForKey:@"textSliceFilename"]];
        [self embiggen];
    }else{
        [self ensmallen];
    }

}

-(void)embiggen{
    dispatch_async(dispatch_get_main_queue(), ^{
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"f_sidebarVisible"];
    NSRect frame = [_window frame];
    frame.size = NSMakeSize(1024,789);
    [_window setFrame:frame display:YES animate:YES];
    });
}

-(void)ensmallen{
    dispatch_async(dispatch_get_main_queue(), ^{
    [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"f_sidebarVisible"];
    NSRect frame = [_window frame];
    frame.size = NSMakeSize(640,789);
    [_window setFrame:frame display:YES animate:YES];
    });
}



- (IBAction)toggleSidebar:(id)sender {
    if ([(NSButton *)sender state ] == NSOnState){
        [self embiggen];
    }else{
        [self ensmallen];
    }
}

- (IBAction)saveSliceFileButton:(id)sender {

    NSLog(@"Save slice file");
    [AppDelegate saveSliceFile];
}

// Save slices to disk
+ (void)saveSliceFile{
    
    // Mark our place
    int selectionIndex = (int)[[[(AppDelegate *)[[NSApplication sharedApplication] delegate] slicedTextCollection] selectionIndexes] firstIndex];
                          
    
    NSString *output;
    for(TextSlice* thisSlice in [[(AppDelegate *)[[NSApplication sharedApplication] delegate] slicedText] arrangedObjects]){
        
        //[output stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
        if ([thisSlice displayText]){
        output = [NSString stringWithFormat:@"%@%@\r\n\r\n",output?output:@"",[thisSlice displayText] ];
        }
    }
    [output writeToFile:[[NSUserDefaults standardUserDefaults] valueForKey:@"textSliceFilename"]  atomically:NO encoding:NSUTF8StringEncoding error:nil];
    
    // Reload
    [self loadSliceFileFromPath:[[NSUserDefaults standardUserDefaults] valueForKey:@"textSliceFilename"]];
    
    // Reset selection index
    if (selectionIndex <= [[[(AppDelegate *)[[NSApplication sharedApplication] delegate] slicedText] arrangedObjects] count]){
        [[(AppDelegate *)[[NSApplication sharedApplication] delegate] slicedTextCollection] setSelectionIndexes:[NSIndexSet indexSetWithIndex:selectionIndex]];
    }
}

+(void)loadSliceFileFromPath:(NSString*)path{
    // Clear the array
    NSRange range = NSMakeRange(0, [[[(AppDelegate *)[[NSApplication sharedApplication] delegate] slicedText] arrangedObjects] count]);
    [[(AppDelegate *)[[NSApplication sharedApplication] delegate] slicedText] removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];
    
    [[(AppDelegate *)[[NSApplication sharedApplication] delegate] slicedText] rearrangeObjects];
    
    // Split the file on newlines
    NSString *contents = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSArray *splitContents = [contents componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
    
    // Grab the blocks between newlines (we do it this way so it should work with all kinds of newlines)
    NSString *blockAggregator;
    for(NSString* textChunk in splitContents){
        
        // If we hit a blank line, save previous as a block
        if([[textChunk stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0){
            
            // Add new object
            if ([[blockAggregator stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] != 0){
                
                TextSlice *newSlice=[[TextSlice alloc] init];
                newSlice.displayText=blockAggregator;
                [[(AppDelegate *)[[NSApplication sharedApplication] delegate] slicedText] addObject:newSlice];
            }
            blockAggregator=@"";
            
            
            
        // Otherwise just aggregate
        }else{
            
            // Aggregate
            if ([[blockAggregator stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] != 0){
                blockAggregator = [NSString stringWithFormat:@"%@\n%@",blockAggregator,textChunk];
            }else{
                blockAggregator = textChunk;
            }
            
            // Edgecase... EOF with no newline after
            if([splitContents lastObject] == textChunk){
                TextSlice *newSlice=[[TextSlice alloc] init];
                newSlice.displayText=blockAggregator;
                if(newSlice.displayText){
                [[(AppDelegate *)[[NSApplication sharedApplication] delegate] slicedText] addObject:newSlice];
                }
            }
        }
    }
    [[(AppDelegate *)[[NSApplication sharedApplication] delegate] slicedTextCollection] setSelectionIndexes:[NSIndexSet indexSetWithIndex:0]];
}
- (IBAction)watchfile_clear:(id)sender {
    [self ensmallen];
    [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"displayText"];
    [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"externalFilename"];
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"inputSource"];
    NSRange range = NSMakeRange(0, [[_slicedText arrangedObjects] count]);
    [_slicedText removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];
}

-(void)applicationWillTerminate:(NSNotification *)notification{
    [AppController restoreResolution];
}

///////////////////////////////////////////////////////////////////////
// APPLICATION
///////////////////////////////////////////////////////////////////////
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application {
    return YES;
}


// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "andrewsempere.org.SinK3" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"andrewsempere.org.SinK3"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"SinK3" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"SinK3.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) 
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender{
    
    
    
    
    
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

@end
