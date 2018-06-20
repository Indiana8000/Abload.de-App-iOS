//
//  AT_AlbumTableViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 22.03.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#define cImageCell @"ImageTableViewCell"

#import "AT_AlbumTableViewController.h"

@interface AT_AlbumTableViewController ()

@end

@implementation AT_AlbumTableViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if(self) {
        self.title = NSLocalizedString(@"nav_title_album", @"Navigation");
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"label_cancel", @"ImagePicker") style:UIBarButtonItemStylePlain target:self action:@selector(cancleView)];
        [self.tableView registerClass:[AT_ImageTableViewCell class] forCellReuseIdentifier:cImageCell];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)cancleView {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:(id)self.imagePickerViewController];
    [self.imagePickerViewController.selectedImages removeAllIndexes];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.imagePickerViewController.albumArr count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AT_ImageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cImageCell forIndexPath:indexPath];
    cell.separatorInset = UIEdgeInsetsZero;
    cell.canbeSelected = NO;
    
    cell.textLabel.text = [[self.imagePickerViewController.albumArr objectAtIndex:indexPath.row] objectForKey:@"localizedTitle"];
    cell.detailTextLabel.text = @" ";
    cell.dateTextLabel.text = @" ";
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = [UIImage imageNamed:@"AppIcon"];

    PHFetchResult* fetchResult = [[self.imagePickerViewController.albumArr objectAtIndex:indexPath.row] objectForKey:@"fetchResult"];
    PHAsset* asset = [fetchResult lastObject];
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(50, 50) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (result) {
            cell.imageView.image = result;
        }
    }];
    
    return cell;
}

- (NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(self.imagePickerViewController.selectedAlbum != indexPath.row) {
        [self.imagePickerViewController.selectedImages removeAllIndexes];
        self.imagePickerViewController.firstView = YES;
    }
    self.imagePickerViewController.selectedAlbum = indexPath.row;
    [self.navigationController pushViewController:self.imagePickerViewController animated:YES];
}



@end
