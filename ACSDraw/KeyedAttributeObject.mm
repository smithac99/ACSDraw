//
//  KeyedAttributeObject.mm
//  ACSDraw
//
//  Created by alan on 15/02/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import "KeyedAttributeObject.h"
#import "ArchiveDelegate.h"
#import "ACSDrawDocument.h"


@implementation KeyedAttributeObject

- (void) encodeWithCoder:(NSCoder*)coder
   {
	id delegate = [(NSKeyedArchiver*)coder delegate];
	if (delegate && [delegate respondsToSelector:@selector(archiveType)])
		if ([delegate archiveType] == ARCHIVE_PASTEBOARD)
			[coder encodeInt:self.objectKey forKey:@"KOobjectKey"];
   }

- (id) initWithCoder:(NSCoder*)coder
   {
	self = [self init];
	id delegate = [(NSKeyedUnarchiver*)coder delegate];
	if (delegate && [delegate respondsToSelector:@selector(archiveType)])
	{
		if ([delegate archiveType] == ARCHIVE_FILE)
			[(ArchiveDelegate*)delegate registerObject:self];
		else
			self.objectKey = [coder decodeIntForKey:@"KOobjectKey"];
	}
	return self;
   }


@end
