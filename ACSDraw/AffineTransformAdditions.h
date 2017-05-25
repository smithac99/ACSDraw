//
//  AffineTransformAdditions.h
//  ACSDraw
//
//  Created by alan on 27/03/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSAffineTransform(AffineTransformAdditions)

+(NSAffineTransform*)transformWithRotationByDegrees:(float)deg;
+(NSAffineTransform*)transformWithTranslateXBy:(float)x yBy:(float)y;
+(NSAffineTransform*)transformWithScaleXBy:(float)x yBy:(float)y;
+(NSAffineTransform*)transformWithScaleBy:(float)f;

-(NSRect)transformRect:(NSRect)r;

@end
