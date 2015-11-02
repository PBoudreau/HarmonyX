//
//  FSCControlGroup.m
//
//  Created by Philippe Boudreau on 2014-11-09
//  Copyright (c) 2014 Fasterre services-conseils inc.. All rights reserved.
//

#import "FSCControlGroup.h"
#import "FSCFunction.h"


NSString *const kFSCControlGroupName = @"name";
NSString *const kFSCControlGroupFunction = @"function";


@interface FSCControlGroup ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation FSCControlGroup

@synthesize name = _name;
@synthesize function = _function;


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
            self.name = [self objectOrNilForKey:kFSCControlGroupName fromDictionary:dict];
    NSObject *receivedFSCFunction = [dict objectForKey:kFSCControlGroupFunction];
    NSMutableArray *parsedFSCFunction = [NSMutableArray array];
    if ([receivedFSCFunction isKindOfClass:[NSArray class]]) {
        for (NSDictionary *item in (NSArray *)receivedFSCFunction) {
            if ([item isKindOfClass:[NSDictionary class]]) {
                [parsedFSCFunction addObject:[FSCFunction modelObjectWithDictionary:item]];
            }
       }
    } else if ([receivedFSCFunction isKindOfClass:[NSDictionary class]]) {
       [parsedFSCFunction addObject:[FSCFunction modelObjectWithDictionary:(NSDictionary *)receivedFSCFunction]];
    }

    self.function = [NSArray arrayWithArray:parsedFSCFunction];

    }
    
    return self;
    
}

- (FSCFunction *) functionNamed: (NSString *) functionName
{
    FSCFunction * function = nil;
    
    for (FSCFunction * aFunction in [self function])
    {
        if ([[aFunction name] isEqualToString: functionName])
        {
            function = aFunction;
            
            break;
        }
    }
    
    return function;
}

- (FSCFunction *) volumeDownFunction
{
    return [self functionNamed: @"VolumeDown"];
}

- (FSCFunction *) volumeUpFunction
{
    return [self functionNamed: @"VolumeUp"];
}

- (FSCFunction *) playFunction
{
    return [self functionNamed: @"Play"];
}

- (FSCFunction *) pauseFunction
{
    return [self functionNamed: @"Pause"];
}

- (FSCFunction *) skipBackwardFunction
{
    return [self functionNamed: @"SkipBackward"];
}

- (FSCFunction *) skipForwardFunction
{
    return [self functionNamed: @"SkipForward"];
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.name forKey:kFSCControlGroupName];
    NSMutableArray *tempArrayForFunction = [NSMutableArray array];
    for (NSObject *subArrayObject in self.function) {
        if([subArrayObject respondsToSelector:@selector(dictionaryRepresentation)]) {
            // This class is a model object
            [tempArrayForFunction addObject:[subArrayObject performSelector:@selector(dictionaryRepresentation)]];
        } else {
            // Generic object
            [tempArrayForFunction addObject:subArrayObject];
        }
    }
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForFunction] forKey:kFSCControlGroupFunction];

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

    self.name = [aDecoder decodeObjectForKey:kFSCControlGroupName];
    self.function = [aDecoder decodeObjectForKey:kFSCControlGroupFunction];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_name forKey:kFSCControlGroupName];
    [aCoder encodeObject:_function forKey:kFSCControlGroupFunction];
}

- (id)copyWithZone:(NSZone *)zone
{
    FSCControlGroup *copy = [[FSCControlGroup alloc] init];
    
    if (copy) {

        copy.name = [self.name copyWithZone:zone];
        copy.function = [self.function copyWithZone:zone];
    }
    
    return copy;
}


@end
