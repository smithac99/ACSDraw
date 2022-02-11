//
//  SVGPaint.h
//  Vectorius
//
//  Created by Alan Smith on 06/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum
{
    PAINTTYPE_NONE,
    PAINTTYPE_COLOUR,
    PAINTTYPE_SERVER
};

@interface SVGPaint : NSObject

@property int paintType;
@property id ref;

-(instancetype)initWithObj:(id)obj;
-(instancetype)initWithString:(NSString*)attrstr;
@end

