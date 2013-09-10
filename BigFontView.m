//
//  BigFontView.m
//  CyborgameSubtitler
//
//  Created by Andrew on 6/5/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import "BigFontView.h"
#import "MainView.h"
#import "FRAppCommon.h"
#import "NSView+snapshot.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/glu.h>
#import <Syphon/Syphon.h>
#import "AppController.h"
#import "AppDelegate.h"
#import "TextSlice.h"

@implementation BigFontView

- (BOOL) acceptsFirstResponder{return YES;}
- (BOOL) resignFirstResponder{return YES;}
- (BOOL) becomeFirstResponder{return YES;}
- (BOOL) canBecomeKeyView{return YES;}
- (BOOL) isFlipped{return NO;}


#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)
#define fequalzero(a) (fabs(a) < FLT_EPSILON)

///////////////////////////////////////////////////////////
// NSView
///////////////////////////////////////////////////////////
- (id) initWithFrame:(NSRect)frameRect{
	return [self initWithFrame:frameRect shareContext:nil];
    
}
- (id) initWithFrame:(NSRect)frameRect shareContext:(NSOpenGLContext*)context{
    if (self) {
        
        // Create a double-buffered view
        NSOpenGLPixelFormatAttribute attribs[] =
        {
            kCGLPFAAccelerated,
            kCGLPFANoRecovery,
            kCGLPFADoubleBuffer,
            kCGLPFAColorSize, 24,
            kCGLPFADepthSize, 16,
            0
        };
        pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
        if (!pixelFormat){NSLog(@"No OpenGL pixel format");}
        
        // NSOpenGLView does not handle context sharing, so we draw to a custom NSView instead
        openGLContext = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:context];
        if (self = [super initWithFrame:frameRect]) {
            [[self openGLContext] makeCurrentContext];
            
            // Synchronize buffer swaps with vertical refresh rate
            GLint swapInt = 1;
            [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
            
            [self setupDisplayLink];
            
            // Look for changes in view size
            // Note, -reshape will not be called automatically on size changes because NSView does not export it to override
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(reshape)
                                                         name:NSViewGlobalFrameDidChangeNotification
                                                       object:self];
            
            //Drag and Drop Setup
            [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
        }
        
        
        
        f_fullscreenMode=false;
        
   
        [self stopTimer];
        [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"f_typingEffect"];
        
        [[FRAppCommon sharedFRAppCommon] setFontViewController:self];
        
        
        [[self openGLContext] makeCurrentContext];
        glLoadIdentity();
        glGenTextures(1, &glTex_floor);


    }
    return self;
}


// Invert a range (used to flip slider vals)
-(float)invertValue:(float)value rangeMin:(float)rangeMin rangeMax:(float)rangeMax{
    return ((value * -1)+rangeMax) + rangeMin;
}
///////////////////////////////////////////////////////////
// Displaylink
///////////////////////////////////////////////////////////
static bool isAnimating=false;
static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [(__bridge BigFontView*)displayLinkContext setNeedsDisplay:YES];
    });
    return kCVReturnSuccess;
}
- (void) setupDisplayLink{
	// Create a display link capable of being used with all active displays
	CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	
	// Set the renderer output callback function
	CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, (__bridge void *)(self));
    
    
}

- (void) startAnimation{
    isAnimating=true;
	if (displayLink && !CVDisplayLinkIsRunning(displayLink)){
		CVDisplayLinkStart(displayLink);
    }
    

}
- (void) stopAnimation{
    isAnimating=false;
	if (displayLink && CVDisplayLinkIsRunning(displayLink))
		CVDisplayLinkStop(displayLink);
}


- (NSOpenGLContext*) openGLContext{return openGLContext;}

