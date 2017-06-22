//
//  GroupViewController.m
//  ACSDraw
//
//  Created by Alan on 03/02/2016.
//
//

#import "GroupViewController.h"
#import "ACSDGroup.h"
#import "AffineTransformAdditions.h"

BOOL NodeIsExpanded(SCNNode* node);
int totalChildDepth(SCNNode* node);

enum
{
	STATE_IDLE,
	STATE_DRAGGING,
	STATE_DRAGGING_VERTEX
};

@interface GroupViewController()
{
	CGFloat xRotation,yRotation,zRotation;
	int state;
	NSPoint anchorPoint;
	SCNNode *objNode,*cameraNode;
	SCNMatrix4 startTransform;
	CGFloat graphicRatio;
	CGFloat zInc;
}
@end

@implementation GroupViewController

-(CGFloat)modelScale
{
	return graphicRatio / 200;
}

-(SCNGeometry*)geometryFromGraphic:(ACSDGraphic*)g
{
	NSRect b = [g displayBounds];
	CGFloat w = b.size.width;
	CGFloat h = b.size.height;
	int aw = w * graphicRatio;
	int ah = h * graphicRatio;
	NSBitmapImageRep *bitmap = newBitmap(aw, ah);
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
	[[NSAffineTransform transformWithScaleBy:graphicRatio]concat];
	[[NSAffineTransform transformWithTranslateXBy:-b.origin.x yBy:-b.origin.y]concat];
	[g drawObject:b view:nil options:nil];
	[NSGraphicsContext restoreGraphicsState];
	NSImage *image = [[NSImage alloc]initWithSize:NSMakeSize(aw,ah)];
	[image addRepresentation:bitmap];
	
	CGFloat ratio = [self modelScale];
	CGFloat ow = w * ratio;
	CGFloat oh = h * ratio;
	CGFloat ow2 = ow / 2;
	CGFloat oh2 = oh / 2;
	SCNVector3 vertices[] = {
		SCNVector3Make(ow2, -oh2, 0),
		SCNVector3Make(ow2, oh2, 0),
		SCNVector3Make(-ow2, oh2, 0),
		SCNVector3Make(-ow2, -oh2, 0),
	};
	NSInteger indices[] = {
		0,1,2,
		0,2,3
	};
	SCNVector3 normals[4];
	for (int i = 0;i < 4;i++)
		normals[i] = SCNVector3Make(0, 0, 1);
	CGPoint uvs[] = {
		CGPointMake(1, 1),
		CGPointMake(1, 0),
		CGPointMake(0,0),
		CGPointMake(0, 1)
	};
	SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithVertices:vertices count:4];
	SCNGeometrySource *normalSource = [SCNGeometrySource geometrySourceWithNormals:normals count:4];
	SCNGeometrySource *textureSource = [SCNGeometrySource geometrySourceWithTextureCoordinates:uvs count:4];
	NSData *indexData = [NSData dataWithBytes:indices length:sizeof(indices)];
	SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:indexData primitiveType:SCNGeometryPrimitiveTypeTriangles primitiveCount:6 bytesPerIndex:sizeof(NSInteger)];
	SCNGeometry *geometry = [SCNGeometry geometryWithSources:@[vertexSource,normalSource,textureSource] elements:@[element]];
	geometry.firstMaterial.diffuse.contents = image;
	geometry.firstMaterial.specular.contents = [NSColor whiteColor];
	geometry.firstMaterial.doubleSided = YES;
	return geometry;
}

-(SCNNode*)nodeFromGraphic:(ACSDGraphic*)g
{
	SCNNode *node = [SCNNode nodeWithGeometry:[self geometryFromGraphic:g]];
	return node;
}

