//
//  TKPlace.m
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import "TKPlace+Private.h"
#import "TKMedium+Private.h"
#import "TKReference+Private.h"
#import "TKMapWorker+Private.h"
#import "NSObject+Parsing.h"


@implementation TKPlace

+ (NSDictionary<NSNumber *, NSString *> *)categorySlugs
{
	static NSDictionary<NSNumber *, NSString *> *slugs = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		slugs = @{
			@(TKPlaceCategorySightseeing): @"sightseeing",
			@(TKPlaceCategoryShopping): @"shopping",
			@(TKPlaceCategoryEating): @"eating",
			@(TKPlaceCategoryDiscovering): @"discovering",
			@(TKPlaceCategoryPlaying): @"playing",
			@(TKPlaceCategoryTraveling): @"traveling",
			@(TKPlaceCategoryGoingOut): @"going_out",
			@(TKPlaceCategoryHiking): @"hiking",
			@(TKPlaceCategorySports): @"sports",
			@(TKPlaceCategoryRelaxing): @"relaxing",
			@(TKPlaceCategorySleeping): @"sleeping",
		};
	});

	return slugs;
}

+ (NSDictionary<NSNumber *, NSString *> *)levelStrings
{
	static NSDictionary<NSNumber *, NSString *> *levels = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		levels = @{
			@(TKPlaceLevelPOI): @"poi",
			@(TKPlaceLevelNeighbourhood): @"neighbourhood",
			@(TKPlaceLevelLocality): @"locality",
			@(TKPlaceLevelSettlement): @"settlement",
			@(TKPlaceLevelVillage): @"village",
			@(TKPlaceLevelTown): @"town",
			@(TKPlaceLevelCity): @"city",
			@(TKPlaceLevelCounty): @"county",
			@(TKPlaceLevelRegion): @"region",
			@(TKPlaceLevelIsland): @"island",
			@(TKPlaceLevelArchipelago): @"archipelago",
			@(TKPlaceLevelState): @"state",
			@(TKPlaceLevelCountry): @"country",
			@(TKPlaceLevelContinent): @"continent",
		};
	});

	return levels;
}

+ (TKPlaceLevel)levelFromString:(NSString *)str
{
	NSDictionary *levels = [self levelStrings];

	if (str)
		for (NSNumber *key in levels.allKeys)
			if ([levels[key] isEqual:str])
				return key.unsignedIntegerValue;

	return TKPlaceLevelUnknown;
}

+ (TKPlaceCategory)categoriesFromSlugArray:(NSArray<NSString *> *)categories
{
	TKPlaceCategory __block res = TKPlaceCategoryNone;

	NSDictionary<NSNumber *, NSString *> *slugs = [self categorySlugs];

	[slugs enumerateKeysAndObjectsUsingBlock:^(NSNumber *cat, NSString *slug, BOOL *__unused stop) {
		if ([categories containsObject:slug])
			res |= cat.unsignedIntegerValue;
	}];

	return res;
}

- (instancetype)initFromResponse:(NSDictionary *)dictionary
{
	if (self = [super init])
	{
		// Basic attributes
		_ID = [dictionary[@"id"] parsedString];
		_name = [dictionary[@"name"] parsedString];
		_suffix = [dictionary[@"name_suffix"] parsedString];

		// Coordinates
		NSDictionary *location = [dictionary[@"location"] parsedDictionary];
		NSNumber *lat = [location[@"lat"] parsedNumber];
		NSNumber *lng = [location[@"lng"] parsedNumber];

		if (lat && lng) _location = [[CLLocation alloc]
			initWithLatitude:lat.doubleValue longitude:lng.doubleValue];

		if (!_ID || !_name || !_location) return nil;

		_perex = [dictionary[@"perex"] parsedString];
		_level = [[self class] levelFromString:[dictionary[@"level"] parsedString]];

		NSString *thumbnail = [dictionary[@"thumbnail_url"] parsedString];
		if (thumbnail) {
			NSURL *thumbURL = [NSURL URLWithString:thumbnail];
			if (thumbURL) _thumbnailURL = thumbURL;
		}

		_quadKey = [dictionary[@"quadkey"] parsedString];
		if (!_quadKey && _location)
			_quadKey = [TKMapWorker quadKeyForCoordinate:_location.coordinate detailLevel:18];

		// Bounding box
		if ((location = [dictionary[@"bounding_box"] parsedDictionary]))
		{
			lat = [dictionary[@"south"] parsedNumber];
			lng = [dictionary[@"west"] parsedNumber];
			CLLocation *southWest = (lat && lng) ? [[CLLocation alloc]
				initWithLatitude:lat.doubleValue longitude:lng.doubleValue] : nil;
			lat = [dictionary[@"north"] parsedNumber];
			lng = [dictionary[@"east"] parsedNumber];
			CLLocation *northEast = (lat && lng) ? [[CLLocation alloc]
				initWithLatitude:lat.doubleValue longitude:lng.doubleValue] : nil;
			if (southWest && northEast)
				_boundingBox = [[TKMapRegion alloc]
					initWithSouthWestPoint:southWest northEastPoint:northEast];
		}

		// Activity details
		if (dictionary[@"description"])
			_detail = [[TKPlaceDetail alloc] initFromResponse:dictionary];

		// Properties
		_rating = [dictionary[@"rating"] parsedNumber];

		// Parents
		NSMutableArray *locationIDs = [NSMutableArray array];
		for (NSString *parentID in [dictionary[@"parent_guids"] parsedArray])
			if ([parentID parsedString]) [locationIDs addObject:parentID];
		_parents = locationIDs;

		// Feature marker
		_marker = [dictionary[@"marker"] parsedString];
		if ([_marker isEqualToString:@"default"])
			_marker = nil;

		// Fetch possible categories, tags and flags
		NSMutableOrderedSet<NSString *> *flags = [NSMutableOrderedSet orderedSetWithCapacity:4];

		_categories = [[self class] categoriesFromSlugArray:[dictionary[@"categories"] parsedArray]];

		if ([[dictionary[@"description"][@"is_translated"] parsedNumber] boolValue])
			[flags addObject:@"translated_description"];

		if ([[dictionary[@"description"][@"provider"] parsedString] isEqualToString:@"wikipedia"])
			[flags addObject:@"wikipedia_description"];

		_flags = [flags array];
    }

    return self;
}

