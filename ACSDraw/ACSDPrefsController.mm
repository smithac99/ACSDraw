#import <Quartz/Quartz.h>
#import "ACSDPrefsController.h"

NSString *ACSDGuideColourDidChangeNotification = @"ACSDGuideColourDidChange";
NSString *ACSDSelectionColourDidChangeNotification = @"ACSDSelectionColourDidChange";
NSString *ACSDHiliteColourDidChangeNotification = @"ACSDHiliteColourDidChange";
NSString *ACSDHotSpotSizeDidChangeNotification = @"ACSDHotSpotSizeDidChange";
NSString *ACSDSnapSizeDidChangeNotification = @"ACSDSnapSizeDidChange";
NSString *ACSDBackgroundColourChange = @"ACSDBackgroundColour";
NSString *ACSDBackgroundTypeChange = @"ACSDBackgroundType";


NSString *prefsGuideColourKey = @"ACSDrawGuideColour";
NSString *prefsSelectionColourKey = @"ACSDrawSelectionColour";
NSString *prefsHiliteColourKey = @"ACSDrawHiliteColour";
NSString *prefsSnapSizeKey = @"ACSDrawSnapSize";
NSString *prefsHotSpotSizeKey = @"ACSDrawHotSpotSize";
NSString *prefsPDFLinkModeKey = @"ACSDrawPDFLinkMode";
NSString *prefsPDFLinkStrokeKey = @"ACSDrawPDFLinkStroke";
NSString *prefsPDFLinkColourKey = @"ACSDrawPDFLinkColour";
NSString *prefsOpenAfterExportKey = @"ACSprefsOpenAfterExport";
NSString *prefsBackgroundType = @"ACSDrawBackgroundType";
NSString *prefsBackgroundColour = @"ACSDrawBackgroundColour";
NSString *prefsShowPathDirection = @"ACSDrawShowPathDirection";
NSString *prefsRenameString = @"ACSDrawRenameString";
NSString *prefsRenameStartFromString = @"ACSDrawRenameStringStart";
NSString *prefsRegexpPattern = @"ACSDrawprefsRegexpPattern";
NSString *prefsRegexpTemplate = @"ACSDrawprefsRegexpTemplate";

NSArray *arrayFromColour(NSColor *col);
NSColor *colourFromArray(NSArray* arr);

@implementation ACSDPrefsController

+ (id)sharedACSDPrefsController:(ACSDPrefsController*)controller
{
    static ACSDPrefsController *sharedACSDPrefsController = nil;
    if (controller)
        sharedACSDPrefsController = controller;
    return sharedACSDPrefsController;
}

+ (NSDictionary*)sharedDefaults
{
    static NSDictionary *appDefaults = nil;
	if (appDefaults == nil)
    {
		appDefaults = [NSDictionary
                        dictionaryWithObjectsAndKeys:[NSArchiver archivedDataWithRootObject:[NSColor cyanColor]],prefsSelectionColourKey,
                        [NSArchiver archivedDataWithRootObject:[NSColor purpleColor]],prefsGuideColourKey,
                        [NSArchiver archivedDataWithRootObject:[NSColor redColor]],prefsHiliteColourKey,
                        [NSNumber numberWithInt:4],prefsSnapSizeKey,
                        [NSNumber numberWithInt:20],prefsHotSpotSizeKey,
                        [NSNumber numberWithInt:PDF_LINK_STROKE],prefsPDFLinkModeKey,
                        [NSNumber numberWithFloat:PDF_LINK_STROKE],prefsPDFLinkStrokeKey,
                        [NSArchiver archivedDataWithRootObject:[[NSColor redColor]colorWithAlphaComponent:0.25]],prefsPDFLinkColourKey,
                        [NSNumber numberWithInt:BACKGROUND_DRAW_COLOUR],prefsBackgroundType,
                        [NSArchiver archivedDataWithRootObject:[NSColor whiteColor]],prefsBackgroundColour,
                        [NSNumber numberWithBool:NO],prefsShowPathDirection,
                        nil];
    }
	return appDefaults;
}

