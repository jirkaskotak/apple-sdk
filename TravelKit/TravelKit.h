//
//  TravelKit.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/02/17.
//  Copyright © 2017 Tripomatic. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for TravelKit.
FOUNDATION_EXPORT double TravelKitVersionNumber;

//! Project version string for TravelKit.
FOUNDATION_EXPORT const unsigned char TravelKitVersionString[];

#import <TravelKit/TKPlace.h>
#import <TravelKit/TKPlacesQuery.h>
#import <TravelKit/TKReference.h>
#import <TravelKit/TKMedium.h>
#import <TravelKit/TKTour.h>
#import <TravelKit/TKToursQuery.h>
#import <TravelKit/TKMapRegion.h>
#import <TravelKit/TKMapPlaceAnnotation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The main class currently used for authentication and data fetching. It provides a singleton
 instance with the public `+sharedKit` method which may be used to work with the _Travel_
 backend.

 The basic workflow is pretty straightforward – to start using _TravelKit_, you only need a
 couple of lines to get the desired data.

```objc
// Get shared instance
TravelKit *kit = [TravelKit sharedKit];

// Set your API key
kit.APIKey = @"<YOUR_API_KEY_GOES_HERE>";

// Ask kit for Eiffel Tower TKPlace object with details
[kit detailedPlaceWithID:@"poi:530" completion:^(TKPlace *place, NSError *e) {
    if (place) NSLog(@"Let's visit %@!", place.name);
    else NSLog(@"Something went wrong :/");
}];
```

 @warning API key must be provided, otherwise using any methods listed below will result
 in an error being returned in a call completion block.
 */
@interface TravelKit : NSObject

///---------------------------------------------------------------------------------------
/// @name Key properties
///---------------------------------------------------------------------------------------

/**
 Client API key you've obtained.

 @warning This needs to be set in order to perform data requests successfully.
 */
@property (nonatomic, copy, nullable) NSString *APIKey;

/**
 Preferred language of response data to use.

 @note Supported language codes: **`en`**, **`fr`**, **`de`**, **`es`**, **`nl`**,
       **`pt`**, **`it`**, **`ru`**, **`cs`**, **`sk`**, **`pl`**, **`tr`**,
       **`zh`**, **`ko`**.
 
 Default language code is `en`.

 If you want to enforce specific language or pick the one depending on your own choice,
 simply set one of the options listed.

 @warning This needs to be set in order to receive translated content.
 */
@property (nonatomic, copy, null_resettable) NSString *language;

///---------------------------------------------------------------------------------------
/// @name Initialisation
///---------------------------------------------------------------------------------------

/**
 Shared singleton object to work with.

 @return Singleton `TravelKit` object.

 @warning Regular `-init` and `+new` methods are not available.
 */
+ (nonnull TravelKit *)sharedKit NS_SWIFT_NAME(shared());

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)new UNAVAILABLE_ATTRIBUTE;

///---------------------------------------------------------------------------------------
/// @name Place working queries
///---------------------------------------------------------------------------------------

/**
 Returns a collection of `TKPlace` objects for the given query object.

 This method is good for fetching Places to use for lists, map annotations and other batch uses.

 @param query `TKPlacesQuery` object containing the desired attributes to look for.
 @param completion Completion block called on success or error.
 */
- (void)placesForQuery:(TKPlacesQuery *)query
	completion:(void (^)(NSArray<TKPlace *>  * _Nullable places, NSError * _Nullable error))completion;

/**
 Returns a collection of `TKPlace` objects for the given IDs.

 @param placeIDs Array of strings matching desired Place IDs.
 @param completion Completion block called on success or error.
 */
- (void)placesWithIDs:(NSArray<NSString *> *)placeIDs
	completion:(void (^)(NSArray<TKPlace *> * _Nullable places, NSError * _Nullable error))completion;

/**
 Returns a Detailed `TKPlace` object for the given global Place identifier.

 This method is good for fetching further Place information to use f.e. on Place Detail screen.

 @param placeID Global identifier of the desired Place.
 @param completion Completion block called on success or error.
 */
