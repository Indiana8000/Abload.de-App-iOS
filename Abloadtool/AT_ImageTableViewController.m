//
//  AT_ImageTableViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 10.01.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#define cImageCell @"ImageTableViewCell"

#import "AT_ImageTableViewController.h"


@interface AT_ImageTableViewController ()
@property BOOL multiSelectMode;
@property NSMutableIndexSet* selectedImages;
@property UIBarButtonItem* btnShare;
@property UIBarButtonItem* btnLinkCopy;
@end


@implementation AT_ImageTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.multiSelectMode = NO;
    self.selectedImages = [[NSMutableIndexSet alloc] init];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"label_select", @"Image") style:UIBarButtonItemStylePlain target:self action:@selector(switchSelectMode)];

    UIBarButtonItem* btnSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    self.btnShare = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(askShare)];
    self.btnShare.enabled = NO;

    UIBarButtonItem* btnSpaceX = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    btnSpaceX.width = 40;

    UIBarButtonItem* btnSelAll = [[UIBarButtonItem alloc] initWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"photo_selected"]]];
    [btnSelAll.customView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectAll)]];
    
    UIBarButtonItem* btnDeSelAll = [[UIBarButtonItem alloc] initWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"photo_deselected"]]];
    [btnDeSelAll.customView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(deSelectAll)]];

    UIBarButtonItem* btnLinkOptions = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"20-gear-clip"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettingsLinkType)];
    self.btnLinkCopy = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"901-clipboard"] style:UIBarButtonItemStylePlain target:self action:@selector(doCopyLinks)];
    self.btnLinkCopy.enabled = NO;

    [self setToolbarItems:@[self.btnShare, btnSpace, btnSpaceX, btnSelAll, btnDeSelAll, btnSpace, btnLinkOptions, self.btnLinkCopy]];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(doRefresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    [self.tableView registerClass:[AT_ImageTableViewCell class] forCellReuseIdentifier:cImageCell];
    self.detailedViewController = [[AT_DetailedViewController alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    //[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:animated];
    [self.tabBarController.tabBar setHidden:NO];
    [self.tableView reloadData];
    if(self.multiSelectMode)
        [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)resetForNewGroup {
    self.btnLinkCopy.enabled = NO;
    self.btnShare.enabled = NO;
    [self.selectedImages removeAllIndexes];
    if(self.multiSelectMode)
        [self switchSelectMode];
}

- (void)switchSelectMode {
    self.multiSelectMode = !self.multiSelectMode;
    if(self.multiSelectMode) {
        self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"label_cancel", @"Image");
        [self.navigationController setToolbarHidden:NO animated:YES];
    } else {
        self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"label_select", @"Image");
        [self.navigationController setToolbarHidden:YES animated:YES];
    }
    [self.tableView reloadData];
}

- (void)selectAll {
    if([[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] count] > 0) {
        [self.selectedImages removeAllIndexes];
        [self.selectedImages addIndexesInRange:NSMakeRange(0, [[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] count])];
        self.btnLinkCopy.enabled = YES;
        self.btnShare.enabled = YES;
        [self.tableView reloadData];
    }
}

- (void)deSelectAll {
    [self.selectedImages removeAllIndexes];
    self.btnLinkCopy.enabled = NO;
    self.btnShare.enabled = NO;
    [self.tableView reloadData];
}

#pragma mark - Helper

- (NSString *)bytesToUIString:(NSNumber *) number {
    double size = [number doubleValue];
    unsigned long i = 0;
    while (size >= 1024) {
        size /= 1024;
        i++;
    }
    NSArray *extension = [[NSArray alloc] initWithObjects:@"Byte", @"KB", @"MB", @"GB", @"TB", @"PB", @"EB", @"ZB", @"YB" ,@"???" , nil];
    
    if(i>([extension count]-2)) i = [extension count]-1;
    return [NSString stringWithFormat:@"%.1f %@", size, [extension objectAtIndex:i]];
}


#pragma mark - TableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AT_ImageTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cImageCell forIndexPath:indexPath];
    cell.separatorInset = UIEdgeInsetsZero;
    cell.detailTextLabel.textAlignment = NSTextAlignmentRight;

    cell.textLabel.text = [[[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] objectAtIndex:indexPath.row] objectForKey:@"_filename"];
    cell.detailTextLabel.text = [self bytesToUIString:[[[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] objectAtIndex:indexPath.row] objectForKey:@"_filesize"]];
    cell.dateTextLabel.text = [[[[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] objectAtIndex:indexPath.row] objectForKey:@"_date"] substringToIndex:16];

    NSString *tmpURL = [NSString stringWithFormat:@"%@/mini/%@", cURL_BASE, [[[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] objectAtIndex:indexPath.row] objectForKey:@"_filename"]];
    [cell.imageView setImageWithURL:[NSURL URLWithString:tmpURL] placeholderImage:[UIImage imageNamed:@"AppIcon"]];
    
    cell.canbeSelected = self.multiSelectMode;
    if([self.selectedImages containsIndex:indexPath.row]) {
        cell.isSelected = YES;
    } else {
        cell.isSelected = NO;
    }
    
    //UILongPressGestureRecognizer* longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(doShowImage:)];
    //[cell addGestureRecognizer:longPressGesture];
    
    return cell;
}


