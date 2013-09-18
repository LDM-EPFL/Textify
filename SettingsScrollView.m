//
//  SettingsScrollView.m
//  Textify
//
//  Created by Andrew on 9/18/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import "SettingsScrollView.h"
#import "AppDelegate.h"
#import "SettingsFile.h"
@implementation SettingsScrollView

-(void)awakeFromNib{
    [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    [super awakeFromNib];
}
-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {return NSDragOperationCopy;}
-(BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {return YES;}
-(BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    // Check extension...
    NSPasteboard* pbrd = [sender draggingPasteboard];
    NSArray *draggedFilePaths = [pbrd propertyListForType:NSFilenamesPboardType];
    NSString *path=draggedFilePaths[0];
    
    
    BOOL isDir;
    if([[NSFileManager defaultManager]
        fileExistsAtPath:path isDirectory:&isDir] && !isDir){
        path=[path stringByDeletingLastPathComponent];
    }
    
    NSLog(path);
    
    [[NSUserDefaults standardUserDefaults] setValue:path forKey:@"settingsDirectory"];
    
    [SettingsFile refreshSettingsSidebarWithArrayController:[(AppDelegate *)[[NSApplication sharedApplication] delegate] settingsFiles]];
    
    return YES;
}


@end
