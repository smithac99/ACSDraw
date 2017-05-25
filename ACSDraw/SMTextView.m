//
//  SMTextView.m
//  SoundManage
//
//  Created by Alan on 18/02/2013.
//  Copyright (c) 2013 Eurotalk. All rights reserved.
//

#import "SMTextView.h"
#import "ACSDTableView.h"

@implementation SMTextView

-(void)moveDown:(id)sender
{
	[self.tableView editNextRow];
}

-(void)moveUp:(id)sender
{
	[self.tableView editPrevRow];
}

-(void)insertTab:(id)sender
{
	[self.tableView editNextColumn];
}

-(void)insertBacktab:(id)sender
{
	[self.tableView editPrevColumn];
}

-(void)insertNewline:(id)sender
{
	[[self window]makeFirstResponder:self.tableView];
}

-(void)performCancel:(id)sender
{
	[[self window]makeFirstResponder:self.tableView];
}

-(void)keyDown:(NSEvent *)theEvent
{
    unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    if (key == 27)
        [self performCancel:self];
    else
        [super keyDown:theEvent];
}

@end
