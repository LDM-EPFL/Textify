//FIXME: Why is appcontroller a view??

//
//  AppController.m
//  CyborgameSubtitler
//
//  Created by Andrew on 7/3/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import "AppDelegate.h"
#import "AppController.h"
#import "FRAppCommon.h"
#import "BigFontView.h"
#import "SettingsFile.h"
@implementation AppController


// For resolution switch
static int fullscreen_width;
static int fullscreen_height;
static int fullscreen_rate;
static int fullscreen_depth;

static int currentScreen_width;
static int currentScreen_height;
static int currentScreen_rate;
static int currentScreen_depth;
static BOOL allowResolutionChange;

#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)
#define fequalzero(a) (fabs(a) < FLT_EPSILON)

///////////////////////////////////////////////////////////
// NSView
///////////////////////////////////////////////////////////

- (id)initWithCoder:(NSCoder *)decoder{
    if (self = [super initWithCoder:decoder])  {
        [self initCommon];
    }
    
    return (self);
}
- (id)initWithFrame:(NSRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self initCommon];
    }
    
    return self;
}
-(void) initCommon{

    // Displaylink
    [self setupDisplayLink];
    
    // Look for changes in view size
    // Note, -reshape will not be called automatically on size changes because NSView does not export it to override
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reshape)
                                                 name:NSViewGlobalFrameDidChangeNotification
                                               object:self];
}
- (void) drawRect:(NSRect)dirtyRect{[self drawView];}

- (IBAction)resetScrollSettings:(id)sender {
    [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"scrollRate"];
    [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"f_scrollPause"];

    [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"global_offsetX"];

    [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"global_offsetY"];
    [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"scrollRate"];
    [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"scrollPosition"];
    
}



///////////////////////////////////////////////////////////
// Displaylink
///////////////////////////////////////////////////////////
static bool isAnimating=false;
static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext){
    CVReturn result = [(__bridge AppController*)displayLinkContext getFrameForTime:outputTime];
    return result;
}
- (void) setupDisplayLink{
	// Create a display link capable of being used with all active displays
	CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	
	// Set the renderer output callback function
	CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, (__bridge void *)(self));
	
    
}
- (CVReturn) getFrameForTime:(const CVTimeStamp*)outputTime{
      @autoreleasepool {
        [self display];
    }return kCVReturnSuccess;
}
- (void) startAnimation{
    isAnimating=true;
	if (displayLink && !CVDisplayLinkIsRunning(displayLink))
		CVDisplayLinkStart(displayLink);
}
- (void) stopAnimation{
    isAnimating=false;
	if (displayLink && CVDisplayLinkIsRunning(displayLink))
		CVDisplayLinkStop(displayLink);
}


bool f_dockedMode=false;
-(void)drawView{
    
    return;
    // If we're not animating, start
    if (!isAnimating) {[self startAnimation];}

}

-(void)awakeFromNib{
    //Global keyboard handler
    [self globalKeyboardHandler];
    [[FRAppCommon sharedFRAppCommon] setMainWindow:controlWindow];
    
    
    // When we switch to fullscreen, change resolution to this
    allowResolutionChange=FALSE;
    fullscreen_width=640;
    fullscreen_height=480;
    fullscreen_rate=60;
    fullscreen_depth=32;
    
    // Init default restore
    /*
    CGDisplayModeRef currentMode = CGDisplayCopyDisplayMode(kCGDirectMainDisplay);
    currentScreen_width = (int)CGDisplayModeGetWidth(currentMode);
    currentScreen_height =(int)CGDisplayModeGetHeight(currentMode);
    currentScreen_rate = CGDisplayModeGetRefreshRate(currentMode);
    currentScreen_depth =32;
     */
}

