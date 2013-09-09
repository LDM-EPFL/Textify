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

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
       
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}

-(void)awakeFromNib{
    [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
}

-(BOOL)acceptsFirstResponder{return YES;}
-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {return NSDragOperationCopy;}
-(BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {return YES;}


-(BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    // Check extension... If this is a settings file, load the settings
    NSPasteboard* pbrd = [sender draggingPasteboard];
    NSArray *draggedFilePaths = [pbrd propertyListForType:NSFilenamesPboardType];
    NSString *path=draggedFilePaths[0];
    NSArray *parsedPath = [path componentsSeparatedByString:@"/"];
    NSArray *parsedFilename = [parsedPath[[parsedPath count]-1] componentsSeparatedByString:@"."];
    NSString* extension = parsedFilename[[parsedFilename count]-1];
    
    [[NSUserDefaults standardUserDefaults] setValue:path forKey:@"textSliceFilename"];
    [[NSUserDefaults standardUserDefaults] setValue:[[[NSUserDefaults standardUserDefaults] valueForKey:@"textSliceFilename"] lastPathComponent] forKey:@"textSliceFilenameWithoutPath"];
    
    // Is this a txt file?
    if ([extension isEqualToString:@"txt"]){
      
        [AppDelegate loadSliceFileFromPath:path];

        
        
         // Select textSlice mode
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"inputSource"];
        
        return TRUE;
    }

    return FALSE;

}


@end
