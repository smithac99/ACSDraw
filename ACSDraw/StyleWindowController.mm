#import "StyleWindowController.h"
#import "TableSource.h"
#import "GraphicView.h"
#import "ACSDrawDocument.h"
#import "ACSDStyle.h"
#import "ACSDText.h"
#import "ACSDTableView.h"

@implementation StyleWindowController

+ (id)sharedStyleWindowController
   {
    static StyleWindowController *sharedStyleWindowController = nil;
	if (!sharedStyleWindowController)
        sharedStyleWindowController = [[StyleWindowController alloc]init];
    return sharedStyleWindowController;
   }

+ (NSMutableArray*)defaultFontSizes
   {
	float f[] = {8.0,9.0,10.0,12.0,14.0,18.0,24.0,36.0,64.0};
	NSMutableArray *m = [NSMutableArray arrayWithCapacity:20];
	for (unsigned i = 0;i < (sizeof(f)/sizeof(float));i++)
		[m addObject:[NSNumber numberWithFloat:f[i]]];
	return m;
   }

- (id)init
   {
    if ((self = [self initWithWindowNibName:@"StylePanel"]))
	   {
        [self setWindowFrameAutosaveName:@"StylePanel"];
       }
    return self;
   }

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(GraphicView*)inspectingGraphicView
   {
	return inspectingGraphicView;
   }

- (BOOL)setActionsDisabled:(BOOL)disabled
   {
	BOOL temp = actionsDisabled;
	actionsDisabled = disabled;
	return temp;
   }

- (BOOL)actionsDisabled
   {
    return actionsDisabled;
   }

-(NSUndoManager*)undoManager
   {
	if (inspectingGraphicView)
		return [inspectingGraphicView undoManager];
	return nil;
   }

-(void)setControlsForStyle:(ACSDStyle*)style
   {
	NSString *fontFace = [style fontFace];
	NSString *fontFamilyName = [[NSFont fontWithName:fontFace size:[style fontPointSize]]familyName];
	NSArray *fontNames = [fontFamilyTableSource objectList];
	NSUInteger ind = [fontNames indexOfObject:fontFamilyName];
	if (ind != NSNotFound)
	   {
		[[fontFamilyTableSource tableView]selectRowIndexes:[NSIndexSet indexSetWithIndex:ind]byExtendingSelection:NO];
		[[fontFamilyTableSource tableView]scrollRowToVisible:ind];
		NSArray *faces = [[NSFontManager sharedFontManager] availableMembersOfFontFamily:fontFamilyName];
		[faceTableSource setObjectList:(id)faces];
		ind = 0;
		for (NSUInteger i = 0,ct = [faces count];i < ct;i++)
			if ([[[faces objectAtIndex:i]objectAtIndex:0]isEqualToString:fontFace])
			   {
				ind = i;
				break;
			   }
		[[faceTableSource tableView]selectRowIndexes:[NSIndexSet indexSetWithIndex:ind]byExtendingSelection:NO];
		[[faceTableSource tableView]scrollRowToVisible:ind];
	   }
	float fontPointSize = [style fontPointSize];
	NSArray *fontSizes = [fontSizeTableSource objectList];
	ind = [fontSizes indexOfObject:[NSNumber numberWithFloat:fontPointSize]];
	if (ind == NSNotFound)
	   {
		[sizeText setFloatValue:fontPointSize];
		[[fontSizeTableSource tableView]selectRowIndexes:[NSIndexSet indexSet]byExtendingSelection:NO];
	   }
	else
	   {
		[[fontSizeTableSource tableView]selectRowIndexes:[NSIndexSet indexSetWithIndex:ind]byExtendingSelection:NO];
		[[fontSizeTableSource tableView]scrollRowToVisible:ind];
		[sizeText setObjectValue:@""];
	   }
	NSColor *col = [style foregroundColour];
	if (col)
		[foregroundColourWell setColor:col];
	else
		[foregroundColourWell setColor:[NSColor blackColor]];
	NSTextAlignment a = [style textAlignment];
	int just;
	switch(a)
	   {
           case NSTextAlignmentCenter:
			just = 1;
			break;
           case NSTextAlignmentRight:
			just = 2;
			break;
		case NSJustifiedTextAlignment:
			just = 3;
			break;
		default:
			just = 0;
			break;
	   }
	[justifyMatrix selectCellAtRow:0 column:just];
	[firstIndent setFloatValue:[style floatValueForKey:StyleFirstIndent]];
	[leading setFloatValue:[style floatValueForKey:StyleLeading]];
	[leftIndent setFloatValue:[style floatValueForKey:StyleLeftIndent]];
	[rightIndent setFloatValue:[style floatValueForKey:StyleRightIndent]];
	[spaceAfter setFloatValue:[style floatValueForKey:StyleSpaceAfter]];
	[spaceBefore setFloatValue:[style floatValueForKey:StyleSpaceBefore]];
	ACSDStyle *bo = [style basedOn];
	[basedOnReset setEnabled:(bo !=nil)];
	if (bo)
	   {
		ind = [[styleTableSource objectList]indexOfObjectIdenticalTo:bo];
		[[basedOnTableSource tableView]selectRowIndexes:[NSIndexSet indexSetWithIndex:ind]byExtendingSelection:NO];
	   }
	else
	   {
		[[basedOnTableSource tableView]selectRowIndexes:[NSIndexSet indexSetWithIndex:0]byExtendingSelection:NO];
	   }
	[[basedOnTableSource tableView]scrollRowToVisible:ind];
	[genHelpCB setIntValue:style.generateAppleHelp];
   }

