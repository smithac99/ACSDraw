//
//  ACSDDocImage.h
//  ACSDraw
//
//  Created by alan on 09/01/15.
//
//

#import "ACSDImage.h"

@interface ACSDDocImage : ACSDImage

@property (retain) ACSDrawDocument *drawDoc;

-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l drawDoc:(ACSDrawDocument*)drawDoc;

@end
