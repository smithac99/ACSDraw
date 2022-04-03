//
//  ArchiveTextDelegate.mm
//  ACSDraw
//
//  Created by alan on 07/02/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import "ArchiveTextDelegate.h"
#import "ACSDStyle.h"
#import "ACSDrawDocument.h"
#import "ACSDLink.h"


@implementation ArchiveTextDelegate

+(ArchiveTextDelegate*)archiveTextDelegateWithType:(int)ty styleMatching:(int)stm styles:(id)sts document:(ACSDrawDocument*)doc enclosingGraphic:(ACSDGraphic*)eg;
   {
	ArchiveTextDelegate *a = [[ArchiveTextDelegate alloc]initWithType:ty styleMatching:stm styles:sts document:doc enclosingGraphic:eg];
	return a;
   }

-(id)initWithType:(int)ty styleMatching:(int)stm styles:(id)sts document:(ACSDrawDocument*)doc enclosingGraphic:(ACSDGraphic*)eg;
   {
	if (self = [super initWithType:ty document:doc])
	   {
		styleMatching = stm;
		styles = sts;
		enclosingGraphic = eg;
		defaultStyle = [[document styles]objectAtIndex:0];
	   }
	return self;
   }

-(id)matchStyle:(ACSDStyle*)style
   {
	ACSDStyle *st = nil;
	if (styleMatching == MATCH_KEYS)
		st = [styles objectForKey:[NSNumber numberWithInt:[style objectKey]]];
	else if (styleMatching == MATCH_SIMILAR)
		st = [styles objectForKey:[style name]];
	if (st)
		return st;
	return defaultStyle;
   }

- (id)unarchiver:(NSKeyedUnarchiver *)unarchiver didDecodeObject:(id)object
   {
	//NSLog(@"Unarchiving %@ %x",[object class],object);
	
	if (archiveType == ARCHIVE_FILE)
		return object;
	if ([object isKindOfClass:[ACSDStyle class]])
	   {
		id o = [self matchStyle:object];
		//NSLog(@"ACSDStyle substitute %x for %x",(unsigned)o,object);
		return o;
	   }
	if ([object isKindOfClass:[ACSDLink class]])
	   {
		if ([object fromObject] == nil)
			[object setFromObject:enclosingGraphic];
		if ([object toObject] == nil)
		   {
			id o = [self matchLink:object];
			if (!o)
				return object;
			return o;
			//			return [self matchLink:object];
		   }
	   }
	return object;
   }

@end
