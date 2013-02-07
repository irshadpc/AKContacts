//
//  AKContactSwitchViewCell.m
//  AKContacts
//
//  Copyright (c) 2013 Adam Kornafeld All rights reserved.
//

#import "AKContactSwitchViewCell.h"
#import "AKContact.h"
#import "AKContactViewController.h"

@interface AKContactSwitchViewCell ()

@property (nonatomic, assign) ABPropertyID abPropertyID;
@property (nonatomic, assign) NSInteger identifier;

@end

@implementation AKContactSwitchViewCell

@synthesize abPropertyID;
@synthesize identifier;

@synthesize parent;

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    // Initialization code
  }
  return self;
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {

  [super setSelected:selected animated:animated];

  // Configure the view for the selected state
}

- (void)dealloc {
}

@end
