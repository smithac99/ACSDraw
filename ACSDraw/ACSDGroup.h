//
//  ACSDGroup.h
//  ACSDraw
//
//  Created by alan on Mon Feb 23 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "ACSDGraphic.h"

enum
{
    COLOUR_MODE_SUB,
    COLOUR_MODE_OVERLAY
};
@interface ACSDGroup : ACSDGraphic
   {
	NSMutableArray *graphics;
   }

@property int colourMode;

-(id)initWithName:(NSString*)n graphics:(NSArray*)gArray layer:(ACSDLayer*)l;
-(void)setGraphics:(NSArray*)g;
-(void)adjustGraphicsBoundsOffset:(NSPoint)offset;
- (NSArray*)originalObjects;
- (NSArray*)graphics;
-(NSArray*)removeGraphics;
-(void)fixTextBoxLinks;

@end
