//
//  SVGTransform.m
//  Vectorius
//
//  Created by Alan Smith on 07/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVGTransform.h"

static NSArray *componentsOfTransformString(NSString *inputString)
{
    static NSMutableCharacterSet *skippers = nil;
    if (skippers == nil)
    {
        skippers = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
        [skippers addCharactersInString:@","];
    }
    NSMutableArray *outputs = [NSMutableArray array];
    NSScanner *scanner = [NSScanner scannerWithString:inputString];
    [scanner setCharactersToBeSkipped:skippers];
    BOOL ok = YES;
    while (![scanner isAtEnd] && ok)
    {
        NSString *opString = nil;
        if ((ok = [scanner scanUpToString:@"(" intoString:&opString]))
        {
            if ((ok = [scanner scanString:@"(" intoString:NULL]))
            {
                NSString *floatString = nil;
                [scanner scanUpToString:@")" intoString:&floatString];
                [scanner scanString:@")" intoString:NULL];
                NSMutableArray<NSNumber*>*floats = [NSMutableArray array];
                NSScanner *floatScanner = [NSScanner scannerWithString:floatString];
                [floatScanner setCharactersToBeSkipped:skippers];

                BOOL fok = YES;
                while (![floatScanner isAtEnd] && fok)
                {
                    float f;
                    if ((fok = [floatScanner scanFloat:&f]))
                        [floats addObject:@(f)];
                }
                if (opString)
                    [outputs addObject:@[opString,floats]];
            }
        }

    }
    return outputs;
}
@implementation SVGTransform

-(instancetype)initWithFunction:(NSString*)function numbers:(NSArray*)numbers
{
    if (self = [super init])
    {
        self.function = function;
        self.numbers = numbers;
    }
    return self;

}
+(NSArray*)transformsForInputString:(NSString*)inputString
{
    NSArray *components = componentsOfTransformString(inputString);
    NSMutableArray *trs = [NSMutableArray array];
    for (NSArray* component in components)
    {
        SVGTransform *svgt = [[SVGTransform alloc]initWithFunction:component[0] numbers:component[1]];
        [trs addObject:svgt];
    }
    return trs;
}

-(void)calculateTransform
{
    self.nativeTransform = [NSAffineTransform transform];
    if ([self.function isEqualToString:@"translate"])
    {
        float dx = 0.0,dy = 0.0;
        if ([self.numbers count] > 0)
            dx = [_numbers[0] floatValue];
        if ([self.numbers count] > 1)
            dy = [self.numbers[1] floatValue];
        [self.nativeTransform translateXBy:dx yBy:dy];
    }
    else if ([self.function isEqualToString:@"scale"])
    {
        float sx = 1.0;
        if ([self.numbers count] > 0)
            sx = [self.numbers[0] floatValue];
        float sy = sx;
        if ([self.numbers count] > 1)
            sy = [self.numbers[1] floatValue];
        [self.nativeTransform scaleXBy:sx yBy:sy];
    }
    else if ([self.function isEqualToString:@"rotate"])
    {
        float ang = 0.0;
        if ([self.numbers count] > 0)
            ang = [self.numbers[0] floatValue];
        float cx = 0.0,cy = 0.0;
        if ([self.numbers count] > 1)
            cx = [self.numbers[1] floatValue];
        if ([self.numbers count] > 2)
            cy = [self.numbers[2] floatValue];
        if (cx != 0.0 || cy != 0.0)
            [self.nativeTransform translateXBy:cx yBy:cy];
        [self.nativeTransform rotateByDegrees:ang];
        if (cx != 0.0 || cy != 0.0)
            [self.nativeTransform translateXBy:-cx yBy:-cy];
    }
    else if ([self.function isEqualToString:@"matrix"])
    {
        if ([self.numbers count] >= 6)
        {
            NSAffineTransformStruct ts;
            /*ts.m11 = [self.numbers[0] floatValue];
            ts.m21 = [self.numbers[1] floatValue];
            ts.m12 = [self.numbers[2] floatValue];
            ts.m22 = [self.numbers[3] floatValue];
            ts.tX  = [self.numbers[4] floatValue];
            ts.tY  = [self.numbers[5] floatValue];*/
            ts.m11 = [self.numbers[0] floatValue];
            ts.m12 = [self.numbers[1] floatValue];
            ts.m21 = [self.numbers[2] floatValue];
            ts.m22 = [self.numbers[3] floatValue];
            ts.tX  = [self.numbers[4] floatValue];
            ts.tY  = [self.numbers[5] floatValue];
            [self.nativeTransform setTransformStruct:ts];
        }
    }
    else if ([self.function isEqualToString:@"skewX"])
    {
        if ([self.numbers count] > 0)
        {
            NSAffineTransformStruct ts;
            ts.m11 = 1;
            ts.m21 = 0;
            ts.m12 = tanf(RADIANS([self.numbers[0] floatValue]));
            ts.m22 = 1;
            ts.tX  = 0;
            ts.tY  = 0;
            [self.nativeTransform setTransformStruct:ts];
        }
    }
    else if ([self.function isEqualToString:@"skewY"])
    {
        if ([self.numbers count] > 0)
        {
            NSAffineTransformStruct ts;
            ts.m11 = 1;
            ts.m21 = tanf(RADIANS([self.numbers[0] floatValue]));
            ts.m12 = 0;
            ts.m22 = 1;
            ts.tX  = 0;
            ts.tY  = 0;
            [self.nativeTransform setTransformStruct:ts];
        }
    }

}

-(void)apply
{
    [self.nativeTransform concat];
}
@end
