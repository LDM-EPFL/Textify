//
//  MainView.h
//  CyborgameSubtitler
//
//  Created by Andrew on 7/4/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BigFontView.h"

@interface MainView : NSView <NSDraggingDestination>{
     BigFontView *_windowedTextView;
}

@property (weak) IBOutlet NSImageView *pubImage;


@property(strong) IBOutlet BigFontView *windowedTextView;
@property(strong) IBOutlet NSWindow *windowedText;

@end
