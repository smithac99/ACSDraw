#import "StrokePanelController.h"
#import "ACSDGraphic.h"
#import "StrokeCell.h"
#import "DashFormatter.h"
#import "ArrowCell.h"
#import "ArrowListTableSource.h"
#import "ACSDLineEnding.h"
#import "ACSDMatrix.h"
#import "ACSDTableView.h"
#import "ArrayAdditions.h"
#import "DragView.h"
#import "PanelCoordinator.h"
#import "GraphicView.h"

StrokePanelController *_sharedStrokePanelController = nil;

@implementation StrokePanelController

+ (id)sharedStrokePanelController
{
	if (!_sharedStrokePanelController)
		[PanelCoordinator sharedPanelCoordinator];
    return _sharedStrokePanelController;
}

- (void)dealloc
{
    [self setStrokeList:nil];
	[matrixStrokeBox release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (NSMutableArray*)strokeList
{
	return strokeList;
}

- (NSTableView*)strokeTableView
{
	return strokeTableView;
}

- (void)setStrokeList:(NSMutableArray*)s
{
	if (strokeList)
		[strokeList autorelease];
	if (s)
		strokeList = [s retain];
	else
		strokeList = nil;
	[[strokeTableView dataSource]setStrokeList:s];
}

- (void)setLineEndingList:(NSMutableArray*)f
{
	if (lineEndingList)
		[lineEndingList autorelease];
	if (f)
		lineEndingList = [f retain];
	else
		lineEndingList = nil;
	[[arrowTableView dataSource]setArrowList:f];
}

- (void)zeroControls
{
	[arrowTableView setAllowsEmptySelection:YES];
	[strokeTableView setAllowsEmptySelection:YES];
	[self setStrokeList:nil];
	[strokeTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
	[strokeTableView reloadData];
	[self setLineEndingList:nil];
}

- (void)reloadLineEndings:(NSNotification *)notification
{
	[arrowTableView reloadData];
}

- (void)reloadStrokes:(NSNotification *)notification
{
	[strokeTableView reloadData];
}

- (void)setControlsForStroke:(ACSDStroke*)stroke
{
	BOOL flag;
	if (stroke == nil)
	   {
		BOOL temp = [self actionsDisabled];
		[self setActionsDisabled:YES];
		[arrowTableView setAllowsEmptySelection:YES];
		[strokeTableView setAllowsEmptySelection:YES];
		[strokeTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
		[arrowTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
		[self setActionsDisabled:temp];
		flag = NO;
	   }
	else
	   {
		flag = [stroke colour] != nil;
		[strokeSwitch setState:(flag ? NSOnState : NSOffState)];
		[strokeWell setColor:(flag ? [stroke colour] : [NSColor clearColor])];
		float lw = [stroke lineWidth];
		float eLineWidth = log(lw);
		if (eLineWidth > [lineWidthSlider maxValue])
			[lineWidthSlider setMaxValue:eLineWidth];
		[lineWidthSlider setFloatValue:eLineWidth];
		NSInteger startOrEnd = [arrowRBMatrix selectedRow];
		ACSDLineEnding *le;
		if (startOrEnd == START_OF_LINE)
			le = [stroke lineStart];
		else
			le = [stroke lineEnd];
		if (le == nil)
			[arrowTableView selectRow:0 byExtendingSelection:NO];
		else
		{
			NSUInteger i = [lineEndingList indexOfObjectIdenticalTo:le];
			if (i == NSNotFound)
				[arrowTableView selectRow:0 byExtendingSelection:NO];
			else
				[arrowTableView selectRow:i byExtendingSelection:NO];
		}
		[dashText setObjectValue:[stroke dashes]];
		[phaseText setFloatValue:[stroke dashPhase]];
		[capRBMatrix selectCellAtRow:[stroke lineCap] column:0];
	   }
	[strokeSwitch setEnabled:(stroke != nil)];
	[strokeWell setEnabled:flag];
	[lineWidthSlider setEnabled:flag];
	[arrowRBMatrix setEnabled:flag];
	[arrowTableView setEnabled:flag];
	[dashText setEnabled:flag];
	[phaseText setEnabled:flag];
	[capRBMatrix setEnabled:flag];
	[lineView setNeedsDisplay:YES];
}

- (void)selectAndSetControlsForStroke:(ACSDStroke*)stroke
{
	if (strokeList == nil)
		return;
	if (stroke != nil)
	   {
		NSInteger pos = [strokeList indexOfObject:stroke];
		if (pos == NSNotFound)
			return;
		[strokeTableView selectRow:pos byExtendingSelection:NO];
	   }
	[self setControlsForStroke:stroke];
}

-(void)setDocumentControls:(ACSDrawDocument*)doc
{
	[self setStrokeList:[doc strokes]];
	[self setLineEndingList:[doc lineEndings]];
}

-(void)setGraphicControls
{
	NSInteger ct = [[[self inspectingGraphicView] selectedGraphics] count];
	id g = nil;
	if (ct == 1)
		g = [[[[self inspectingGraphicView] selectedGraphics] allObjects]objectAtIndex:0];
	if (g)
	   {
		[self selectAndSetControlsForStroke:[g graphicStroke]];
		[strokeTableView setAllowsEmptySelection:NO];
		[arrowTableView setAllowsEmptySelection:NO];
		
	   }
	else if (ct == 0)
	   {
		if (strokeList)
		{
			NSInteger sel = [strokeTableView selectedRow];
			if (sel == -1)
			{
				[strokeTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
			}
			else
				[self setControlsForStroke:[strokeList objectAtIndex:sel]];
		}
	   }
	else
	   {
		NSArray *arr = [[[self inspectingGraphicView] selectedGraphics] allObjects];
		ACSDStroke *str = [(ACSDGraphic*)[arr objectAtIndex:0]stroke];
		if ([arr andMakeObjectsPerformSelector:@selector(graphicUsesStroke:) withObject:str])
			[self selectAndSetControlsForStroke:str];
//			[self setControlsForStroke:str];
		else
			[self setControlsForStroke:nil];
	   }
	[self showHideMatrixControls:g];
}

- (void)showHideMatrixControls:(ACSDGraphic *)graphic
{
	if (graphic && [graphic isKindOfClass:[ACSDMatrix class]])
	   {
		ACSDMatrix *mat = (ACSDMatrix*)graphic;
		if (![matrixStrokeBox superview])
			[matrixStrokeBoxSuperView addSubview:matrixStrokeBox positioned:NSWindowAbove relativeTo:nil];
		int rb = [mat strokeType];
		for (int i = 0;i < 3;i++)
		{
			NSCell *c = [matrixStrokeRB cellAtRow:i column:0];
			if (i == rb)
				[c setState:NSOnState];
			else
				[c setState:NSOffState];
		}
	   }
	else
	   {
		if ([matrixStrokeBox superview])
			[matrixStrokeBox removeFromSuperview];
	   }
}


-(void)awakeFromNib
{
	_sharedStrokePanelController = self;
	[dragView setLeft:0.0];
	[dragView setRight:50.0];
	[super awakeFromNib];
	rowForContextualMenu = -1;
	displayRowForContextualMenu = -1;
	[[dashText cell] setFormatter:[[[DashFormatter alloc]init]autorelease]];
	[[[strokeTableView tableColumns]objectAtIndex:0] setDataCell:[[[StrokeCell alloc]init]autorelease]];
	[[[arrowTableView tableColumns]objectAtIndex:0] setDataCell:[[[ArrowCell alloc]init]autorelease]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadLineEndings:) name:ACSDRefreshLineEndingsNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadStrokes:) name:ACSDRefreshStrokesNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unsetRowForContextualMenu:) name:NSMenuDidEndTrackingNotification object:nil];
	matrixStrokeBoxSuperView = [matrixStrokeBox superview];
	[matrixStrokeBox retain];
	
}

- (int)strokeRBValue
{
	if ([matrixStrokeBox superview])
	   {
		if ([[matrixStrokeRB cellAtRow:0 column:0]state] == NSOnState)
			return 0;
		else if ([[matrixStrokeRB cellAtRow:1 column:0]state] == NSOnState)
			return 1;
		else
			return 0;
	   }
	else
		return(0);
}


- (void)strokeTableSelectionChange:(NSInteger)row
{
	ACSDStroke *stroke = [strokeList objectAtIndex:row]; 
	[self setControlsForStroke:stroke];
	if (![self inspectingGraphicView])
		return;
	NSInteger count;
	BOOL changed = NO;
	if ((count = [[[self inspectingGraphicView] selectedGraphics] count]) > 0)
	   {
		NSArray *graphics = [[[self inspectingGraphicView] selectedGraphics] allObjects];
		for (int i = 0;i < count;i++)
		{
		    ACSDGraphic *graphic = [graphics objectAtIndex:i];
			changed = [graphic setGraphicStroke:stroke notify:NO] || changed;
		}
		if (changed)
			[[[self inspectingGraphicView] undoManager] setActionName:@"Change Stroke"];
	   }
	[[self inspectingGraphicView] setDefaultStroke:stroke];
}


- (void)arrowTableSelectionChange:(NSInteger)row
{
	ACSDLineEnding *le = [lineEndingList objectAtIndex:row];
	ACSDStroke *stroke = [strokeList objectAtIndex:[strokeTableView selectedRow]];
	NSInteger startOrEnd = [arrowRBMatrix selectedRow];
	if (startOrEnd == START_OF_LINE)
		[stroke changeLineStart:le view:[self inspectingGraphicView]];
	else
		[stroke changeLineEnd:le view:[self inspectingGraphicView]];
	[strokeTableView reloadData];
	[lineView setNeedsDisplay:YES];
}

-(void)duplicateLineEndingAtRow:(NSInteger)row
{
	ACSDLineEnding *le = [[lineEndingList objectAtIndex:row]copy];
	[lineEndingList insertObject:le atIndex:row + 1];
	[arrowTableView reloadData];
	[arrowTableView selectRow:row + 1 byExtendingSelection:NO];
}


- (IBAction)duplicateLineEnding:(id)sender
{
	if (rowForContextualMenu > -1)
		[self duplicateLineEndingAtRow:rowForContextualMenu];
}

-(void)duplicateStrokeAtRow:(NSInteger)row
{
	ACSDStroke *stroke = [[strokeList objectAtIndex:row]copy];
	[strokeList insertObject:stroke atIndex:row + 1];
	[strokeTableView reloadData];
	[strokeTableView selectRow:row + 1 byExtendingSelection:NO];
}

- (IBAction)duplicateStroke:(id)sender
{
	if (rowForContextualMenu > -1)
		[self duplicateStrokeAtRow:rowForContextualMenu];
}

- (void)deleteLineEndingAtIndex:(NSInteger)row
{
	if (!lineEndingList || ![self inspectingGraphicView])
		return;
	if (row < 0)
		return;
	if ([[lineEndingList objectAtIndex:row]nonDeletedCount] == 0)
	   {
		[[[self inspectingGraphicView] document]deleteLineEndingAtIndex:row];
		[[[self inspectingGraphicView] undoManager] setActionName:@"Delete Line Ending"];
	   }
}

- (IBAction)deleteLineEnding:(id)sender
{
	[self deleteLineEndingAtIndex:rowForContextualMenu];
}

- (void)deleteStrokeAtIndex:(NSInteger)row
{
	if (!strokeList || ![self inspectingGraphicView])
		return;
	if (row < 0)
		return;
	if ([[strokeList objectAtIndex:row]nonDeletedCount] == 0)
	   {
		[[[self inspectingGraphicView] document]deleteStrokeAtIndex:row];
		[[[self inspectingGraphicView] undoManager] setActionName:@"Delete Stroke"];
	   }
}

- (IBAction)deleteStroke:(id)sender
{
	[self deleteStrokeAtIndex:rowForContextualMenu];
}

- (IBAction)arrowRBHit:(id)sender
{
	ACSDStroke *stroke = [strokeList objectAtIndex:[strokeTableView selectedRow]];
	NSInteger startOrEnd = [arrowRBMatrix selectedRow];
	ACSDLineEnding *le;
	if (startOrEnd == START_OF_LINE)
		le = [stroke lineStart];
	else
		le = [stroke lineEnd];
	if (le == nil)
		[arrowTableView selectRow:0 byExtendingSelection:NO];
	else
	   {
		NSUInteger i = [lineEndingList indexOfObjectIdenticalTo:le];
		if (i == NSNotFound)
			[arrowTableView selectRow:0 byExtendingSelection:NO];
		else
			[arrowTableView selectRow:i byExtendingSelection:NO];
	   }
}

- (IBAction)strokeWellHit:(id)sender
{
    NSColor *color = [sender color];
	ACSDStroke *stroke = [strokeList objectAtIndex:[strokeTableView selectedRow]];
	if (![color isEqual:[stroke colour]])
	   {
        [stroke changeColour:color view:[self inspectingGraphicView]];
		[strokeTableView reloadData];
       }
}

- (IBAction)lineWidthSliderHit:(id)sender
{
	float elineWidth = [sender floatValue];
	float lineWidth;
	if (elineWidth == -2.0)
		lineWidth = 0.0;
	else
		lineWidth = exp(elineWidth);
	ACSDStroke *stroke = [strokeList objectAtIndex:[strokeTableView selectedRow]];
	if (lineWidth != [stroke lineWidth])
	   {
		[stroke changeLineWidth:lineWidth view:[self inspectingGraphicView]];
		[strokeTableView reloadData];
		[lineView setNeedsDisplay:YES];
	   }
}

- (IBAction)dashTextHit:(id)sender
{
	NSMutableArray *dashes = [sender objectValue];
	ACSDStroke *stroke = [strokeList objectAtIndex:[strokeTableView selectedRow]];
	[stroke setDashes:dashes view:[self inspectingGraphicView]];
	[strokeTableView reloadData];
	[lineView setNeedsDisplay:YES];
}

- (IBAction)phaseTextHit:(id)sender
{
	float phase = [sender floatValue];
	ACSDStroke *stroke = [strokeList objectAtIndex:[strokeTableView selectedRow]];
	if ([stroke dashPhase] != phase)
	   {
		[stroke changeDashPhase:phase view:[self inspectingGraphicView]];
		[strokeTableView reloadData];
		[lineView setNeedsDisplay:YES];
	   }
}

- (IBAction)capRBMatrixHit:(id)sender
{
	int cap = (int)[sender selectedRow];
	ACSDStroke *stroke = [strokeList objectAtIndex:[strokeTableView selectedRow]];
	if ([stroke lineCap] != cap)
	   {
		[stroke changeLineCap:cap view:[self inspectingGraphicView]];
		[strokeTableView reloadData];
		[lineView setNeedsDisplay:YES];
	   }
}

- (IBAction)strokeSwitchHit:(id)sender
{
}

- (IBAction)strokeListHit:(id)sender
{
}

- (IBAction)strokePlusHit:(id)sender
{
	if (strokeList)
	   {
	    NSInteger row = [strokeTableView selectedRow];
		if (row >= 0)
		{
		    [self duplicateStrokeAtRow:row];
		}
	   }
}

- (IBAction)strokeMinusHit:(id)sender
{
	[self deleteStrokeAtIndex:[strokeTableView selectedRow]];
}

- (IBAction)lineEndingPlusHit:(id)sender
{
	if (lineEndingList)
	   {
	    NSInteger row = [arrowTableView selectedRow];
		if (row >= 0)
		{
		    [self duplicateLineEndingAtRow:row];
		}
	   }
}

- (IBAction)lineEndingMinusHit:(id)sender
{
	[self deleteLineEndingAtIndex:[arrowTableView selectedRow]];
}

-(void)refreshStrokes
{
	[strokeTableView reloadData];
}

-(void)refreshLineEndings
{
	[arrowTableView reloadData];
}


- (IBAction)strokeMatrixHit:(id)sender
{
    NSArray *selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
    NSInteger ct = [selectedGraphics count];
    if (ct > 0)
	   {
	    ACSDStroke *str=nil;
		NSInteger val = [sender selectedRow];
        for (int i = 0;i < ct;i++)
		{
			id obj = [selectedGraphics objectAtIndex:i];
			if ([obj respondsToSelector:@selector(setGraphicStrokeType:)])
				str = [obj setGraphicStrokeType:(StrokeType)val];
		}
        [[[self inspectingGraphicView] undoManager] setActionName:@"Change Stroke Type"];
		[self selectAndSetControlsForStroke:str];
       }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notif
{
	if ([self actionsDisabled])
		return;
	if ([notif object] == strokeTableView)
		[self strokeTableSelectionChange:[strokeTableView selectedRow]];
	else if ([notif object] == arrowTableView)
		[self arrowTableSelectionChange:[arrowTableView selectedRow]];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
	if (aTableView == arrowTableView)
	   {
		ACSDLineEnding *le = [lineEndingList objectAtIndex:rowIndex];
		if ([[self inspectingGraphicView] recursionForObject:le])
			return NO;
		ACSDStroke *stroke = [strokeList objectAtIndex:[strokeTableView selectedRow]];
		if ([[le usedStrokes]containsObject:stroke])
			return NO;
		return YES;
	   }
	else
		return YES;
}

- (IBAction)editLineEnding:(id)sender
{
	if (!lineEndingList || ![self inspectingGraphicView])
		return;
	int i = rowForContextualMenu;
	if (i < 0)
		return;
	if ([[lineEndingList objectAtIndex:i]graphic])
		[[[self inspectingGraphicView] document] createLineEndingWindowWithLineEnding:[lineEndingList objectAtIndex:i]isNew:NO];
}

- (BOOL)validateMenuItem:(id)menuItem
{
	BOOL strokeMenu = ([menuItem menu] == [strokeTableView menu]);
	if (strokeMenu)
	   {
		if (strokeList && rowForContextualMenu > -1)
			[strokeTableView reDisplayRow:rowForContextualMenu];
	   }
	else
	   {
		if (lineEndingList && rowForContextualMenu > -1)
			[arrowTableView reDisplayRow:rowForContextualMenu];
	   }
	SEL action = [menuItem action];
	if (action == @selector(editLineEnding:))
	   {
		if (lineEndingList)
		{
			int i = rowForContextualMenu;
			if (i > -1 && [[lineEndingList objectAtIndex:i]graphic])
				return YES;
		}
		return NO;
	   }
	if (action == @selector(deleteStroke:))
	   {
		if (strokeList)
		{
			int i = rowForContextualMenu;
			if (i > -1 && ([[strokeList objectAtIndex:i]nonDeletedCount] == 0))
				return YES;
		}
		return NO;
	   }
	return YES;
}

@end
