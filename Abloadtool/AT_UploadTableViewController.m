//
//  AT_UploadTableViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 27.10.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#define cButtonCell @"ButtonTableViewCell"
#define cImageCell @"ImageTableViewCell"

#import "AT_UploadTableViewController.h"

@interface AT_UploadTableViewController ()

@end

@implementation AT_UploadTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Upload", @"Navigation Title");
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"106-sliders"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettings:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"56-cloud"] style:UIBarButtonItemStylePlain target:self action:@selector(startUploadingImages:)];
    
    [self.tableView registerClass:[AT_ImageTableViewCell class] forCellReuseIdentifier:cImageCell];
    [self.tableView registerClass:UITableViewCell.self forCellReuseIdentifier:cButtonCell];
    //self.tableView.rowHeight = 57.0;
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
        return [[[NetworkManager sharedManager] uploadImages] count];
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if(indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:cButtonCell forIndexPath:indexPath];
        cell.textLabel.text = NSLocalizedString(@"Add Pictures", @"Upload");
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:cImageCell forIndexPath:indexPath];
        cell.textLabel.text = @"Picture #?";
        cell.detailTextLabel.text = @"Picture #?";
        [cell.imageView setImageWithURL:[NSURL fileURLWithPath:[[[NetworkManager sharedManager] uploadImages] objectAtIndex:indexPath.row]] placeholderImage:[UIImage imageNamed:@"AppIcon"]];
    }
    return cell;
}

#pragma mark - Table view delegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 1;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {

    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        [self showImagePicker];
    } else {
        // Picture tapped
    }
}

#pragma mark - More

- (void)showSettings:(id) sender {
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

- (void)startUploadingImages:(id) sender {
    [[NetworkManager sharedManager] uploadImagesNow:^(NSDictionary *responseObject) {
        [NetworkManager showMessage:@"Done"];
    } failure:^(NSString *failureReason, NSInteger statusCode) {
        [NetworkManager showMessage:failureReason];
    }];
}









@end
