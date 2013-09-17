//
//  AppDelegate.m
//  SinK3
//
//  Created by Andrew on 2/1/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import "AppDelegate.h"
#import "AppController.h"
#import "FRAppCommon.h"
#import "FRMIDIInput.h"
#import "TextSlice.h"
#import "SettingsFile.h"

/////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////

@implementation AppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

//////////////////////////////////////////////////////////////////////
- (IBAction)expandSidebar:(id)sender {
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"f_sidebarVisible"]){
        [self ensmallen];
    }else{
        [self embiggen];
    }
}


// SETTINGS FILES ////////////////
- (IBAction)refreshSettingsDir:(id)sender {
    
    [SettingsFile refreshSettingsSidebarWithArrayController:_settingsFiles];
    
}

-(void)saveSettings:(SettingsFile*)sf{
    [SettingsFile saveCurrentSettingsToPath:sf.path withDisplayName:sf.name];
}

-(void)deleteSettings:(SettingsFile*)sf{
    [SettingsFile deleteSettingsFile:sf.path];
}


- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
   if (proposedMinimumPosition < 85)
    {
        proposedMinimumPosition = 85;
    }
    
    return proposedMinimumPosition;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
     if (proposedMax > 700)
    {
        proposedMax = 700;
    }
    
    return proposedMax ;
}
- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview{
    return NO;
}

-(void)doubleClickSettings{

    SettingsFile* thisFile = [[(AppDelegate *)[[NSApplication sharedApplication] delegate] settingsFiles] selectedObjects][0];
    
    // This loads the cached version
    /*
    for(NSString* key in thisFile.settings){
        [[NSUserDefaults standardUserDefaults] setValue:[thisFile.settings valueForKey:key] forKey:key];
    }
     */
    
    // This loads from disk
    [SettingsFile loadSettingsFromPath:thisFile.path];
}

- (IBAction)launchPreferences:(id)sender {
    [prefsWindow makeKeyAndOrderFront:self];
    [prefsWindow center];
}

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
    
     [[NSUserDefaults standardUserDefaults] setValue:[(NSFont *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"fontSelected"]] familyName] forKey:@"fontRequested"];
   
}
- (unsigned int)validModesForFontPanel:(NSFontPanel *)fontPanel{
    return NSFontPanelFaceModeMask | NSFontPanelCollectionModeMask;// | NSFontPanelSizeModeMask;
}
- (void)applicationDidFinishLaunching:(NSNotification *)notification{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *file = [[NSBundle mainBundle] pathForResource:@"default_prefs" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:file];
    [preferences registerDefaults:dict];
    
    // MIDI controller
    [[FRAppCommon sharedFRAppCommon] setMidiConfigController:_midiConfigController];
     midiInput = [[FRMIDIInput alloc] init];
    
    
    
    if([[NSUserDefaults standardUserDefaults] valueForKey:@"f_sidebarVisible"]){
        [self embiggen];
    }else{
        [self ensmallen];
    }

    // Settings file list
    [self refreshSettingsDir:self];
}
-(void)applicationWillTerminate:(NSNotification *)notification{
    //[AppController restoreResolution];
    [self saveSliceFile];
}


