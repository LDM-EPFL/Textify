//
//  StepperTextField.h
//  Viewer
//
//  Created by Matt Brewer on 1/1/07.
//  Copyright (c) 2006 Matt Brewer All rights reserved.
//  http://www.macfanatic.net
//
//  I needed an easy way to add keyboard actions so that a user could use the
//  up and down arrows to increment/decrement the field itself, in conjunction with
//  bounds specified in the NSStepper that I used for the mouse events.
//
//  Will need to eventually add so that holding keys down for a length of time autorepeat
//


#import <Cocoa/Cocoa.h>

@interface StepperTextField : NSTextField{
	IBOutlet NSStepper *stepper;
}

// you can only override keydown in window or view controllers 
-(void)keyUp:(NSEvent *)event;
-(void)keyDown:(NSEvent *)event;

@end
