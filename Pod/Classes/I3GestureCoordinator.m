//
//  I3GestureCoordinator.m
//  BetweenKit
//
//  Created by Stephen Fortune on 14/09/2014.
//  Copyright (c) 2013 IceCube Software Ltd. All rights reserved.
//

#import "I3GestureCoordinator.h"
#import "I3Logging.h"


@interface I3GestureCoordinator (Private)


/**
 
 Sets the current dragging view and point.
 
 */
-(void) setCurrentDraggingCollection:(id<I3Collection>) collection atPoint:(CGPoint) at;


/**
 
 Entry point for pan gestures that are coordinated to the I3Collections.
 
 */
-(void) handlePan:(UIPanGestureRecognizer*) gestureRecognizer;


/**
 
 The drag has started! This method determines which collection (if any) the drag started in
 and how then that may be handled.
 
 */
-(void) handleDragStarted;


/**
 
 A drag gesture has stopped! This method determines which collection (if any) the drag has
 stopped in and how that may be handled.
 
 */
-(void) handleDragStopped;


/**
 
 Called whilst we are dragging. It basically just emits notifications such that an external
 rendered can render the drag event.
 
 */
-(void) handleDrag;


/**
 
 Called when a drag has been recognized to start within a particular collection at a particular
 point.
 
 */
-(void) handleDragStartedAtPoint:(CGPoint) at;


/**
 
 Called when a drag, started from a collection has stopped outside of all valid collections at
 a particular point.
 
 */
-(void) handleDragStoppedOutsideAtPoint:(CGPoint) at;


/**
 
 Called when a drag from a collection has stopped on another collection at a given point.
 
 */
-(void) handleDragStoppedInCollection:(id<I3Collection>) to atPoint:(CGPoint) at;


@end


@implementation I3GestureCoordinator


-(id) initWithDragArena:(I3DragArena *)arena withGestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer{

    self = [super init];
    
    if(self){
        
        _arena = arena;
        _gestureRecognizer = gestureRecognizer ?: [[UIPanGestureRecognizer alloc] init];

        SEL panSelector = @selector(handlePan:);
        [_gestureRecognizer addTarget:self action:panSelector];

    }

    return self;
}


#pragma mark - Coordination methods


-(void) handlePan:(UIPanGestureRecognizer*) gestureRecognizer{
    
    switch([gestureRecognizer state]){
            
        case UIGestureRecognizerStateBegan:
            
            DND_LOG(@"Drag Started");
            [self handleDragStarted];
            
            break;
            
        case UIGestureRecognizerStateChanged:
            
            DND_LOG(@"Dragging");
            [self handleDrag];
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            
            DND_LOG(@"Drag Stopped");
            [self handleDragStopped];
            break;
            
        default:
            break;
            
    }

}


-(void) handleDragStarted{
    
    for (id<I3Collection> collection in self.arena.collections){
        
        UIView* collectionView = collection.collectionView;
        CGPoint pointInCollection = [self.gestureRecognizer locationInView:collectionView];
        
        if([collectionView pointInside:pointInCollection withEvent:nil]){
            
            [self handleDragStartedAtPoint:pointInCollection];
            [self setCurrentDraggingCollection:collection atPoint:pointInCollection];
            
            break;
            /// @todo I want to be able to handle transparency here. I3DragDataSource should
            /// implement some BOOL method for whether we're transparent in a particular
            /// place

        }
    }
    
}


-(void) handleDragStopped{

    if(!_currentDraggingCollection){
        DND_LOG(@"Invalid drag stopped.");
        return;
    }
    
    id<I3Collection> dstCollection;
    
    for(id<I3Collection> collection in self.arena.collections){
        
        UIView* collectionView = collection.collectionView;
        CGPoint pointInCollection = [self.gestureRecognizer locationInView:collectionView];
        
        if([collectionView pointInside:pointInCollection withEvent:nil]){
            
            [self handleDragStoppedInCollection:collection atPoint:pointInCollection];
            dstCollection = collection;
            break;
            /// @todo see the todo in handleDragStarted
            
        }
    }
    
    if(!dstCollection){
        
        CGPoint point = [_gestureRecognizer locationInView:self.arena.superview];
        [self handleDragStoppedOutsideAtPoint:point];
    }
    
    [self setCurrentDraggingCollection:nil atPoint:CGPointZero];

}


-(void) handleDrag{
    
    if(!_currentDraggingCollection){
        
        DND_LOG(@"Handle drag but we're not dragging.");
        return;
    }
    
    /// @todo Emit notification for rendering

}


#pragma mark Accessor methods


-(void) setCurrentDraggingCollection:(id<I3Collection>) collection atPoint:(CGPoint) at{

    _currentDraggingCollection = collection;
    _currentDragOrigin = at;

}


@end