-(void)resetWindows{
    // Hide the windows
    [controlWindow orderBack:self];
    [stageWindow orderBack:self];
    
    
    // Move control to center of mainscreen
    NSPoint newLocation;
    NSScreen * mainScreen = [[NSScreen screens] objectAtIndex:0];
    newLocation.y=(mainScreen.visibleFrame.size.height/2)+200;
    newLocation.x=(mainScreen.visibleFrame.size.width/2);//
    newLocation.x-=mainScreen.frame.size.width/4;
    
    
    // Move main window into position
    NSRect newFrame = controlWindow.frame;
    newFrame.origin=newLocation;
    [controlWindow setFrame:newFrame display:YES];
    
    
    // Resize and align stage to this
    //newRect.size.width=newRect.size.width*2;
    newFrame.size.height=480;
    newFrame.size.width=640;

    newFrame.origin.y-=controlWindow.frame.size.height+(newFrame.size.height/2);
    [stageWindow setFrame:newFrame display:YES];
    
    // Unhide
    [stageWindow makeKeyAndOrderFront:self];
    [controlWindow makeKeyAndOrderFront:self];
}

/*
// Edit the display name of settings
- (IBAction)SettingsNameEdit:(id)sender {
    for(SettingsFile* thisFile in [[(AppDelegate *)[[NSApplication sharedApplication] delegate]settingsFiles] arrangedObjects]){
        
        // If the name should change, write it to disk
        if(![thisFile.name isEqualToString:thisFile.originalName]){
            NSLog(@"Rename: %@ to %@",thisFile.originalName,thisFile.name);
            thisFile.originalName=thisFile.name;
        }
        
    }
}
 */

