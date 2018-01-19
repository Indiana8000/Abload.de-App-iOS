//
//  AT_TabBarController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 26.10.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#import "AT_TabBarController.h"

@interface AT_TabBarController ()

@end

@implementation AT_TabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tabUpload = [[AT_UploadTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    self.tabGallery = [[AT_GalleryTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    self.tabAbout = [[AT_AboutViewController alloc] init];

    UINavigationController *navUL = [[UINavigationController alloc] initWithRootViewController:self.tabUpload];
    navUL.tabBarItem.title = NSLocalizedString(@"nav_tabbar_upload", @"Navigation");
    navUL.tabBarItem.image = [UIImage imageNamed:@"56-cloud"];

    UINavigationController *navGL = [[UINavigationController alloc] initWithRootViewController:self.tabGallery];
    navGL.tabBarItem.title = NSLocalizedString(@"nav_tabbar_images", @"Navigation");
    navGL.tabBarItem.image = [UIImage imageNamed:@"42-photos"];

    UINavigationController *navAB = [[UINavigationController alloc] initWithRootViewController:self.tabAbout];
    navAB.tabBarItem.title = NSLocalizedString(@"nav_tabbar_about", @"Navigation");
    navAB.tabBarItem.image = [UIImage imageNamed:@"999-logo"];

    [self setViewControllers:@[navUL, navGL, navAB]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