- (void)refreshControls
   {
	BOOL temp = [self setActionsDisabled:YES];
	[self setControlsForStyle:[[styleTableSource objectList]objectAtIndex:[[styleTableSource tableView] selectedRow]]];
	[self setActionsDisabled:temp];
   }

- (void)setControls
   {
	[styleTableSource setObjectList:[[inspectingGraphicView document]styles]];
	[basedOnTableSource setObjectList:[[inspectingGraphicView document]styles]];
	if ([[self inspectingGraphicView]editingGraphic])
		[self textSelectionChanged:nil];
	else
		[self refreshControls];
   }

- (void)zeroControls
   {
   }

- (void)setMainWindow:(NSWindow *)mainWindow
   {
    if (mainWindow == nil)
	   {
		BOOL temp = [self setActionsDisabled:YES];
		[self setActionsDisabled:YES];
		[self zeroControls];
		[self setActionsDisabled:temp];
		inspectingGraphicView = nil;
		return;
	   }
	BOOL temp = [self setActionsDisabled:YES];
	id controller = [mainWindow windowController];
    if (controller && [controller respondsToSelector:@selector(graphicView)])
        inspectingGraphicView = [controller graphicView];
    else
		inspectingGraphicView = nil;
	[self setControls];
	[self setActionsDisabled:temp];
   }


- (void)mainWindowChanged:(NSNotification *)notification
   {
    [self setMainWindow:[notification object]];
   }

- (void)mainWindowResigned:(NSNotification *)notification
   {
    [self setMainWindow:nil];
   }
 
