//
//  AnimationEntry.m
//  ACSDraw
//
//  Created by Alan on 30/06/2014.
//
//

#import "AnimationEntry.h"

@implementation AnimationEntry

-(id)init
{
    if (self = [super init])
    {
        self.settings = [NSMutableDictionary dictionaryWithCapacity:5];
    }
    return self;
}

-(id)copy
{
    AnimationEntry *ae = [[[self class]alloc]init];
    ae.name = self.name;
    ae.text = self.text;
    return ae;
}

- (void) encodeWithCoder:(NSCoder*)coder
{
	[coder encodeObject:self.name forKey:@"name"];
	[coder encodeObject:self.text forKey:@"text"];
}

- (id) initWithCoder:(NSCoder*)coder
{
	self = [self init];
    self.name = [coder decodeObjectForKey:@"name"];
    self.text = [coder decodeObjectForKey:@"text"];
	return self;
}


@end
