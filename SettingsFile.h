//
//  SettingsFile.h
//  Textify
//
//  Created by Andrew on 9/14/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SettingsFile : NSObject{}

@property NSString* name;
@property NSString* path;
+(BOOL)loadSettingsFromPath:(NSString*)path;
+(BOOL)allowedKey:(NSString*)key;

@end
