//
//  AT_UploadTableViewController.h
//  Abloadtool
//
//  Created by Andreas Kreisl on 27.10.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "UzysAssetsPickerController.h"

#import "NetworkManager.h"
#import "AT_UploadTableViewCell.h"
#import "AT_ImageTableViewCell.h"
#import "AT_SettingTableViewController.h"
#import "AT_SettingOutputLinksTableViewController.h"
#import "AT_DetailedViewController.h"
#import "AT_AlbumTableViewController.h"
#import "AT_ImagePickerViewController.h"


@interface AT_UploadTableViewController : UITableViewController <UIPopoverPresentationControllerDelegate>
    @property AT_SettingTableViewController* pageSetting;
    @property UINavigationController* navSetting;
    @property UzysAssetsPickerController* uzysPicker;
    @property AT_DetailedViewController* detailedViewController;
@end