- (void) drawRect:(NSRect)dirtyRect{
    
    // If we're not animating, start
    if (!isAnimating) {[self startAnimation];}
   
    
   
    // Draw the view into an NSImage context (so we can set the resolution)
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"outputResolution"] == 0){
        renderDimensions = NSMakeSize(320, 240);
    }else   if ([[NSUserDefaults standardUserDefaults] integerForKey:@"outputResolution"] == 1){
        renderDimensions = NSMakeSize(640, 480);
    }else   if ([[NSUserDefaults standardUserDefaults] integerForKey:@"outputResolution"] == 2){
        renderDimensions = NSMakeSize(1024, 768);
    }else   if ([[NSUserDefaults standardUserDefaults] integerForKey:@"outputResolution"] == 3){
        CGDisplayModeRef currentMode = CGDisplayCopyDisplayMode(kCGDirectMainDisplay);
        renderDimensions = NSMakeSize((int)CGDisplayModeGetWidth(currentMode)
                                      , (int)CGDisplayModeGetHeight(currentMode));
    }
    
     NSImage *drawIntoImage = [[NSImage alloc] initWithSize:renderDimensions];
    [drawIntoImage lockFocus];
    [self drawViewOfSize:renderDimensions];
    [drawIntoImage unlockFocus];
    //[self syphonSendImage:drawIntoImage];

    // Resize to fit preview area and draw
    NSSize newSize = NSMakeSize(self.frame.size.width, self.frame.size.height);
    [drawIntoImage setSize: newSize];
    [[NSColor blackColor] set];
    
    [self lockFocus];
    [NSBezierPath fillRect:self.frame];
    [drawIntoImage drawAtPoint:NSZeroPoint fromRect:self.frame operation:NSCompositeCopy fraction:1];
    [self unlockFocus];
  
    // OUtput syphon
    [self syphonSendImage:drawIntoImage];
    
    
    /* 
     
     Experimental screen capture code
    /////
    
    CGDisplayModeRef currentMode = CGDisplayCopyDisplayMode(kCGDirectMainDisplay);
    CFArrayRef onScreenWindows = CGWindowListCreate(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
    CFArrayRef nonDesktopElements = CGWindowListCreate(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID);
    CFRange range = CFRangeMake(0, CFArrayGetCount(nonDesktopElements));
    CFMutableArrayRef desktopElements = CFArrayCreateMutableCopy(NULL, 0, onScreenWindows);
    for (int i = CFArrayGetCount(desktopElements) - 1; i >= 0; i--)
    {
        CGWindowID window = (CGWindowID)(uintptr_t)CFArrayGetValueAtIndex(desktopElements, i);
        if (CFArrayContainsValue(nonDesktopElements, range, (void*)(uintptr_t)window))
            CFArrayRemoveValueAtIndex(desktopElements, i);
    }
    
    CGImageRef cgimage = CGWindowListCreateImageFromArray(CGRectInfinite, desktopElements, kCGWindowListOptionAll);
    NSBitmapImageRep* rep = [[NSBitmapImageRep alloc] initWithCGImage:cgimage];
    NSData* data = [rep representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];
    //[data writeToFile:@"/tmp/foo.png" atomically:YES];
    [self syphonSendImage:[[NSImage alloc] initWithCGImage:cgimage size:renderDimensions]];
     */
    
}

-(void) syphonSend{
    [self syphonSendImage:[[FRAppCommon sharedFRAppCommon] screenShot]];
}
-(void) syphonSendImage:(NSImage*)Image{

    
    // Set current context
    [openGLContext makeCurrentContext];
    
    // Initialize Syphon
    if (!syphonServer){
        NSLog(@"Initializing Syphon Server...");
        syphonServer = [[SyphonServer alloc] initWithName:nil context:[openGLContext CGLContextObj] options:nil];
        if(!syphonServer){NSLog(@"Error initializing Syphon server!");}
        
    
    // Send frame
    }else{
            NSImage *screenShot = Image;
            [self loadTextureFromNSImage:screenShot];
            if(syphonServer.hasClients){[syphonServer publishFrameTexture:glTex_floor
                                                            textureTarget:GL_TEXTURE_2D
                                                              imageRegion:NSMakeRect(0,0,screenShot.size.width,screenShot.size.height)
                                                        textureDimensions:NSMakeSize(screenShot.size.width,screenShot.size.height)
                                                                  flipped:NO];}
    }

}

