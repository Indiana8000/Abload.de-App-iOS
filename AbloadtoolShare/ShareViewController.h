//
//  ShareViewController.h
//  AbloadtoolShare
//
//  Created by Andreas Kreisl on 15.02.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import <Photos/Photos.h>

@interface ShareViewController : UIViewController // SLComposeServiceViewController
@property(nonatomic , strong) PHFetchResult *assetsFetchResults;
@property(nonatomic , strong) PHCachingImageManager *imageManager;
@property(nonatomic , strong) NSMutableDictionary *imageList;

@end
