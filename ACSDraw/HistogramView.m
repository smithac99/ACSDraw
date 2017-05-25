//
//  HistogramView.m
//  ACSDraw
//
//  Created by Alan Smith on 06/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "HistogramView.h"
#import <Accelerate/Accelerate.h>

@implementation HistogramView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor whiteColor]set];
	NSRectFill(dirtyRect);
	if (histogramData)
	{
		[[NSColor blackColor]set];
		float maxH;
		vDSP_maxv(histogramData, 1, &maxH, 256);
		if (maxH > 0.0)
		{
			float h = [self bounds].size.height;
			float multiplier = h / maxH;
			for (int i = 0;i < 256;i++)
			{
				float y = histogramData[i] * multiplier;
				float x = i + 0.5;
				[NSBezierPath strokeLineFromPoint:NSMakePoint(x, 0) toPoint:NSMakePoint(x, y)];
			}
		}
	}
}

-(void)setHistogramData:(float*)hd
{
	histogramData = hd;
}
@end
