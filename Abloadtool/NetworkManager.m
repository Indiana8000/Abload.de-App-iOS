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
    @property (nonatomic, strong) NSUserDefaults *defaults;

    @property (nonatomic, strong) NSString* pathImagesUpload;
    @property (nonatomic, strong) NSString* pathThumbnails;
    @property (nonatomic, strong) NSString* pathImagesShared;
    @property NSInteger uploadNumber;

    @property NSInteger settingGallerySorted;

    @property (nonatomic, strong) NSString* sessionKey;
    @property NSInteger settingLastMOD;

@end


@implementation NetworkManager
@synthesize galleryList;


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
    NSLog(@"NetworkManager - init");
    if ((self = [super init])) {
        self.defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.de.bluepaw.Abloadtool"];
        self.loggedin = 0;
        self.noad = 0;
        self.lastRefresh = [NSDate date];
        self.imageList = [[NSMutableDictionary alloc] init];
        self.imageLast = [[NSArray alloc] init];
        [self initPathVariables];
        [self loadImagesFromDisk];
        [self loadDefaults];

        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"scalemethods" ofType:@"plist"];
        self.settingAvailableScalingList = [NSArray arrayWithContentsOfFile:plistPath];
        
        plistPath = [[NSBundle mainBundle] pathForResource:@"outputlinks" ofType:@"plist"];
        self.settingAvailableOutputLinkList = [NSArray arrayWithContentsOfFile:plistPath];

    }
    return self;
}

- (void)initPathVariables {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    self.pathImagesUpload = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"images"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:self.pathImagesUpload]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.pathImagesUpload withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    self.pathThumbnails = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"thumbnails"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:self.pathThumbnails]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.pathThumbnails withIntermediateDirectories:YES attributes:nil error:nil];
    }

    NSURL* securityPath = [[[NSFileManager alloc] init] containerURLForSecurityApplicationGroupIdentifier:@"group.de.bluepaw.Abloadtool"];
    self.pathImagesShared = [[securityPath path] stringByAppendingPathComponent:@"images"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:self.pathImagesShared]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.pathImagesShared withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSLog(@"PATH:\r\n%@\r\n%@\r\n%@",self.pathImagesUpload,self.pathThumbnails,self.pathImagesShared);
}

- (void)loadImagesFromDisk {
    self.uploadImages = [[NSMutableArray alloc] init];
    NSFileManager* fileManager=[[NSFileManager alloc] init];
    NSDirectoryEnumerator* dirEnum = [fileManager enumeratorAtPath:self.pathImagesUpload];
    NSString *file;
    while ((file = [dirEnum nextObject])) {
        if ([[file pathExtension] isEqualToString: @"jpeg"]) {
            NSString* filePath = [self.pathImagesUpload stringByAppendingPathComponent:file];
            NSString* fileThumb = [self.pathThumbnails stringByAppendingPathComponent:file];
            NSNumber* fileSize = [NSNumber numberWithLong:[[fileManager attributesOfItemAtPath:filePath error:nil] fileSize]];
            NSMutableDictionary* photoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:filePath, @"_path", fileThumb, @"_thumb", file, @"_filename", fileSize, @"_filesize", @"0", @"_uploaded", [NSNumber numberWithDouble:0], @"_progress", nil];
            [self.uploadImages addObject:photoDict];
        }
    }
}


#pragma mark - Help-Functions

+ (void)showMessage:(NSString*) msg {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:msg
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"btn_ok", @"Abloadtool") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    [alert addAction:ok];
    [[[UIApplication sharedApplication] delegate].window.rootViewController presentViewController:alert animated:YES completion:nil];
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


#pragma mark - UserDefaults

