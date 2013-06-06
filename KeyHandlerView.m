//
//  KeyHandlerView.m
//  CyborgameSubtitler
//
//  Created by Andrew on 6/5/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import "KeyHandlerView.h"
#import <ApplicationServices/ApplicationServices.h>

@implementation KeyHandlerView

bool f_fullscreenMode=false;

- (id)initWithFrame:(NSRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect{
    // Drawing code here.

}




// FUllscreen: http://cocoadevcentral.com/articles/000028.php
- (void)goFullscreen{
    int windowLevel;
    NSRect screenRect;
    
    // Capture the main display
    // CGCaptureAllDisplays() instead will shield ALL screens
    if (CGDisplayCapture( kCGDirectMainDisplay ) != kCGErrorSuccess) {
        NSLog( @"Couldn't capture the main display!" );
    }
    
    // Get the shielding window level
    windowLevel = CGShieldingWindowLevel();
    
    // Get the screen rect of our main display
    screenRect = [[NSScreen mainScreen] frame];
    
    //screenRect = NSMakeRect(0, 0, 200, 200);
    
    // Put up a new window
    mainWindow = [[NSWindow alloc] initWithContentRect:screenRect
                                             styleMask:NSBorderlessWindowMask
                                               backing:NSBackingStoreBuffered
                                                 defer:NO 
                                                screen:[NSScreen mainScreen]];
    [mainWindow setLevel:windowLevel];
    [mainWindow setBackgroundColor:[NSColor blackColor]];
    
        
    // Load our content view into it
    NSLog(@"Loading content...");
    [_fullScreenView setFrame:screenRect display:YES];
    [mainWindow setContentView:[_fullScreenView contentView]];
    
   
    [mainWindow makeKeyAndOrderFront:nil];

    
    f_fullscreenMode=true;
}

- (void)undoFullscreen{
    [mainWindow orderOut:self];
    f_fullscreenMode=false;
    
    // Release the display(s)
    if (CGDisplayRelease( kCGDirectMainDisplay ) != kCGErrorSuccess) {
        NSLog( @"Couldn't release the display(s)!" );
    }
    
}



// Keyboard
- (BOOL) acceptsFirstResponder{return YES;}
- (BOOL) resignFirstResponder{return YES;}
- (BOOL) becomeFirstResponder{return YES;}
- (BOOL) canBecomeKeyView{return YES;}
- (void)keyDown:(NSEvent *)event {
    NSLog(@"keyDown [%@]", [event characters]);
    
    unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
    switch(key) {
            
        case 'f':case 'F':
            if (!f_fullscreenMode){
                [self goFullscreen];
            }else{
                [self undoFullscreen];
            }
            break;

    }
    
    switch([event keyCode]) {
        // ESC
        case 53:
            if (f_fullscreenMode){
                NSLog(@"Closing self...");
                [self undoFullscreen];
            }
            break;
    }
    
    [[self nextResponder] keyDown:event];
}


- (void)mouseDown:(NSEvent *)theEvent {
    NSLog(@"Click");
    [[self nextResponder] mouseDown:theEvent];
}
@end
