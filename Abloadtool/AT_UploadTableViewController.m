//
//  AT_UploadTableViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 27.10.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#define cButtonCell @"ButtonTableViewCell"
#define cImageCell @"UploadTableViewCell"

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
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"106-sliders"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"901-clipboard"] style:UIBarButtonItemStylePlain target:self action:@selector(copyLinksPasteboard)];

    // Init TableView
    [self.tableView registerClass:[AT_UploadTableViewCell class] forCellReuseIdentifier:cImageCell];
    [self.tableView registerClass:UITableViewCell.self forCellReuseIdentifier:cButtonCell];
    //self.tableView.rowHeight = 57.0;
    
    // Link uploadImages
    self.uploadImages = [[NetworkManager sharedManager] uploadImages];
    
    // Init uploadStatus
    self.uploadStatus = @"ADD";
    
    // Init detailed View
    self.detailedViewController = [[AT_DetailedViewController alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if([self.uploadStatus caseInsensitiveCompare:@"ADD"] == NSOrderedSame)
        return 3;
    else
        return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0 || section == 2) {
        return 1;
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
        if([self.uploadStatus caseInsensitiveCompare:@"ADD"] == NSOrderedSame) {
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
        cell.textLabel.text = NSLocalizedString(@"btn_image_add", @"Upload Tab");
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:cImageCell forIndexPath:indexPath];
        AT_UploadTableViewCell* tmpCell = (id)cell;
        cell.separatorInset = UIEdgeInsetsZero;
        cell.textLabel.text = [[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_name"];
        cell.detailTextLabel.text = [self bytesToUIString:[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_size"]];

        if([[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_uploaded"] intValue] < 1) {
            [cell.imageView setImageWithURL:[NSURL fileURLWithPath:[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_path"]] placeholderImage:[UIImage imageNamed:@"AppIcon"]];
            cell.accessoryType = UITableViewCellAccessoryNone;
            [tmpCell.progressView setProgress:0.0];
            [tmpCell.progressView setBackgroundColor:[UIColor clearColor]];
        } else {
            NSString *tmpURL = [NSString stringWithFormat:@"%@/mini/%@", cURL_BASE, [[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_name"]];
            [cell.imageView setImageWithURL:[NSURL URLWithString:tmpURL] placeholderImage:[UIImage imageNamed:@"AppIcon"]];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        [[self.uploadImages objectAtIndex:indexPath.row] setObject:tmpCell.progressView forKey:@"progressView"];
    }
    return cell;
}

#pragma mark - Table view delegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return ((indexPath.section == 1) && ([[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_uploaded"] intValue] >= 0));
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    if([[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_uploaded"] intValue] == 1) {
        UITableViewRowAction *modifyAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:NSLocalizedString(@"btn_slide_copylink", @"Upload Tab") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath *indexPath) {
            [UIPasteboard generalPasteboard].string = [[NetworkManager sharedManager] generateLink:[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_name"]];
        }];
        modifyAction.backgroundColor = [UIColor orangeColor];
        return @[modifyAction];
    } else {
        UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:NSLocalizedString(@"btn_slide_delete", @"Upload Tab") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            [[NSFileManager defaultManager] removeItemAtPath:[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_path"]  error:nil];
            [self.uploadImages removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:YES];
        }];
        return @[deleteAction];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [[NSFileManager defaultManager] removeItemAtPath:[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_path"]  error:nil];
        [self.uploadImages removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:YES];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
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
            [self.tableView reloadData];
        }
    } else if(indexPath.section == 2) {
        [self showImagePicker];
    } else {
        if([[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_uploaded"] intValue] < 1) {
            self.detailedViewController.imageURL = [NSURL fileURLWithPath:[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_path"]];
        } else {
            self.detailedViewController.imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/img/%@", cURL_BASE, [[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_name"]]];
        }
        [self.navigationController pushViewController:self.detailedViewController animated:YES];
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
    NSArray *extension = [[NSArray alloc] initWithObjects:@"Byte", @"KiB", @"MiB", @"GiB", @"TiB", @"PiB", @"EiB", @"ZiB", @"YiB" ,@"???" , nil];
    
    if(i>([extension count]-2)) i = [extension count]-1;
    return [NSString stringWithFormat:@"%.1f %@", size, [extension objectAtIndex:i]];
}

- (void)startUploadingImages {
    if([self.uploadImages count] > 0) {
        [self.navigationItem.leftBarButtonItem setEnabled:NO];
        self.uploadStatus = @"UPLOAD";
        [NSTimer scheduledTimerWithTimeInterval:0.1 target:self.tableView selector:@selector(reloadData) userInfo:nil repeats:NO];
        [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(uploadNextImage) userInfo:nil repeats:NO];
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
    self.uploadStatus = @"DONE";
    [self.tableView scrollsToTop];
    [self.navigationItem.leftBarButtonItem setEnabled:YES];
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self.tableView selector:@selector(reloadData) userInfo:nil repeats:NO];
    [NetworkManager showMessage:@"Done!"];
}

- (void)uploadImage:(unsigned long) idx {
    [[self.uploadImages objectAtIndex:idx] setObject:@"-1" forKey:@"_uploaded"];
    [[NetworkManager sharedManager] uploadImagesNow:[self.uploadImages objectAtIndex:idx] success:^(NSDictionary *responseObject) {
        if ( [[responseObject objectForKey:@"images"] objectForKey:@"image"] ) {
            [[self.uploadImages objectAtIndex:idx] setObject:@"1" forKey:@"_uploaded"];
            [[self.uploadImages objectAtIndex:idx] setObject:[[[responseObject objectForKey:@"images"] objectForKey:@"image"] objectForKey:@"_newname"] forKey:@"_name"];
            [[NSFileManager defaultManager] removeItemAtPath:[[self.uploadImages objectAtIndex:idx] objectForKey:@"_path"]  error:nil];

            UIProgressView* tmpPV = [[self.uploadImages objectAtIndex:idx] objectForKey:@"progressView"];
            [tmpPV setProgress:0.0];
            [tmpPV setBackgroundColor:[UIColor clearColor]];
            UITableViewCell* tmpCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:1]];
            tmpCell.accessoryType = UITableViewCellAccessoryCheckmark;
            
            //[self uploadNextImage];
            [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(uploadNextImage) userInfo:nil repeats:NO];
        }
    } failure:^(NSString *failureReason, NSInteger statusCode) {
        [[self.uploadImages objectAtIndex:idx] setObject:@"0" forKey:@"_uploaded"];

        UIProgressView* tmpPV = [[self.uploadImages objectAtIndex:idx] objectForKey:@"progressView"];
        [tmpPV setProgress:0.0];
        UITableViewCell* tmpCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:1]];
        tmpCell.accessoryType = UITableViewCellAccessoryNone;
        
        [self.navigationItem.leftBarButtonItem setEnabled:YES];
        [self.navigationItem.rightBarButtonItem setEnabled:YES];

        [NetworkManager showMessage:failureReason];
    }];
}

- (void) copyLinksPasteboard {
    NSMutableString* linkX = [[NSMutableString alloc] init];
    unsigned long i;
    unsigned long k = 0;
    for(i = 0;i < [self.uploadImages count];i++) {
        if([[[self.uploadImages objectAtIndex:i] objectForKey:@"_uploaded"] intValue] == 1) {
            [linkX appendString:[[NetworkManager sharedManager] generateLink:[[self.uploadImages objectAtIndex:i] objectForKey:@"_name"]]];
            k++;
        }
    }
    if(k > 0) {
        [UIPasteboard generalPasteboard].string = linkX;
        [NetworkManager showMessage:[NSString stringWithFormat:NSLocalizedString(@"msg_copylink_done %ld", @"Upload Tab"), k]];
    }
}


@end