#pragma mark - TableView Delegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *modifyAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:NSLocalizedString(@"btn_slide_copylink", @"Upload Tab") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath *indexPath) {
        [UIPasteboard generalPasteboard].string = [[NetworkManager sharedManager] generateLinkForImage:[[[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] objectAtIndex:indexPath.row] objectForKey:@"_filename"]];
    }];
    modifyAction.backgroundColor = [UIColor orangeColor];
    
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:NSLocalizedString(@"btn_slide_delete", @"Upload Tab") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [[NetworkManager sharedManager] deleteImageWithName:[[[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] objectAtIndex:indexPath.row] objectForKey:@"_filename"] success:^(NSDictionary *responseObject) {
            [[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] removeObjectAtIndex:indexPath.row];
            NSMutableIndexSet* newIndexSet = [[NSMutableIndexSet alloc] init];
            [self.selectedImages enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                if(idx < indexPath.row) {
                    [newIndexSet addIndex:idx];
                } else {
                    [newIndexSet addIndex:(idx -1)];
                }
            }];
            self.selectedImages = newIndexSet;
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:YES];
        } failure:^(NSString *failureReason, NSInteger statusCode) {
            [NetworkManager showMessage:failureReason];
        }];
    }];
    return @[modifyAction, deleteAction];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(self.multiSelectMode) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        AT_ImageTableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if([self.selectedImages containsIndex:indexPath.row]) {
            [self.selectedImages removeIndex:indexPath.row];
            cell.isSelected = NO;
        } else {
            [self.selectedImages addIndex:indexPath.row];
            cell.isSelected = YES;
        }
        if([self.selectedImages count] > 0) {
            self.btnLinkCopy.enabled = YES;
            self.btnShare.enabled = YES;
        } else {
            self.btnLinkCopy.enabled = NO;
            self.btnShare.enabled = NO;
        }
    } else {
        self.detailedViewController.imageID = indexPath.row;
        self.detailedViewController.imageList = [[[NetworkManager sharedManager] imageList] objectForKey:self.gid];
        self.detailedViewController.title = NSLocalizedString(@"label_loading", @"Image");
        [self.navigationController pushViewController:self.detailedViewController animated:YES];
    }
}


#pragma mark - RefreshController

