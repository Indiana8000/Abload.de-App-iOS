//
//  NetworkManager.h
//  Abloadtool
//
//  Created by Andreas Kreisl on 05.10.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <XMLDictionary/XMLDictionary.h>

typedef void (^NetworkManagerSuccess)(NSDictionary *responseObject);
typedef void (^NetworkManagerFailure)(NSString *failureReason, NSInteger statusCode);

@interface NetworkManager : NSObject {
    NSArray* gallery;
}
    + (id)sharedManager;

    - (void)showLoginWithViewController:(UIViewController*)viewController andCallback:(void(^)(void))successCallback;
    - (void)tokenCheckWithSuccess:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure;
    - (void)authenticateWithEmail:(NSString*)email password:(NSString*)password success:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure;
    - (void)getGalleryList:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure;
    - (void)getImageList:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure;

@property (nonatomic, strong) NSNumber* loggedin;
@property (nonatomic, strong) NSArray* gallery;
@property (nonatomic, strong) NSArray* images;


@end
