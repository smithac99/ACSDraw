//
//  ACSDStyle.mm
//  ACSDraw
//
//  Created by alan on 30/01/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import "ACSDStyle.h"
#import "ACSDrawDocument.h"

NSString *StyleAttribute = @"StyleAttribute";

NSString *StyleTextAlignment = @"TextAlignment";
NSString *StyleFontFamilyName = @"FontFamilyName";
NSString *StyleFontFaceName = @"FontFaceName";
NSString *StyleFontPointSize = @"FontPointSize";
NSString *StyleForegroundColour = @"ForegroundColour";
NSString *StyleBackgroundColour = @"BackgroundColour";
NSString *StyleFirstIndent = @"FirstIndent";
NSString *StyleLeftIndent = @"LeftIndent";
NSString *StyleRightIndent = @"RightIndent";
NSString *StyleLeading = @"Leading";
NSString *StyleSpaceAfter = @"SpaceAfter";
NSString *StyleSpaceBefore = @"SpaceBefore";
NSString *StyleTabs = @"Tabs";
NSString *StyleBold = @"Bold";
NSString *StyleItalic = @"Italic";


@implementation ACSDStyle

@synthesize nullStyle,generateAppleHelp;

+(ACSDStyle*)defaultStyle
{
    ACSDStyle *a = [[ACSDStyle alloc]initWithName:@"--No Style--"];
    [a setNullStyle:YES];
    return a;
}

+(NSMutableDictionary*)attributesFromTypingAttributes:(NSDictionary*)typing
{
    ACSDStyle *st = [[ACSDStyle alloc] initWithNoAttributes];
    id o;
    if ((o = [typing objectForKey:NSFontAttributeName]))
    {
        [st setFontFace:[o fontName]];
        [st setFontPointSize:[o pointSize]];
    }
    if ((o = [typing objectForKey:NSForegroundColorAttributeName]))
        [st setForegroundColour:o];
    NSParagraphStyle *ps = [typing objectForKey:NSParagraphStyleAttributeName];
    if (ps)
    {
        [st setTextAlignment:[ps alignment]];
        [st setFloatValue:[ps headIndent]forKey:StyleLeftIndent];
        [st setFloatValue:[ps firstLineHeadIndent]-[ps headIndent]forKey:StyleFirstIndent];
        [st setFloatValue:[ps lineSpacing]forKey:StyleLeading];
        [st setFloatValue:-[ps tailIndent]forKey:StyleRightIndent];
        [st setFloatValue:[ps paragraphSpacing]forKey:StyleSpaceAfter];
        [st setFloatValue:[ps paragraphSpacingBefore]forKey:StyleSpaceBefore];
        [[st attributes]setObject:[NSArray arrayWithArray:[ps tabStops]]forKey:StyleTabs];
    }
    return [st attributes];
}

+(ACSDStyle*) styleFromTypingAttributes:(NSDictionary*)typing
{
    ACSDStyle *st = [[ACSDStyle alloc] initWithNoAttributes];
    id o;
    if ((o = [typing objectForKey:NSFontAttributeName]))
    {
        [st setFontFace:[o fontName]];
        [st setFontPointSize:[o pointSize]];
    }
    if ((o = [typing objectForKey:NSForegroundColorAttributeName]))
        [st setForegroundColour:o];
    NSParagraphStyle *ps = [typing objectForKey:NSParagraphStyleAttributeName];
    if (ps)
    {
        [st setTextAlignment:[ps alignment]];
        [st setFloatValue:[ps headIndent]forKey:StyleLeftIndent];
        [st setFloatValue:[ps firstLineHeadIndent]-[ps headIndent]forKey:StyleFirstIndent];
        [st setFloatValue:[ps lineSpacing]forKey:StyleLeading];
        [st setFloatValue:-[ps tailIndent]forKey:StyleRightIndent];
        [st setFloatValue:[ps paragraphSpacing]forKey:StyleSpaceAfter];
        [st setFloatValue:[ps paragraphSpacingBefore]forKey:StyleSpaceBefore];
        [[st attributes]setObject:[NSArray arrayWithArray:[ps tabStops]]forKey:StyleTabs];
    }
    return st;
}

