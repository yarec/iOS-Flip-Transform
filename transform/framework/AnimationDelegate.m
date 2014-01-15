
/*
 
 File: AnimationDelegate.m
 Abstract: Animation Delegate is the helper to handle callbacks
 from transform operations. The animation 
 delegate should have knowledge of how and what kind of transform
 should be applied to current animation frame, based on the type
 of animation and various user settings.
 
 
 Copyright (c) 2011 Dillion Tan
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import "AnimationDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "GenericAnimationView.h"
#import "AnimationFrame.h"

@interface AnimationDelegate ()
{
    CGImageRef _transitionImageBackup;
    
    float _currentDuration;
    
    DirectionType _currentDirection;
    
    float _value;
    
    float _oldOpacityValue;
}
@end

@implementation AnimationDelegate

- (id)initWithSequenceType:(SequenceType)aType
             directionType:(DirectionType)aDirection 
{

    if ((self = [super init])) {
        
        self.transformView = nil;
        self.controller = nil;
        
        self.sequenceType = aType;
        _currentDirection = aDirection;
        self.repeat = NO;
        
        // default values
        self.nextDuration = 0.6;
        self.repeatDelay = 0.2;
        self.sensitivity = 40;
        self.gravity = 2;
        self.perspectiveDepth = 500;
        self.shadow = YES;
        
        if (self.sequenceType == kSequenceAuto) {
            self.repeat = YES;
        } else {
            self.repeat = NO;
        }
        
    }
    return self;
}

- (BOOL)startAnimation:(DirectionType)aDirection 
{
    if (self.animationState == 0) {
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        
        if (aDirection != kDirectionNone) {
            _currentDirection = aDirection;
        }
        
        switch (_currentDirection) {
            case kDirectionForward:
                [self setTransformValue:10.0f delegating:YES];
                return YES;
                break;
            case kDirectionBackward:
                [self setTransformValue:-10.0f delegating:YES];
                return YES;
                break;
            default:break;
        }
    }
    
    return NO;
}

- (void)animationDidStop:(CABasicAnimation *)theAnimation finished:(BOOL)flag
{
    if (flag) {
        
        switch (self.animationState) {
            case 0:
                break;
            case 1: {
                switch (self.transformView.animationType) {
                    case kAnimationFlipVertical:
                    case kAnimationFlipHorizontal: {
                        [self animationCallback];
                    }
                        break;
                    default:
                        break;
                }
            }
                break;
            default:
                break;
        }
    }
}

- (void)animationCallback 
{
    [self resetTransformValues];
    
    if (self.animationCompletionBlock)
        self.animationCompletionBlock(self);
    
    if (self.repeat && self.sequenceType == kSequenceAuto) {
        // the recommended way to queue CAAnimations by Apple is to offset the beginTime, 
        // but doing so requires changing the fillmode to kCAFillModeBackwards
        // using perform selector allows maintaining the fillmode value of the original animation
        [self performSelector:@selector(startAnimation:) withObject:nil afterDelay:self.repeatDelay];
    }
        
}

- (void)endStateWithSpeed:(float)aVelocity
{
    if (_value == 0.0f) {
        
        [self resetTransformValues];
        
    } else if (_value == 10.0f) {
        
        [self resetTransformValues];
        
    } else {
        
        AnimationFrame* currentFrame = [self.transformView.imageStackArray lastObject];
        CALayer *targetLayer;
        
        int aX, aY, aZ;
        int rotationModifier;
        
        switch (self.transformView.animationType) {
            case kAnimationFlipVertical:
                aX = 1;
                aY = 0;
                aZ = 0;
                rotationModifier = -1;
                break;
            case kAnimationFlipHorizontal:
                aX = 0;
                aY = 1;
                aZ = 0;
                rotationModifier = 1;
                break;
            default:break;
        }
        
        float rotationAfterDirection;
        
        if (_currentDirection == kDirectionForward) {
            rotationAfterDirection = M_PI * rotationModifier;
            targetLayer = [currentFrame.animationImages lastObject];
        } else {
            rotationAfterDirection = -M_PI * rotationModifier;
            targetLayer = [currentFrame.animationImages objectAtIndex:0];
        }
        CALayer *targetShadowLayer;
        
        CATransform3D aTransform = CATransform3DIdentity;
        aTransform.m34 = 1.0 / -self.perspectiveDepth;
        [targetLayer setValue:[NSValue valueWithCATransform3D:CATransform3DRotate(aTransform,rotationAfterDirection/10.0 * _value, aX, aY, aZ)] forKeyPath:@"transform"];
        for (CALayer *layer in targetLayer.sublayers) {
            [layer removeAllAnimations];
        }
        [targetLayer removeAllAnimations];
        
        if (self.gravity > 0) {
            
            self.animationState = 1;
            
            if (_value+aVelocity <= 5.0f) {
                targetShadowLayer = [targetLayer.sublayers objectAtIndex:1];
                
                [self setTransformProgress:rotationAfterDirection / 10.0 * _value
                                          :0.0f
                                          :1.0f/(self.gravity+aVelocity)
                                          :aX :aY :aZ
                                          :YES
                                          :NO
                                          :kCAFillModeForwards 
                                          :targetLayer];
                if (self.shadow) {
                    [self setOpacityProgress:_oldOpacityValue 
                                            :0.0f
                                            :0.0f
                                            :_currentDuration 
                                            :kCAFillModeForwards 
                                            :targetShadowLayer];
                }
                _value = 0.0f;
            } else {
                targetShadowLayer = [targetLayer.sublayers objectAtIndex:3];
                
                [self setTransformProgress:rotationAfterDirection / 10.0 * _value
                                          :rotationAfterDirection
                                          :1.0f/(self.gravity+aVelocity)
                                          :aX :aY :aZ
                                          :YES
                                          :NO
                                          :kCAFillModeForwards 
                                          :targetLayer];
                if (self.shadow) {
                    [self setOpacityProgress:_oldOpacityValue 
                                            :0.0f
                                            :0.0f
                                            :_currentDuration 
                                            :kCAFillModeForwards 
                                            :targetShadowLayer];
                }
                _value = 10.0f;
            }
        }
    }
}

- (void)resetTransformValues
{
    AnimationFrame* currentFrame = [self.transformView.imageStackArray lastObject];
    
    CALayer *targetLayer;
    CALayer *targetShadowLayer, *targetShadowLayer2;
    
    if (_currentDirection == kDirectionForward) {
        targetLayer = [currentFrame.animationImages lastObject];
    } else {
        targetLayer = [currentFrame.animationImages objectAtIndex:0];
    }
    
    targetShadowLayer = [targetLayer.sublayers objectAtIndex:1];
    targetShadowLayer2 = [targetLayer.sublayers objectAtIndex:3];
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    [targetLayer setValue:[NSValue valueWithCATransform3D:CATransform3DIdentity] forKeyPath:@"transform"];
    targetShadowLayer.opacity = 0.0f;
    targetShadowLayer2.opacity = 0.0f;
    
    for (CALayer *layer in targetLayer.sublayers) {
        [layer removeAllAnimations];
    }
    [targetLayer removeAllAnimations];
    
    targetLayer.zPosition = 0;
    
    CATransform3D aTransform = CATransform3DIdentity;
    targetLayer.sublayerTransform = aTransform;
    
    if (_value == 10.0f) {
        [self.transformView rearrangeLayers:_currentDirection :3];
    } else {
        [self.transformView rearrangeLayers:_currentDirection :2];
    }
    
    [CATransaction commit];
    
    if (self.controller && [self.controller respondsToSelector:@selector(animationDidFinish:)]) {
        if (_currentDirection == kDirectionForward && _value == 10.0f) {
            [self.controller animationDidFinish:1];
        } else if (_currentDirection == kDirectionBackward && _value == 10.0f) {
            [self.controller animationDidFinish:-1];
        }
    }
    
    self.animationState = 0;
    self.animationLock = NO;
    _transitionImageBackup = nil;
    _value = 0.0f;
    _oldOpacityValue = 0.0f;
}

// set the progress of the animation
- (void)setTransformValue:(float)aValue delegating:(BOOL)bValue
{
    _currentDuration = self.nextDuration;
    
    int frameCount = [self.transformView.imageStackArray count];
    AnimationFrame* currentFrame = [self.transformView.imageStackArray lastObject];
    CALayer *targetLayer;
    AnimationFrame* nextFrame = [self.transformView.imageStackArray objectAtIndex:frameCount-2];
    AnimationFrame* previousFrame = [self.transformView.imageStackArray objectAtIndex:0];

    int aX, aY, aZ;
    int rotationModifier;
    
    switch (self.transformView.animationType) {
        case kAnimationFlipVertical:
            aX = 1;
            aY = 0;
            aZ = 0;
            rotationModifier = -1;
            break;
        case kAnimationFlipHorizontal:
            aX = 0;
            aY = 1;
            aZ = 0;
            rotationModifier = 1;
            break;
        default:break;
    }
    
    float rotationAfterDirection;
    
    if (_transitionImageBackup == nil) {
        if (aValue - _value >= 0.0f) {
            _currentDirection = kDirectionForward;
            switch (self.transformView.animationType) {
                case kAnimationFlipVertical:
                case kAnimationFlipHorizontal: {
                    targetLayer = [currentFrame.animationImages lastObject];
                    targetLayer.zPosition = 100;
                }
                    break;
                default:
                    break;
            }
            self.animationState++;
        } else if (aValue - _value < 0.0f) {
            _currentDirection = kDirectionBackward;
            [self.transformView rearrangeLayers:_currentDirection :1];
            switch (self.transformView.animationType) {
                case kAnimationFlipVertical:
                case kAnimationFlipHorizontal: {
                    targetLayer = [currentFrame.animationImages objectAtIndex:0];
                    targetLayer.zPosition = 100;
                }
                    break;
                default:
                    break;
            }
            self.animationState++;
        }
    }
    
    if (_currentDirection == kDirectionForward) {
        rotationAfterDirection = M_PI * rotationModifier;
        targetLayer = [currentFrame.animationImages lastObject];
    } else {
        rotationAfterDirection = -M_PI * rotationModifier;
        targetLayer = [currentFrame.animationImages objectAtIndex:0];
    }
    
    float adjustedValue;
    float opacityValue;
    if (self.sequenceType == kSequenceControlled) {
        adjustedValue = fabs(aValue * (self.sensitivity/1000.0));
    } else {
        adjustedValue = fabs(aValue);
    }
    adjustedValue = MAX(0.0, adjustedValue);
    adjustedValue = MIN(10.0, adjustedValue);
    
    if (adjustedValue <= 5.0f) {
        opacityValue = adjustedValue/10.0f;
    } else if (adjustedValue > 5.0f) {
        opacityValue = (10.0f - adjustedValue)/10.0f;
    }
    
    CALayer *targetFrontLayer, *targetBackLayer = nil;
    CALayer *targetShadowLayer, *targetShadowLayer2 = nil;
    
    switch (self.transformView.animationType) {
        case kAnimationFlipVertical: {
            
            switch (_currentDirection) {
                case kDirectionForward: {
                    
                    targetFrontLayer = [targetLayer.sublayers objectAtIndex:2];
                    CALayer *nextLayer = [nextFrame.animationImages objectAtIndex:0];
                    targetBackLayer = [nextLayer.sublayers objectAtIndex:0];
                    
                }
                    break;
                case kDirectionBackward: {
                    
                    targetFrontLayer = [targetLayer.sublayers objectAtIndex:2];
                    CALayer *previousLayer = [previousFrame.animationImages objectAtIndex:1];
                    targetBackLayer = [previousLayer.sublayers objectAtIndex:0];
                    
                }
                    break;
                default:
                    break;
            }
            
        }
            break;
        case kAnimationFlipHorizontal: {
            
            switch (_currentDirection) {
                case kDirectionForward: {
                    
                    targetFrontLayer = [targetLayer.sublayers objectAtIndex:2];
                    CALayer *nextLayer = [nextFrame.animationImages objectAtIndex:0];
                    targetBackLayer = [nextLayer.sublayers objectAtIndex:0];
                }
                    break;
                case kDirectionBackward: {
                    
                    targetFrontLayer = [targetLayer.sublayers objectAtIndex:2];
                    CALayer *previousLayer = [previousFrame.animationImages objectAtIndex:1];
                    targetBackLayer = [previousLayer.sublayers objectAtIndex:0];
                }
                    break;
                default:
                    break;
            }
        }
            break;
        default:break;
    }
    if (adjustedValue == 10.0f && _value == 0.0f) {
        targetShadowLayer = [targetLayer.sublayers objectAtIndex:1];
        targetShadowLayer2 = [targetLayer.sublayers objectAtIndex:3];
    }
    else if (adjustedValue <= 5.0f) {
        targetShadowLayer = [targetLayer.sublayers objectAtIndex:1];
    } 
    else {
        targetShadowLayer = [targetLayer.sublayers objectAtIndex:3];
    }
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    CATransform3D aTransform = CATransform3DIdentity;
    aTransform.m34 = 1.0 / -self.perspectiveDepth;
    [targetLayer setValue:[NSValue valueWithCATransform3D:CATransform3DRotate(aTransform, rotationAfterDirection/10.0 * _value, aX, aY, aZ)] forKeyPath:@"transform"];
    targetShadowLayer.opacity = _oldOpacityValue;
    if (targetShadowLayer2) targetShadowLayer2.opacity = _oldOpacityValue;
    for (CALayer *layer in targetLayer.sublayers) {
        [layer removeAllAnimations];
    }
    [targetLayer removeAllAnimations];
    
    [CATransaction commit];
    
    if (adjustedValue != _value) {
        
        CATransform3D aTransform = CATransform3DIdentity;
        aTransform.m34 = 1.0 / -self.perspectiveDepth;
        targetLayer.sublayerTransform = aTransform;
        
        if (_transitionImageBackup == nil) { //transition has begun, copy the layer content for the reverse layer
            
            CGImageRef tempImageRef = (CGImageRef)targetBackLayer.contents;
            
            //NSLog(@"%s:%d imageref=%@", __func__, __LINE__, tempImageRef);
            
            _transitionImageBackup = (CGImageRef)targetFrontLayer.contents;
            targetFrontLayer.contents = (__bridge id)tempImageRef;
        } 
        
        [self setTransformProgress:(rotationAfterDirection/10.0 * _value)
                                  :(rotationAfterDirection/10.0 * adjustedValue)
                                  :_currentDuration
                                  :aX :aY :aZ
                                  :bValue
                                  :NO
                                  :kCAFillModeForwards 
                                  :targetLayer];
        
        if (self.shadow) {
            if (_oldOpacityValue == 0.0f && _oldOpacityValue == opacityValue) {
                
                [self setOpacityProgress:0.0f 
                                        :0.5f
                                        :0.0f
                                        :_currentDuration/2 
                                        :kCAFillModeForwards 
                                        :targetShadowLayer];
                [self setOpacityProgress:0.5f 
                                        :0.0f
                                        :_currentDuration/2
                                        :_currentDuration/2 
                                        :kCAFillModeBackwards 
                                        :targetShadowLayer2];
            } else {
                [self setOpacityProgress:_oldOpacityValue 
                                        :opacityValue
                                        :0.0f
                                        :_currentDuration 
                                        :kCAFillModeForwards 
                                        :targetShadowLayer];
            }
        }
        
        _value = adjustedValue;
        
        _oldOpacityValue = opacityValue;
    }

}

- (void)setTransformProgress:(float)startTransformValue
                            :(float)endTransformValue
                            :(float)duration
                            :(int)aX 
                            :(int)aY 
                            :(int)aZ
                            :(BOOL)setDelegate
                            :(BOOL)removedOnCompletion
                            :(NSString *)fillMode
                            :(CALayer *)targetLayer
{
    //NSLog(@"transform value %f, %f", startTransformValue, endTransformValue);
    
    CATransform3D aTransform = CATransform3DIdentity;
    aTransform.m34 = 1.0 / -self.perspectiveDepth;
    
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform"];
    anim.duration = duration;
    anim.fromValue= [NSValue valueWithCATransform3D:CATransform3DRotate(aTransform, startTransformValue, aX, aY, aZ)];
    anim.toValue=[NSValue valueWithCATransform3D:CATransform3DRotate(aTransform, endTransformValue, aX, aY, aZ)];
    if (setDelegate) {
        anim.delegate = self;
    }
    anim.removedOnCompletion = removedOnCompletion;
    [anim setFillMode:fillMode];
    
    [targetLayer addAnimation:anim forKey:@"transformAnimation"];
}

- (void)setOpacityProgress:(float)startOpacityValue
                          :(float)endOpacityValue
                          :(float)beginTime
                          :(float)duration
                          :(NSString *)fillMode
                          :(CALayer *)targetLayer
{
    //NSLog(@"opacity value %f, %f, %@", startOpacityValue, endOpacityValue, targetLayer);
    
    CFTimeInterval localMediaTime = [targetLayer convertTime:CACurrentMediaTime() fromLayer:nil];
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"opacity"];
    anim.duration = duration;
    anim.fromValue= [NSNumber numberWithFloat:startOpacityValue];
    anim.toValue= [NSNumber numberWithFloat:endOpacityValue];
    anim.beginTime = localMediaTime+beginTime;
    anim.removedOnCompletion = NO;
    [anim setFillMode:fillMode];
    
    [targetLayer addAnimation:anim forKey:@"opacityAnimation"];
}

@end