-(void)loadTextureFromNSImage:(NSImage*)floorTextureNSImage{
    
    
    // If we are passed an empty image, just quit
    if (floorTextureNSImage == nil){
        //NSLog(@"LOADTEXTUREFROMNSIMAGE: Error: you called me with an empty image!");
        return;
    }
    
    
    // We need to save and restore the pixel state
    [self GLpushPixelState];
    glEnable(GL_TEXTURE_2D);

    glBindTexture(GL_TEXTURE_2D, glTex_floor);
    
    
    
    //  Aquire and flip the data
    NSSize imageSize = floorTextureNSImage.size;
    if (![floorTextureNSImage isFlipped]) {
        NSImage *drawImage = [[NSImage alloc] initWithSize:imageSize];
        NSAffineTransform *transform = [NSAffineTransform transform];
        
        [drawImage lockFocus];
        
        [transform translateXBy:0 yBy:imageSize.height];
        [transform scaleXBy:1 yBy:-1];
        [transform concat];
        
        [floorTextureNSImage drawAtPoint:NSZeroPoint
                                fromRect:(NSRect){NSZeroPoint, imageSize}
                               operation:NSCompositeCopy
                                fraction:1];
        
        [drawImage unlockFocus];
        
        floorTextureNSImage = drawImage;
    }
    
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithData:[floorTextureNSImage TIFFRepresentation]];
    
    
    //  Now make a texture out of the bitmap data
    // Set proper unpacking row length for bitmap.
    glPixelStorei(GL_UNPACK_ROW_LENGTH, (GLint)[bitmap pixelsWide]);
    
    // Set byte aligned unpacking (needed for 3 byte per pixel bitmaps).
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    
    NSInteger samplesPerPixel = [bitmap samplesPerPixel];
    
    // Nonplanar, RGB 24 bit bitmap, or RGBA 32 bit bitmap.
    if(![bitmap isPlanar] && (samplesPerPixel == 3 || samplesPerPixel == 4)) {
        // Create one OpenGL texture
        glTexImage2D(GL_TEXTURE_2D, 0,
                     GL_RGBA,//samplesPerPixel == 4 ? GL_RGBA8 : GL_RGB8,
                     (GLint)[bitmap pixelsWide],
                     (GLint)[bitmap pixelsHigh],
                     0,
                     GL_RGBA,//samplesPerPixel == 4 ? GL_RGBA : GL_RGB,
                     GL_UNSIGNED_BYTE,
                     [bitmap bitmapData]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
    }else{
        [[NSException exceptionWithName:@"ImageFormat" reason:@"Unsupported image format" userInfo:nil] raise];
    }
    [self GLpopPixelState];
}

static GLint swapbytes, lsbfirst, rowlength, skiprows, skippixels, alignment;
static GLint swapbytes2, lsbfirst2, rowlength2, skiprows2, skippixels2, alignment2;
-(void)GLpushPixelState{
    glGetIntegerv(GL_UNPACK_SWAP_BYTES, &swapbytes);
    glGetIntegerv(GL_UNPACK_LSB_FIRST, &lsbfirst);
    glGetIntegerv(GL_UNPACK_ROW_LENGTH, &rowlength);
    glGetIntegerv(GL_UNPACK_SKIP_ROWS, &skiprows);
    glGetIntegerv(GL_UNPACK_SKIP_PIXELS, &skippixels);
    glGetIntegerv(GL_UNPACK_ALIGNMENT, &alignment);
    glGetIntegerv(GL_PACK_SWAP_BYTES, &swapbytes2);
    glGetIntegerv(GL_PACK_LSB_FIRST, &lsbfirst2);
    glGetIntegerv(GL_PACK_ROW_LENGTH, &rowlength2);
    glGetIntegerv(GL_PACK_SKIP_ROWS, &skiprows2);
    glGetIntegerv(GL_PACK_SKIP_PIXELS, &skippixels2);
    glGetIntegerv(GL_PACK_ALIGNMENT, &alignment2);
}
-(void)GLpopPixelState{
    // Restore current pixel store state
    glPixelStorei(GL_UNPACK_SWAP_BYTES, swapbytes);
    glPixelStorei(GL_UNPACK_LSB_FIRST, lsbfirst);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, rowlength);
    glPixelStorei(GL_UNPACK_SKIP_ROWS, skiprows);
    glPixelStorei(GL_UNPACK_SKIP_PIXELS, skippixels);
    glPixelStorei(GL_UNPACK_ALIGNMENT, alignment);
    
    glPixelStorei(GL_PACK_SWAP_BYTES, swapbytes2);
    glPixelStorei(GL_PACK_LSB_FIRST, lsbfirst2);
    glPixelStorei(GL_PACK_ROW_LENGTH, rowlength2);
    glPixelStorei(GL_PACK_SKIP_ROWS, skiprows2);
    glPixelStorei(GL_PACK_SKIP_PIXELS, skippixels2);
    glPixelStorei(GL_PACK_ALIGNMENT, alignment2);
}



