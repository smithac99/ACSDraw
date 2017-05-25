//
//  DocController.h
//  ACSDraw
//
//  Created by alan on 08/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ViewController.h"


@interface DocController : ViewController
{
    IBOutlet id docTitle;
    IBOutlet id documentHeight;
    IBOutlet id documentWidth;
    IBOutlet id viewMagnification;
    IBOutlet id scriptURL;
    IBOutlet id additionalCSS;
    IBOutlet id backgroundColour;
}


- (IBAction)backgroundColourHit:(id)sender;
- (IBAction)docTitleHit:(id)sender;
- (IBAction)scriptURLHit:(id)sender;
- (IBAction)documentWidthHit:(id)sender;
- (IBAction)documentHeightHit:(id)sender;
- (IBAction)viewMagnificationHit:(id)sender;
- (IBAction)additionalCSSHit:(id)sender;

@end
