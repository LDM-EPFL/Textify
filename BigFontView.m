//
//  BigFontView.m
//  CyborgameSubtitler
//
//  Created by Andrew on 6/5/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import "BigFontView.h"


@implementation BigFontView

- (BOOL) acceptsFirstResponder{return YES;}
- (BOOL) resignFirstResponder{return YES;}
- (BOOL) becomeFirstResponder{return YES;}
- (BOOL) canBecomeKeyView{return YES;}
- (BOOL) isFlipped{return NO;}


static bool f_fullscreenMode=false;
NSWindow* fullscreenWindow;
NSPoint original_pos;
NSSize original_size;
NSMutableString *scrollString;
int scrollScalingFactor;
bool f_initialized=false;
bool f_tailing=false;
int y = 1;
NSFont  *fontToUse;
NSColor *backgroundColor;
NSColor *backgroundColor2;
NSColor *fontColor;
NSColor *fontColorShadow;
NSString* g_displayText;

///////////////////////////////////////////////////////////
// NSView
///////////////////////////////////////////////////////////
- (id)initWithFrame:(NSRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        
        //Accept Drag and Drop
        [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];

        // Displaylink
        [self setupDisplayLink];
		
		// Look for changes in view size
		// Note, -reshape will not be called automatically on size changes because NSView does not export it to override
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(reshape)
													 name:NSViewGlobalFrameDidChangeNotification
												   object:self];
    
        NSTimer* pollFile = [NSTimer scheduledTimerWithTimeInterval:(1.0) target:self selector:@selector(reloadFile) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:pollFile forMode:NSRunLoopCommonModes];
        
    }
    
    return self;
}
- (void) drawRect:(NSRect)dirtyRect{
    [self drawView];
}


///////////////////////////////////////////////////////////
// Displaylink
///////////////////////////////////////////////////////////
static bool isAnimating=false;
static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext){
    CVReturn result = [(__bridge BigFontView*)displayLinkContext getFrameForTime:outputTime];
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


///////////////////////////////////////////////////////////////////////
// Setup and Draw
///////////////////////////////////////////////////////////////////////
-(void)initializeAllTheThings{
    
    NSLog(@"Setting defaults...");
    
    
    // Try and get these from the userprefs (will fail if not initialized before)
    @try {
        [self loadColorsAndFonts];
    }@catch (NSException *exception) {
        NSLog(@"ERORR: Problem loading colors or fonts, setting factory defaults...");
        
       
        backgroundColor=[NSColor whiteColor];
        backgroundColor2=[NSColor blackColor];
        fontColor=[NSColor blackColor];
        fontColorShadow=[NSColor blackColor];


        NSData *data = [NSArchiver archivedDataWithRootObject:fontToUse];
        [[NSUserDefaults standardUserDefaults] setValue:data forKey:@"fontSelected"];
        
        data = [NSArchiver archivedDataWithRootObject:backgroundColor];
        [[NSUserDefaults standardUserDefaults] setValue:data forKey:@"colorBackground"];

        data = [NSArchiver archivedDataWithRootObject:backgroundColor2];
        [[NSUserDefaults standardUserDefaults] setValue:data forKey:@"colorBackground2"];

        data = [NSArchiver archivedDataWithRootObject:fontColor];
        [[NSUserDefaults standardUserDefaults] setValue:data forKey:@"colorFont"];

        data = [NSArchiver archivedDataWithRootObject:fontColorShadow];
        [[NSUserDefaults standardUserDefaults] setValue:data forKey:@"colorFontShadow"];

        
    }
    
    
    

}
-(void)loadColorsAndFonts{
    fontToUse=(NSFont *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"fontSelected"]];
    backgroundColor=(NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"colorBackground"]];
    backgroundColor2=(NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"colorBackground2"]];
    fontColor=(NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"colorFont"]];
    fontColorShadow=(NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"colorFontShadow"]];
    
    if (fontToUse == Nil){
        NSLog(@"ERROR: Cannot load chosen font %@...", [fontToUse fontName]);
        fontToUse=[NSFont fontWithName:@"Helvetica" size:20];
        NSData *data = [NSArchiver archivedDataWithRootObject:fontToUse];
        [[NSUserDefaults standardUserDefaults] setValue:data forKey:@"fontSelected"];
    }
    
    [fontToUse setValue:@"20" forKey:@"size"];
}

