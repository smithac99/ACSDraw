//
//  BackingView.mm
//  ACSDraw
//
//  Created by alan on 10/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BackingView.h"
#import "ACSDPrefsController.h"


@implementation BackingView

@synthesize backingColour;

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    self.backingColour = nil;
}
-(void)awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backingColourChanged:)
												 name:ACSDBackgroundColourChange object:[ACSDPrefsController sharedACSDPrefsController:nil]];
	[self setBackingColour:[[ACSDPrefsController sharedACSDPrefsController:nil]backgroundColour]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backingTypeChanged:)
												 name:ACSDBackgroundTypeChange object:[ACSDPrefsController sharedACSDPrefsController:nil]];
	backingType = [[ACSDPrefsController sharedACSDPrefsController:nil]backgroundType];
}

#define BLOCK_SIZE 64

#define IS_ODD(a) (a&1)?YES:NO

- (void)drawBacking:(NSRect)dirtyRect
{
	if (backingType == BACKGROUND_DRAW_CHECKERS)
	{
		NSColor *white = [NSColor whiteColor];
		NSColor *lightBlue = [NSColor colorWithCalibratedRed:0.8 green:0.8 blue:1.0 alpha:1.0];
		int minRow,maxRow,minColumn,maxColumn;
		minRow = ((int)NSMinY(dirtyRect))/ 64;
		minColumn = ((int)NSMinX(dirtyRect))/ 64;
		maxRow = ((int)NSMaxY(dirtyRect))/ 64;
		maxColumn = ((int)NSMaxX(dirtyRect))/ 64;
		NSRect r = NSMakeRect(0.0,0.0,64.0,64.0);
		for (int j = minRow;j <= maxRow;j++)
		{
			float y = j * 64;
			for (int i = minColumn;i <= maxColumn;i++)
			{
				float x = i * 64;
				NSColor *col;
				if (IS_ODD(i+j))
					col = white;
				else
					col = lightBlue;
				[col set];
				r.origin = NSMakePoint(x,y);
				NSRectFill(r);
			}
		}
	}
	else if (backingType == BACKGROUND_DRAW_COLOUR)
		
	{
		[backingColour set];
		NSRectFill(dirtyRect);
	}
	
}

- (void)drawRect:(NSRect)aRect
{
	[self drawBacking:aRect];
}

- (BOOL)isOpaque
{
	if (backingType == BACKGROUND_DRAW_CHECKERS)
		return YES;
	if (backingType == BACKGROUND_DRAW_COLOUR)
		return ([backingColour alphaComponent] == 1.0);
	return NO;
}

- (void)backingTypeChanged:(NSNotification *)notification
{
	backingType = [[ACSDPrefsController sharedACSDPrefsController:nil]backgroundType];
	[self setNeedsDisplay:YES];
}

- (void)backingColourChanged:(NSNotification *)notification
{
	[self setBackingColour:[[notification userInfo]objectForKey:@"col"]];
	[self setNeedsDisplay:YES];
}


@end
