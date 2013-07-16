//
//  AppController.m
//  CyborgameSubtitler
//
//  Created by Andrew on 7/3/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import "AppController.h"
#import "AppDistributed.h"
#import "AppCommon.h"

@implementation AppController

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

}

-(void)awakeFromNib{
    //Global keyboard handler
    [self globalKeyboardHandler];
}


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
                        }
                            
                        // CMD+CTRL+ALT+upArrow Put the stageview on the display above where it is now
                        case NSUpArrowFunctionKey:{
                            BOOL destinationFound=false;
                            for(NSScreen *foundScreen in [NSScreen screens]){
                                // Skip the screen we're on
                                if   (!(foundScreen.frame.origin.x == stageWindow.screen.frame.origin.x
                                        && foundScreen.frame.origin.y == stageWindow.screen.frame.origin.y)){
                                    // A screen is above me if its origin Y point is above my topmost point
                                    if (foundScreen.frame.origin.y >= stageWindow.screen.frame.origin.y+stageWindow.frame.size.height){
                                        [stageWindow orderBack:self];
                                        [stageWindow setFrameOrigin:foundScreen.frame.origin];
                                        [stageWindow center];
                                        [stageWindow makeKeyAndOrderFront:self];
                                        destinationFound=true;
                                        //if we're putting it on the same window as the control panel, don't fullsize
           
                                        
                                        if (foundScreen.frame.origin.x == controlWindow.screen.frame.origin.x && foundScreen.frame.origin.y == controlWindow.screen.frame.origin.y){
                                            NSLog(@"Should be windowed");
                                            [[AppCommon sharedInstance] setF_goWindowed:TRUE];
                                        }else{
                                            [[AppCommon sharedInstance] setF_goFullscreen:TRUE];
                                        }
                                        break;
                                    }
                                }
                            }
                            if(!destinationFound){NSBeep();}
                            break;
                            
                            
                        // CMD+CTRL+ALT+downArrow Put the stageview on the display below where it is now
                        }case NSDownArrowFunctionKey:{
                            BOOL destinationFound=false;
                            for(NSScreen *foundScreen in [NSScreen screens]){
                                // Skip the screen we're on
                                if   (!(foundScreen.frame.origin.x == stageWindow.screen.frame.origin.x
                                        && foundScreen.frame.origin.y == stageWindow.screen.frame.origin.y)){
                                    // A screen is below me if its topmost point is below my origin
                                    if ((foundScreen.frame.origin.y+foundScreen.frame.size.height) <= stageWindow.screen.frame.origin.y){
                                        
                                        [stageWindow orderBack:self];
                                        [stageWindow setFrameOrigin:foundScreen.frame.origin];
                                        [stageWindow center];
                                        [stageWindow makeKeyAndOrderFront:self];
                                        destinationFound=true;
                                        //if we're putting it on the same window as the control panel, don't fullsize
                                        [[AppCommon sharedInstance] setF_goWindowed:TRUE];
                                        
                                        if (foundScreen.frame.origin.x == controlWindow.screen.frame.origin.x && foundScreen.frame.origin.y == controlWindow.screen.frame.origin.y){
                                            NSLog(@"Should be windowed");
                                            [[AppCommon sharedInstance] setF_goWindowed:TRUE];
                                        }else{
                                            [[AppCommon sharedInstance] setF_goFullscreen:TRUE];
                                        }
                                        break;
                                    }
                                }
                            }
                            if(!destinationFound){NSBeep();}
                            break;
                            
                            
                            
                        // CMD+CTRL+ALT+leftArrow Put the stageview on the display to the left of where it is now
                        }case NSLeftArrowFunctionKey:{
                            BOOL destinationFound=false;
                            for(NSScreen *foundScreen in [NSScreen screens]){
                                // Skip the screen we're on
                                if   (!(foundScreen.frame.origin.x == stageWindow.screen.frame.origin.x
                                        && foundScreen.frame.origin.y == stageWindow.screen.frame.origin.y)){
                                    // A screen is to my left if its rightmost point is to the left of my origin
                                    if ((foundScreen.frame.origin.x+foundScreen.frame.size.width) <= stageWindow.screen.frame.origin.x){
                                       
                                        [stageWindow orderBack:self];
                                        [stageWindow setFrameOrigin:foundScreen.frame.origin];
                                        [stageWindow center];
                                        [stageWindow makeKeyAndOrderFront:self];
                                        destinationFound=true;
                                        //if we're putting it on the same window as the control panel, don't fullsize
                                        
                                        if (foundScreen.frame.origin.x == controlWindow.screen.frame.origin.x && foundScreen.frame.origin.y == controlWindow.screen.frame.origin.y){
                                            NSLog(@"Should be windowed");
                                            [[AppCommon sharedInstance] setF_goWindowed:TRUE];
                                        }else{
                                            [[AppCommon sharedInstance] setF_goFullscreen:TRUE];
                                        }
                                        break;
                                    }
                                }
                            }
                            if(!destinationFound){NSBeep();}
                            break;
                            
                            
                        // CMD+CTRL+ALT+rightArrow Put the stageview on the display to the left of where it is now
                        }case NSRightArrowFunctionKey:{
                            BOOL destinationFound=false;
                            for(NSScreen *foundScreen in [NSScreen screens]){
                                // Skip the screen we're on
                                if   (!(foundScreen.frame.origin.x == stageWindow.screen.frame.origin.x
                                        && foundScreen.frame.origin.y == stageWindow.screen.frame.origin.y)){
                                    // A screen is to my left if its rightmost point is to the left of my origin
                                    if (foundScreen.frame.origin.x >= (stageWindow.screen.frame.origin.x+stageWindow.screen.frame.size.width)){
                                        
                                        [stageWindow orderBack:self];
                                        [stageWindow setFrameOrigin:foundScreen.frame.origin];
                                        [stageWindow center];
                                        [stageWindow makeKeyAndOrderFront:self];
                                        destinationFound=true;
                                        //if we're putting it on the same window as the control panel, don't fullsize
                                        
                                        if (foundScreen.frame.origin.x == controlWindow.screen.frame.origin.x && foundScreen.frame.origin.y == controlWindow.screen.frame.origin.y){
                                            NSLog(@"Should be windowed");
                                            [[AppCommon sharedInstance] setF_goWindowed:TRUE];
                                        }else{
                                            [[AppCommon sharedInstance] setF_goFullscreen:TRUE];
                                        }
                                        break;
                                    }
                                }
                            }
                            if(!destinationFound){NSBeep();}
                            break;
                            
                        // CMD+CTRL+ALT+R Reset display
                        }case 'R':case'r':{
                            
                            
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
                            newFrame.size.height*=2;
                            newFrame.origin.y-=controlWindow.frame.size.height+(newFrame.size.height/2);
                            [stageWindow setFrame:newFrame display:YES];
                            
                            // Unhide
                            [stageWindow makeKeyAndOrderFront:self];
                            [controlWindow makeKeyAndOrderFront:self];
                            
                            
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
                        NSLog(@"Saving...");
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


@end
