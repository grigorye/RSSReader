//
//  UINavigationItem+MultipleBarButtonItemsCollections.m
//  RSSReader
//
//  Created by Grigory Entin on 28.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

#import "UINavigationItem+MultipleBarButtonItemsCollections.h"

@implementation UINavigationItem (MultipleBarButtonItemsCollections)

- (void)setRightBarButtonItemsCollection:(NSArray *)rightBarButtonItemsCollection;
{
    self.rightBarButtonItems = [rightBarButtonItemsCollection sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"tag" ascending:YES]]];
}

- (void)setLeftBarButtonItemsCollection:(NSArray *)leftBarButtonItemsCollection;
{
    self.leftBarButtonItems = [leftBarButtonItemsCollection sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"tag" ascending:YES]]];
}

- (NSArray *)rightBarButtonItemsCollection;
{
    return self.rightBarButtonItems;
}

- (NSArray *)leftBarButtonItemsCollection;
{
    return self.leftBarButtonItems;
}

@end
