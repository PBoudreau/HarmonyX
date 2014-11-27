//
//  FSCActivity.m
//
//  Created by Philippe Boudreau on 2014-11-09
//  Copyright (c) 2014 Fasterre services-conseils inc.. All rights reserved.
//

#import "FSCActivity.h"
#import "FSCControlGroup.h"

#import "UIImage+Mask.h"

NSString *const kFSCActivityId = @"id";
NSString *const kFSCActivityBaseImageUri = @"baseImageUri";
NSString *const kFSCActivityLabel = @"label";
NSString *const kFSCActivityActivityTypeDisplayName = @"activityTypeDisplayName";
NSString *const kFSCActivityControlGroup = @"controlGroup";
NSString *const kFSCActivityChannelChangingActivityRole = @"ChannelChangingActivityRole";
NSString *const kFSCActivityFixit = @"fixit";
NSString *const kFSCActivitySequences = @"sequences";
NSString *const kFSCActivityType = @"type";
NSString *const kFSCActivityActivityOrder = @"activityOrder";
NSString *const kFSCActivityIcon = @"icon";
NSString *const kFSCActivityIsTuningDefault = @"isTuningDefault";
NSString *const kFSCActivitySuggestedDisplay = @"suggestedDisplay";
NSString *const kFSCActivityImageName = @"imageName";


@interface FSCActivity ()

@property (nonatomic, copy) NSString * imageName;

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation FSCActivity

@synthesize activityIdentifier = _activityIdentifier;
@synthesize baseImageUri = _baseImageUri;
@synthesize label = _label;
@synthesize activityTypeDisplayName = _activityTypeDisplayName;
@synthesize controlGroup = _controlGroup;
@synthesize channelChangingActivityRole = _channelChangingActivityRole;
@synthesize sequences = _sequences;
@synthesize type = _type;
@synthesize activityOrder = _activityOrder;
@synthesize icon = _icon;
@synthesize isTuningDefault = _isTuningDefault;
@synthesize suggestedDisplay = _suggestedDisplay;


+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict
{
    return [[self alloc] initWithDictionary:dict];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    
    // This check serves to make sure that a non-NSDictionary object
    // passed into the model class doesn't break the parsing.
    if(self && [dict isKindOfClass:[NSDictionary class]]) {
            self.activityIdentifier = [self objectOrNilForKey:kFSCActivityId fromDictionary:dict];
            self.baseImageUri = [self objectOrNilForKey:kFSCActivityBaseImageUri fromDictionary:dict];
            self.label = [self objectOrNilForKey:kFSCActivityLabel fromDictionary:dict];
            self.activityTypeDisplayName = [self objectOrNilForKey:kFSCActivityActivityTypeDisplayName fromDictionary:dict];
    NSObject *receivedFSCControlGroup = [dict objectForKey:kFSCActivityControlGroup];
    NSMutableArray *parsedFSCControlGroup = [NSMutableArray array];
    if ([receivedFSCControlGroup isKindOfClass:[NSArray class]]) {
        for (NSDictionary *item in (NSArray *)receivedFSCControlGroup) {
            if ([item isKindOfClass:[NSDictionary class]]) {
                [parsedFSCControlGroup addObject:[FSCControlGroup modelObjectWithDictionary:item]];
            }
       }
    } else if ([receivedFSCControlGroup isKindOfClass:[NSDictionary class]]) {
       [parsedFSCControlGroup addObject:[FSCControlGroup modelObjectWithDictionary:(NSDictionary *)receivedFSCControlGroup]];
    }

    self.controlGroup = [NSArray arrayWithArray:parsedFSCControlGroup];
            self.channelChangingActivityRole = [self objectOrNilForKey:kFSCActivityChannelChangingActivityRole fromDictionary:dict];
            self.sequences = [self objectOrNilForKey:kFSCActivitySequences fromDictionary:dict];
            self.type = [self objectOrNilForKey:kFSCActivityType fromDictionary:dict];
            self.activityOrder = [[self objectOrNilForKey:kFSCActivityActivityOrder fromDictionary:dict] doubleValue];
            self.icon = [self objectOrNilForKey:kFSCActivityIcon fromDictionary:dict];
            self.isTuningDefault = [[self objectOrNilForKey:kFSCActivityIsTuningDefault fromDictionary:dict] boolValue];
            self.suggestedDisplay = [self objectOrNilForKey:kFSCActivitySuggestedDisplay fromDictionary:dict];

    }
    
    [self deriveImageName];
    
    return self;
    
}