+(NSMutableArray*)initialStyles
{
    NSMutableArray *m = [NSMutableArray arrayWithCapacity:20];
    [m addObject:[ACSDStyle defaultStyle]];
    [m addObject:[[ACSDStyle alloc]initWithName:@"Body text" font:[NSFont userFontOfSize:0]]];
    NSFont *f = [[NSFontManager sharedFontManager]convertFont:[NSFont userFontOfSize:18]toHaveTrait:NSBoldFontMask];
    [m addObject:[[ACSDStyle alloc]initWithName:@"Heading 1" font:f]];
    f = [[NSFontManager sharedFontManager]convertFont:f toSize:16];
    [m addObject:[[ACSDStyle alloc]initWithName:@"Heading 2" font:f]];
    f = [[NSFontManager sharedFontManager]convertFont:f toSize:14];
    [m addObject:[[ACSDStyle alloc]initWithName:@"Heading 3" font:f]];
    [m addObject:[[ACSDStyle alloc]initWithName:@"Code" font:[NSFont userFixedPitchFontOfSize:0]]];
    return m;
}

+(NSMutableDictionary*)defaultAttributes
{
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:20];
    NSFont *f = [NSFont userFontOfSize:0];
    [d setObject:[f fontName] forKey:StyleFontFaceName];
    [d setObject:[NSNumber numberWithFloat:[f pointSize]] forKey:StyleFontPointSize];
    NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc]init];
    [d setObject:[NSNumber numberWithInteger:[ps alignment]]forKey:StyleTextAlignment];
    [d setObject:[NSNumber numberWithFloat:[ps headIndent]]forKey:StyleLeftIndent];
    [d setObject:[NSNumber numberWithFloat:[ps firstLineHeadIndent]-[ps headIndent]]forKey:StyleFirstIndent];
    [d setObject:[NSNumber numberWithFloat:[ps lineSpacing]]forKey:StyleLeading];
    [d setObject:[NSNumber numberWithFloat:-[ps tailIndent]]forKey:StyleRightIndent];
    [d setObject:[NSNumber numberWithFloat:[ps paragraphSpacing]]forKey:StyleSpaceAfter];
    [d setObject:[NSNumber numberWithFloat:[ps paragraphSpacingBefore]]forKey:StyleSpaceBefore];
    [d setObject:[ps tabStops]forKey:StyleTabs];
    return d;
}

+(NSDictionary*)stylesByKey:(NSArray*)styles
{
    NSUInteger ct = [styles count];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:ct];
    for (unsigned i = 0;i < ct;i++)
    {
        ACSDStyle *st = [styles objectAtIndex:i];
        [dict setObject:st forKey:[NSNumber numberWithInt:[st objectKey]]];
    }
    return dict;
}

+(NSDictionary*)stylesByName:(NSArray*)styles
{
    NSUInteger ct = [styles count];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:ct];
    for (unsigned i = 0;i < ct;i++)
    {
        ACSDStyle *st = [styles objectAtIndex:i];
        [dict setObject:st forKey:[st name]];
    }
    return dict;
}

- (id)init
{
    if ((self = [super init]))
    {
        referrers = [[NSMutableSet alloc]initWithCapacity:20];
        nullStyle = NO;
    }
    return self;
}

- (id)initWithAttributes:(NSMutableDictionary*)d
{
    if ((self = [self init]))
        attributes = d;
    return self;
}

- (id)initWithNoAttributes
{
    self = [self initWithAttributes:[NSMutableDictionary dictionaryWithCapacity:20]];
    return self;
}

- (id)initWithName:(NSString*)n
{
    if ((self = [self initWithAttributes:[ACSDStyle defaultAttributes]]))
        self.name = n;
    return self;
}

-(id)initWithName:(NSString*)n font:(NSFont*)f
{
    if ((self = [self initWithAttributes:[ACSDStyle defaultAttributes]]))
    {
        self.name = n;
        [attributes setObject:[f fontName] forKey:StyleFontFaceName];
        [attributes setObject:[NSNumber numberWithFloat:[f pointSize]] forKey:StyleFontPointSize];
        NSColor *col = [[f fontDescriptor]objectForKey:NSForegroundColorAttributeName];
        if (col && ![col isEqual:[NSColor blackColor]])
            [attributes setObject:col forKey:StyleForegroundColour];
    }
    return self;
}

