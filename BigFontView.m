//
//  BigFontView.m
//  CyborgameSubtitler
//
//  Created by Andrew on 6/5/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import "BigFontView.h"
#import "MainView.h"
#import "AppCommon.h"
#import "NSView+snapshot.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/glu.h>
#import <Syphon/Syphon.h>

@implementation BigFontView

					

@synthesize fontToUse;
@synthesize backgroundColor;
@synthesize backgroundColor2;
@synthesize fontColor;
@synthesize fontColorShadow;
@synthesize displayString;
@synthesize f_autoScale;
@synthesize f_centerText;
@synthesize f_drawShadow;
@synthesize f_flipText;
@synthesize f_mirrorText;
@synthesize f_scrollPause;
@synthesize scaleTextType;
@synthesize scrollDirection;
@synthesize gradientAngle;
@synthesize scaleFactor;
@synthesize global_offsetX;
@synthesize global_offsetY;
@synthesize scrollRate;
@synthesize scrollPosition;
@synthesize droppedFileURL;
@synthesize position;

- (BOOL) acceptsFirstResponder{return YES;}
- (BOOL) resignFirstResponder{return YES;}
- (BOOL) becomeFirstResponder{return YES;}
- (BOOL) canBecomeKeyView{return YES;}
- (BOOL) isFlipped{return NO;}



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
        
        
        // Defaults
        fontToUse=[NSFont fontWithName:@"Helvetica" size:20];
        f_autoScale = false;
        f_centerText = true;
        f_drawShadow = true;
        f_flipText = false;
        f_mirrorText = false;
        f_scrollPause = false;
        gradientAngle=45;
        scaleFactor=1.0;
        global_offsetX = 0.0;
        global_offsetY = 0.0;
        scrollRate = 0.0;
        scaleTextType = 0;
        scrollDirection = 0;
        displayString =  @"";
        scrollRate = 0.0;
        scrollPosition=0.0;
        
        backgroundColor = [NSColor whiteColor];
        backgroundColor2 = [NSColor blackColor];
        fontColor = [NSColor blackColor];
        fontColorShadow = [NSColor blackColor];
        
        f_fullscreenMode=false;
        
        
        
        [[AppCommon sharedInstance] setFontViewController:self];
        
        
        [[self openGLContext] makeCurrentContext];
        glLoadIdentity();
        glGenTextures(1, &glTex_floor);


    }
    return self;
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
    }
    
    return kCVReturnSuccess;
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


- (NSOpenGLContext*) openGLContext{return openGLContext;}

- (void) drawRect:(NSRect)dirtyRect{
    
    // If we're not animating, start
    if (!isAnimating) {[self startAnimation];}
   
    // Draw the view
    [self drawView];
    

    // Sreenshot (much faster than PDF)
    // Used for preview and Syphon
    [[AppCommon sharedInstance] setScreenShot:[self snapshot]];

    // Send via Syphon
    [self syphonSend];
    
   
}

