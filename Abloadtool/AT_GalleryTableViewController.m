//
//  AT_GalleryTableViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 19.10.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#define cImageCell @"ImageTableViewCell"

#import "AT_GalleryTableViewController.h"

@interface AT_GalleryTableViewController ()

@end

@implementation AT_GalleryTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Init Navigation Controller + Buttons
    self.navigationItem.title = NSLocalizedString(@"nav_title_gallery", @"Navigation");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(doAddGallery:)];

    // Init RefreshController
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(doRefresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    // Init TableView
    [self.tableView registerClass:[AT_ImageTableViewCell class] forCellReuseIdentifier:cImageCell];
    
    // Init ImageTable
    self.imageTableViewController = [[AT_ImageTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidAppear:(BOOL)animated {
    if([[[NetworkManager sharedManager] loggedin] intValue] == 0) {
        [[NetworkManager sharedManager] showLoginWithViewController:[self parentViewController] andCallback:^(void) {
            [self doRefresh:nil];
        }];
    } else if ([[[NetworkManager sharedManager] loggedin] intValue] == -1) {
        [[NetworkManager sharedManager] tokenCheckWithSuccess:^(NSDictionary *responseObject) {
            [self doRefresh:nil];
        }  failure:^(NSString *failureReason, NSInteger statusCode) {
            if([[[NetworkManager sharedManager] loggedin] intValue] == 0) {
                [self doRefresh:nil];
            } else {
                [NetworkManager showMessage:failureReason];
            }
        }];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0) {
        return 1;
    } else {
        return [[[NetworkManager sharedManager] gallery] count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cImageCell forIndexPath:indexPath];
    cell.separatorInset = UIEdgeInsetsZero;
    
    if(indexPath.section == 0) {
        cell.textLabel.text = NSLocalizedString(@"label_nogallery", @"Settings");
        cell.detailTextLabel.text = @" ";
        [cell.imageView setImage:[UIImage imageNamed:@"AppIcon"]];
    } else {
        cell.textLabel.text = [[[[NetworkManager sharedManager] gallery] objectAtIndex:indexPath.row] objectForKey:@"_name"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@#  %@", [[[[NetworkManager sharedManager] gallery] objectAtIndex:indexPath.row] objectForKey:@"_images"], [[[[NetworkManager sharedManager] gallery] objectAtIndex:indexPath.row] objectForKey:@"_desc"]];
        
        NSString *tmpURL = [NSString stringWithFormat:@"%@/mini/%@", cURL_BASE, [[[[NetworkManager sharedManager] gallery] objectAtIndex:indexPath.row] objectForKey:@"_thumb"]];
        [cell.imageView setImageWithURL:[NSURL URLWithString:tmpURL] placeholderImage:[UIImage imageNamed:@"AppIcon"]];
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section == 1);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self doDeleteGallery:indexPath.row];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[NetworkManager sharedManager] showProgressHUD];
    if(indexPath.section == 0) {
        self.imageTableViewController.gid = @"x";
        self.imageTableViewController.navigationItem.title = NSLocalizedString(@"label_nogallery", @"Settings");
    } else {
        self.imageTableViewController.gid = [[[[NetworkManager sharedManager] gallery] objectAtIndex:indexPath.row] objectForKey:@"_id"];
        self.imageTableViewController.navigationItem.title = [[[[NetworkManager sharedManager] gallery] objectAtIndex:indexPath.row] objectForKey:@"_name"];
    }

    [[NetworkManager sharedManager] getImageList:^(NSDictionary *responseObject) {
        [[NetworkManager sharedManager] hideProgressHUD];
        [self.navigationController pushViewController:self.imageTableViewController animated:YES];
    } failure:^(NSString *failureReason, NSInteger statusCode) {
        [[NetworkManager sharedManager] hideProgressHUD];
        [NetworkManager showMessage:failureReason];
    }];
}

#pragma mark - RefreshController

- (void)doRefresh:(id)sender {
    if([[[NetworkManager sharedManager] loggedin] intValue] == 1) {
        [[NetworkManager sharedManager] getGalleryList:^(NSDictionary *responseObject) {
            [self setLastRefresh];
            [[self refreshControl] endRefreshing];
            [self.tableView reloadData];
        } failure:^(NSString *failureReason, NSInteger statusCode) {
            [[self refreshControl] endRefreshing];
            [NetworkManager showMessage:failureReason];
        }];
    } else if ([[[NetworkManager sharedManager] loggedin] intValue] == -1) {
        [[NetworkManager sharedManager] tokenCheckWithSuccess:^(NSDictionary *responseObject) {
            [self doRefresh:nil];
        }  failure:^(NSString *failureReason, NSInteger statusCode) {
            if([[[NetworkManager sharedManager] loggedin] intValue] == 0) {
                [self doRefresh:sender];
            } else {
                [NetworkManager showMessage:failureReason];
            }
        }];
    } else {
        [[NetworkManager sharedManager] showLoginWithViewController:[self parentViewController] andCallback:^(void) {
            [self doRefresh:sender];
        }];
        [[self refreshControl] endRefreshing];
    }
}

- (void)setLastRefresh {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"]];
    [formatter setDateFormat:@"d. MMM, H:mm"];
    NSString *lastUpdated = [NSString stringWithFormat:NSLocalizedString(@"label_lastrefresh %@", @"Gallery"),
                             [formatter stringFromDate:[NSDate date]]];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:lastUpdated];
}

#pragma mark - Manage Gallerys

- (void)doAddGallery:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Abloadtool", @"Abloadtool")
                                                                   message:NSLocalizedString(@"newgallery_title", @"Gallery")
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"newgallery_btn_create", @"Gallery") style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action) {
                                                   [[NetworkManager sharedManager] showProgressHUD];
                                                   [[NetworkManager sharedManager] createGalleryWithName:[[alert.textFields objectAtIndex:0] text] andDesc:[[alert.textFields objectAtIndex:1] text] success:^(id responseObject) {
                                                       [[NetworkManager sharedManager] hideProgressHUD];
                                                       [self.tableView reloadData];
                                                   } failure:^(NSString *failureReason, NSInteger statusCode) {
                                                       [[NetworkManager sharedManager] hideProgressHUD];
                                                       [NetworkManager showMessage:failureReason];
                                                   }];
                                               }];
    [alert addAction:ok];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"newgallery_btn_chancel", @"Gallery") style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                                   }];
    [alert addAction:cancel];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"newgallery_label_name", @"Gallery");
        textField.keyboardType = UIKeyboardTypeDefault;
    }];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"newgallery_label_description", @"Gallery");
        textField.keyboardType = UIKeyboardTypeDefault;
    }];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)doDeleteGallery:(NSInteger) row {
    long gid = [[[[[NetworkManager sharedManager] gallery] objectAtIndex:row] objectForKey:@"_id"] intValue];
    long bc = [[[[[NetworkManager sharedManager] gallery] objectAtIndex:row] objectForKey:@"_images"] intValue];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Abloadtool", @"Abloadtool")
                                                                   message:[NSString stringWithFormat:NSLocalizedString(@"delgallery_question %@", @"Gallery"), [[[[NetworkManager sharedManager] gallery] objectAtIndex:row] objectForKey:@"_name"]]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"delgallery_btn_withoutimage", @"Gallery") style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action) {
                                                   [[NetworkManager sharedManager] deleteGalleryWithID:gid andImages:0 success:^(NSDictionary *responseObject) {
                                                       [self.tableView reloadData];
                                                   } failure:^(NSString *failureReason, NSInteger statusCode) {
                                                       [NetworkManager showMessage:failureReason];
                                                   }];
                                               }];
    [alert addAction:ok];
    
    UIAlertAction *ok2 = [UIAlertAction actionWithTitle:[NSString stringWithFormat:NSLocalizedString(@"delgallery_btn_withimage", @"Gallery"), bc] style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action) {
                                                   [[NetworkManager sharedManager] deleteGalleryWithID:gid andImages:1 success:^(NSDictionary *responseObject) {
                                                       [self.tableView reloadData];
                                                   } failure:^(NSString *failureReason, NSInteger statusCode) {
                                                       [NetworkManager showMessage:failureReason];
                                                   }];
                                               }];
    [alert addAction:ok2];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"delgallery_btn_chancel", @"Gallery") style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                                   }];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}



@end