- (void)loadDefaults {
    if([self.defaults objectForKey:@"settingSessionKey"]) {
        self.sessionKey = [self.defaults objectForKey:@"settingSessionKey"];
    } else {
        self.sessionKey = nil;
    }
    
    if([self.defaults objectForKey:@"settingGalleryList"]) {
        self.galleryList = [self.defaults objectForKey:@"settingGalleryList"];
    } else {
        self.galleryList = [[NSArray alloc] init];
    }

    if ([self.defaults objectForKey:@"settingGallerySorted"]) {
        self.settingGallerySorted = [self.defaults integerForKey:@"settingGallerySorted"];
    } else {
        self.settingGallerySorted = 0;
    }

    if([self.defaults objectForKey:@"settingGallerySelected"]) {
        self.settingGallerySelected = [self.defaults integerForKey:@"settingGallerySelected"];
    } else {
        self.settingGallerySelected = 0;
    }

    if([self.defaults objectForKey:@"settingLastMOD"]) {
        self.settingLastMOD = [self.defaults integerForKey:@"settingLastMOD"];
    } else {
        self.settingLastMOD = 0;
    }
    
    if ([self.defaults objectForKey:@"settingUploadNumber"]) {
        self.uploadNumber = [self.defaults integerForKey:@"settingUploadNumber"];
    } else {
        self.uploadNumber = 0;
    }

    if([self.defaults objectForKey:@"settingResolutionSelected"]) {
        self.settingResolutionSelected = [self.defaults objectForKey:@"settingResolutionSelected"];
    } else {
        self.settingResolutionSelected = NSLocalizedString(@"label_keeporiginal", @"Settings");
    }
    
    if([self.defaults objectForKey:@"settingScaleSelected"]) {
        self.settingScaleSelected = [self.defaults integerForKey:@"settingScaleSelected"];
    } else {
        self.settingScaleSelected =  1;
    }
    
    if ([self.defaults objectForKey:@"settingOutputLinkSelected"]) {
        self.settingOutputLinkSelected = [self.defaults integerForKey:@"settingOutputLinkSelected"];
    } else {
        self.settingOutputLinkSelected =  0;
    }
}

- (void)saveSessionKey:(NSString*) newSessionKey {
    self.sessionKey = newSessionKey;
    [self.defaults setObject:newSessionKey forKey:@"settingSessionKey"];
    [self.defaults synchronize];
}

- (NSString*)getSessionKey {
    return self.sessionKey;
}

- (void)saveGalleryList:(NSArray*) newGalleryList {
    if([newGalleryList count] > 1) {
        switch (self.settingGallerySorted) {
            case 1:
                self.galleryList = [newGalleryList sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
                    NSString *first = [(NSDictionary*)a objectForKey:@"_lastchange"];
                    NSString *second = [(NSDictionary*)b objectForKey:@"_lastchange"];
                    return [second compare:first];
                }];
                break;
            default:
                self.galleryList = [newGalleryList sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
                    NSString *first = [(NSDictionary*)a objectForKey:@"_name"];
                    NSString *second = [(NSDictionary*)b objectForKey:@"_name"];
                    return [first compare:second];
                }];
                break;
        }
    } else {
        self.galleryList = newGalleryList;
    }
    [self.defaults setObject:self.galleryList forKey:@"settingGalleryList"];
    [self.defaults synchronize];
}

- (void)saveGallerySorted:(NSInteger) gallerySorted {
    self.settingGallerySorted = gallerySorted;
    [self.defaults setInteger:gallerySorted forKey:@"settingGallerySorted"];
    [self.defaults synchronize];
    [self saveGalleryList:self.galleryList];
}

- (void)saveGallerySelected:(NSInteger) galleryID {
    self.settingGallerySelected = galleryID;
    [self.defaults setInteger:galleryID forKey:@"settingGallerySelected"];
    [self.defaults synchronize];
}

- (void)saveResolutionSelected:(NSString*) newResolution {
    self.settingResolutionSelected = newResolution;
    [self.defaults setObject:newResolution forKey:@"settingResolutionSelected"];
    [self.defaults synchronize];
}

