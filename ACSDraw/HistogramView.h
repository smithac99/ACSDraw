//
//  HistogramView.h
//  ACSDraw
//
//  Created by Alan Smith on 06/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface HistogramView : NSView
{
	float *histogramData;
}

-(void)setHistogramData:(float*)hd;

@end