- (void) deriveImageName
{
    NSString * imageSuffix = @"custom";
    
    if ([self suggestedDisplay] &&
        ![[self suggestedDisplay] isEqualToString: @"Default"])
    {
        if ([[self suggestedDisplay] isEqualToString: @"WatchAppleTV"])
        {
            imageSuffix = @"appletv";
        }
    }
    else
    {
        if ([[self type] isEqualToString: @"PowerOff"])
        {
            imageSuffix = @"powering_off";
        }
        else if ([[self type] isEqualToString: @"VirtualCdMulti"])
        {
            imageSuffix = @"playmusic";
        }
        else if ([[self type] isEqualToString: @"VirtualTelevisionN"])
        {
            imageSuffix = @"watchtv";
        }
        else if ([[self type] isEqualToString: @"VirtualDvd"])
        {
            imageSuffix = @"watchmovie";
        }
    }
    
    [self setImageName: [NSString stringWithFormat:
                         @"activity_%@",
                         imageSuffix]];
}

- (UIImage *) maskedImageWithColor: (UIColor *) color
{
    UIImage * mask = [UIImage imageNamed: [self imageName]];
    
    UIImage * maskedImage = [mask convertToInverseMaskWithColor: color];
    
    return maskedImage;
}

- (FSCControlGroup *) controlGroupNamed: (NSString *) controlGroupName
{
    FSCControlGroup * controlGroup = nil;
    
    for (FSCControlGroup * aControlGroup in [self controlGroup])
    {
        if ([[aControlGroup name] isEqualToString: controlGroupName])
        {
            controlGroup = aControlGroup;
            
            break;
        }
    }
    
    return controlGroup;
}

- (FSCControlGroup *) volumeControlGroup
{
    return [self controlGroupNamed: @"Volume"];
}

- (FSCControlGroup *) transportBasicControlGroup
{
    return [self controlGroupNamed: @"TransportBasic"];
}

- (FSCControlGroup *) transportExtendedControlGroup
{
    return [self controlGroupNamed: @"TransportExtended"];
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.activityIdentifier forKey:kFSCActivityId];
    [mutableDict setValue:self.baseImageUri forKey:kFSCActivityBaseImageUri];
    [mutableDict setValue:self.label forKey:kFSCActivityLabel];
    [mutableDict setValue:self.activityTypeDisplayName forKey:kFSCActivityActivityTypeDisplayName];
    NSMutableArray *tempArrayForControlGroup = [NSMutableArray array];
    for (NSObject *subArrayObject in self.controlGroup) {
        if([subArrayObject respondsToSelector:@selector(dictionaryRepresentation)]) {
            // This class is a model object
            [tempArrayForControlGroup addObject:[subArrayObject performSelector:@selector(dictionaryRepresentation)]];
        } else {
            // Generic object
            [tempArrayForControlGroup addObject:subArrayObject];
        }
    }
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForControlGroup] forKey:kFSCActivityControlGroup];
    [mutableDict setValue:self.channelChangingActivityRole forKey:kFSCActivityChannelChangingActivityRole];
    NSMutableArray *tempArrayForSequences = [NSMutableArray array];
    for (NSObject *subArrayObject in self.sequences) {
        if([subArrayObject respondsToSelector:@selector(dictionaryRepresentation)]) {
            // This class is a model object
            [tempArrayForSequences addObject:[subArrayObject performSelector:@selector(dictionaryRepresentation)]];
        } else {
            // Generic object
            [tempArrayForSequences addObject:subArrayObject];
        }
    }
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForSequences] forKey:kFSCActivitySequences];
    [mutableDict setValue:self.type forKey:kFSCActivityType];
    [mutableDict setValue:[NSNumber numberWithDouble:self.activityOrder] forKey:kFSCActivityActivityOrder];
    [mutableDict setValue:self.icon forKey:kFSCActivityIcon];
    [mutableDict setValue:[NSNumber numberWithBool:self.isTuningDefault] forKey:kFSCActivityIsTuningDefault];
    [mutableDict setValue:self.suggestedDisplay forKey:kFSCActivitySuggestedDisplay];

    return [NSDictionary dictionaryWithDictionary:mutableDict];
}

