//
//  ACSDLink.mm
//  ACSDraw
//
//  Created by alan on 03/02/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import "ACSDLink.h"
#import "ACSDGraphic.h"
#import "ACSDPage.h"
#import "ACSDText.h"
#import "ArchiveDelegate.h"


@implementation ACSDLink

+(ACSDLink*)linkFrom:(id)from to:(id)to
   {
	return [ACSDLink linkFrom:from to:to anchorID:-1];
   }

+(ACSDLink*)linkFrom:(id)from to:(id)to anchorID:(int)a
   {
	return [[[ACSDLink alloc]initFrom:from to:to anchorID:a]autorelease];
   }

+(ACSDLink*)linkFrom:(id)from to:(id)to anchorID:(int)anchorID substitutePageNo:(BOOL)substitutePageNo changeAttributes:(BOOL)changeAttributes
   {
	ACSDLink *l = [[ACSDLink alloc]initFrom:from to:to anchorID:anchorID];
	[l setSubstitutePageNo:substitutePageNo];
	[l setChangeAttributes:changeAttributes];
	return [l autorelease];
   }

-(id)initFrom:(id)from to:(id)to anchorID:(int)a
   {
	if (self = [super init])
	   {
		fromObject = [from retain];
		toObject = [to retain];
		self.anchorID = a;
		overflow = NO;
		substitutePageNo = NO;
		changeAttributes = YES;
	   }
	return self;
   }

- (void) dealloc
{
    [fromObject release];
    [toObject release];
    //NSLog(@"ACSDLink dealloc %lx",(NSUInteger)self);
    [super dealloc];
}

- (void) encodeWithCoder:(NSCoder*)coder
   {
	[coder encodeConditionalObject:fromObject forKey:@"ACSDLink_fromObject"];
	[coder encodeConditionalObject:toObject forKey:@"ACSDLink_toObject"];
	[coder encodeInt:self.anchorID forKey:@"ACSDLink_anchorID"];
	[coder encodeBool:changeAttributes forKey:@"ACSDLink_changeAttributes"];
	[coder encodeBool:substitutePageNo forKey:@"ACSDLink_substitutePageNo"];
	id delegate = [(NSKeyedUnarchiver*)coder delegate];
	if (delegate && [delegate respondsToSelector:@selector(archiveType)] && [delegate archiveType] == ARCHIVE_PASTEBOARD)
		[coder encodeInt:[toObject objectKey] forKey:@"toObjectKey"];
   }

- (id) initWithCoder:(NSCoder*)coder
   {
	self = [super init];
	fromObject = [[coder decodeObjectForKey:@"ACSDLink_fromObject"]retain];
	toObject = [[coder decodeObjectForKey:@"ACSDLink_toObject"]retain];
	self.anchorID = [coder decodeIntForKey:@"ACSDLink_anchorID"];
	self.tempToKey = [coder decodeIntForKey:@"toObjectKey"];
//	substitutePageNo = NO;
	substitutePageNo = [coder decodeBoolForKey:@"ACSDLink_substitutePageNo"];
	if ([coder containsValueForKey:@"ACSDLink_changeAttributes"])
		changeAttributes = [coder decodeBoolForKey:@"ACSDLink_changeAttributes"];
	else
		changeAttributes = YES;
	return self;
   }

- (BOOL)changeAttributes
   {
    return changeAttributes;
   }

- (BOOL)substitutePageNo
   {
    return substitutePageNo;
   }

- (BOOL)overflow
   {
    return overflow;
   }

-(void)setSubstitutePageNo:(BOOL)a
   {
	substitutePageNo = a;
   }

-(void)setChangeAttributes:(BOOL)a
   {
	changeAttributes = a;
   }

- (id)fromObject
   {
    return fromObject;
   }

- (id)toObject
   {
    return toObject;
   }

- (void)removeFromLinkedObjects
   {
	if ([fromObject link] == self)
		[fromObject setLink:nil];
	else if ([fromObject isKindOfClass:[ACSDText class]])
		[(ACSDText*)fromObject removeTextLink:self];
	[toObject uRemoveLinkedObject:self];
   }

-(void)setFromObject:(id)newFrom
   {
	if (fromObject == newFrom)
		return;
	if (fromObject)
		[fromObject release];
	fromObject = newFrom;
	if (fromObject)
		[fromObject retain];
   }

-(void)setToObject:(id)newTo
   {
	if (toObject == newTo)
		return;
	if (toObject)
	   {
		[toObject release];
		[toObject uRemoveLinkedObject:self];
	   }
	toObject = newTo;
	if (toObject)
		[toObject retain];
	[toObject uAddLinkedObject:self];
   }

-(BOOL)checkToObj
   {
	if (self.anchorID < 0)
		return NO;
	overflow = NO;
	id newTo = [toObject checkLink:self overflow:&overflow];
	if (newTo != toObject)
	   {
		[self setToObject:newTo];
		return YES;
	   }
	return NO;
   }

