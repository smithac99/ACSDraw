#import "HtmlExportController.h"

@implementation HtmlExportController

-(void)dealloc
{
	[_accessoryView release];
	[super dealloc];
}

-(BOOL)clickThrough
   {
	return [clickThroughCB state];
   }

-(NSString*)picFormat
   {
	return [[picFormatMenu selectedItem]title];
   }

-(void)enableAreaDimension:(int)val
   {
	[picDimension setEnabled:(val == 1)];
	[picArea setEnabled:(val == 2)];
   }

- (IBAction)clickThroughCBHit:(id)sender
   {
	[picSizeRB setEnabled:[clickThroughCB state]];
	[self enableAreaDimension:([clickThroughCB state])?(int)[picSizeRB selectedRow]:0];
   }

-(int)clickThroughLimitType
   {
	return (int)[picSizeRB selectedRow];
   }

-(int)clickThroughLimit
   {
	switch ([picSizeRB selectedRow])
	   {
		case PICS_ORIGINAL:
			return 0;
		case PICS_MAX_DIM:
			return [picDimension intValue];
		case PICS_MAX_AREA:
			return [picArea intValue];
	   }
	return 0;
   }

- (IBAction)picSizeRBHit:(id)sender
   {
	[self enableAreaDimension:(int)[picSizeRB selectedRow]];
   }

- (IBAction)vectorGraphicsRBHit:(id)sender
   {
   }

-(void)enableControls
   {
	[self clickThroughCBHit:nil];
   }

-(void)setControls:(NSMutableDictionary*)htmlSettings
   {
	if (htmlSettings)
	   {
		[clickThroughCB setState:[[htmlSettings objectForKey:@"clickThrough"]intValue]];
		[ieCompatibility setState:[[htmlSettings objectForKey:@"ieCompatibility"]boolValue]];
		int clickThroughLimitType = [[htmlSettings objectForKey:@"clickThroughLimitType"]intValue];
		[picSizeRB selectCellAtRow:clickThroughLimitType column:0];
		[vectorGraphicsRB selectCellAtRow:[[htmlSettings objectForKey:@"vectorGraphicsType"]intValue] column:0];
		int clickThroughLimit = [[htmlSettings objectForKey:@"clickThroughLimit"]intValue];
		if (clickThroughLimitType == PICS_MAX_DIM)
			[picDimension setIntValue:clickThroughLimit];
		else if (clickThroughLimitType == PICS_MAX_AREA)
			[picArea setIntValue:clickThroughLimit];
		NSString *picString = [htmlSettings objectForKey:@"picFormat"];
		if (picString)
		   {
			NSInteger i = [picFormatMenu indexOfItemWithTitle:picString];
			if (i > -1)
				[picFormatMenu selectItemAtIndex:i];
		   }
		[openAfterExportCB setState:[[htmlSettings objectForKey:@"openAfterExport"]intValue]];
	   }
	[self enableControls];
   }

-(void)updateSettingsFromControls:(NSMutableDictionary*)htmlSettings
   {
	BOOL clickThrough = [self clickThrough];
	[htmlSettings setObject:[NSNumber numberWithBool:clickThrough] forKey:@"clickThrough"];
	if (clickThrough)
	   {
		[htmlSettings setObject:[NSNumber numberWithInt:[self clickThroughLimitType]] forKey:@"clickThroughLimitType"];
		[htmlSettings setObject:[NSNumber numberWithInt:[self clickThroughLimit]] forKey:@"clickThroughLimit"];
	   }
	[htmlSettings setObject:[self picFormat] forKey:@"picFormat"];
	NSString *imageSuffix,*imageType;
	if ([[self picFormat] isEqualToString:@"PNG"])
	   {
		imageSuffix = @"png";
		imageType = (NSString*)kUTTypePNG;
	   }
	else
	   {
		imageSuffix = @"jpg";
		imageType = (NSString*)kUTTypeJPEG;
	   }
	[htmlSettings setObject:imageSuffix forKey:@"imageSuffix"];
	[htmlSettings setObject:imageType forKey:@"imageType"];
	[htmlSettings setObject:[NSNumber numberWithInteger:[vectorGraphicsRB selectedRow]] forKey:@"vectorGraphicsType"];
	[htmlSettings setObject:[NSNumber numberWithBool:[ieCompatibility state]] forKey:@"ieCompatibility"];
	[htmlSettings setObject:[NSNumber numberWithBool:[openAfterExportCB state]] forKey:@"openAfterExport"];
   }

@end