- (void)saveScaleSelected:(NSInteger) newScale {
    self.settingScaleSelected = newScale;
    [self.defaults setInteger:newScale forKey:@"settingScaleSelected"];
    [self.defaults synchronize];
}

- (void)saveOutputLinkSelected:(NSInteger) newOutputLinks {
    self.settingOutputLinkSelected = newOutputLinks;
    [self.defaults setInteger:newOutputLinks forKey:@"settingOutputLinkSelected"];
    [self.defaults synchronize];
}

- (void)saveMODTime:(NSInteger) newMODTime {
    self.settingLastMOD = newMODTime;
    [self.defaults setInteger:newMODTime forKey:@"settingLastMOD"];
    [self.defaults synchronize];
}

- (NSInteger)incrementUploadNumber {
    if(self.uploadNumber >= NSIntegerMax)
        self.uploadNumber = 1;
    else
        self.uploadNumber++;
    [self.defaults setInteger:self.uploadNumber forKey:@"settingUploadNumber"];
    [self.defaults synchronize];
    return self.uploadNumber;
}


#pragma mark - ImageFile

- (void)saveImageToDisk:(NSData*) imageData {
    NSString* fileImage = [self.pathImagesUpload stringByAppendingFormat:@"/mobile.%ld.jpeg", [self incrementUploadNumber]];
    NSNumber* fileSize = [NSNumber numberWithLong:[imageData length]];
    [imageData writeToFile:fileImage atomically:YES];
    
    UIImage* imageThumb = [[UIImage alloc] initWithData:imageData];
    imageThumb = [imageThumb panToSize:CGSizeMake(225, 150)];
    NSData* dataThumb = UIImageJPEGRepresentation(imageThumb, 0.85);
    NSString* fileThumb = [self.pathThumbnails stringByAppendingFormat:@"/mobile.%ld.jpeg", self.uploadNumber];
    [dataThumb writeToFile:fileThumb atomically:YES];

    NSMutableDictionary* photoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:fileImage, @"_path", fileThumb, @"_thumb", [fileImage lastPathComponent], @"_filename", fileSize, @"_filesize", @"0", @"_uploaded", [NSNumber numberWithDouble:0], @"_progress", nil];
    [self.uploadImages addObject:photoDict];
}

- (void)checkAndLoadSharedImages {
    NSInteger shareCount = [self.defaults integerForKey:@"share_count"];
    NSLog(@"shareCount %ld", shareCount);
    if(shareCount > 0) {
        NSFileManager* fileManager=[[NSFileManager alloc] init];
        NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:self.pathImagesShared];
        NSString *file;
        while ((file = [dirEnum nextObject])) {
            if ([[file pathExtension] isEqualToString: @"jpeg"]) {
                NSString* fileImageSrc = [self.pathImagesShared stringByAppendingPathComponent:file];
                NSString* fileImageDst = [self.pathImagesUpload stringByAppendingFormat:@"/mobile.%ld.shared.jpeg", [self incrementUploadNumber]];
                [fileManager moveItemAtPath:fileImageSrc toPath:fileImageDst error:nil];
                NSNumber* fileSize = [NSNumber numberWithLong:[[fileManager attributesOfItemAtPath:fileImageDst error:nil] fileSize]];
                
                UIImage* imageThumb = [[UIImage alloc] initWithContentsOfFile:fileImageDst];
                imageThumb = [imageThumb panToSize:CGSizeMake(225, 150)];
                NSData* dataThumb = UIImageJPEGRepresentation(imageThumb, 0.85);
                NSString* fileThumb = [self.pathThumbnails stringByAppendingFormat:@"/mobile.%ld.shared.jpeg", self.uploadNumber];
                [dataThumb writeToFile:fileThumb atomically:YES];

                NSMutableDictionary* photoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys: fileImageDst, @"_path", fileThumb, @"_thumb",[fileImageDst lastPathComponent], @"_filename", fileSize, @"_filesize", @"0", @"_uploaded",  [NSNumber numberWithDouble:0], @"_progress", nil];
                [self.uploadImages addObject:photoDict];
            }
        }
        shareCount = 0;
        [self.defaults setInteger:shareCount forKey:@"share_count"];
        [self.defaults synchronize];
    }
}