-(void)createScene
{
	self.scene = [[SCNScene alloc]init];
	self.sceneView.scene = self.scene;
	cameraNode = [SCNNode node];
	self.camera = cameraNode.camera = [SCNCamera camera];
	cameraNode.position = SCNVector3Make(0, 0, 20);
	[self.scene.rootNode addChildNode:cameraNode];
	self.camera.xFov = 60;
	self.displayZVal = 10;
	
	SCNLight *light = [SCNLight light];
	light.type = SCNLightTypeOmni;
	light.color = [NSColor whiteColor];
	SCNNode *lightNode = [SCNNode node];
	lightNode.position = SCNVector3Make(10, 20, 10);
	lightNode.light = light;
	[self.scene.rootNode addChildNode:lightNode];
	
	SCNLight *ambientLight = [SCNLight light];
	ambientLight.type = SCNLightTypeAmbient;
	ambientLight.color = [NSColor colorWithCalibratedWhite:0.55 alpha:1];
	SCNNode *alightNode = [SCNNode node];
	alightNode.light = ambientLight;
	[self.scene.rootNode addChildNode:alightNode];
	
	self.sceneView.acceptsTouchEvents = YES;

}
-(void)awakeFromNib
{
	if (self.scene == nil)
	{
		zInc = 0.1;
		[self createScene];
	}
}

#define MAX_DIM 2048

-(void)setUpObjectsForGraphic:(ACSDGraphic*)graphic
{
    self.graphic = graphic;
    if (objNode)
	{
		[objNode removeFromParentNode];
	}
	if (graphic)
	{
		CGSize sz = [graphic displayBounds].size;
		CGFloat bigger = fmax(sz.width, sz.height);
		graphicRatio = MAX_DIM / bigger;
		objNode = [self nodeFromGraphic:self.graphic];
		[self.scene.rootNode addChildNode:objNode];
		[self.outlineView reloadData];
	}
}

-(void)expandGraphic:(ACSDGraphic*)parent
{
	SCNNode *parentnode = [self nodeForGraphic:parent];
	if (parentnode == nil || ![parent isKindOfClass:[ACSDGroup class]])
		return;
	NSRect pdb = [parent displayBounds];
	parentnode.geometry = nil;
	ACSDGroup *gp = (ACSDGroup*)parent;
	for (ACSDGraphic *chg in [gp graphics])
	{
		SCNNode *n = [self nodeFromGraphic:chg];
		NSRect chb = [chg displayBounds];
		CGFloat offx = (NSMidX(chb) - NSMidX(pdb)) * [self modelScale];
		CGFloat offy = (NSMidY(chb) - NSMidY(pdb)) * [self modelScale];
		SCNVector3 pos;
		pos.x = offx;
		pos.y = offy;
		pos.z = 0;
		n.position = pos;
		[parentnode addChildNode:n];
		n.hidden = [chg hidden];
	}
}

-(void)collapseGraphic:(ACSDGraphic*)parent
{
	SCNNode *parentnode = [self nodeForGraphic:parent];
	if (parentnode == nil)
		return;
	for (SCNNode *node in parentnode.childNodes)
		[node removeFromParentNode];
	parentnode.geometry = [self geometryFromGraphic:parent];
}

-(BOOL)graphicIsExpanded:(ACSDGraphic*)g
{
	if ([g isKindOfClass:[ACSDGroup class]])
	{
		return [self.outlineView isItemExpanded:g];
	}
	return NO;
}

BOOL NodeIsExpanded(SCNNode* node)
{
	return [node.childNodes count] > 0;
}

int totalChildDepth(SCNNode* node)
{
	if (NodeIsExpanded(node))
	{
		int tot = 0;
		for (SCNNode *n in node.childNodes)
			tot += totalChildDepth(n);
	}
	return 1;
}

-(SCNNode*)nodeForGraphic:(ACSDGraphic*)g
{
	if (g == self.graphic)
		return objNode;
	NSArray *path = [g indexPathFromAncestor:(ACSDGroup*)self.graphic];
	SCNNode *node = objNode;
	for (NSNumber *n in path)
	{
		NSInteger i = [n integerValue];
		node = node.childNodes[i];
	}
	return node;
}

-(CGFloat)distributeFromZ:(CGFloat)z increment:(CGFloat)zinc node:(SCNNode*)n
{
	if (NodeIsExpanded(n))
	{
		for (NSInteger i = 0;i < [n.childNodes count];i++)
		{
			SCNNode *nc = n.childNodes[i];
			z = [self distributeFromZ:z increment:zinc node:nc];
		}
		return z;
	}
	else
	{
		SCNVector3 pos = n.position;
		pos.z = z;
		n.position = pos;
		return z + zinc;
	}
}

#pragma mark - dragging

-(void)mouseUp:(NSEvent *)theEvent
{
	state = STATE_IDLE;
}

