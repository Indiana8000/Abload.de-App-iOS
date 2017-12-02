//
//  NetworkManager.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 05.10.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//


//#define BASE_URL @"http://www.bluepaw.de/"
#define BASE_URL @"https://www.abload.de/api/"

#import "NetworkManager.h"


@interface NetworkManager()
    @property (nonatomic, strong) AFHTTPSessionManager *networkingManager;
    @property (nonatomic, strong) MBProgressHUD *progressHUD;
@end


@implementation NetworkManager
@synthesize gallery;
@synthesize motd_time;

#pragma mark - Constructors

static NetworkManager *sharedManager = nil;

+ (NetworkManager*)sharedManager {
    static dispatch_once_t once;
    dispatch_once(&once, ^
                  {
                      sharedManager = [[NetworkManager alloc] init];
                  });
    return sharedManager;
}

- (id)init {
    NSLog(@"Net - init");
    if ((self = [super init])) {
        self.loggedin = [NSNumber numberWithInteger:0]; // Not Logged In
        self.noad = [NSNumber numberWithInteger:0]; // Show Ad

        //NSLog(@"PATH: %@",[[NSBundle mainBundle] bundlePath] );
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"scalemethods" ofType:@"plist"];
        self.listScaling = [NSArray arrayWithContentsOfFile:plistPath];
        
        self.images = [[NSMutableDictionary alloc] initWithCapacity:100];
        [self loadDefaults];
        
        //[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(initCheck) userInfo:nil repeats:NO];
    }
    return self;
}

- (void)initCheck {
    [self tokenCheckWithSuccess:^(NSDictionary *responseObject) {
        //NSLog(@"NET - initCheck Success: \r\n%@", responseObject);
    }  failure:^(NSString *failureReason, NSInteger statusCode) {
        //NSLog(@"NET - initCheck Error: %@", failureReason);
    }];
}

- (void)showLoginWithViewController:(UIViewController*)viewController andCallback:(void(^)(void))successCallback  {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Abloadtool"
                                                                   message:NSLocalizedString(@"Login", @"Dialog Login")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Dialog Login") style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action) {
                                                   [self authenticateWithEmail:[[alert.textFields objectAtIndex:0] text] password:[[alert.textFields objectAtIndex:1] text] success:^(id responseObject) {
                                                       successCallback();
                                                   } failure:^(NSString *failureReason, NSInteger statusCode) {
                                                       [NetworkManager showMessage:failureReason];
                                                   }];
                                               }];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Dialog Login") style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                                   }];
    
    [alert addAction:ok];
    [alert addAction:cancel];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"Userid or Email", @"Dialog Login");
        textField.keyboardType = UIKeyboardTypeEmailAddress;
    }];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"Password", @"Dialog Login");
        textField.keyboardType = UIKeyboardTypeDefault;
        textField.secureTextEntry = YES;
    }];

    UIViewController *rootController = [[[[UIApplication sharedApplication]delegate] window] rootViewController];
    [viewController presentViewController:alert animated:YES completion:nil];
    
}

#pragma mark - Helper

- (NSMutableDictionary*)getBaseParams {
    NSMutableDictionary *baseParams = [NSMutableDictionary dictionary];
    [baseParams setObject:@"1.0.0" forKey:@"api_version"];
    [baseParams setObject:[NSString stringWithFormat:@"%ld", UIDevice.currentDevice.userInterfaceIdiom] forKey:@"device_type"];
    return baseParams;
}

- (id)getSecurityPolicy {
    return [AFSecurityPolicy defaultPolicy];
    /* AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    [policy setAllowInvalidCertificates:YES];
    [policy setValidatesDomainName:NO];
    return policy; */
}

- (void)showProgressHUD {
    [self hideProgressHUD];
    self.progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
    [self.progressHUD removeFromSuperViewOnHide];
    self.progressHUD.bezelView.color = [UIColor colorWithWhite:0.0 alpha:1.0];
    self.progressHUD.contentColor = [UIColor whiteColor];
}

- (void)hideProgressHUD {
    if (self.progressHUD != nil) {
        [self.progressHUD hideAnimated:YES];
        [self.progressHUD removeFromSuperview];
        self.progressHUD = nil;
    }
}

+ (void)showMessage:(NSString*) msg {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Abloadtool"
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Dialog Generic") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    [alert addAction:ok];
    [[[UIApplication sharedApplication] delegate].window.rootViewController presentViewController:alert animated:YES completion:nil];
}

#pragma mark - AbloadAPI