- (NSUInteger)displayableHexColor
{
	if (_categories & TKPlaceCategorySightseeing) return 0xF6746C;
	if (_categories & TKPlaceCategoryShopping)    return 0xE7A41C;
	if (_categories & TKPlaceCategoryEating)      return 0xF6936C;
	if (_categories & TKPlaceCategoryDiscovering) return 0x898F9A;
	if (_categories & TKPlaceCategoryPlaying)     return 0x6CD8F6;
	if (_categories & TKPlaceCategoryTraveling)   return 0x6B91F6;
	if (_categories & TKPlaceCategoryGoingOut)    return 0xE76CA0;
	if (_categories & TKPlaceCategoryHiking)      return 0xD59B6B;
	if (_categories & TKPlaceCategorySports)      return 0x68B277;
	if (_categories & TKPlaceCategoryRelaxing)    return 0xA06CF6;
	if (_categories & TKPlaceCategorySleeping)    return 0xA4CB69;

	return 0x999999;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<TKPlace: %p | ID: %@ | Name: %@>", self, _ID, _name];
}

@end


@implementation TKPlaceDescription

- (instancetype)initFromResponse:(NSDictionary *)response
{
	if (self = [super init])
	{
		_text = [response[@"text"] parsedString];
		_provider = [response[@"provider"] parsedString];

		if (!_text) return nil;

		NSString *link = [response[@"link"] parsedString];
		if (link) _link = [NSURL URLWithString:link];

		_translated = [[response[@"is_translated"] parsedNumber] boolValue];
		_translationProvider = [response[@"translation_provider"] parsedString];
	}

	return self;
}

@end


@implementation TKPlaceTag

- (instancetype)initFromResponse:(NSDictionary *)response
{
	if (self = [super init])
	{
		_key = [response[@"key"] parsedString];
		_name = [response[@"name"] parsedString];

		if (!_key) return nil;
	}

	return self;
}

@end


@implementation TKPlaceDetail

- (instancetype)initFromResponse:(NSDictionary *)response
{
	if (self = [super init])
	{
		// Tags
		NSMutableOrderedSet<TKPlaceTag *> *tags = [NSMutableOrderedSet orderedSetWithCapacity:16];

		TKPlaceTag *tag;
		for (NSDictionary *tagDict in [response[@"tags"] parsedArray])
			if ((tag = [[TKPlaceTag alloc] initFromResponse:tagDict]))
				[tags addObject:tag];
		_tags = [tags array];

		// References
		NSArray *arr = [response[@"references"] parsedArray];
		NSMutableArray *refs = [NSMutableArray arrayWithCapacity:arr.count];
		for (NSDictionary *dict in arr) {
			TKReference *ref = [[TKReference alloc] initFromResponse:dict];
			if (ref) [refs addObject:ref];
		}
		_references = refs;

		// Main media

		arr = [response[@"main_media"][@"media"] parsedArray];
		NSMutableArray *media = [NSMutableArray arrayWithCapacity:arr.count];
		for (NSDictionary *dict in arr) {
			TKMedium *medium = [[TKMedium alloc] initFromResponse:dict];
			if (medium) [media addObject:medium];
		}
		_mainMedia = media;

		// Other properties

		NSDictionary *description = [response[@"description"] parsedDictionary];
		if (description) _fullDescription = [[TKPlaceDescription alloc] initFromResponse:description];

		_address = [response[@"address"] parsedString];
		_phone = [response[@"phone"] parsedString];
		_email = [response[@"email"] parsedString];
		_duration = [response[@"duration"] parsedNumber];
		_openingHours = [response[@"opening_hours"] parsedString];
		_admission = [response[@"admission"] parsedString];
	}

	return self;
}

@end
