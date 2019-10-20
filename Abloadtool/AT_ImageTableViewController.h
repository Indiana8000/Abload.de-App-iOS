//
//  AT_ImageTableViewController.h
//  Abloadtool
//
//  Created by Andreas Kreisl on 10.01.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <AFNetworking/AFImageDownloader.h>

#import "NetworkManager.h"
#import "AT_ImageTableViewCell.h"
#import "AT_DetailedViewController.h"
#import "AT_SettingOutputLinksTableViewController.h"
#import "AT_ActivityItemProvider.h"


@interface AT_ImageTableViewController : UITableViewController
    @property NSString* gid;
    @property AT_DetailedViewController* detailedViewController;
    @property AT_SettingOutputLinksTableViewController* pageSetting;
    @property UINavigationController* navSetting;
    @property BOOL scrollTop;
    - (void)setLastRefresh;
    - (void)resetForNewGroup;
@end