// Global keyboard handler
// Be careful with this, it is truly global (will capture even if in a textbox, for example)
-(void)globalKeyboardHandler{
    
   
    
    // Global keyboard handler.
    NSEvent * (^monitorHandler)(NSEvent *);
    
    // The event handler
    monitorHandler = ^NSEvent * (NSEvent * theEvent){
        unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
        NSUInteger flags = [[NSApp currentEvent] modifierFlags];
        
        
        // This handles only command keys
        if(!(flags & NSCommandKeyMask)){return theEvent;}
        
        // Parse...
        if((flags & NSCommandKeyMask)){
            if((flags & NSAlternateKeyMask)){
                
                // CMD + CTRL + ALT + key
                if((flags & NSControlKeyMask)){
                    //NSLog(@"Command + CTRL + Alt %i",key);
                    
                    
                // CMD + ALT + key
                }else{
                    
                }
                
            // CMD + key
            }else{
                
                switch (key){
               
                // CMD+f fullscreen
                case 'f':case'F':{
                    
                    if (![[FRAppCommon sharedFRAppCommon] isFullscreen]){
                        [[[FRAppCommon sharedFRAppCommon] fontViewController] goFullscreen];
                    }else{
                       [[[FRAppCommon sharedFRAppCommon] fontViewController] goWindowed];
                    }
                        break;

                // CMD+s Save settings
                    }case 's':case'S':{
                      
                      
                      // Default to desktop if not specified
                      NSString* path = [[NSUserDefaults standardUserDefaults] valueForKey:@"settingsDirectory"];
                      if([path length] == 0){
                          path = [NSString stringWithFormat:@"%@/Desktop",NSHomeDirectory()];
                          [[NSFileManager defaultManager ] createDirectoryAtPath:path withIntermediateDirectories: YES attributes: nil error: NULL ];
                      }
                      
                      // Default filename is timestamp
                      NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
                      NSNumber *timeStampObj = [NSNumber numberWithDouble: timeStamp];
                      NSString *fileName=[[NSString alloc] initWithFormat:@"%@/%@_SUB.settings",path,timeStampObj];
                      
                      [SettingsFile saveCurrentSettingsToPath:fileName
                                              withDisplayName:nil];
                       
                      
                        break;
                        
                      
                        
                    // Unhandled... just forward the event
                    }default:{
                        return theEvent;
                        break;
                    }
                }
            }
        }
        // We handled the event, so consume it
        return nil;
    };
    
    eventMon = [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:monitorHandler];
}
-(void)globalKeyboardHandler_OLD{
    
    NSLog(@"Global keyboard shortcuts disabled...");
    return;
    
    // Global keyboard handler.
    NSEvent * (^monitorHandler)(NSEvent *);
    
    // The event handler
    monitorHandler = ^NSEvent * (NSEvent * theEvent){
        unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
        NSUInteger flags = [[NSApp currentEvent] modifierFlags];
        
        
        // This handles only command keys
        if(!(flags & NSCommandKeyMask)){return theEvent;}
        
        // Parse...
        if((flags & NSCommandKeyMask)){
            if((flags & NSAlternateKeyMask)){
                
                // CMD + CTRL + ALT + key
                if((flags & NSControlKeyMask)){
                    //NSLog(@"Command + CTRL + Alt %i",key);
                    switch (key){
                            
                        // CMD+CTRL+ALT+0...9 Save the position settings
                        case'1':case'2':case'3':case'4':case'5':case'6':case'7':case'8':case'9':case'0':{
                            NSString* currentPosition = [NSString stringWithFormat:@"%f:%f:%f:%f:%f",
                                                         [[NSUserDefaults standardUserDefaults] floatForKey:@"positionX"],
                                                         [[NSUserDefaults standardUserDefaults] floatForKey:@"positionY"],
                                                         [[NSUserDefaults standardUserDefaults] floatForKey:@"positionZ"],
                                                         [[NSUserDefaults standardUserDefaults] floatForKey:@"position_angle"],
                                                         [[NSUserDefaults standardUserDefaults] floatForKey:@"position_tilt"]];
                            NSString* storageKey = [NSString stringWithFormat:@"globalPosition_%c",key];
                            [[NSUserDefaults standardUserDefaults] setValue:currentPosition forKey:storageKey];
                            break;
                        
                            
                    // CMD+CTRL+ALT+leftArrow Put the stageview on the display to the left/right/above/below of where it is now
                    }case NSLeftArrowFunctionKey:case NSRightArrowFunctionKey:case NSUpArrowFunctionKey:case NSDownArrowFunctionKey:{
                        [stageWindow makeKeyAndOrderFront:self];
                        //BOOL destinationFound=false;
                        for(NSScreen *foundScreen in [NSScreen screens]){
                            // Skip the screen we're on
                            
                            if   (!(fequal(foundScreen.frame.origin.x,stageWindow.screen.frame.origin.x)
                                    && fequal(foundScreen.frame.origin.y,stageWindow.screen.frame.origin.y))){
                                
                                // Locate the screen that is above/below/left/right of me
                                if(
                                   ((key == NSUpArrowFunctionKey)
                                    &&(foundScreen.frame.origin.y >= stageWindow.screen.frame.origin.y+stageWindow.frame.size.height))
                                   ||
                                   ((key == NSDownArrowFunctionKey)
                                    &&((foundScreen.frame.origin.y+foundScreen.frame.size.height) <= stageWindow.screen.frame.origin.y))
                                   ||
                                   ((key == NSRightArrowFunctionKey)
                                    &&(foundScreen.frame.origin.x >= (stageWindow.screen.frame.origin.x+stageWindow.screen.frame.size.width)))
                                   ||
                                   ((key == NSLeftArrowFunctionKey)
                                    &&((foundScreen.frame.origin.x+foundScreen.frame.size.width) <= stageWindow.screen.frame.origin.x))
                                   ){
                                    
                                    
                                    
                                    
                                    // Request fullscreen for non-control windows
                                    if (fequal(foundScreen.frame.origin.x,controlWindow.screen.frame.origin.x)
                                        && fequal(foundScreen.frame.origin.y,controlWindow.screen.frame.origin.y)){
                                        [[[FRAppCommon sharedFRAppCommon] fontViewController] goWindowed];
                                        [self resetWindows];
                                    }else{
                                        //Move the window
                                        [stageWindow orderBack:self];
                                        [stageWindow setFrameOrigin:foundScreen.frame.origin];
                                        [stageWindow center];
                                        [[[FRAppCommon sharedFRAppCommon] fontViewController] goFullscreen];
                                    }
                                    
                                    
                                    break;
                                }
                            }
                        }
                        break;
                        
                        // CMD+CTRL+ALT+R Reset display
                        }case 'R':case'r':{
                            
                            [[[FRAppCommon sharedFRAppCommon] fontViewController] goWindowed];
                            [self resetWindows];
                            
                            
                        }
                    }
                    
                // CMD + ALT + key
                }else{
                    //NSLog(@"Command + Shift %i",key);
                    switch (key){
                            
                        // F2
                        case NSF2FunctionKey:{
                            // Pin Stage Window
                            //NSLog(@"Pin stage");
                            //[AppController pinButton_action];
                            break;
                            
                        // 0...9
                        }case'1':case'2':case'3':case'4':case'5':case'6':case'7':case'8':case'9':case'0':{
                            // Load and animate to saved position
                            NSLog(@"APPCONTROLLER: ANIMATING TO position %i",key);
                            break;
                        }
                    }
                }
                
            // CMD + key
            }else{
                
                switch (key){
                    // CMD+F1 Focus on control window
                    case NSF1FunctionKey:{
                        
                        [controlWindow makeKeyAndOrderFront:self];
                        break;
                        
                    // CMD+F2 Focus Stage Window
                    }case NSF2FunctionKey:{
                        [stageWindow makeKeyAndOrderFront:self];
                        break;
                    
                    // CMD + s
                    }case 's':case'S':{
                                        
                        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"subtitler_settings_file"];
                        [[NSUserDefaults standardUserDefaults] setValue:[(NSFont *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"fontSelected"]] familyName] forKey:@"fontRequested"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        
                        
                        NSDictionary *settings=[[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
                        
                        NSString* basePath = [NSString stringWithFormat:@"%@/Desktop",NSHomeDirectory()];
                        [ [ NSFileManager defaultManager ] createDirectoryAtPath:basePath withIntermediateDirectories: YES attributes: nil error: NULL ];
                        NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
                        NSNumber *timeStampObj = [NSNumber numberWithDouble: timeStamp];
                        NSString *fileName=[[NSString alloc] initWithFormat:@"%@/%@_SUB.settings",basePath,timeStampObj];
                        //NSLog(@"Saving: %@", fileName);
                        
                        
                        NSMutableDictionary* cleanSettings=[[NSMutableDictionary alloc] init];
                        for (NSString* key in settings) {
                            if([SettingsFile allowedKey:key]){
                                [cleanSettings setObject:[settings objectForKey:key] forKey:key];
                            }
                        }
                        
                        
                        [cleanSettings writeToFile:fileName atomically:YES];

                        
                        break;
                        
                    // CMD + 0...9 Load saved position
                    }case'1':case'2':case'3':case'4':case'5':case'6':case'7':case'8':case'9':case'0':{
                        NSString* storageKey = [NSString stringWithFormat:@"globalPosition_%c",key];
                        NSString* loadPosition = [[NSUserDefaults standardUserDefaults] valueForKey:storageKey];
                        NSArray* positionSetting =[loadPosition componentsSeparatedByString:@":"];
                        [[NSUserDefaults standardUserDefaults] setFloat:[positionSetting[0] floatValue] forKey:@"positionX"];
                        [[NSUserDefaults standardUserDefaults] setFloat:[positionSetting[1] floatValue] forKey:@"positionY"];
                        [[NSUserDefaults standardUserDefaults] setFloat:[positionSetting[2] floatValue] forKey:@"positionZ"];
                        [[NSUserDefaults standardUserDefaults] setFloat:[positionSetting[3] floatValue] forKey:@"position_angle"];
                        [[NSUserDefaults standardUserDefaults] setFloat:[positionSetting[4] floatValue] forKey:@"position_tilt"];
                        break;
                        
                                            
                    // Unhandled... just forward the event
                    }default:{
                        return theEvent;
                        break;
                    }
                }
            }
        }
        // We handled the event, so consume it
        return nil;
    };
    
    eventMon = [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:monitorHandler];
}


// Pop up an alert
+(void)alertUser:(NSString*)alertTitle info:(NSString*)alertMessage{
    //NSRunAlertPanel(alertTitle, alertMessage, @"Ok",nil,nil);
    [self alertUserOnWindow:[[FRAppCommon sharedFRAppCommon] mainWindow]
                 alertTitle:alertTitle
                       info:alertMessage];
}

// Model alert on a sheet
+(void)alertUserOnWindow:(NSWindow*)displayWindow alertTitle:(NSString*)alertTitle info:(NSString*)alertMessage{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:alertTitle];
    [alert setInformativeText:alertMessage];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:displayWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
}

