 //
//  MainView.m
//  CyborgameSubtitler
//
//  Created by Andrew on 7/4/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import "MainView.h"
#import "AppDistributed.h"

#import "AppCommon.h"
@implementation MainView


- (BOOL) acceptsFirstResponder{return YES;}
- (BOOL) resignFirstResponder{return YES;}
- (BOOL) becomeFirstResponder{return YES;}
- (BOOL) canBecomeKeyView{return YES;}

// Called by timer
bool f_resetScrollPosition=false;
bool f_makeChildFront=true;
NSString *previousLoadString;










-(void)updateState{

    
    [_pubImage setImage:[[AppCommon sharedInstance] screenShot]];
    [_pubImage setNeedsDisplay:YES];
    
    
    


    [[NSUserDefaults standardUserDefaults] setValue:[_windowedTextView.droppedFileURL absoluteString] forKey:@"externalFilename"];
    if(_windowedTextView.droppedFileURL && [[NSUserDefaults standardUserDefaults] boolForKey:@"f_watchFile"]){
        
        
        //NSLog(@"I should load %@",[_windowedTextView.droppedFileURL absoluteString]);
        
        NSError* error = nil;
        NSString* string = [NSString stringWithContentsOfURL:_windowedTextView.droppedFileURL  encoding:NSUTF8StringEncoding error:&error];
        
        if(![string isEqualToString:previousLoadString]){
            NSLog(@"Something changed!");
            [_windowedTextView setRangeMax:0];
        }
        
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
        
    
    }else{
        [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"f_watchFile"];
    }
    
    
    
    // Synchronize view and UI
    if(f_resetScrollPosition){
        NSLog(@"Reset scroll position...");
        _windowedTextView.scrollPosition = 0.0;
        f_resetScrollPosition=false;
    }
    _windowedTextView.f_flipText = [[NSUserDefaults standardUserDefaults] boolForKey:@"f_flipText"];
    _windowedTextView.f_autoScale = [[NSUserDefaults standardUserDefaults] boolForKey:@"f_autoScale"];
    _windowedTextView.f_centerText = [[NSUserDefaults standardUserDefaults] boolForKey:@"f_centerText"];
    _windowedTextView.f_drawShadow = [[NSUserDefaults standardUserDefaults] boolForKey:@"f_drawShadow"];
    _windowedTextView.f_flipText = [[NSUserDefaults standardUserDefaults] boolForKey:@"f_flipText"];
    _windowedTextView.f_mirrorText = [[NSUserDefaults standardUserDefaults] boolForKey:@"f_mirrorText"];
    _windowedTextView.f_scrollPause = [[NSUserDefaults standardUserDefaults] boolForKey:@"f_scrollPause"];
    
    
    _windowedTextView.gradientAngle=[[NSUserDefaults standardUserDefaults] floatForKey:@"gradientAngle"];
    _windowedTextView.scaleFactor = [[NSUserDefaults standardUserDefaults] floatForKey:@"scaleFactor"];
    
    _windowedTextView.global_offsetX = [[NSUserDefaults standardUserDefaults] floatForKey:@"global_offsetX"];
    _windowedTextView.global_offsetY = [[NSUserDefaults standardUserDefaults] floatForKey:@"global_offsetY"];
    _windowedTextView.scrollRate = [[NSUserDefaults standardUserDefaults] floatForKey:@"scrollRate"];
    _windowedTextView.scaleTextType = [[NSUserDefaults standardUserDefaults] integerForKey:@"scaleTextType"];
    _windowedTextView.scrollDirection = [[NSUserDefaults standardUserDefaults] integerForKey:@"scrollDirection"];
    
    _windowedTextView.displayString = [[NSUserDefaults standardUserDefaults] valueForKey:@"displayText"];
    _windowedTextView.scrollRate = [[NSUserDefaults standardUserDefaults] floatForKey:@"scrollRate"];
    
    
    @try {
        _windowedTextView.fontToUse = (NSFont *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"fontSelected"]];
        _windowedTextView.backgroundColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"colorBackground"]];
        _windowedTextView.backgroundColor2 = (NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"colorBackground2"]];
        _windowedTextView.fontColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"colorFont"]];
        _windowedTextView.fontColorShadow = (NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"colorFontShadow"]];
        
    }@catch (NSException *exception) {
        NSLog(@"Failed loading fonts and colors from userprefs, setting defaults...");
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:[NSFont fontWithName:@"Helvetica" size:20]] forKey:@"fontSelected"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:_windowedTextView.backgroundColor] forKey:@"colorBackground"];
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:_windowedTextView.backgroundColor2] forKey:@"colorBackground2"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:_windowedTextView.fontColor] forKey:@"colorFont"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:_windowedTextView.backgroundColor] forKey:@"colorFontShadow"];
    }
    
    
    
    
    
}