- (void)textSelectionChanged:(NSNotification *)notification
   {
	if ([self inspectingGraphicView])
	   {
		ACSDGraphic *edg = [[self inspectingGraphicView]editingGraphic];
		if (edg)
		   {
			NSTextView *textView = [[self inspectingGraphicView]editor];
			NSTextStorage *textStorage = [textView textStorage];
			NSMutableSet *styleSet = [NSMutableSet setWithCapacity:5];
			ACSDStyle *style;
			NSArray *rangeArray = [textView selectedRanges];
			for (unsigned i = 0;i < [rangeArray count];i++)
			   {
				NSRange r = [[rangeArray objectAtIndex:i]rangeValue];
				NSRange longestRange;
				if (r.location < [textStorage length])
					style = [textStorage attribute:StyleAttribute atIndex:r.location longestEffectiveRange:&longestRange inRange:r];
				else
					style = [[textView typingAttributes]objectForKey:StyleAttribute];
				if (style)
					[styleSet addObject:style];
				else
					[styleSet addObject:[[styleTableSource objectList]objectAtIndex:0]];
			   }
			if ([styleSet count] == 1)
			   {
				style = [[styleSet allObjects]objectAtIndex:0];
				NSUInteger ind = [[styleTableSource objectList] indexOfObjectIdenticalTo:style];
				if (ind != NSNotFound)
				   {
					BOOL temp = [self setActionsDisabled:YES];
					[[styleTableSource tableView]selectRowIndexes:[NSIndexSet indexSetWithIndex:ind]byExtendingSelection:NO];
					[[styleTableSource tableView]scrollRowToVisible:ind];
					[self refreshControls];
					[self setActionsDisabled:temp];
				   }
			   }
			else
			   {
				BOOL temp = [self setActionsDisabled:YES];
				[[styleTableSource tableView]selectRowIndexes:[NSIndexSet indexSetWithIndex:0]byExtendingSelection:NO];
				[self refreshControls];
				[self setActionsDisabled:temp];
			   }
		   }
	   }
   }

- (void)windowDidLoad
   {
    [super windowDidLoad];
	[[self window]setOpaque:NO];
	[[self window]setBackgroundColor:[[NSColor blackColor]colorWithAlphaComponent:0.5]];
    [(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowChanged:) name:NSWindowDidBecomeMainNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowResigned:) name:NSWindowDidResignMainNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textSelectionChanged:) name:ACSDGraphicViewTextSelectionDidChangeNotification object:nil];
	NSMutableArray *m = [NSMutableArray arrayWithCapacity:100];
	[m addObjectsFromArray:[[NSFontManager sharedFontManager]availableFontFamilies]];
	[m sortUsingSelector:@selector(compare:)];
	[fontFamilyTableSource setObjectList:m];
	[fontSizeTableSource setObjectList:[StyleWindowController defaultFontSizes]];
    [self setMainWindow:[NSApp mainWindow]];
   }

-(ACSDStyle*)currentStyle
   {
	if (![self inspectingGraphicView])
		return nil;
	NSInteger ind = [[styleTableSource tableView] selectedRow];
	if (ind == -1)
		return nil;
	return [[[inspectingGraphicView document]styles]objectAtIndex:ind];
   }

-(ACSDStyle*)currentBasedOnStyle
   {
	if (![self inspectingGraphicView])
		return nil;
	NSInteger ind = [[basedOnTableSource tableView] selectedRow];
	if (ind == -1)
		return nil;
	return [[[inspectingGraphicView document]styles]objectAtIndex:ind];
   }

-(void)uSetAttributes:(NSMutableDictionary*)dict forStyle:(ACSDStyle*)st
   {
	if (!st)
		return;
	[[[self undoManager] prepareWithInvocationTarget:self] uSetAttributes:[st attributes] forStyle:st];
	NSDictionary *copyAttr = [[st attributes]copy];
	[st setAttributes:dict];
	[self refreshControls];
	if ([self inspectingGraphicView])
		[[self inspectingGraphicView]updateForStyle:st oldAttributes:copyAttr];
   }

-(void)uSetStyle:(ACSDStyle*)st fontPointSize:(float)f
   {
	if (!st)
		return;
	[[[self undoManager] prepareWithInvocationTarget:self] uSetStyle:st fontPointSize:[st fontPointSize]];
	NSDictionary *copyAttr = [[st attributes]copy];
	[st setFontPointSize:f];
	[self refreshControls];
	if ([self inspectingGraphicView])
		[[self inspectingGraphicView]updateForStyle:st oldAttributes:copyAttr];
   }

- (void)fontSizeTableSelectionChange:(NSInteger)row
   {
	if (row == -1)
		return;
	float f = [[[fontSizeTableSource objectList] objectAtIndex:row]floatValue];
	if (![self inspectingGraphicView])
		return;
	ACSDStyle *st = [self currentStyle];
	if (st)
	   {
		[self uSetStyle:st fontPointSize:f];
		[[self undoManager] setActionName:@"Set Style Font Family"];	
	   }
   }

