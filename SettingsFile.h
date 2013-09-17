//
//  SettingsFile.h
//  Textify
//
//  Created by Andrew on 9/14/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SettingsFile : NSObject{}

@property NSMutableDictionary* settings;
@property NSString* originalName;
@property NSString* name;
@property NSString* path;
@property BOOL isLocked;

+(BOOL)loadSettingsFromPath:(NSString*)path;
+(BOOL)allowedKey:(NSString*)key;
+(void)saveCurrentSettingsToPath:(NSString*)fullFilePath withDisplayName:(NSString*)displayName;
+(void)refreshSettingsSidebarWithArrayController:(NSArrayController*)ac;
+(void)deleteSettingsFile:(NSString*)fullPath;

@end