-(NSString*)anchorNameForToObject
   {
	return [ACSDLink anchorNameForObject:[self toObject] anchorID:[self anchorID]];
   }

-(NSInteger)pageNumberForToObject
   {
	if ([[self toObject] isKindOfClass:[ACSDPage class]])
		return [[self toObject] pageNo];
	return [[[(ACSDGraphic*)[self toObject]layer]page] pageNo];
   }

+(NSString*)anchorNameForObject:(id)obj
   {
	if ([obj isKindOfClass:[ACSDPage class]])
		return [NSString stringWithFormat:@"Page%ld",[obj pageNo]];
	return [NSString stringWithFormat:@"a%lx",(NSUInteger)obj];
   }


+(NSString*)anchorNameForObject:(id)obj anchorID:(int)anc
   {
	if ([obj isKindOfClass:[ACSDPage class]])
		return [NSString stringWithFormat:@"Page%ld",[obj pageNo]];
	NSString *str = [NSString stringWithFormat:@"a%lx",(NSUInteger)obj];
	if (anc >= 0)
		str = [NSString stringWithFormat:@"%@-%d",str,anc];
	return str;
   }

-(NSString*)anchorNameForFromObject
   {
	if ([fromObject isKindOfClass:[ACSDPage class]])
		return [NSString stringWithFormat:@"Page%ld",[fromObject pageNo]];
	return [NSString stringWithFormat:@"a%lx",(NSUInteger)[self fromObject]];
   }

+(void)uDeleteFromFromObjectLink:(ACSDLink*)l undoManager:(NSUndoManager*)undoManager
   {
	id fromObject = [l fromObject];
	if ([fromObject link] == l)
		[ACSDLink uDeleteLinkForObject:fromObject undoManager:undoManager];
	else
	   {
		[l retain];
		NSRange r = [fromObject removeTextLink:l];
		if (r.location != NSNotFound)
			[[undoManager prepareWithInvocationTarget:self] uLinkFromObject:fromObject range:r toObject:[l toObject] anchor:[l anchorID]
														   substitutePageNo:[l substitutePageNo] changeAttributes:[l changeAttributes] undoManager:undoManager];			
		[[l toObject] uRemoveLinkedObject:l];
		[l release];
	   }
   }

+(void)uDeleteLinkForObject:(id)fromObject undoManager:(NSUndoManager*)undoManager
   {
	if (![fromObject link])
		return;
	ACSDLink *l = [fromObject link];
	[[undoManager prepareWithInvocationTarget:self] uLinkFromObject:fromObject toObject:[l toObject] anchor:[l anchorID]
												   substitutePageNo:[l substitutePageNo] changeAttributes:[l changeAttributes] undoManager:undoManager];
	[l removeFromLinkedObjects];
   }

+(void)uDeleteLinkForObject:(id)fromObject range:(NSRange)textRange undoManager:(NSUndoManager*)undoManager
   {
	ACSDLink *l = [fromObject link];
	[[undoManager prepareWithInvocationTarget:self] uLinkFromObject:fromObject range:textRange toObject:[l toObject] anchor:[l anchorID]
												   substitutePageNo:[l substitutePageNo] changeAttributes:[l changeAttributes] undoManager:undoManager];
	[l removeFromLinkedObjects];
   }

+(ACSDLink*)uLinkFromObject:(id)fromObject toObject:(id)toObject anchor:(int)anchor 
		   substitutePageNo:(BOOL)substitutePageNo changeAttributes:(BOOL)changeAttributes undoManager:(NSUndoManager*)undoManager
   {
	if ([fromObject link])
		[ACSDLink uDeleteLinkForObject:fromObject undoManager:undoManager];
	ACSDLink *l = [ACSDLink linkFrom:fromObject to:toObject anchorID:anchor substitutePageNo:substitutePageNo changeAttributes:changeAttributes];
	[[undoManager prepareWithInvocationTarget:self] uDeleteLinkForObject:fromObject undoManager:undoManager];
	[fromObject uSetLink:l];
	[toObject uAddLinkedObject:l];
	return l;
   }

+(ACSDLink*)uLinkFromObject:(id)fromObject range:(NSRange)textRange toObject:(id)toObject anchor:(int)anchor 
		   substitutePageNo:(BOOL)substitutePageNo changeAttributes:(BOOL)changeAttributes undoManager:(NSUndoManager*)undoManager
   {
	ACSDLink *l = [ACSDLink linkFrom:fromObject to:toObject anchorID:anchor];
	[[undoManager prepareWithInvocationTarget:self] uDeleteLinkForObject:fromObject range:textRange undoManager:undoManager];
	[(ACSDText*)fromObject uSetLink:l forRange:textRange];
	[toObject uAddLinkedObject:l];
	return l;
   }


@end
