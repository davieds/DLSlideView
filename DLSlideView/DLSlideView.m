//
//  DLSlideView.m
//  DLSlideController
//
//  Created by Dongle Su on 14-12-7.
//  Copyright (c) 2014年 dongle. All rights reserved.
//

#import "DLSlideView.h"

#define kPanSwitchOffsetThreshold 50.0f

@implementation DLSlideView{
    int oldIndex_;
    int panToIndex_;
    UIPanGestureRecognizer *pan_;
    CGPoint panStartPoint_;
}

- (void)commonInit{
    oldIndex_ = -1;
    
    pan_ = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panHandler:)];
    [self addGestureRecognizer:pan_];
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (int)selectedIndex{
    return oldIndex_;
}
- (void)setSelectedIndex:(int)selectedIndex{
    if (selectedIndex != oldIndex_) {
        [self switchTo:selectedIndex];
    }
}
- (void)setViewControllers:(NSArray *)vcs{
    _viewControllers = vcs;
}

- (void)showAt:(int)index{
    if (oldIndex_ != index) {
        [self removeAt:oldIndex_];
        
        UIViewController *vc = [self.viewControllers objectAtIndex:index];
        [self.baseViewController addChildViewController:vc];
        vc.view.frame = self.bounds;
        [self addSubview:vc.view];
        [vc didMoveToParentViewController:self.baseViewController];
        oldIndex_ = index;
    }
}

- (void)removeAt:(int)index{
    if (oldIndex_ == index) {
        oldIndex_ = -1;
    }
    
    if (index >= 0 && index <= self.viewControllers.count) {
        UIViewController *vc = [self.viewControllers objectAtIndex:index];
        [vc willMoveToParentViewController:nil];
        [vc.view removeFromSuperview];
        [vc removeFromParentViewController];
    }
}
- (void)switchTo:(int)index{
    if (index == oldIndex_) {
        return;
    }
    
    if (oldIndex_ >= 0) {
        UIViewController *oldvc = [self.viewControllers objectAtIndex:oldIndex_];
        UIViewController *newvc = [self.viewControllers objectAtIndex:index];
        
        [oldvc willMoveToParentViewController:nil];
        [self.baseViewController addChildViewController:newvc];
        
        CGRect nowRect = oldvc.view.frame;
        CGRect leftRect = CGRectMake(nowRect.origin.x-nowRect.size.width, nowRect.origin.y, nowRect.size.width, nowRect.size.height);
        CGRect rightRect = CGRectMake(nowRect.origin.x+nowRect.size.width, nowRect.origin.y, nowRect.size.width, nowRect.size.height);
        
        CGRect newStartRect;
        CGRect oldEndRect;
        if (index > oldIndex_) {
            newStartRect = rightRect;
            oldEndRect = leftRect;
        }
        else{
            newStartRect = leftRect;
            oldEndRect = rightRect;
        }
        
        newvc.view.frame = newStartRect;
        
        [self.baseViewController transitionFromViewController:oldvc toViewController:newvc duration:0.4 options:0 animations:^{
            newvc.view.frame = nowRect;
            oldvc.view.frame = oldEndRect;
        } completion:^(BOOL finished) {
            [oldvc removeFromParentViewController];
            [newvc didMoveToParentViewController:self.baseViewController];
        }];
        
        oldIndex_ = index;
    }
    else{
        [self showAt:index];
    }
}

