//
//  SettingsFile.m
//  Textify
//
//  Created by Andrew on 9/14/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import "SettingsFile.h"
#import "FRAppCommon.h"
#import "BigFontView.h"
#import "AppController.h"

@implementation SettingsFile

// UGH! This is NOT the way to do this, but I don't want to break existing settings files
+(BOOL)allowedKey:(NSString*)key{
    return (
            
            [key isEqualToString:@"externalFilename"] ||
            
            [key isEqualToString:@"global_translateX"] ||
            [key isEqualToString:@"global_translateY"] ||
            
            [key isEqualToString:@"global_offsetX"] ||
            [key isEqualToString:@"global_offsetY"] ||
            
            [key isEqualToString:@"colorBackground2"] ||
            
            [key isEqualToString:@"fontSelected"] ||
            [key isEqualToString:@"scrollSpeed"] ||
            [key isEqualToString:@"colorFont"] ||
            [key isEqualToString:@"f_scrollReverse"] ||
            [key isEqualToString:@"colorBackground"] ||
            
            [key isEqualToString:@"gradientAngle"] ||
            [key isEqualToString:@"publishID"] ||
            [key isEqualToString:@"displayText"] ||
            
            [key isEqualToString:@"f_flipText"] ||
            [key isEqualToString:@"textFile"] ||
            [key isEqualToString:@"f_publishImage"] ||
            [key isEqualToString:@"f_mirrorText"] ||
            
            [key isEqualToString:@"f_lockScrollOptions"] ||
            [key isEqualToString:@"f_scroll"] ||
            [key isEqualToString:@"f_centerTextv"] ||
            [key isEqualToString:@"scrollRate"] ||
            [key isEqualToString:@"f_scrollPause"] ||
            //[key isEqualToString:@"f_watchFile"] ||
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
            
            [key isEqualToString:@"f_typingEffect"] ||
            [key isEqualToString:@"f_typingEffectPause"] ||
            [key isEqualToString:@"typingRate"] ||
            [key isEqualToString:@"f_typingEffectLoop"] ||
            [key isEqualToString:@"f_typingEffectHumanize"] ||
            [key isEqualToString:@"outputResolution"] ||
            [key isEqualToString:@"f_transparentBackground"] ||
            
            
            [key isEqualToString:@"inputSource"] ||
            [key isEqualToString:@"textSliceFilename"] ||
            [key isEqualToString:@"textSliceFilenameWithoutPath"] ||
            
            [key isEqualToString:@"globalPosition_0"] ||
            [key isEqualToString:@"globalPosition_1"] ||
            [key isEqualToString:@"globalPosition_2"] ||
            [key isEqualToString:@"globalPosition_3"] ||
            [key isEqualToString:@"globalPosition_4"] ||
            [key isEqualToString:@"globalPosition_5"] ||
            [key isEqualToString:@"globalPosition_6"] ||
            [key isEqualToString:@"globalPosition_7"] ||
            [key isEqualToString:@"globalPosition_8"] ||
            [key isEqualToString:@"globalPosition_9"] ||
            [key isEqualToString:@"overlayTransparencyVal"] ||
            [key isEqualToString:@"f_correctOrigin"] ||
            
            [key isEqualToString:@"textAlignment"] ||
            [key isEqualToString:@"fontRequested"] ||
            [key isEqualToString:@"subtitler_settings_file"] ||
            
            
            [key isEqualToString:@"scrollDirection"]
            );
}

+(BOOL)loadSettingsFromPath:(NSString*)path{
    
    NSMutableDictionary *savedSettings = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    //NSLog(@"Loading settings file... %@ ",path);
    
    // Check to make sure this is a subtitler settings file
    if (![savedSettings objectForKey:@"subtitler_settings_file"]) {
        NSBeep();
        NSLog(@"Not a settings file!: %@",path);
        return false;
        
        // Ok, update the system with the settings
    }else{
        
        
        // Reset a few things
        [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"scrollRate"];
        [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:@"scrollPosition"];
        [[[FRAppCommon sharedFRAppCommon] fontViewController] stopTimer];
        
        // Some junk in here to support old settings files
        BOOL fontCheckPerformed=FALSE;
        for (NSString* key in savedSettings) {
            if([self allowedKey:key]){
                
                // Check if font is available
                if ([key isEqualToString:@"fontRequested"]){
                    fontCheckPerformed=TRUE;
                    NSArray *fonts = [[NSFontManager sharedFontManager] availableFontFamilies];
                    NSString* fontRequested = [savedSettings objectForKey:key];
                    if(![fonts containsObject:fontRequested]){
                        [AppController alertUser:@"Font not available!" info:[NSString stringWithFormat:@"'%@' will be replaced with system font.",fontRequested]];
                    }
                }
                
                
                [[NSUserDefaults standardUserDefaults] setObject:[savedSettings objectForKey:key] forKey:key];
            }
        }
        
        if(!fontCheckPerformed){
            [AppController alertUser:@"Warning!" info:[NSString stringWithFormat:@"You have loaded an older settings file.\n I can't promise it will work correctly."]];
        }
        
        return true;
        
    }
    
}


@end