- (void)removeImageFromDisk:(NSInteger) imageIndex andList:(BOOL) includeList  {
    [[NSFileManager defaultManager] removeItemAtPath:[[self.uploadImages objectAtIndex:imageIndex] objectForKey:@"_path"]  error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[[self.uploadImages objectAtIndex:imageIndex] objectForKey:@"_thumb"]  error:nil];
    if(includeList == YES) [self.uploadImages removeObjectAtIndex:imageIndex];
}


#pragma mark - HTTP-Basic

- (NSMutableDictionary*)getBaseParams {
    NSMutableDictionary *baseParams = [NSMutableDictionary dictionary];
    [baseParams setObject:@"1.0" forKey:@"api_version"];
    [baseParams setObject:@"iOS" forKey:@"device_vendor"];
    [baseParams setObject:[NSString stringWithFormat:@"%ld", UIDevice.currentDevice.userInterfaceIdiom] forKey:@"device_type"];
    [baseParams setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] forKey:@"app_build"];
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

- (void)addImageToList:(NSDictionary*) image {
    NSString* gid = [image objectForKey:@"_gid"];
    if(!([gid intValue] > 0)) {
        gid = @"x";
    }
    if(![self.imageList objectForKey:gid]) {
        [self.imageList setObject:[[NSMutableArray alloc] initWithCapacity:1] forKey:gid];
    }
    [[self.imageList objectForKey:gid] addObject:image];
}

