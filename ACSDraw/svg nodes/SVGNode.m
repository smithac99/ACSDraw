//
//  SVGNode.m
//  Vectorius
//
//  Created by Alan Smith on 06/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVGNode.h"
#import "SVGDimension.h"
#import "SVG_rect.h"
#import "SVG_g.h"
#import "SVG_ellipse.h"
#import "SVG_circle.h"
#import "SVG_path.h"
#import "SVG_line.h"
#import "SVG_polyline.h"
#import "SVG_polygon.h"

@implementation SVGNode

-(instancetype)init
{
    if (self = [super init])
    {
        self.buildAttributes = [NSMutableDictionary dictionary];
        self.resolvedAttributes = [NSMutableDictionary dictionary];
        self.processedAttributes = [NSMutableDictionary dictionary];
        self.children = [NSMutableArray array];
    }
    return self;
}

-(instancetype)initWithXMLNode:(XMLNode*)xmlNode context:(NSMutableDictionary*)context
{
    if (self = [self init])
    {
        [self buildTree:xmlNode context:context];
    }
    return self;
}

-(instancetype)copyToClass:(Class)cl
{
    SVGNode *nodecopy = [[cl alloc]init];
    for (id k in [self.buildAttributes allKeys])
        nodecopy.buildAttributes[k] = self.buildAttributes[k];
    for (id k in [self.resolvedAttributes allKeys])
        nodecopy.resolvedAttributes[k] = self.resolvedAttributes[k];
    for (SVGNode *n in self.children)
    {
        SVGNode *nc = [n copy];
        [nodecopy.children addObject:nc];
        nc.parent = nodecopy;
    }
    return nodecopy;
}

-(instancetype)copy
{
    return [self copyToClass:[self class]];
}

