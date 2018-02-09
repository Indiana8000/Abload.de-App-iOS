//
//  NetworkManager.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 05.10.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//


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
        self.imageList = [[NSMutableDictionary alloc] initWithCapacity:10];
        self.imageLast = [[NSArray alloc] init];

        // Init Scaling Enumeration
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"scalemethods" ofType:@"plist"];
        self.listScaling = [NSArray arrayWithContentsOfFile:plistPath];
        
        // Init OutpuLink Enumeration
        plistPath = [[NSBundle mainBundle] pathForResource:@"outputlinks" ofType:@"plist"];
        self.listOutputLinks = [NSArray arrayWithContentsOfFile:plistPath];

        // Set Image Upload Path
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        self.uploadPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"images"];
        if(![[NSFileManager defaultManager] fileExistsAtPath:self.uploadPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:self.uploadPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        // Load Cached Upload Images
        self.uploadImages = [[NSMutableArray alloc] initWithCapacity:10];
        NSFileManager *localFileManager=[[NSFileManager alloc] init];
        NSDirectoryEnumerator *dirEnum = [localFileManager enumeratorAtPath:self.uploadPath];
        NSString *file;
        while ((file = [dirEnum nextObject])) {
            if ([[file pathExtension] isEqualToString: @"jpeg"]) {
                NSString* filePath = [self.uploadPath stringByAppendingPathComponent:file];
                NSNumber* fileSize = [NSNumber numberWithLong:[[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize]];
                NSMutableDictionary* photoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:filePath, @"_path", file, @"_name", fileSize, @"_size", @"0", @"_uploaded", nil];
                [self.uploadImages addObject:photoDict];
            }
        }

        // Load Defaults
        [self loadDefaults];
        
        // Check for valid token and internet connection
        // moved to UploadTableViewController
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
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Abloadtool", @"Abloadtool")
                                                                   message:NSLocalizedString(@"net_login_title", @"NetworkManager")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"net_login_ok", @"NetworkManager") style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action) {
                                                   [self authenticateWithEmail:[[alert.textFields objectAtIndex:0] text] password:[[alert.textFields objectAtIndex:1] text] success:^(id responseObject) {
                                                       if(successCallback != nil) successCallback();
                                                   } failure:^(NSString *failureReason, NSInteger statusCode) {
                                                       [NetworkManager showMessage:failureReason];
                                                   }];
                                               }];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"net_login_cancel", @"NetworkManager") style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                                   }];
    
    [alert addAction:ok];
    [alert addAction:cancel];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"net_login_label_userid", @"NetworkManager");
        textField.keyboardType = UIKeyboardTypeEmailAddress;
    }];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"net_login_label_password", @"NetworkManager");
        textField.keyboardType = UIKeyboardTypeDefault;
        textField.secureTextEntry = YES;
    }];

    [viewController presentViewController:alert animated:YES completion:nil];
}

- (void)logoutWithCallback:(void(^)(void))successCallback {
    self.token = @"";
    [self setToken:@""];
    self.loggedin = [NSNumber numberWithInteger:0];;
    self.noad = [NSNumber numberWithInteger:0];;
    successCallback();
}

#pragma mark - Helper

- (NSMutableDictionary*)getBaseParams {
    NSMutableDictionary *baseParams = [NSMutableDictionary dictionary];
    [baseParams setObject:@"1.0.0" forKey:@"api_version"];
    [baseParams setObject:@"iOS" forKey:@"device_vendor"];
    [baseParams setObject:[NSString stringWithFormat:@"%ld", UIDevice.currentDevice.userInterfaceIdiom] forKey:@"device_type"];
    return baseParams;
}

- (id)getSecurityPolicy {
    return [AFSecurityPolicy defaultPolicy];
    /*
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    [policy setAllowInvalidCertificates:YES];
    [policy setValidatesDomainName:NO];
    return policy;
    */
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
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Abloadtool", @"Abloadtool")
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"btn_ok", @"Abloadtool") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    [alert addAction:ok];
    [[[UIApplication sharedApplication] delegate].window.rootViewController presentViewController:alert animated:YES completion:nil];
}

#pragma mark - AbloadAPI

