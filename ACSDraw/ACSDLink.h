//
//  ACSDLink.h
//  ACSDraw
//
//  Created by alan on 03/02/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KeyedObject.h"


@interface ACSDLink : KeyedObject 

@property int anchorID,tempToKey;
@property (retain) id fromObject;
@property (retain,nonatomic) id toObject;
@property BOOL overflow,substitutePageNo,changeAttributes;

+(ACSDLink*)linkFrom:(id)from to:(id)to;
+(ACSDLink*)linkFrom:(id)from to:(id)to anchorID:(int)anchorID;
+(ACSDLink*)linkFrom:(id)from to:(id)to anchorID:(int)anchorID substitutePageNo:(BOOL)substitutePageNo changeAttributes:(BOOL)changeAttributes;
-(id)initFrom:(id)from to:(id)to anchorID:(int)anchorID;


- (id)fromObject;
- (id)toObject;
- (void)removeFromLinkedObjects;
-(BOOL)checkToObj;
- (BOOL)overflow;
+(NSString*)anchorNameForObject:(id)obj;
+(NSString*)anchorNameForObject:(id)obj anchorID:(int)anc;
-(NSString*)anchorNameForToObject;
-(NSString*)anchorNameForFromObject;
-(void)setToObject:(id)newTo;
-(void)setFromObject:(id)newFrom;
- (BOOL)changeAttributes;
-(void)setChangeAttributes:(BOOL)a;
- (BOOL)substitutePageNo;
-(void)setSubstitutePageNo:(BOOL)a;
-(NSInteger)pageNumberForToObject;
+(ACSDLink*)uLinkFromObject:(id)fromObject toObject:(id)toObject anchor:(int)anchor 
		   substitutePageNo:(BOOL)substitutePageNo changeAttributes:(BOOL)changeAttributes undoManager:(NSUndoManager*)undoManager;
+(void)uDeleteLinkForObject:(id)fromObject undoManager:(NSUndoManager*)undoManager;
+(ACSDLink*)uLinkFromObject:(id)fromObject range:(NSRange)textRange toObject:(id)toObject anchor:(int)anchor 
		   substitutePageNo:(BOOL)substitutePageNo changeAttributes:(BOOL)changeAttributes undoManager:(NSUndoManager*)undoManager;
+(void)uDeleteLinkForObject:(id)fromObject range:(NSRange)textRange undoManager:(NSUndoManager*)undoManager;
+(void)uDeleteFromFromObjectLink:(ACSDLink*)l undoManager:(NSUndoManager*)undoManager;

@end
