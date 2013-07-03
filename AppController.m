//
//  AppController.m
//  CyborgameSubtitler
//
//  Created by Andrew on 7/3/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import "AppController.h"

@implementation AppController

///////////////////////////////////////////////////////////
// NSView
///////////////////////////////////////////////////////////

- (id)initWithCoder:(NSCoder *)decoder
{
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
- (void) drawRect:(NSRect)dirtyRect{
    [self drawView];
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
    
    NSLog(@"Saving pos...");
    NSRect frame = [self.window frame];
    [[NSUserDefaults standardUserDefaults] setInteger:frame.origin.x forKey:@"dockPos_x"];
    [[NSUserDefaults standardUserDefaults] setInteger:frame.origin.y forKey:@"dockPos_y"];
    [[NSUserDefaults standardUserDefaults] setInteger:frame.size.width forKey:@"dockPos_width"];
}
@end
