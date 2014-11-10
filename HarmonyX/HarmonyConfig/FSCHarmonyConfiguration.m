//
//  FSCHarmonyConfiguration.m
//
//  Created by Philippe Boudreau on 2014-11-09
//  Copyright (c) 2014 Fasterre services-conseils inc.. All rights reserved.
//

#import "FSCHarmonyConfiguration.h"
#import "FSCActivity.h"
#import "FSCDevice.h"
#import "FSCContent.h"
#import "FSCGlobal.h"


NSString *const kFSCHarmonyConfigActivity = @"activity";
NSString *const kFSCHarmonyConfigSequence = @"sequence";
NSString *const kFSCHarmonyConfigDevice = @"device";
NSString *const kFSCHarmonyConfigContent = @"content";
NSString *const kFSCHarmonyConfigGlobal = @"global";


@interface FSCHarmonyConfiguration ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation FSCHarmonyConfiguration

@synthesize activity = _activity;
@synthesize sequence = _sequence;
@synthesize device = _device;
@synthesize content = _content;
@synthesize global = _global;


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
    NSObject *receivedFSCActivity = [dict objectForKey:kFSCHarmonyConfigActivity];
    NSMutableArray *parsedFSCActivity = [NSMutableArray array];
    if ([receivedFSCActivity isKindOfClass:[NSArray class]]) {
        for (NSDictionary *item in (NSArray *)receivedFSCActivity) {
            if ([item isKindOfClass:[NSDictionary class]]) {
                [parsedFSCActivity addObject:[FSCActivity modelObjectWithDictionary:item]];
            }
       }
    } else if ([receivedFSCActivity isKindOfClass:[NSDictionary class]]) {
       [parsedFSCActivity addObject:[FSCActivity modelObjectWithDictionary:(NSDictionary *)receivedFSCActivity]];
    }

    self.activity = [parsedFSCActivity sortedArrayUsingComparator: ^NSComparisonResult(FSCActivity * activity1, FSCActivity * activity2) {
        
        NSComparisonResult result = NSOrderedSame;
        
        double activity1Order = [activity1 activityOrder];
        double activity2Order = [activity2 activityOrder];
        
        if (activity1Order <= 0)
        {
            result = NSOrderedDescending;
        }
        else if (activity2Order <= 0)
        {
            result = NSOrderedAscending;
        }
        else
        {
            result = [[NSNumber numberWithDouble: [activity1 activityOrder]] compare: [NSNumber numberWithDouble: [activity2 activityOrder]]];
        }
        
        return result;
    }];
            self.sequence = [self objectOrNilForKey:kFSCHarmonyConfigSequence fromDictionary:dict];
    NSObject *receivedFSCDevice = [dict objectForKey:kFSCHarmonyConfigDevice];
    NSMutableArray *parsedFSCDevice = [NSMutableArray array];
    if ([receivedFSCDevice isKindOfClass:[NSArray class]]) {
        for (NSDictionary *item in (NSArray *)receivedFSCDevice) {
            if ([item isKindOfClass:[NSDictionary class]]) {
                [parsedFSCDevice addObject:[FSCDevice modelObjectWithDictionary:item]];
            }
       }
    } else if ([receivedFSCDevice isKindOfClass:[NSDictionary class]]) {
       [parsedFSCDevice addObject:[FSCDevice modelObjectWithDictionary:(NSDictionary *)receivedFSCDevice]];
    }

    self.device = [NSArray arrayWithArray:parsedFSCDevice];
            self.content = [FSCContent modelObjectWithDictionary:[dict objectForKey:kFSCHarmonyConfigContent]];
            self.global = [FSCGlobal modelObjectWithDictionary:[dict objectForKey:kFSCHarmonyConfigGlobal]];

    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    NSMutableArray *tempArrayForActivity = [NSMutableArray array];
    for (NSObject *subArrayObject in self.activity) {
        if([subArrayObject respondsToSelector:@selector(dictionaryRepresentation)]) {
            // This class is a model object
            [tempArrayForActivity addObject:[subArrayObject performSelector:@selector(dictionaryRepresentation)]];
        } else {
            // Generic object
            [tempArrayForActivity addObject:subArrayObject];
        }
    }
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForActivity] forKey:kFSCHarmonyConfigActivity];
    NSMutableArray *tempArrayForSequence = [NSMutableArray array];
    for (NSObject *subArrayObject in self.sequence) {
        if([subArrayObject respondsToSelector:@selector(dictionaryRepresentation)]) {
            // This class is a model object
            [tempArrayForSequence addObject:[subArrayObject performSelector:@selector(dictionaryRepresentation)]];
        } else {
            // Generic object
            [tempArrayForSequence addObject:subArrayObject];
        }
    }
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForSequence] forKey:kFSCHarmonyConfigSequence];
    NSMutableArray *tempArrayForDevice = [NSMutableArray array];
    for (NSObject *subArrayObject in self.device) {
        if([subArrayObject respondsToSelector:@selector(dictionaryRepresentation)]) {
            // This class is a model object
            [tempArrayForDevice addObject:[subArrayObject performSelector:@selector(dictionaryRepresentation)]];
        } else {
            // Generic object
            [tempArrayForDevice addObject:subArrayObject];
        }
    }
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForDevice] forKey:kFSCHarmonyConfigDevice];
    [mutableDict setValue:[self.content dictionaryRepresentation] forKey:kFSCHarmonyConfigContent];
    [mutableDict setValue:[self.global dictionaryRepresentation] forKey:kFSCHarmonyConfigGlobal];

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

    self.activity = [aDecoder decodeObjectForKey:kFSCHarmonyConfigActivity];
    self.sequence = [aDecoder decodeObjectForKey:kFSCHarmonyConfigSequence];
    self.device = [aDecoder decodeObjectForKey:kFSCHarmonyConfigDevice];
    self.content = [aDecoder decodeObjectForKey:kFSCHarmonyConfigContent];
    self.global = [aDecoder decodeObjectForKey:kFSCHarmonyConfigGlobal];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_activity forKey:kFSCHarmonyConfigActivity];
    [aCoder encodeObject:_sequence forKey:kFSCHarmonyConfigSequence];
    [aCoder encodeObject:_device forKey:kFSCHarmonyConfigDevice];
    [aCoder encodeObject:_content forKey:kFSCHarmonyConfigContent];
    [aCoder encodeObject:_global forKey:kFSCHarmonyConfigGlobal];
}

- (id)copyWithZone:(NSZone *)zone
{
    FSCHarmonyConfiguration *copy = [[FSCHarmonyConfiguration alloc] init];
    
    if (copy) {

        copy.activity = [self.activity copyWithZone:zone];
        copy.sequence = [self.sequence copyWithZone:zone];
        copy.device = [self.device copyWithZone:zone];
        copy.content = [self.content copyWithZone:zone];
        copy.global = [self.global copyWithZone:zone];
    }
    
    return copy;
}


@end
