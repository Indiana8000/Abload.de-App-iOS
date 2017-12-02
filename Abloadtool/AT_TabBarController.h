//
//  AT_TabBarController.h
//  Abloadtool
//
//  Created by Andreas Kreisl on 26.10.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AT_UploadTableViewController.h"
#import "AT_GalleryTableViewController.h"
#import "AT_AboutViewController.h"

@interface AT_TabBarController : UITabBarController
    @property (nonatomic, strong) AT_UploadTableViewController* tabUpload;
    @property (nonatomic, strong) AT_GalleryTableViewController* tabGallery;
    @property (nonatomic, strong) AT_AboutViewController* tabAbout;
@end