-(void)updateObjectMatrix
{
	SCNMatrix4 mat = SCNMatrix4Identity;
	mat = SCNMatrix4Rotate(mat, RADIANS(xRotation), 1, 0, 0);
	mat = SCNMatrix4Rotate(mat, RADIANS(yRotation), 0, 1, 0);
	mat = SCNMatrix4Mult(mat, startTransform);
	objNode.transform = mat;
}

-(void)mouseDragged:(NSEvent *)theEvent
{
	if (state == STATE_DRAGGING)
	{
		NSPoint curPoint = [self.sceneView convertPoint:[theEvent locationInWindow] fromView:nil];
		float yDiff = curPoint.y - anchorPoint.y;
		float xDiff = curPoint.x - anchorPoint.x;
		xRotation = yDiff / self.sceneView.bounds.size.height * -180.0;
		yRotation = xDiff / self.sceneView.bounds.size.width * 180.0;
		[self updateObjectMatrix];
	}
}

-(void)mouseDown:(NSEvent *)theEvent
{
	anchorPoint = [self.sceneView convertPoint:[theEvent locationInWindow] fromView:nil];
	startTransform = objNode.transform;
	state = STATE_DRAGGING;
}

#pragma mark - outlineview

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if ([item isKindOfClass:[ACSDGroup class]])
    {
        ACSDGroup *g = item;
        return [[g graphics]count];
    }
	if (item == nil && self.graphic != nil)
		return 1;
	return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return [item isKindOfClass:[ACSDGroup class]];
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	NSString *nm = [tableColumn identifier];
	if ([nm isEqualToString:@"name"])
	{
		NSTableCellView *result = [outlineView makeViewWithIdentifier:@"name" owner:self];
		result.textField.stringValue = [item name];
		result.textField.delegate = self;
		[result.textField setEditable:YES];
		NSButton *cb = [result viewWithTag:37];
		if ([item hidden])
			[cb setState:NSOffState];
		else
			[cb setState:NSOnState];
		[cb setTarget:self];
		[cb setAction:@selector(hiddenCbHit:)];
		return result;
	}
	return nil;
}

-(void)refreshSpacing
{
	int dpth = totalChildDepth([self nodeForGraphic:self.graphic]);
	[self distributeFromZ:(dpth - 1)/2 * zInc increment:zInc node:[self nodeForGraphic:self.graphic]];
}

-(void)outlineViewItemDidExpand:(NSNotification *)notification
{
	ACSDGraphic *item = notification.userInfo[@"NSObject"];
	if (item)
	{
		[self expandGraphic:item];
		[self refreshSpacing];
	}
}

-(void)outlineViewItemDidCollapse:(NSNotification *)notification
{
	ACSDGraphic *item = notification.userInfo[@"NSObject"];
	if (item)
	{
		[self collapseGraphic:item];
		[self refreshSpacing];
	}
}

-(IBAction)hiddenCbHit:(id)sender
{
	NSInteger row = [self.outlineView rowForView:sender];
	ACSDGraphic *g = [self.outlineView itemAtRow:row];
	[g setGraphicHidden:[sender state]==NSOffState];
	SCNNode *node = [self nodeForGraphic:g];
	if (node)
		node.hidden = [g hidden];
}

-(id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	NSString *nm = [tableColumn identifier];
	if ([nm isEqualToString:@"name"])
	{
		return [item name];
	}
	return @"a";
}
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if (item == nil)
	{
		return (self.graphic);
	}
    if ([item isKindOfClass:[ACSDGroup class]])
    {
        ACSDGroup *g = item;
        
        if ([[g graphics]count] > index)
            return [g graphics][index];
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn
			   item:(id)item
{
	return YES;
}
#pragma mark -

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	NSInteger row = [self.outlineView selectedRow];
	ACSDGraphic *g = [self.outlineView itemAtRow:row];
	[g setGraphicName:[fieldEditor string]];
	return YES;
}

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor
{
	return YES;
}

-(void)setDisplayZInc:(float)displayZInc
{
	_displayZInc = zInc = displayZInc;
	[self refreshSpacing];
}
-(void)setDisplayZVal:(float)displayZVal
{
	_displayZVal = displayZVal;
	SCNVector3 pos = cameraNode.position;
	pos.z = displayZVal;
	cameraNode.position = pos;
}
@end