///////////////////////////////////////////////////////////////////////
// Setup and Draw
///////////////////////////////////////////////////////////////////////
-(void)refreshDisplayText{
    
    
    // Input text can come from three different sources...
    
    // What input mode?
    AppDelegate* appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
    int sliceSelectionIndex = (int)[[(NSCollectionView*)[appDelegate slicedTextCollection] selectionIndexes] firstIndex];
    
    // 0=manual
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"inputSource"] == 0){
        
    // 1=textslicer
    } else if ([[NSUserDefaults standardUserDefaults] integerForKey:@"inputSource"] == 1){
            TextSlice *thisSlice = [[[appDelegate slicedText] arrangedObjects] objectAtIndex:sliceSelectionIndex];
            NSString* string = thisSlice.displayText;
            if(![previousLoadString isEqualToString:string]){
                [[NSUserDefaults standardUserDefaults] setValue:string forKey:@"displayText"];
                [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"f_typingEffectPause"];
                [self setRangeMax:0];
            }
            previousLoadString = string;
        
    // 2=watchfile
    } else if ([[NSUserDefaults standardUserDefaults] integerForKey:@"inputSource"] == 2){
            
            NSError* error = nil;
            NSURL *url = [[NSURL alloc] initWithString:[[NSUserDefaults standardUserDefaults] valueForKey:@"externalFilename"]];
            NSString* string = [NSString stringWithContentsOfURL:url  encoding:NSUTF8StringEncoding error:&error];
            
            if(![string isEqualToString:previousLoadString]){
                NSLog(@"Something changed!");
                [self stopTimer];
                if([[NSUserDefaults standardUserDefaults] boolForKey:@"f_typingEffect"]){
                    [self resetTimer];
                }
            }
            
            // Do we need to refresh displaytext?
            previousLoadString = string;
            if([[NSUserDefaults standardUserDefaults] boolForKey:@"f_stripLinebreaks"]){
                NSCharacterSet *charactersToRemove =
                [[ NSCharacterSet alphanumericCharacterSet ] invertedSet ];
                
                string =
                [[ string componentsSeparatedByCharactersInSet:charactersToRemove ]
                 componentsJoinedByString:@" " ];
            }
            
            [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"f_watchFile"];
            [[NSUserDefaults standardUserDefaults] setValue:string forKey:@"displayText"];
            
    }
    
    
}