- (void)doRefresh:(id)sender {
    if([[NetworkManager sharedManager] loggedin] == 1) {
        [[NetworkManager sharedManager] getImageListForGroup:self.gid success:^(NSDictionary *responseObject) {
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


#pragma mark - Actions

- (void)doShowImage:(UIGestureRecognizer *)gestureRecognizer {
    if(gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        NSLog(@"gestureRecognizer: %@", gestureRecognizer.view);
        NSIndexPath* indexPath = [self.tableView indexPathForCell:(AT_ImageTableViewCell*)gestureRecognizer.view];
        self.detailedViewController.imageID = indexPath.row;
        self.detailedViewController.imageList = [[[NetworkManager sharedManager] imageList] objectForKey:self.gid];
        self.detailedViewController.title = NSLocalizedString(@"label_loading", @"Image");
        [self.navigationController pushViewController:self.detailedViewController animated:YES];
    }
}

- (void)doCopyLinks {
    NSMutableString* linkX = [[NSMutableString alloc] init];
    /*
    for(NSUInteger i = 0;i < [[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] count];i++) {
        [linkX appendString:[[NetworkManager sharedManager] generateLinkForImage:[[[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] objectAtIndex:i] objectForKey:@"_filename"]]];
        [linkX appendString:@"\n"];
    }
     */
    [self.selectedImages enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [linkX appendString:[[NetworkManager sharedManager] generateLinkForImage:[[[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] objectAtIndex:idx] objectForKey:@"_filename"]]];
        [linkX appendString:@"\n"];
    }];
    [UIPasteboard generalPasteboard].string = linkX;
    NSUInteger numberOfOccurrences = [[linkX componentsSeparatedByString:@"\n"] count] - 1;
    [NetworkManager showMessage:[NSString stringWithFormat:NSLocalizedString(@"msg_copylink_done %ld", @"Upload Tab"), numberOfOccurrences]];
}

- (void)doCopyLinksForRow:(long) row AsType:(int) linkType {
    [[NetworkManager sharedManager] saveOutputLinkSelected:linkType];
    [UIPasteboard generalPasteboard].string = [[NetworkManager sharedManager] generateLinkForImage:[[[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] objectAtIndex:row] objectForKey:@"_filename"]];
}

- (void)onSelfLongpressDetected:(UILongPressGestureRecognizer*)pGesture {
    if(pGesture.state == UIGestureRecognizerStateBegan) {
        UITableView* tableView = (UITableView*)self.view;
        CGPoint touchPoint = [pGesture locationInView:self.view];
        NSIndexPath* row = [tableView indexPathForRowAtPoint:touchPoint];
        if (row != nil) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"btn_slide_copylink", @"Upload Tab")
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            for(int i = 0;i < [[[NetworkManager sharedManager] settingAvailableOutputLinkList] count];++i) {
                UIAlertAction *linkX = [UIAlertAction actionWithTitle:[[[[NetworkManager sharedManager] settingAvailableOutputLinkList] objectAtIndex:i] objectForKey:@"name"]  style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [self doCopyLinksForRow:row.row AsType:i];
                                                              }];
                [alert addAction:linkX];
            }
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"net_login_cancel", @"NetworkManager") style:UIAlertActionStyleCancel
                                                           handler:^(UIAlertAction * action) {
                                                               [alert dismissViewControllerAnimated:YES completion:nil];
                                                           }];
            [alert addAction:cancel];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

- (void)showSettingsLinkType {
    if(self.pageSetting == nil) {
        self.pageSetting = [[AT_SettingOutputLinksTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        self.navSetting = [[UINavigationController alloc] initWithRootViewController:self.pageSetting];
        self.navSetting.modalPresentationStyle = UIModalPresentationPopover;
    } else {
        [self.pageSetting.tableView reloadData];
    }
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController pushViewController:self.pageSetting animated:YES];
    } else {
        [self.navigationController presentViewController:self.navSetting animated:YES completion:nil];
        UIPopoverPresentationController *presentationController =[self.navSetting popoverPresentationController];
        presentationController.barButtonItem = self.btnLinkCopy;
    }
}

- (void)askShare {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:NSLocalizedString(@"label_share_warning", @"Image")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"btn_ok", @"Upload Tab")  style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction * action) {
                                                      [self doShare];
                                                  }];
    [alert addAction:ok];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"net_login_cancel", @"NetworkManager") style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
                                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                                   }];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)doShare {
    NSMutableArray *activityItems = [[NSMutableArray alloc] init];
    [self.selectedImages enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        AT_ActivityItemProvider* tmp = [[AT_ActivityItemProvider alloc] initWithPlaceholderItem:[[UIImage alloc] init]];
        tmp.imageName = [[[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] objectAtIndex:idx] objectForKey:@"_filename"];
        [activityItems addObject:tmp];
    }];

    UIActivityViewController *activityViewControntroller = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityViewControntroller.excludedActivityTypes = @[];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        activityViewControntroller.popoverPresentationController.barButtonItem = self.btnShare;
    }
    [self presentViewController:activityViewControntroller animated:true completion:nil];
}

@end
