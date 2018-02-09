//
//  AT_UploadTableViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 27.10.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#define cButtonCell @"ButtonTableViewCell"
#define cUploadCell @"UploadTableViewCell"
#define cImageCell @"ImageTableViewCell"

#import "AT_UploadTableViewController.h"

@interface AT_UploadTableViewController ()
    @property (nonatomic, strong) NSString* uploadStatus;
    @property (nonatomic, strong) NSMutableArray* uploadImages;
@end

@implementation AT_UploadTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Init Navigation Controller + Buttons
    self.navigationItem.title = NSLocalizedString(@"nav_title_upload", @"Navigation");
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"20-gear-2"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"901-clipboard"] style:UIBarButtonItemStylePlain target:self action:@selector(copyLinksPasteboard)];
    [self.navigationItem.rightBarButtonItem setEnabled:NO];

    // Init TableView
    [self.tableView registerClass:[AT_UploadTableViewCell class] forCellReuseIdentifier:cUploadCell];
    [self.tableView registerClass:[AT_ImageTableViewCell class] forCellReuseIdentifier:cImageCell];
    [self.tableView registerClass:UITableViewCell.self forCellReuseIdentifier:cButtonCell];
    //[self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    //self.tableView.rowHeight = 57.0;
    
    // Link uploadImages
    self.uploadImages = [[NetworkManager sharedManager] uploadImages];
    
    // Init uploadStatus
    self.uploadStatus = @"ADD";
    
    // Init detailed View
    self.detailedViewController = [[AT_DetailedViewController alloc] init];
    
    if(([[NetworkManager sharedManager] token] == nil) || ([[[NetworkManager sharedManager] token] length] == 0)) {
        [[NetworkManager sharedManager] showLoginWithViewController:self andCallback:^{
            [[NetworkManager sharedManager] getGalleryList:nil failure:nil];
        }];
    } else {
        [[NetworkManager sharedManager] tokenCheckWithSuccess:^(NSDictionary *responseObject) {
            //NSLog(@"NET - initCheck Success: \r\n%@", responseObject);
            [self.tableView reloadData];
        }  failure:^(NSString *failureReason, NSInteger statusCode) {
            //NSLog(@"NET - initCheck Error: %@", failureReason);
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if([self.uploadStatus caseInsensitiveCompare:@"ADD"] == NSOrderedSame) {
        if([[[NetworkManager sharedManager] imageLast] count] > 0) {
            return 4;
        } else {
            return 3;
        }
    } else {
        return 2;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 3) {
        return NSLocalizedString(@"title_last5", @"Upload Tab");
    } else {
        return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0) {
        return 1;
    } else if(section == 2) {
        if([self.uploadStatus caseInsensitiveCompare:@"ADD"] == NSOrderedSame) {
            return 1;
        } else {
            return 0;
        }
    } else if(section == 3) {
        return [[[NetworkManager sharedManager] imageLast] count];
    } else {
        return [self.uploadImages count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if(indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:cButtonCell forIndexPath:indexPath];
        cell.separatorInset = UIEdgeInsetsZero;
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:18.0];
        //cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor darkTextColor];
        if([self.uploadStatus caseInsensitiveCompare:@"ADD"] == NSOrderedSame) {
            if([self.uploadImages count] == 0) cell.textLabel.textColor = [UIColor lightGrayColor];
            cell.textLabel.text = NSLocalizedString(@"btn_upload_upload", @"Upload Tab");
        } else if([self.uploadStatus caseInsensitiveCompare:@"UPLOAD"] == NSOrderedSame) {
            cell.textLabel.text = NSLocalizedString(@"btn_upload_chancel", @"Upload Tab");
        } else if([self.uploadStatus caseInsensitiveCompare:@"DONE"] == NSOrderedSame) {
            cell.textLabel.text = NSLocalizedString(@"btn_upload_clear", @"Upload Tab");
        } else {
            cell.textLabel.text = @"Error Code: 1";
        }
    } else if(indexPath.section == 2) {
        cell = [tableView dequeueReusableCellWithIdentifier:cButtonCell forIndexPath:indexPath];
        cell.separatorInset = UIEdgeInsetsZero;
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:18.0];
        cell.textLabel.text = NSLocalizedString(@"btn_image_add", @"Upload Tab");
        //cell.backgroundColor = [UIColor clearColor];
    } else if(indexPath.section == 3) {
        cell = [tableView dequeueReusableCellWithIdentifier:cImageCell forIndexPath:indexPath];
        cell.separatorInset = UIEdgeInsetsZero;
        cell.detailTextLabel.textAlignment = NSTextAlignmentRight;
        cell.textLabel.text = [[[[NetworkManager sharedManager] imageLast] objectAtIndex:indexPath.row] objectForKey:@"_filename"];
        cell.detailTextLabel.text = [self bytesToUIString:[[[[NetworkManager sharedManager] imageLast] objectAtIndex:indexPath.row] objectForKey:@"_filesize"]];
        NSString *tmpURL = [NSString stringWithFormat:@"%@/mini/%@", cURL_BASE, [[[[NetworkManager sharedManager] imageLast] objectAtIndex:indexPath.row] objectForKey:@"_filename"]];
        [cell.imageView setImageWithURL:[NSURL URLWithString:tmpURL] placeholderImage:[UIImage imageNamed:@"AppIcon"]];
        AT_ImageTableViewCell* tmpCell = (id)cell;
        tmpCell.dateTextLabel.text = [[[[NetworkManager sharedManager] imageLast] objectAtIndex:indexPath.row] objectForKey:@"_date"];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:cUploadCell forIndexPath:indexPath];
        AT_UploadTableViewCell* tmpCell = (id)cell;
        cell.separatorInset = UIEdgeInsetsZero;
        cell.detailTextLabel.text = [self bytesToUIString:[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_size"]];

        if([[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_uploaded"] intValue] < 1) {
            cell.textLabel.text = [[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_name"];
            [cell.imageView setImageWithURL:[NSURL fileURLWithPath:[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_path"]] placeholderImage:[UIImage imageNamed:@"AppIcon"]];
            cell.accessoryType = UITableViewCellAccessoryNone;
            [tmpCell.progressView setProgress:0.0];
            [tmpCell.progressView setBackgroundColor:[UIColor clearColor]];
        } else {
            cell.textLabel.text = [[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_filename"];
            NSString *tmpURL = [NSString stringWithFormat:@"%@/mini/%@", cURL_BASE, [[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_filename"]];
            [cell.imageView setImageWithURL:[NSURL URLWithString:tmpURL] placeholderImage:[UIImage imageNamed:@"AppIcon"]];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        [[self.uploadImages objectAtIndex:indexPath.row] setObject:tmpCell.progressView forKey:@"progressView"];
    }
    return cell;
}

#pragma mark - Table view delegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return ((indexPath.section == 1) && ([[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_uploaded"] intValue] >= 0))  || (indexPath.section == 3);
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    if((indexPath.section == 3) || ([[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_uploaded"] intValue] == 1)) {
        UITableViewRowAction *modifyAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:NSLocalizedString(@"btn_slide_copylink", @"Upload Tab") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath *indexPath) {
            if(indexPath.section == 3) {
                [UIPasteboard generalPasteboard].string = [[NetworkManager sharedManager] generateLinkForImage:[[[[NetworkManager sharedManager] imageLast] objectAtIndex:indexPath.row] objectForKey:@"_filename"]];
            } else {
                [UIPasteboard generalPasteboard].string = [[NetworkManager sharedManager] generateLinkForImage:[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_name"]];
            }
        }];
        modifyAction.backgroundColor = [UIColor orangeColor];
        return @[modifyAction];
    } else {
        UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:NSLocalizedString(@"btn_slide_delete", @"Upload Tab") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            [[NSFileManager defaultManager] removeItemAtPath:[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_path"]  error:nil];
            [self.uploadImages removeObjectAtIndex:indexPath.row];
            //[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:YES];
            [tableView reloadData];
        }];
        return @[deleteAction];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 && [self.uploadImages count] == 0) return nil;
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        if([self.uploadStatus caseInsensitiveCompare:@"ADD"] == NSOrderedSame) {
            [self startUploadingImages];
        } else if([self.uploadStatus caseInsensitiveCompare:@"UPLOAD"] == NSOrderedSame) {
            [[[NetworkManager sharedManager] uploadTask] cancel];
            self.uploadStatus = @"ADD";
            [self.tableView reloadData];
        } else if([self.uploadStatus caseInsensitiveCompare:@"DONE"] == NSOrderedSame) {
            self.uploadStatus = @"ADD";
            for(int i = (int)[self.uploadImages count];i > 0;i--) {
                if([[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_uploaded"] intValue] >= 1)
                    [self.uploadImages removeObjectAtIndex:(i -1)];
            }
            [self.navigationItem.rightBarButtonItem setEnabled:NO];
            [self.tableView reloadData];
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else if(indexPath.section == 2) {
        [self showImagePicker];
    } else if(indexPath.section == 3) {
        self.detailedViewController.imageList = [[NetworkManager sharedManager] imageLast];
        self.detailedViewController.imageID = indexPath.row;
        [self.navigationController pushViewController:self.detailedViewController animated:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        self.detailedViewController.imageList = self.uploadImages;
        self.detailedViewController.imageID = indexPath.row;
        [self.navigationController pushViewController:self.detailedViewController animated:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - More

- (void)showSettings {
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
    }
}

- (void)showImagePicker {
    self.uzysPicker = [[UzysAssetsPickerController alloc] init];
    self.uzysPicker.delegate = (id)self;
    self.uzysPicker.maximumNumberOfSelectionVideo = 0;
    self.uzysPicker.maximumNumberOfSelectionPhoto = 999;
    [self presentViewController:self.uzysPicker animated:YES completion:nil];
}

- (void)uzysAssetsPickerController:(UzysAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets {
    [assets enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ALAsset *asset = obj;
        ALAssetRepresentation *rep = [asset defaultRepresentation];
        Byte *buffer = (Byte*)malloc(rep.size);
        NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];
        NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
        [[NetworkManager sharedManager] saveImage:data];
    }];
    [self.tableView reloadData];
}

- (NSString *)bytesToUIString:(NSNumber *) number {
    double size = [number doubleValue];
    unsigned long i = 0;
    while (size >= 1000) {
        size /= 1024;
        i++;
    }
    NSArray *extension = [[NSArray alloc] initWithObjects:@"Byte", @"KB", @"MB", @"GB", @"TB", @"PB", @"EB", @"ZB", @"YB" ,@"???" , nil];
    
    if(i>([extension count]-2)) i = [extension count]-1;
    return [NSString stringWithFormat:@"%.1f %@", size, [extension objectAtIndex:i]];
}

- (void)startUploadingImages {
    if([self.uploadImages count] > 0) {
        if(([[NetworkManager sharedManager] token] == nil) || ([[[NetworkManager sharedManager] token] length] == 0)) {
            [[NetworkManager sharedManager] showLoginWithViewController:self andCallback:^{
                [self startUploadingImages];
            }];
        } else {
            self.uploadStatus = @"UPLOAD";
            [self.navigationItem.leftBarButtonItem setEnabled:NO];
            [UIApplication sharedApplication].idleTimerDisabled = YES;
            [NSTimer scheduledTimerWithTimeInterval:0.1 target:self.tableView selector:@selector(reloadData) userInfo:nil repeats:NO];
            [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(uploadNextImage) userInfo:nil repeats:NO];
        }
    }
}

- (void)uploadNextImage {
    unsigned long i;
    for(i = 0;i < [self.uploadImages count];i++) {
        if([[[self.uploadImages objectAtIndex:i] objectForKey:@"_uploaded"] intValue] == 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:1] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
            [self uploadImage:i];
            return;
        }
    }
    [[NetworkManager sharedManager] getGalleryList:nil failure:nil];
    self.uploadStatus = @"DONE";
    [self.navigationItem.leftBarButtonItem setEnabled:YES];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self.tableView scrollsToTop];
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self.tableView selector:@selector(reloadData) userInfo:nil repeats:NO];
    [NetworkManager showMessage:NSLocalizedString(@"msg_upload_done", @"Upload Tab")];
}

- (void)uploadImage:(unsigned long) idx {
    [[self.uploadImages objectAtIndex:idx] setObject:@"-1" forKey:@"_uploaded"];
    [[NetworkManager sharedManager] uploadImagesNow:[self.uploadImages objectAtIndex:idx] success:^(NSDictionary *responseObject) {
        if ( [[responseObject objectForKey:@"images"] objectForKey:@"image"] ) {
            [[self.uploadImages objectAtIndex:idx] setObject:@"1" forKey:@"_uploaded"];
            [[self.uploadImages objectAtIndex:idx] setObject:[[[responseObject objectForKey:@"images"] objectForKey:@"image"] objectForKey:@"_newname"] forKey:@"_filename"];
            [[NSFileManager defaultManager] removeItemAtPath:[[self.uploadImages objectAtIndex:idx] objectForKey:@"_path"]  error:nil];

            UIProgressView* tmpPV = [[self.uploadImages objectAtIndex:idx] objectForKey:@"progressView"];
            [tmpPV setProgress:0.0];
            [tmpPV setBackgroundColor:[UIColor clearColor]];
            UITableViewCell* tmpCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:1]];
            tmpCell.accessoryType = UITableViewCellAccessoryCheckmark;
            
            //[self uploadNextImage];
            [self.navigationItem.rightBarButtonItem setEnabled:YES];
            [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(uploadNextImage) userInfo:nil repeats:NO];
        }
    } failure:^(NSString *failureReason, NSInteger statusCode) {
        [[self.uploadImages objectAtIndex:idx] setObject:@"0" forKey:@"_uploaded"];

        UIProgressView* tmpPV = [[self.uploadImages objectAtIndex:idx] objectForKey:@"progressView"];
        [tmpPV setProgress:0.0];
        UITableViewCell* tmpCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:1]];
        tmpCell.accessoryType = UITableViewCellAccessoryNone;
        
        [self.navigationItem.leftBarButtonItem setEnabled:YES];
        [NetworkManager showMessage:failureReason];
    }];
}

- (void) copyLinksPasteboard {
    NSMutableString* linkX = [[NSMutableString alloc] init];
    unsigned long i;
    unsigned long k = 0;
    for(i = 0;i < [self.uploadImages count];i++) {
        if([[[self.uploadImages objectAtIndex:i] objectForKey:@"_uploaded"] intValue] == 1) {
            [linkX appendString:[[NetworkManager sharedManager] generateLinkForImage:[[self.uploadImages objectAtIndex:i] objectForKey:@"_name"]]];
            k++;
        }
    }
    if(k > 0) {
        [UIPasteboard generalPasteboard].string = linkX;
        [NetworkManager showMessage:[NSString stringWithFormat:NSLocalizedString(@"msg_copylink_done %ld", @"Upload Tab"), k]];
    }
}


@end