// Draw loop
NSString* lastDisplayString;
float scrollCounter=0;
bool f_polling=false;
bool f_wasFullscreen=false;
bool f_useExternalFile=false;
bool upsize=false;
-(void)drawView{
    
    // Initialize the world
    if(!f_initialized){
        NSLog(@"Initializing...");
        [self initializeAllTheThings];
        f_initialized=true;
    }
    
    
    // If we're not animating, start
    if (!isAnimating) {[self startAnimation];}
   
    
    // Load (or reload) colors and fonts
    [self loadColorsAndFonts];
    
    
    // If we transtioned from watching an external file to no
    if (f_useExternalFile && ![[NSUserDefaults standardUserDefaults] boolForKey:@"f_watchFile"]){
        f_useExternalFile=false;
        [[NSUserDefaults standardUserDefaults] setValue:g_displayText forKey:@"displayText"];
        [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"textFile"];
    }
    

    // Actually display the text
    if(f_useExternalFile){
        [self renderString:g_displayText];
    }else{
        [self renderString:[[NSUserDefaults standardUserDefaults] valueForKey:@"displayText"]];
    }
    
    
}
-(void)renderString:(NSString*)displayString{
   
    // Setup vars
    bool f_autoScale = [[NSUserDefaults standardUserDefaults] boolForKey:@"f_scaleText"];
    bool f_centerText = [[NSUserDefaults standardUserDefaults] boolForKey:@"f_centerText"];
    bool f_drawShadow = [[NSUserDefaults standardUserDefaults] boolForKey:@"f_drawShadow"];
    bool f_flipText = [[NSUserDefaults standardUserDefaults] boolForKey:@"f_flipText"];
    bool f_mirrorText = [[NSUserDefaults standardUserDefaults] boolForKey:@"f_mirrorText"];
    bool f_scrollPause = [[NSUserDefaults standardUserDefaults] boolForKey:@"f_scrollPause"];
    float gradientAngle=[[NSUserDefaults standardUserDefaults] integerForKey:@"gradientAngle"];
    float scaleBy = [[NSUserDefaults standardUserDefaults] floatForKey:@"scaleFactor"];
    float global_offsetX = [[NSUserDefaults standardUserDefaults] floatForKey:@"global_translateX"];
    float global_offsetY = [[NSUserDefaults standardUserDefaults] floatForKey:@"global_translateY"];
    float scrollSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"scrollSpeed"];
    int f_scaleTextType = [[NSUserDefaults standardUserDefaults] floatForKey:@"f_scaleTextType"];
    int f_scrollDirection = [[NSUserDefaults standardUserDefaults] floatForKey:@"f_scrollDirection"];
    
    NSRect displayRect = self.frame;
    NSAffineTransform* transformation = [NSAffineTransform transform];

    

    
    
    // Push the state onto the stack
    [NSGraphicsContext saveGraphicsState];
    
    // Not sure what this does
    [[[self window] graphicsContext] setShouldAntialias:YES];
    
    
        // Set up the display type
        NSMutableDictionary *drawStringAttributes = [[NSMutableDictionary alloc] init];
        [drawStringAttributes setObject:fontToUse forKey:NSFontAttributeName];
        [drawStringAttributes setValue:fontColor  forKey:NSForegroundColorAttributeName];
        NSSize stringSize =  [displayString sizeWithAttributes:drawStringAttributes];
    
    
        // If autoscaling, pick the scale that fills the render window
        if (f_autoScale){
            if (f_scaleTextType == 0){
                scaleBy=displayRect.size.height/stringSize.height;
            }else{
                scaleBy=displayRect.size.width/stringSize.width;
            }
        }
    
        // Center the text
        if (f_centerText){
            [transformation translateXBy:displayRect.size.width/2 yBy:displayRect.size.height/2];
            
            // Apply the scaling
            [transformation scaleXBy:scaleBy yBy:scaleBy];
            
            // Slide text over halfway
            [transformation translateXBy:-stringSize.width/2 yBy:-stringSize.height/2];
           
            
        // Not centering text
        }else{
            
            // Apply the scaling
            [transformation scaleXBy:scaleBy yBy:scaleBy];
            
            // This is a hardcoded visual correction, ideally should be line width of font
            // (good luck finding that)
            [transformation translateXBy:-1.0 yBy:-5.0];
            
        }
    
    
        // Gradient fill background
        NSGradient *backgroundGradient = [[NSGradient alloc] initWithStartingColor:backgroundColor endingColor:backgroundColor2];
        [backgroundGradient drawInRect:displayRect angle:gradientAngle];

    
        // Add dropshadow if requested
        if (f_drawShadow){
            NSShadow *stringShadow = [[NSShadow alloc] init];
            [stringShadow setShadowColor:fontColorShadow];
            NSSize shadowSize;
            shadowSize.width = 2;
            shadowSize.height = -2;
            [stringShadow setShadowOffset:shadowSize];
            [stringShadow setShadowBlurRadius:6];
            [drawStringAttributes setValue:stringShadow forKey:NSShadowAttributeName];
        }
            
    
        //Flip
        if (f_flipText){
            [transformation scaleXBy:1.0 yBy:-1.0];
            [transformation translateXBy:1.0 yBy:-stringSize.height];
        }
        
        //Mirror
        if (f_mirrorText){
            [transformation scaleXBy:-1.0 yBy:1.0];
            [transformation translateXBy:-stringSize.width yBy:1.0];
        }
    
      
        // Global offset
        [transformation translateXBy:global_offsetX
                                 yBy:global_offsetY];
    
    
        // Scroll the text
        float scaledLineWidth = stringSize.width*scaleBy;
        float scaledLineHeight = stringSize.height*scaleBy;
        float displayWidth = displayRect.size.width;
        float displayHeight = displayRect.size.height;

        // Horizontal scroll
        float rolloverAt;
        if (f_scrollDirection == 0){
            // We rollover at half the line width plus half the display width
            rolloverAt=scaledLineWidth/2 + displayWidth/2;
        
            // But scaling only changes the linewidth coordinates, so we divide to adjust
            rolloverAt=rolloverAt/scaleBy;
        
            // Vertical scroll
        }else{
            
            // We rollover at half the line width plus half the display width
            rolloverAt=scaledLineHeight/2 + displayHeight/2;
            
            // But scaling only changes the linewidth coordinates, so we divide to adjust
            rolloverAt=rolloverAt/scaleBy;
            
        }
    
        // We should scale the scrollstep as well
        float scrollUnit=scrollSpeed/scaleBy;
    
        // Scroll if not paused
        if (!f_scrollPause){
            scrollCounter=scrollCounter+scrollUnit;
           // If we are off the screen, wrap
            if (abs(scrollCounter) > rolloverAt){
                if (scrollUnit < 0){
                    scrollCounter = rolloverAt;
                }else{
                    scrollCounter = -1*rolloverAt;
                }
            }
        }
       
    
        // Apply scroll offset
        if (f_scrollDirection == 0){
            [transformation translateXBy:scrollCounter yBy:1.0];
        }else{
            [transformation translateXBy:1.0 yBy:scrollCounter];
        }
    
        // Actually apply transformation to view
        [transformation concat];
    
        // NOW draw the text into the transformed view
        [displayString drawAtPoint:NSMakePoint(0.0, 0.0) withAttributes:drawStringAttributes];
    
    // Pop the stack
    [NSGraphicsContext restoreGraphicsState];
    


}


