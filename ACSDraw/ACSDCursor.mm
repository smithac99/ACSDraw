//
//  ACSDCursor.mm
//  ACSDraw
//
//  Created by Alan Smith on Sun Jan 20 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ACSDCursor.h"
#import "ACSDGraphic.h"


@implementation NSCursor(ACSDCursor)

+(NSCursor*)redArrowCursor
{
	static NSCursor *cursor = nil;
	if (!cursor)
	{
		NSImage *image = [NSImage imageNamed:@"redarrowcs"];
		cursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint(9.0,5.0)];
	}
	return cursor;
}

+(NSCursor*)whiteArrowCursor
{
	static NSCursor *cursor = nil;
	if (!cursor)
	{
		NSImage *image = [NSImage imageNamed:@"whitearrowcs"];
		cursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint(9.0,5.0)];
	}
	return cursor;
}

+(NSCursor*)whiteArrowPlusCursor
{
	static NSCursor *cursor = nil;
	if (!cursor)
	{
		NSImage *image = [NSImage imageNamed:@"whitearrowpluscs"];
		cursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint(9.0,5.0)];
	}
	return cursor;
}

+(NSCursor*)arrowPlusCursor
{
	static NSCursor *cursor = nil;
	if (!cursor)
	{
		NSImage *image = [NSImage imageNamed:@"arrowplus"];
		cursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint(1.0,1.0)];
	}
	return cursor;
}

+(NSCursor*)splitPlusCursor
{
	static NSCursor *cursor = nil;
	if (!cursor)
	{
		NSImage *image = [NSImage imageNamed:@"splitcsplus"];
		cursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint(7.0,7.0)];
	}
	return cursor;
}

+(NSCursor*)splitCursor
{
    static NSCursor *cursor = nil;
    if (!cursor)
	{
        NSImage *image = [NSImage imageNamed:@"splitpointcs"];
        cursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint(7.0,4.0)];
	}
	return cursor;
}

+(NSCursor*)splitCursorPoint
{
    static NSCursor *cursor = nil;
    if (!cursor)
	{
        NSImage *image = [NSImage imageNamed:@"splitpointcsr"];
        cursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint(7.0,4.0)];
	}
	return cursor;
}

+(NSCursor*)closehairsCursor
{
	static NSCursor *cursor = nil;
	if (!cursor)
	{
		NSImage *image = [NSImage imageNamed:@"closehairs"];
		NSSize imageSize = [image size];
		cursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint((imageSize.width / 2.0), (imageSize.height / 2.0))];
	}
	return cursor;
}

+(NSCursor*)leftRightCursor
{
	static NSCursor *cursor = nil;
	if (!cursor)
	{
		NSImage *image = [NSImage imageNamed:@"leftright"];
		NSSize imageSize = [image size];
		cursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint((imageSize.width / 2.0), (imageSize.height / 2.0))];
	}
	return cursor;
}

+(NSCursor*)magPlusCursor
{
	static NSCursor *cursor = nil;
	if (!cursor)
	{
		NSImage *image = [NSImage imageNamed:@"magplus"];
		cursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint(5.0,5.0)];
	}
	return cursor;
}

+(NSCursor*)magMinusCursor
{
	static NSCursor *cursor = nil;
	if (!cursor)
	{
		NSImage *image = [NSImage imageNamed:@"magminus"];
		cursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint(5.0,5.0)];
	}
	return cursor;
}

+(NSCursor*)upDownCursor
{
	static NSCursor *cursor = nil;
	if (!cursor)
	{
		NSImage *image = [NSImage imageNamed:@"updown"];
		NSSize imageSize = [image size];
		cursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint((imageSize.width / 2.0), (imageSize.height / 2.0))];
	}
	return cursor;
}

+(NSCursor*)topLeftCursor
{
	static NSCursor *cursor = nil;
	if (!cursor)
	{
		NSImage *image = [NSImage imageNamed:@"oblique2"];
		NSSize imageSize = [image size];
		cursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint((imageSize.width / 2.0), (imageSize.height / 2.0))];
	}
	return cursor;
}

+(NSCursor*)topRightCursor
{
	static NSCursor *cursor = nil;
	if (!cursor)
	{
		NSImage *image = [NSImage imageNamed:@"oblique"];
		NSSize imageSize = [image size];
		cursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint((imageSize.width / 2.0), (imageSize.height / 2.0))];
	}
	return cursor;
}

+(NSCursor*)chainCursor
{
	static NSCursor *cursor = nil;
	if (!cursor)
	{
		NSImage *image = [NSImage imageNamed:@"chain"];
		NSSize imageSize = [image size];
		cursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint((imageSize.width / 2.0), (imageSize.height / 2.0))];
	}
	return cursor;
}

+(NSCursor*)rotateCrossCursor
{
	static NSCursor *cursor = nil;
	if (!cursor)
	{
		NSImage *image = [NSImage imageNamed:@"celticcross"];
		NSSize imageSize = [image size];
		cursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint((imageSize.width / 2.0), (imageSize.height / 2.0))];
	}
	return cursor;
}

+(NSCursor*)rotateCursor
{
	static NSCursor *cursor = nil;
	if (!cursor)
	{
		NSImage *image = [NSImage imageNamed:@"rotatecursor"];
		NSSize imageSize = [image size];
		cursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint((imageSize.width / 2.0), (imageSize.height / 2.0))];
	}
	return cursor;
}

+(NSCursor*)cursorForKnob:(int)knob
{
	switch(knob)
	{
		case UpperLeftKnob:
		case LowerRightKnob:
			return [NSCursor topRightCursor];
		case UpperRightKnob:
		case LowerLeftKnob:
			return [NSCursor topLeftCursor];
		case UpperMiddleKnob:
		case LowerMiddleKnob:
			return [NSCursor upDownCursor];
		case MiddleLeftKnob:
		case MiddleRightKnob:
			return [NSCursor leftRightCursor];
	}
	return [NSCursor leftRightCursor];
}


@end
