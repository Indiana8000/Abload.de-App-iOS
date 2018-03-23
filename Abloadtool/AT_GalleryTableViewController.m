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
    self.navigationItem.title = NSLocalizedString(@"nav_title_gallery", @"Navigation");
    self.navigationItem.rightBarButtonItems =  @[
                                                [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(doAddGallery:)],
                                                [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"155-sort"] style:UIBarButtonItemStylePlain target:self action:@selector(sortGalleery)]
                                                ];

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(doRefresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    [self.tableView registerClass:[AT_ImageTableViewCell class] forCellReuseIdentifier:cImageCell];
    self.imageTableViewController = [[AT_ImageTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView.refreshControl endRefreshing];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if([[NetworkManager sharedManager] loggedin] == 0) {
        [self.tableView reloadData];
        [[NetworkManager sharedManager] showLoginWithCallback:^(void) {
            [self doRefresh:nil];
        }];
    } else if ([[NetworkManager sharedManager] loggedin] == -1) {
        [[NetworkManager sharedManager] checkSessionKeyWithSuccess:^(NSDictionary *responseObject) {
            [self doRefresh:nil];
        } failure:^(NSString *failureReason, NSInteger statusCode) {
            if([[NetworkManager sharedManager] loggedin] == 0) {
                [self doRefresh:nil];
            } else {
                [NetworkManager showMessage:failureReason];
            }
        }];
    }
}


#pragma mark - TableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0) {
        return 1;
    } else {
        return [[[NetworkManager sharedManager] galleryList] count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AT_ImageTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cImageCell forIndexPath:indexPath];
    cell.separatorInset = UIEdgeInsetsZero;

    if(indexPath.section == 0) {
        cell.textLabel.text = NSLocalizedString(@"label_nogallery", @"Settings");
        cell.detailTextLabel.text = @" ";
        cell.dateTextLabel.text = @" ";
        [cell.imageView setImage:[UIImage imageNamed:@"AppIcon"]];
    } else {
        cell.textLabel.text = [[[[NetworkManager sharedManager] galleryList] objectAtIndex:indexPath.row] objectForKey:@"_name"];
        //cell.textLabel.text = [[NSString alloc] initWithData:[[[[[NetworkManager sharedManager] galleryList] objectAtIndex:indexPath.row] objectForKey:@"_name"] dataUsingEncoding:NSUTF8StringEncoding] encoding:NSNonLossyASCIIStringEncoding];
        if([[[[[NetworkManager sharedManager] galleryList] objectAtIndex:indexPath.row] objectForKey:@"_desc"] length] > 0) {
            cell.detailTextLabel.text = [[[[NetworkManager sharedManager] galleryList] objectAtIndex:indexPath.row] objectForKey:@"_desc"];
            //cell.detailTextLabel.text = [[NSString alloc] initWithData:[[[[[NetworkManager sharedManager] galleryList] objectAtIndex:indexPath.row] objectForKey:@"_desc"] dataUsingEncoding:NSUTF8StringEncoding] encoding:NSNonLossyASCIIStringEncoding];
        } else {
            cell.detailTextLabel.text = @" ";
        }
        cell.dateTextLabel.text = [[[[[NetworkManager sharedManager] galleryList] objectAtIndex:indexPath.row] objectForKey:@"_lastchange"] substringToIndex:16];

        NSString *tmpURL = [NSString stringWithFormat:@"%@/mini/%@", cURL_BASE, [[[[NetworkManager sharedManager] galleryList] objectAtIndex:indexPath.row] objectForKey:@"_thumb"]];
        [cell.imageView setImageWithURL:[NSURL URLWithString:tmpURL] placeholderImage:[UIImage imageNamed:@"AppIcon"]];
    }
    return cell;
}


#pragma mark - TableView Delegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section == 1);
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
        UITableViewRowAction *modifyAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:NSLocalizedString(@"btn_slide_copylink", @"Upload Tab") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath *indexPath) {
            [UIPasteboard generalPasteboard].string = [[NetworkManager sharedManager] generateLinkForGallery:[[[[NetworkManager sharedManager] galleryList] objectAtIndex:indexPath.row] objectForKey:@"_code"]];
        }];
        modifyAction.backgroundColor = [UIColor orangeColor];

        UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:NSLocalizedString(@"btn_slide_delete", @"Upload Tab") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            [self doDeleteGallery:indexPath.row];
        }];
        return @[modifyAction, deleteAction];
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
        NSData *data = [[[[[NetworkManager sharedManager] galleryList] objectAtIndex:indexPath.row] objectForKey:@"_name"] dataUsingEncoding:NSUTF8StringEncoding];
        NSString *name = [[NSString alloc] initWithData:data encoding:NSNonLossyASCIIStringEncoding];
        
        self.imageTableViewController.gid = [[[[NetworkManager sharedManager] galleryList] objectAtIndex:indexPath.row] objectForKey:@"_id"];
        self.imageTableViewController.navigationItem.title = name;
    }
    [self.imageTableViewController resetForNewGroup];

    [[NetworkManager sharedManager] getImageListForGroup:self.imageTableViewController.gid success:^(NSDictionary *responseObject) {
        [[NetworkManager sharedManager] hideProgressHUD];
        [self.imageTableViewController setLastRefresh];
        [self.navigationController pushViewController:self.imageTableViewController animated:YES];
    } failure:^(NSString *failureReason, NSInteger statusCode) {
        [[NetworkManager sharedManager] hideProgressHUD];
        [NetworkManager showMessage:failureReason];
    }];
}


