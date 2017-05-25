//
//  ShadowsController.h
//  ACSDraw
//
//  Created by alan on 08/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ViewController.h"


@interface ShadowsController : ViewController
{
    IBOutlet id radiusSlider;
    IBOutlet id shadowTableView;
    IBOutlet id shadowListTableSource;
    IBOutlet id shadowPlus;
    IBOutlet id shadowMinus;
    IBOutlet id shadowWell;
    IBOutlet id xOffsetSlider;
    IBOutlet id yOffsetSlider;
	NSMutableArray *shadowList;
}

- (void)setShadowList:(NSMutableArray*)f;
- (IBAction)shadowPlusHit:(id)sender;
- (IBAction)shadowMinusHit:(id)sender;
- (IBAction)shadowWellHit:(id)sender;
- (IBAction)duplicateShadow:(id)sender;
- (IBAction)radiusSliderHit:(id)sender;
- (IBAction)xOffsetSliderHit:(id)sender;
- (IBAction)yOffsetSliderHit:(id)sender;

-(void)refreshShadows;

@end
