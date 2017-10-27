//
//  AT_TabBarController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 26.10.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#import "AT_TabBarController.h"
#import "FirstViewController.h"
#import "SecondViewController.h"
#import "AT_GalleryTableViewController.h"

@interface AT_TabBarController ()
    @property (nonatomic, strong) AT_GalleryTableViewController* tabGallery;
@end

@implementation AT_TabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tabGallery = [[AT_GalleryTableViewController alloc] init];

    FirstViewController *firstVC = [[FirstViewController alloc] init];
    firstVC.tabBarItem.title = @"First";
    
    UINavigationController *nacVC = [[UINavigationController alloc] initWithRootViewController:self.tabGallery];
    nacVC.tabBarItem.title = @"Gallery";

    [self setViewControllers:@[firstVC,nacVC]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