#pragma mark - RefreshController

- (void)doRefresh:(id)sender {
    if([[NetworkManager sharedManager] loggedin] == 1) {
        [[NetworkManager sharedManager] getGalleryList:^(NSDictionary *responseObject) {
            [self setLastRefresh];
            [[self refreshControl] endRefreshing];
            [self.tableView reloadData];
        } failure:^(NSString *failureReason, NSInteger statusCode) {
            [[self refreshControl] endRefreshing];
            [NetworkManager showMessage:failureReason];
        }];
    } else if ([[NetworkManager sharedManager] loggedin] == -1) {
        [[NetworkManager sharedManager] checkSessionKeyWithSuccess:^(NSDictionary *responseObject) {
            [self doRefresh:nil];
        }  failure:^(NSString *failureReason, NSInteger statusCode) {
            if([[NetworkManager sharedManager] loggedin] == 0) {
                [self doRefresh:sender];
            } else {
                [[self refreshControl] endRefreshing];
                [NetworkManager showMessage:failureReason];
            }
        }];
    } else {
        [[NetworkManager sharedManager] showLoginWithCallback:^(void) {
            [self doRefresh:sender];
        }];
        [[self refreshControl] endRefreshing];
    }
}

- (void)setLastRefresh {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:NSLocalizedString(@"label_lastrefresh_language", @"Gallery")]];
    [formatter setDateFormat:@"d. MMM, H:mm"];
    NSString *lastUpdated = [NSString stringWithFormat:NSLocalizedString(@"label_lastrefresh %@", @"Gallery"),
                             [formatter stringFromDate:[NSDate date]]];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:lastUpdated];
}


#pragma mark - Gallerys

- (void)sortGalleery {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"sort_title", @"Gallery")
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];

    
    UIAlertAction *sort1 = [UIAlertAction actionWithTitle:NSLocalizedString(@"sort_by_name", @"Gallery")  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    [[NetworkManager sharedManager] saveGallerySorted:0];
                                                    [self.tableView reloadData];
                                                }];
    [alert addAction:sort1];
    
    UIAlertAction *sort2 = [UIAlertAction actionWithTitle:NSLocalizedString(@"sort_by_date", @"Gallery")  style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [[NetworkManager sharedManager] saveGallerySorted:1];
                                                       [self.tableView reloadData];
                                                   }];
    [alert addAction:sort2];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"net_login_cancel", @"NetworkManager") style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
                                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                                   }];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)doAddGallery:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"newgallery_title", @"Gallery")
                                                                   message:nil
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

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"newgallery_btn_cancel", @"Gallery") style:UIAlertActionStyleDefault
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
    long gid = [[[[[NetworkManager sharedManager] galleryList] objectAtIndex:row] objectForKey:@"_id"] intValue];
    long bc = [[[[[NetworkManager sharedManager] galleryList] objectAtIndex:row] objectForKey:@"_images"] intValue];

    NSData *data = [[[[[NetworkManager sharedManager] galleryList] objectAtIndex:row] objectForKey:@"_name"] dataUsingEncoding:NSUTF8StringEncoding];
    NSString *name = [[NSString alloc] initWithData:data encoding:NSNonLossyASCIIStringEncoding];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedString(@"delgallery_question %@", @"Gallery"), name ]
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"delgallery_btn_withoutimage", @"Gallery") style:UIAlertActionStyleDestructive
                                               handler:^(UIAlertAction * action) {
                                                   [[NetworkManager sharedManager] showProgressHUD];
                                                   [[NetworkManager sharedManager] deleteGalleryWithID:gid andImages:0 success:^(NSDictionary *responseObject) {
                                                       [[NetworkManager sharedManager] hideProgressHUD];
                                                       [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:1]] withRowAnimation:YES];
                                                   } failure:^(NSString *failureReason, NSInteger statusCode) {
                                                       [[NetworkManager sharedManager] hideProgressHUD];
                                                       [NetworkManager showMessage:failureReason];
                                                   }];
                                               }];
    [alert addAction:ok];
    
    UIAlertAction *ok2 = [UIAlertAction actionWithTitle:[NSString stringWithFormat:NSLocalizedString(@"delgallery_btn_withimage %ld", @"Gallery"), bc] style:UIAlertActionStyleDestructive
                                               handler:^(UIAlertAction * action) {
                                                   [[NetworkManager sharedManager] showProgressHUD];
                                                   [[NetworkManager sharedManager] deleteGalleryWithID:gid andImages:1 success:^(NSDictionary *responseObject) {
                                                       [[NetworkManager sharedManager] hideProgressHUD];
                                                       [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:1]] withRowAnimation:YES];
                                                   } failure:^(NSString *failureReason, NSInteger statusCode) {
                                                       [[NetworkManager sharedManager] hideProgressHUD];
                                                       [NetworkManager showMessage:failureReason];
                                                   }];
                                               }];
    [alert addAction:ok2];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"delgallery_btn_cancel", @"Gallery") style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
                                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                                   }];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}


@end