// Draw loop
-(void)drawViewOfSize:(NSSize)renderSize{
    
    // Three possible sources for displaytext
    [self refreshDisplayText];
    NSString *displayText =[[NSUserDefaults standardUserDefaults] valueForKey:@"displayText"];
    
    // Recalculate string if typing effect on
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"f_typingEffect"]){
            NSRange range={0,_rangeMax};
        
        if(range.length > [displayText length]){
            _rangeMax=0;
        }else{
            displayText = [displayText substringWithRange:range];
        }
        
    }
    
    // At least one space
    if(!displayText){displayText=@" ";}
    
    // Are we in fullsreen mode or not?
    [[FRAppCommon sharedFRAppCommon] setIsFullscreen:f_fullscreenMode];
    
    // Check origin
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"f_correctOrigin"]){
        [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"f_centerText"];
    }
    
    //Typing timer
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"f_typingEffect"]){
        if(![typingTimer isValid]){
            [self resetTimer];
        }
    }else{
        if([typingTimer isValid]){
            [self stopTimer];
        }
    }
    
 
    
    // Push the state onto the stack
    [NSGraphicsContext saveGraphicsState];
    
    // Actually display the text
    NSAffineTransform* transformation = [NSAffineTransform transform];

    
    // The very first time this gets called all this is nil
    NSFont* fontSelected = [NSFont fontWithName:@"Helvetica" size:10];
    NSColor* fontColor = [NSColor whiteColor];
    NSColor* backgroundColor = [NSColor blackColor];
    NSColor* backgroundColor2 = [NSColor blackColor];
    @try {
        fontSelected = (NSFont *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"fontSelected"]];
        fontColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"colorFont"]];
        backgroundColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"colorBackground"]];
        backgroundColor2 = (NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"colorBackground2"]];
    }
    @catch (NSException *exception) {
        NSLog(@"Running for the first time, setting defaults..");
        [[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:fontSelected] forKey:@"fontSelected"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:fontColor] forKey:@"colorFont"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:backgroundColor] forKey:@"colorBackground"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:backgroundColor2] forKey:@"colorBackground2"];
    }
    
                                      
    
        NSMutableDictionary *drawStringAttributes = [[NSMutableDictionary alloc] init];
        [drawStringAttributes setObject:fontSelected
                                 forKey:NSFontAttributeName];
        [drawStringAttributes setValue:(NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"colorFont"]]  forKey:NSForegroundColorAttributeName];
    
      
        NSSize stringSize =  [displayText sizeWithAttributes:drawStringAttributes];

        
    
        // If autoscaling, pick the scale that fills the render window
        float scaleBy = [[NSUserDefaults standardUserDefaults] doubleForKey:@"scaleFactor"];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"f_autoScale"]){
            if ([[NSUserDefaults standardUserDefaults] integerForKey:@"scaleTextType"] == 0){
                scaleBy=renderSize.height/stringSize.height;
            }else{
                scaleBy=renderSize.width/stringSize.width;
            }
        }
    
    
        //Text alignment
        BOOL f_centerText=false;
        BOOL f_correctOrigin=false;
        if ([[NSUserDefaults standardUserDefaults] integerForKey:@"textAlignment"] == 0){
            f_centerText=true;
            f_correctOrigin=false;
        }else if ([[NSUserDefaults standardUserDefaults] integerForKey:@"textAlignment"] == 1){
            f_centerText=false;
            f_correctOrigin=false;
        }else if ([[NSUserDefaults standardUserDefaults] integerForKey:@"textAlignment"] == 2){
            f_centerText=false;
            f_correctOrigin=true;
        }
        // Center the text
        float adjustedHeight;
        if (f_centerText){
            [transformation translateXBy:renderSize.width/2 yBy:renderSize.height/2];
            
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
            
            //Calculate the offset for origin correction
            if (!fequalzero(scaleBy)){
                adjustedHeight=(renderSize.height/scaleBy)-stringSize.height;
            }else{
                adjustedHeight=(renderSize.height)-stringSize.height;
            }
        }
    
    
        // Gradient fill background
        if(![[NSUserDefaults standardUserDefaults] boolForKey:@"f_transparentBackground"]){
            
            NSColor* backgroundColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"colorBackground"]];
            NSColor* backgroundColor2 = (NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"colorBackground2"]];
        
            NSGradient *backgroundGradient = [[NSGradient alloc] initWithStartingColor:backgroundColor endingColor:backgroundColor2];
            [backgroundGradient drawInRect:NSMakeRect(0,0,renderSize.width,renderSize.height) angle:[[NSUserDefaults standardUserDefaults] floatForKey:@"gradientAngle"]];

        }
    
        // Add dropshadow if requested
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"f_drawShadow"]){
            NSShadow *stringShadow = [[NSShadow alloc] init];
            [stringShadow setShadowColor:(NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"colorFontShadow"]]];
            NSSize shadowSize;
            shadowSize.width = 2;
            shadowSize.height = -2;
            [stringShadow setShadowOffset:shadowSize];
            [stringShadow setShadowBlurRadius:6];
            [drawStringAttributes setValue:stringShadow forKey:NSShadowAttributeName];
        }
            
    
        //Flip
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"f_flipText"]){
            [transformation scaleXBy:1.0 yBy:-1.0];
            [transformation translateXBy:1.0 yBy:-stringSize.height];
        }
        
        //Mirror
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"f_mirrorText"]){
            [transformation scaleXBy:-1.0 yBy:1.0];
            [transformation translateXBy:-stringSize.width yBy:1.0];
        }
    
    
        // Correct the origin if requested
        if (f_correctOrigin){
            
            //NSLog(@"Adjusting y:%f",adjustedHeight);
            [transformation translateXBy:0.0 yBy:adjustedHeight];
            // Global offset
            [transformation translateXBy:[[NSUserDefaults standardUserDefaults] floatForKey:@"global_offsetX"] yBy:[[NSUserDefaults standardUserDefaults] floatForKey:@"global_offsetY"]];
        }else{
            // Global offset
            [transformation translateXBy:[[NSUserDefaults standardUserDefaults] floatForKey:@"global_offsetX"] yBy:[[NSUserDefaults standardUserDefaults] floatForKey:@"global_offsetY"]];
        }
    
    
    
    
        // Scroll the text
        float scaledLineWidth = stringSize.width*scaleBy;
        float scaledLineHeight = stringSize.height*scaleBy;
        float displayWidth = renderSize.width;
        float displayHeight =renderSize.height;
        float rolloverAt;
    
        // Horizontal scroll
        if ([[NSUserDefaults standardUserDefaults] integerForKey:@"scrollDirection"] == HORIZONTAL){
            // We rollover at half the line width plus half the display width
            rolloverAt=scaledLineWidth/2 + displayWidth/2;
        
            // But scaling only changes the linewidth coordinates, so we divide to adjust
            if (!fequalzero(scaleBy)){
                rolloverAt=rolloverAt/scaleBy;
            }
        // Vertical scroll
        }else if ([[NSUserDefaults standardUserDefaults] integerForKey:@"scrollDirection"] == VERTICAL){
                // We rollover at half the line width plus half the display width
                rolloverAt=scaledLineHeight/2 + displayHeight/2;
                
                // But scaling only changes the linewidth coordinates, so we divide to adjust
                if (!fequalzero(scaleBy)){
                rolloverAt=rolloverAt/scaleBy;
            }
        }
    
        // We should scale the scrollstep as well

        //float scrollUnit=1;
    
        // Make a unit that is 1 character
        float scrollUnit=1;
        if(stringSize.width){
            scrollUnit = stringSize.width/displayText.length;
        }
        if (!fequalzero(scaleBy)){
            scrollUnit=scrollUnit/scaleBy;
        }
        // Adjust for width of window
        scrollUnit = scrollUnit * (renderSize.width/858.0);

        
    
        // Multiply it by the rate
        scrollUnit = scrollUnit*[[NSUserDefaults standardUserDefaults] floatForKey:@"scrollRate"];
    
    
        // Scroll if not paused
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"f_scrollPause"]){
             
             [[NSUserDefaults standardUserDefaults] setFloat:[[NSUserDefaults standardUserDefaults] floatForKey:@"scrollPosition"]+scrollUnit forKey:@"scrollPosition"];
            
           // If we are off the screen, wrap
            if (abs([[NSUserDefaults standardUserDefaults] floatForKey:@"scrollPosition"]) > rolloverAt){
                if (scrollUnit < 0){
                    [[NSUserDefaults standardUserDefaults] setFloat:rolloverAt forKey:@"scrollPosition"];
                }else{
                    [[NSUserDefaults standardUserDefaults] setFloat:-1*rolloverAt forKey:@"scrollPosition"];                    
                }
            }
        }
    
        
        // Apply scroll offset
        if ([[NSUserDefaults standardUserDefaults] integerForKey:@"scrollDirection"] == HORIZONTAL){
            [transformation translateXBy:[[NSUserDefaults standardUserDefaults] floatForKey:@"scrollPosition"] yBy:1.0];
        }else if ([[NSUserDefaults standardUserDefaults] integerForKey:@"scrollDirection"] == VERTICAL){
            [transformation translateXBy:1.0 yBy:[[NSUserDefaults standardUserDefaults] floatForKey:@"scrollPosition"]];
        }
    

        // Actually apply transformation to view
        [transformation concat];
    
        // NOW draw the text into the transformed view
        [displayText drawAtPoint:NSMakePoint(0.0, 0.0) withAttributes:drawStringAttributes];
        
    // Pop the stack
    [NSGraphicsContext restoreGraphicsState];
    
}


