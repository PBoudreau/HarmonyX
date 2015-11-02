//
//  FSCFunction.m
//
//  Created by Philippe Boudreau on 2014-11-09
//  Copyright (c) 2014 Fasterre services-conseils inc.. All rights reserved.
//

#import "FSCFunction.h"


NSString *const kFSCFunctionName = @"name";
NSString *const kFSCFunctionAction = @"action";
NSString *const kFSCFunctionLabel = @"label";


@interface FSCFunction ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation FSCFunction

@synthesize name = _name;
@synthesize action = _action;
@synthesize label = _label;


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
            self.name = [self objectOrNilForKey:kFSCFunctionName fromDictionary:dict];
            self.action = [self objectOrNilForKey:kFSCFunctionAction fromDictionary:dict];
            self.label = [self objectOrNilForKey:kFSCFunctionLabel fromDictionary:dict];

    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.name forKey:kFSCFunctionName];
    [mutableDict setValue:self.action forKey:kFSCFunctionAction];
    [mutableDict setValue:self.label forKey:kFSCFunctionLabel];

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

    self.name = [aDecoder decodeObjectForKey:kFSCFunctionName];
    self.action = [aDecoder decodeObjectForKey:kFSCFunctionAction];
    self.label = [aDecoder decodeObjectForKey:kFSCFunctionLabel];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_name forKey:kFSCFunctionName];
    [aCoder encodeObject:_action forKey:kFSCFunctionAction];
    [aCoder encodeObject:_label forKey:kFSCFunctionLabel];
}

- (id)copyWithZone:(NSZone *)zone
{
    FSCFunction *copy = [[FSCFunction alloc] init];
    
    if (copy) {

        copy.name = [self.name copyWithZone:zone];
        copy.action = [self.action copyWithZone:zone];
        copy.label = [self.label copyWithZone:zone];
    }
    
    return copy;
}


@end
