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
    @property (nonatomic, strong) UIBarButtonItem* btnUpload;
    @property (nonatomic, strong) UIBarButtonItem* btnAdd;
@end

@implementation AT_UploadTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Init Navigation Controller + Buttons
    self.navigationItem.title = NSLocalizedString(@"nav_title_upload", @"Navigation");
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"20-gear-cloud"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];

    UIBarButtonItem* btnCopy = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"901-clipboard"] style:UIBarButtonItemStylePlain target:self action:@selector(copyLinksPasteboard)];
    UIBarButtonItem* btnSettingsLinkType = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"20-gear-clip"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettingsLinkType)];
    self.navigationItem.rightBarButtonItems = @[btnCopy,btnSettingsLinkType];
    [self.navigationItem.rightBarButtonItems[0] setEnabled:NO];

    // Init TableView
    [self.tableView registerClass:[AT_UploadTableViewCell class] forCellReuseIdentifier:cUploadCell];
    [self.tableView registerClass:[AT_ImageTableViewCell class] forCellReuseIdentifier:cImageCell];
    [self.tableView registerClass:UITableViewCell.self forCellReuseIdentifier:cButtonCell];
    //[self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    //self.tableView.rowHeight = 57.0;
    
    self.btnUpload = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"btn_upload_upload", @"Upload Tab") style:UIBarButtonItemStylePlain target:self action:@selector(startUpload)];
    self.btnAdd = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"btn_image_add", @"Upload Tab") style:UIBarButtonItemStylePlain target:self action:@selector(showImagePicker)];
    UIBarButtonItem* btnSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self setToolbarItems:@[btnSpace, self.btnUpload, btnSpace, self.btnAdd, btnSpace]];

    // Link uploadImages
    self.uploadImages = [[NetworkManager sharedManager] uploadImages];
    
    // Init uploadStatus
    self.uploadStatus = @"ADD";
    
    // Init detailed View
    self.detailedViewController = [[AT_DetailedViewController alloc] init];
    
    if([[NetworkManager sharedManager] token] == nil) {
        [[NetworkManager sharedManager] showLoginWithViewController:self andCallback:^{
            [[NetworkManager sharedManager] getGalleryList:^(NSDictionary *responseObject) {
                [self.tableView reloadData];
            } failure:nil];
        }];
    } else {
        [[NetworkManager sharedManager] tokenCheckWithSuccess:^(NSDictionary *responseObject) {
            [self.tableView reloadData];
        }  failure:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setToolbarHidden:NO animated:NO];
    [[NetworkManager sharedManager] getSharedImages];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setToolbarHidden:YES animated:NO];
}

#pragma mark - Table view data source

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
            return nil;
            break;
        case 1:
            return NSLocalizedString(@"title_last5", @"Upload Tab");;
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
            [cell.imageView setImageWithURL:[NSURL fileURLWithPath:[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_path"]] placeholderImage:[UIImage imageNamed:@"AppIcon"]];
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

#pragma mark - Table view delegate

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
            [[NSFileManager defaultManager] removeItemAtPath:[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_path"]  error:nil];
            [self.uploadImages removeObjectAtIndex:indexPath.row];
            //[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:YES];
            [tableView reloadData];
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
            [[NSFileManager defaultManager] removeItemAtPath:[[self.uploadImages objectAtIndex:idx] objectForKey:@"_path"]  error:nil];

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

- (void) copyLinksPasteboard {
    NSMutableString* linkX = [[NSMutableString alloc] init];
    unsigned long i;
    unsigned long k = 0;
    for(i = 0;i < [self.uploadImages count];i++) {
        if([[[self.uploadImages objectAtIndex:i] objectForKey:@"_uploaded"] intValue] == 1) {
            [linkX appendString:[[NetworkManager sharedManager] generateLinkForImage:[[self.uploadImages objectAtIndex:i] objectForKey:@"_name"]]];
            [linkX appendString:@"\n"];
            k++;
        }
    }
    if(k > 0) {
        [UIPasteboard generalPasteboard].string = linkX;
        [NetworkManager showMessage:[NSString stringWithFormat:NSLocalizedString(@"msg_copylink_done %ld", @"Upload Tab"), k]];
    }
}

- (void) startUpload {
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

- (void)showSpenden {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:@"Gefällt dir unser Service? Bitte informiere dich auf unserer Homepage wie du uns unterstützen kannst."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    

    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Danke" style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
                                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                                   }];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
