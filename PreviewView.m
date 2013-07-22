//
//  PreviewView.m
//  PerformanceSpace
//
//  Created by Andrew on 7/18/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//
// Fixes NSLOG (removes timestamp)

#import "PreviewView.h"
#import "KinectView.h"
#import "AppCommon.h"
#import "KinectViewController.h"

// Fixes NSLOG (removes timestamp)
#define NSLog(FORMAT, ...) fprintf(stderr,"%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
@implementation PreviewView

- (id)initWithFrame:(NSRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        //Drag and Drop Setup
        [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect{
    [super drawRect:dirtyRect];
    // Drawing code here.
}


- (BOOL)acceptsFirstResponder{return YES;}


-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {return NSDragOperationCopy;}
-(BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {return YES;}
-(BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
        
    // Accepts a folder
    NSPasteboard* pbrd = [sender draggingPasteboard];
    NSArray *draggedFilePaths = [pbrd propertyListForType:NSFilenamesPboardType];
    NSString *path=draggedFilePaths[0];
    NSArray *parsedPath = [path componentsSeparatedByString:@"/"];
    //NSString *folderName=parsedPath[[parsedPath count]-1];
    
    
    // Check extension... If this is a settings file, load the settings
    NSArray *parsedFilename = [parsedPath[[parsedPath count]-1] componentsSeparatedByString:@"."];
    NSString* extension = parsedFilename[[parsedFilename count]-1];
    if ([extension isEqualToString:@"settings"]){
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
                
                
                
                for (NSString* key in savedSettings) {

                    if ([key isEqualToString:@"global_offsetY"] ||
                        [key isEqualToString:@"colorBackground2"] ||
                        [key isEqualToString:@"scrollPosition"] ||
                        [key isEqualToString:@"fontSelected"] ||
                        [key isEqualToString:@"scrollSpeed"] ||
                        [key isEqualToString:@"colorFont"] ||
                        [key isEqualToString:@"f_scrollReverse"] ||
                        [key isEqualToString:@"colorBackground"] ||
                        [key isEqualToString:@"global_offsetX"] ||
                        [key isEqualToString:@"gradientAngle"] ||
                        [key isEqualToString:@"publishID"] ||
                        [key isEqualToString:@"displayText"] ||
                        [key isEqualToString:@"global_translateX"] ||
                        [key isEqualToString:@"f_flipText"] ||
                        [key isEqualToString:@"textFile"] ||
                        [key isEqualToString:@"f_publishImage"] ||
                        [key isEqualToString:@"f_mirrorText"] ||
                        [key isEqualToString:@"global_translateY"] ||
                        [key isEqualToString:@"f_scroll"] ||
                        [key isEqualToString:@"f_centerTextv"] ||
                        [key isEqualToString:@"scrollRate"] ||
                        [key isEqualToString:@"f_scrollPause"] ||
                        [key isEqualToString:@"f_watchFile"] ||
                        [key isEqualToString:@"scaleFactor"] ||
                        [key isEqualToString:@"colorFontShadow"] ||
                        [key isEqualToString:@"f_scaleTextType"] ||
                        [key isEqualToString:@"f_scaleText"] ||
                         [key isEqualToString:@"f_autoScale"] ||
                        [key isEqualToString:@"f_drawShadow"] ||
                        [key isEqualToString:@"positionX"] ||
                        [key isEqualToString:@"positionY"] ||
                        [key isEqualToString:@"positionZ"] ||
                        [key isEqualToString:@"scaleTextType"] ||
                        [key isEqualToString:@"f_stripLinebreaks"] ||
                        [key isEqualToString:@"typingRate"] ||
                        [key isEqualToString:@"f_centerText"] ||
                        [key isEqualToString:@"f_overlay"] ||
                        [key isEqualToString:@"f_typingEffect"] ||
                        [key isEqualToString:@"scrollDirection"] ||
                        
                        [key isEqualToString:@"globalPosition_"] ||
                        [key isEqualToString:@"globalPosition_"] ||
                        [key isEqualToString:@"globalPosition_"] ||
                        [key isEqualToString:@"globalPosition_"] ||
                        [key isEqualToString:@"globalPosition_"] ||
                        [key isEqualToString:@"globalPosition_"] ||
                        [key isEqualToString:@"globalPosition_"] ||
                        [key isEqualToString:@"globalPosition_"] ||
                        [key isEqualToString:@"globalPosition_"] ||
                        [key isEqualToString:@"overlayTransparencyVal"] ||
                        [key isEqualToString:@"f_correctOrigin"] ||
                        [key isEqualToString:@"f_typingEffectPause"] 
                        ){
                        //NSLog(@"%@",key);
                        [[NSUserDefaults standardUserDefaults] setObject:[savedSettings objectForKey:key] forKey:key];
                    }else{
                        NSLog(@"IGNORING: %@",key);
                    }
                }
                return true;
            }
        }
    }
    return NO;
}
@end
