//
//  SVGDimension.m
//  Vectorius
//
//  Created by Alan Smith on 06/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVGDimension.h"

#define dpi 72

@implementation SVGDimension

+(instancetype)dimension:(NSString*)str
{
    return [[SVGDimension alloc]initWithString:str];
}

+(int)unitTypeFromString:(NSString*)str
{
    NSArray *unitstrs = @[@"px",@"cm",@"mm",@"in",@"pt",@"em",@"en",@"ex",@"pc",@"%"];
    for (int i = 0;i < [unitstrs count];i++)
    {
        if ([unitstrs[i] isEqualToString:str])
            return i;
    }
    return -1;
}
-(instancetype)initWithFloat:(float)f
{
    return [self initWithFloat:f unitType:UNIT_USER];
}

-(instancetype)initWithFloat:(float)f unitType:(UnitType)ut
{
    if (self = [super init])
    {
        _value = f;
        _unitType = ut;
    }
    return self;
}

-(instancetype)initWithString:(NSString*)str
    {
    if (self = [super init])
    {
        NSScanner *scanner = [NSScanner scannerWithString:str];
        float f;
        if ([scanner scanFloat:&f])
        {
            _value = f;
            if (![scanner isAtEnd])
            {
                [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
                if (![scanner isAtEnd])
                {
                    NSString *output = nil;
                    [scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&output];
                    if (output && [output length] > 0)
                    {
                        int ut = [[self class] unitTypeFromString:output];
                        if (ut < 0)
                            ut = 0;
                        _unitType = ut;
                    }
                }
            }
        }
        else
            return nil;
    }
    return self;
}

#define IN(val) (val * dpi)
#define CM(val) (IN((val)/2.54))
#define MM(val) (CM((val)/10.0))
#define PC(val) (IN(val) / 6)

-(instancetype)copyWithZone:(nullable NSZone *)zone
{
    SVGDimension *scopy = [[[self class]alloc]initWithFloat:_value unitType:_unitType];
    return scopy;
}
-(SVGDimension*)resolve:(NSDictionary*)context
{
    float size;
    switch(_unitType)
    {
        case UNIT_USER:
            break;
        case UNIT_CM:
            _value = CM(_value);
            _unitType = UNIT_USER;
            break;
        case UNIT_MM:
            _value = MM(_value);
            _unitType = UNIT_USER;
            break;
        case UNIT_IN:
            _value = IN(_value);
            _unitType = UNIT_USER;
            break;
        case UNIT_PT:
            _unitType = UNIT_USER;
            break;
        case UNIT_EM:
            _value = [context[@"_fontsize"]floatValue];
            _unitType = UNIT_USER;
            break;
        case UNIT_EN:
            size = [context[@"_fontsize"]floatValue];
            _value = size / 2.0;
            _unitType = UNIT_USER;
            break;
        case UNIT_EX:
            size = [context[@"_fontxheight"]floatValue];
            _value = size;
            _unitType = UNIT_USER;
            break;
        case UNIT_PC:
            _value = PC(_value);
            _unitType = UNIT_USER;
            break;
        case UNIT_PERCENT:
            size = [context[@"_size"]floatValue];
            _value = _value / 100.0 * size;
            _unitType = UNIT_USER;
            break;
        default:
            _unitType = UNIT_USER;
    }
    return self;
}

-(float)resolveValue:(NSDictionary*)context
{
    float size,offset;
    switch(_unitType)
    {
        case UNIT_USER:
            return _value;
        case UNIT_CM:
            return CM(_value);
        case UNIT_MM:
            return MM(_value);
        case UNIT_IN:
            return IN(_value);
        case UNIT_PT:
            return _value;
        case UNIT_EM:
            size = [context[@"_fontsize"]floatValue];
            return size;
        case UNIT_EN:
            size = [context[@"_fontsize"]floatValue];
            return size / 2.0;
        case UNIT_EX:
            size = [context[@"_fontxheight"]floatValue];
            return size;
        case UNIT_PC:
            return PC(_value);
        case UNIT_PERCENT:
            offset = [context[@"_offset"]floatValue];
            size = [context[@"_size"]floatValue];
            return offset + _value / 100.0 * size;
        case UNIT_RATIO:
            offset = [context[@"_offset"]floatValue];
            size = [context[@"_size"]floatValue];
            return offset + _value * size;
        default:
            return _value;
    }
}

@end
