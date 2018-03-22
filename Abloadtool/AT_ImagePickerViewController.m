//
//  AT_ImagePickerViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 19.03.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#import "AT_ImagePickerViewController.h"

@interface AT_ImagePickerViewController ()
@property MBProgressHUD *progressHUD;
@property BOOL firstLoad;
@property PHFetchOptions *fetchOptions;
@property UICollectionViewController* collectionViewController;

@end

@implementation AT_ImagePickerViewController

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithCollectionViewLayout:layout];
    self.selectedImages = [[NSMutableIndexSet alloc] init];
    self.firstLoad = YES;
    
    self.fetchOptions = [[PHFetchOptions alloc] init];
    self.fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    
    [self.collectionView registerClass:[AT_ImagePickerCollectionViewCell class] forCellWithReuseIdentifier:@"cCollectionViewCellImage"];
    self.collectionView.alwaysBounceVertical = YES;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Abbruch" style:UIBarButtonItemStylePlain target:self action:@selector(cancleView)];
    return self;
}

- (void)cancleView {
    [self.selectedImages removeAllIndexes];
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setItemSize:self.view.bounds.size];
    [self.collectionView reloadData];
    self.navigationItem.title = [[self.albumArr objectAtIndex:self.selectedAlbum] objectForKey:@"localizedTitle"];
    [self.navigationController setToolbarHidden:NO animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self setItemSize:size];
    [self.collectionView reloadData];
}

- (void)setItemSize:(CGSize)newSize {
    UICollectionViewFlowLayout *flowLayout = (id)self.collectionViewLayout;
    CGFloat itemMargin = 3.0f;
    flowLayout.sectionInset = UIEdgeInsetsMake(itemMargin, itemMargin, itemMargin, itemMargin);
    flowLayout.minimumInteritemSpacing = itemMargin;
    flowLayout.minimumLineSpacing = itemMargin;
    CGFloat i = ceil(newSize.width / 120.0);
    if(i < 3) i = 3; if(i > 6) i = 6;
    CGFloat itemSize = (newSize.width - (i + 1) * itemMargin) / i;
    flowLayout.itemSize = CGSizeMake(itemSize, itemSize);
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSLog(@"selectedImages: %@", self.selectedImages);
    return [[[self.albumArr objectAtIndex:self.selectedAlbum] objectForKey:@"fetchResult"] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AT_ImagePickerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cCollectionViewCellImage" forIndexPath:indexPath];
    
    if([self.selectedImages containsIndex:indexPath.row]) {
        cell.isSelected = YES;
    } else {
        cell.isSelected = NO;
    }
    
    PHFetchResult* fetchResult = [[self.albumArr objectAtIndex:self.selectedAlbum] objectForKey:@"fetchResult"];
    PHAsset* asset = [fetchResult objectAtIndex:indexPath.row];
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:[(UICollectionViewFlowLayout*)self.collectionViewLayout itemSize] contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (result) {
            cell.imageView.image = result;
        }
    }];
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    AT_ImagePickerCollectionViewCell *cell = (AT_ImagePickerCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if([self.selectedImages containsIndex:indexPath.row]) {
        [self.selectedImages removeIndex:indexPath.row];
        cell.isSelected = NO;
    } else {
        [self.selectedImages addIndex:indexPath.row];
        cell.isSelected = YES;
    }
}

#pragma mark - Other

- (void)prepareDisplay {
    [self showProgressHUD];
    if(self.firstLoad) {
        [self getAllAlbums];
        self.selectedAlbum = 0;
        self.firstLoad = NO;
    } else {
        [self getImages];
    }
    [self hideProgressHUD];
}

- (void)showProgressHUD {
    [self hideProgressHUD];
    self.progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
    [self.progressHUD removeFromSuperViewOnHide];
    self.progressHUD.label.text = @"Loading ...";
    self.progressHUD.bezelView.color = [UIColor colorWithWhite:0.1 alpha:1.0];
    self.progressHUD.contentColor = [UIColor whiteColor];
}

- (void)hideProgressHUD {
    if (self.progressHUD != nil) {
        [self.progressHUD hideAnimated:YES];
        [self.progressHUD removeFromSuperview];
        self.progressHUD = nil;
    }
}

- (void)getAllAlbums {
    self.albumArr = [NSMutableArray array];

    PHFetchResult *myPhotoStreamAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream options:nil];
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    PHFetchResult *syncedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
    PHFetchResult *sharedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumCloudShared options:nil];
    NSArray *allAlbums = @[myPhotoStreamAlbum,smartAlbums,topLevelUserCollections,syncedAlbums,sharedAlbums];
    
    for (PHFetchResult *fetchResult in allAlbums) {
        for (PHAssetCollection *collection in fetchResult) {
            if (![collection isKindOfClass:[PHAssetCollection class]]) continue;
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:self.fetchOptions];
            if (fetchResult.count < 1) continue;
            
            NSMutableDictionary* albumObj = [[NSMutableDictionary alloc] init];
            [albumObj setObject:collection forKey:@"collection"];
            [albumObj setObject:collection.localizedTitle forKey:@"localizedTitle"];
            [albumObj setObject:fetchResult forKey:@"fetchResult"];

            if(collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary) {
                [albumObj setObject:@"1" forKey:@"isCameraRoll"];
                [self.albumArr insertObject:albumObj atIndex:0];
            } else {
                [albumObj setObject:@"0" forKey:@"isCameraRoll"];
                [self.albumArr addObject:albumObj];
            }
        }
    }
}

- (void)getImages {
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:[[self.albumArr objectAtIndex:self.selectedAlbum] objectForKey:@"collection"] options:self.fetchOptions];
    [[self.albumArr objectAtIndex:self.selectedAlbum] setObject:fetchResult forKey:@"fetchResult"];
}



@end
