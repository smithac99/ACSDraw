//
//  gSubPath.h
//  ACSDraw
//
//  Created by alan on 08/01/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ACSDSubPath;

@interface gSubPath : NSObject

@property float fractionalLength;
@property (strong) NSMutableArray *elements;
@property float length,lengthFrom;

+(gSubPath*)gSubPathFromACSDSubPath:(ACSDSubPath*)sp;
+(NSArray*)s:(float)s alongGSubPaths:(NSArray*)gsps;
+(NSMutableArray*)gSubPathsFromACSDSubPaths:(NSMutableArray*)sps;
+(NSAffineTransform*)transformForLength:(float)l fromGSubPaths:(NSMutableArray*)gSubPaths;
-(void)calcLength;
-(void)generateElementsFromSubPath:(ACSDSubPath*)subPath;
-(NSAffineTransform*)transformForLength:(float)l;
-(gSubPath*)subPathUpToS:(float)s;
-(NSBezierPath*)bezierPath;

@end
