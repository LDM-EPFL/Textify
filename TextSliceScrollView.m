//
//  TextSliceCollectionView.m
//  Textify
//
//  Created by Andrew on 9/7/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import "TextSliceScrollView.h"
#import "TextSlice.h"
#import "AppDelegate.h"

@implementation TextSliceScrollView

-(void)awakeFromNib{
    [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    [super awakeFromNib];
}

-(BOOL)acceptsFirstResponder{return YES;}
-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {return NSDragOperationCopy;}
-(BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {return YES;}


-(BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    // Check extension... 
    NSPasteboard* pbrd = [sender draggingPasteboard];
    NSArray *draggedFilePaths = [pbrd propertyListForType:NSFilenamesPboardType];
    NSString *path=draggedFilePaths[0];
    NSArray *parsedPath = [path componentsSeparatedByString:@"/"];
    NSArray *parsedFilename = [parsedPath[[parsedPath count]-1] componentsSeparatedByString:@"."];
    NSString* extension = parsedFilename[[parsedFilename count]-1];
    
    [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"textSliceFilename"];
    [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"textSliceFilenameWithoutPath"];
    
    // Is this a txt file?
    if ([extension isEqualToString:@"txt"]){
        
        [[NSUserDefaults standardUserDefaults] setValue:path forKey:@"textSliceFilename"];
        [[NSUserDefaults standardUserDefaults] setValue:[[[NSUserDefaults standardUserDefaults] valueForKey:@"textSliceFilename"] lastPathComponent] forKey:@"textSliceFilenameWithoutPath"];

        [(AppDelegate *)[[NSApplication sharedApplication] delegate] setIsLoading:TRUE];

        // Clear the array
        NSRange range = NSMakeRange(0, [[[(AppDelegate *)[[NSApplication sharedApplication] delegate] slicedText] arrangedObjects] count]);
        [[(AppDelegate *)[[NSApplication sharedApplication] delegate] slicedText] removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];
        
        [(AppDelegate *)[[NSApplication sharedApplication] delegate] loadSliceFileFromPath:path];
        
        
         // Select textSlice mode
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"inputSource"];
        
        return TRUE;
    }

    return FALSE;

}


@end
