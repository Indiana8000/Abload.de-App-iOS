//
//  AT_UploadTableViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 27.10.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#define cButtonCell @"ButtonTableViewCell"
#define cUploadCell @"UploadTableViewCell"
#define cImageCell  @"ImageTableViewCell"

#import "AT_UploadTableViewController.h"

@interface AT_UploadTableViewController ()
    @property (nonatomic, strong) NSString* uploadStatus;
    @property (nonatomic, strong) NSMutableArray* uploadImages;
    @property (nonatomic, strong) UIBarButtonItem* btnUpload;
    @property (nonatomic, strong) UIBarButtonItem* btnAdd;
@end

@implementation AT_UploadTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"nav_title_upload", @"Navigation");
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"20-gear-cloud"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettingsUpload)];

    UIBarButtonItem* btnCopy = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"901-clipboard"] style:UIBarButtonItemStylePlain target:self action:@selector(copyLinksPasteboard)];
    UIBarButtonItem* btnSettingsLinkType = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"20-gear-clip"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettingsLinkType)];
    self.navigationItem.rightBarButtonItems = @[btnCopy,btnSettingsLinkType];
    [self.navigationItem.rightBarButtonItems[0] setEnabled:NO];

    [self.tableView registerClass:[AT_UploadTableViewCell class] forCellReuseIdentifier:cUploadCell];
    [self.tableView registerClass:[AT_ImageTableViewCell class] forCellReuseIdentifier:cImageCell];
    [self.tableView registerClass:UITableViewCell.self forCellReuseIdentifier:cButtonCell];
    
    self.btnUpload = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"btn_upload_upload", @"Upload Tab") style:UIBarButtonItemStylePlain target:self action:@selector(startUpload)];
    self.btnAdd = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"btn_image_add", @"Upload Tab") style:UIBarButtonItemStylePlain target:self action:@selector(showImagePicker)];
    UIBarButtonItem* btnSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self setToolbarItems:@[btnSpace, self.btnUpload, btnSpace, self.btnAdd, btnSpace]];

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTable) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:NO];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES animated:NO];
}

- (void)reloadTable {
    [[NetworkManager sharedManager] checkAndLoadSharedImages];
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
    if([self.uploadStatus caseInsensitiveCompare:@"ADD"] == NSOrderedSame) {
        return 2;
    } else {
        return 1;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return NSLocalizedString(@"title_images_waiting_for_upload", @"Upload Tab");
            break;
        case 1:
            return NSLocalizedString(@"title_last5", @"Upload Tab");
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
        AT_UploadTableViewCell* tmpCell = (id)cell;
        cell.separatorInset = UIEdgeInsetsZero;
        cell.detailTextLabel.textAlignment = NSTextAlignmentRight;
        cell.detailTextLabel.text = [self bytesToUIString:[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_filesize"]];
        cell.textLabel.text = [[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_filename"];

        if([[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_uploaded"] intValue] < 1) {
            [cell.imageView setImageWithURL:[NSURL fileURLWithPath:[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_thumb"]] placeholderImage:[UIImage imageNamed:@"AppIcon"]];
            cell.accessoryType = UITableViewCellAccessoryNone;
            [tmpCell.progressView setProgress:0.0];
            [tmpCell.progressView setBackgroundColor:[UIColor clearColor]];
        } else {
            NSString *tmpURL = [NSString stringWithFormat:@"%@/mini/%@", cURL_BASE, [[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_filename"]];
            [cell.imageView setImageWithURL:[NSURL URLWithString:tmpURL] placeholderImage:[UIImage imageNamed:@"AppIcon"]];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        [[self.uploadImages objectAtIndex:indexPath.row] setObject:tmpCell.progressView forKey:@"progressView"];
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
        self.detailedViewController.imageList = self.uploadImages;
        self.detailedViewController.imageID = indexPath.row;
        [self.navigationController pushViewController:self.detailedViewController animated:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    }
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
        presentationController.barButtonItem = self.navigationItem.rightBarButtonItems[1];
    }
}

- (void)copyLinksPasteboard {
    NSMutableString* linkX = [[NSMutableString alloc] init];
    unsigned long i;
    unsigned long k = 0;
    for(i = 0;i < [self.uploadImages count];i++) {
        if([[[self.uploadImages objectAtIndex:i] objectForKey:@"_uploaded"] intValue] == 1) {
            [linkX appendString:[[NetworkManager sharedManager] generateLinkForImage:[[self.uploadImages objectAtIndex:i] objectForKey:@"_filename"]]];
            [linkX appendString:@"\n"];
            k++;
        }
    }
    if(k > 0) {
        [UIPasteboard generalPasteboard].string = linkX;
        [NetworkManager showMessage:[NSString stringWithFormat:NSLocalizedString(@"msg_copylink_done %ld", @"Upload Tab"), k]];
    }
}


#pragma mark - Add Image

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
        [[NetworkManager sharedManager] saveImageToDisk:data];
    }];
    [self.tableView reloadData];
}


#pragma mark - Upload

- (void)startUpload {
    if([self.uploadStatus caseInsensitiveCompare:@"ADD"] == NSOrderedSame) {
        [self startUploadingImages];
    } else if([self.uploadStatus caseInsensitiveCompare:@"UPLOAD"] == NSOrderedSame) {
        [[[NetworkManager sharedManager] uploadTask] cancel];
        self.uploadStatus = @"ADD";
        self.btnUpload.title = NSLocalizedString(@"btn_upload_upload", @"Upload Tab");
        self.btnAdd.enabled = YES;
        [self.tableView reloadData];
    } else if([self.uploadStatus caseInsensitiveCompare:@"DONE"] == NSOrderedSame) {
        self.uploadStatus = @"ADD";
        self.btnUpload.title = NSLocalizedString(@"btn_upload_upload", @"Upload Tab");
        for(int i = (int)[self.uploadImages count];i > 0;i--) {
            if([[[self.uploadImages objectAtIndex:(i -1)] objectForKey:@"_uploaded"] intValue] >= 1)
                [self.uploadImages removeObjectAtIndex:(i -1)];
        }
        self.btnAdd.enabled = YES;
        [self.navigationItem.rightBarButtonItems[0] setEnabled:NO];
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
            self.btnUpload.title = NSLocalizedString(@"btn_upload_chancel", @"Upload Tab");
            self.btnAdd.enabled = NO;
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
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
            [self uploadImage:i];
            return;
        }
    }
    [[NetworkManager sharedManager] getGalleryList:nil failure:nil];
    self.uploadStatus = @"DONE";
    self.btnUpload.title = NSLocalizedString(@"btn_upload_clear", @"Upload Tab");
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
            [[NetworkManager sharedManager] removeImageFromDisk:idx andList:NO];
            
            UIProgressView* tmpPV = [[self.uploadImages objectAtIndex:idx] objectForKey:@"progressView"];
            [tmpPV setProgress:0.0];
            [tmpPV setBackgroundColor:[UIColor clearColor]];
            UITableViewCell* tmpCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:1]];
            tmpCell.accessoryType = UITableViewCellAccessoryCheckmark;
            
            //[self uploadNextImage];
            [self.navigationItem.rightBarButtonItems[0] setEnabled:YES];
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


@end
