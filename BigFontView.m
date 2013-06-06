//
//  BigFontView.m
//  CyborgameSubtitler
//
//  Created by Andrew on 6/5/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import "BigFontView.h"

@implementation BigFontView



- (BOOL) acceptsFirstResponder{return YES;}
- (BOOL) resignFirstResponder{return YES;}
- (BOOL) becomeFirstResponder{return YES;}
- (BOOL) canBecomeKeyView{return YES;}



- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    [NSTimer scheduledTimerWithTimeInterval:(1.0/30) target:self selector:@selector(redraw) userInfo:nil repeats:YES];
    [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"f_scroll"];
    return self;
}

NSMutableString *scrollString;
NSTimer *scrollTimer;
bool f_scrolling = false;
- (void)redraw{
    

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"f_scroll"] && !f_scrolling){
        NSLog(@"Scrolling on");
        scrollTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/[[NSUserDefaults standardUserDefaults] floatForKey:@"scrollSpeed"] target:self selector:@selector(scrollText) userInfo:nil repeats:YES];
        f_scrolling=true;
    }
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"f_scroll"] && f_scrolling){
       NSLog(@"Scrolling off");
        [scrollTimer invalidate];
        f_scrolling=false;
    }
    
    [self setNeedsDisplay:YES];
}

-(void)scrollText{
    
    NSString *firstChar =[scrollString substringWithRange:NSMakeRange(0, 1)];
    NSString *restOfString = [scrollString substringWithRange:NSMakeRange(1, ([scrollString length]-1))];
    
    scrollString=[NSMutableString stringWithFormat:@"%@%@",restOfString,firstChar];
}

- (void)drawRect:(NSRect)dirtyRect {
    
    // Retrieve settings from UI
    NSColor *backgroundColor=(NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"colorBackground"]];
    NSFont  *fontToUse=(NSFont *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"fontSelected"]];
    if (!fontToUse){
        fontToUse=[NSFont fontWithName:@"Helvetica" size:20];
    }
    
    //Save it
    NSData *fontSelected = [NSArchiver archivedDataWithRootObject:fontToUse];
    [[NSUserDefaults standardUserDefaults] setValue:fontSelected forKey:@"fontSelected"];
    
    
    NSColor *backgroundColor2=(NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"colorBackground2"]];
    NSColor *fontColor=(NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"colorFont"]];
    NSColor *fontColorShadow=(NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"colorFontShadow"]];
    
    NSString *displayString = [[NSUserDefaults standardUserDefaults] valueForKey:@"displayText"];

    if (f_scrolling){
        displayString=scrollString;
    }else{
        scrollString = [NSMutableString stringWithFormat:@"     %@     ",displayString];
    }
       
    // Build the gradient
	NSGradient *backgroundGradient = [[NSGradient alloc] initWithStartingColor:backgroundColor endingColor:backgroundColor2];
	[backgroundGradient drawInRect:dirtyRect angle:[[NSUserDefaults standardUserDefaults] integerForKey:@"gradientAngle"]];
    
    
    // Set up the font
	NSMutableDictionary *drawStringAttributes = [[NSMutableDictionary alloc] init];
	[drawStringAttributes setValue:fontColor
                            forKey:NSForegroundColorAttributeName];
	[drawStringAttributes setObject:fontToUse forKey:NSFontAttributeName];
	
    
    [[[self window] graphicsContext] setShouldAntialias:YES]; 
    
    // Dropshadow if requested
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"f_drawShadow"]){
        NSShadow *stringShadow = [[NSShadow alloc] init];
        [stringShadow setShadowColor:fontColorShadow];
        NSSize shadowSize;
        shadowSize.width = 2;
        shadowSize.height = -2;
        [stringShadow setShadowOffset:shadowSize];
        [stringShadow setShadowBlurRadius:6];
        [drawStringAttributes setValue:stringShadow forKey:NSShadowAttributeName];
    }
    
    // Now draw the text
	NSSize stringSize = [displayString sizeWithAttributes:drawStringAttributes];
	NSPoint centerPoint;
	centerPoint.x = (dirtyRect.size.width / 2) - (stringSize.width / 2);
	centerPoint.y = dirtyRect.size.height / 2 - (stringSize.height / 2);
	[displayString drawAtPoint:centerPoint withAttributes:drawStringAttributes];
    
   
}





@end
