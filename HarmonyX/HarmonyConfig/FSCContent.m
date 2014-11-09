//
//  FSCContent.m
//
//  Created by Philippe Boudreau on 2014-11-09
//  Copyright (c) 2014 Fasterre services-conseils inc.. All rights reserved.
//

#import "FSCContent.h"


NSString *const kFSCContentContentServiceHost = @"contentServiceHost";
NSString *const kFSCContentContentDeviceHost = @"contentDeviceHost";
NSString *const kFSCContentContentImageHost = @"contentImageHost";
NSString *const kFSCContentContentUserHost = @"contentUserHost";
NSString *const kFSCContentHouseholdUserProfileUri = @"householdUserProfileUri";


@interface FSCContent ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation FSCContent

@synthesize contentServiceHost = _contentServiceHost;
@synthesize contentDeviceHost = _contentDeviceHost;
@synthesize contentImageHost = _contentImageHost;
@synthesize contentUserHost = _contentUserHost;
@synthesize householdUserProfileUri = _householdUserProfileUri;


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
            self.contentServiceHost = [self objectOrNilForKey:kFSCContentContentServiceHost fromDictionary:dict];
            self.contentDeviceHost = [self objectOrNilForKey:kFSCContentContentDeviceHost fromDictionary:dict];
            self.contentImageHost = [self objectOrNilForKey:kFSCContentContentImageHost fromDictionary:dict];
            self.contentUserHost = [self objectOrNilForKey:kFSCContentContentUserHost fromDictionary:dict];
            self.householdUserProfileUri = [self objectOrNilForKey:kFSCContentHouseholdUserProfileUri fromDictionary:dict];

    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.contentServiceHost forKey:kFSCContentContentServiceHost];
    [mutableDict setValue:self.contentDeviceHost forKey:kFSCContentContentDeviceHost];
    [mutableDict setValue:self.contentImageHost forKey:kFSCContentContentImageHost];
    [mutableDict setValue:self.contentUserHost forKey:kFSCContentContentUserHost];
    [mutableDict setValue:self.householdUserProfileUri forKey:kFSCContentHouseholdUserProfileUri];

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

    self.contentServiceHost = [aDecoder decodeObjectForKey:kFSCContentContentServiceHost];
    self.contentDeviceHost = [aDecoder decodeObjectForKey:kFSCContentContentDeviceHost];
    self.contentImageHost = [aDecoder decodeObjectForKey:kFSCContentContentImageHost];
    self.contentUserHost = [aDecoder decodeObjectForKey:kFSCContentContentUserHost];
    self.householdUserProfileUri = [aDecoder decodeObjectForKey:kFSCContentHouseholdUserProfileUri];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_contentServiceHost forKey:kFSCContentContentServiceHost];
    [aCoder encodeObject:_contentDeviceHost forKey:kFSCContentContentDeviceHost];
    [aCoder encodeObject:_contentImageHost forKey:kFSCContentContentImageHost];
    [aCoder encodeObject:_contentUserHost forKey:kFSCContentContentUserHost];
    [aCoder encodeObject:_householdUserProfileUri forKey:kFSCContentHouseholdUserProfileUri];
}

- (id)copyWithZone:(NSZone *)zone
{
    FSCContent *copy = [[FSCContent alloc] init];
    
    if (copy) {

        copy.contentServiceHost = [self.contentServiceHost copyWithZone:zone];
        copy.contentDeviceHost = [self.contentDeviceHost copyWithZone:zone];
        copy.contentImageHost = [self.contentImageHost copyWithZone:zone];
        copy.contentUserHost = [self.contentUserHost copyWithZone:zone];
        copy.householdUserProfileUri = [self.householdUserProfileUri copyWithZone:zone];
    }
    
    return copy;
}


@end