///////////////////////////////////////////////////////////////////////
// Keyboard handling
///////////////////////////////////////////////////////////////////////

// Go fullsceen
- (void)goFullscreen{
    NSRect frame = [self.window frame];
    
    original_size = frame.size;
    original_pos = frame.origin;
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:NO],NSFullScreenModeAllScreens,
                             nil];
    
    
    [self enterFullScreenMode:[NSScreen mainScreen] withOptions:options];
    //CGDisplayHideCursor (kCGMain);
    /*
     NSRect frame = [self.window frame];
     frame.origin.x=0;
     frame.origin.y=0;
     frame.size.width *= 2;
     [self.window setContentSize:frame.size];
     */
    f_fullscreenMode=true;
}
- (void)goFullscreen2{
    
    return;
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:NO],NSFullScreenModeAllScreens,
                             nil];
    
    NSRect frame = [self.window frame];
    
    original_pos = frame.origin;
    
    NSPoint pos;
    pos.x=0;
    pos.y=0;
    [self.window setFrameOrigin:pos];
    
    [self enterFullScreenMode:[NSScreen mainScreen] withOptions:options];
    
    frame = [self.window frame];
    frame.size.width *= 2;
    [self.window setContentSize:frame.size];
    
    f_fullscreenMode=true;
}
- (void)goWindowed{
    [self exitFullScreenModeWithOptions:nil];
    [self.window makeFirstResponder:self];
    
    f_fullscreenMode=false;
}
- (void)keyDown:(NSEvent *)event {
    
    float max_scrollSpeed = 50;
    float min_scrollSpeed = -50;
    float step_scrollSpeed = 1;
    unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
    switch(key) {
            
        case 'f':case 'F':
            
            // F + CTRL
            if([event modifierFlags] & NSControlKeyMask){
                [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:@"f_flipText"] forKey:@"f_flipText"];
            
            // F
            }else{
                if (!f_fullscreenMode){
                    [self goFullscreen];
                }else{
                    [self goWindowed];
                }
            }
            break;
            
        case 'm':case 'M':
            
            // M + CTRL
            if([event modifierFlags] & NSControlKeyMask){
                [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:@"f_mirrorText"] forKey:@"f_mirrorText"];

            // M
            }else{
               
            }
            break;
            
            
            
        case 'c':case 'C':
            
            // C + CTRL
            if([event modifierFlags] & NSControlKeyMask){
                
                [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:@"f_centerText"] forKey:@"f_centerText"];
                
            // C
            }else{}
            break;
            
        case 's':case 'S':
            
            // S + CTRL
            if([event modifierFlags] & NSControlKeyMask){
                
                [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:@"f_scaleText"] forKey:@"f_scaleText"];
                
            // S
            }else{}
            break;
      
        
        case 'd':case 'D':
            if (!f_fullscreenMode){
                
                //[self enterFullScreenMode:self withOptions:nil];
                [self goFullscreen2];
            }else{
                [self goWindowed];
            }
            break;
            
        case 'r':case 'R':
            
            // CMD R
            if([event modifierFlags] & NSCommandKeyMask){

                [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"global_translateX"];
                [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"global_translateY"];
                [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"scrollSpeed"];
                [[NSUserDefaults standardUserDefaults] setFloat:1.0 forKey:@"scaleFactor"];
                scrollCounter=0;
                
            // R
            }else{}
        
        break;
            
        case 'p':case 'P': case ' ':                                                                                                                
            [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:@"f_scrollPause"] forKey:@"f_scrollPause"];
            break;
            
            
        case NSLeftArrowFunctionKey:
            // SHIFT Left Arrow
            if([event modifierFlags] & NSShiftKeyMask){
                [[NSUserDefaults standardUserDefaults] setFloat:[[NSUserDefaults standardUserDefaults] floatForKey:@"global_translateX"]-1 forKey:@"global_translateX"];
           
            // Left Arrow
            }else{
                float newScrollSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"scrollSpeed"]-step_scrollSpeed;
                if (newScrollSpeed < min_scrollSpeed){
                    newScrollSpeed=min_scrollSpeed;
                }
                [[NSUserDefaults standardUserDefaults] setFloat:newScrollSpeed forKey:@"scrollSpeed"];
            }
        break;
            
            
        case NSRightArrowFunctionKey:
            // SHIFT Right Arrow
            if([event modifierFlags] & NSShiftKeyMask){
                [[NSUserDefaults standardUserDefaults] setFloat:[[NSUserDefaults standardUserDefaults] floatForKey:@"global_translateX"]+1 forKey:@"global_translateX"];
        
            // Right Arrow
            }else{
                
                float newScrollSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"scrollSpeed"]+step_scrollSpeed;
                if (newScrollSpeed > max_scrollSpeed){
                    newScrollSpeed=max_scrollSpeed;
                }
                [[NSUserDefaults standardUserDefaults] setFloat:newScrollSpeed forKey:@"scrollSpeed"];
            }
        break;
        
            
        case NSDownArrowFunctionKey:
            // SHIFT Down Arrow
            if([event modifierFlags] & NSShiftKeyMask){
                [[NSUserDefaults standardUserDefaults] setFloat:[[NSUserDefaults standardUserDefaults] floatForKey:@"global_translateY"]-1 forKey:@"global_translateY"];
                   
            // CMD Down Arrow
            }else if([event modifierFlags] & NSCommandKeyMask){
                
                float newScaleFactor = [[NSUserDefaults standardUserDefaults] floatForKey:@"scaleFactor"]-1;
                if (newScaleFactor < 1){
                    newScaleFactor=1;
                }
                [[NSUserDefaults standardUserDefaults] setFloat:newScaleFactor forKey:@"scaleFactor"];
  
            // Down Arrow
            }else{
                float newScrollSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"scrollSpeed"]-step_scrollSpeed;
                if (newScrollSpeed < min_scrollSpeed){
                    newScrollSpeed=min_scrollSpeed;
                }
                [[NSUserDefaults standardUserDefaults] setFloat:newScrollSpeed forKey:@"scrollSpeed"];

            }
        break;
            
            
        case NSUpArrowFunctionKey:
            // SHIFT Up Arrow
            if([event modifierFlags] & NSShiftKeyMask){
                [[NSUserDefaults standardUserDefaults] setFloat:[[NSUserDefaults standardUserDefaults] floatForKey:@"global_translateY"]+1 forKey:@"global_translateY"];
                break;
            
            // CMD Up Arrow
            }else if([event modifierFlags] & NSCommandKeyMask){
                float newScaleFactor = [[NSUserDefaults standardUserDefaults] floatForKey:@"scaleFactor"]+1;
                if (newScaleFactor > 75){
                    newScaleFactor=75;
                }
                [[NSUserDefaults standardUserDefaults] setFloat:newScaleFactor forKey:@"scaleFactor"];

                
           
            // UP Arrow
            }else{
                float newScrollSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"scrollSpeed"]+step_scrollSpeed;
                if (newScrollSpeed > max_scrollSpeed){
                    newScrollSpeed=max_scrollSpeed;
                }
                [[NSUserDefaults standardUserDefaults] setFloat:newScrollSpeed forKey:@"scrollSpeed"];

            }
        break;
                        
            
            
            
            
            
    }
    
    switch([event keyCode]) {
            // ESC
        case 53:
            if (f_fullscreenMode){
                [self goWindowed];
            }
            break;
    }
    
    //[[self nextResponder] keyDown:event];
}


