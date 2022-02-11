//
//  SVGTransform.h
//  Vectorius
//
//  Created by Alan Smith on 07/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

@import AppKit;

#define RADIANS(x) ((x)/(360.0/(2.0 * M_PI)))

@interface SVGTransform : NSObject

@property NSAffineTransform *nativeTransform;
@property NSString *function;
@property NSArray<NSNumber*> *numbers;

-(instancetype)initWithFunction:(NSString*)function numbers:(NSArray*)numbers;
+(NSArray*)transformsForInputString:(NSString*)inputString;
-(void)calculateTransform;
-(void)apply;

@end
