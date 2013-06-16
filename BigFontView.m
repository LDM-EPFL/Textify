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



- (id)initWithFrame:(NSRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    NSTimer *drawTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0/30) target:self selector:@selector(redraw) userInfo:nil repeats:YES];
    
    [[NSRunLoop currentRunLoop] addTimer:drawTimer forMode:NSEventTrackingRunLoopMode];
    
    [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"f_scroll"];
    return self;
}

NSMutableString *scrollString;
NSTimer *scrollTimer;
int scrollScalingFactor;
bool f_scrolling = false;
- (void)redraw{
    

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"f_scroll"] && !f_scrolling){
        NSLog(@"Scrolling on");
        [self updateScrollTimer];
    }
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"f_scroll"] && f_scrolling){
       NSLog(@"Scrolling off");
        [scrollTimer invalidate];
        f_scrolling=false;
    }
    
    [self setNeedsDisplay:YES];
}


// Actually scroll the text
-(void)scrollText{
    
    // If direction changes
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"f_scrollReverse"]){
        [self scrollText_1];
    }else{
        [self scrollText_2];
    }
    
    // If speed changes
    int new = [[NSUserDefaults standardUserDefaults] floatForKey:@"scrollSpeed"];
    if (scrollScalingFactor != [[NSUserDefaults standardUserDefaults] integerForKey:@"scrollSpeed"]){
        [self updateScrollTimer];
    }
    
    
}

// Timer to update scrolling, also checks for changes
-(void)updateScrollTimer{
    [scrollTimer invalidate];
    scrollScalingFactor=[[NSUserDefaults standardUserDefaults] floatForKey:@"scrollSpeed"];
    scrollTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/scrollScalingFactor target:self selector:@selector(scrollText) userInfo:nil repeats:YES];
    f_scrolling=true;
}

// Scroll one way
-(void)scrollText_1{
    
    NSString *firstChar =[scrollString substringWithRange:NSMakeRange(0, 1)];
    NSString *restOfString = [scrollString substringWithRange:NSMakeRange(1, ([scrollString length]-1))];
    
    scrollString=[NSMutableString stringWithFormat:@"%@%@",restOfString,firstChar];
}

// Scroll the other way
-(void)scrollText_2{
    
    NSString *lastChar =[scrollString substringWithRange:NSMakeRange(([scrollString length]-1), 1)];
    NSString *restOfString = [scrollString substringWithRange:NSMakeRange(0, ([scrollString length]-1))];
    
    scrollString=[NSMutableString stringWithFormat:@"%@%@",lastChar,restOfString];
}


- (void)drawRect:(NSRect)dirtyRect {
    
    // Defaults
    NSFont  *fontToUse=[NSFont fontWithName:@"Helvetica" size:20];
    NSColor *backgroundColor=[NSColor whiteColor];
    NSColor *backgroundColor2=[NSColor blackColor];
    NSColor *fontColor=[NSColor blackColor];
    NSColor *fontColorShadow=[NSColor blackColor];
    
    // Try and get these from the userprefs (will fail if not initialized before)
    @try {
        fontToUse=(NSFont *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"fontSelected"]];
    }@catch (NSException *exception) {
        NSLog(@"Cannot load font, using default...");
        [[NSUserDefaults standardUserDefaults] setValue:fontToUse forKey:@"fontSelected"];
    }

    @try {
        backgroundColor=(NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"colorBackground"]];
    }@catch (NSException *exception) {
        NSLog(@"Cannot load bgcolor, using default...");
    }
    
    @try {
        backgroundColor2=(NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"colorBackground2"]];
    }@catch (NSException *exception) {
        NSLog(@"Cannot load bgcolor2, using default...");
    }

    @try {
        fontColor=(NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"colorFont"]];
    }@catch (NSException *exception) {
        NSLog(@"Cannot load fontcolor, using default...");
    }
    
    @try {
        fontColorShadow=(NSColor *)[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"colorFontShadow"]];
    }@catch (NSException *exception) {
        NSLog(@"Cannot load shadowcolor, using default...");
    }



    //Save it
    NSData *fontSelected = [NSArchiver archivedDataWithRootObject:fontToUse];
    [[NSUserDefaults standardUserDefaults] setValue:fontSelected forKey:@"fontSelected"];
    NSString *displayString = [[NSUserDefaults standardUserDefaults] valueForKey:@"displayText"];

    if (f_scrolling){
        displayString=scrollString;
    }else{
        scrollString = [NSMutableString stringWithFormat:@"       %@       ",displayString];
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

    
    
    //centerPoint.x = (dirtyRect.size.width / 2) - (stringSize.width / 2);
	//centerPoint.y = dirtyRect.size.height / 2 - (stringSize.height / 2);
    centerPoint.x=0;
    centerPoint.y=0;

    
    
        /* Draw a circle for no reason
    NSBezierPath* circlePath = [NSBezierPath bezierPath];
    [circlePath appendBezierPathWithOvalInRect: dirtyRect];
    [circlePath setLineWidth:5];
    [circlePath stroke];
    */
    
    // Begin with identity
    NSAffineTransform* t = [NSAffineTransform transform];
    
    //Center text
    [t translateXBy:(dirtyRect.size.width / 2) - (stringSize.width / 2) yBy:dirtyRect.size.height / 2 - (stringSize.height / 2)];
    
    //Flip
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"f_flipText"]){
        [t scaleXBy:1.0 yBy:-1.0];
        // To keep centered slide text up by lineheight
        [t translateXBy:1.0 yBy:-(stringSize.height)];
        [t translateXBy:1.0 yBy:1.0];
    }
    
    //Mirror
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"f_mirrorText"]){
        [t scaleXBy:-1.0 yBy:1.0];
        // To keep centered slide right up by half linewidth
        [t translateXBy:-stringSize.width yBy:1.0];
        [t translateXBy:-.09 yBy:-.9];
    }
    
    

	
    //Apply transformation to view
    [t concat];
    
    [displayString drawAtPoint:centerPoint withAttributes:drawStringAttributes];
    
    


    
   
    
    
    [NSGraphicsContext restoreGraphicsState];
    
 
}

- (BOOL)isFlipped{return NO;}




@end