-(instancetype)gCopy
{
    return [self copyToClass:[SVG_g class]];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone
{
    return [self copy];
}

-(NSArray*)inheritableAttributeIds
{
    static NSArray *a = nil;
    if (a == nil)
        a = @[
            @"fill",
            @"fill-rule",
            @"fill-opacity",
            @"stroke",
            @"stroke-linecap",
            @"stroke-linejoin",
            @"stroke-miterlimit",
            @"stroke-dasharray",
            @"stroke-dashoffset",
            @"stroke-opacity",
            @"stroke-width",
            @"_viewbox"
        ];
    return a;
}

#pragma mark -

-(NSString*)getAttributeString:(NSString*)attrstr fromXmlNode:(XMLNode*)node
{
    NSString *str = nil;
    if ((str = node.attributes[attrstr]))
    {
        self.buildAttributes[attrstr] = str;
    }
    return str;
}

#pragma mark -

-(SVGDimension*)processAttributeDimension:(NSString*)attrid
{
    NSString *str = nil;
    SVGDimension *dim = nil;
    if ((str = self.resolvedAttributes[attrid]))
    {
        dim = [SVGDimension dimension:str];
        self.processedAttributes[attrid] = dim;
    }
    return dim;
}

-(SVGDimension*)processAttributeDimension:(NSString*)attrid defaultVal:(float)deff
{
    NSString *str = nil;
    SVGDimension *dim = nil;
    if ((str = self.resolvedAttributes[attrid]))
        dim = [SVGDimension dimension:str];
    else
        dim = [[SVGDimension alloc]initWithFloat:deff unitType:UNIT_USER];
    self.processedAttributes[attrid] = dim;
    return dim;
}

-(NSNumber*)processAttributeFloat:(NSString*)attrstr
{
    NSString *str = nil;
    NSNumber *n = nil;
    if ((str = self.resolvedAttributes[attrstr]))
    {
        n = [NSNumber numberWithFloat:[str floatValue]];
        self.processedAttributes[attrstr] = n;
    }
    return n;
}


-(SVGPaint*)processAttributePaint:(NSString*)attrid
{
    NSString *str = nil;
    SVGPaint *p = nil;
    if ((str = self.resolvedAttributes[attrid]))
    {
        p = [[SVGPaint alloc]initWithString:str];
        self.processedAttributes[attrid] = p;
    }
    return p;
}

-(NSString*)processAttributeString:(NSString*)attrid
{
    NSString *str = nil;
    if ((str = self.resolvedAttributes[attrid]))
    {
        self.processedAttributes[attrid] = str;
    }
    return str;
}

#pragma mark -

-(NSArray*)getAttributeTransform:(NSString*)attr fromXmlNode:(XMLNode*)node
{
    NSString *str = nil;
    NSArray *trs = nil;
    if ((str = node.attributes[attr]))
    {
        NSArray *trs = [SVGTransform transformsForInputString:str];
        self.buildAttributes[@"_transforms"] = trs;
    }
    return  trs;
}

-(NSArray*)getAttributeTransformsFromXmlNode:(XMLNode*)node
{
    return [self getAttributeTransform:@"transform" fromXmlNode:node];
}

#pragma mark -

-(void)processOtherAttributes:(NSMutableDictionary*)context
{
    
}
-(void)processAttributes:(NSMutableDictionary*)context
{
    if (!self.resolved)
        [self resolveAttributes:context];
    [self processPaintingAttributes:context];
    [self processOtherAttributes:context];
    self.processed = YES;
}

-(void)processChildrenAttributes:(NSMutableDictionary*)context
{
    for (SVGNode *child in self.children)
    {
        [child processAttributes:context];
    }
}

#pragma mark -

-(void)inheritAttributesFromParent:(NSMutableDictionary*)context
{
    if (self.parent)
    {
        if (!self.parent.resolved)
            [self.parent resolveAttributes:context];
        for (NSString *pid in [self inheritableAttributeIds])
            if (self.parent.resolvedAttributes[pid])
                self.resolvedAttributes[pid] = self.parent.resolvedAttributes[pid];
    }
}

-(void)resolveAttributes:(NSMutableDictionary*)context
{
    [self inheritAttributesFromParent:context];
    [self.resolvedAttributes addEntriesFromDictionary:[self classStyles:context]];
    [self.resolvedAttributes addEntriesFromDictionary:self.buildAttributes];
    self.resolved = YES;
}

-(NSRect)getViewBoxFromString:(NSString*)str
{
    static NSMutableCharacterSet *skippers = nil;
    if (skippers == nil)
    {
        skippers = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
        [skippers addCharactersInString:@","];
    }
    NSRect box = NSZeroRect;
    NSScanner *scanner = [NSScanner scannerWithString:str];
    scanner.charactersToBeSkipped = skippers;
    float f;
    if (![scanner scanFloat:&f])
        return box;
    box.origin.x =  f;
    if (![scanner scanFloat:&f])
        return box;
    box.origin.y =  f;
    if (![scanner scanFloat:&f])
        return box;
    box.size.width =  f;
    if (![scanner scanFloat:&f])
        return box;
    box.size.height =  f;

    return box;
}

-(void)buildChildren:(XMLNode*)xmlNode context:(NSMutableDictionary*)context
{
    for (XMLNode *node in xmlNode.children)
    {
        NSString *className = [NSString stringWithFormat:@"SVG_%@",node.nodeName];
        Class aClass = NSClassFromString(className);
        if (aClass)
        {
            SVGNode *sn = [[aClass alloc]initWithXMLNode:node context:context];
            [self.children addObject:sn];
            sn.parent = self;
        }
    }
}

-(void)resolveChildren:(NSMutableDictionary*)context
{
    for (SVGNode *child in self.children)
    {
        [child resolveAttributes:context];
    }
    
}

-(void)processPaintingAttributes:(NSDictionary*)context
{
    [self processAttributePaint:@"fill"];
    [self processAttributeString:@"fill-rule"];
    [self processAttributeFloat:@"fill-opacity"];
    [self processAttributePaint:@"stroke"];
    SVGDimension *n = [self processAttributeDimension:@"stroke-width"];
    float strokeWidth;
    if (n.unitType == UNIT_PERCENT)
    {
        NSRect vb = [self.resolvedAttributes[@"_viewbox"] rectValue];
        float sz = sqrtf(vb.size.width*vb.size.width+vb.size.height*vb.size.height);
        strokeWidth = [[n resolve:@{@"_size":@(sz)}]resolveValue:@{}];
    }
    else
        strokeWidth = [[n resolve:@{}]resolveValue:@{}];
    self.processedAttributes[@"_strokewidth"] = @(strokeWidth);

    [self processAttributeFloat:@"stroke-opacity"];
    [self processAttributeFloat:@"stroke-miterlimit"];
    [self processAttributeString:@"stroke-linecap"];
    [self processAttributeString:@"stroke-linejoin"];
    [self processAttributeString:@"display"];
    [self processAttributeString:@"visibility"];

}

-(NSDictionary*)classStyles:(NSMutableDictionary*)context
{
    NSString *clname = self.buildAttributes[@"class"];
    if (clname)
    {
        NSMutableDictionary *styleDict = context[@"styledict"];
        return styleDict[[NSString stringWithFormat:@".%@",clname]];
    }
    return nil;
}

-(void)getAttributesFromStyles:(XMLNode*)xmlNode context:(NSMutableDictionary*)context
{
    NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
    [mdict addEntriesFromDictionary:[self classStyles:context]];
    if (xmlNode.attributes[@"style"])
    {
        NSArray *svgstyles = [xmlNode.attributes[@"style"] componentsSeparatedByString:@";"];
        for (NSString *style in svgstyles)
        {
            if (style != nil && [style length] > 2)
            {
                NSArray *arr = [style componentsSeparatedByString:@":"];
                if ([arr count] > 1)
                {
                    NSString *sty = arr[0];
                    NSString *val = arr[1];
                    sty = [sty stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    val = [val stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    if ([sty length] > 0)
                    {
                        mdict[sty] = val;
                    }
                }
            }
        }
    }
    [_buildAttributes addEntriesFromDictionary:mdict];
}

-(void)buildTree:(XMLNode*)xmlNode context:(NSMutableDictionary*)context
{
    [self getAttributesFromStyles:xmlNode context:context];
    [self.buildAttributes addEntriesFromDictionary:xmlNode.attributes];
    NSString *idattr = self.buildAttributes[@"id"];
    if (idattr != nil && context[@"objectdict"][idattr] == nil)
    {
        context[@"objectdict"][idattr] = self;
    }
    [self getAttributeTransformsFromXmlNode:xmlNode];
}

-(SVGDimension*)processDimension:(NSString*)attrId defaultValue:(float)def size:(float)size
{
    SVGDimension *n = [self processAttributeDimension:attrId];
    if (n == nil)
    {
        n = [[SVGDimension alloc]initWithFloat:def];
        self.processedAttributes[attrId] = n;
    }
    else
        [n resolve:@{@"_size":@(size)}];
    return n;
}

-(SVGDimension*)processAttributeDimension:(NSString*)attr defaultDimension:(SVGDimension*)defDim
{
    SVGDimension *n = [self processAttributeDimension:attr];
    if (n == nil)
    {
        n = defDim;
        self.processedAttributes[attr] = n;
    }
    return n;
}

-(void)applyClip:(NSRect)bbox context:(NSMutableDictionary*)context
{
    
}
@end
