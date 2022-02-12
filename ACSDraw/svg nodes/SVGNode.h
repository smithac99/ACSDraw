//
//  SVGNode.h
//  Vectorius
//
//  Created by Alan Smith on 06/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMLNode.h"
#import "SVGPaint.h"
#import "SVGDimension.h"
#import "SVGTransform.h"


@interface SVGNode : NSObject<NSCopying>

@property (retain) NSMutableDictionary *buildAttributes;
@property (retain) NSMutableDictionary *processedAttributes;
@property (retain) NSMutableDictionary *resolvedAttributes;
@property (retain) NSMutableArray<SVGNode*> *children;
@property (weak) SVGNode *parent;
@property BOOL resolved,processed;

-(instancetype)initWithXMLNode:(XMLNode*)xmlNode context:(NSMutableDictionary*)context;
-(instancetype)copyToClass:(Class)cl;
-(instancetype)gCopy;

-(void)buildTree:(XMLNode*)xmlNode context:(NSMutableDictionary*)context;

-(void)resolveAttributes:(NSMutableDictionary*)context;
-(NSRect)getViewBoxFromString:(NSString*)str;
-(void)resolveChildren:(NSMutableDictionary*)context;
-(void)buildChildren:(XMLNode*)xmlNode context:(NSMutableDictionary*)context;
-(NSString*)getAttributeString:(NSString*)attrstr fromXmlNode:(XMLNode*)node;
-(NSArray*)getAttributeTransformsFromXmlNode:(XMLNode*)node;
-(NSArray*)getAttributeTransform:(NSString*)attr fromXmlNode:(XMLNode*)node;
-(void)processChildrenAttributes:(NSMutableDictionary*)context;
-(void)processAttributes:(NSMutableDictionary*)context;
-(NSArray*)inheritableAttributeIds;
-(SVGDimension*)processAttributeDimension:(NSString*)attrstr;
-(void)processOtherAttributes:(NSMutableDictionary*)context;
-(SVGDimension*)processDimension:(NSString*)attrId defaultValue:(float)def size:(float)size;
-(NSNumber*)processAttributeFloat:(NSString*)attrstr;
-(SVGPaint*)processAttributePaint:(NSString*)attrid;
-(SVGDimension*)processAttributeDimension:(NSString*)attrid defaultVal:(float)deff;
-(SVGDimension*)processAttributeDimension:(NSString*)attr defaultDimension:(SVGDimension*)defDim;
-(void)applyClip:(NSRect)bbox context:(NSMutableDictionary*)context;
@end