-(void) awakeFromNib{
    //Accept Drag and Drop
    //[self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    
    // Timer to poll external file
    NSLog(@"Launching timer...");
    NSTimer* pollFile = [NSTimer scheduledTimerWithTimeInterval:1/2 target:self selector:@selector(updateState) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:pollFile forMode:NSRunLoopCommonModes];
    
    // Bring other window front
    [self.window makeKeyAndOrderFront:self];
    
    
    // Defaults
    //[[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"displayText"];
    [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"textFile"];
    [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"global_offsetX"];
    [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"global_offsetY"];
    [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"f_scrollPause"];
    [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"f_watchFile"];

       
}


///////////////////////////////////////////////////////////////////////
// Keyboard handling
///////////////////////////////////////////////////////////////////////
- (void)keyDown:(NSEvent *)event{
    
    float max_scrollRate = 100;
    float min_scrollRate = -100;
    float step_scrollRate = .05;
    
    unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
    switch(key) {
            
        case 'f':case 'F':
            
            // F + CTRL
            if([event modifierFlags] & NSControlKeyMask){
                [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:@"f_flipText"] forKey:@"f_flipText"];
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
            }
            

            
            break;
            
            
        // CMD+r
        case 'r':
            if([event modifierFlags] & NSCommandKeyMask){
                
                [self resetText];
               
            }
            break;
        
        // CMD +SHFT+R
        case 'R':
            
            // CMD R
            if([event modifierFlags] & NSCommandKeyMask){
                
                NSLog(@"%f,%f,%f,%f,%f,%f",
                [[NSUserDefaults standardUserDefaults] floatForKey:@"global_offsetX"],
                [[NSUserDefaults standardUserDefaults] floatForKey:@"global_offsetY"],
                [[NSUserDefaults standardUserDefaults] floatForKey:@"scrollRate"],
                [[NSUserDefaults standardUserDefaults] floatForKey:@"scaleFactor"],
                [[NSUserDefaults standardUserDefaults] floatForKey:@"scrollPosition"],
                      _windowedTextView.scrollPosition);
                
                
                [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"global_offsetX"];
                [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"global_offsetY"];
                [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"scrollRate"];
                [[NSUserDefaults standardUserDefaults] setFloat:1.0 forKey:@"scaleFactor"];
                [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"scrollPosition"];
                f_resetScrollPosition=true;
            }
        break;
            
        case 'p':case 'P': case ' ':
            [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:@"f_scrollPause"] forKey:@"f_scrollPause"];
            break;
            
            
            


        
        
        case NSLeftArrowFunctionKey:
            // SHIFT Left Arrow
            if([event modifierFlags] & NSShiftKeyMask){
                [[NSUserDefaults standardUserDefaults] setFloat:[[NSUserDefaults standardUserDefaults] floatForKey:@"global_offsetX"]-1 forKey:@"global_offsetX"];
                
                // Left Arrow
            }else{
                float newscrollRate = [[NSUserDefaults standardUserDefaults] floatForKey:@"scrollRate"]-step_scrollRate;
                if (newscrollRate < min_scrollRate){
                    newscrollRate=min_scrollRate;
                }
                [[NSUserDefaults standardUserDefaults] setFloat:newscrollRate forKey:@"scrollRate"];
            }
            break;
            
            
        case NSRightArrowFunctionKey:
            // SHIFT Right Arrow
            if([event modifierFlags] & NSShiftKeyMask){
                [[NSUserDefaults standardUserDefaults] setFloat:[[NSUserDefaults standardUserDefaults] floatForKey:@"global_offsetX"]+1 forKey:@"global_offsetX"];
                
                // Right Arrow
            }else{
                
                float newscrollRate = [[NSUserDefaults standardUserDefaults] floatForKey:@"scrollRate"]+step_scrollRate;
                if (newscrollRate > max_scrollRate){
                    newscrollRate=max_scrollRate;
                }
                [[NSUserDefaults standardUserDefaults] setFloat:newscrollRate forKey:@"scrollRate"];
            }
            break;
            
            
        case NSDownArrowFunctionKey:
            // SHIFT Down Arrow
            if([event modifierFlags] & NSShiftKeyMask){
                [[NSUserDefaults standardUserDefaults] setFloat:[[NSUserDefaults standardUserDefaults] floatForKey:@"global_offsetY"]-1 forKey:@"global_offsetY"];
                
            // CMD Down Arrow
            }else if([event modifierFlags] & NSCommandKeyMask){
                
                if([[NSUserDefaults standardUserDefaults] boolForKey:@"f_autoScale"]){
                    NSBeep();
                    break;
                }

                
                float newScaleFactor = [[NSUserDefaults standardUserDefaults] floatForKey:@"scaleFactor"]-1;
                if (newScaleFactor < 1){
                    newScaleFactor=1;
                    NSBeep();
                    break;
                }
                [[NSUserDefaults standardUserDefaults] setFloat:newScaleFactor forKey:@"scaleFactor"];
                
                // Down Arrow
            }else{
                float newscrollRate = [[NSUserDefaults standardUserDefaults] floatForKey:@"scrollRate"]-step_scrollRate;
                if (newscrollRate < min_scrollRate){
                    newscrollRate=min_scrollRate;
                }
                [[NSUserDefaults standardUserDefaults] setFloat:newscrollRate forKey:@"scrollRate"];
                
            }
            break;
            
            
        case NSUpArrowFunctionKey:
            // SHIFT Up Arrow
            if([event modifierFlags] & NSShiftKeyMask){
                [[NSUserDefaults standardUserDefaults] setFloat:[[NSUserDefaults standardUserDefaults] floatForKey:@"global_offsetY"]+1 forKey:@"global_offsetY"];
                break;
                
            // CMD Up Arrow
            }else if([event modifierFlags] & NSCommandKeyMask){
                
                if([[NSUserDefaults standardUserDefaults] boolForKey:@"f_autoScale"]){
                    NSBeep();
                    break;
                }
                float newScaleFactor = [[NSUserDefaults standardUserDefaults] floatForKey:@"scaleFactor"]+1;
                if (newScaleFactor > 150){
                    newScaleFactor=150;
                    NSBeep();
                    break;
                }
                [[NSUserDefaults standardUserDefaults] setFloat:newScaleFactor forKey:@"scaleFactor"];
                
                
                
            // UP Arrow
            }else{
                float newscrollRate = [[NSUserDefaults standardUserDefaults] floatForKey:@"scrollRate"]+step_scrollRate;
                if (newscrollRate > max_scrollRate){
                    newscrollRate=max_scrollRate;
                }
                [[NSUserDefaults standardUserDefaults] setFloat:newscrollRate forKey:@"scrollRate"];
                
            }
            break;
            
            
            
            
            
            
    }
    
       
    //[[self nextResponder] keyDown:event];
}


-(void)resetText{
    [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"global_offsetX"];
    [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"global_offsetY"];
    [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"scrollRate"];
    
    [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"scrollPosition"];
    f_resetScrollPosition=true;

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
    
    /* FIXME
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
     */
    return false;
}


- (IBAction)publishImage:(id)sender {
}
@end
