//
//  FSCDevice.m
//
//  Created by Philippe Boudreau on 2014-11-09
//  Copyright (c) 2014 Fasterre services-conseils inc.. All rights reserved.
//

#import "FSCDevice.h"
#import "FSCControlGroup.h"


NSString *const kFSCDeviceId = @"id";
NSString *const kFSCDeviceLabel = @"label";
NSString *const kFSCDeviceDeviceProfileUri = @"deviceProfileUri";
NSString *const kFSCDeviceIsKeyboardAssociated = @"IsKeyboardAssociated";
NSString *const kFSCDeviceControlPort = @"ControlPort";
NSString *const kFSCDeviceControlGroup = @"controlGroup";
NSString *const kFSCDeviceType = @"type";
NSString *const kFSCDeviceIsManualPower = @"isManualPower";
NSString *const kFSCDeviceDongleRFID = @"DongleRFID";
NSString *const kFSCDeviceCapabilities = @"Capabilities";
NSString *const kFSCDeviceTransport = @"Transport";
NSString *const kFSCDeviceDeviceTypeDisplayName = @"deviceTypeDisplayName";
NSString *const kFSCDeviceManufacturer = @"manufacturer";
NSString *const kFSCDeviceSuggestedDisplay = @"suggestedDisplay";
NSString *const kFSCDeviceModel = @"model";
NSString *const kFSCDeviceIcon = @"icon";


@interface FSCDevice ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation FSCDevice

