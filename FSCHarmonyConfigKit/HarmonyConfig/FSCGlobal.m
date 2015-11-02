//
//  FSCGlobal.m
//
//  Created by Philippe Boudreau on 2014-11-09
//  Copyright (c) 2014 Fasterre services-conseils inc.. All rights reserved.
//

#import "FSCGlobal.h"


NSString *const kFSCGlobalTimeStampHash = @"timeStampHash";
NSString *const kFSCGlobalLocale = @"locale";


@interface FSCGlobal ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation FSCGlobal

@synthesize timeStampHash = _timeStampHash;
@synthesize locale = _locale;


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
            self.timeStampHash = [self objectOrNilForKey:kFSCGlobalTimeStampHash fromDictionary:dict];
            self.locale = [self objectOrNilForKey:kFSCGlobalLocale fromDictionary:dict];

    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.timeStampHash forKey:kFSCGlobalTimeStampHash];
    [mutableDict setValue:self.locale forKey:kFSCGlobalLocale];

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

    self.timeStampHash = [aDecoder decodeObjectForKey:kFSCGlobalTimeStampHash];
    self.locale = [aDecoder decodeObjectForKey:kFSCGlobalLocale];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_timeStampHash forKey:kFSCGlobalTimeStampHash];
    [aCoder encodeObject:_locale forKey:kFSCGlobalLocale];
}

- (id)copyWithZone:(NSZone *)zone
{
    FSCGlobal *copy = [[FSCGlobal alloc] init];
    
    if (copy) {

        copy.timeStampHash = [self.timeStampHash copyWithZone:zone];
        copy.locale = [self.locale copyWithZone:zone];
    }
    
    return copy;
}


@end
