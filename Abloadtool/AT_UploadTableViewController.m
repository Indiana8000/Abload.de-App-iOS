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
@property (nonatomic, strong) NSMutableArray* uploadImages;
@end

@implementation AT_UploadTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Init Navigation Controller + Buttons
    self.navigationItem.title = NSLocalizedString(@"Upload", @"Navigation Title");
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"106-sliders"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"56-cloud"] style:UIBarButtonItemStylePlain target:self action:@selector(startUploadingImages)];

    // Init TableView
    [self.tableView registerClass:[AT_UploadTableViewCell class] forCellReuseIdentifier:cImageCell];
    [self.tableView registerClass:UITableViewCell.self forCellReuseIdentifier:cButtonCell];
    //self.tableView.rowHeight = 57.0;
    
    // Link uploadImages
    self.uploadImages = [[NetworkManager sharedManager] uploadImages];
    
    // Init detailed View
    self.detailedViewController = [[AT_DetailedViewController alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0) {
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
        cell.textLabel.text = NSLocalizedString(@"Add Pictures", @"Upload");
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:cImageCell forIndexPath:indexPath];
        cell.separatorInset = UIEdgeInsetsZero;
        cell.textLabel.text = [[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_name"];
        cell.detailTextLabel.text = [self bytesToUIString:[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_size"]];

        if([[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_uploaded"] intValue] == 0) {
            [cell.imageView setImageWithURL:[NSURL fileURLWithPath:[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_path"]] placeholderImage:[UIImage imageNamed:@"AppIcon"]];
        } else {
            NSString *tmpURL = [NSString stringWithFormat:@"%@/mini/%@", cURL_BASE, [[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_name"]];
            [cell.imageView setImageWithURL:[NSURL URLWithString:tmpURL] placeholderImage:[UIImage imageNamed:@"AppIcon"]];
        }
        AT_UploadTableViewCell* tmpCell = (id)cell;
        [[self.uploadImages objectAtIndex:indexPath.row] setObject:tmpCell.progressView forKey:@"progressView"];
        [tmpCell.progressView setProgress:0.0];
    }
    return cell;
}

#pragma mark - Table view delegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section == 1);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete Image
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
        [self showImagePicker];
    } else {
        if([[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_uploaded"] intValue] == 0) {
            self.detailedViewController.imageURL = [NSURL fileURLWithPath:[[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_path"]];
        } else {
            self.detailedViewController.imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/img/%@", cURL_BASE, [[self.uploadImages objectAtIndex:indexPath.row] objectForKey:@"_name"]]];
        }
        [self.navigationController pushViewController:self.detailedViewController animated:YES];
    }
}

#pragma mark - More

- (void)showSettings {
    if ( self.pageSetting == nil) {
        self.pageSetting = [[AT_SettingTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        self.navSetting = [[UINavigationController alloc] initWithRootViewController:self.pageSetting];
        self.navSetting.modalPresentationStyle = UIModalPresentationPopover;
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController pushViewController:self.pageSetting animated:YES];
    } else {
        [self.navigationController presentViewController:self.navSetting animated:YES completion:nil];
        UIPopoverPresentationController *presentationController =[self.navSetting popoverPresentationController];
        presentationController.barButtonItem = self.navigationItem.leftBarButtonItem;
    }
}

- (void)showImagePicker {
    NSLog(@"UPLOAD - showImagePicker");
    self.uzysPicker = [[UzysAssetsPickerController alloc] init];
    self.uzysPicker.delegate = (id)self;
    self.uzysPicker.maximumNumberOfSelectionVideo = 0;
    self.uzysPicker.maximumNumberOfSelectionPhoto = 999;
    [self presentViewController:self.uzysPicker animated:YES completion:nil];
}

- (void)uzysAssetsPickerController:(UzysAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets {
    NSLog(@"UPLOAD - didFinishPickingAssets");
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
    [self uploadNextImage];
}

- (void)uploadNextImage {
    unsigned long i;
    for(i = 0;i < [self.uploadImages count];i++) {
        NSLog(@"Checking: %ld", i);
        if([[[self.uploadImages objectAtIndex:i] objectForKey:@"_uploaded"] intValue] == 0) {
            [self uploadImage:i];
            return;
        }
    }
    [NetworkManager showMessage:@"Done!"];
}

- (void)uploadImage:(unsigned long) idx {
    [[NetworkManager sharedManager] uploadImagesNow:[self.uploadImages objectAtIndex:idx] success:^(NSDictionary *responseObject) {
        if ( [[responseObject objectForKey:@"images"] objectForKey:@"image"] ) {
            NSLog(@"Upload Success: %@", [[[responseObject objectForKey:@"images"] objectForKey:@"image"] objectForKey:@"_newname"]);
            [[self.uploadImages objectAtIndex:idx] setObject:@"1" forKey:@"_uploaded"];
            [[self.uploadImages objectAtIndex:idx] setObject:[[[responseObject objectForKey:@"images"] objectForKey:@"image"] objectForKey:@"_newname"] forKey:@"_name"];
            [[NSFileManager defaultManager] removeItemAtPath:[[self.uploadImages objectAtIndex:idx] objectForKey:@"_path"]  error:nil];
            [self uploadNextImage];
        }
    } failure:^(NSString *failureReason, NSInteger statusCode) {
        [NetworkManager showMessage:failureReason];
    }];
}



@end
