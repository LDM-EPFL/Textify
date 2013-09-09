 //
//  MainView.m
//  CyborgameSubtitler
//
//  Created by Andrew on 7/4/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import "MainView.h"
#import "AppDelegate.h"
#import "TextSlice.h"
#import "AppController.h"

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



-(void) awakeFromNib{
    //Accept Drag and Drop
    //[self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    
    // Timer to poll external file
    NSTimer* pollFile = [NSTimer scheduledTimerWithTimeInterval:1/2 target:self selector:@selector(updateState) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:pollFile forMode:NSRunLoopCommonModes];
    
    // Bring other window front
    [self.window makeKeyAndOrderFront:self];

    /*
    // Defaults
    //[[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"displayText"];
    [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"textFile"];
    [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"global_offsetX"];
    [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"global_offsetY"];
    [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"f_scrollPause"];
    [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"f_watchFile"];
*/
       
}


///////////////////////////////////////////////////////////////////////
// Keyboard handling
///////////////////////////////////////////////////////////////////////
- (void)keyDown:(NSEvent *)event{
    
    NSLog(@"Keyboard shortcuts disabled...");
    return;
    
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
                NSBeep();
            }
            break;
        
        // CMD +SHFT+R
        case 'R':
            
            // CMD R
            if([event modifierFlags] & NSCommandKeyMask){
                NSBeep();
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
