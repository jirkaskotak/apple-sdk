# Sygic Travel Apple SDK


Sygic Travel Apple SDK is a framework for embedding a rich set of Sygic Travel data within your application. It gives you access to millions of Places covering the entire world. 

## Requirements

- Xcode 8.0+ (recommended)
- macOS 10.12+ SDK (recommended)
- iOS 10.0+ SDK (recommended)
- tvOS 10.0+ SDK (recommended)
- _Objective-C_ or _Swift_ project
- _API key_ for your business or project

## Deployment

- OS X 10.9+ target (_macOS framework_)
- iOS 8.2+ target (_iOS framework_)
- tvOS 9.0+ target (_tvOS framework_)

## Installation
TODO

## Quick Usage Introduction

This quick example shows how to use the SDK to fetch a representative set of data.

Let's define a set of Places we want:

- placed in _London_
- marked as _Points of interest_
- included in the _Sightseeing_ category
- only the _Top 10_ of them

```objc
// Hold an instance
TravelKit *kit = [TravelKit sharedKit];
	
// Set your API key
kit.APIKey = @"<YOUR_API_KEY_GOES_HERE>";
	
// Create query to get Top 10 Sightseeing Places in London
TKPlacesQuery *query = [TKPlacesQuery new];
query.parentIDs = @[ @"city:1" ];
query.levels = TKPlaceLevelPOI;
query.categories = @[ @"sightseeing" ];
query.limit = 10;
	
// Perform query and print a message containing the first item
[kit placesForQuery:query completion:^(NSArray< TKPlace *> *places, NSError *error){
	if (places.firstObject) NSLog(@"Let's visit %@!", places.firstObject.name);
	else NSLog(@"Something went wrong :/");
}];
```

```swift
// Set your API key
TravelKit.shared().apiKey = "<YOUR_API_KEY_GOES_HERE>"
	
// Create query to get Top 10 Sightseeing Places in London
let query = TKPlacesQuery()
query.parentIDs = ["city:1"]
query.levels = .POI
query.categories = ["sightseeing"]
query.limit = 10
	
// Perform query and print a message containing the first item
TravelKit.shared().places(for: query) { (places, error) in
	if let place = places?.first { print("Let's visit \(place.name)!") }
	else { print("Something went wrong :/") }
}
```

The *API key* must be provided, otherwise using any methods listed below will result in an error being returned by the completion block.

*TravelKit* is very easily testable using _Swift Playgrounds_ – a sample playground is provided together with the workspace attached.

## Basic Classes

Class               | Description
:-------------------|:---------------------
**`TravelKit`**       | Singleton instance for fetching data
**`TKPlace`**         | Basic `Place` entity
**`TKPlaceDetail`**   | Detailed object including additional `Place` properties
**`TKPlacesQuery`**   | Entity used when querying for `Places`
**`TKMedium`**        | Basic `Medium` entity
**`TKReference`**     | External `Reference` link