/*
// Create a safe temporary working location
// Thx http://www.cocoawithlove.com/2009/07/temporary-files-and-folders-in-cocoa.html
+(NSString*)createTempWorkingFolder{
    NSString *tempDirectoryTemplate =
    [NSTemporaryDirectory() stringByAppendingPathComponent:@"edu.olin.daVinci.XXXXXX"];
    const char *tempDirectoryTemplateCString =
    [tempDirectoryTemplate fileSystemRepresentation];
    char *tempDirectoryNameCString =
    (char *)malloc(strlen(tempDirectoryTemplateCString) + 1);
    strcpy(tempDirectoryNameCString, tempDirectoryTemplateCString);
    
    char *result = mkdtemp(tempDirectoryNameCString);
    // handle directory creation failure
    if (!result){
        [self alertUser:@"FATAL!" info:@"Serious error, cannot create working directory"];
    }
    
    NSString *tempDirectoryPath =
    [[NSFileManager defaultManager]
     stringWithFileSystemRepresentation:tempDirectoryNameCString
     length:strlen(result)];
    free(tempDirectoryNameCString);
    
    return [NSString stringWithFormat:@"%@/",tempDirectoryPath];
}
*/

// Accept drag and drop
+(BOOL)performDragOperation:(id<NSDraggingInfo>)sender {

    // Check extension... If this is a settings file, load the settings
    NSPasteboard* pbrd = [sender draggingPasteboard];
    NSArray *draggedFilePaths = [pbrd propertyListForType:NSFilenamesPboardType];
    NSString *path=draggedFilePaths[0];
    NSArray *parsedPath = [path componentsSeparatedByString:@"/"];
    NSArray *parsedFilename = [parsedPath[[parsedPath count]-1] componentsSeparatedByString:@"."];
    NSString* extension = parsedFilename[[parsedFilename count]-1];
    
    // Treat everything except .settings as a text file
    if (![extension isEqualToString:@"settings"]){
        [[NSUserDefaults standardUserDefaults] setValue:[[NSURL URLFromPasteboard: [sender draggingPasteboard]] absoluteString] forKey:@"externalFilename"];
        [[NSUserDefaults standardUserDefaults] setValue:[[[NSUserDefaults standardUserDefaults] valueForKey:@"externalFilename"] lastPathComponent] forKey:@"externalFilenameWithoutPath"];
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"f_watchFile"];
        [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"inputSource"];
        return true;
    }else{
        return [SettingsFile loadSettingsFromPath:path];
    }
    return NO;
}