-(void)uSetStyle:(ACSDStyle*)st fontFace:(NSString*)f
   {
	if (!st)
		return;
	[[[self undoManager] prepareWithInvocationTarget:self] uSetStyle:st fontFace:[st fontFace]];
	NSDictionary *copyAttr = [[st attributes]copy];
	[st setFontFace:f];
	[self refreshControls];
	if ([self inspectingGraphicView])
		[[self inspectingGraphicView]updateForStyle:st oldAttributes:copyAttr];
   }

- (void)faceTableSelectionChange:(NSInteger)row
   {
	if (row == -1)
		return;
	if (![self inspectingGraphicView])
		return;
	NSString *face = [[[faceTableSource objectList] objectAtIndex:row]objectAtIndex:0];
	ACSDStyle *st = [self currentStyle];
	if (st)
	   {
		[self uSetStyle:st fontFace:face];
		[[self undoManager] setActionName:@"Set Style Font Face"];	
	   }
   }


-(BOOL)uSetStyle:(ACSDStyle*)st generateAppleHelp:(BOOL)b
{
	if (!st)
		return NO;
	if (st.generateAppleHelp == b)
		return NO;
	[[[self undoManager] prepareWithInvocationTarget:self] uSetStyle:st generateAppleHelp:st.generateAppleHelp];
	st.generateAppleHelp = b;
	[self refreshControls];
	return YES;
}

- (IBAction)genHelpCBHit:(id)sender
{
	if (![self inspectingGraphicView])
		return;
	ACSDStyle *st = [self currentStyle];
	if (!st)
		return;
	if ([self uSetStyle:st generateAppleHelp:[genHelpCB intValue]])
		[[self undoManager] setActionName:@"Set Style Generate Apple Help"];
}

-(void)uSetStyle:(ACSDStyle*)st name:(NSString*)n
   {
	if (!st)
		return;
	if ([[st name] isEqual:n])
		return;
	[[[self undoManager] prepareWithInvocationTarget:self] uSetStyle:st name:[st name]];
	[st setName:n];
	[[styleTableSource tableView]reloadData];
	[[self undoManager] setActionName:@"Set Style Name"];	
   }

-(void)uSetStyle:(ACSDStyle*)st justification:(NSTextAlignment)a
   {
	if (!st)
		return;
	[[[self undoManager] prepareWithInvocationTarget:self] uSetStyle:st justification:[st textAlignment]];
	NSDictionary *copyAttr = [[st attributes]copy];
	[st setTextAlignment:a];
//	[self refreshControls];
	if ([self inspectingGraphicView])
		[[self inspectingGraphicView]updateForStyle:st oldAttributes:copyAttr];
   }

-(void)uSetStyle:(ACSDStyle*)st attribute:(NSString*)attrName value:(id)value
   {
	if (!st)
		return;
	[[[self undoManager] prepareWithInvocationTarget:self] uSetStyle:st attribute:attrName value:[st attributeForKey:attrName]];
	NSDictionary *copyAttr = [[st attributes]copy];
	[st setAttribute:value forKey:attrName];
	if ([self inspectingGraphicView])
		[[self inspectingGraphicView]updateForStyle:st oldAttributes:copyAttr];
   }

-(void)floatAttributeHit:(float)val attrName:(NSString*)attrName undoName:(NSString*)undoName
   {
	ACSDStyle *st = [self currentStyle];
	if (st && val != [st floatValueForKey:attrName])
	   {
		[self uSetStyle:[self currentStyle] attribute:attrName value:[NSNumber numberWithFloat:val]];
		[[self undoManager] setActionName:undoName];	
	   }
   }

- (IBAction)firstIndentHit:(id)sender
   {
	[self floatAttributeHit:[sender floatValue] attrName:StyleFirstIndent undoName:@"Set First Indent"];
   }

- (IBAction)leadingHit:(id)sender
   {
	[self floatAttributeHit:[sender floatValue] attrName:StyleLeading undoName:@"Set Leading"];
   }

- (IBAction)leftIndentHit:(id)sender
   {
	[self floatAttributeHit:[sender floatValue] attrName:StyleLeftIndent undoName:@"Set Left Indent"];
   }