///////////////////////////////////////////////////////////////////////
// Drag and Drop
///////////////////////////////////////////////////////////////////////
-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {return NSDragOperationCopy;}
-(BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {return YES;}
-(BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    
    if ( [sender draggingSource] != self ) {
        droppedFileURL=[NSURL URLFromPasteboard: [sender draggingPasteboard]];
        [self loadTextFile];
        
        return true;
    }

    return false;

}


///////////////////////////////////////////////////////////////////////
// External file loading
///////////////////////////////////////////////////////////////////////
bool loadingSource=false;
bool interruptLoad=false;
NSURL* droppedFileURL;
bool loadingFile=false;
-(void)reloadFile{
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"f_watchFile"]
        && ([[droppedFileURL absoluteString] length] != 0)){
        
        if(loadingFile){NSLog(@"Busy");return;}
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            loadingFile=true;
            bool reload=[self loadTextFile];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if(reload){
                    NSLog(@"Updating...");
                }
                
                loadingFile=false;
            });
        });
        
    }else{
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"f_watchFile"];
    }
    
}
-(bool)loadTextFile{
    
    //NSLog(@"Checking...");
    NSError* error = nil;
    NSString* string = [NSString stringWithContentsOfURL:droppedFileURL encoding:NSUTF8StringEncoding error:&error];
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"f_stripLinebreaks"]){
        //NSLog(@"Stripping...");
        
        
        NSCharacterSet *charactersToRemove =
        [[ NSCharacterSet alphanumericCharacterSet ] invertedSet ];
        
        string =
        [[ string componentsSeparatedByCharactersInSet:charactersToRemove ]
         componentsJoinedByString:@" " ];
    }

    if (!f_useExternalFile || ([string length] > 0 && ![string isEqualToString:g_displayText])){
        NSArray *parts = [[droppedFileURL absoluteString] componentsSeparatedByString:@"/"];
        NSString *filename = [parts objectAtIndex:[parts count]-1];
        g_displayText=string;
        [[NSUserDefaults standardUserDefaults] setValue:filename forKey:@"textFile"];
        scrollCounter=0;
        f_useExternalFile=true;
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"f_watchFile"];
        [[NSUserDefaults standardUserDefaults] setValue:filename forKey:@"displayText"];
        return true;
       
    }
    return false;
}

@end