+ (void)initialize
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:[ACSDPrefsController sharedDefaults]];
    [CIPlugIn loadAllPlugIns];
}

-(NSButton*)openAfterExportCB
{
	return openAfterExportCB;
}

- (IBAction)openAfterExportCBHit:(id)sender
   {
	BOOL val = [(NSButton*)sender state];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:val] forKey:prefsOpenAfterExportKey];
   }

NSArray *arrayFromColour(NSColor *col)
   {
	col = [col colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
	return [NSArray arrayWithObjects:[NSNumber numberWithFloat:[col redComponent]],[NSNumber numberWithFloat:[col greenComponent]],[NSNumber numberWithFloat:[col blueComponent]],[NSNumber numberWithFloat:[col alphaComponent]],nil];
   }

NSColor *colourFromArray(NSArray* arr)
   {
	return [NSColor colorWithDeviceRed:[[arr objectAtIndex:0]floatValue] green:[[arr objectAtIndex:1]floatValue]blue:[[arr objectAtIndex:2]floatValue]alpha:[[arr objectAtIndex:3]floatValue]];
   }

- (IBAction)pdfLinkHighlightingColourWellHit:(id)sender
   {
	[[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:(NSColor*)[sender color]] forKey:prefsPDFLinkColourKey];
   }

- (IBAction)pdfLinkHighlightingStrokeHit:(id)sender
   {
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:[sender floatValue]] forKey:prefsPDFLinkStrokeKey];
   }

- (IBAction)pdfLinkHighlightingMatrixhit:(id)sender
   {
	NSUInteger sel = [sender selectedRow];
	if (sel > 0)
		sel = 1 << (sel - 1);
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:sel] forKey:prefsPDFLinkModeKey];
   }

- (IBAction)guideColourHit:(id)sender
   {
	[[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:(NSColor*)[sender color]] forKey:prefsGuideColourKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDGuideColourDidChangeNotification object:self 
		userInfo:[NSDictionary dictionaryWithObject:(NSColor*)[sender color]forKey:@"col"]];
   }

- (IBAction)hotSpotSizeHit:(id)sender
   {
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:[sender intValue]] forKey:prefsHotSpotSizeKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDHotSpotSizeDidChangeNotification object:self 
		userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[sender intValue]] forKey:@"n"]];
   }

- (IBAction)selectionColourHit:(id)sender
   {
	[[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:(NSColor*)[sender color]] forKey:prefsSelectionColourKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDSelectionColourDidChangeNotification object:self 
		userInfo:[NSDictionary dictionaryWithObject:(NSColor*)[sender color]forKey:@"col"]];
   }

- (IBAction)hiliteColourHit:(id)sender
   {
	[[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:(NSColor*)[sender color]] forKey:prefsHiliteColourKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDHiliteColourDidChangeNotification object:self 
													  userInfo:[NSDictionary dictionaryWithObject:(NSColor*)[sender color]forKey:@"col"]];
   }

- (NSColor*)selectionColour
   {
	return [selectionColour color];
   }

- (NSColor*)guideColour
   {
	return [guideColour color];
   }

- (NSColor*)hiliteColour
   {
	return [hiliteColour color];
   }

- (NSColor*)pdfLinkHighlightColour
   {
	return [pdfLinkHighlightingColourWell color];
   }

- (int)pdfLinkMode
   {
	NSNumber *num = [[NSUserDefaults standardUserDefaults] objectForKey:prefsPDFLinkModeKey];
	if (num)
		return [num intValue];
	return PDF_LINK_STROKE;
   }

- (float)pdfLinkStrokeSize
   {
	NSNumber *num = [[NSUserDefaults standardUserDefaults] objectForKey:prefsPDFLinkStrokeKey];
	if (num)
		return [num floatValue];
  	return 1.0;
   }

-(int)backgroundType
{
	return (int)[[NSUserDefaults standardUserDefaults]integerForKey:prefsBackgroundType];
}

