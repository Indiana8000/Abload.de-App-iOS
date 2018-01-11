//
//  NetworkManager.h
//  Abloadtool
//
//  Created by Andreas Kreisl on 05.10.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#define cURL_BASE @"https://www.abload.de"
#define cURL_API @"https://www.abload.de/api/"

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <XMLDictionary/XMLDictionary.h>

typedef void (^NetworkManagerSuccess)(NSDictionary *responseObject);
typedef void (^NetworkManagerFailure)(NSString *failureReason, NSInteger statusCode);

@interface NetworkManager : NSObject {
}
    + (id)sharedManager;
    + (void)showMessage:(NSString*) msg;

    - (void)showProgressHUD;
    - (void)hideProgressHUD;

    - (void)showLoginWithViewController:(UIViewController*)viewController andCallback:(void(^)(void))successCallback;
    - (void)logoutWithCallback:(void(^)(void))successCallback;
    - (void)tokenCheckWithSuccess:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure;
    - (void)authenticateWithEmail:(NSString*)email password:(NSString*)password success:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure;

    - (void)saveSelectedGallery:(NSNumber*) gid;
    - (void)saveSelectedResolution:(NSString*) name;
    - (void)saveSelectedScale:(NSNumber*) scale;

    - (void)getGalleryList:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure;
    - (void)getImageList:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure;

    - (void)createGalleryWithName:(NSString*)name andDesc:(NSString*)desc success:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure;
    - (void)deleteGalleryWithID:(NSInteger)gid andImages:(NSInteger)img success:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure;

    - (void)saveImage:(NSData*) image;
    - (void)uploadImagesNow:(NSMutableDictionary*)metaImage success:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure;


@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSNumber* loggedin;
@property (nonatomic, strong) NSNumber* noad;
@property (nonatomic, strong) NSNumber* motd_time;

@property (nonatomic, strong) NSArray* gallery;
@property (nonatomic, strong) NSNumber* selectedGallery;
@property (nonatomic, strong) NSString* selectedResolution;
@property (nonatomic, strong) NSNumber* selectedScale;
@property (nonatomic, strong) NSArray* listScaling;

@property (nonatomic, strong) NSMutableDictionary* imageList;

@property (nonatomic, strong) NSString* uploadPath;
@property NSInteger uploadNumber;
@property (nonatomic, strong) NSMutableArray* uploadImages;

@end
