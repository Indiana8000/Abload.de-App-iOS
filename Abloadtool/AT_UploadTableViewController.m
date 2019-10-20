//
//  AT_UploadTableViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 27.10.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#define cUploadCell @"UploadTableViewCell"
#define cImageCell  @"ImageTableViewCell"

#import "AT_UploadTableViewController.h"


@interface AT_UploadTableViewController ()
    @property NSString* uploadStatus;
    @property NSMutableArray* uploadImages;

    @property UIBarButtonItem* btnSpace;
    @property UIBarButtonItem* btnUpload;
    @property UIBarButtonItem* btnAdd;

    @property UIBarButtonItem* btnShare;
    @property UIBarButtonItem* btnSpaceX;
    @property UIBarButtonItem* btnSelAll;
    @property UIBarButtonItem* btnDeSelAll;
    @property UIBarButtonItem* btnLinkOptions;
    @property UIBarButtonItem* btnLinkCopy;

    @property BOOL multiSelectMode;
    @property NSMutableIndexSet* selectedImages;

    @property AT_AlbumTableViewController* albumTableViewController;
    @property AT_ImagePickerViewController* imagePickerViewController;
    @property UINavigationController* imagePickerNavigationController;
@end


@implementation AT_UploadTableViewController

#pragma mark - View Live Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"nav_title_upload", @"Navigation");
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"20-gear-cloud"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettingsUpload)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"label_select", @"Image") style:UIBarButtonItemStylePlain target:self action:@selector(switchSelectMode)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.multiSelectMode = NO;
    self.selectedImages = [[NSMutableIndexSet alloc] init];

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(doRefresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;

    [self.tableView registerClass:[AT_UploadTableViewCell class] forCellReuseIdentifier:cUploadCell];
    [self.tableView registerClass:[AT_ImageTableViewCell class] forCellReuseIdentifier:cImageCell];
    
    self.btnUpload = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"btn_upload_upload", @"Upload Tab") style:UIBarButtonItemStylePlain target:self action:@selector(startUpload)];
    self.btnAdd = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"btn_image_add", @"Upload Tab") style:UIBarButtonItemStylePlain target:self action:@selector(showImagePicker)];
    self.btnSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self setToolbarItems:@[self.btnSpace, self.btnUpload, self.btnSpace, self.btnAdd, self.btnSpace]];

    self.btnShare = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(doShareLink)];
    self.btnShare.enabled = NO;
    self.btnSpaceX = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    self.btnSpaceX.width = 40;
    self.btnSelAll = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"photo_select_btn"] style:UIBarButtonItemStylePlain target:self action:@selector(selectAll)];
    self.btnDeSelAll = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"photo_deselected"] style:UIBarButtonItemStylePlain target:self action:@selector(deSelectAll)];
    self.btnLinkOptions = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"20-gear-clip"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettingsLinkType)];
    self.btnLinkCopy = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"901-clipboard"] style:UIBarButtonItemStylePlain target:self action:@selector(doCopyLinks)];
    self.btnLinkCopy.enabled = NO;
    
    self.uploadImages = [[NetworkManager sharedManager] uploadImages];
    self.uploadStatus = @"ADD";
    self.detailedViewController = [[AT_DetailedViewController alloc] init];
    
    if([[NetworkManager sharedManager] getSessionKey]) {
        [[NetworkManager sharedManager] checkSessionKeyWithSuccess:^(NSDictionary *responseObject) {
            [self.tableView reloadData];
        } failure:nil];
    } else {
        [[NetworkManager sharedManager] showLoginWithCallback:^{
            [[NetworkManager sharedManager] getGalleryList:^(NSDictionary *responseObject) {
                [self.tableView reloadData];
            } failure:nil];
        }];
    }
    
    UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc] init];
    self.albumTableViewController = [[AT_AlbumTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    self.imagePickerViewController = [[AT_ImagePickerViewController alloc] initWithCollectionViewLayout:layout];
    self.imagePickerNavigationController = [[UINavigationController alloc] initWithRootViewController:self.albumTableViewController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTable) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.tabBarController.tabBar setHidden:NO];
    [self.navigationController setToolbarHidden:NO animated:animated];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)reloadTable {
    [[NetworkManager sharedManager] checkAndLoadSharedImages];
    [self.tableView reloadData];
    if([[[NetworkManager sharedManager] lastRefresh] timeIntervalSinceNow] < -300) {
        [[NetworkManager sharedManager] getGalleryList:^(NSDictionary *responseObject) {
            [self.tableView reloadData];
        } failure:nil];
    }
}

