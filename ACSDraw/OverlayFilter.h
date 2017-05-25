//
//  OverlayFilter.h
//  ACSDraw
//
//  Created by alan on 05/07/14.
//
//

#import <QuartzCore/QuartzCore.h>

@interface OverlayFilter : CIFilter
{
	CIImage      *inputImage;
	CIColor		*colour;
}

@end
