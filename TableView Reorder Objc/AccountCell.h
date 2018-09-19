//
//  AccountCell.h
//  TableView Reorder Objc
//
//  Created by William Peroche on 20/09/18.
//  Copyright © 2018 William Peroche. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface AccountCell : UITableViewCell
extern NSString *const kAccountCellIdentifier;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@end
