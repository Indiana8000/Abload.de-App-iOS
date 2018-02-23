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

@end


@implementation AT_ImageTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItems = @[
                                                [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"901-clipboard"] style:UIBarButtonItemStylePlain target:self action:@selector(doCopyLinks)],
                                                [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"20-gear-clip"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettingsLinkType)]
                                                ];

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(doRefresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    [self.tableView registerClass:[AT_ImageTableViewCell class] forCellReuseIdentifier:cImageCell];
    self.detailedViewController = [[AT_DetailedViewController alloc] init];
}

- (void) viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
    [self.tabBarController.tabBar setHidden:NO];
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
    
    //UILongPressGestureRecognizer* longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onSelfLongpressDetected:)];
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
    self.detailedViewController.imageID = indexPath.row;
    self.detailedViewController.imageList = [[[NetworkManager sharedManager] imageList] objectForKey:self.gid];
    
    self.detailedViewController.title = NSLocalizedString(@"label_loading", @"Image");
    [self.navigationController pushViewController:self.detailedViewController animated:YES];
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

- (void)doCopyLinks {
    NSMutableString* linkX = [[NSMutableString alloc] init];
    unsigned long i;
    for(i = 0;i < [[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] count];i++) {
        [linkX appendString:[[NetworkManager sharedManager] generateLinkForImage:[[[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] objectAtIndex:i] objectForKey:@"_filename"]]];
        [linkX appendString:@"\n"];
    }
    [UIPasteboard generalPasteboard].string = linkX;
    [NetworkManager showMessage:[NSString stringWithFormat:NSLocalizedString(@"msg_copylink_done %ld", @"Upload Tab"), i]];
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
        presentationController.barButtonItem = self.navigationItem.rightBarButtonItems[1];
    }
}


@end