#pragma mark - Image Selection

- (void)switchSelectMode {
    self.multiSelectMode = !self.multiSelectMode;
    if(self.multiSelectMode) {
        self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"label_cancel", @"Image");
        [self setToolbarItems:@[self.btnShare, self.btnSpaceX, self.btnSpace, self.btnSelAll, self.btnDeSelAll, self.btnSpace, self.btnLinkOptions, self.btnLinkCopy]];
    } else {
        self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"label_select", @"Image");
        [self setToolbarItems:@[self.btnSpace, self.btnUpload, self.btnSpace, self.btnAdd, self.btnSpace]];
    }
    [self.tableView reloadData];
}

- (void)selectAll {
    [self.selectedImages removeAllIndexes];
    [self.selectedImages addIndexesInRange:NSMakeRange(0, [self.uploadImages count])];
    self.btnLinkCopy.enabled = YES;
    self.btnShare.enabled = YES;
    [self.tableView reloadData];
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


#pragma mark - TableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if([self.uploadStatus caseInsensitiveCompare:@"ADD"] == NSOrderedSame) {
        return 2;
    } else {
        return 1;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            if([self.uploadStatus caseInsensitiveCompare:@"DONE"] == NSOrderedSame) {
                return NSLocalizedString(@"title_images_uploaded", @"Upload Tab");
            } else {
                return NSLocalizedString(@"title_images_waiting_for_upload", @"Upload Tab");
            }
            break;
        case 1:
            return NSLocalizedString(@"title_last5", @"Upload Tab");
            break;
        default:
            return nil;
            break;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case 0:
            if([self.uploadImages count] > 0) {
                if([[[NetworkManager sharedManager] settingResolutionSelected] compare:NSLocalizedString(@"label_keeporiginal", @"Settings")] != NSOrderedSame) {
                    return [NSString stringWithFormat:NSLocalizedString(@"%@ %@:\n%@: %@\n%@: %@\n%@: %@", @"Upload Tab"),
                            NSLocalizedString(@"nav_tabbar_upload",@"Navigation"),
                            NSLocalizedString(@"nav_title_settings",@"Navigation"),
                            NSLocalizedString(@"label_gallery",@"Settings"),
                            [[NetworkManager sharedManager] settingGallerySelectedName],
                            NSLocalizedString(@"label_resize",@"Settings"),
                            [[NetworkManager sharedManager] settingResolutionSelected],
                            NSLocalizedString(@"label_scale",@"Settings"),
                            [[[[NetworkManager sharedManager] settingAvailableScalingList] objectAtIndex:[[NetworkManager sharedManager] settingScaleSelected]] objectAtIndex:0]];

                } else {
                    return [NSString stringWithFormat:NSLocalizedString(@"%@ %@:\n%@: %@\n%@: %@", @"Upload Tab"),
                            NSLocalizedString(@"nav_tabbar_upload",@"Navigation"),
                            NSLocalizedString(@"nav_title_settings",@"Navigation"),
                            NSLocalizedString(@"label_gallery",@"Settings"),
                            [[NetworkManager sharedManager] settingGallerySelectedName],
                            NSLocalizedString(@"label_resize",@"Settings"),
                            [[NetworkManager sharedManager] settingResolutionSelected]];
                }
            } else {
                return NSLocalizedString(@"label_empty", @"Upload Tab");
            }
            break;
            default:
            return nil;
            break;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            if([self.uploadImages count] > 0) {
                self.btnUpload.enabled = YES;
            } else {
                self.btnUpload.enabled = NO;
            }
            return [self.uploadImages count];
            break;
        case 1:
            return [[[NetworkManager sharedManager] imageLast] count];
            break;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;

    if(indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:cUploadCell forIndexPath:indexPath];
        cell.separatorInset = UIEdgeInsetsZero;
        AT_UploadTableViewCell* tmpCell = (id)cell;
        cell.detailTextLabel.textAlignment = NSTextAlignmentRight;
        cell.detailTextLabel.text = [self bytesToUIString:[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_filesize"]];
        if([[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_filesize"] intValue] > [NetworkManager apiMaxImageSize]) {
            cell.detailTextLabel.textColor = [UIColor systemRedColor];
            cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"label_toolarge %@ %@", @"Upload Tab"), cell.detailTextLabel.text, [self bytesToUIString:[NSNumber numberWithInt:[NetworkManager apiMaxImageSize]]]];
        } else {
            if (@available(iOS 13.0, *)) {
                cell.detailTextLabel.textColor = [UIColor labelColor];
            } else {
                cell.detailTextLabel.textColor = [UIColor blackColor];
            }
        }
        cell.textLabel.text = [[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_filename"];
        tmpCell.dateTextLabel.text = [[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_date"];
        tmpCell.canbeSelected = self.multiSelectMode;
        if([self.selectedImages containsIndex:indexPath.row]) {
            tmpCell.isSelected = YES;
        } else {
            tmpCell.isSelected = NO;
        }
        if([[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_uploaded"] intValue] == 1) {
            NSString *tmpURL = [NSString stringWithFormat:@"%@/mini/%@", cURL_BASE, [[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_filename"]];
            [cell.imageView setImageWithURL:[NSURL URLWithString:tmpURL] placeholderImage:[UIImage imageNamed:@"AppIcon"]];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [tmpCell.progressView setBackgroundColor:[UIColor clearColor]];
            [tmpCell.progressView setProgress:0.0];
        } else if([[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_uploaded"] intValue] == -1) {
            [cell.imageView setImageWithURL:[NSURL fileURLWithPath:[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_thumb"]] placeholderImage:[UIImage imageNamed:@"AppIcon"]];
            cell.accessoryType = UITableViewCellAccessoryNone;
            [tmpCell.progressView setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]];
            [tmpCell.progressView setProgress:[[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_progress"] doubleValue]];
        } else {
            [cell.imageView setImageWithURL:[NSURL fileURLWithPath:[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_thumb"]] placeholderImage:[UIImage imageNamed:@"AppIcon"]];
            cell.accessoryType = UITableViewCellAccessoryNone;
            [tmpCell.progressView setBackgroundColor:[UIColor clearColor]];
            [tmpCell.progressView setProgress:0.0];
        }
    } else if(indexPath.section == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:cImageCell forIndexPath:indexPath];
        cell.separatorInset = UIEdgeInsetsZero;
        cell.detailTextLabel.textAlignment = NSTextAlignmentRight;
        cell.textLabel.text = [[[[NetworkManager sharedManager] imageLast] objectAtIndex:indexPath.row] objectForKey:@"_filename"];
        cell.detailTextLabel.text = [self bytesToUIString:[[[[NetworkManager sharedManager] imageLast] objectAtIndex:indexPath.row] objectForKey:@"_filesize"]];
        NSString *tmpURL = [NSString stringWithFormat:@"%@/mini/%@", cURL_BASE, [[[[NetworkManager sharedManager] imageLast] objectAtIndex:indexPath.row] objectForKey:@"_filename"]];
        [cell.imageView setImageWithURL:[NSURL URLWithString:tmpURL] placeholderImage:[UIImage imageNamed:@"AppIcon"]];
        AT_ImageTableViewCell* tmpCell = (id)cell;
        tmpCell.dateTextLabel.text = [[[[NetworkManager sharedManager] imageLast] objectAtIndex:indexPath.row] objectForKey:@"_date"];
    }
    
    return cell;
}


#pragma mark - TableView Delegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    if((indexPath.section == 1) || ([[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_uploaded"] intValue] == 1)) {
        UITableViewRowAction *modifyAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:NSLocalizedString(@"btn_slide_copylink", @"Upload Tab") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath *indexPath) {
            if(indexPath.section == 1) {
                [UIPasteboard generalPasteboard].string = [[NetworkManager sharedManager] generateLinkForImage:[[[[NetworkManager sharedManager] imageLast] objectAtIndex:indexPath.row] objectForKey:@"_filename"]];
            } else {
                [UIPasteboard generalPasteboard].string = [[NetworkManager sharedManager] generateLinkForImage:[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_filename"]];
            }
        }];
        modifyAction.backgroundColor = [UIColor orangeColor];
        return @[modifyAction];
    } else {
        UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:NSLocalizedString(@"btn_slide_delete", @"Upload Tab") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            [[NetworkManager sharedManager] removeImageFromDisk:indexPath.row andList:YES];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:YES];
        }];
        return @[deleteAction];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        if(self.multiSelectMode) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            AT_UploadTableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
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
            self.detailedViewController.imageList = self.uploadImages;
            self.detailedViewController.imageID = indexPath.row;
            [self.navigationController pushViewController:self.detailedViewController animated:YES];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    } else if(indexPath.section == 1) {
        self.detailedViewController.imageList = [[NetworkManager sharedManager] imageLast];
        self.detailedViewController.imageID = indexPath.row;
        [self.navigationController pushViewController:self.detailedViewController animated:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}


#pragma mark - Actions

- (void)showSettingsUpload {
    if(self.pageSetting == nil) {
        self.pageSetting = [[AT_SettingTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        self.navSetting = [[UINavigationController alloc] initWithRootViewController:self.pageSetting];
        self.navSetting.modalPresentationStyle = UIModalPresentationPopover;
    }
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController pushViewController:self.pageSetting animated:YES];
    } else {
        [self.navigationController presentViewController:self.navSetting animated:YES completion:nil];
        UIPopoverPresentationController *presentationController =[self.navSetting popoverPresentationController];
        presentationController.barButtonItem = self.navigationItem.leftBarButtonItem;
        presentationController.delegate = self;
    }
}

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    [self.tableView reloadData];
    return YES;
}

- (void)showSettingsLinkType {
    AT_SettingOutputLinksTableViewController* tmpOLT = [[AT_SettingOutputLinksTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController* tmpNC = [[UINavigationController alloc] initWithRootViewController:tmpOLT];
    tmpNC.modalPresentationStyle = UIModalPresentationPopover;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController pushViewController:tmpOLT animated:YES];
    } else {
        [self.navigationController presentViewController:tmpNC animated:YES completion:nil];
        UIPopoverPresentationController *presentationController =[tmpNC popoverPresentationController];
        presentationController.barButtonItem = self.btnLinkOptions;
    }
}

- (void)doCopyLinks {
    NSMutableString* linkX = [[NSMutableString alloc] init];
    [self.selectedImages enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [linkX appendString:[[NetworkManager sharedManager] generateLinkForImage:[[self.uploadImages objectAtIndex:idx] objectForKey:@"_filename"]]];
        [linkX appendString:@"\n"];
    }];
    [UIPasteboard generalPasteboard].string = linkX;
    NSUInteger numberOfOccurrences = [[linkX componentsSeparatedByString:@"\n"] count] - 1;
    [NetworkManager showMessage:[NSString stringWithFormat:NSLocalizedString(@"msg_copylink_done %ld", @"Upload Tab"), numberOfOccurrences]];
}

- (void)doShareLink {
    NSMutableArray *activityItems = [[NSMutableArray alloc] init];
    [self.selectedImages enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        NSString* tmpName = [[self.uploadImages objectAtIndex:idx] objectForKey:@"_filename"];
        NSString* tmpURL = [[NetworkManager sharedManager] generateLinkForImage:tmpName];
        [activityItems addObject:tmpURL];
    }];
    
    UIActivityViewController *activityViewControntroller = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityViewControntroller.excludedActivityTypes = @[];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        activityViewControntroller.popoverPresentationController.barButtonItem = self.btnShare;
    }
    [self presentViewController:activityViewControntroller animated:true completion:nil];
}


#pragma mark - Add Image

- (void)showImagePicker {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if(status == PHAuthorizationStatusAuthorized) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.imagePickerViewController prepareDisplay];
                self.albumTableViewController.imagePickerViewController = self.imagePickerViewController;
                self.imagePickerViewController.collectionView.backgroundColor = self.tableView.backgroundColor;
                [self presentViewController:self.imagePickerNavigationController animated:YES completion:nil];
                [self.imagePickerNavigationController pushViewController:self.imagePickerViewController animated:NO];
            });
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                           message:NSLocalizedString(@"msg_no_access_photos", @"Upload Tab")
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"btn_settings", @"Upload Tab")  style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:[[NSDictionary alloc] init] completionHandler:nil];
                                                       }];
            [alert addAction:ok];
            
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"net_login_cancel", @"NetworkManager") style:UIAlertActionStyleCancel
                                                           handler:^(UIAlertAction * action) {
                                                               [alert dismissViewControllerAnimated:YES completion:nil];
                                                           }];
            [alert addAction:cancel];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

#pragma mark - Upload

- (void)startUpload {
    if([self.uploadStatus caseInsensitiveCompare:@"ADD"] == NSOrderedSame) {
        [self startUploadingImages];
    } else if([self.uploadStatus caseInsensitiveCompare:@"UPLOAD"] == NSOrderedSame) {
        if([[NetworkManager sharedManager] uploadTask]) {
            [[[NetworkManager sharedManager] uploadTask] cancel];
            self.uploadStatus = @"ADD";
            self.btnUpload.title = NSLocalizedString(@"btn_upload_upload", @"Upload Tab");
            self.btnAdd.enabled = YES;
            [self.tableView reloadData];
        }
    } else if([self.uploadStatus caseInsensitiveCompare:@"DONE"] == NSOrderedSame) {
        self.uploadStatus = @"ADD";
        self.btnUpload.title = NSLocalizedString(@"btn_upload_upload", @"Upload Tab");
        for(int i = (int)[self.uploadImages count];i > 0;i--) {
            if([[[self.uploadImages objectAtIndex:(i -1)] objectForKey:@"_uploaded"] intValue] >= 1)
                [self.uploadImages removeObjectAtIndex:(i -1)];
        }
        self.btnAdd.enabled = YES;
        self.navigationItem.leftBarButtonItem.enabled = YES;
        self.navigationItem.rightBarButtonItem.enabled = NO;
        [self.selectedImages removeAllIndexes];
        [self.tableView reloadData];
    }
}

- (void)startUploadingImages {
    if([self.uploadImages count] > 0) {
        if([[NetworkManager sharedManager] loggedin] != 1) {
            [[NetworkManager sharedManager] showLoginWithCallback:^{
                [self startUploadingImages];
            }];
        } else {
            self.uploadStatus = @"UPLOAD";
            self.btnUpload.title = NSLocalizedString(@"btn_upload_cancel", @"Upload Tab");
            self.btnAdd.enabled = NO;
            self.navigationItem.leftBarButtonItem.enabled = NO;
            [UIApplication sharedApplication].idleTimerDisabled = YES;
            [self.tableView reloadData];
            //[NSTimer scheduledTimerWithTimeInterval:0.1 target:self.tableView selector:@selector(reloadData) userInfo:nil repeats:NO];
            [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(uploadNextImage) userInfo:nil repeats:NO];
        }
    }
}

- (void)uploadNextImage {
    unsigned long i;
    for(i = 0;i < [self.uploadImages count];i++) {
        if([[[self.uploadImages objectAtIndex:i] objectForKey:@"_uploaded"] intValue] == 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
                [self uploadImageWithID:i];
            });
            return;
        }
    }
    [[NetworkManager sharedManager] getGalleryList:^(NSDictionary *responseObject) {
        [self.tableView reloadData];
    } failure:^(NSString *failureReason, NSInteger statusCode) {
        [self.tableView reloadData];
    }];
    self.uploadStatus = @"DONE";
    self.btnUpload.title = NSLocalizedString(@"btn_upload_clear", @"Upload Tab");
    self.navigationItem.rightBarButtonItem.enabled = YES;
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self.tableView scrollsToTop];
    [NetworkManager showMessage:NSLocalizedString(@"msg_upload_done", @"Upload Tab")];
}

- (void)uploadImageWithID:(NSInteger) imageID {
    [[self.uploadImages objectAtIndex:imageID] setObject:@"-1" forKey:@"_uploaded"];
    [[NetworkManager sharedManager] uploadImageWithID:imageID progress:^(double fraction) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(fraction >= 0.0) {
                [self updateTableViewCellAtRow:imageID WithProgress:fraction];
            } else if(fraction == -2.0) {
                [self updateTableViewCellAtRow:imageID WithText:NSLocalizedString(@"label_resizing_image", @"Upload Tab")];
            } else if(fraction == -1.0) {
                [self updateTableViewCellAtRow:imageID WithText:[self bytesToUIString:[[self.uploadImages objectAtIndex:imageID] objectForKey:@"_filesize"]]];
            }
        });
    } success:^(NSDictionary *responseObject) {
        if([[responseObject objectForKey:@"images"] objectForKey:@"image"]) {
            [[self.uploadImages objectAtIndex:imageID] setObject:@"1" forKey:@"_uploaded"];
            [[self.uploadImages objectAtIndex:imageID] setObject:[[[responseObject objectForKey:@"images"] objectForKey:@"image"] objectForKey:@"_newname"] forKey:@"_filename"];
            [[NetworkManager sharedManager] removeImageFromDisk:imageID andList:NO];
            
            AT_UploadTableViewCell* tmpCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:imageID inSection:0]];
            tmpCell.accessoryType = UITableViewCellAccessoryCheckmark;
            [tmpCell.progressView setProgress:0.0];
            [tmpCell.progressView setBackgroundColor:[UIColor clearColor]];

            [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(uploadNextImage) userInfo:nil repeats:NO];
        }
    } failure:^(NSString *failureReason, NSInteger statusCode) {
        [[self.uploadImages objectAtIndex:imageID] setObject:@"0" forKey:@"_uploaded"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            AT_UploadTableViewCell* tmpCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:imageID inSection:0]];
            tmpCell.accessoryType = UITableViewCellAccessoryNone;
            [tmpCell.progressView setProgress:0.0];
            [tmpCell.progressView setBackgroundColor:[UIColor clearColor]];

            self.uploadStatus = @"ADD";
            self.btnUpload.title = NSLocalizedString(@"btn_upload_upload", @"Upload Tab");
            self.btnAdd.enabled = YES;
            [self.navigationItem.leftBarButtonItem setEnabled:YES];
            [NetworkManager showMessage:failureReason];
            [self.tableView reloadData];
        });

    }];
}

- (void)updateTableViewCellAtRow:(NSInteger) idx WithProgress:(double) fractionCompleted {
    for (NSIndexPath *indexPathForVisibleRow in self.tableView.indexPathsForVisibleRows) {
        if(indexPathForVisibleRow.section == 0 && indexPathForVisibleRow.row == idx) {
            AT_UploadTableViewCell *visibleCell = [self.tableView cellForRowAtIndexPath:indexPathForVisibleRow];
            if (visibleCell != nil) {
                [visibleCell.progressView setProgress:fractionCompleted];
                [visibleCell.progressView setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]];
            }
        }
    }
}

- (void)updateTableViewCellAtRow:(NSInteger) idx WithText:(NSString*) text {
    for (NSIndexPath *indexPathForVisibleRow in self.tableView.indexPathsForVisibleRows) {
        if(indexPathForVisibleRow.section == 0 && indexPathForVisibleRow.row == idx) {
            AT_UploadTableViewCell *visibleCell = [self.tableView cellForRowAtIndexPath:indexPathForVisibleRow];
            if (visibleCell != nil) {
                visibleCell.detailTextLabel.text = text;
            }
        }
    }
}


@end