- (void)postRequestToAbload:(NSString*)action WithOptions:(NSMutableDictionary*)params success:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure {
    [[self getNetworkingManager] POST:action parameters:params progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSDictionary *tmpDict = [NSDictionary dictionaryWithXMLParser:responseObject];
        if([[tmpDict objectForKey:@"login"] objectForKey:@"_session"]) {
            [self saveSessionKey:[[tmpDict objectForKey:@"login"] objectForKey:@"_session"]];
            NSString *tmpStr = [[tmpDict objectForKey:@"login"] objectForKey:@"_disable_advertising"];
            if ([tmpStr compare:@"true"] == NSOrderedSame) {
                self.noad = 1;
            } else {
                self.noad = 0;
            }
        }
        if([tmpDict objectForKey:@"motd"] && [[[tmpDict objectForKey:@"motd"] objectForKey:@"_time"] integerValue] > self.settingLastMOD) {
            [self saveMODTime:[[[tmpDict objectForKey:@"motd"] objectForKey:@"_time"] integerValue]];
            [NetworkManager showMessage:[[tmpDict objectForKey:@"motd"] objectForKey:@"_text"]];
        }
        if([[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"]) {
            if([[[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"] isKindOfClass:[NSArray class]]) { // Array = Multiple Galleries
                [self saveGalleryList:[[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"]];
            } else { // Dict = Single Gallery
                [self saveGalleryList:@[[[tmpDict objectForKey:@"galleries"] objectForKey:@"gallery"]]];
            }
        }
        if([[tmpDict objectForKey:@"images"] objectForKey:@"image"]) {
            self.imageList = [[NSMutableDictionary alloc] initWithCapacity:[self.galleryList count]];
            if([[[tmpDict objectForKey:@"images"] objectForKey:@"image"] isKindOfClass:[NSArray class]]) { // Array = Multiple Images
                for(long i = 0;i < [[[tmpDict objectForKey:@"images"] objectForKey:@"image"] count];i++) {
                    [self addImageToList:[[[tmpDict objectForKey:@"images"] objectForKey:@"image"] objectAtIndex:i]];
                }
            } else { // Dict = Single Image
                [self addImageToList:[[tmpDict objectForKey:@"images"] objectForKey:@"image"]];
            }
        }
        if([[tmpDict objectForKey:@"lastimages"] objectForKey:@"image"]) {
            self.lastRefresh = [NSDate date];
            if([[[tmpDict objectForKey:@"lastimages"] objectForKey:@"image"] isKindOfClass:[NSArray class]]) { // Array = Multiple Images
                self.imageLast = [[tmpDict objectForKey:@"lastimages"] objectForKey:@"image"];
            } else { // Dict = Single Image
                self.imageLast = @[[[tmpDict objectForKey:@"lastimages"] objectForKey:@"image"]];
            }
        }
        if (success != nil) {
            success(tmpDict);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        self.loggedin = -1;
        if (failure != nil) {
            failure([NSString stringWithFormat:@"%@", [error localizedDescription]], ((NSHTTPURLResponse*)operation.response).statusCode);
        }
    }];
}

- (BOOL)checkValidSession {
    if (self.sessionKey == nil || [self.sessionKey length] < 9) {
        self.loggedin = 0;
        return NO;
    } else {
        return YES;
    }
}


#pragma mark - HTTP-Session

- (void)checkSessionKeyWithSuccess:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure {
    if([self checkValidSession]) {
        NSMutableDictionary *params = [self getBaseParams];
        [params setObject:self.sessionKey forKey:@"session"];
        [self postRequestToAbload:@"user" WithOptions:params success:^(NSDictionary *responseObject) {
            //NSLog(@"tokenCheckWithSuccess:\r\n%@", responseObject);
            if([responseObject objectForKey:@"status"] && [[[responseObject objectForKey:@"status"] objectForKey:@"_code"] intValue]  == 801) {
                self.loggedin = 1;
                if(![responseObject objectForKey:@"galleries"]) {
                    [self saveGalleryList:@[]];
                }
                if(![responseObject objectForKey:@"lastimages"]) {
                    self.imageLast = @[];
                }
                if (success != nil) {
                    success(responseObject);
                }
            } else {
                self.loggedin = 0;
                if (failure != nil) {
                    failure([[responseObject objectForKey:@"status"] objectForKey:@"__text"], [[[responseObject objectForKey:@"status"] objectForKey:@"_code"] intValue]);
                }
            }
        } failure:^(NSString *failureReason, NSInteger statusCode) {
            if(failure!=nil)
                failure(failureReason, statusCode);
        }];
    } else {
        if (failure != nil) {
            failure(NSLocalizedString(@"error_session_invalid", @"NetworkManager"), -1);
        }
    }
}

- (void)authenticateWithEmail:(NSString*)email password:(NSString*)password success:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure {
    if (email != nil && [email length] > 0 && password != nil && [password length] > 0) {
        NSMutableDictionary *params = [self getBaseParams];
        [params setObject:email forKey:@"name"];
        [params setObject:password forKey:@"password"];
        [self postRequestToAbload:@"login" WithOptions:params success:^(NSDictionary *responseObject) {
            NSLog(@"authenticateWithEmail:\r\n%@", responseObject);
            if([responseObject objectForKey:@"status"] && [[[responseObject objectForKey:@"status"] objectForKey:@"_code"] intValue]  == 801) {
                self.loggedin = 1;
                if(![responseObject objectForKey:@"galleries"]) {
                    [self saveGalleryList:@[]];
                }
                if (success != nil) {
                    success(responseObject);
                }
            } else {
                self.loggedin = 0;
                if (failure != nil) {
                    failure([[responseObject objectForKey:@"status"] objectForKey:@"__text"], [[[responseObject objectForKey:@"status"] objectForKey:@"_code"] intValue]);
                }
            }
        } failure:^(NSString *failureReason, NSInteger statusCode) {
            if(failure!=nil)
                failure(failureReason, statusCode);
        }];
    } else {
        if (failure != nil) {
            failure(NSLocalizedString(@"net_login_error_missingvalues", @"NetworkManager"), -1);
        }
    }
}


#pragma mark - HTTP-Gallery

- (void)getGalleryList:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure {
    if([self checkValidSession]) {
        NSMutableDictionary *params = [self getBaseParams];
        [params setObject:self.sessionKey forKey:@"session"];
        [self postRequestToAbload:@"gallery/list" WithOptions:params success:^(NSDictionary *responseObject) {
            //NSLog(@"getGalleryList:\r\n%@", responseObject);
            if(![responseObject objectForKey:@"status"]) {
                if(![responseObject objectForKey:@"galleries"]) {
                    [self saveGalleryList:@[]];
                }
                if(![responseObject objectForKey:@"lastimages"]) {
                    self.imageLast = @[];
                }
                if (success != nil) {
                    success(responseObject);
                }
            } else {
                if (failure != nil) {
                    failure([[responseObject objectForKey:@"status"] objectForKey:@"__text"], [[[responseObject objectForKey:@"status"] objectForKey:@"_code"] intValue]);
                }
            }
        } failure:^(NSString *failureReason, NSInteger statusCode) {
            if(failure!=nil)
                failure(failureReason, statusCode);
        }];
    } else {
        if (failure != nil) {
            failure(NSLocalizedString(@"error_session_invalid", @"NetworkManager"), -1);
        }
    }
}

- (void)createGalleryWithName:(NSString*)name andDesc:(NSString*)desc success:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure {
    if([self checkValidSession]) {
        name = [[NSString alloc] initWithData:[name dataUsingEncoding:NSNonLossyASCIIStringEncoding] encoding:NSUTF8StringEncoding];
        desc = [[NSString alloc] initWithData:[desc dataUsingEncoding:NSNonLossyASCIIStringEncoding] encoding:NSUTF8StringEncoding];

        NSMutableDictionary *params = [self getBaseParams];
        [params setObject:self.sessionKey forKey:@"session"];
        [params setObject:name forKey:@"name"];
        [params setObject:desc forKey:@"desc"];
        [self postRequestToAbload:@"gallery/new" WithOptions:params success:^(NSDictionary *responseObject) {
            //NSLog(@"createGalleryWithName:\r\n%@", responseObject);
            if ([[[responseObject objectForKey:@"status"] objectForKey:@"_code"] intValue]  == 605) {
                if(![responseObject objectForKey:@"galleries"]) {
                    [self saveGalleryList:@[]];
                }
                if (success != nil) {
                    success(responseObject);
                }
            } else {
                if (failure != nil) {
                    failure([[responseObject objectForKey:@"status"] objectForKey:@"__text"], [[[responseObject objectForKey:@"status"] objectForKey:@"_code"] intValue]);
                }
            }
        } failure:^(NSString *failureReason, NSInteger statusCode) {
            if(failure!=nil)
                failure(failureReason, statusCode);
        }];
    } else {
        if (failure != nil) {
            failure(NSLocalizedString(@"error_session_invalid", @"NetworkManager"), -1);
        }
    }
}

- (void)deleteGalleryWithID:(NSInteger)gid andImages:(NSInteger)img success:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure {
    if([self checkValidSession]) {
        NSMutableDictionary *params = [self getBaseParams];
        [params setObject:self.sessionKey forKey:@"session"];
        [params setObject:[NSString stringWithFormat:@"%ld", gid] forKey:@"gid"];
        [params setObject:[NSString stringWithFormat:@"%ld", img] forKey:@"img"];
        [self postRequestToAbload:@"gallery/del" WithOptions:params success:^(NSDictionary *responseObject) {
            //NSLog(@"deleteGalleryWithID:\r\n%@", responseObject);
            if (([[[responseObject objectForKey:@"status"] objectForKey:@"_code"] intValue]  == 608 || [[[responseObject objectForKey:@"status"] objectForKey:@"_code"] intValue]  == 609)) {
                if(![responseObject objectForKey:@"galleries"]) {
                    [self saveGalleryList:@[]];
                }
                if(![responseObject objectForKey:@"lastimages"]) {
                    self.imageLast = @[];
                }
                if (success != nil) {
                    success(responseObject);
                }
            } else {
                if (failure != nil) {
                    failure([[responseObject objectForKey:@"status"] objectForKey:@"__text"], [[[responseObject objectForKey:@"status"] objectForKey:@"_code"] intValue]);
                }
            }
        } failure:^(NSString *failureReason, NSInteger statusCode) {
            if(failure!=nil)
                failure(failureReason, statusCode);
        }];
    } else {
        if (failure != nil) {
            failure(NSLocalizedString(@"error_session_invalid", @"NetworkManager"), -1);
        }
    }
}


#pragma mark - HTTP-Images

- (void)getImageListForGroup:(NSString*) gid success:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure {
    if([self checkValidSession]) {
        NSMutableDictionary *params = [self getBaseParams];
        [params setObject:self.sessionKey forKey:@"session"];
        if([gid caseInsensitiveCompare:@"x"] != NSOrderedSame) [params setObject:gid forKey:@"gid"];
        [self postRequestToAbload:@"images" WithOptions:params success:^(NSDictionary *responseObject) {
            NSLog(@"getImageListForGroup:\r\n%@", responseObject);
            if(![responseObject objectForKey:@"status"]) {
                if (success != nil) {
                    success(responseObject);
                }
            } else {
                if (failure != nil) {
                    failure([[responseObject objectForKey:@"status"] objectForKey:@"__text"], [[[responseObject objectForKey:@"status"] objectForKey:@"_code"] intValue]);
                }
            }
        } failure:^(NSString *failureReason, NSInteger statusCode) {
            if(failure!=nil)
                failure(failureReason, statusCode);
        }];
    } else {
        if (failure != nil) {
            failure(NSLocalizedString(@"error_session_invalid", @"NetworkManager"), -1);
        }
    }
}

- (void) testest:(void (^)(int result))completionHandler {
    
}

- (void)uploadImageWithID:(NSInteger)imageID progress:(void (^)(double fraction))progress success:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure {
    if([self checkValidSession]) {
        NSMutableDictionary* metaImage = [self.uploadImages objectAtIndex:imageID];
        // Resize if necessary
        NSArray* resolutionString = [self.settingResolutionSelected componentsSeparatedByString:@" "];
        NSArray* resolutionSize = [[resolutionString objectAtIndex:0] componentsSeparatedByString:@"x"];
        if([resolutionSize count] > 1) {
            UIImage* imageOriginal = [[UIImage alloc] initWithContentsOfFile:[metaImage objectForKey:@"_path"]];
            UIImage* imageNew = nil;
            switch (self.settingScaleSelected) {
                case 0:
                    imageNew = [imageOriginal scaleToSize:CGSizeMake([[resolutionSize objectAtIndex:0] floatValue],[[resolutionSize objectAtIndex:1] floatValue])];
                    break;
                case 1:
                    imageNew = [imageOriginal panToSize:CGSizeMake([[resolutionSize objectAtIndex:0] floatValue],[[resolutionSize objectAtIndex:1] floatValue])];
                    break;
                case 2:
                    imageNew = [imageOriginal cutToSize:CGSizeMake([[resolutionSize objectAtIndex:0] floatValue],[[resolutionSize objectAtIndex:1] floatValue])];
                    break;
                default:
                    break;
            }
            if(imageNew != nil) {
                float jpegQuality = 0.95;
                if((imageNew.size.width > 500 && imageNew.size.height > 500) || imageNew.size.width > 2500 || imageNew.size.height > 2500) {
                    jpegQuality = 0.85;
                }
                NSData* imageData = UIImageJPEGRepresentation(imageNew, jpegQuality);
                [imageData writeToFile:[metaImage objectForKey:@"_path"] atomically:YES];
                [metaImage setObject:[NSNumber numberWithLong:[imageData length]] forKey:@"_filesize"];
            }
        }
        // Upload Image
        NSMutableDictionary *params = [self getBaseParams];
        [params setObject:self.sessionKey forKey:@"session"];
        if(self.settingGallerySelected > 0)
            [params setObject:[NSString stringWithFormat:@"%ld", self.settingGallerySelected] forKey:@"gallery"];
        self.uploadTask = [[self getNetworkingManager] POST:@"upload" parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> _Nonnull formData) {
            [formData appendPartWithFileURL:[NSURL fileURLWithPath:[metaImage objectForKey:@"_path"]] name:@"img0" fileName:[metaImage objectForKey:@"_filename"] mimeType:@"image/jpeg" error:nil];
        } progress:^(NSProgress * _Nonnull uploadProgress) {
            [metaImage setObject:[NSNumber numberWithDouble:uploadProgress.fractionCompleted] forKey:@"_progress"];
            progress(uploadProgress.fractionCompleted);
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSDictionary *tmpDict = [NSDictionary dictionaryWithXMLParser:responseObject];
            //NSLog(@"uploadImagesNow:\r\n%@", tmpDict);
            if (success != nil) {
                success(tmpDict);
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (failure != nil) {
                failure([NSString stringWithFormat:@"%@", [error localizedDescription]], 1);
            }
        }];
    } else {
        if (failure != nil) {
            failure(NSLocalizedString(@"error_session_invalid", @"NetworkManager"), -1);
        }
    }
}

- (void)deleteImageWithName:(NSString*) filename success:(NetworkManagerSuccess)success failure:(NetworkManagerFailure)failure {
    if([self checkValidSession]) {
        NSMutableDictionary *params = [self getBaseParams];
        [params setObject:self.sessionKey forKey:@"session"];
        [params setObject:filename forKey:@"filename"];
        [self postRequestToAbload:@"image/del" WithOptions:params success:^(NSDictionary *responseObject) {
            //NSLog(@"deleteImageWithName:\r\n%@", responseObject);
            if([[[responseObject objectForKey:@"status"] objectForKey:@"_code"] intValue] == 703) {
                if(![responseObject objectForKey:@"lastimages"]) {
                    self.imageLast = @[];
                }
                if (success != nil) {
                    success(responseObject);
                }
            } else {
                if (failure != nil) {
                    failure([[responseObject objectForKey:@"status"] objectForKey:@"__text"], [[[responseObject objectForKey:@"status"] objectForKey:@"_code"] intValue]);
                }
            }
        } failure:^(NSString *failureReason, NSInteger statusCode) {
            if(failure!=nil)
                failure(failureReason, statusCode);
        }];
    } else {
        if (failure != nil) {
            failure(NSLocalizedString(@"error_session_invalid", @"NetworkManager"), -1);
        }
    }
}


#pragma mark - User-Actions

- (void)showLoginWithCallback:(void(^)(void))successCallback  {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"net_login_title", @"NetworkManager")
                                                                   message:nil
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

    [[[UIApplication sharedApplication] delegate].window.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (void)logoutWithCallback:(void(^)(void))successCallback {
    [self saveSessionKey:@""];

    self.loggedin = 0;
    self.noad = 0;

    [self saveGalleryList:[[NSArray alloc] init]];
    self.imageLast = [[NSArray alloc] init];

    successCallback();
}

- (NSString*)generateLinkForImage:(NSString*) name {
    NSString* link = [[[self.settingAvailableOutputLinkList objectAtIndex:self.settingOutputLinkSelected] objectForKey:@"url"] stringByReplacingOccurrencesOfString:@"$B$" withString:cURL_BASE];
    link = [link stringByReplacingOccurrencesOfString:@"$I$" withString:name];
    return link;
}

- (NSString*)generateLinkForGallery:(NSString*) name {
    return [NSString stringWithFormat:@"%@/gallery.php?key=%@", cURL_BASE, name];
}


@end