// Typing timer
-(void)incrementRange{
    
    
    // Exit if paused
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"f_typingEffectPause"]){return;}
    
    
    // Stop timer if we are out of range
    if(_rangeMax >= [(NSString*)[[NSUserDefaults standardUserDefaults] valueForKey:@"displayText"] length]){
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"f_typingEffectLoop"]){
            _rangeMax=0;
        }else{
            //[[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"f_typingEffect"];
        }
        return;
    }
    
    
    
    // Add some "humanity" to the typing (microdelay)
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"f_typingEffectHumanize"]){
        
        // If we're out of range
        if(_rangeMax+1 >= [(NSString*)[[NSUserDefaults standardUserDefaults] valueForKey:@"displayText"] length]){
            _rangeMax++;
            return;
        }else{
            
            // What char are we going to type next?
            NSString* nextChar=@"x";
            NSRange range={_rangeMax+1,1};
            nextChar=[[[NSUserDefaults standardUserDefaults] valueForKey:@"displayText"] substringWithRange:range];

                      
           // If it's uppercase or punctuation, introduce a delay
            if([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:nextChar] ||
               [[NSCharacterSet punctuationCharacterSet] characterIsMember:nextChar]){
                
                if(arc4random() % 2 == 1){_rangeMax++;}
                
            // If it's whitespace, introduce a slightly longer delay
            }else if([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:nextChar]){
        
                if(arc4random() % 5 == 1){_rangeMax++;}
            
            // No delay
            }else{ _rangeMax++;}
        }
        
    // No microdelay
    }else{
        _rangeMax++;
    }
    
    // Pause if EOL and requested
    if (_rangeMax > 0 && [[NSUserDefaults standardUserDefaults] boolForKey:@"f_typingEffectAutoPause"]){
        
        if(_rangeMax+1 >= [(NSString*)[[NSUserDefaults standardUserDefaults] valueForKey:@"displayText"] length]){
             _rangeMax++;
            return;
        }

        // What char are we going to type next?
        NSRange range={_rangeMax,1};
        NSString* thisChar=[[[NSUserDefaults standardUserDefaults] valueForKey:@"displayText"] substringWithRange:range];

        if ([thisChar isEqualToString:@"\n"]){            
            [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"f_typingEffectPause"];
        }
    }
    
    // Reset timer rate if requested
    [self adjustTimerToRate:[[NSUserDefaults standardUserDefaults] doubleForKey:@"typingRate"]];
}

