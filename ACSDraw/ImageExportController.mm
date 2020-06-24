//
//  ImageExportController.mm
//  ACSDraw
//
//  Created by alan on 15/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ImageExportController.h"


@implementation ImageExportController

@synthesize imageWidth,imageHeight,maintainAspectRatio;

NSMutableArray *_utis;
NSMutableArray *_uti_descs;
NSMutableArray *_suffixes;

-(void)dealloc
{
	[_accessoryView release];
	[super dealloc];
}

-(NSArray*)utis
{
	if (!_utis)
	{
		CFArrayRef cfutis = CGImageDestinationCopyTypeIdentifiers();
		NSArray *nsutis = (__bridge NSArray*)cfutis;
		_suffixes = [[NSMutableArray arrayWithCapacity:[nsutis count]]retain];
		_utis = [[NSMutableArray arrayWithCapacity:[nsutis count]]retain];
		_uti_descs = [[NSMutableArray arrayWithCapacity:[_utis count]]retain];
		for (NSString *nsuti in nsutis)
		{
			[_utis addObject:nsuti];
			CFStringRef cfty = UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)nsuti,kUTTagClassFilenameExtension);
            if (cfty)
            {
                [_suffixes addObject:(NSString*)cfty];
                CFRelease(cfty);
            }
            else
                cfty = (CFStringRef)@"";
			CFStringRef cfutidesc = UTTypeCopyDescription((CFStringRef)nsuti);
			if (cfutidesc)
			{
				[_uti_descs addObject:[NSString stringWithFormat:@"%@ - %@",nsuti,(NSString*)cfutidesc]];
				CFRelease(cfutidesc);
			}
			else
				[_uti_descs addObject:(NSString*)cfty];
		}
		CFRelease(cfutis);
	}
	return _utis;
}

-(NSArray*)uti_descs
{
	if (!_uti_descs)
		[self utis];
	return _uti_descs;
}

-(NSArray*)file_suffixes
{
	if (!_suffixes)
		[self utis];
	return _suffixes;
}

-(NSString*)chosenSuffix
{
    return [self file_suffixes][selectedUTI];
}
- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel
{
	[fileTypeMenu removeAllItems];
	[fileTypeMenu addItemsWithTitles:[self uti_descs]];
	NSString *utiString = [[NSUserDefaults standardUserDefaults]objectForKey:@"imageexportcontrolleruti"];
	if (utiString)
	{
		NSUInteger i = [[self utis]indexOfObject:utiString];
		if (i != NSNotFound)
			selectedUTI = i;
	}
	[fileTypeMenu selectItemAtIndex:selectedUTI];
	[savePanel setAccessoryView:_accessoryView];
	//[savePanel setRequiredFileType:[[self utis] objectAtIndex:selectedUTI]];
    if (!self.ignoreSavePanel)
        [savePanel setAllowedFileTypes:[NSArray arrayWithObject:[[self utis] objectAtIndex:selectedUTI]]];
	[compressionQualitySlider setFloatValue:compressionQuality];
	[compressionQualityTextField setFloatValue:compressionQuality];
    return YES;
}

-(void)enableControls
{
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
	if (!maintainAspectRatio)
		return;
	id obj = [aNotification object];
	if (obj == imageWidthTextField)
	{
		int newVal  = [imageWidthTextField intValue] / aspect;
		if (newVal != imageHeight)
			self.imageHeight = newVal;
	}
	else if (obj == imageHeightTextField)
	{
		int newVal  = [imageHeightTextField intValue] * aspect;
		if (newVal != imageWidth)
			self.imageWidth = newVal;
	}
}

- (IBAction)fileTypeMenuHit:(id)sender
{
	selectedUTI = [sender indexOfSelectedItem];
    if (!self.ignoreSavePanel)
        [(NSSavePanel*)[_accessoryView window] setAllowedFileTypes:[NSArray arrayWithObject:[[self file_suffixes] objectAtIndex:selectedUTI]]];
	[[NSUserDefaults standardUserDefaults]setObject:[[self utis] objectAtIndex:selectedUTI] forKey:@"imageexportcontrolleruti"];
}

- (IBAction)compressionQualitySliderHit:(id)sender
{
	float f = [sender floatValue];
	if (f != compressionQuality)
	{
		compressionQuality = f;
		[compressionQualityTextField setFloatValue:f];
	}
}

- (IBAction)compressionQualityTextFieldHit:(id)sender
{
	float f = [sender floatValue];
	if (f != compressionQuality)
	{
		compressionQuality = f;
		[compressionQualitySlider setFloatValue:f];
	}
}

-(NSString*)uti
{
	return [[self utis] objectAtIndex:selectedUTI];
}

-(void)setControls:(NSMutableDictionary*)exportImageSettings
{
	if (exportImageSettings)
	{
		compressionQuality = [[exportImageSettings objectForKey:@"compressionQuality"]floatValue];
		[compressionQualitySlider setFloatValue:compressionQuality];
		[compressionQualityTextField setFloatValue:compressionQuality];
		selectedUTI = [[exportImageSettings objectForKey:@"UTIindex"]intValue];
		self.imageWidth = [[exportImageSettings objectForKey:@"imageWidth"]intValue];
		self.imageHeight = [[exportImageSettings objectForKey:@"imageHeight"]intValue];
		self.maintainAspectRatio = [[exportImageSettings objectForKey:@"maintainAspectRatio"]boolValue];
		aspect = imageWidth * 1.0 / imageHeight;
	}
	[self enableControls];
}

-(void)updateSettingsFromControls:(NSMutableDictionary*)exportImageSettings
{
	[[_accessoryView window]makeFirstResponder:_accessoryView];
	[exportImageSettings setObject:[NSNumber numberWithFloat:[compressionQualitySlider floatValue]] forKey:@"compressionQuality"];
	[exportImageSettings setObject:[NSNumber numberWithInteger:self.imageWidth] forKey:@"imageWidth"];
	[exportImageSettings setObject:[NSNumber numberWithInteger:self.imageHeight] forKey:@"imageHeight"];
	[exportImageSettings setObject:[NSNumber numberWithBool:self.maintainAspectRatio] forKey:@"maintainAspectRatio"];
	[exportImageSettings setObject:[self uti] forKey:@"filetype"];
}


@end
