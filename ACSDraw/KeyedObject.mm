//
//  KeyedObject.mm
//  ACSDraw
//
//  Created by alan on 14/02/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import "GXPArchiveDelegate.h"
#import "KeyedObject.h"
#import "ArchiveDelegate.h"
#import "ACSDrawDocument.h"


@implementation KeyedObject

-(id)init
{
	if (self = [super init])
	{
		self.objectKey = -1;
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    if (self.attributes)
        [coder encodeObject:self.attributes forKey:@"attributes"];
	id delegate = [(NSKeyedUnarchiver*)coder delegate];
	if (delegate && [delegate isMemberOfClass:[GXPArchiveDelegate class]])
		[coder encodeInt:self.objectKey forKey:@"objectKey"];
}

- (id) initWithCoder:(NSCoder*)coder
{
	self = [self init];
    self.attributes = [coder decodeObjectForKey:@"attributes"];
	id delegate = [(NSKeyedUnarchiver*)coder delegate];
	if (delegate)
		[(ArchiveDelegate*)delegate registerObject:self];
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    KeyedObject *obj =  [[[self class] allocWithZone:zone] init];
    obj.attributes = [self.attributes mutableCopy];
    return obj;
}

-(void)deRegisterWithDocument:(ACSDrawDocument*)doc
{
	[doc deRegisterObject:self];
}

-(void)registerWithDocument:(ACSDrawDocument*)doc
{
	[doc registerObject:self];
}

-(void)addBlankAttribute
{
    if (self.attributes == nil)
        self.attributes = [NSMutableArray arrayWithCapacity:10];
    [self.attributes addObject:@[@"",@""]];
}
@end