- (void)detailedPlaceWithID:(NSString *)placeID
	completion:(void (^)(TKPlace * _Nullable place, NSError * _Nullable error))completion;

///---------------------------------------------------------------------------------------
/// @name Media working queries
///---------------------------------------------------------------------------------------

/**
 Returns a collection of `TKMedium` objects for the given global Place identifier.

 This method is used to fetch all Place media to be used f.e. for Gallery screen.

 @param placeID Global identifier of the desired Place.
 @param completion Completion block called on success or error.
 */
- (void)mediaForPlaceWithID:(NSString *)placeID
	completion:(void (^)(NSArray<TKMedium *> * _Nullable media, NSError * _Nullable error))completion;

///---------------------------------------------------------------------------------------
/// @name Tours working queries
///---------------------------------------------------------------------------------------

/**
 Returns a collection of `TKTour` objects for the given query object.

 This method is good for fetching Tours to use for lists and other batch uses.

 @param query `TKToursQuery` object containing the desired attributes to look for.
 @param completion Completion block called on success or error.

 @note Experimental.
 */
- (void)toursForQuery:(TKToursQuery *)query
	completion:(void (^)(NSArray<TKTour *>  * _Nullable tours, NSError * _Nullable error))completion;

///---------------------------------------------------------------------------------------
/// @name Favorites
///---------------------------------------------------------------------------------------

/**
 Fetches an array of IDs of Places previously marked as favorite.

 @return Array of Place IDs.
 */
- (NSArray<NSString *> *)favoritePlaceIDs;

/**
 Updates a favorite state for a specific Place ID.

 @param favoriteID Place ID to update.
 @param favorite Desired Favorite state, either `YES` or `NO`.
 */
- (void)updateFavoritePlaceID:(NSString *)favoriteID setFavorite:(BOOL)favorite;

///---------------------------------------------------------------------------------------
/// @name Map-related methods
///---------------------------------------------------------------------------------------

/**
 Naive method for fetching standardised quad keys for the given region.

 @param region Region to calculate quad keys for.
 @return Array of quad key strings.
 */
- (NSArray<NSString *> *)quadKeysForMapRegion:(MKCoordinateRegion)region;

/**
 Spreading method calculating optimally spread `TKMapPlaceAnnotation` objects in 3 basic sizes.

 @param places Places to spread and create `TKMapPlaceAnnotation` objects for.
 @param region Region where to spread the annotations.
 @param size Standard size of the Map view. May be taken from either `-frame` or `-bounds`.
 @return Array of spread annotations.
 */
- (NSArray<TKMapPlaceAnnotation *> *)spreadAnnotationsForPlaces:(NSArray<TKPlace *> *)places
            mapRegion:(MKCoordinateRegion)region mapViewSize:(CGSize)size;

/**
 Interpolating method for sorting Map annotations.

 @param newAnnotations Array of annotations you'd like to display.
 @param oldAnnotations Array of annotations currently displayed.
 @param toAdd Out array of annotations to add to the map.
 @param toKeep Out array of annotations to keep on the map.
 @param toRemove Out array of annotations to remove from the map.
 
 @note `toAdd`, `toKeep` and `toRemove` are regular given mutable arrays this method will fill.
       Annotations in `toAdd` array are meant to be used with `-addAnnotations:` or equivalent
       method of your Map view, `toRemove` accordingly with `-removeAnnotations:` method.
 */
- (void)interpolateNewAnnotations:(NSArray<TKMapPlaceAnnotation *> *)newAnnotations
                   oldAnnotations:(NSArray<TKMapPlaceAnnotation *> *)oldAnnotations
                            toAdd:(NSMutableArray<TKMapPlaceAnnotation *> *)toAdd
                           toKeep:(NSMutableArray<TKMapPlaceAnnotation *> *)toKeep
                         toRemove:(NSMutableArray<TKMapPlaceAnnotation *> *)toRemove;

///---------------------------------------------------------------------------------------
/// @name Session-related methods
///---------------------------------------------------------------------------------------

/**
 Clears all cached and persisting user data.
 */
- (void)clearUserData;

@end

NS_ASSUME_NONNULL_END