- (IBAction)backgroundColourTypeHit:(id)sender
{
	NSInteger sel = [sender selectedRow];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLong:sel] forKey:prefsBackgroundType];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDBackgroundTypeChange object:self userInfo:nil];
}

-(NSColor*)backgroundColour
{
	id d = [[NSUserDefaults standardUserDefaults] objectForKey:prefsBackgroundColour];
	if (d)
		return [NSUnarchiver unarchiveObjectWithData:d];
	return nil;
}

-(BOOL)showPathDirection
{
    return [[NSUserDefaults standardUserDefaults]boolForKey:prefsShowPathDirection];
}

-(IBAction)toggleShowPathDirection:(id)sender
{
    [[NSUserDefaults standardUserDefaults]setBool:![[NSUserDefaults standardUserDefaults]boolForKey:prefsShowPathDirection] forKey:prefsShowPathDirection];
}

- (IBAction)backgroundColourHit:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:(NSColor*)[sender color]] forKey:prefsBackgroundColour];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDBackgroundColourChange object:self 
													  userInfo:[NSDictionary dictionaryWithObject:(NSColor*)[sender color]forKey:@"col"]];
}


- (int)snapSize
   {
	NSNumber *num = [[NSUserDefaults standardUserDefaults] objectForKey:prefsSnapSizeKey];
	if (num)
		return [num intValue];
	return 4;
   }

- (int)hotSpotSize
   {
	NSNumber *num = [[NSUserDefaults standardUserDefaults] objectForKey:prefsHotSpotSizeKey];
	if (num)
		return [num intValue];
	return 20;
   }

- (IBAction)snapSizehit:(id)sender
   {
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:[sender intValue]] forKey:prefsSnapSizeKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDSnapSizeDidChangeNotification object:self 
		userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[sender intValue]] forKey:@"n"]];
   }

-(void)setValuesFromGuidePrefsUndo:(BOOL)undo
{
	NSColor *col = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:prefsSelectionColourKey]];
	if (col)
		[selectionColour setColor:col];
	col = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:prefsGuideColourKey]];
	if (col)
		[guideColour setColor:col];
	col = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:prefsHiliteColourKey]];
	if (col)
		[hiliteColour setColor:col];
	
	int bgt = (int)[[NSUserDefaults standardUserDefaults]integerForKey:prefsBackgroundType];
	[backgroundColourTypeMatrix selectCellAtRow:bgt column:0];
}

-(void)setValuesFromSnapPrefsUndo:(BOOL)undo
   {
	NSNumber *num = [[NSUserDefaults standardUserDefaults] objectForKey:prefsSnapSizeKey];
	if (num)
		[snapSize setObjectValue:num];
	num = [[NSUserDefaults standardUserDefaults] objectForKey:prefsHotSpotSizeKey];
	if (num)
		[hotSpotSize setObjectValue:num];
   }

-(void)setValuesFromPDFPrefsUndo:(BOOL)undo
   {
	NSColor *col = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:prefsPDFLinkColourKey]];
	if (col)
		[pdfLinkHighlightingColourWell setColor:col];
	unsigned num = [[[NSUserDefaults standardUserDefaults] objectForKey:prefsPDFLinkModeKey]intValue];
	if (num > 0)
		num = 1 << num;
	[pdfLinkHighlightingMatrix selectCellAtRow:num column:0];
	id n = [[NSUserDefaults standardUserDefaults] objectForKey:prefsPDFLinkStrokeKey];
	if (n)
		[pdfLinkHighlightingStroke setObjectValue:n];
   }

-(void)setOtherValues
{
	BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:prefsOpenAfterExportKey];
	[openAfterExportCB setState:b];
}

-(void)awakeFromNib
   {
	[ACSDPrefsController sharedACSDPrefsController:self];
	[self setValuesFromGuidePrefsUndo:NO];
	[self setValuesFromSnapPrefsUndo:NO];
	[self setValuesFromPDFPrefsUndo:NO];
	[self setOtherValues];
   }


@end