// Key handler
- (void)keyDown:(NSEvent *)event {
    
    NSLog(@"Keyboard shortcuts disabled...");
    return;
    
        unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
        switch(key) {
                
            case 'f':case 'F':
                
                if([[NSUserDefaults standardUserDefaults] boolForKey:@"f_pinDisplay"]){
                    NSBeep();
                     break;
                }
                
                if([event modifierFlags] & NSControlKeyMask){
                }else{
                    if (!f_fullscreenMode){
                        [self goFullscreen];
                    }else{
                        [self goWindowed];
                    }
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
        
    // Call controller
    [[[MainView alloc] init] keyDown:event];

}

- (void) stopTimer{
    [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"f_typingEffectPause"];
    _rangeMax=0;
    [typingTimer invalidate];
}

- (void) resetTimer{
    NSLog(@"reset");
    _rangeMax=0;
    [self adjustTimerToRate:[[NSUserDefaults standardUserDefaults] doubleForKey:@"typingRate"]];
}

-(void) adjustTimerToRate:(float)newTimerRate{
    

    if (![typingTimer isValid] || !fequal(currentTimerRate, [[NSUserDefaults standardUserDefaults] doubleForKey:@"typingRate"])){
        //NSLog(@"START Timer: %f",newTimerRate);
        currentTimerRate=newTimerRate;
         newTimerRate = (double)([self invertValue:newTimerRate rangeMin:0.00001 rangeMax:.5]);
        
        
        [typingTimer invalidate];
        typingTimer = [NSTimer scheduledTimerWithTimeInterval:newTimerRate
                                                       target:self
                                                     selector:@selector(incrementRange)
                                                     userInfo:nil
                                                      repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:typingTimer forMode:NSEventTrackingRunLoopMode];

    }
}

// Screencap code based on 002.vade.info
-(GLuint) createWindowTexture:(CGLContextObj) internalContext
           mainDrawingContext:(CGLContextObj) mainDrawingContext
                        width:(NSInteger) width
                       height:(NSInteger) height
                      originX:(NSInteger) originX
                      originY:(NSInteger) originY{
    
    CGLContextObj cgl_ctx = internalContext;
    
    
    if (CGLSetCurrentContext(cgl_ctx) != kCGLNoError){
        NSLog(@"CANNOT MAKE CURRENT CONTEXT");
        return nil;
    };
    
    // Make sure our context is valid
    if(!cgl_ctx){
        NSLog(@"INVALID CONTEXT");
        return nil;
    }
    
    
    // Thread lock OpenGL Context
    CGLLockContext(cgl_ctx);
    
    GLuint mTextureName;
    GLenum theError = GL_NO_ERROR;
    
    // set up our texture storage for copying
    glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
    glPixelStorei(GL_PACK_ROW_LENGTH, 0);
    glPixelStorei(GL_PACK_SKIP_ROWS, 0);
    glPixelStorei(GL_PACK_SKIP_PIXELS, 0);
    
    // Create and configure the texture - rectangluar coords
    glGenTextures(1, &mTextureName);
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, mTextureName);
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    // define our texture - we're allowd to supply a null pointer since we are letting the GPU handle texture storage.
    glTexImage2D(GL_TEXTURE_RECTANGLE_ARB,0,GL_RGBA, (int)width,(int)height,0,GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, NULL);
    
    // read from the front buffer
    glReadBuffer(GL_FRONT);
    //	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, mTextureName);
    
    // copy contents of a portion of the buffer to our texture
    glCopyTexSubImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, 0, 0, (int)originX, (int)originY, (int)width, (int)height);
    
    // fin
    glFlush();
    
    // Thread unlock
    CGLUnlockContext(cgl_ctx);
    
    //Check for OpenGL errors
    theError = glGetError();
    if(theError) {
        NSLog(@"v002ScreenCapture: OpenGL texture creation failed (error 0x%04X)", theError);
        CGLUnlockContext(cgl_ctx); // Thread unlock
        return 0;
    }
    
    return mTextureName;
}


