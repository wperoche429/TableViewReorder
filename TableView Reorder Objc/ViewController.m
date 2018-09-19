//
//  ViewController.m
//  TableView Reorder Objc
//
//  Created by William Peroche on 20/09/18.
//  Copyright © 2018 William Peroche. All rights reserved.
//

#import "ViewController.h"
#import "AccountCell.h"

#define kAnimationDuration 0.25
#define kVisibleAlpha 1.0F
#define kInvisibleAlpha 0.0F
#define kTranslucentAlpha 0.98F
#define kShadowRadius 5.0F
#define kShadowOpacity 0.5F
#define kContextScale 0.0F

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSMutableArray *itemsArray;
@property (strong, nonatomic) UIView *movingCellSnapshotView;
@property (assign, nonatomic) BOOL movingCellIsAnimating;
@property (assign, nonatomic) BOOL movingCellNeedsToShow;
@property (strong, nonatomic) NSIndexPath *movingCellInitialIndexPath;
@property (strong, nonatomic) IBOutlet UITableView *tableView;


@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    self.itemsArray = [[NSMutableArray alloc] initWithObjects:@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"10", nil];
    [self setupTableView];
    [self setupGesture];
}


- (void)setupTableView
{
    UINib *nib = [UINib nibWithNibName:kAccountCellIdentifier bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:kAccountCellIdentifier];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 50.0F;
}

- (void)setupGesture
{
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognized:)];
    [self.tableView addGestureRecognizer:longPress];
}


- (void)longPressGestureRecognized:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint locationInView = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:locationInView];
    
    if (indexPath == nil)
    {
        [self finalizeReorderOfCell];
        return;
    }
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            [self createSnapshotOfMovingCellWithIndexPath:indexPath locationInView:locationInView];
            break;

        case UIGestureRecognizerStateChanged:
            [self updateModelWithMovingCellWithIndexPath:indexPath locationInView:locationInView];
            break;

        default:
            [self finalizeReorderOfCell];
            break;
    }
    
}


- (UIView *)snapshotOfCell:(UITableViewCell *)inputView
{
    UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, NO, kContextScale);
    [inputView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIView *snapshotView = [[UIImageView alloc] initWithImage:image];
    [snapshotView.layer setMasksToBounds:NO];
    [snapshotView.layer setShadowOffset:CGSizeMake(-5.0F, 0.0F)];
    [snapshotView.layer setShadowRadius:kShadowRadius];
    [snapshotView.layer setShadowOpacity:kShadowOpacity];
    return snapshotView;
}

- (void)createSnapshotOfMovingCellWithIndexPath:(NSIndexPath *)indexPath locationInView:(CGPoint)locationInView
{
    self.movingCellInitialIndexPath = indexPath;
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (cell == nil)
    {
        return;
    }
    
    UIView *snapshotView = [self snapshotOfCell:cell];
    self.movingCellSnapshotView = snapshotView;
    CGPoint center = cell.center;
    snapshotView.center = center;
    snapshotView.alpha = kInvisibleAlpha;
    [self.tableView addSubview:snapshotView];
    
    __weak typeof(self) weakSelf = self;
    
    [UIView animateWithDuration:kAnimationDuration animations:^{
        weakSelf.movingCellIsAnimating = YES;
        snapshotView.center = center;
        snapshotView.alpha = kVisibleAlpha;
        cell.alpha = kInvisibleAlpha;
    } completion:^(BOOL finished) {
        if (finished)
        {
            weakSelf.movingCellIsAnimating = NO;
            if (weakSelf.movingCellNeedsToShow)
            {
                weakSelf.movingCellNeedsToShow = NO;
                [UIView animateWithDuration:kAnimationDuration animations:^{
                    cell.alpha = kVisibleAlpha;
                }];
            }
            else
            {
                cell.hidden = YES;
            }
        }
    }];
    
}

- (void)updateModelWithMovingCellWithIndexPath:(NSIndexPath *)indexPath locationInView:(CGPoint)locationInView
{
    if ((self.movingCellSnapshotView == nil) || (self.movingCellInitialIndexPath == nil))
    {
        return;
    }
    
    CGPoint center = self.movingCellSnapshotView.center;
    center.y = locationInView.y;
    self.movingCellSnapshotView.center = center;
    
    if (indexPath != self.movingCellInitialIndexPath)
    {
        NSString *obj = self.itemsArray[self.movingCellInitialIndexPath.section];
        [self.itemsArray removeObjectAtIndex:self.movingCellInitialIndexPath.section];
        [self.itemsArray insertObject:obj atIndex:indexPath.section];
        [self.tableView moveSection:self.movingCellInitialIndexPath.section toSection:indexPath.section];
        self.movingCellInitialIndexPath = indexPath;
    }
}

- (void)finalizeReorderOfCell
{
    if ((self.movingCellInitialIndexPath == nil) || [self.tableView cellForRowAtIndexPath:self.movingCellInitialIndexPath] == nil || (self.movingCellSnapshotView == nil))
    {
        return;
    }
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.movingCellInitialIndexPath];
    
    if (self.movingCellIsAnimating)
    {
        self.movingCellNeedsToShow = YES;
    }
    else
    {
        cell.hidden = NO;
        cell.alpha = kInvisibleAlpha;
    }
    
    __weak typeof(self) weakSelf = self;
    
    [UIView animateWithDuration:kAnimationDuration animations:^{
        weakSelf.movingCellSnapshotView.center = cell.center;
        weakSelf.movingCellSnapshotView.transform = CGAffineTransformIdentity;
        weakSelf.movingCellSnapshotView.alpha = kInvisibleAlpha;
        cell.alpha = kVisibleAlpha;
    } completion:^(BOOL finished) {
        if (finished)
        {
            weakSelf.movingCellInitialIndexPath = nil;
            [weakSelf.movingCellSnapshotView removeFromSuperview];
            weakSelf.movingCellSnapshotView = nil;
        }
    }];
}


- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.itemsArray.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AccountCell *cell = (AccountCell *)[self.tableView dequeueReusableCellWithIdentifier:kAccountCellIdentifier];
    cell.titleLabel.text = self.itemsArray[indexPath.section];
    cell.titleLabel.textColor = [UIColor redColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

@end
