//
//  KeyHandlerView.h
//  CyborgameSubtitler
//
//  Created by Andrew on 6/5/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface KeyHandlerView : NSView{
     NSWindow *mainWindow;
    __unsafe_unretained NSPanel *_fullScreenView;
    BOOL isAnimating;
}
@property (unsafe_unretained) IBOutlet NSPanel *fullScreenView;
@end
