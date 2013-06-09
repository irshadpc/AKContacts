//
//  AKContactsProgressIndicatorView.m
//
//  Copyright (c) 2013 Adam Kornafeld All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions
//  are met:
//  1. Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//  notice, this list of conditions and the following disclaimer in the
//  documentation and/or other materials provided with the distribution.
//  3. The name of the author may not be used to endorse or promote products
//  derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
//  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
//  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "AKContactsProgressIndicatorView.h"

#import <QuartzCore/QuartzCore.h>

static const CGFloat kStrokeWidth = 2.f;
static const CGFloat kRadius = 11.f;

@interface AKContactsProgressIndicatorView ()

@property (assign, nonatomic) CAShapeLayer *spinLayer;

@end

@implementation AKContactsProgressIndicatorView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
        [activity startAnimating];
        [self addSubview: activity];

        CAShapeLayer *s = [CAShapeLayer layer];
        UIColor *stroke = [UIColor colorWithRed: .196f green: .3098f blue: .52f alpha: .8f];
        [s setStrokeColor: stroke.CGColor];
        [s setLineWidth: kStrokeWidth];
        [s setFillColor: [UIColor clearColor].CGColor];
        [[self layer] addSublayer: s];
        [self setSpinLayer:s];
        [[AKAddressBook sharedInstance] setDelegate: self];

        [self setProgress: 0.f];
    }
    return self;
}

- (void)dealloc
{
  [[AKAddressBook sharedInstance] setDelegate: nil];
}

- (void)setProgress: (CGFloat)progress
{
    _progress = progress;

    [CATransaction begin];
    [CATransaction setDisableActions: YES];
    [[self spinLayer] setStrokeEnd: _progress];
    [CATransaction commit];

    if (progress == 1.f)
    {
        [[AKAddressBook sharedInstance] setDelegate: nil];
        [self removeFromSuperview];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect outer = [self bounds];
    UIBezierPath *outerPath = [UIBezierPath bezierPathWithArcCenter: CGPointMake(CGRectGetMidX(outer), CGRectGetMidY(outer))
                                                             radius: kRadius
                                                         startAngle: -M_PI_2 endAngle:(2.0 * M_PI - M_PI_2) clockwise: YES];
    [[self spinLayer] setPath: [outerPath CGPath]];
    [[self spinLayer] setFrame: [self bounds]];
}

@end
