#import "FillPanelController.h"

#import "ColourCell.h"
#import "SelCell.h"
#import "ACSDGraphic.h"
#import "GradientDisplay.h"
#import "GradientControl.h"
#import "ColourCell.h"
#import "PatternDisplay.h"
#import "ACSDPattern.h"
#import "ArrayAdditions.h"
#import "ACSDTableView.h"
#import "ACSDImage.h"
#import "DragView.h"
#import "PanelCoordinator.h"
#import "GraphicView.h"
#import "FillListTableSource.h"

enum
{
	FILL_RADIO_NO_FILL,
	FILL_RADIO_FILL,
	FILL_RADIO_GRADIENT,
	FILL_RADIO_PATTERN
};

FillPanelController *_sharedFillPanelController = nil;

@implementation FillPanelController

+ (id)sharedFillPanelController
{
	if (!_sharedFillPanelController)
		[PanelCoordinator sharedPanelCoordinator];
    return _sharedFillPanelController;
}

- (void)dealloc
{
    [self setFillList:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (NSMutableArray*)fillList
{
	return fillList;
}

- (void)setFillList:(NSMutableArray*)f
{
	if (fillList)
		[fillList autorelease];
	if (f)
		fillList = [f retain];
	else
		fillList = nil;
	[(id)[fillTableView dataSource]setFillList:f];
}

- (void)zeroControls
{
	[fillTableView setAllowsEmptySelection:YES];
	[self setFillList:nil];
	[fillTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
	[fillTableView reloadData];
}

- (void)reloadFills:(NSNotification *)notification
{
	[fillTableView reloadData];
}

-(void)awakeFromNib
{
	_sharedFillPanelController = self;
	[dragView setLeft:50.0];
	[dragView setRight:100.0];
	[super awakeFromNib];
	rowForContextualMenu = -1;
	displayRowForContextualMenu = -1;
	[[[fillTableView tableColumns]objectAtIndex:0] setDataCell:[[[ColourCell alloc]init]autorelease]];
	[[[fillTableView tableColumns]objectAtIndex:1] setDataCell:[[[SelCell alloc]init]autorelease]];
	[gradientControl setup];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadFills:) name:ACSDFillAdded object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unsetRowForContextualMenu:) name:NSMenuDidEndTrackingNotification object:nil];
}

-(bool)rebuildRequiredForFill:(ACSDFill*)fill
{
	if (fill == nil && ([[[staticView superview]subviews]count] > 1))
		return YES;
	return (([fill isMemberOfClass:[ACSDFill class]] && [fillView superview] == nil)
			||([fill isMemberOfClass:[ACSDGradient class]] && [gradientView superview] == nil)
			||([fill isMemberOfClass:[ACSDPattern class]] && [patternView superview] == nil));
}

-(void)addViewToFillPanel:(NSView*)view
{
	if (view && [view superview])
		return;
	[[staticView superview]setAutoresizesSubviews:NO];
//	[[dragView superview]setAutoresizesSubviews:NO];
	NSRect staticR = [staticView frame];
	NSRect viewR;
	if (view)
		viewR = [view frame];
	else
		viewR = NSZeroRect;
	NSRect dragR = [dragView frame];
	NSRect wFrame = [window frame];
//	float requiredHeight = staticR.size.height + viewR.size.height + dragR.size.height;
	float requiredHeight = (wFrame.size.height - staticR.origin.y - dragR.size.height) + viewR.size.height + dragR.size.height;
	float diff = wFrame.size.height - requiredHeight;
	if (diff != 0.0)
	{
		dragR.origin.y -= diff;
//		[dragView setFrame:dragR];
		staticR.origin.y -= diff;
		[staticView setFrame:staticR];
		wFrame.origin.y += diff;
		wFrame.size.height = requiredHeight;
		[window setFrame:wFrame display:YES animate:NO];
	}
	if (view)
	{
		viewR.origin.y = 0.0;
		[view setFrame:viewR];
		[[staticView superview]addSubview:view];
	}
//	[window invalidateShadow];
	[[staticView superview]setAutoresizesSubviews:YES];
//	[[dragView superview]setAutoresizesSubviews:YES];
}

-(void)rebuildForFill:(ACSDFill*)fill
{
	if ([fillView superview])
		[fillView removeFromSuperview];
	if ([patternView superview])
		[patternView removeFromSuperview];
	if ([gradientView superview])
		[gradientView removeFromSuperview];
	if ([fill isMemberOfClass:[ACSDFill class]])
	{
		if ([fill canFill])
			[self addViewToFillPanel:fillView];
		else
			[self addViewToFillPanel:nil];
	}
	else if ([fill isMemberOfClass:[ACSDGradient class]])
		[self addViewToFillPanel:gradientView];
	else if ([fill isMemberOfClass:[ACSDPattern class]])
		[self addViewToFillPanel:patternView];
}

