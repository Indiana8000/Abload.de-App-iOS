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
    self.tabGallery = [[AT_GalleryTableViewController alloc] initWithStyle:UITableViewStylePlain];
    self.tabAbout = [[AT_AboutViewController alloc] init];

    UINavigationController *navUL = [[UINavigationController alloc] initWithRootViewController:self.tabUpload];
    navUL.tabBarItem.title = NSLocalizedString(@"Upload", @"Tab Bar Title");
    navUL.tabBarItem.image = [UIImage imageNamed:@"266-upload"];

    UINavigationController *navGL = [[UINavigationController alloc] initWithRootViewController:self.tabGallery];
    navGL.tabBarItem.title = NSLocalizedString(@"Gallery", @"Tab Bar Title");
    navGL.tabBarItem.image = [UIImage imageNamed:@"42-photos"];

    UINavigationController *navAB = [[UINavigationController alloc] initWithRootViewController:self.tabAbout];
    navAB.tabBarItem.title = NSLocalizedString(@"About Us", @"Tab Bar Title");
    navAB.tabBarItem.image = [UIImage imageNamed:@"999-logo"];

    [self setViewControllers:@[navUL, navGL, navAB]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