- (id)initWithName:(NSString*)n basedOn:(ACSDStyle*)b
{
    if ((self = [self initWithNoAttributes]))
    {
        self.name = n;
        [self setBasedOn:b];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone 
{
    ACSDStyle *obj = [(ACSDStyle*)[ACSDStyle alloc]initWithAttributes:(NSMutableDictionary*)[attributes mutableCopy]];
    [obj setNullStyle:nullStyle];
    [obj setName:self.name];
    [obj setBasedOn:basedOn];
    obj.generateAppleHelp = generateAppleHelp;
    return obj;
}

NSString *StyleNameKey = @"Style_name";
NSString *StyleNullKey = @"Style_null";
NSString *StyleBasedOnKey = @"Style_basedOn";
NSString *StyleAttributesKey = @"Style_attributes";
NSString *StyleReferrersKey = @"Style_attributes";
NSString *StyleGenAppleHelpKey = @"Style_genapplehelp";

- (void) encodeWithCoder:(NSCoder*)coder
{
    [super encodeWithCoder:coder];
    [coder encodeObject:[self name] forKey:StyleNameKey];
    if (basedOn)
        [coder encodeConditionalObject:basedOn forKey:StyleBasedOnKey];
    [coder encodeObject:attributes forKey:StyleAttributesKey];
    [coder encodeBool:nullStyle forKey:StyleNullKey];
    [coder encodeBool:generateAppleHelp forKey:StyleGenAppleHelpKey];
}

- (id) initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    self.name = [coder decodeObjectForKey:StyleNameKey];
    nullStyle = [coder decodeBoolForKey:StyleNullKey];
    id b = [coder decodeObjectForKey:StyleBasedOnKey];
    if (b)
        [self setBasedOn:b];
    attributes = [coder decodeObjectForKey:StyleAttributesKey];
    generateAppleHelp = [coder decodeBoolForKey:StyleGenAppleHelpKey];
    return self;
}

-(NSMutableDictionary*)attributes
{
    return attributes;
}

-(void)setAttributes:(NSMutableDictionary*)a
{
    if (a == attributes)
        return;
    attributes = a;
}

-(void)addReferrer:(ACSDStyle*)style
{
    [referrers addObject:style];
}

-(void)removeReferrer:(ACSDStyle*)style
{
    [referrers removeObject:style];
}

-(void)includeMissingAttributesFrom:(NSDictionary*)basedOnAttrs
{
    NSEnumerator *basedOnEnum = [[basedOnAttrs allKeys] objectEnumerator];
    id key,value;
    while ((key = [basedOnEnum nextObject]) != nil)
    {
        if ((value = [attributes objectForKey:key])==nil)
            [attributes setObject:[basedOnAttrs objectForKey:key] forKey:key];
    }
}

-(void)removeAttributesIdenticalTo:(NSDictionary*)basedOnAttrs
{
    NSEnumerator *basedOnEnum = [[basedOnAttrs allKeys] objectEnumerator];
    id key,value;
    while ((key = [basedOnEnum nextObject]) != nil)
    {
        if ((value = [attributes objectForKey:key])!=nil)
            if ([value isEqual:[basedOnAttrs objectForKey:key]])
                [attributes removeObjectForKey:key];
    }
}

-(void)setBasedOn:(ACSDStyle*)newBasedOn
{
    if (newBasedOn == basedOn)
        return;
    if (basedOn)
        [basedOn removeReferrer:self];
    if (newBasedOn == nil)
        [self includeMissingAttributesFrom:[basedOn attributes]];
    else
        [self removeAttributesIdenticalTo:[newBasedOn attributes]];
    basedOn = newBasedOn;
    [basedOn addReferrer:self];
}

-(ACSDStyle*)basedOn
{
    return basedOn;
}

-(BOOL)basedOnWouldCreateCycle:(ACSDStyle*)bo
{
    if (bo == self)
        return YES;
    NSMutableSet *set = [NSMutableSet setWithCapacity:10];
    [set addObject:self];
    while ((bo = [bo basedOn]))
        if ([set containsObject:bo])
            return YES;
        else
            [set addObject:bo];
    return NO;
}

-(id)attributeForKey:(id)k
{
    id attr = [attributes objectForKey:k];
    return attr;
}

-(void)setAttribute:(id)attr forKey:(id)k
{
    if (attr)
        [attributes setObject:attr forKey:k];
    else
        [attributes removeObjectForKey:k];
}

-(void)setFloatValue:(float)f forKey:(id)k
{
    [self setAttribute:[NSNumber numberWithFloat:f] forKey:k];
}

-(id)chainedObjectForKey:(id)k
{
    id obj = [attributes objectForKey:k];
    if (!obj)
        if (basedOn)
            obj = [basedOn chainedObjectForKey:k];
    return obj;
}

-(NSString*)fontFace
{
    return [self chainedObjectForKey:StyleFontFaceName];
}

-(void)setFontFace:(id)ff
{
    if (ff)
        [attributes setObject:ff forKey:StyleFontFaceName];
    else
        [attributes removeObjectForKey:StyleFontFaceName];
}

-(NSColor*)foregroundColour
{
    return [self chainedObjectForKey:StyleForegroundColour];
}

-(void)setForegroundColour:(id)col
{
    if (col)
        [attributes setObject:col forKey:StyleForegroundColour];
    else
        [attributes removeObjectForKey:StyleForegroundColour];
}

-(NSString*)fontFamily
{
    return [self chainedObjectForKey:StyleFontFamilyName];
}

-(void)setFontFamily:(id)ff
{
    [attributes setObject:ff forKey:StyleFontFamilyName];
}

-(float)fontPointSize
{
    return [[self chainedObjectForKey:StyleFontPointSize]floatValue];
}

-(void)setFontPointSize:(float)f
{
    [attributes setObject:[NSNumber numberWithFloat:f] forKey:StyleFontPointSize];
}

-(NSTextAlignment)textAlignment
{
    return (NSTextAlignment)[[self chainedObjectForKey:StyleTextAlignment]intValue];
}

-(void)setTextAlignment:(NSTextAlignment)a
{
    [attributes setObject:[NSNumber numberWithInteger:a] forKey:StyleTextAlignment];
}

-(NSFont*)fontForAttributes
{
    return [NSFont fontWithName:[self fontFace] size:[self fontPointSize]];
}

-(float)floatValueForKey:(id)key
{
    id ff = [self chainedObjectForKey:key];
    if (ff)
        return [ff floatValue];
    return 0.0;
}

+(NSParagraphStyle*)paragraphStyleForAttributes:(NSDictionary*)attrs existingParagraphStyle:(NSParagraphStyle*)existingPS
{
    NSMutableParagraphStyle *ps;
    if (existingPS)
        ps = [existingPS mutableCopy];
    else
        ps = [[NSMutableParagraphStyle alloc]init];
    id obj = [attrs objectForKey:StyleTextAlignment];
    if (obj)
        [ps setAlignment: (NSTextAlignment)[obj intValue]];
    obj = [attrs objectForKey:StyleLeftIndent];
    float indent;
    if (obj)
    {
        indent = [obj floatValue];
        [ps setHeadIndent:indent];
    }
    obj = [attrs objectForKey:StyleFirstIndent];
    if (obj)
        [ps setFirstLineHeadIndent:[obj floatValue]+[ps headIndent]];
    obj = [attrs objectForKey:StyleLeading];
    if (obj)
        [ps setLineSpacing:[obj floatValue]];
    obj = [attrs objectForKey:StyleRightIndent];
    if (obj)
        [ps setTailIndent:-[obj floatValue]];
    obj = [attrs objectForKey:StyleSpaceAfter];
    if (obj)
        [ps setParagraphSpacing:[obj floatValue]];
    obj = [attrs objectForKey:StyleSpaceBefore];
    if (obj)
        [ps setParagraphSpacingBefore:[obj floatValue]];
    obj = [attrs objectForKey:StyleTabs];
    if (obj)
        [ps setTabStops:obj];
    return ps;
}

-(NSParagraphStyle*)paragraphStyleForAttributesExistingParagraphStyle:(NSParagraphStyle*)existingPS
{
    return [ACSDStyle paragraphStyleForAttributes:attributes  existingParagraphStyle:existingPS];
}

+(NSMutableDictionary*)typingAttributesFromAttributes:(NSDictionary*)attrs existingAttributes:(NSDictionary*)existingAttrs existingParagraphStyle:(NSParagraphStyle*)existingPS
{
    NSMutableDictionary *a = [NSMutableDictionary dictionaryWithCapacity:10];
    id obj;
    if ((obj = [attrs objectForKey:StyleFontFaceName]))
    {
        id val = [attrs objectForKey:StyleFontPointSize];
        if (!val)
            val = [existingAttrs objectForKey:StyleFontPointSize];
        [a setObject:[NSFont fontWithName:obj size:[val floatValue]] forKey:NSFontAttributeName];
    }
    if ((obj = [ACSDStyle paragraphStyleForAttributes:attrs existingParagraphStyle:existingPS]))
        [a setObject:obj forKey:NSParagraphStyleAttributeName];
    if ((obj = [attrs objectForKey:StyleForegroundColour]))
        [a setObject:obj forKey:NSForegroundColorAttributeName];
    else
        [a setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
    return a;
}

+(NSMutableDictionary*)typingAttributesFromAttributes:(NSDictionary*)attrs existingParagraphStyle:(NSParagraphStyle*)existingPS
{
    NSMutableDictionary *a = [NSMutableDictionary dictionaryWithCapacity:10];
    id obj;
    if ((obj = [attrs objectForKey:StyleFontFaceName]))
        [a setObject:[NSFont fontWithName:obj size:[[attrs objectForKey:StyleFontPointSize]floatValue]] forKey:NSFontAttributeName];
    if ((obj = [ACSDStyle paragraphStyleForAttributes:attrs existingParagraphStyle:existingPS]))
        [a setObject:obj forKey:NSParagraphStyleAttributeName];
    if ((obj = [attrs objectForKey:StyleForegroundColour]))
        [a setObject:obj forKey:NSForegroundColorAttributeName];
    else
        [a setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
    return a;
}

-(NSMutableDictionary*)textAttributes
{
    return [ACSDStyle typingAttributesFromAttributes:[self fullAttributes]existingParagraphStyle:nil];
}

-(NSMutableDictionary*)textAndStyleAttributes
{
    NSMutableDictionary *a = [self textAttributes];
    [a setObject:self forKey:StyleAttribute];
    return a;
}

-(NSMutableDictionary*)fullAttributes
{
    if (basedOn)
    {
        NSMutableDictionary *attrs = [basedOn fullAttributes];
        NSEnumerator *enumerator = [attributes keyEnumerator];
        NSString *k;
        while ((k = [enumerator nextObject]))
            [attrs setObject:[attributes objectForKey:k] forKey:k];
        return attrs;
    }
    return attributes;
}


+(NSDictionary*)attributesFrom:(NSDictionary*)a1 differingFrom:(NSDictionary*)a2
{
    if (a2 == nil)
        return [NSDictionary dictionary];
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionaryWithCapacity:10];
    NSEnumerator *a1enumerator = [a1 keyEnumerator];
    NSString *a1k;
    while ((a1k = [a1enumerator nextObject]))
    {
        id a2obj = [a2 objectForKey:a1k];
        if (a2obj == nil || !([a2obj isEqual:[a1 objectForKey:a1k]]))
            [resultDict setObject:[a1 objectForKey:a1k] forKey:a1k];
    }
    return resultDict;
}

+(NSMutableDictionary*)attributesFrom:(NSDictionary*)a1 notIn:(NSDictionary*)a2
{
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionaryWithCapacity:10];
    NSEnumerator *a1enumerator = [a1 keyEnumerator];
    NSString *a1k;
    while ((a1k = [a1enumerator nextObject]))
        if ([a2 objectForKey:a1k] == nil)
            [resultDict setObject:[a1 objectForKey:a1k] forKey:a1k];
        else if ([a1k isEqualToString:StyleFontFaceName])
        {
            NSString *f1Name = [a1 objectForKey:a1k];
            NSString *f2Name = [a2 objectForKey:a1k];
            NSFont *f1 = [NSFont fontWithName:f1Name size:0];
            NSFont *f2 = [NSFont fontWithName:f2Name size:0];
            [resultDict setObject:[[[NSFontManager sharedFontManager]convertFont:f2 toFamily:[f1 familyName]]fontName] forKey:a1k];
        }
    return resultDict;
}

+(NSMutableDictionary*)typingAttributes:(NSDictionary*)typing overridingStyleAttributes:(NSDictionary*)styleAttributes
{
    NSDictionary *typingAttributes = [ACSDStyle attributesFromTypingAttributes:typing];
    //	return [ACSDStyle typingAttributesFromAttributes:[ACSDStyle attributesFrom:styleAttributes notIn:typingAttributes]];
    return [ACSDStyle typingAttributesFromAttributes:[ACSDStyle attributesFrom:typingAttributes notIn:styleAttributes]existingParagraphStyle:[typing objectForKey:NSParagraphStyleAttributeName]];
}

-(NSMutableDictionary*)attributesOverridingStyle:(NSDictionary*)typing
{
    NSDictionary *typingAttributes = [ACSDStyle attributesFromTypingAttributes:typing];
    NSDictionary *styleAttributes = [self fullAttributes];
    return [ACSDStyle typingAttributesFromAttributes:[ACSDStyle attributesFrom:styleAttributes notIn:typingAttributes]existingParagraphStyle:[typing objectForKey:NSParagraphStyleAttributeName]];
}

-(NSMutableDictionary*)baseFontAttributes
{
    NSMutableDictionary *a = [NSMutableDictionary dictionaryWithCapacity:10];
    id x = [self foregroundColour];
    if (x)
        [a setObject:x forKey:NSForegroundColorAttributeName];
    else
        [a setObject:[NSColor blackColor] forKey:StyleForegroundColour];
    [a setObject:[NSNumber numberWithFloat:[self fontPointSize]]forKey:StyleFontPointSize];
    [a setObject:[[NSFont fontWithName:[self fontFace]size:0]familyName]forKey:StyleFontFamilyName];
    [a setObject:[self fontFace]forKey:StyleFontFaceName];
    return a;
}

@end