- (IBAction)rightIndentHit:(id)sender
   {
	[self floatAttributeHit:[sender floatValue] attrName:StyleRightIndent undoName:@"Set Right Indent"];
   }

- (IBAction)spaceAfterHit:(id)sender
   {
	[self floatAttributeHit:[sender floatValue] attrName:StyleSpaceAfter undoName:@"Set Space After"];
   }

- (IBAction)spaceBeforeHit:(id)sender
   {
	[self floatAttributeHit:[sender floatValue] attrName:StyleSpaceBefore undoName:@"Set SpaceAfter"];
   }

- (IBAction)justifyMatrixHit:(id)sender
   {
	int just = (int)[justifyMatrix selectedColumn];
	NSTextAlignment align=NSTextAlignmentLeft;
	switch(just)
	   {
		case 0:
               align = NSTextAlignmentLeft;
			break;
		case 1:
               align = NSTextAlignmentCenter;
			break;
		case 2:
               align = NSTextAlignmentRight;
			break;
		case 3:
               align = NSTextAlignmentJustified;
			break;
	   }
	ACSDStyle *st = [self currentStyle];
	if (st)
	   {
		[self uSetStyle:st justification:align];
		[[self undoManager] setActionName:@"Set Style Justification"];	
	   }
   }

-(void)uSetStyle:(ACSDStyle*)st basedOnStyle:(ACSDStyle*)bost
   {
	if (!st)
		return;
	[[[self undoManager] prepareWithInvocationTarget:self] uSetStyle:st basedOnStyle:[st basedOn]];
	NSDictionary *copyAttr = [[st attributes]copy];
	[st setBasedOn:bost];
	[self refreshControls];
	if ([self inspectingGraphicView])
		[[self inspectingGraphicView]updateForStyle:st oldAttributes:copyAttr];
   }

- (IBAction)basedOnResetHit:(id)sender
   {
	if (![self inspectingGraphicView])
		return;
	ACSDStyle *st = [self currentStyle];
	if (!st)
		return;
	if (![st basedOn])
		return;
	[self uSetAttributes:[NSMutableDictionary dictionaryWithCapacity:10] forStyle:st];
	[[self undoManager] setActionName:@"Reset Style"];	
   }

-(void)uSetStyle:(ACSDStyle*)st foregroundColour:(NSColor*)col
   {
	if (!st)
		return;
	[[[self undoManager] prepareWithInvocationTarget:self] uSetStyle:st foregroundColour:[st foregroundColour]];
	NSDictionary *copyAttr = [[st attributes]copy];
	[st setForegroundColour:col];
	[self refreshControls];
	if ([self inspectingGraphicView])
		[[self inspectingGraphicView]updateForStyle:st oldAttributes:copyAttr];
   }

- (IBAction)foregroundColourWellHit:(id)sender
   {
	if (![self inspectingGraphicView])
		return;
	ACSDStyle *st = [self currentStyle];
	if (!st)
		return;
	[self uSetStyle:st foregroundColour:[sender color]];
	[[self undoManager] setActionName:@"Set Colour"];	
   }

- (IBAction)sizeTextHit:(id)sender
   {
	float f = [sizeText floatValue];
	if (f == 0.0)
		return;
	if (![self inspectingGraphicView])
		return;
	ACSDStyle *st = [self currentStyle];
	if (st && [st fontPointSize] != f)
	   {
		[self uSetStyle:st fontPointSize:f];
		[[self undoManager] setActionName:@"Set Style Point Size"];	
	   }
   }

-(void)uDeleteStyleAtIndex:(NSInteger)row
   {
	[[[self undoManager] prepareWithInvocationTarget:self] uInsertStyle:[[styleTableSource objectList] objectAtIndex:row] atIndex:(int)row];
	[[styleTableSource objectList] removeObjectAtIndex:row];
	if (row > (int)[[styleTableSource objectList]count])
		[[styleTableSource tableView]selectRowIndexes:[NSIndexSet indexSetWithIndex:row-1]byExtendingSelection:NO];
	[[styleTableSource tableView]reloadData];
	[self refreshControls];
	if ([self inspectingGraphicView])
		[[self inspectingGraphicView]updateForStyle:[self currentStyle] oldAttributes:[NSDictionary dictionary]];
   }