- (void)setControlsForFill:(ACSDFill*)fill
{
	if ([self rebuildRequiredForFill:fill])
		[self rebuildForFill:fill];
	if (fill == nil)
	   {
		BOOL temp = [self actionsDisabled];
		[self setActionsDisabled:YES];
		[fillTableView setAllowsEmptySelection:YES];
		[fillTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
		[self setActionsDisabled:temp];
	   }
	else
	   {
		int mode = FILL_RADIO_NO_FILL;
		if ([fill isMemberOfClass:[ACSDFill class]])
		{
			if ([fill canFill])
				mode = FILL_RADIO_FILL;
		}
		else if ([fill isMemberOfClass:[ACSDGradient class]])
			mode = FILL_RADIO_GRADIENT;
		else if ([fill isMemberOfClass:[ACSDPattern class]])
			mode = FILL_RADIO_PATTERN;
		NSInteger sel = [fillRBMatrix selectedColumn];
		if (sel != mode)
			[fillRBMatrix selectCellAtRow:0 column:mode];
		if (mode == FILL_RADIO_FILL)
		{
			[fillDisplay setColor:[fill colour]];
		}
		else if (mode == FILL_RADIO_GRADIENT)
		{
			[gradientWell1 setEnabled:YES];
			[gradientDisplay setGradient:(ACSDGradient*)fill];
			[gradientControl setGradient:(ACSDGradient*)fill];
			[gradientDisplay setNeedsDisplay:YES];
			[gradientControl setNeedsDisplay:YES];
		}
		else if (mode == FILL_RADIO_PATTERN)
		{
			[patternDisplay setPattern:(ACSDPattern*)fill];
			[scaleTextField setFloatValue:[(ACSDPattern*)fill scale]];
			[scaleSlider setFloatValue:log10([(ACSDPattern*)fill scale])];
			[spacingTextField setFloatValue:[(ACSDPattern*)fill spacing]];
			[spacingSlider setFloatValue:log10([(ACSDPattern*)fill spacing])];
			[offsetTextField setFloatValue:[(ACSDPattern*)fill offset]];
			[offsetSlider setFloatValue:[(ACSDPattern*)fill offset]];
			[offsetTypeRBMatrix selectCellAtRow:0 column:[(ACSDPattern*)fill offsetMode]];
			[patternModeRBMatrix selectCellAtRow:0 column:[(ACSDPattern*)fill mode]];
			
			[opacityTextField setFloatValue:[(ACSDPattern*)fill alpha]];
			[opacitySlider setFloatValue:[(ACSDPattern*)fill alpha]];
		}
	}
}

- (void)selectAndSetControlsForFill:(ACSDFill*)fill
{
	if (fillList == nil)
		return;
	NSInteger pos = [fillList indexOfObject:fill];
	if (pos == NSNotFound)
		return;
	[fillTableView selectRow:pos byExtendingSelection:NO];
	[self setControlsForFill:fill];
}

- (void)fillTableSelectionChange:(NSInteger)row
{
	ACSDFill *fill = [fillList objectAtIndex:row]; 
	[self setControlsForFill:fill];
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
			changed = [graphic setGraphicFill:fill notify:NO] || changed;
		}
		if (changed)
			[[[self inspectingGraphicView] undoManager] setActionName:@"Change Fill"];
	   }
	[[self inspectingGraphicView] setDefaultFill:fill];
	if (row == -1 || [fillTableView oldSelectedRow] == -1)
		[self reloadFills:nil];
	else
	   {
		[fillTableView refreshSelectionIndicatorForRow:row];
		[fillTableView refreshSelectionIndicatorForRow:[fillTableView oldSelectedRow]];
	   }
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView
{
	[fillTableView setOldSelectedRow:[aTableView selectedRow]];
	return YES;
}

- (ACSDFill*)currentFill
{
	return [fillList objectAtIndex:[fillTableView selectedRow]]; 
}

-(void)setDocumentControls:(ACSDrawDocument*)doc
{
	[self setFillList:[doc fills]];
}

