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
NSString *prefsImageLibs = @"ACSDrawprefsImageLibs";
NSString *prefsDocScale = @"ACSDrawprefsDocScale";
NSString *prefsDocSizeWidth = @"ACSDrawprefsDocSizeWidth";
NSString *prefsDocSizeHeight = @"ACSDrawprefsDocSizeHeight";
NSString *prefsDocRepeatScale = @"ACSDrawprefsDocRepeatScale";
NSString *prefsDocSizeRow = @"ACSDrawprefsDocSizeRow";
NSString *prefsDocSizeColumn = @"ACSDrawprefsDocSizeColumn";
NSString *prefSVGInlineEmbedded = @"prefsSVGInlineEmbedded";
NSString *prefsBatchScalePage = @"ACSDrawprefsBatchscalePage";
NSString *prefsBatchScaleLayer = @"ACSDrawprefsBatchscaleLayer";
NSString *prefsBatchScaleObject = @"ACSDrawprefsBatchscaleObject";
NSString *prefsBatchScaleScale = @"ACSDrawprefsBatchscaleScale";

NSString *ixPBType = @"indexpbtype";
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
                        dictionaryWithObjectsAndKeys:archivedObject([NSColor cyanColor]),prefsSelectionColourKey,
                       archivedObject([NSColor purpleColor]),prefsGuideColourKey,
                       archivedObject([NSColor redColor]),prefsHiliteColourKey,
                        @(4),prefsSnapSizeKey,
                        @(20),prefsHotSpotSizeKey,
                        @(PDF_LINK_STROKE),prefsPDFLinkModeKey,
                        @(PDF_LINK_STROKE),prefsPDFLinkStrokeKey,
                        archivedObject([[NSColor redColor]colorWithAlphaComponent:0.25]),prefsPDFLinkColourKey,
                        @(BACKGROUND_DRAW_COLOUR),prefsBackgroundType,
                        archivedObject([NSColor whiteColor]),prefsBackgroundColour,
                       @NO,prefsShowPathDirection,
                       @(1),prefsDocScale,
                       @[@"/"],prefsImageLibs,
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
	return @[[NSNumber numberWithFloat:[col redComponent]],[NSNumber numberWithFloat:[col greenComponent]],[NSNumber numberWithFloat:[col blueComponent]],[NSNumber numberWithFloat:[col alphaComponent]]];
   }

NSColor *colourFromArray(NSArray* arr)
   {
	return [NSColor colorWithDeviceRed:[arr[0]floatValue] green:[arr[1]floatValue]blue:[arr[2]floatValue]alpha:[arr[3]floatValue]];
   }

- (IBAction)pdfLinkHighlightingColourWellHit:(id)sender
   {
	[[NSUserDefaults standardUserDefaults] setObject:archivedObject([sender color]) forKey:prefsPDFLinkColourKey];
   }

- (IBAction)pdfLinkHighlightingStrokeHit:(id)sender
   {
	[[NSUserDefaults standardUserDefaults] setObject:@([sender floatValue]) forKey:prefsPDFLinkStrokeKey];
   }

- (IBAction)pdfLinkHighlightingMatrixhit:(id)sender
   {
	NSUInteger sel = [sender selectedRow];
	if (sel > 0)
		sel = 1 << (sel - 1);
	[[NSUserDefaults standardUserDefaults] setObject:@(sel) forKey:prefsPDFLinkModeKey];
   }

- (IBAction)guideColourHit:(id)sender
   {
	[[NSUserDefaults standardUserDefaults] setObject:archivedObject([sender color]) forKey:prefsGuideColourKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDGuideColourDidChangeNotification object:self 
                                                      userInfo:@{@"col":[sender color]}];
   }

- (IBAction)hotSpotSizeHit:(id)sender
   {
	[[NSUserDefaults standardUserDefaults] setObject:@([sender intValue]) forKey:prefsHotSpotSizeKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDHotSpotSizeDidChangeNotification object:self 
		userInfo:[NSDictionary dictionaryWithObject:@([sender intValue]) forKey:@"n"]];
   }

NSData *archivedObject(id obj)
{
    return [NSArchiver archivedDataWithRootObject:obj];
}

- (IBAction)selectionColourHit:(id)sender
   {
	[[NSUserDefaults standardUserDefaults] setObject:archivedObject([sender color]) forKey:prefsSelectionColourKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDSelectionColourDidChangeNotification object:self 
		userInfo:[NSDictionary dictionaryWithObject:(NSColor*)[sender color]forKey:@"col"]];
   }