-(void)uInsertStyle:(ACSDStyle*)st atIndex:(NSInteger)row
   {
	[[[self undoManager] prepareWithInvocationTarget:self] uDeleteStyleAtIndex:row+1];
	[[styleTableSource objectList]insertObject:st atIndex:row];
	[[styleTableSource tableView]selectRowIndexes:[NSIndexSet indexSetWithIndex:row]byExtendingSelection:NO];
	[[styleTableSource tableView]reloadData];
	[self refreshControls];
	if ([self inspectingGraphicView])
		[[self inspectingGraphicView]updateForStyle:st oldAttributes:[NSDictionary dictionary]];
   }

-(void)uInsertStyle:(ACSDStyle*)st
   {
	NSInteger ind = [[styleTableSource tableView] selectedRow];
	if (ind == -1)
		ind = [[styleTableSource objectList] count];
	else
		ind = ind + 1;
	[self uInsertStyle:st atIndex:ind];
   }

-(void)uUpdateStyle:(ACSDStyle*)st withAttributes:(NSMutableDictionary*)attr
   {
	if (st == nil)
		return;
	[[[self undoManager] prepareWithInvocationTarget:self] uUpdateStyle:st withAttributes:[st attributes]];
	NSDictionary *copyAttr = [[st attributes]copy];
	[st setAttributes:attr];
	[self refreshControls];
	if ([self inspectingGraphicView])
		[[self inspectingGraphicView]updateForStyle:st oldAttributes:copyAttr];
   }

-(void)uUpdateStyleWithAttributes:(NSMutableDictionary*)attr
   {
	ACSDStyle *st = [self currentStyle];
	if (st == nil)
		return;
	[self uUpdateStyle:st withAttributes:attr];
   }

- (IBAction)stylePlusHit:(id)sender
   {
	if (![self inspectingGraphicView])
		return;
	NSInteger row = [[styleTableSource tableView] selectedRow];
	if (row < 0)
		return;
	ACSDStyle *st = [[self currentStyle]copy];
	[[inspectingGraphicView document]registerObject:st];
	[st setName:[[st name]stringByAppendingString:@" copy"]];
	[self uInsertStyle:st atIndex:row+1];
	if (st)
	   {
		[[self undoManager] setActionName:@"Add Style"];	
	   }
   }

- (void)forceCurrentParaToStyle:(ACSDStyle*)style
   {
	if ([self inspectingGraphicView])
	   {
		ACSDGraphic *edg = [[self inspectingGraphicView]editingGraphic];
		if (edg)
		   {
			NSTextView *textView = [[self inspectingGraphicView]editor];
			NSArray *ranges = [textView rangesForUserParagraphAttributeChange];
			for (unsigned i = 0;i < [ranges count];i++)
			   {
				NSRange r = [[ranges objectAtIndex:i]rangeValue];
				[(ACSDText*)edg forceUpdateRange:r forStyle:style];
			   }
			[textView setTypingAttributes:[style textAndStyleAttributes]];
		   }
	   }
   }

- (IBAction)tableClicked:(id)sender
   {
       if (([sender selectedRowPriorToClick] == [sender clickedRow]) && ([sender modifierFlags] & NSEventModifierFlagOption))
	   {
		[self forceCurrentParaToStyle:[self currentStyle]];
	   }
   }

-(void)awakeFromNib
   {
	[[styleTableSource tableView]setTarget:self];
	[[styleTableSource tableView]setAction:@selector(tableClicked:)];
   }

- (IBAction)styleMinusHit:(id)sender
   {
   }