-(void)setGraphicControls
{
	NSInteger ct = [[[self inspectingGraphicView] selectedGraphics] count];
	id g = nil;
	if (ct == 1)
		g = [[[[self inspectingGraphicView] selectedGraphics] allObjects]objectAtIndex:0];
	if (g)
	   {
		[fillTableView setAllowsEmptySelection:NO];
		[self selectAndSetControlsForFill:[(ACSDGraphic*)g fill]];
	   }
	else if (ct == 0)
	   {
		if (fillList)
		{
			NSInteger sel = [fillTableView selectedRow];
			if (sel == -1)
				[fillTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
			else
				[self setControlsForFill:[fillList objectAtIndex:sel]];
		}
	   }
	else
	   {
		NSArray *arr = [[[self inspectingGraphicView] selectedGraphics] allObjects];
		ACSDFill *f = [(ACSDGraphic*)[arr objectAtIndex:0]fill];
		if ([arr andMakeObjectsPerformSelector:@selector(graphicUsesFill:) withObject:f])
			[self setControlsForFill:f];
		else
			[self setControlsForFill:nil];
	   }
}	

- (IBAction)editPattern:(id)sender
{
	if (!fillList || ![self inspectingGraphicView])
		return;
	int i = rowForContextualMenu;
	if (i < 0)
		return;
	if ([[fillList objectAtIndex:i]isKindOfClass:[ACSDPattern class]])
		[[[self inspectingGraphicView] document] createPatternWindowWithPattern:[fillList objectAtIndex:i]isNew:NO];
}

- (IBAction)fillWellHit:(id)sender
{
    NSColor *color = [sender color];
	ACSDFill *fill = [fillList objectAtIndex:[fillTableView selectedRow]];
	if (![color isEqual:[fill colour]])
	   {
        [fill changeColour:color view:[self inspectingGraphicView]];
		[fillTableView reloadData];
       }
}

- (IBAction)gradientWell1Hit:(id)sender
{
    NSColor *color = [sender color];
	ACSDGradient *fill = [fillList objectAtIndex:[fillTableView selectedRow]];
	if (![color isEqual:[fill leftColour]])
	   {
        [fill setLeftColour:color inView:[self inspectingGraphicView]];
		[fillTableView reloadData];
		[gradientDisplay setNeedsDisplay:YES];
       }
}

- (IBAction)patternModeRBMatrixHit:(id)sender
{
	ACSDPattern *pattern = [fillList objectAtIndex:[fillTableView selectedRow]];
	[pattern changeMode:(int)[patternModeRBMatrix selectedColumn] view:[self inspectingGraphicView]];
	[fillTableView reloadData];
	[patternDisplay setNeedsDisplay:YES];
}

- (IBAction)scaleSliderHit:(id)sender
{
	float scale10 = [sender floatValue];
	float scale;
	scale = pow(10,scale10);
	ACSDPattern *pattern = [fillList objectAtIndex:[fillTableView selectedRow]];
	if (scale != [pattern scale])
	   {
		[pattern changeScale:scale view:[self inspectingGraphicView]];
		[fillTableView reloadData];
		[patternDisplay setNeedsDisplay:YES];
		[scaleTextField setFloatValue:scale];
	   }
}

- (IBAction)spacingSliderHit:(id)sender
{
	float spacing10 = [sender floatValue];
	float spacing;
	spacing = pow(10,spacing10);
	ACSDPattern *pattern = [fillList objectAtIndex:[fillTableView selectedRow]];
	if (spacing != [pattern spacing])
	   {
		[pattern changeSpacing:spacing view:[self inspectingGraphicView]];
		[fillTableView reloadData];
		[patternDisplay setNeedsDisplay:YES];
		[spacingTextField setFloatValue:spacing];
	   }
}

- (IBAction)offsetSliderHit:(id)sender
{
	float offset = [sender floatValue];
	ACSDPattern *pattern = [fillList objectAtIndex:[fillTableView selectedRow]];
	if (offset != [pattern offset])
	   {
		[pattern changeOffset:offset view:[self inspectingGraphicView]];
		[fillTableView reloadData];
		[patternDisplay setNeedsDisplay:YES];
		[offsetTextField setFloatValue:offset];
	   }
}

- (IBAction)offsetTypeRBMatrixHit:(id)sender
{
	int otype = (int)[offsetTypeRBMatrix selectedColumn];
	ACSDPattern *pattern = [fillList objectAtIndex:[fillTableView selectedRow]];
	if (otype != [pattern offsetMode])
	   {
		[pattern changeOffsetMode:otype view:[self inspectingGraphicView]];
		[fillTableView reloadData];
		[patternDisplay setNeedsDisplay:YES];
	   }
}

- (IBAction)opacitySliderHit:(id)sender
{
	float opacity = [sender floatValue];
	ACSDPattern *pattern = [fillList objectAtIndex:[fillTableView selectedRow]];
	if (opacity != [pattern alpha])
	   {
		[pattern changeAlpha:opacity view:[self inspectingGraphicView]];
		[fillTableView reloadData];
		[patternDisplay setNeedsDisplay:YES];
		[opacityTextField setFloatValue:opacity];
	   }
}

- (IBAction)scaleTextFieldHit:(id)sender
{
	float scale = [sender floatValue];
	float scale10 = log10(scale);
	ACSDPattern *pattern = [fillList objectAtIndex:[fillTableView selectedRow]];
	if (scale != [pattern scale])
	   {
		[pattern changeScale:scale view:[self inspectingGraphicView]];
		[fillTableView reloadData];
		[patternDisplay setNeedsDisplay:YES];
		[scaleSlider setFloatValue:scale10];
	   }
}


- (IBAction)spacingTextFieldHit:(id)sender
{
	float spacing = [sender floatValue];
	float spacing10 = log10(spacing);
	ACSDPattern *pattern = [fillList objectAtIndex:[fillTableView selectedRow]];
	if (spacing != [pattern spacing])
	   {
		[pattern changeSpacing:spacing view:[self inspectingGraphicView]];
		[fillTableView reloadData];
		[patternDisplay setNeedsDisplay:YES];
		[spacingSlider setFloatValue:spacing10];
	   }
}

- (IBAction)offsetTextFieldHit:(id)sender
{
	float offset = [sender floatValue];
	ACSDPattern *pattern = [fillList objectAtIndex:[fillTableView selectedRow]];
	if (offset != [pattern offset])
	   {
		[pattern changeOffset:offset view:[self inspectingGraphicView]];
		[fillTableView reloadData];
		[patternDisplay setNeedsDisplay:YES];
		[offsetSlider setFloatValue:offset];
	   }
}

- (IBAction)opacityTextFieldHit:(id)sender
{
	float opacity = [sender floatValue];
	ACSDPattern *pattern = [fillList objectAtIndex:[fillTableView selectedRow]];
	if (opacity != [pattern alpha])
	   {
		[pattern changeAlpha:opacity view:[self inspectingGraphicView]];
		[fillTableView reloadData];
		[patternDisplay setNeedsDisplay:YES];
		[opacitySlider setFloatValue:opacity];
	   }
}

- (IBAction)fillSwitchHit:(id)sender
{
}

- (IBAction)gradientSwitchHit:(id)sender
{
}

- (void)duplicateFillAtIndex:(NSInteger)row select:(BOOL)sel
{
	[[[self inspectingGraphicView] document]insertFill:[[fillList objectAtIndex:row]copy] atIndex:row+1];
	if (sel)
		[fillTableView selectRow:row + 1 byExtendingSelection:NO];
	[[[self inspectingGraphicView] undoManager] setActionName:@"Duplicate Fill"];
}

- (IBAction)duplicateFill:(id)sender
{
	if (!fillList || ![self inspectingGraphicView])
		return;
	int i = rowForContextualMenu;
	if (i < 0)
		return;
	[self duplicateFillAtIndex:i select:NO];
}

- (IBAction)fillPlusHit:(id)sender
{
	if (fillList)
	   {
	    NSInteger row = [fillTableView selectedRow];
		if (row >= 0)
			[self duplicateFillAtIndex:row select:YES];
	   }
}

- (void)deleteFillAtIndex:(NSInteger)row
{
	if (!fillList || ![self inspectingGraphicView])
		return;
	if (row < 0)
		return;
	if ([[fillList objectAtIndex:row]nonDeletedCount] == 0)
	   {
		[[[self inspectingGraphicView] document]deleteFillAtIndex:row];
		[[[self inspectingGraphicView] undoManager] setActionName:@"Delete Fill"];
	   }
}

- (IBAction)deleteFill:(id)sender
{
	[self deleteFillAtIndex:rowForContextualMenu];
}

- (IBAction)fillMinusHit:(id)sender
{
	[self deleteFillAtIndex:[fillTableView selectedRow]];
}

- (IBAction)fillRBHit:(id)sender
{
	//	ACSDFill *fill = [fillList objectAtIndex:[fillTableView selectedRow]];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notif
{
	if ([self actionsDisabled])
		return;
	if ([notif object] == fillTableView)
		[self fillTableSelectionChange:[fillTableView selectedRow]];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
	if (aTableView == fillTableView)
	   {
		ACSDFill *fill = [fillList objectAtIndex:rowIndex];
		return ![[self inspectingGraphicView] recursionForObject:fill];
	   }
	else
		return YES;
}

- (BOOL)validateMenuItem:(id)menuItem
{
	SEL action = [menuItem action];
	if (fillList && rowForContextualMenu > -1)
	   {
		[fillTableView reDisplayRow:rowForContextualMenu];
	   }
	if (action == @selector(duplicateFill:))
		return (fillList && rowForContextualMenu > -1);
	if (action == @selector(deleteFill:))
		return (fillList && (rowForContextualMenu > -1) && ([[fillList objectAtIndex:rowForContextualMenu]nonDeletedCount] == 0));
	if (action == @selector(editPattern:))
	   {
		if (fillList)
		{
			int i = rowForContextualMenu;
			if (i > -1 && [[fillList objectAtIndex:i]isKindOfClass:[ACSDPattern class]])
				return YES;
		}
		return NO;
	   }
	return NO;
}


@end
