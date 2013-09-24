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
#import "AppDelegate.h"

@implementation SettingsFile

// UGH! 
+(BOOL)allowedKey:(NSString*)key{
    return (
            
            [key isEqualToString:@"externalFilename"] ||
            [key isEqualToString:@"displayName"] ||
            
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
            //[key isEqualToString:@"f_transparentBackground"] ||
            
            
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

+(void)saveCurrentSettingsToPath:(NSString*)fullFilePath withDisplayName:(NSString*)displayName{
    
    // Save some stuff with the settings
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"subtitler_settings_file"];
    [[NSUserDefaults standardUserDefaults] setValue:[(NSFont *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"fontSelected"]] familyName] forKey:@"fontRequested"];
    
    // Synch
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSDictionary *settings=[[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    
    // Displayname
    if(!displayName){
        
        int maxIndex = (int)[[[NSUserDefaults standardUserDefaults] valueForKey:@"displayText"] length];
        maxIndex=MIN(maxIndex,20);
        displayName=[NSString stringWithFormat:@"NEW:%@",[[[NSUserDefaults standardUserDefaults] valueForKey:@"displayText" ] substringToIndex:maxIndex]];
        
        [displayName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
         
    }
    [settings setValue:displayName forKey:@"displayName"];
    

    // Clean the settings
    NSMutableDictionary* cleanSettings=[[NSMutableDictionary alloc] init];
    for (NSString* key in settings) {
        if([SettingsFile allowedKey:key]){
            [cleanSettings setObject:[settings objectForKey:key] forKey:key];
        }
    }
    
    // Write them to disk
    [cleanSettings writeToFile:fullFilePath atomically:YES];
    
    // Update and refresh UI
    [[NSUserDefaults standardUserDefaults] setValue:[fullFilePath stringByDeletingLastPathComponent] forKey:@"settingsDirectory"];
    [(AppDelegate *)[[NSApplication sharedApplication] delegate] refreshSettingsDir:self];
}

+(void)refreshSettingsSidebarWithArrayController:(NSArrayController*)ac{
    
    //Note the selection index
    int selectionIndex = (int)[ac selectionIndex];
    
    // Clear the array
    NSRange range = NSMakeRange(0, [[[(AppDelegate *)[[NSApplication sharedApplication] delegate] settingsFiles] arrangedObjects] count]);
    [[(AppDelegate *)[[NSApplication sharedApplication] delegate] settingsFiles] removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];
    
    // Check extension...
    NSString *path=[[NSUserDefaults standardUserDefaults] valueForKey:@"settingsDirectory"];
    NSArray *directory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    NSArray *fileList = [directory filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.settings'"]];
    
    // Grab name from file and make sure it really is a settings file
    
    
    // Is this a settings file?
    for(NSString* filename in fileList){
        NSString* fullPath = [NSString stringWithFormat:@"%@/%@",path,filename];
        
        NSMutableDictionary *savedSettings = [[NSMutableDictionary alloc] initWithContentsOfFile:fullPath];
        // Check to make sure this is a subtitler settings file
        if ([savedSettings objectForKey:@"subtitler_settings_file"]) {
            
            SettingsFile* newFile = [[SettingsFile alloc] init];
            newFile.settings=savedSettings;
            if ([savedSettings objectForKey:@"displayName"]) {
                newFile.name=[savedSettings valueForKey:@"displayName"];
            }else{
                newFile.name=[filename stringByDeletingPathExtension];
            }
            newFile.originalName=newFile.name;
            newFile.path=fullPath;
            [ac addObject:newFile];
        }else{
            NSLog(@"Skip: %@: ",filename);
        }
        
    }
    
    // Restore selection index
    if([[ac arrangedObjects] count] >= selectionIndex){
        [ac setSelectionIndex:selectionIndex];
    }else{
        [ac setSelectionIndex:0];
    }

}

+(void)deleteSettingsFile:(NSString*)fullPath{
    [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
    [(AppDelegate *)[[NSApplication sharedApplication] delegate] refreshSettingsDir:self];
}
@end
