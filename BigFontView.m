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
- (void)undoFullscreen{
    [self exitFullScreenModeWithOptions:nil];
    [self.window makeFirstResponder:self];

    f_fullscreenMode=false;
}
- (void)keyDown:(NSEvent *)event {
    //NSLog(@"keyDown [%@]", [event characters]);
    
    unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
    switch(key) {
            
        case 'f':case 'F':
            if (!f_fullscreenMode){
                
                //[self enterFullScreenMode:self withOptions:nil];
                [self goFullscreen];
            }else{
                [self undoFullscreen];
            }
            break;
        case 'd':case 'D':
            if (!f_fullscreenMode){
                
                //[self enterFullScreenMode:self withOptions:nil];
                [self goFullscreen2];
            }else{
                [self undoFullscreen];
            }
            break;
            
        case 'r':case 'R':
            [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"global_translateX"];
            [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"global_translateY"];
            [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"scrollSpeed"];
            scrollCounter=0;
            
            
            break;

        case 'p':case 'P':
            [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:@"f_scrollPause"] forKey:@"f_scrollPause"];
           
            break;

        // Arrows
        
        case NSLeftArrowFunctionKey:
            [[NSUserDefaults standardUserDefaults] setFloat:[[NSUserDefaults standardUserDefaults] floatForKey:@"scrollSpeed"]-0.05 forKey:@"scrollSpeed"];
            break;
        case NSRightArrowFunctionKey:
            [[NSUserDefaults standardUserDefaults] setFloat:[[NSUserDefaults standardUserDefaults] floatForKey:@"scrollSpeed"]+0.05 forKey:@"scrollSpeed"];
            break;
        
        case NSDownArrowFunctionKey:  [[NSUserDefaults standardUserDefaults] setFloat:[[NSUserDefaults standardUserDefaults] floatForKey:@"global_translateY"]-1 forKey:@"global_translateY"]; break;
        case NSUpArrowFunctionKey:    [[NSUserDefaults standardUserDefaults] setFloat:[[NSUserDefaults standardUserDefaults] floatForKey:@"global_translateY"]+1 forKey:@"global_translateY"]; break;

            
            
            
        

    }
    
    switch([event keyCode]) {
            // ESC
        case 53:
            if (f_fullscreenMode){
                [self undoFullscreen];
            }
            break;
    }
    
    //[[self nextResponder] keyDown:event];
}

///////////////////////////////////////////////////////////////////////
// Setup and Draw
///////////////////////////////////////////////////////////////////////
//Setup
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

// Draw loop
NSString* lastDisplayString;
float scrollCounter=0;
bool f_polling=false;
bool f_wasFullscreen=false;
bool f_useExternalFile=false;
bool upsize=false;
- (void)drawView{
    
    
    
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
        [self renderString:[[NSUserDefaults standardUserDefaults] valueForKey:@"displayText" ]];
    }
    
  }

bool blankFrame=false;
-(void)renderString:(NSString*)displayString{
    
    NSRect displayRect = self.frame;
    NSRect screenRect  = [[NSScreen mainScreen] frame];
    
    
    // Set up the display type
	NSMutableDictionary *drawStringAttributes = [[NSMutableDictionary alloc] init];
	[drawStringAttributes setValue:fontColor
                            forKey:NSForegroundColorAttributeName];
	[drawStringAttributes setObject:fontToUse forKey:NSFontAttributeName];
	
    
    [NSGraphicsContext saveGraphicsState];
    //[[[self window] graphicsContext] setShouldAntialias:YES];
    
    // Dropshadow if requested
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"f_drawShadow"]){
        NSShadow *stringShadow = [[NSShadow alloc] init];
        [stringShadow setShadowColor:fontColorShadow];
        NSSize shadowSize;
        shadowSize.width = 2;
        shadowSize.height = -2;
        [stringShadow setShadowOffset:shadowSize];
        [stringShadow setShadowBlurRadius:6];
        [drawStringAttributes setValue:stringShadow forKey:NSShadowAttributeName];
    }
    
    // Now draw the text
	NSSize stringSize = [displayString sizeWithAttributes:drawStringAttributes];
    
    // Proportional scaling
    float scaleFactor = [[NSUserDefaults standardUserDefaults] floatForKey:@"scaleFactor"];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"f_scaleText"]){
        scaleFactor = 10 + (10* (displayRect.size.width/screenRect.size.width));
    }
    
    
    
    // Size of string
    float stringSize_width=stringSize.width*scaleFactor;
	float stringSize_height=stringSize.height*scaleFactor;
        // Begin with identity
    NSAffineTransform* transformation = [NSAffineTransform transform];
    
    //Flip
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"f_flipText"]){
        [transformation scaleXBy:1.0 yBy:-1.0];
        // To keep visible slide text up by lineheight
        [transformation translateXBy:1.0 yBy:-(stringSize.height)];
        //[transformation translateXBy:1.0 yBy:1.0];
    }
    
    //Mirror
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"f_mirrorText"]){
        [transformation scaleXBy:-1.0 yBy:1.0];
        // To keep visible slide right up by half linewidth
        [transformation translateXBy:-stringSize.width yBy:1.0];
        //[transformation translateXBy:-.09 yBy:-.9];
    }
    
    
    //Scale everything
    [transformation scaleXBy:scaleFactor yBy:scaleFactor];
    
   
    
    
   
    //Global translate
    [transformation translateXBy:[[NSUserDefaults standardUserDefaults] floatForKey:@"global_translateX"]
                             yBy:[[NSUserDefaults standardUserDefaults] floatForKey:@"global_translateY"]];
    
    // Build the gradient
  	NSGradient *backgroundGradient = [[NSGradient alloc] initWithStartingColor:backgroundColor endingColor:backgroundColor2];
	[backgroundGradient drawInRect:displayRect angle:[[NSUserDefaults standardUserDefaults] integerForKey:@"gradientAngle"]];
    
    
    // Scroll
    float rolloverAt=(stringSize_width+(displayRect.size.width/2)) - (stringSize_width/2);
    rolloverAt=rolloverAt/scaleFactor;
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"f_scrollPause"]){
        scrollCounter=scrollCounter+[[NSUserDefaults standardUserDefaults] floatForKey:@"scrollSpeed"];
        
        // If we are off the screen, wrap
        if (abs(scrollCounter) > rolloverAt){
            scrollCounter = -1*scrollCounter;
        }
    }
   
    // Apply scroll offset
    [transformation translateXBy:scrollCounter yBy:1.0];
    
    // Actually apply transformation to view
    [transformation concat];
    
    // Paint the text
    NSPoint drawPoint;
    drawPoint.x=0;
    drawPoint.y=0;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"f_centerText"]){
    
        // Half of the scaled distance to get midpoint
        drawPoint.x=(displayRect.size.width/scaleFactor)/2;
        drawPoint.y=(displayRect.size.height/scaleFactor)/2;
        
        // Now offset for line. Height derived experimentally
        drawPoint.x=drawPoint.x-stringSize.width/2;
        drawPoint.y=drawPoint.y-(stringSize.height/2)-10;
    }
    
    [displayString drawAtPoint:drawPoint withAttributes:drawStringAttributes];
    
 
    
    [NSGraphicsContext restoreGraphicsState];
    


}



///////////////////////////////////////////////////////////////////////
// Drag and Drop
///////////////////////////////////////////////////////////////////////
bool loadingSource=false;
bool interruptLoad=false;
NSURL* droppedFileURL;
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
