//
//  NetworkManager.h
//  Abloadtool
//
//  Created by Andreas Kreisl on 05.10.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#define cURL_BASE @"https://abload.de"
#define cURL_API  @"https://abload.de/api/"

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <XMLDictionary/XMLDictionary.h>

#import "UIImage+Scale.h"


typedef void (^NetworkManagerSuccess)(NSDictionary *responseObject);
typedef void (^NetworkManagerFailure)(NSString *failureReason, NSInteger statusCode);


@interface NetworkManager : NSObject

#pragma mark - Constructor
+ (id)sharedManager;

#pragma mark - Help-Functions
+ (void)showMessage:(NSString*) msg;
- (void)showProgressHUD;
- (void)hideProgressHUD;

#pragma mark - Session
@property NSInteger loggedin;
@property NSInteger noad;
@property NSDate* lastRefresh;
- (NSString*)getSessionKey;

#pragma mark - ImageFiles
@property NSMutableArray* uploadImages;
- (void)saveImageToDisk:(NSData*) imageData;
- (void)checkAndLoadSharedImages;
- (void)removeImageFromDisk:(NSInteger) imageIndex andList:(BOOL) includeList;

#pragma mark - Gallery
@property NSArray* galleryList;
@property NSInteger settingGallerySelected;
- (void)saveGalleryList:(NSArray*) gallery;
- (void)saveGallerySorted:(NSInteger) gallerySorted;
- (void)saveGallerySelected:(NSInteger) galleryID;

#pragma mark - Settings
@property NSArray* settingAvailableScalingList;
@property NSArray* settingAvailableOutputLinkList;
@property NSString* settingResolutionSelected;
@property NSInteger settingScaleSelected;
@property NSInteger settingOutputLinkSelected;
- (void)saveResolutionSelected:(NSString*) name;
- (void)saveScaleSelected:(NSInteger) newScale;
- (void)saveOutputLinkSelected:(NSInteger) newOutputLinks;

#pragma mark - HTTP
@property NSURLSessionDataTask* uploadTask;
@property NSMutableDictionary* imageList;
@property NSArray* imageLast;
- (void)checkSessionKeyWithSuccess:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure;
- (void)showLoginWithCallback:(void(^)(void))successCallback;
- (void)logoutWithCallback:(void(^)(void))successCallback;
- (NSString*)generateLinkForImage:(NSString*) name;
- (NSString*)generateLinkForGallery:(NSString*) name;

#pragma mark - HTTP-Gallery
- (void)getGalleryList:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure;
- (void)createGalleryWithName:(NSString*)name andDesc:(NSString*)desc success:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure;
- (void)deleteGalleryWithID:(NSInteger)gid andImages:(NSInteger)img success:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure;

#pragma mark - HTTP-Image
- (void)getImageListForGroup:(NSString*) gid success:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure;
- (void)uploadImageWithID:(NSInteger)imageID progress:(void (^)(double fraction))progress success:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure;
- (void)deleteImageWithName:(NSString*) filename success:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure;


@end
