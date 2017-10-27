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
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(initCheck) userInfo:nil repeats:NO];
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
                                                                   message:@"Anmeldung"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action) {
                                                   //Do Some action here
                                                   NSLog(@"%@", [[alert.textFields objectAtIndex:0] text]);
                                                   NSLog(@"%@", [[alert.textFields objectAtIndex:1] text]);
                                                   [self authenticateWithEmail:[[alert.textFields objectAtIndex:0] text] password:[[alert.textFields objectAtIndex:1] text] success:^(id responseObject) {
                                                       // Save User Credentials and show content
                                                       successCallback();
                                                   } failure:^(NSString *failureReason, NSInteger statusCode) {
                                                       // Explain to user why authentication failed
                                                   }];
                                               }];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                                   }];
    
    [alert addAction:ok];
    [alert addAction:cancel];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Benutzername oder E-Mail-Adresse";
        textField.keyboardType = UIKeyboardTypeEmailAddress;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Passwort";
        textField.keyboardType = UIKeyboardTypeDefault;
        textField.secureTextEntry = YES;
    }];

    //UIViewController *rootController = [[[[UIApplication sharedApplication]delegate] window] rootViewController];
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

- (NSString*)getError:(NSError*)error {
    if (error != nil) {
        NSData *errorData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData: errorData options:kNilOptions error:nil];
        if (responseObject != nil && [responseObject isKindOfClass:[NSDictionary class]] && [responseObject objectForKey:@"message"] != nil && [[responseObject objectForKey:@"message"] length] > 0) {
            return [responseObject objectForKey:@"message"];
        }
    }
    return @"Server Error. Please try again later";
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

#pragma mark - Functions

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
        if (failure != nil) {
            failure(@"Invalid Token", -1);
        }
        return;
    }
    NSMutableDictionary *params = [self getBaseParams];
    [params setObject:token forKey:@"session"];
    [[self getNetworkingManager] POST:@"user" parameters:params progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSDictionary *tmpDict = [NSDictionary dictionaryWithXMLParser:responseObject];
        //NSLog(@"NET - Check: %@", tmpDict);
        if ( [[[tmpDict objectForKey:@"status"] objectForKey:@"_code"] intValue]  == 801 ) {
            NSString *newToken = [[tmpDict objectForKey:@"login"] objectForKey:@"_session"];
            [defaults setObject:newToken forKey:@"token"];
            self.loggedin = [NSNumber numberWithInteger:1];
            if ( [[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"] ) {
                [self setGallery:[[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"]];
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
        self.loggedin = [NSNumber numberWithInteger:0];
        if (failure != nil) {
            failure([NSString stringWithFormat:@"%@", error], ((NSHTTPURLResponse*)operation.response).statusCode);
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
            //NSLog(@"NET - Login: %@", tmpDict);
            if ( [[[tmpDict objectForKey:@"status"] objectForKey:@"_code"] intValue]  == 801 ) {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                NSString *newToken = [[tmpDict objectForKey:@"login"] objectForKey:@"_session"];
                [defaults setObject:newToken forKey:@"token"];
                self.loggedin = [NSNumber numberWithInteger:1];
                if ( [[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"] ) {
                    [self setGallery:[[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"]];
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
            self.loggedin = [NSNumber numberWithInteger:0];
            [self hideProgressHUD];
            if (failure != nil) {
                failure([NSString stringWithFormat:@"%@", error], ((NSHTTPURLResponse*)operation.response).statusCode);
            }
        }];
    } else {
        if (failure != nil) {
            failure(@"Email and Password Required", -1);
        }
    }
}

- (void)getGalleryList:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults objectForKey:@"token"];
    if (token == nil || [token length] == 0) {
        if (failure != nil) {
            failure(@"Invalid Token", -1);
        }
        return;
    }
    NSMutableDictionary *params = [self getBaseParams];
    [params setObject:token forKey:@"session"];
    [[self getNetworkingManager] POST:@"gallery/list" parameters:params progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSDictionary *tmpDict = [NSDictionary dictionaryWithXMLParser:responseObject];
        if ( [[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"] ) {
            [self setGallery:[[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"]];
        }
        if (success != nil) {
            success(tmpDict);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        if (failure != nil) {
            failure([NSString stringWithFormat:@"%@", error], ((NSHTTPURLResponse*)operation.response).statusCode);
        }
    }];
}

- (void)getImageList:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults objectForKey:@"token"];
    if (token == nil || [token length] == 0) {
        if (failure != nil) {
            failure(@"Invalid Token", -1);
        }
        return;
    }
    NSMutableDictionary *params = [self getBaseParams];
    [params setObject:token forKey:@"session"];
    [[self getNetworkingManager] POST:@"images" parameters:params progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSDictionary *tmpDict = [NSDictionary dictionaryWithXMLParser:responseObject];
        if ( [[tmpDict objectForKey:@"images"] objectForKey:@"image"] ) {
            [self setImages:[[tmpDict objectForKey:@"images"] objectForKey:@"image"]];
        }
        if (success != nil) {
            success(tmpDict);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        if (failure != nil) {
            failure([NSString stringWithFormat:@"%@", error], ((NSHTTPURLResponse*)operation.response).statusCode);
        }
    }];
}



@end
