//
//  ACSDCursor.h
//  ACSDraw
//
//  Created by Alan Smith on Sun Jan 20 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSCursor(ACSDCursor)

+(NSCursor*)whiteArrowCursor;
+(NSCursor*)whiteArrowPlusCursor;
+(NSCursor*)arrowPlusCursor;
+(NSCursor*)closehairsCursor;
+(NSCursor*)leftRightCursor;
+(NSCursor*)magMinusCursor;
+(NSCursor*)magPlusCursor;
+(NSCursor*)upDownCursor;
+(NSCursor*)topLeftCursor;
+(NSCursor*)topRightCursor;
+(NSCursor*)cursorForKnob:(int)knob;
+(NSCursor*)splitPlusCursor;
+(NSCursor*)splitCursor;
+(NSCursor*)splitCursorPoint;
+(NSCursor*)chainCursor;
+(NSCursor*)rotateCrossCursor;
+(NSCursor*)rotateCursor;


@end