- (BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:
(NSTabViewItem *)tabViewItem{
    
    int requestedIndex = (int)[tabView indexOfTabViewItem:tabViewItem];
    if (requestedIndex == 0){
    }else if (requestedIndex == 1){
         int selectionIndex = (int)[[[(AppDelegate *)[[NSApplication sharedApplication] delegate] slicedTextCollection] selectionIndexes] firstIndex];        int arrayCount = (int)[[[(AppDelegate *)[[NSApplication sharedApplication] delegate] slicedText] arrangedObjects] count];
        if(selectionIndex < 0 || arrayCount < selectionIndex || arrayCount==0){
            //[AppController alertUser:@"Not Available" info:@"To activate TextSlicer mode, expand and drag a text file onto the TextSlicer to the right."];
            //return NO;
        }
    }else if (requestedIndex == 2){        
        if([[[NSUserDefaults standardUserDefaults] valueForKey:@"externalFilename"] length] ==0){
            [AppController alertUser:@"Not Available" info:@"To activate, drag a text file onto the display window below."];
            return NO;
        }
    }
    
    
    return YES;
    
}

-(void)awakeFromNib{
    
    // Do we have a slicer to load?
    [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"isSlicerAvailable"];
    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"textSliceFilename"]){
        [(AppDelegate *)[[NSApplication sharedApplication] delegate] loadSliceFileFromPath:[[NSUserDefaults standardUserDefaults] valueForKey:@"textSliceFilename"]];
        
        [self embiggen];
    }else{
        [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"textSliceFilenameWithoutPath"];
        [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"textSliceFilename"];
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

// Button: Select a destination for logfiles
- (IBAction)selectSettingsFolder:(id)sender {
    NSOpenPanel* dlg =[NSOpenPanel openPanel];
    
    [dlg setPrompt:@"Choose"];
    [dlg setCanChooseFiles:NO];
    [dlg setCanChooseDirectories:YES];
    [dlg runModal];
    
    NSString *path = [[[dlg URLs] objectAtIndex:0] path];
    [[NSUserDefaults standardUserDefaults] setValue:path forKey:@"settingsDirectory"];
    
    [SettingsFile refreshSettingsSidebarWithArrayController:_settingsFiles];
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
    [(AppDelegate *)[[NSApplication sharedApplication] delegate] saveSliceFile];
}

// Save slices to disk
-(void)saveSliceFile{

    // For each slice
    NSString *outputFileAsString;
    for(TextSlice* thisSlice in [[(AppDelegate *)[[NSApplication sharedApplication] delegate] slicedText] arrangedObjects]){
        
        // If we have text
        if ([thisSlice displayText]){
            
            NSString* thisSliceText=[thisSlice displayText];
            
            // Aggregate lines
            outputFileAsString = [NSString stringWithFormat:@"%@%@\r\n\r\n",outputFileAsString?outputFileAsString:@"",thisSliceText];
        }
    }
    
    // Write to disk
    [outputFileAsString writeToFile:[[NSUserDefaults standardUserDefaults] valueForKey:@"textSliceFilename"]  atomically:NO encoding:NSUTF8StringEncoding error:nil];
}



// Load file
-(void)loadSliceFileFromPath:(NSString*)path{
    [self loadSliceFileFromPath:path restoringIndexTo:0];
}
-(void)loadSliceFileFromPath:(NSString*)path restoringIndexTo:(int)selectionIndex{

    // Clear the array
    NSRange range = NSMakeRange(0, [[[(AppDelegate *)[[NSApplication sharedApplication] delegate] slicedText] arrangedObjects] count]);
    [[(AppDelegate *)[[NSApplication sharedApplication] delegate] slicedText] removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];
    
    // Split the file on newlines
    NSString *contents = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSArray *splitContents = [contents componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
    
    
    // Progress bar
    [self setCancelLoad:FALSE];
    [self setProgressAmount:0.0];
    
    // Grab the blocks between newlines (we do it this way so it should work with all kinds of newlines)
    NSMutableArray* arrayOfNewSlices=[[NSMutableArray alloc] init];
    int sliceCount=(int)[splitContents count];
    //NSLog(@"Loading %i chunks...",sliceCount);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *blockAggregator;
        int chunkCount=0;
        for(NSString* textChunk in splitContents){
            
            // Cancel?
            if(_cancelLoad){break;}
            
            // If we hit a blank line, save previous as a block
            if([[textChunk stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0){
                
                // Add new object
                if ([[blockAggregator stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] != 0){
                    
                    TextSlice *newSlice=[[TextSlice alloc] init];
                    newSlice.displayText=blockAggregator;
                    [arrayOfNewSlices addObject:newSlice];
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
                    
                    //Eliminate blank lines from each slice
                    NSArray *splitContents = [blockAggregator componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
                    NSString *cleanedOutput=[[NSString alloc] init];
                    for(NSString* line in splitContents){
                        if([line length] > 0){
                            cleanedOutput=[NSString stringWithFormat:@"%@\n%@",cleanedOutput,line];
                        }
                    }
                    
                    newSlice.displayText=cleanedOutput;
                    if(newSlice.displayText){
                        [arrayOfNewSlices addObject:newSlice];
                        
                    }
                }
            }
            
            
                self.progressAmount=(double)(((double)chunkCount/(double)sliceCount)*100);
            

            chunkCount++;
        }
        
        // Callback run on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(_cancelLoad){
                [self setCancelLoad:FALSE];
                [self setIsLoading:false];
                [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"isSlicerAvailable"];
                [arrayOfNewSlices removeAllObjects];
            }else{
                [[(AppDelegate *)[[NSApplication sharedApplication] delegate] slicedText] addObjects:arrayOfNewSlices];
                [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"isSlicerAvailable"];
                [self setIsLoading:false];
                
                
                // Restore selection index
                NSArrayController* ac = [(AppDelegate *)[[NSApplication sharedApplication] delegate] slicedText];
                //NSLog(@"Attempting to restore to: %i of %li",selectionIndex,(unsigned long)[[ac arrangedObjects] count]);
                if([[ac arrangedObjects] count] >= selectionIndex){
                    [ac setSelectionIndex:selectionIndex];
                }else{
                    [ac setSelectionIndex:0];
                }
            
            }

        });
    });
}
-(IBAction)watchfile_clear:(id)sender {
    [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"displayText"];
    [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"externalFilename"];
    [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"textSliceFilenameWithoutPath"];
    [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"textSliceFilename"];
    [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"isSlicerAvailable"];
    NSRange range = NSMakeRange(0, [[_slicedText arrangedObjects] count]);
    [_slicedText removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];
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