@synthesize deviceIdentifier = _deviceIdentifier;
@synthesize label = _label;
@synthesize deviceProfileUri = _deviceProfileUri;
@synthesize isKeyboardAssociated = _isKeyboardAssociated;
@synthesize controlPort = _controlPort;
@synthesize controlGroup = _controlGroup;
@synthesize type = _type;
@synthesize isManualPower = _isManualPower;
@synthesize dongleRFID = _dongleRFID;
@synthesize capabilities = _capabilities;
@synthesize transport = _transport;
@synthesize deviceTypeDisplayName = _deviceTypeDisplayName;
@synthesize manufacturer = _manufacturer;
@synthesize suggestedDisplay = _suggestedDisplay;
@synthesize model = _model;
@synthesize icon = _icon;


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
            self.deviceIdentifier = [self objectOrNilForKey:kFSCDeviceId fromDictionary:dict];
            self.label = [self objectOrNilForKey:kFSCDeviceLabel fromDictionary:dict];
            self.deviceProfileUri = [self objectOrNilForKey:kFSCDeviceDeviceProfileUri fromDictionary:dict];
            self.isKeyboardAssociated = [[self objectOrNilForKey:kFSCDeviceIsKeyboardAssociated fromDictionary:dict] boolValue];
            self.controlPort = [[self objectOrNilForKey:kFSCDeviceControlPort fromDictionary:dict] doubleValue];
    NSObject *receivedFSCControlGroup = [dict objectForKey:kFSCDeviceControlGroup];
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
            self.type = [self objectOrNilForKey:kFSCDeviceType fromDictionary:dict];
            self.isManualPower = [self objectOrNilForKey:kFSCDeviceIsManualPower fromDictionary:dict];
            self.dongleRFID = [[self objectOrNilForKey:kFSCDeviceDongleRFID fromDictionary:dict] doubleValue];
            self.capabilities = [self objectOrNilForKey:kFSCDeviceCapabilities fromDictionary:dict];
            self.transport = [[self objectOrNilForKey:kFSCDeviceTransport fromDictionary:dict] doubleValue];
            self.deviceTypeDisplayName = [self objectOrNilForKey:kFSCDeviceDeviceTypeDisplayName fromDictionary:dict];
            self.manufacturer = [self objectOrNilForKey:kFSCDeviceManufacturer fromDictionary:dict];
            self.suggestedDisplay = [self objectOrNilForKey:kFSCDeviceSuggestedDisplay fromDictionary:dict];
            self.model = [self objectOrNilForKey:kFSCDeviceModel fromDictionary:dict];
            self.icon = [self objectOrNilForKey:kFSCDeviceIcon fromDictionary:dict];

    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.deviceIdentifier forKey:kFSCDeviceId];
    [mutableDict setValue:self.label forKey:kFSCDeviceLabel];
    [mutableDict setValue:self.deviceProfileUri forKey:kFSCDeviceDeviceProfileUri];
    [mutableDict setValue:[NSNumber numberWithBool:self.isKeyboardAssociated] forKey:kFSCDeviceIsKeyboardAssociated];
    [mutableDict setValue:[NSNumber numberWithDouble:self.controlPort] forKey:kFSCDeviceControlPort];
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
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForControlGroup] forKey:kFSCDeviceControlGroup];
    [mutableDict setValue:self.type forKey:kFSCDeviceType];
    [mutableDict setValue:self.isManualPower forKey:kFSCDeviceIsManualPower];
    [mutableDict setValue:[NSNumber numberWithDouble:self.dongleRFID] forKey:kFSCDeviceDongleRFID];
    NSMutableArray *tempArrayForCapabilities = [NSMutableArray array];
    for (NSObject *subArrayObject in self.capabilities) {
        if([subArrayObject respondsToSelector:@selector(dictionaryRepresentation)]) {
            // This class is a model object
            [tempArrayForCapabilities addObject:[subArrayObject performSelector:@selector(dictionaryRepresentation)]];
        } else {
            // Generic object
            [tempArrayForCapabilities addObject:subArrayObject];
        }
    }
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForCapabilities] forKey:kFSCDeviceCapabilities];
    [mutableDict setValue:[NSNumber numberWithDouble:self.transport] forKey:kFSCDeviceTransport];
    [mutableDict setValue:self.deviceTypeDisplayName forKey:kFSCDeviceDeviceTypeDisplayName];
    [mutableDict setValue:self.manufacturer forKey:kFSCDeviceManufacturer];
    [mutableDict setValue:self.suggestedDisplay forKey:kFSCDeviceSuggestedDisplay];
    [mutableDict setValue:self.model forKey:kFSCDeviceModel];
    [mutableDict setValue:self.icon forKey:kFSCDeviceIcon];

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

    self.deviceIdentifier = [aDecoder decodeObjectForKey:kFSCDeviceId];
    self.label = [aDecoder decodeObjectForKey:kFSCDeviceLabel];
    self.deviceProfileUri = [aDecoder decodeObjectForKey:kFSCDeviceDeviceProfileUri];
    self.isKeyboardAssociated = [aDecoder decodeBoolForKey:kFSCDeviceIsKeyboardAssociated];
    self.controlPort = [aDecoder decodeDoubleForKey:kFSCDeviceControlPort];
    self.controlGroup = [aDecoder decodeObjectForKey:kFSCDeviceControlGroup];
    self.type = [aDecoder decodeObjectForKey:kFSCDeviceType];
    self.isManualPower = [aDecoder decodeObjectForKey:kFSCDeviceIsManualPower];
    self.dongleRFID = [aDecoder decodeDoubleForKey:kFSCDeviceDongleRFID];
    self.capabilities = [aDecoder decodeObjectForKey:kFSCDeviceCapabilities];
    self.transport = [aDecoder decodeDoubleForKey:kFSCDeviceTransport];
    self.deviceTypeDisplayName = [aDecoder decodeObjectForKey:kFSCDeviceDeviceTypeDisplayName];
    self.manufacturer = [aDecoder decodeObjectForKey:kFSCDeviceManufacturer];
    self.suggestedDisplay = [aDecoder decodeObjectForKey:kFSCDeviceSuggestedDisplay];
    self.model = [aDecoder decodeObjectForKey:kFSCDeviceModel];
    self.icon = [aDecoder decodeObjectForKey:kFSCDeviceIcon];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_deviceIdentifier forKey:kFSCDeviceId];
    [aCoder encodeObject:_label forKey:kFSCDeviceLabel];
    [aCoder encodeObject:_deviceProfileUri forKey:kFSCDeviceDeviceProfileUri];
    [aCoder encodeBool:_isKeyboardAssociated forKey:kFSCDeviceIsKeyboardAssociated];
    [aCoder encodeDouble:_controlPort forKey:kFSCDeviceControlPort];
    [aCoder encodeObject:_controlGroup forKey:kFSCDeviceControlGroup];
    [aCoder encodeObject:_type forKey:kFSCDeviceType];
    [aCoder encodeObject:_isManualPower forKey:kFSCDeviceIsManualPower];
    [aCoder encodeDouble:_dongleRFID forKey:kFSCDeviceDongleRFID];
    [aCoder encodeObject:_capabilities forKey:kFSCDeviceCapabilities];
    [aCoder encodeDouble:_transport forKey:kFSCDeviceTransport];
    [aCoder encodeObject:_deviceTypeDisplayName forKey:kFSCDeviceDeviceTypeDisplayName];
    [aCoder encodeObject:_manufacturer forKey:kFSCDeviceManufacturer];
    [aCoder encodeObject:_suggestedDisplay forKey:kFSCDeviceSuggestedDisplay];
    [aCoder encodeObject:_model forKey:kFSCDeviceModel];
    [aCoder encodeObject:_icon forKey:kFSCDeviceIcon];
}

- (id)copyWithZone:(NSZone *)zone
{
    FSCDevice *copy = [[FSCDevice alloc] init];
    
    if (copy) {

        copy.deviceIdentifier = [self.deviceIdentifier copyWithZone:zone];
        copy.label = [self.label copyWithZone:zone];
        copy.deviceProfileUri = [self.deviceProfileUri copyWithZone:zone];
        copy.isKeyboardAssociated = self.isKeyboardAssociated;
        copy.controlPort = self.controlPort;
        copy.controlGroup = [self.controlGroup copyWithZone:zone];
        copy.type = [self.type copyWithZone:zone];
        copy.isManualPower = [self.isManualPower copyWithZone:zone];
        copy.dongleRFID = self.dongleRFID;
        copy.capabilities = [self.capabilities copyWithZone:zone];
        copy.transport = self.transport;
        copy.deviceTypeDisplayName = [self.deviceTypeDisplayName copyWithZone:zone];
        copy.manufacturer = [self.manufacturer copyWithZone:zone];
        copy.suggestedDisplay = [self.suggestedDisplay copyWithZone:zone];
        copy.model = [self.model copyWithZone:zone];
        copy.icon = [self.icon copyWithZone:zone];
    }
    
    return copy;
}


@end