///////////////////////////////////////////////////////////////////////
// Drag and Drop
///////////////////////////////////////////////////////////////////////
-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {return NSDragOperationCopy;}
-(BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {return YES;}
-(BOOL)performDragOperation:(id<NSDraggingInfo>)sender {return [AppController performDragOperation:sender];}

///////////////////////////////////////////////////////////////////////
// Fullscreen
///////////////////////////////////////////////////////////////////////
- (void)goFullscreen{
    
    if(f_fullscreenMode){
        NSLog(@"Already full...");    
        return;
    }
    
   
    //Hide cursor
    [NSCursor hide];
    
    // Switch resolution
    [AppController lowerResolution];
        
    NSRect frame = [self.window frame];
    original_size = frame.size;
    //self.position = frame.origin;
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:NO],NSFullScreenModeAllScreens,
                             nil];
    
    
    [self enterFullScreenMode:[NSScreen mainScreen] withOptions:options];

    f_fullscreenMode=true;
}
- (void)goWindowed{
    
    if(!f_fullscreenMode){return;}
    
    // Restore resolution
    [AppController restoreResolution];

    // Exit fullscreen mode
    [self exitFullScreenModeWithOptions:nil];
    [self.window makeFirstResponder:self];
    
    //Hide cursor
    [NSCursor unhide];
    
    
    f_fullscreenMode=false;
}



@end