-(void) syphonSend{
    
    // Set current context
    [openGLContext makeCurrentContext];
    
    // Initialize Syphon
    if (!syphonServer){
        NSLog(@"Initializing Syphon Server...");
        syphonServer = [[SyphonServer alloc] initWithName:nil context:[openGLContext CGLContextObj] options:nil];
        if(!syphonServer){NSLog(@"Error initializing Syphon server!");}
        
    
    // Send frame
    }else{
            NSImage *screenShot = [[AppCommon sharedInstance] screenShot];
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
    
    if (![floorTextureNSImage isFlipped]) {
        NSImage *drawImage = [[NSImage alloc] initWithSize:floorTextureNSImage.size];
        NSAffineTransform *transform = [NSAffineTransform transform];
        
        [drawImage lockFocus];
        
        [transform translateXBy:0 yBy:floorTextureNSImage.size.height];
        [transform scaleXBy:1 yBy:-1];
        [transform concat];
        
        [floorTextureNSImage drawAtPoint:NSZeroPoint
                                fromRect:(NSRect){NSZeroPoint, floorTextureNSImage.size}
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

// Draw loop
-(void)drawView{
    
    
    NSString *displayText = self.displayString;
    // Recalculate string if typing effect on
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"f_typingEffect"]){
        if(_rangeMax <= [displayText length]){
            NSRange range={0,_rangeMax};
            displayText = [displayText substringWithRange:range];
        }else{
            if([[NSUserDefaults standardUserDefaults] boolForKey:@"f_typingEffectLoop"]){
                _rangeMax=0;
            }else{
                _rangeMax=(int)[displayText length];
                [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"f_typingEffect"];
            }
        }
    }
    
    
    
    if(displayText == nil){
        displayText=@" ";
    }
    
    // Check origin
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"f_correctOrigin"]){
        [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"f_centerText"];
    }
    //Typing timer
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"f_typingEffect"]){
        if(![typingTimer isValid]){
            typingTimer = [NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults] floatForKey:@"typingRate"] target:self selector:@selector(incrementRange) userInfo:nil repeats:YES];
            _rangeMax=0;
        }
    }else{
        if([typingTimer isValid]){
            [typingTimer invalidate];
            [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"f_typingEffectPause"];
            _rangeMax=0;
        }
    }
    
    
    [[AppCommon sharedInstance] setIsFullscreen:f_fullscreenMode];
    
    // Push the state onto the stack
    [NSGraphicsContext saveGraphicsState];
    
    // Actually display the text
    NSRect displayRect = self.frame;
    NSAffineTransform* transformation = [NSAffineTransform transform];

        // Not sure what this does
        //[[[self window] graphicsContext] setShouldAntialias:YES];

        NSMutableDictionary *drawStringAttributes = [[NSMutableDictionary alloc] init];
        [drawStringAttributes setObject:self.fontToUse forKey:NSFontAttributeName];
        [drawStringAttributes setValue:self.fontColor  forKey:NSForegroundColorAttributeName];
    
      
        NSSize stringSize =  [displayText sizeWithAttributes:drawStringAttributes];

        
    
        // If autoscaling, pick the scale that fills the render window
        float scaleBy = self.scaleFactor;
        if (self.f_autoScale){
            if (self.scaleTextType == 0){
                scaleBy=displayRect.size.height/stringSize.height;
            }else{
                scaleBy=displayRect.size.width/stringSize.width;
            }
        }
    
        // Center the text
        float adjustedHeight;
        if (self.f_centerText){
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
            
            //Calculate the offset for origin correction
            if (scaleBy != 0){
                adjustedHeight=(displayRect.size.height/scaleBy)-stringSize.height;
            }else{
                adjustedHeight=(displayRect.size.height)-stringSize.height;
            }
            
            //NSLog(@"%f",adjustedHeight);
            
            
            
        }
    
    
        // Gradient fill background
        NSGradient *backgroundGradient = [[NSGradient alloc] initWithStartingColor:self.backgroundColor endingColor:self.backgroundColor2];
        [backgroundGradient drawInRect:displayRect angle:self.gradientAngle];

    
        // Add dropshadow if requested
        if (self.f_drawShadow){
            NSShadow *stringShadow = [[NSShadow alloc] init];
            [stringShadow setShadowColor:self.fontColorShadow];
            NSSize shadowSize;
            shadowSize.width = 2;
            shadowSize.height = -2;
            [stringShadow setShadowOffset:shadowSize];
            [stringShadow setShadowBlurRadius:6];
            [drawStringAttributes setValue:stringShadow forKey:NSShadowAttributeName];
        }
            
    
        //Flip
        if (self.f_flipText){
            [transformation scaleXBy:1.0 yBy:-1.0];
            [transformation translateXBy:1.0 yBy:-stringSize.height];
        }
        
        //Mirror
        if (self.f_mirrorText){
            [transformation scaleXBy:-1.0 yBy:1.0];
            [transformation translateXBy:-stringSize.width yBy:1.0];
        }
    
      
        // Correct the origin if requested
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"f_correctOrigin"]){
            
            //NSLog(@"Adjusting y:%f",adjustedHeight);
            [transformation translateXBy:0.0 yBy:adjustedHeight];
            // Global offset
            [transformation translateXBy:self.global_offsetX yBy:self.global_offsetY];
        }else{
            // Global offset
            [transformation translateXBy:self.global_offsetX yBy:self.global_offsetY];
        }
    
    
    
    
        // Scroll the text
        float scaledLineWidth = stringSize.width*scaleBy;
        float scaledLineHeight = stringSize.height*scaleBy;
        float displayWidth = displayRect.size.width;
        float displayHeight = displayRect.size.height;
        float rolloverAt;
    
        // Horizontal scroll
        if (self.scrollDirection == HORIZONTAL){
            // We rollover at half the line width plus half the display width
            rolloverAt=scaledLineWidth/2 + displayWidth/2;
        
            // But scaling only changes the linewidth coordinates, so we divide to adjust
            if (scaleBy != 0){
                rolloverAt=rolloverAt/scaleBy;
            }
        // Vertical scroll
        }else if (self.scrollDirection == VERTICAL){
            
            // We rollover at half the line width plus half the display width
            rolloverAt=scaledLineHeight/2 + displayHeight/2;
            
            // But scaling only changes the linewidth coordinates, so we divide to adjust
            if (scaleBy != 0){
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
        if (scaleBy != 0){
            scrollUnit=scrollUnit/scaleBy;
        }
        // Adjust for width of window
        scrollUnit = scrollUnit * (displayRect.size.width/858.0);

        // Adjust for height of type
        //scrollUnit = scrollUnit + (scaledLineHeight/.01);

        // Scale the unit
        //scrollUnit = scrollUnit/scaleBy;
        //scrollUnit=scrollUnit/100;
    
        // Multiply it by the rate
        scrollUnit = scrollUnit*self.scrollRate;
    
        // Adjust for width of window
        //scrollUnit = scrollUnit * (displayRect.size.width/858.0);
        //NSLog(@"%f:%f",scrollUnit, self.scrollPosition);
    
    
        // Scroll if not paused
        if (!self.f_scrollPause){
            self.scrollPosition=self.scrollPosition+scrollUnit;
           // If we are off the screen, wrap
            if (abs(self.scrollPosition ) > rolloverAt){
                if (scrollUnit < 0){
                    self.scrollPosition  = rolloverAt;
                }else{
                    self.scrollPosition  = -1*rolloverAt;
                }
            }
        }
    
        
        // Apply scroll offset
        if (self.scrollDirection == HORIZONTAL){
            [transformation translateXBy:self.scrollPosition  yBy:1.0];
        }else if (self.scrollDirection == VERTICAL){
            [transformation translateXBy:1.0 yBy:self.scrollPosition];
        }
    

        // Actually apply transformation to view
        [transformation concat];
    
        // NOW draw the text into the transformed view
        [displayText drawAtPoint:NSMakePoint(0.0, 0.0) withAttributes:drawStringAttributes];
        
    // Pop the stack
    [NSGraphicsContext restoreGraphicsState];
    
    
    
    // Overlay
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"f_overlay"]){}

    
   
}