- (void)styleTableSelectionChange:(NSInteger)row
{
    BOOL altDown = ([(ACSDTableView*)[styleTableSource tableView] modifierFlags] & NSEventModifierFlagOption);
    [self refreshControls];
    if ([self inspectingGraphicView])
    {
        ACSDGraphic *edg = [[self inspectingGraphicView]editingGraphic];
        if (edg)
        {
            ACSDStyle *style = [self currentStyle];
            NSTextView *textView = [[self inspectingGraphicView]editor];
            NSArray *ranges = [textView rangesForUserParagraphAttributeChange];
            for (unsigned i = 0;i < [ranges count];i++)
            {
                NSRange r = [[ranges objectAtIndex:i]rangeValue];
                if (altDown)
                    [(ACSDText*)edg forceUpdateRange:r forStyle:style];
                else
                    [(ACSDText*)edg updateRange:r forNewStyle:style];
            }
            [textView setTypingAttributes:[style textAndStyleAttributes]];
        }
    }
}

-(void)uSetStyle:(ACSDStyle*)st fontFamily:(NSString*)ff
   {
	if (!st)
		return;
	[[[self undoManager] prepareWithInvocationTarget:self] uSetStyle:st fontFamily:[st fontFamily]];
	NSDictionary *copyAttr = [[st attributes]copy];
	NSInteger faceRow = [[faceTableSource tableView]selectedRow];
	NSString *fontFace = [[[faceTableSource objectList]objectAtIndex:faceRow]objectAtIndex:0];
	NSFont *font = [NSFont fontWithName:fontFace size:10];
	font = [[NSFontManager sharedFontManager]convertFont:font toFamily:ff];
	[st setFontFace:[font fontName]];
	[self refreshControls];
	if ([self inspectingGraphicView])
		[[self inspectingGraphicView]updateForStyle:st oldAttributes:copyAttr];
   }

- (void)fontFamilyTableSelectionChange:(NSInteger)row
   {
	NSString *fontFamily = [[fontFamilyTableSource objectList] objectAtIndex:row]; 
	if (![self inspectingGraphicView])
		return;
	ACSDStyle *st = [self currentStyle];
	if (st)
	   {
		[self uSetStyle:st fontFamily:fontFamily];
		[[self undoManager] setActionName:@"Set Style Font Family"];	
	   }
   }

- (void)basedOnTableSelectionChange:(NSInteger)row
   {
	if (![self inspectingGraphicView])
		return;
	ACSDStyle *bost = [[[inspectingGraphicView document]styles]objectAtIndex:row];
	if ([bost nullStyle])
		bost = nil;
	ACSDStyle *st = [self currentStyle];
	if (st)
	   {
		[self uSetStyle:st basedOnStyle:bost];
		[[self undoManager] setActionName:@"Set Based On"];	
	   }
   }

- (void)tableViewSelectionDidChange:(NSNotification *)notif
   {
	if ([self actionsDisabled])
		return;
	if ([notif object] == [fontFamilyTableSource tableView])
		[self fontFamilyTableSelectionChange:[[fontFamilyTableSource tableView] selectedRow]];
	else if ([notif object] == [styleTableSource tableView])
		[self styleTableSelectionChange:[[styleTableSource tableView] selectedRow]];
	else if ([notif object] == [fontSizeTableSource tableView])
		[self fontSizeTableSelectionChange:[[fontSizeTableSource tableView] selectedRow]];
	else if ([notif object] == [faceTableSource tableView])
		[self faceTableSelectionChange:[[faceTableSource tableView] selectedRow]];
	else if ([notif object] == [basedOnTableSource tableView])
		[self basedOnTableSelectionChange:[[basedOnTableSource tableView] selectedRow]];
   }

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
   {
	if (![self inspectingGraphicView])
		return NO;
	if (aTableView != [basedOnTableSource tableView])
		return YES;
	ACSDStyle *st =  [[[inspectingGraphicView document]styles]objectAtIndex:rowIndex];
	if ([[self currentStyle]nullStyle])
		return [st nullStyle];
	return [st nullStyle] || ![[self currentStyle]basedOnWouldCreateCycle:st];
   }

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
   {
	if (command == @selector(insertNewline:))
	   {
		[[self window]makeFirstResponder:control];
		return YES;
	   }
	return NO;
   }

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)sender
   {
	return [self undoManager];
   }


@end