- (IBAction)hiliteColourHit:(id)sender
   {
	[[NSUserDefaults standardUserDefaults] setObject:archivedObject([sender color]) forKey:prefsHiliteColourKey];
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
	[[NSUserDefaults standardUserDefaults] setObject:archivedObject([sender color]) forKey:prefsBackgroundColour];
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
	[[NSUserDefaults standardUserDefaults] setObject:@([sender intValue]) forKey:prefsSnapSizeKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDSnapSizeDidChangeNotification object:self 
		userInfo:[NSDictionary dictionaryWithObject:@([sender intValue]) forKey:@"n"]];
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
    [imageLibTableView registerForDraggedTypes:@[ixPBType]];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSArray *libs = [[NSUserDefaults standardUserDefaults] objectForKey:prefsImageLibs];
    return [libs count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSArray *libs = [[NSUserDefaults standardUserDefaults] objectForKey:prefsImageLibs];
    if (row < [libs count])
        return libs[row];
    return nil;
}

- (BOOL)tablexView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self selectDir:row];
    });
    
    return YES;
}

- (void)selectDir:(NSInteger)row
{
    NSMutableArray *libs = [[[NSUserDefaults standardUserDefaults] objectForKey:prefsImageLibs]mutableCopy];
    NSString *path = libs[row];
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    NSURL *u = [NSURL fileURLWithPath:path];
    if (u)
        [panel setDirectoryURL:u];
    [panel beginSheetModalForWindow:[self.openAfterExportCB window]
                  completionHandler:^(NSInteger result)
     {
         if (result == NSModalResponseOK)
         {
             for (NSURL *url in [panel URLs])
                 libs[row] = [url path];
         }
         [[NSUserDefaults standardUserDefaults]setObject:libs forKey:prefsImageLibs];
     }];
}
- (IBAction)imagePlusHit:(id)sender
{
    NSInteger row = [imageLibTableView selectedRow];
    NSMutableArray *libs = [[[NSUserDefaults standardUserDefaults] objectForKey:prefsImageLibs]mutableCopy];
    [libs insertObject:@"/" atIndex:row + 1];
    [[NSUserDefaults standardUserDefaults]setObject:libs forKey:prefsImageLibs];
    [imageLibTableView reloadData];
}
- (IBAction)imageMinusHit:(id)sender
{
    NSInteger row = [imageLibTableView selectedRow];
    NSMutableArray *libs = [[[NSUserDefaults standardUserDefaults] objectForKey:prefsImageLibs]mutableCopy];
    if (row > -1 && row < [libs count])
    {
        [libs removeObjectAtIndex:row];
        [[NSUserDefaults standardUserDefaults]setObject:libs forKey:prefsImageLibs];
        [imageLibTableView reloadData];
    }
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self selectDir:row];
    });
    
    return NO;

}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    return [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:rowIndexes] forType:ixPBType];
}

- (NSDragOperation)tableView:(NSTableView*)tabView validateDrop:(id <NSDraggingInfo>)info
                 proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    if (operation == NSTableViewDropOn)
        return  NSDragOperationNone;
    else
        return NSDragOperationMove;
}

static void MoveRowsFromIndexSetToPosition(NSMutableArray* arr,NSIndexSet *ixs,NSInteger pos)
{
    NSArray *temparr = [arr objectsAtIndexes:ixs];
    NSUInteger ind = [ixs lastIndex];
    while (ind != NSNotFound && ind >= pos)
    {
        [arr removeObjectAtIndex:ind];
        ind = [ixs indexLessThanIndex:ind];
    }
    [arr insertObjects:temparr atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(pos, [temparr count])]];
    while (ind != NSNotFound)
    {
        [arr removeObjectAtIndex:ind];
        ind = [ixs indexLessThanIndex:ind];
    }
}

- (BOOL)tableView:(NSTableView*)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:ixPBType];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    NSMutableArray *libs = [[[NSUserDefaults standardUserDefaults] objectForKey:prefsImageLibs]mutableCopy];
    MoveRowsFromIndexSetToPosition(libs,rowIndexes,row);
    [[NSUserDefaults standardUserDefaults]setObject:libs forKey:prefsImageLibs];
    [imageLibTableView reloadData];
    return YES;
}

@end
