//
//  AKGroupsViewController.h
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

#import "AKBadge.h"

@interface AKBadge ()

@property(copy, nonatomic) NSString *text;
@property(strong, nonatomic) UIColor *textColor;
@property(strong, nonatomic) UIColor *insetColor;
@property(strong, nonatomic) UIColor *frameColor;

@property(assign, nonatomic) CGFloat cornerRoundness;

@end

@implementation AKBadge

+ (AKBadge *)badgeWithText: (NSString *)text
{
  return [[AKBadge alloc] initWithText: text];
}

- (id)initWithText: (NSString *)text
{
  self = [super initWithFrame:CGRectMake(0.f, 0.f, 25.f, 25.f)];
	if(self != nil)
  {
		self.backgroundColor = [UIColor clearColor];
		_textColor = [UIColor whiteColor];

		_frameColor = [UIColor whiteColor];
		_insetColor = [UIColor redColor];
		_cornerRoundness = 0.4;
		[self autoBadgeSizeWithText: text];

  }
  return self;
}

- (void) autoBadgeSizeWithText:(NSString *)text
{
	CGSize retValue;
	CGFloat rectWidth, rectHeight;
	CGSize stringSize = [text sizeWithFont:[UIFont boldSystemFontOfSize:12]];
	CGFloat flexSpace;
	if ([text length] >= 2)
  {
		flexSpace = [text length];
		rectWidth = 25 + (stringSize.width + flexSpace); rectHeight = 25;
		retValue = CGSizeMake(rectWidth, rectHeight);
	}
  else
  {
		retValue = CGSizeMake(25.f, 25.f);
	}
	self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, retValue.width, retValue.height);
	self.text = text;
	[self setNeedsDisplay];
}

-(void) drawRoundedRectWithContext:(CGContextRef)context withRect:(CGRect)rect
{
	CGContextSaveGState(context);
	
	CGFloat radius = CGRectGetMaxY(rect) * self.cornerRoundness;
	CGFloat puffer = CGRectGetMaxY(rect) * .1f;
	CGFloat maxX = CGRectGetMaxX(rect) - puffer;
	CGFloat maxY = CGRectGetMaxY(rect) - puffer;
	CGFloat minX = CGRectGetMinX(rect) + puffer;
	CGFloat minY = CGRectGetMinY(rect) + puffer;
  
  CGContextBeginPath(context);
	CGContextSetFillColorWithColor(context, [self.insetColor CGColor]);
	CGContextAddArc(context, maxX-radius, minY+radius, radius, M_PI+(M_PI/2), 0, 0);
	CGContextAddArc(context, maxX-radius, maxY-radius, radius, 0, M_PI/2, 0);
	CGContextAddArc(context, minX+radius, maxY-radius, radius, M_PI/2, M_PI, 0);
	CGContextAddArc(context, minX+radius, minY+radius, radius, M_PI, M_PI+M_PI/2, 0);
  if (SYSTEM_VERSION_LESS_THAN(@"7.0"))
  {
    CGContextSetShadowWithColor(context, CGSizeMake(1.f, 1.f), 3, [[UIColor blackColor] CGColor]);
  }
  CGContextFillPath(context);
  
	CGContextRestoreGState(context);
  
}

-(void) drawShineWithContext:(CGContextRef)context withRect:(CGRect)rect
{
	CGContextSaveGState(context);
  
	CGFloat radius = CGRectGetMaxY(rect) * self.cornerRoundness;
	CGFloat puffer = CGRectGetMaxY(rect) * .1f;
	CGFloat maxX = CGRectGetMaxX(rect) - puffer;
	CGFloat maxY = CGRectGetMaxY(rect) - puffer;
	CGFloat minX = CGRectGetMinX(rect) + puffer;
	CGFloat minY = CGRectGetMinY(rect) + puffer;
	CGContextBeginPath(context);
	CGContextAddArc(context, maxX-radius, minY+radius, radius, M_PI+(M_PI/2), 0, 0);
	CGContextAddArc(context, maxX-radius, maxY-radius, radius, 0, M_PI/2, 0);
	CGContextAddArc(context, minX+radius, maxY-radius, radius, M_PI/2, M_PI, 0);
	CGContextAddArc(context, minX+radius, minY+radius, radius, M_PI, M_PI+M_PI/2, 0);
	CGContextClip(context);

	size_t num_locations = 2;
	CGFloat locations[2] = { .0f, .4f };
	CGFloat components[8] = { .92f, .92f, .92f, 1.f, .82f, .82f, .82f, .4f };

	CGColorSpaceRef cspace;
	CGGradientRef gradient;
	cspace = CGColorSpaceCreateDeviceRGB();
	gradient = CGGradientCreateWithColorComponents (cspace, components, locations, num_locations);
	
	CGPoint startPoint = CGPointMake(0.f, 0.f);
  CGPoint endPoint = CGPointMake(0.f, maxY);
	CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);

	CGColorSpaceRelease(cspace);
	CGGradientRelease(gradient);
	
	CGContextRestoreGState(context);
}

-(void) drawFrameWithContext:(CGContextRef)context withRect:(CGRect)rect
{
	CGFloat radius = CGRectGetMaxY(rect) * self.cornerRoundness;
	CGFloat puffer = CGRectGetMaxY(rect) * .1f;
	
	CGFloat maxX = CGRectGetMaxX(rect) - puffer;
	CGFloat maxY = CGRectGetMaxY(rect) - puffer;
	CGFloat minX = CGRectGetMinX(rect) + puffer;
	CGFloat minY = CGRectGetMinY(rect) + puffer;

  CGContextBeginPath(context);
	CGFloat lineSize = 2.f;
	CGContextSetLineWidth(context, lineSize);
	CGContextSetStrokeColorWithColor(context, [self.frameColor CGColor]);
	CGContextAddArc(context, maxX-radius, minY+radius, radius, M_PI+(M_PI/2), 0, 0);
	CGContextAddArc(context, maxX-radius, maxY-radius, radius, 0, M_PI/2, 0);
	CGContextAddArc(context, minX+radius, maxY-radius, radius, M_PI/2, M_PI, 0);
	CGContextAddArc(context, minX+radius, minY+radius, radius, M_PI, M_PI+M_PI/2, 0);
	CGContextClosePath(context);
	CGContextStrokePath(context);
}


- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();

	[self drawRoundedRectWithContext:context withRect:rect];

  if (SYSTEM_VERSION_LESS_THAN(@"7.0"))
  {
    [self drawShineWithContext:context withRect:rect];

    [self drawFrameWithContext:context withRect:rect];
  }

	if ([self.text length] > 0)
  {
		[self.textColor set];
		CGFloat sizeOfFont = 13.5f;
		if ([self.text length] < 2)
    {
			sizeOfFont += sizeOfFont * .2f;
		}
		UIFont *textFont = [UIFont boldSystemFontOfSize: sizeOfFont];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
      textFont = [UIFont systemFontOfSize: sizeOfFont];
    }
		CGSize textSize = [self.text sizeWithFont: textFont];
		[self.text drawAtPoint: CGPointMake((rect.size.width/2-textSize.width/2), (rect.size.height/2-textSize.height/2))
                  withFont: textFont];
	}
}

@end