+(void)lowerResolution{
    NSLog(@"Fullscreen at %ix%i...",fullscreen_width,fullscreen_height);
    [self changeResolutionHeight:fullscreen_height width:fullscreen_width rate:fullscreen_rate depth:fullscreen_depth];
}
+(void)restoreResolution{
    [self changeResolutionHeight:currentScreen_height width:currentScreen_width rate:currentScreen_rate depth:currentScreen_depth];
}
+(void)changeResolutionHeight:(int)height width:(int)width rate:(int)rate depth:(int)depth{
    NSLog(@"ERROR: RESOLUTION CHANGING DISABLED!"); return;
    /*
    if (!allowResolutionChange){return;}
    // Store current settings so we can switch back to them when we exit fullscreen
    CGDisplayModeRef currentMode = CGDisplayCopyDisplayMode(kCGDirectMainDisplay);
    currentScreen_width = (int)CGDisplayModeGetWidth(currentMode);
    currentScreen_height =(int)CGDisplayModeGetHeight(currentMode);
    currentScreen_rate = CGDisplayModeGetRefreshRate(currentMode);
    currentScreen_depth =32;
    
    CGDisplayCapture( kCGDirectMainDisplay );
    CFDictionaryRef    displayMode;
    displayMode = CGDisplayBestModeForParametersAndRefreshRate(
                                                               kCGDirectMainDisplay,
                                                               depth,
                                                               width,
                                                               height,
                                                               rate,
                                                               NULL
                                                               );
    CGDisplaySwitchToMode( kCGDirectMainDisplay, displayMode );
    CGDisplayRelease ( kCGDirectMainDisplay );
    */
}


@end
