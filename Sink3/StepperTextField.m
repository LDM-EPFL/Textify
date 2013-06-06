#import "StepperTextField.h"

@implementation StepperTextField

// Just sets the field to @"1" on launch
-(void)awakeFromNib {
	//[self setStringValue:@"1"];
}

/* ---------------------------------------------------------------------------------------------------

We grab the numeric keypad keys pressed as a string and if there was 
only one, we see if that was the up or down arrow key.

We check to keep the field in bounds by keeping it always greater than 1
but less than the -maxValue defined by the NSStepper, setup in IB

----------------------------------------------------------------------------------------------------- */


- (void)keyDown:(NSEvent *)theEvent {
    NSLog(@"Well, down happened");
}

-(void)keyUp:(NSEvent *)theEvent {
    
    NSLog(@"Well, up happened");
	
	// Looking for array keys only here
	if ([theEvent modifierFlags] & NSNumericPadKeyMask) {
		NSString *theArrow = [theEvent charactersIgnoringModifiers];

		if ( [theArrow length] == 0 ) {
			return;            // reject dead keys
		}
	
		if ( [theArrow length] == 1 ) {
			
			// Grab just the key pressed
			unichar keyChar = [theArrow characterAtIndex:0];
		
			// If it was an up arrow key
			if ( keyChar == NSUpArrowFunctionKey ) {
				
				// Setup the loop, wrapping action between bounds
				if ( [[self stringValue] doubleValue] < [stepper maxValue] ) {
					NSNumber *value = [NSNumber numberWithInt:[[self stringValue] intValue] + 1];
					[self setStringValue:[value stringValue]];
				} else if ( [[self stringValue] doubleValue] >= [stepper maxValue] ) {
					[self setStringValue:@"1"];
				}
			}
			
			// if it was a down arrow key
			else if ( keyChar == NSDownArrowFunctionKey ) {

				// Setup loop, wrapping action between bounds 
				if ( [[self stringValue] doubleValue] > 1 ) {
					NSNumber *value = [NSNumber numberWithInt:[[self stringValue] intValue] - 1];
					[self setStringValue:[value stringValue]];
				} else if ( [[self stringValue] doubleValue] <= 1 ) {
					[self setStringValue:[NSString stringWithFormat:@"%.0lf", [stepper maxValue]]];
				}
			}
		}
	}
}

@end
