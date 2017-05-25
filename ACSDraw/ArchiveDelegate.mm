//
//  ArchiveDelegate.mm
//  ACSDraw
//
//  Created by alan on 07/02/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import "ArchiveDelegate.h"
#import "ACSDrawDocument.h"
#import "KeyedObject.h"
#import "ACSDLink.h"
#import "ACSDFill.h"
#import "ACSDStroke.h"
#import "ShadowType.h"
#import "ACSDLineEnding.h"

int findSame(id obj,NSArray *arr);


@implementation ArchiveDelegate

+(ArchiveDelegate*)archiveDelegateWithType:(int)ty document:(ACSDrawDocument*)doc
{
	ArchiveDelegate *a = [[ArchiveDelegate alloc]initWithType:ty document:doc];
	return [a autorelease];
}

-(id)initWithType:(int)ty document:(ACSDrawDocument*)doc
{
	if (self = [super init])
	{
		archiveType = ty;
		document = doc;
	}
	return self;
}

-(void)dealloc
{
	[super dealloc];
	if (newFills)
		[newFills release];
}

-(int)archiveType
{
	return archiveType;
}

-(void)registerObject:(KeyedObject*)ko
{
	[document registerObject:ko];
}

-(NSMutableSet*)newFills
{
	if (!newFills)
		newFills = [[NSMutableSet setWithCapacity:20]retain];
	return newFills;
}

-(NSMutableSet*)newStrokes
{
	if (!newStrokes)
		newStrokes = [[NSMutableSet setWithCapacity:20]retain];
	return newStrokes;
}

-(NSMutableSet*)newShadows
{
	if (!newShadows)
		newShadows = [[NSMutableSet setWithCapacity:20]retain];
	return newShadows;
}

-(NSMutableSet*)newLineEndings
{
	if (!newLineEndings)
		newLineEndings = [[NSMutableSet setWithCapacity:20]retain];
	return newLineEndings;
}

-(id)matchLink:(ACSDLink*)link
{
	if ([link tempToKey] == -1  || ! sameDocument)
		return nil;
	id o = [[document keyedObjects]objectForKey:[NSNumber numberWithInt:[link tempToKey]]];
	if (o == nil)
		return nil;
	[link setToObject:o];
	return link;
}

-(id)matchFill:(ACSDFill*)fill
{
	if ([newFills containsObject:fill])
		return fill;
	if ([self sameDocument])
	{
		id o = [[document keyedObjects]objectForKey:[NSNumber numberWithInt:[fill objectKey]]];
		if (o)
			return o;
	}
	int ind;
	if ((ind = findSame(fill,[document fills])) >= 0)
		return [[document fills]objectAtIndex:ind];
	[[self newFills] addObject:fill];
	[fill setObjectKey:-1];
	[document registerObject:fill];
	return fill;
}

-(id)matchLineEnding:(ACSDLineEnding*)le
{
	if ([newLineEndings containsObject:le])
		return le;
	if ([self sameDocument])
	{
		id o = [[document keyedObjects]objectForKey:[NSNumber numberWithInt:[le objectKey]]];
		if (o)
			return o;
	}
	int ind;
	if ((ind = findSame(le,[document lineEndings])) >= 0)
		return [[document lineEndings]objectAtIndex:ind];
	[[self newLineEndings] addObject:le];
	[le setObjectKey:-1];
	[document registerObject:le];
	return le;
}

-(id)matchStroke:(ACSDStroke*)stroke
{
	if ([newStrokes containsObject:stroke])
		return stroke;
	if ([self sameDocument])
	{
		id o = [[document keyedObjects]objectForKey:[NSNumber numberWithInt:[stroke objectKey]]];
		if (o)
			return o;
	}
	int ind;
	if ((ind = findSame(stroke,[document strokes])) >= 0)
		return [[document strokes]objectAtIndex:ind];
	[[self newStrokes] addObject:stroke];
	[stroke setObjectKey:-1];
	[document registerObject:stroke];
	return stroke;
}

-(id)matchShadow:(ShadowType*)sh
{
	if ([newShadows containsObject:sh])
		return sh;
	if ([self sameDocument])
	{
		id o = [[document keyedObjects]objectForKey:[NSNumber numberWithInt:[sh objectKey]]];
		if (o)
			return o;
	}
	int ind;
	if ((ind = findSame(sh,[document shadows])) >= 0)
		return [[document shadows]objectAtIndex:ind];
	[[self newShadows] addObject:sh];
	[sh setObjectKey:-1];
	[document registerObject:sh];
	return sh;
}

- (id)unarchiver:(NSKeyedUnarchiver *)unarchiver didDecodeObject:(id)object
{
	if (archiveType == ARCHIVE_FILE)
		return object;
	if ([object isKindOfClass:[ACSDLink class]])
	{
		if ([object fromObject] == nil)
			return nil;
		if ([object toObject] == nil)
		{
			id o = [self matchLink:object];
			return o;
			//			return [self matchLink:object];
		}
	}
	if ([object isKindOfClass:[ACSDFill class]])
		return [self matchFill:object];
	if ([object isKindOfClass:[ACSDStroke class]])
		return [self matchStroke:object];
	if ([object isKindOfClass:[ACSDLineEnding class]])
		return [self matchLineEnding:object];
	if ([object isKindOfClass:[ShadowType class]])
		return [self matchShadow:object];
	return object;
}

-(BOOL)sameDocument
{
	return sameDocument;
}

-(void)setSameDocument:(BOOL)b
{
	sameDocument = b;
}

@end
