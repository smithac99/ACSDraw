//
//  ACSDFieldEditor.m
//  ACSDraw
//
//  Created by alan on 02/12/14.
//
//

#import "ACSDFieldEditor.h"

@implementation ACSDFieldEditor

- (void)moveDown:(id)sender
{
	NSCell *cell = [(NSTextField*)[self delegate]cell];
	float n = [cell floatValue];
	float n2 = [cell intValue];
	if (n2 == n)
	{
		[cell setIntValue:n2 - 1];
	}
	else
		[cell setIntValue:n2];
}

- (void)moveUp:(id)sender
{
	NSCell *cell = [(NSTextField*)[self delegate]cell];
	float n = [cell floatValue];
	float n2 = ceilf([cell floatValue]);
	if (n2 == n)
	{
		[cell setIntValue:n2 + 1];
	}
	else
		[cell setIntValue:n2];
}
@end
