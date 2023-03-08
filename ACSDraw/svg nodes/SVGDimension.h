//
//  SVGDimension.h
//  Vectorius
//
//  Created by Alan Smith on 06/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    UNIT_USER = 0,
    UNIT_CM,
    UNIT_MM,
    UNIT_IN,
    UNIT_PT,
    UNIT_EM,
    UNIT_EN,
    UNIT_EX,
    UNIT_PC,
    UNIT_PERCENT,
    UNIT_RATIO
} UnitType;


@interface SVGDimension : NSObject<NSCopying>

@property float value;
@property UnitType unitType;

+(instancetype)dimension:(NSString*)str;
+(int)unitTypeFromString:(NSString*)str;
-(instancetype)initWithString:(NSString*)str;
-(instancetype)initWithFloat:(float)f;
-(instancetype)initWithFloat:(float)f unitType:(UnitType)ut;
-(SVGDimension*)resolve:(NSDictionary*)context;
-(float)resolveValue:(NSDictionary*)context;

@end

