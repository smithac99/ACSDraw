//
//  ACSDrawTextAttachmentCell.mm
//  ACSDraw
//
//  Created by alan on 30/01/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ACSDrawTextAttachmentCell.h"


@implementation ACSDrawTextAttachmentCell

-(void)dealloc
{
	if (graphic)
		[graphic release];
	[super dealloc];
}

- (void)setAttachment:(NSTextAttachment *)anAttachment
{
	[super setAttachment:anAttachment];
	if (graphic)
		[graphic release];
//	NSData* serialisedData = [[anAttachment fileWrapper]serializedRepresentation];
}

@end