- (void)repositionForOffsetX:(CGFloat)offsetx{
    float x = 0.0f;
    
    if (panToIndex_ < oldIndex_) {
        x = self.bounds.origin.x - self.bounds.size.width + offsetx;
    }
    else if(panToIndex_ > oldIndex_){
        x = self.bounds.origin.x + self.bounds.size.width + offsetx;
    }
    
    UIViewController *oldvc = [self.viewControllers objectAtIndex:oldIndex_];
    oldvc.view.frame = CGRectMake(self.bounds.origin.x + offsetx, self.bounds.origin.y, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    
    if (panToIndex_ >= 0 && panToIndex_ < self.viewControllers.count) {
        UIViewController *vc = [self.viewControllers objectAtIndex:panToIndex_];
        vc.view.frame = CGRectMake(x, self.bounds.origin.y, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
        if (vc.parentViewController == nil) {
            
            [self.baseViewController addChildViewController:vc];
            [self addSubview:vc.view];
            [vc didMoveToParentViewController:self.baseViewController];
        }
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(DLSlideView:switchingFrom:to:percent:)]) {
        [self.delegate DLSlideView:self switchingFrom:oldIndex_ to:panToIndex_ percent:fabs(offsetx)/self.bounds.size.width];
    }
}

- (void)backToOldWithOffset:(CGFloat)offsetx{
    NSTimeInterval animatedTime = 0;
    animatedTime = 0.3;
    
    //animatedTime = fabs(self.frame.size.width - fabs(offsetx)) / self.frame.size.width * 0.35;
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView animateWithDuration:animatedTime animations:^{
        [self repositionForOffsetX:0];
    } completion:^(BOOL finished) {
        if (panToIndex_ >= 0 && panToIndex_ < self.viewControllers.count && panToIndex_ != oldIndex_) {
            [self removeAt:panToIndex_];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(DLSlideView:switchCanceled:)]) {
            [self.delegate DLSlideView:self switchCanceled:oldIndex_];
        }
    }];
    
    [UIView animateWithDuration:animatedTime delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        float pantox = 0.0f;
        if (offsetx > 0) {
            pantox = -self.bounds.size.width;
        }
        else{
            pantox = self.bounds.size.width;
        }
        
        UIViewController *oldvc = [self.viewControllers objectAtIndex:oldIndex_];
        oldvc.view.frame = CGRectMake(0, self.bounds.origin.y, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
        if (panToIndex_ >= 0 && panToIndex_ < self.viewControllers.count) {
            UIViewController *vc = [self.viewControllers objectAtIndex:panToIndex_];
            vc.view.frame = CGRectMake(pantox, self.bounds.origin.y, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
        }
    } completion:^(BOOL finished) {
        if (panToIndex_ >= 0 && panToIndex_ < self.viewControllers.count && panToIndex_ != oldIndex_) {
            [self removeAt:panToIndex_];
        }
    }];
    
}
- (void)panHandler:(UIPanGestureRecognizer *)pan{
    if (oldIndex_ < 0) {
        return;
    }
    
    CGPoint point = [pan translationInView:self];
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        panStartPoint_ = point;
    }
    else if (pan.state == UIGestureRecognizerStateChanged){
        panToIndex_ = -1;
        float offsetx = point.x - panStartPoint_.x;
        
        if (offsetx > 0) {
            panToIndex_ = oldIndex_ - 1;
        }
        else if(offsetx < 0){
            panToIndex_ = oldIndex_ + 1;
        }
        
        if (panToIndex_ < 0 || panToIndex_ >= self.viewControllers.count) {
            [self repositionForOffsetX:offsetx/2.0f];
        }
        else{
            [self repositionForOffsetX:offsetx];
        }
    }
    else if (pan.state == UIGestureRecognizerStateEnded){
        float offsetx = point.x - panStartPoint_.x;
        
        if (panToIndex_ >= 0 && panToIndex_ < self.viewControllers.count && panToIndex_ != oldIndex_) {
            if (fabs(offsetx) > kPanSwitchOffsetThreshold) {
                NSTimeInterval animatedTime = 0;
                animatedTime = fabs(self.frame.size.width - fabs(offsetx)) / self.frame.size.width * 0.4;
                [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
                [UIView animateWithDuration:animatedTime animations:^{
                    [self repositionForOffsetX:offsetx > 0 ? self.bounds.size.width : -self.bounds.size.width];
                } completion:^(BOOL finished) {
                    [self removeAt:oldIndex_];
                    
                    if (panToIndex_ >= 0 && panToIndex_ < self.viewControllers.count) {
                        oldIndex_ = panToIndex_;
                    }
                    if (self.delegate && [self.delegate respondsToSelector:@selector(DLSlideView:didSwitchTo:)]) {
                        [self.delegate DLSlideView:self didSwitchTo:oldIndex_];
                    }
                }];
            }
            else{
                [self backToOldWithOffset:offsetx];
            }
        }
        else{
            [self backToOldWithOffset:offsetx];
        }
    }
}

@end