- (AFHTTPSessionManager*)getNetworkingManager {
    if (self.networkingManager == nil) {
        self.networkingManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:cURL_API]];
        self.networkingManager.requestSerializer = [AFHTTPRequestSerializer serializer];
        [self.networkingManager.requestSerializer setValue:cURL_AGENT forHTTPHeaderField:@"User-Agent"];
        self.networkingManager.responseSerializer = [AFXMLParserResponseSerializer serializer];
        self.networkingManager.responseSerializer.acceptableContentTypes = [self.networkingManager.responseSerializer.acceptableContentTypes setByAddingObjectsFromArray:@[@"text/html", @"application/xml", @"text/xml"]];
        self.networkingManager.securityPolicy = [self getSecurityPolicy];
    }
    return self.networkingManager;
}

- (void)tokenCheckWithSuccess:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure {
    if (self.token == nil || [self.token length] == 0) {
        self.loggedin = [NSNumber numberWithInteger:0];
        if (failure != nil) {
            failure(NSLocalizedString(@"error_session_invalid", @"NetworkManager"), -1);
        }
        return;
    }
    NSMutableDictionary *params = [self getBaseParams];
    [params setObject:self.token forKey:@"session"];
    [[self getNetworkingManager] POST:@"user" parameters:params progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSDictionary *tmpDict = [NSDictionary dictionaryWithXMLParser:responseObject];
        NSLog(@"tokenCheckWithSuccess:\r\n%@", tmpDict);
        if ( [[[tmpDict objectForKey:@"status"] objectForKey:@"_code"] intValue]  == 801 ) {
            self.token = [[tmpDict objectForKey:@"login"] objectForKey:@"_session"];
            [self saveToken:self.token];
            if ( [tmpDict objectForKey:@"motd"] && [[[tmpDict objectForKey:@"motd"] objectForKey:@"_time"] intValue] > [self.motd_time intValue] ) {
                self.motd_time = [NSNumber numberWithInt:[[[tmpDict objectForKey:@"motd"] objectForKey:@"_time"] intValue]];
                [self saveMotdTime:self.motd_time];
                [NetworkManager showMessage:[[tmpDict objectForKey:@"motd"] objectForKey:@"_text"]];
            }
            self.loggedin = [NSNumber numberWithInteger:1];
            NSString *tmpStr = [[tmpDict objectForKey:@"login"] objectForKey:@"_disable_advertising"];
            if ([tmpStr compare:@"true"] == NSOrderedSame) {
                self.noad = [NSNumber numberWithInteger:1];
            }
            if ( [[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"] ) {
                [self saveGalleryList:[[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"]];
            }
            if ( [[tmpDict objectForKey:@"lastimages"] objectForKey:@"image"] ) {
                self.imageLast = [[tmpDict objectForKey:@"lastimages"] objectForKey:@"image"];
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
            if ( [[[tmpDict objectForKey:@"status"] objectForKey:@"_code"] intValue]  == 801 ) {
                self.token = [[tmpDict objectForKey:@"login"] objectForKey:@"_session"];
                [self saveToken:self.token];
                if ( [tmpDict objectForKey:@"motd"] && [[[tmpDict objectForKey:@"motd"] objectForKey:@"_time"] intValue] > [self.motd_time intValue] ) {
                    self.motd_time = [NSNumber numberWithInt:[[[tmpDict objectForKey:@"motd"] objectForKey:@"_time"] intValue]];
                    [self saveMotdTime:self.motd_time];
                    [NetworkManager showMessage:[[tmpDict objectForKey:@"motd"] objectForKey:@"_text"]];
                }
                self.loggedin = [NSNumber numberWithInteger:1];
                NSString *tmpStr = [[tmpDict objectForKey:@"login"] objectForKey:@"_disable_advertising"];
                if ([tmpStr compare:@"true"] == NSOrderedSame) {
                    self.noad = [NSNumber numberWithInteger:1];
                }
                if ( [[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"] ) {
                    [self saveGalleryList:[[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"]];
                }
                if ( [[tmpDict objectForKey:@"lastimages"] objectForKey:@"image"] ) {
                    self.imageLast = [[tmpDict objectForKey:@"lastimages"] objectForKey:@"image"];
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
            failure(NSLocalizedString(@"net_login_error_missingvalues", @"NetworkManager"), -1);
        }
    }
}

#pragma mark - Settings

- (void)loadDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([defaults objectForKey:@"token"]) {
        self.token = [defaults objectForKey:@"token"];
        NSLog(@"NET - token %@", self.token);
    } else {
        self.token = @"";
        NSLog(@"NET - token NEW");
    }
    
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
        self.selectedResolution = NSLocalizedString(@"label_keeporiginal", @"Settings");
        NSLog(@"NET - selectedResolution NEW");
    }

    if ([defaults objectForKey:@"scale_selected"]) {
        self.selectedScale = [defaults objectForKey:@"scale_selected"];
        NSLog(@"NET - selectedScale %ld", [self.selectedScale longValue]);
    } else {
        self.selectedScale =  [NSNumber numberWithInt:1];
        NSLog(@"NET - selectedScale NEW");
    }

    if ([defaults objectForKey:@"outputlinks_selected"]) {
        self.selectedOutputLinks = [defaults objectForKey:@"outputlinks_selected"];
        NSLog(@"NET - selectedOutputLinks %ld", [self.selectedOutputLinks longValue]);
    } else {
        self.selectedOutputLinks =  [NSNumber numberWithInt:0];
        NSLog(@"NET - selectedOutputLinks NEW");
    }

    if ([defaults objectForKey:@"upload_number"]) {
        self.uploadNumber = [defaults integerForKey:@"upload_number"];
        NSLog(@"NET - uploadNumber %ld / %ld", (long)self.uploadNumber, NSIntegerMax);
    } else {
        self.uploadNumber = 0;
        NSLog(@"NET - uploadNumber NEW");
    }
    
    if ([defaults objectForKey:@"gallery_sorted"]) {
        self.sortedGallery = [defaults objectForKey:@"gallery_sorted"];
        NSLog(@"NET - selectedScale %ld", [self.sortedGallery longValue]);
    } else {
        self.sortedGallery =  [NSNumber numberWithInt:0];
        NSLog(@"NET - selectedScale NEW");
    }
    
}

- (void)saveToken:(NSString*) token {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:token forKey:@"token"];
    [defaults synchronize];
}

- (void)saveGalleryList:(NSArray*) gallery {
    switch ([self.sortedGallery intValue]) {
        case 1:
            self.gallery = [gallery sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
                NSString *first = [(NSDictionary*)a objectForKey:@"_lastchange"];
                NSString *second = [(NSDictionary*)b objectForKey:@"_lastchange"];
                return [second compare:first];
            }];
            break;
        default:
            self.gallery = [gallery sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
                NSString *first = [(NSDictionary*)a objectForKey:@"_name"];
                NSString *second = [(NSDictionary*)b objectForKey:@"_name"];
                return [first compare:second];
            }];
            break;
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.gallery forKey:@"gallery"];
    [defaults synchronize];
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

- (void)saveSelectedOutputLinks:(NSNumber*) outputLinks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:outputLinks forKey:@"outputlinks_selected"];
    [defaults synchronize];
    self.selectedOutputLinks = outputLinks;
}

- (void)saveUploadNumber {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:self.uploadNumber forKey:@"upload_number"];
    [defaults synchronize];
}

- (void)saveMotdTime:(NSNumber*) motdTime {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:motdTime forKey:@"motd_time"];
    [defaults synchronize];
}

- (void)saveSortedGallery:(NSNumber*) sortedGallery {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:sortedGallery forKey:@"gallery_sorted"];
    [defaults synchronize];
    self.sortedGallery = sortedGallery;
}

#pragma mark - Gallery

- (void)getGalleryList:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure {
    if (self.token == nil || [self.token length] == 0) {
        if (failure != nil) {
            failure(NSLocalizedString(@"error_session_invalid", @"NetworkManager"), -1);
        }
        return;
    }
    NSMutableDictionary *params = [self getBaseParams];
    [params setObject:self.token forKey:@"session"];
    [[self getNetworkingManager] POST:@"gallery/list" parameters:params progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSDictionary *tmpDict = [NSDictionary dictionaryWithXMLParser:responseObject];
        if ( [[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"] ) {
            [self saveGalleryList:[[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"]];
            NSLog(@"%@", tmpDict);
        }
        if ( [[tmpDict objectForKey:@"lastimages"] objectForKey:@"image"] ) {
            self.imageLast = [[tmpDict objectForKey:@"lastimages"] objectForKey:@"image"];
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
    if (self.token == nil || [self.token length] == 0) {
        if (failure != nil) {
            failure(NSLocalizedString(@"error_session_invalid", @"NetworkManager"), -1);
        }
        return;
    }
    NSMutableDictionary *params = [self getBaseParams];
    [params setObject:self.token forKey:@"session"];
    [params setObject:name forKey:@"name"];
    [params setObject:desc forKey:@"desc"];
    [[self getNetworkingManager] POST:@"gallery/new" parameters:params progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSDictionary *tmpDict = [NSDictionary dictionaryWithXMLParser:responseObject];
        NSLog(@"createGalleryWithName:\r\n%@", tmpDict);
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
    if (self.token == nil || [self.token length] == 0) {
        if (failure != nil) {
            failure(NSLocalizedString(@"error_session_invalid", @"NetworkManager"), -1);
        }
        return;
    }
    NSMutableDictionary *params = [self getBaseParams];
    [params setObject:self.token forKey:@"session"];
    [params setObject:[NSString stringWithFormat:@"%ld", gid] forKey:@"gid"];
    [params setObject:[NSString stringWithFormat:@"%ld", img] forKey:@"img"];
    [[self getNetworkingManager] POST:@"gallery/del" parameters:params progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSDictionary *tmpDict = [NSDictionary dictionaryWithXMLParser:responseObject];
        NSLog(@"deleteGalleryWithID:\r\n%@", tmpDict);
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

- (void)getImageListForGroup:(NSString*) gid success:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure {
    if (self.token == nil || [self.token length] == 0) {
        if (failure != nil) {
            failure(NSLocalizedString(@"error_session_invalid", @"NetworkManager"), -1);
        }
        return;
    }
    NSMutableDictionary *params = [self getBaseParams];
    [params setObject:self.token forKey:@"session"];
    if([gid caseInsensitiveCompare:@"x"] != NSOrderedSame) [params setObject:gid forKey:@"gid"];
    [[self getNetworkingManager] POST:@"images" parameters:params progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSDictionary *tmpDict = [NSDictionary dictionaryWithXMLParser:responseObject];
        if ( [[tmpDict objectForKey:@"images"] objectForKey:@"image"] ) {
            self.imageList = [[NSMutableDictionary alloc] initWithCapacity:[self.gallery count]];
            if([[[tmpDict objectForKey:@"images"] objectForKey:@"image"] isKindOfClass:[NSArray class]]) {
                for(long i = 0;i < [[[tmpDict objectForKey:@"images"] objectForKey:@"image"] count];i++) {
                    NSString* gid = [[[[tmpDict objectForKey:@"images"] objectForKey:@"image"] objectAtIndex:i] objectForKey:@"_gid"];
                    if(!([gid intValue] > 0)) {
                        gid = @"x";
                    }
                    if(![self.imageList objectForKey:gid]) {
                        [self.imageList setObject:[[NSMutableArray alloc] initWithCapacity:1] forKey:gid];
                    }
                    [[self.imageList objectForKey:gid] addObject:[[[tmpDict objectForKey:@"images"] objectForKey:@"image"] objectAtIndex:i]];
                }
            } else { // Single Object
                NSString* gid = [[[tmpDict objectForKey:@"images"] objectForKey:@"image"]  objectForKey:@"_gid"];
                if(!([gid intValue] > 0)) {
                    gid = @"x";
                }
                if(![self.imageList objectForKey:gid]) {
                    [self.imageList setObject:[[NSMutableArray alloc] initWithCapacity:1] forKey:gid];
                }
                [[self.imageList objectForKey:gid] addObject:[[tmpDict objectForKey:@"images"] objectForKey:@"image"]];
            }
        }
        if ( [[tmpDict objectForKey:@"lastimages"] objectForKey:@"image"] ) {
            self.imageLast = [[tmpDict objectForKey:@"lastimages"] objectForKey:@"image"];
        }
        if ( [[[tmpDict objectForKey:@"status"] objectForKey:@"_code"] intValue]  == 801 || [[tmpDict objectForKey:@"images"] objectForKey:@"image"]) {
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

- (void)saveImage:(NSData*) image {
    if(self.uploadNumber >= NSIntegerMax)
        self.uploadNumber = 1;
    else
        self.uploadNumber++;
    [self saveUploadNumber];
    NSString *photoFile = [self.uploadPath stringByAppendingFormat:@"/mobile.%ld.jpeg", self.uploadNumber];
    [image writeToFile:photoFile atomically:YES];
    
    NSMutableDictionary* photoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:photoFile, @"_path", [photoFile lastPathComponent], @"_name", [NSNumber numberWithLong:[image length]], @"_size", @"0", @"_uploaded", nil];
    [self.uploadImages addObject:photoDict];
}

- (void)uploadImagesNow:(NSMutableDictionary*)metaImage success:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure {
    if (self.token == nil || [self.token length] == 0) {
        if (failure != nil) {
            failure(NSLocalizedString(@"error_session_invalid", @"NetworkManager"), -1);
        }
        return;
    }
    // Resize if necessary
    NSArray* resolutionString = [self.selectedResolution componentsSeparatedByString:@" "];
    NSArray* resolutionSize = [[resolutionString objectAtIndex:0] componentsSeparatedByString:@"x"];
    if([resolutionSize count] > 1) {
        UIImage* imageOriginal = [[UIImage alloc] initWithContentsOfFile:[metaImage objectForKey:@"_path"]];
        UIImage* imageNew;
        switch ([self.selectedScale intValue]) {
            case 1:
                imageNew = [imageOriginal panToSize:CGSizeMake([[resolutionSize objectAtIndex:0] floatValue],[[resolutionSize objectAtIndex:1] floatValue])];
                break;
            case 2:
                imageNew = [imageOriginal cutToSize:CGSizeMake([[resolutionSize objectAtIndex:0] floatValue],[[resolutionSize objectAtIndex:1] floatValue])];
                break;
            case 0:
            default:
                imageNew = [imageOriginal scaleToSize:CGSizeMake([[resolutionSize objectAtIndex:0] floatValue],[[resolutionSize objectAtIndex:1] floatValue])];
                break;
        }
        float jpegQuality = 0.95;
        if((imageNew.size.width > 500 && imageNew.size.height > 500) || imageNew.size.width > 2500 || imageNew.size.height > 2500) {
            jpegQuality = 0.85;
        }
        NSData* imageData = UIImageJPEGRepresentation(imageNew, jpegQuality);
        [imageData writeToFile:[metaImage objectForKey:@"_path"] atomically:YES];
        [metaImage setObject:[NSNumber numberWithLong:[imageData length]] forKey:@"_size"];
    }
    // Upload Image
    NSMutableDictionary *params = [self getBaseParams];
    [params setObject:self.token forKey:@"session"];
    if([self.selectedGallery intValue] > 0) {
        [params setObject:[self.selectedGallery stringValue] forKey:@"gallery"];
    }
    self.uploadTask = [[self getNetworkingManager] POST:@"upload" parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        //[formData appendPartWithFormData:[self.token dataUsingEncoding:NSUTF8StringEncoding] name:@"session"];
        [formData appendPartWithFileURL:[NSURL fileURLWithPath:[metaImage objectForKey:@"_path"]] name:@"img0" fileName:[metaImage objectForKey:@"_name"] mimeType:@"image/jpeg" error:nil];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            float p = uploadProgress.fractionCompleted;
            if(p > 0.995) p = 0.995;
            UIProgressView* tmpPV = [metaImage objectForKey:@"progressView"];
            [tmpPV setProgress:p];
            [tmpPV setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]];
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *tmpDict = [NSDictionary dictionaryWithXMLParser:responseObject];
        NSLog(@"uploadImagesNow:\r\n%@", tmpDict);
        if (success != nil) {
            success(tmpDict);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure != nil) {
            failure([NSString stringWithFormat:@"%@", [error localizedDescription]], 1);
        }
    }];
}

- (void)deleteImageWithName:(NSString*) filename success:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure {
    if (self.token == nil || [self.token length] == 0) {
        if (failure != nil) {
            failure(NSLocalizedString(@"error_session_invalid", @"NetworkManager"), -1);
        }
        return;
    }
    NSMutableDictionary *params = [self getBaseParams];
    [params setObject:self.token forKey:@"session"];
    [params setObject:filename forKey:@"filename"];
    [[self getNetworkingManager] POST:@"image/del" parameters:params progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSDictionary *tmpDict = [NSDictionary dictionaryWithXMLParser:responseObject];
        NSLog(@"deleteImageWithName:\r\n%@", tmpDict);
        if ( [[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"] ) {
            [self saveGalleryList:[[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"]];
        }
        if ( [[[tmpDict objectForKey:@"status"] objectForKey:@"_code"] intValue]  == 703 ) {
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

#pragma mark - Others

- (NSString*)generateLinkForImage:(NSString*) name {
    NSString* link = [[[self.listOutputLinks objectAtIndex:[self.selectedOutputLinks unsignedLongLongValue]] objectForKey:@"url"] stringByReplacingOccurrencesOfString:@"$B$" withString:cURL_BASE];
    link = [link stringByReplacingOccurrencesOfString:@"$I$" withString:name];
    return link;
}

- (NSString*)generateLinkForGallery:(NSString*) name {
    return [NSString stringWithFormat:@"%@/gallery.php?key=%@", cURL_BASE, name];
}

@end