- (NSString *)description 
{
    return [NSString stringWithFormat:@"%@", [self dictionaryRepresentation]];
}

#pragma mark - Helper Method
- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict
{
    id object = [dict objectForKey:aKey];
    return [object isEqual:[NSNull null]] ? nil : object;
}


#pragma mark - NSCoding Methods

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];

    self.activityIdentifier = [aDecoder decodeObjectForKey:kFSCActivityId];
    self.baseImageUri = [aDecoder decodeObjectForKey:kFSCActivityBaseImageUri];
    self.label = [aDecoder decodeObjectForKey:kFSCActivityLabel];
    self.activityTypeDisplayName = [aDecoder decodeObjectForKey:kFSCActivityActivityTypeDisplayName];
    self.controlGroup = [aDecoder decodeObjectForKey:kFSCActivityControlGroup];
    self.channelChangingActivityRole = [aDecoder decodeObjectForKey:kFSCActivityChannelChangingActivityRole];
    self.sequences = [aDecoder decodeObjectForKey:kFSCActivitySequences];
    self.type = [aDecoder decodeObjectForKey:kFSCActivityType];
    self.activityOrder = [aDecoder decodeDoubleForKey:kFSCActivityActivityOrder];
    self.icon = [aDecoder decodeObjectForKey:kFSCActivityIcon];
    self.isTuningDefault = [aDecoder decodeBoolForKey:kFSCActivityIsTuningDefault];
    self.suggestedDisplay = [aDecoder decodeObjectForKey:kFSCActivitySuggestedDisplay];
    self.imageName = [aDecoder decodeObjectForKey:kFSCActivityImageName];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_activityIdentifier forKey:kFSCActivityId];
    [aCoder encodeObject:_baseImageUri forKey:kFSCActivityBaseImageUri];
    [aCoder encodeObject:_label forKey:kFSCActivityLabel];
    [aCoder encodeObject:_activityTypeDisplayName forKey:kFSCActivityActivityTypeDisplayName];
    [aCoder encodeObject:_controlGroup forKey:kFSCActivityControlGroup];
    [aCoder encodeObject:_channelChangingActivityRole forKey:kFSCActivityChannelChangingActivityRole];
    [aCoder encodeObject:_sequences forKey:kFSCActivitySequences];
    [aCoder encodeObject:_type forKey:kFSCActivityType];
    [aCoder encodeDouble:_activityOrder forKey:kFSCActivityActivityOrder];
    [aCoder encodeObject:_icon forKey:kFSCActivityIcon];
    [aCoder encodeBool:_isTuningDefault forKey:kFSCActivityIsTuningDefault];
    [aCoder encodeObject:_suggestedDisplay forKey:kFSCActivitySuggestedDisplay];
    [aCoder encodeObject:_imageName forKey:kFSCActivityImageName];
}

- (id)copyWithZone:(NSZone *)zone
{
    FSCActivity *copy = [[FSCActivity alloc] init];
    
    if (copy) {

        copy.activityIdentifier = [self.activityIdentifier copyWithZone:zone];
        copy.baseImageUri = [self.baseImageUri copyWithZone:zone];
        copy.label = [self.label copyWithZone:zone];
        copy.activityTypeDisplayName = [self.activityTypeDisplayName copyWithZone:zone];
        copy.controlGroup = [self.controlGroup copyWithZone:zone];
        copy.channelChangingActivityRole = [self.channelChangingActivityRole copyWithZone:zone];
        copy.sequences = [self.sequences copyWithZone:zone];
        copy.type = [self.type copyWithZone:zone];
        copy.activityOrder = self.activityOrder;
        copy.icon = [self.icon copyWithZone:zone];
        copy.isTuningDefault = self.isTuningDefault;
        copy.suggestedDisplay = [self.suggestedDisplay copyWithZone:zone];
        copy.imageName = [self.imageName copyWithZone:zone];
    }
    
    return copy;
}


@end
