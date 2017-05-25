//
//  AffineTransformAdditions.mm
//  ACSDraw
//
//  Created by alan on 27/03/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import "AffineTransformAdditions.h"


@implementation NSAffineTransform(AffineTransformAdditions)

+(NSAffineTransform*)transformWithRotationByDegrees:(float)deg
{
	NSAffineTransform *aff = [NSAffineTransform transform];
	[aff rotateByDegrees:deg];
	return aff;
}

+(NSAffineTransform*)transformWithTranslateXBy:(float)x yBy:(float)y
{
	NSAffineTransform *aff = [NSAffineTransform transform];
	[aff translateXBy:x yBy:y];
	return aff;
}

+(NSAffineTransform*)transformWithScaleXBy:(float)x yBy:(float)y
{
	NSAffineTransform *aff = [NSAffineTransform transform];
	[aff scaleXBy:x yBy:y];
	return aff;
}

+(NSAffineTransform*)transformWithScaleBy:(float)f
{
	NSAffineTransform *aff = [NSAffineTransform transform];
	[aff scaleBy:f];
	return aff;
}

-(NSRect)transformRect:(NSRect)r
{
	NSRect outR = r;
	outR.origin = [self transformPoint:r.origin];
	outR.size = [self transformSize:r.size];
	return outR;
}



@end

