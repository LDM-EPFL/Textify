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
- (id)initWithFrame:(NSRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        
        
        //Accept Drag and Drop
        [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
        
        // Displaylink
        [self setupDisplayLink];
        //[NSTimer scheduledTimerWithTimeInterval:1/60 target:self selector:@selector(drawView) userInfo:nil repeats:YES];
        	
		// Look for changes in view size
		// Note, -reshape will not be called automatically on size changes because NSView does not export it to override
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(reshape)
													 name:NSViewGlobalFrameDidChangeNotification
												   object:self];
        
        
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


- (void) drawRect:(NSRect)dirtyRect{
    // If we're not animating, start
    if (!isAnimating) {[self startAnimation];}
    [self drawView];
}


///////////////////////////////////////////////////////////////////////
// Setup and Draw
///////////////////////////////////////////////////////////////////////

// Draw loop
-(void)drawView{
    
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
    
      
        NSSize stringSize =  [self.displayString sizeWithAttributes:drawStringAttributes];

        
    
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
    
      
        // Global offset
        [transformation translateXBy:self.global_offsetX yBy:self.global_offsetY];
    
    
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
            rolloverAt=rolloverAt/scaleBy;
        
        // Vertical scroll
        }else if (self.scrollDirection == VERTICAL){
            
            // We rollover at half the line width plus half the display width
            rolloverAt=scaledLineHeight/2 + displayHeight/2;
            
            // But scaling only changes the linewidth coordinates, so we divide to adjust
            rolloverAt=rolloverAt/scaleBy;
            
        }
    
        // We should scale the scrollstep as well

        //float scrollUnit=1;
    
        // Make a unit that is 1 character
        float scrollUnit=1;
        if(stringSize.width){
            scrollUnit = stringSize.width/displayString.length;
        }

        scrollUnit=scrollUnit/scaleBy;
    
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
        [self.displayString drawAtPoint:NSMakePoint(0.0, 0.0) withAttributes:drawStringAttributes];
        
    // Pop the stack
    [NSGraphicsContext restoreGraphicsState];
    
    
    
    // Overlay
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"f_overlay"]){

        
        
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
