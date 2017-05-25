//
//  XXAffineTransform.mm
//  GeogXPert
//
//  Created by alan on 28/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "XXAffineTransform.h"


@implementation XXAffineTransform

-(CGAffineTransform) transform
{
	return _transform;
}

+(id)transform
{
	return [[XXAffineTransform alloc]init];
}

-(id)init
{
	if (self = [super init])
	{
		_transform = CGAffineTransformIdentity;
	}
	return self;
}

-(id)initWithTransform:(XXAffineTransform*)t
{
	if (self = [super init])
	{
		_transform = [t transform];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder*)coder
{
	[coder encodeFloat:_transform.a  forKey:@"a"];
	[coder encodeFloat:_transform.b  forKey:@"b"];
	[coder encodeFloat:_transform.c  forKey:@"c"];
	[coder encodeFloat:_transform.d  forKey:@"d"];
	[coder encodeFloat:_transform.tx forKey:@"tx"];
	[coder encodeFloat:_transform.ty forKey:@"ty"];
}

- (id) initWithCoder:(NSCoder*)coder
{
	self = [super init];
	_transform.a  = [coder decodeFloatForKey:@"a"];
	_transform.b  = [coder decodeFloatForKey:@"b"];
	_transform.c  = [coder decodeFloatForKey:@"c"];
	_transform.d  = [coder decodeFloatForKey:@"d"];
	_transform.tx = [coder decodeFloatForKey:@"tx"];
	_transform.ty = [coder decodeFloatForKey:@"ty"];
	return self;
}

-(void)scaleBy:(float)amount
{
	CGAffineTransform t = CGAffineTransformMakeScale(amount,amount);
	_transform = CGAffineTransformConcat(_transform,t);
}

-(void)scaleXBy:(float)x yBy:(float)y
{
	CGAffineTransform t = CGAffineTransformMakeScale(x,y);
	_transform = CGAffineTransformConcat(_transform,t);
}

-(void)translateXBy:(float)x yBy:(float)y
{
	CGAffineTransform t = CGAffineTransformMakeTranslation(x,y);
	_transform = CGAffineTransformConcat(_transform,t);
}

-(void)rotateByDegrees:(float)amount
{
	CGAffineTransform t = CGAffineTransformMakeRotation(RADIANS(amount));
	_transform = CGAffineTransformConcat(_transform,t);
}


-(void)appendTransform:(XXAffineTransform*)t
{
	_transform = CGAffineTransformConcat(_transform,[t transform]);	
}

-(void)prependTransform:(XXAffineTransform*)t
{
	_transform = CGAffineTransformConcat([t transform],_transform);	
}


-(void)invert
{
	_transform = CGAffineTransformInvert(_transform);
}

-(CGPoint)transformPoint:(CGPoint)pt
{
	return CGPointApplyAffineTransform(pt, _transform);
}

@end
