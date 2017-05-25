//
//  OverlayFilter.m
//  ACSDraw
//
//  Created by alan on 05/07/14.
//
//

#import "OverlayFilter.h"

@implementation OverlayFilter

static CIKernel *_filterKernel = nil;

+ (void)initialize
{
    [CIFilter registerFilterName: @"OverlayFilter"
                     constructor: (id)self
                 classAttributes:
     @{kCIAttributeFilterDisplayName : @"Overlay",
       kCIAttributeFilterCategories : @[
               kCICategoryColorAdjustment, kCICategoryVideo,
               kCICategoryStillImage, kCICategoryInterlaced,
               kCICategoryNonSquarePixels]}
     ];
}

+ (CIFilter *)filterWithName: (NSString *)name
{
    CIFilter  *filter;
    filter = [[self alloc] init];
    return [filter autorelease];
}

- (id)init
{
    if(_filterKernel == nil)
	{
		NSBundle    *bundle = [NSBundle bundleForClass:[self class]];
		NSStringEncoding encoding = NSUTF8StringEncoding;
		NSError     *error = nil;
		NSString    *code = [NSString stringWithContentsOfFile:[bundle pathForResource:@"OverlayFilter" ofType:@"cikernel"] encoding:encoding error:&error];
		NSArray     *kernels = [CIKernel kernelsWithString:code];
		
		_filterKernel = [[kernels objectAtIndex:0] retain];
    }
    return [super init];
}

- (NSDictionary *)customAttributes
{
    return @{@"colour" : @{kCIAttributeDefault:[CIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]}};
}

- (NSArray *)inputKeys
{
	return @[@"inputImage",@"colour"];
}

- (CIImage *)outputImage
{
    CISampler *src;
    
    src = [CISampler samplerWithImage:inputImage];
    return [self apply:_filterKernel, src,colour,
			kCIApplyOptionDefinition, [src definition],
			nil];
}

@end