- (AFHTTPSessionManager*)getNetworkingManager {
    if (self.networkingManager == nil) {
        self.networkingManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:BASE_URL]];
        self.networkingManager.requestSerializer = [AFHTTPRequestSerializer serializer];
        [self.networkingManager.requestSerializer setValue:@"Abloadtool" forHTTPHeaderField:@"User-Agent"];
        self.networkingManager.responseSerializer = [AFXMLParserResponseSerializer serializer];
        self.networkingManager.responseSerializer.acceptableContentTypes = [self.networkingManager.responseSerializer.acceptableContentTypes setByAddingObjectsFromArray:@[@"text/html", @"application/xml", @"text/xml"]];
        self.networkingManager.securityPolicy = [self getSecurityPolicy];
    }
    return self.networkingManager;
}

- (void)tokenCheckWithSuccess:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults objectForKey:@"token"];
    if (token == nil || [token length] == 0) {
        self.loggedin = [NSNumber numberWithInteger:0];
        if (failure != nil) {
            failure(NSLocalizedString(@"Invalid Session", @"AFNetworking"), -1);
        }
        return;
    }
    NSMutableDictionary *params = [self getBaseParams];
    [params setObject:token forKey:@"session"];
    [[self getNetworkingManager] POST:@"user" parameters:params progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSDictionary *tmpDict = [NSDictionary dictionaryWithXMLParser:responseObject];
        NSLog(@"NET - tokenCheckWithSuccess:\r\n%@", tmpDict);
        if ( [[[tmpDict objectForKey:@"status"] objectForKey:@"_code"] intValue]  == 801 ) {
            NSString *newToken = [[tmpDict objectForKey:@"login"] objectForKey:@"_session"];
            [defaults setObject:newToken forKey:@"token"];
            if ( [tmpDict objectForKey:@"motd"] && [[[tmpDict objectForKey:@"motd"] objectForKey:@"_time"] intValue] > [self.motd_time intValue] ) {
                self.motd_time = [NSNumber numberWithInt:[[[tmpDict objectForKey:@"motd"] objectForKey:@"_time"] intValue]];
                [defaults setObject:self.motd_time forKey:@"motd_time"];
                [NetworkManager showMessage:[[tmpDict objectForKey:@"motd"] objectForKey:@"_text"]];
            }
            [defaults synchronize];
            self.loggedin = [NSNumber numberWithInteger:1];
            NSString *tmpStr = [[tmpDict objectForKey:@"login"] objectForKey:@"_disable_advertising"];
            if ([tmpStr compare:@"true"] == NSOrderedSame) {
                NSLog(@"NO AD's!");
                self.noad = [NSNumber numberWithInteger:1];
            }
            if ( [[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"] ) {
                [self saveGalleryList:[[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"]];
            }
            if (success != nil) {
                success(tmpDict);
            }
        } else {
            self.loggedin = [NSNumber numberWithInteger:0];
            if (failure != nil) {
                failure([[tmpDict objectForKey:@"status"] objectForKey:@"__text"], [[[tmpDict objectForKey:@"status"] objectForKey:@"_code"] intValue]);
            }
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        self.loggedin = [NSNumber numberWithInteger:-1];
        if (failure != nil) {
            failure([NSString stringWithFormat:@"%@", [error localizedDescription]], ((NSHTTPURLResponse*)operation.response).statusCode);
        }
    }];
}

- (void)authenticateWithEmail:(NSString*)email password:(NSString*)password success:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure {
    if (email != nil && [email length] > 0 && password != nil && [password length] > 0) {
        [self showProgressHUD];
        NSMutableDictionary *params = [self getBaseParams];
        [params setObject:email forKey:@"name"];
        [params setObject:password forKey:@"password"];
        [[self getNetworkingManager] POST:@"login" parameters:params progress:nil success:^(NSURLSessionTask *task, id responseObject) {
            [self hideProgressHUD];
            NSDictionary *tmpDict = [NSDictionary dictionaryWithXMLParser:responseObject];
            NSLog(@"NET - authenticateWithEmail:\r\n%@", tmpDict);
            if ( [[[tmpDict objectForKey:@"status"] objectForKey:@"_code"] intValue]  == 801 ) {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                NSString *newToken = [[tmpDict objectForKey:@"login"] objectForKey:@"_session"];
                [defaults setObject:newToken forKey:@"token"];
                if ( [tmpDict objectForKey:@"motd"] && [[[tmpDict objectForKey:@"motd"] objectForKey:@"_time"] intValue] > [self.motd_time intValue] ) {
                    self.motd_time = [NSNumber numberWithInt:[[[tmpDict objectForKey:@"motd"] objectForKey:@"_time"] intValue]];
                    [defaults setObject:self.motd_time forKey:@"motd_time"];
                    [NetworkManager showMessage:[[tmpDict objectForKey:@"motd"] objectForKey:@"_text"]];
                }
                [defaults synchronize];
                self.loggedin = [NSNumber numberWithInteger:1];
                NSString *tmpStr = [[tmpDict objectForKey:@"login"] objectForKey:@"_disable_advertising"];
                if ([tmpStr compare:@"true"] == NSOrderedSame) {
                    NSLog(@"NO AD's!");
                    self.noad = [NSNumber numberWithInteger:1];
                }
                if ( [[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"] ) {
                    [self saveGalleryList:[[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"]];
                }
                if (success != nil) {
                    success(tmpDict);
                }
            } else {
                self.loggedin = [NSNumber numberWithInteger:0];
                if (failure != nil) {
                    failure([[tmpDict objectForKey:@"status"] objectForKey:@"__text"], [[[tmpDict objectForKey:@"status"] objectForKey:@"_code"] intValue]);
                }
            }
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            self.loggedin = [NSNumber numberWithInteger:-1];
            [self hideProgressHUD];
            if (failure != nil) {
                failure([NSString stringWithFormat:@"%@", [error localizedDescription]], ((NSHTTPURLResponse*)operation.response).statusCode);
            }
        }];
    } else {
        if (failure != nil) {
            failure(@"Userid/Email and Password Required", -1);
        }
    }
}

#pragma mark - Gallery

- (void)loadDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"gallery"]) {
        self.gallery = [defaults objectForKey:@"gallery"];
        NSLog(@"NET - loadGallery %ld", [self.gallery count]);
    } else {
        self.gallery = [[NSArray alloc] init];
        NSLog(@"NET - loadGallery NEW");
    }
    
    if ([defaults objectForKey:@"motd_time"]) {
        self.motd_time = [defaults objectForKey:@"motd_time"];
        NSLog(@"NET - mod_time %ld", [self.motd_time longValue]);
    } else {
        self.motd_time =  [NSNumber numberWithInt:0];
        NSLog(@"NET - mod_time NEW");
    }
    
    if ([defaults objectForKey:@"gallery_selected"]) {
        self.selectedGallery = [defaults objectForKey:@"gallery_selected"];
        NSLog(@"NET - selectedGallery %ld", [self.selectedGallery longValue]);
    } else {
        self.selectedGallery =  [NSNumber numberWithInt:0];
        NSLog(@"NET - selectedGallery NEW");
    }

    if ([defaults objectForKey:@"resolution_selected"]) {
        self.selectedResolution = [defaults objectForKey:@"resolution_selected"];
        NSLog(@"NET - selectedResolution %@", self.selectedResolution);
    } else {
        self.selectedResolution = NSLocalizedString(@"Keep Original", @"Settings");
        NSLog(@"NET - selectedResolution NEW");
    }

    if ([defaults objectForKey:@"scale_selected"]) {
        self.selectedScale = [defaults objectForKey:@"scale_selected"];
        NSLog(@"NET - selectedScale %ld", [self.selectedScale longValue]);
    } else {
        self.selectedScale =  [NSNumber numberWithInt:0];
        NSLog(@"NET - selectedScale NEW");
    }

}

- (void)saveGalleryList:(NSArray*) gallery {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:gallery forKey:@"gallery"];
    [defaults synchronize];
    self.gallery = gallery;
}

- (void)saveSelectedGallery:(NSNumber*) gid {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:gid forKey:@"gallery_selected"];
    [defaults synchronize];
    self.selectedGallery = gid;
}

- (void)saveSelectedResolution:(NSString*) name {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:name forKey:@"resolution_selected"];
    [defaults synchronize];
    self.selectedResolution = name;
}

- (void)saveSelectedScale:(NSNumber*) scale {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:scale forKey:@"scale_selected"];
    [defaults synchronize];
    self.selectedScale = scale;
}


- (void)getGalleryList:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults objectForKey:@"token"];
    if (token == nil || [token length] == 0) {
        if (failure != nil) {
            failure(NSLocalizedString(@"Invalid Session", @"AFNetworking"), -1);
        }
        return;
    }
    NSMutableDictionary *params = [self getBaseParams];
    [params setObject:token forKey:@"session"];
    [[self getNetworkingManager] POST:@"gallery/list" parameters:params progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSDictionary *tmpDict = [NSDictionary dictionaryWithXMLParser:responseObject];
        NSLog(@"NET - getGalleryList:\r\n%@", tmpDict);
        if ( [[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"] ) {
            [self saveGalleryList:[[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"]];
        }
        if (success != nil) {
            success(tmpDict);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        if (failure != nil) {
            failure([NSString stringWithFormat:@"%@", [error localizedDescription]], ((NSHTTPURLResponse*)operation.response).statusCode);
        }
    }];
}

- (void)createGalleryWithName:(NSString*)name andDesc:(NSString*)desc success:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults objectForKey:@"token"];
    if (token == nil || [token length] == 0) {
        if (failure != nil) {
            failure(NSLocalizedString(@"Invalid Session", @"AFNetworking"), -1);
        }
        return;
    }
    NSMutableDictionary *params = [self getBaseParams];
    [params setObject:token forKey:@"session"];
    [params setObject:name forKey:@"name"];
    [params setObject:desc forKey:@"desc"];
    [[self getNetworkingManager] POST:@"gallery/new" parameters:params progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSDictionary *tmpDict = [NSDictionary dictionaryWithXMLParser:responseObject];
        NSLog(@"NET - createGalleryWithName:\r\n%@", tmpDict);
        if ( [[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"] ) {
            [self saveGalleryList:[[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"]];
        }
        if ( [[[tmpDict objectForKey:@"status"] objectForKey:@"_code"] intValue]  == 605 ) {
            if (success != nil) {
                success(tmpDict);
            }
        } else {
            if (failure != nil) {
                failure([[tmpDict objectForKey:@"status"] objectForKey:@"__text"], [[[tmpDict objectForKey:@"status"] objectForKey:@"_code"] intValue]);
            }
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        if (failure != nil) {
            failure([NSString stringWithFormat:@"%@", [error localizedDescription]], ((NSHTTPURLResponse*)operation.response).statusCode);
        }
    }];
}

- (void)deleteGalleryWithID:(NSInteger)gid andImages:(NSInteger)img success:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults objectForKey:@"token"];
    if (token == nil || [token length] == 0) {
        if (failure != nil) {
            failure(NSLocalizedString(@"Invalid Session", @"AFNetworking"), -1);
        }
        return;
    }
    NSMutableDictionary *params = [self getBaseParams];
    [params setObject:token forKey:@"session"];
    [params setObject:[NSString stringWithFormat:@"%ld", gid] forKey:@"gid"];
    [params setObject:[NSString stringWithFormat:@"%ld", img] forKey:@"img"];
    [[self getNetworkingManager] POST:@"gallery/del" parameters:params progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSDictionary *tmpDict = [NSDictionary dictionaryWithXMLParser:responseObject];
        NSLog(@"NET - deleteGalleryWithID:\r\n%@", tmpDict);
        if ( [[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"] ) {
            [self saveGalleryList:[[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"]];
        }
        if ( [[[tmpDict objectForKey:@"status"] objectForKey:@"_code"] intValue]  == 608 || [[[tmpDict objectForKey:@"status"] objectForKey:@"_code"] intValue]  == 609 ) {
            if (success != nil) {
                success(tmpDict);
            }
        } else {
            if (failure != nil) {
                failure([[tmpDict objectForKey:@"status"] objectForKey:@"__text"], [[[tmpDict objectForKey:@"status"] objectForKey:@"_code"] intValue]);
            }
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        if (failure != nil) {
            failure([NSString stringWithFormat:@"%@", [error localizedDescription]], ((NSHTTPURLResponse*)operation.response).statusCode);
        }
    }];
}

#pragma mark - Images

- (void)getImageList:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults objectForKey:@"token"];
    if (token == nil || [token length] == 0) {
        if (failure != nil) {
            failure(NSLocalizedString(@"Invalid Session", @"AFNetworking"), -1);
        }
        return;
    }
    NSMutableDictionary *params = [self getBaseParams];
    [params setObject:token forKey:@"session"];
    [[self getNetworkingManager] POST:@"images" parameters:params progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSDictionary *tmpDict = [NSDictionary dictionaryWithXMLParser:responseObject];
        NSLog(@"NET - getImageList:\r\n%@", tmpDict);
        if ( [[tmpDict objectForKey:@"images"] objectForKey:@"image"] ) {
            //[self setImages:[[tmpDict objectForKey:@"images"] objectForKey:@"image"]];
        }
        if ( [[[tmpDict objectForKey:@"status"] objectForKey:@"_code"] intValue]  == 801 ) {
            if (success != nil) {
                success(tmpDict);
            }
        } else {
            if (failure != nil) {
                failure([[tmpDict objectForKey:@"status"] objectForKey:@"__text"], [[[tmpDict objectForKey:@"status"] objectForKey:@"_code"] intValue]);
            }
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        if (failure != nil) {
            failure([NSString stringWithFormat:@"%@", [error localizedDescription]], ((NSHTTPURLResponse*)operation.response).statusCode);
        }
    }];
}



@end
