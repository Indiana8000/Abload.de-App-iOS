//
//  AT_AlbumTableViewController.h
//  Abloadtool
//
//  Created by Andreas Kreisl on 22.03.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <MBProgressHUD/MBProgressHUD.h>

#import "AT_ImagePickerViewController.h"
#import "AT_ImageTableViewCell.h"

@interface AT_AlbumTableViewController : UITableViewController
@property AT_ImagePickerViewController* imagePickerViewController;

@end