-(void)incrementRange{
    
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"f_typingEffectPause"]){
        //NSLog(@"Going %d",_rangeMax);
        _rangeMax++;
    }
}

- (void)keyDown:(NSEvent *)event {
        NSLog(@"Key event...");
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
-(BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    
    if ( [sender draggingSource] != self ) {
        
        
        // Check extension... If this is a settings file, load the settings
        NSPasteboard* pbrd = [sender draggingPasteboard];
        NSArray *draggedFilePaths = [pbrd propertyListForType:NSFilenamesPboardType];
        NSString *path=draggedFilePaths[0];
        NSArray *parsedPath = [path componentsSeparatedByString:@"/"];
        NSArray *parsedFilename = [parsedPath[[parsedPath count]-1] componentsSeparatedByString:@"."];
        NSString* extension = parsedFilename[[parsedFilename count]-1];
        if ([extension isEqualToString:@"settings"]){
            NSMutableDictionary *savedSettings = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
            NSLog(@"Loading settings file... %@ ",path);
            
            if (![savedSettings objectForKey:@"subtitler_settings_file"]) {
                //not a subtitler settings file
                NSBeep();
                NSLog(@"Not a settings file!");
                return false;
            }else{
            
                [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"global_offsetX"];
                [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"global_offsetY"];
                [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"scrollRate"];
                
                [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"scrollPosition"];
                
                
                NSString *searchFor = @"apple";
                NSRange range;
                for (NSString* key in savedSettings) {
                    range = [key rangeOfString:searchFor];
                    NSString *firstTwoChars = [key substringWithRange:NSMakeRange(0, 2)];
                    NSString *firstFiveChars = [key substringWithRange:NSMakeRange(0, 5)];
                    if (range.location == NSNotFound && ![firstTwoChars isEqualToString:@"NS"] && ![firstTwoChars isEqualToString:@"QT"] && ![firstFiveChars isEqualToString:@"Apple"]){
                        NSLog(@"%@",key);
                        [[NSUserDefaults standardUserDefaults] setObject:[savedSettings objectForKey:key] forKey:key];
                    }
                }
                return true;
            }
        }
        
        
        // Else treat as a text file
        self.droppedFileURL=[NSURL URLFromPasteboard: [sender draggingPasteboard]];
        return true;
    }
    
    return false;
    
}


///////////////////////////////////////////////////////////////////////
// Fullscreen
///////////////////////////////////////////////////////////////////////
- (void)goFullscreen{
    
    if(f_fullscreenMode){
        NSLog(@"Already full...");    
        return;
    }
    
    NSLog(@"Going full...");
    
    NSRect frame = [self.window frame];
    original_size = frame.size;
    self.position = frame.origin;
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:NO],NSFullScreenModeAllScreens,
                             nil];
    
    
    [self enterFullScreenMode:[NSScreen mainScreen] withOptions:options];

    f_fullscreenMode=true;
}
- (void)goFullscreen2{
    
    return;
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:NO],NSFullScreenModeAllScreens,
                             nil];
    
    NSRect frame = [self.window frame];
    
    /*
    self.position = frame.origin;
    [[self.window] setFrame:NSMakeRect(self.position.x, self.position.y, NSHeight(frame)) display:YES];
    */
    
    
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
    
    if(!f_fullscreenMode){return;}
    [self exitFullScreenModeWithOptions:nil];
    [self.window makeFirstResponder:self];
    
    f_fullscreenMode=false;
}




@end
