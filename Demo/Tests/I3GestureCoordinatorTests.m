//
//  I3GestureCoordinatorTests.m
//  BetweenKit
//
//  Created by Stephen Fortune on 14/09/2014.
//  Copyright (c) 2014 stephen fortune. All rights reserved.
//

#import <BetweenKit/I3GestureCoordinator.h>
#import "I3DragDataSourceJustCanDelete.h"
#import "I3DragDataSourceJustDelete.h"
#import "I3DragDataSourceJustCanRearrange.h"
#import "I3DragDataSourceJustRearrange.h"
#import "I3DragDataSourceJustCanDrop.h"
#import "I3DragDataSourceJustDrop.h"


/// @todo In a couple of scenarios, we're not asserting anything in these tests. E.g. we
/// are testing that a method is specifically not called. See http://youtu.be/q5Xd1tmIgec?t=33m56s
/// @todo Make sure we're not using 2 of the same class mocks simultaneously.
/// @see http://ocmock.org/reference/ -> Limitations

SpecBegin(I3GestureCoordinator)


    __block NSMutableOrderedSet *collections;
    __block id dragArena;
    __block id superview;
    __block id panGestureRecognizer;



    beforeEach(^{
    
        dragArena = OCMClassMock([I3DragArena class]);
        superview = OCMPartialMock([[UIView alloc] init]);
        panGestureRecognizer = OCMPartialMock([[UIPanGestureRecognizer alloc] init]);
        collections = [[NSMutableOrderedSet alloc] init];
        
        OCMStub([dragArena superview]).andReturn(superview);
        OCMStub([dragArena collections]).andReturn(collections);
        
    });

    afterEach(^{
        
        dragArena = nil;
        superview = nil;
        panGestureRecognizer = nil;
        collections = nil;
    
    });


    describe(@"constructor", ^{
        
        it(@"should inject dependencies", ^{
        
            I3GestureCoordinator *coordinator = [[I3GestureCoordinator alloc] initWithDragArena:dragArena withGestureRecognizer:panGestureRecognizer];
            
            expect(coordinator.gestureRecognizer).to.equal(panGestureRecognizer);
            expect(coordinator.arena).to.equal(dragArena);
        
        });
    
        it(@"should create a UIPanGestureRecognizer by default", ^{
        
            I3GestureCoordinator *coordinator = [[I3GestureCoordinator alloc] initWithDragArena:dragArena withGestureRecognizer:nil];
            expect(coordinator.gestureRecognizer).to.beInstanceOf([UIPanGestureRecognizer class]);
            
        });
        
        it(@"should setup the gesture recognizer's target and superview correctly", ^{
        
            I3GestureCoordinator *coordinator = [[I3GestureCoordinator alloc] initWithDragArena:dragArena withGestureRecognizer:panGestureRecognizer];
            OCMVerify([panGestureRecognizer addTarget:coordinator action:[OCMArg anySelector]]);
            OCMVerify([superview addGestureRecognizer:panGestureRecognizer]);
            
        });
        
        it(@"should not attach the gesture recognizer to the superview if its already attached", ^{

            [superview addGestureRecognizer:panGestureRecognizer];
            
            I3GestureCoordinator *coordinator __unused = [[I3GestureCoordinator alloc] initWithDragArena:dragArena withGestureRecognizer:panGestureRecognizer];
            
            expect([superview gestureRecognizers]).to.haveCountOf(1);

        });
        
    });


    describe(@"destructor", ^{

    
        /** @note Here we use pragma to ignore warnings about weak variables being assigned and
         then released immediately after as this is exactly what we are trying to achieve. In
         order for 'dealloc' to be triggered under ARC we must invoke the ctor by creating a
         weak reference that will unasigned immediately. */
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-unsafe-retained-assign"
        
        
        it(@"should unbind gesture recognizer from coordinator and superview", ^{
            
            [superview addGestureRecognizer:panGestureRecognizer];
            
            __weak I3GestureCoordinator *coordinator __unused = [[I3GestureCoordinator alloc] initWithDragArena:dragArena withGestureRecognizer:panGestureRecognizer];
            
            OCMVerify([panGestureRecognizer removeTarget:[OCMArg any] action:NULL]);
            OCMVerify([superview removeGestureRecognizer:panGestureRecognizer]);
            
        });
        
        it(@"should not attempt to remove gesture recognizer from superview if it is no longer present", ^{
            
            [[superview reject] removeGestureRecognizer:panGestureRecognizer];
            __weak I3GestureCoordinator *coordinator __unused = [[I3GestureCoordinator alloc] initWithDragArena:dragArena withGestureRecognizer:panGestureRecognizer];
            
        });
        
#pragma clang diagnostic pop
        
    });


    describe(@"properties", ^{

        it(@"should set the coordinator's render delegate", ^{

            I3GestureCoordinator *coordinator = [[I3GestureCoordinator alloc] initWithDragArena:dragArena withGestureRecognizer:panGestureRecognizer];
            id renderDelegate = OCMProtocolMock(@protocol(I3DragRenderDelegate));

            [coordinator setRenderDelegate:renderDelegate];
            expect(coordinator.renderDelegate).to.equal(renderDelegate);

        });
        
    });


    describe(@"drag/drop coordination", ^{

        
        __block I3GestureCoordinator *coordinator;
        __block id renderDelegate;

        CGPoint dragOrigin = CGPointMake(10, 10);

        
        beforeEach(^{
            
            coordinator = [[I3GestureCoordinator alloc] initWithDragArena:dragArena withGestureRecognizer:panGestureRecognizer];
            renderDelegate = OCMProtocolMock(@protocol(I3DragRenderDelegate));
            
            coordinator.renderDelegate = renderDelegate;
            
        });
        
        afterEach(^{
            
            coordinator = nil;
            renderDelegate = nil;
            
        });

        
        describe(@"starting a drag", ^{

            
            beforeEach(^{

                OCMStub([panGestureRecognizer state]).andReturn(UIGestureRecognizerStateBegan);
            
            });
            
            
            it(@"should start and render a drag on a collection if the point is inside its bounds and the item is draggable", ^{
                
                id draggingCollection = OCMProtocolMock(@protocol(I3Collection));
                id draggingDataSource = OCMProtocolMock(@protocol(I3DragDataSource));
                id collectionView = OCMPartialMock([[UIView alloc] init]);
                
                OCMStub([draggingCollection dragDataSource]).andReturn(draggingDataSource);
                OCMStub([draggingDataSource canItemBeDraggedAtPoint:dragOrigin inCollection:draggingCollection]).andReturn(YES);
                OCMStub([draggingCollection collectionView]).andReturn(collectionView);
                OCMStub([collectionView pointInside:dragOrigin withEvent:nil]).andReturn(YES);
                [[dragArena collections] addObject:draggingCollection];

                [coordinator handlePan:coordinator.gestureRecognizer];
                
                expect(coordinator.currentDraggingCollection).to.equal(draggingCollection);
                expect(coordinator.currentDragOrigin).to.equal(dragOrigin);
                
                OCMVerify([renderDelegate renderDragStart:coordinator]);
                OCMVerify([draggingCollection dragDataSource]);
                OCMVerify([draggingDataSource canItemBeDraggedAtPoint:dragOrigin inCollection:draggingCollection]);
                
            });
            
            it(@"should assume that a collection is completely un-draggable if there is no data source", ^{
                
                id undraggableCollection = OCMProtocolMock(@protocol(I3Collection));
                id collectionView = OCMPartialMock([[UIView alloc] init]);

                /// Explicitly does not mock the retrieving of the data source so that the collection is
                /// deemed 'undraggable'.
                
                OCMStub([undraggableCollection collectionView]).andReturn(collectionView);
                OCMStub([collectionView pointInside:dragOrigin withEvent:nil]).andReturn(YES);
                [[dragArena collections] addObject:undraggableCollection];

                [coordinator handlePan:coordinator.gestureRecognizer];
                
                expect(coordinator.currentDraggingCollection).to.beNil();
                expect(coordinator.currentDragOrigin).to.equal(CGPointZero);
                
                OCMVerify([undraggableCollection dragDataSource]);
                
            });
            
            it(@"should not start dragging an item in a collection that is not draggable", ^{
                
                id draggingCollection = OCMProtocolMock(@protocol(I3Collection));
                id draggingDataSource = OCMProtocolMock(@protocol(I3DragDataSource));
                id collectionView = OCMPartialMock([[UIView alloc] init]);

                /// Configure the draggingDataSource to allow for the given item at the dragOrigin to be
                /// dragged
                
                OCMStub([draggingCollection dragDataSource]).andReturn(draggingDataSource);
                OCMStub([draggingCollection collectionView]).andReturn(collectionView);
                OCMStub([collectionView pointInside:dragOrigin withEvent:nil]).andReturn(YES);
                OCMStub([draggingDataSource canItemBeDraggedAtPoint:dragOrigin inCollection:draggingCollection]).andReturn(NO);
                [[dragArena collections] addObject:draggingCollection];

                [coordinator handlePan:coordinator.gestureRecognizer];
                
                expect(coordinator.currentDraggingCollection).to.beNil();
                expect(coordinator.currentDragOrigin).to.equal(CGPointZero);
                
                OCMVerify([draggingCollection dragDataSource]);
                OCMVerify([draggingDataSource canItemBeDraggedAtPoint:dragOrigin inCollection:draggingCollection]);

            });
            
            it(@"should start and render dragging on the top-most intersecting collection and none underneith", ^{
                
                id topDraggingCollection = OCMProtocolMock(@protocol(I3Collection));
                id bottomDraggingCollection = OCMProtocolMock(@protocol(I3Collection));

                id topDraggingDataSource = OCMProtocolMock(@protocol(I3DragDataSource));
                id bottomDraggingDataSource = OCMProtocolMock(@protocol(I3DragDataSource));
                
                id topCollectionView = OCMPartialMock([[UIView alloc] init]);
                
                OCMStub([topDraggingDataSource canItemBeDraggedAtPoint:dragOrigin inCollection:topDraggingCollection]).andReturn(YES);
                OCMStub([topDraggingCollection dragDataSource]).andReturn(topDraggingDataSource);
                OCMStub([topDraggingCollection collectionView]).andReturn(topCollectionView);
                OCMStub([topCollectionView pointInside:dragOrigin withEvent:nil]).andReturn(YES);
                [[dragArena collections] addObjectsFromArray:@[topDraggingCollection, bottomDraggingCollection]];

                /// Verify that the bottom drag data source's methods are not called
                
                [[bottomDraggingDataSource reject] canItemBeDraggedAtPoint:dragOrigin inCollection:bottomDraggingCollection];
                [[bottomDraggingCollection reject] dragDataSource];
                [[bottomDraggingCollection reject] collectionView];
                
                [coordinator handlePan:coordinator.gestureRecognizer];
                
                expect(coordinator.currentDraggingCollection).to.equal(topDraggingCollection);
                
                OCMVerify([renderDelegate renderDragStart:coordinator]);
                OCMVerify([topDraggingCollection dragDataSource]);
                OCMVerify([topDraggingDataSource canItemBeDraggedAtPoint:dragOrigin inCollection:topDraggingCollection]);

            });
            
            it(@"should not start dragging or call the data source if the point is outside of the collection view", ^{
                
                id draggingCollection = OCMProtocolMock(@protocol(I3Collection));
                id draggingDataSource = OCMProtocolMock(@protocol(I3DragDataSource));
                id collectionView = OCMPartialMock([[UIView alloc] init]);
                
                OCMStub([draggingCollection collectionView]).andReturn(collectionView);
                OCMStub([collectionView pointInside:dragOrigin withEvent:nil]).andReturn(NO);
                [[dragArena collections] addObject:draggingCollection];

                [[draggingDataSource reject] canItemBeDraggedAtPoint:dragOrigin inCollection:draggingCollection];
                [[draggingCollection reject] dragDataSource];
                
                [coordinator handlePan:coordinator.gestureRecognizer];
                
                expect(coordinator.currentDraggingCollection).to.beNil();
                expect(coordinator.currentDragOrigin).to.equal(CGPointZero);

            });
            
        });

        
        describe(@"stopping a drag", ^{

            /// Here we set up the coordinator as if its already executed a successful drag start
            /// and holds a reference to a dragging collection.
            /// @note that this setup is almost identical to how we setup the coordinator in most of
            /// the drag start tests
            
            __block id draggingCollection;
            __block id draggingDataSource;
            __block id collectionView;
            
            CGPoint dropOrigin = CGPointMake(50, 50);
            
            beforeEach(^{
                
                draggingCollection = OCMProtocolMock(@protocol(I3Collection));
                draggingDataSource = OCMProtocolMock(@protocol(I3DragDataSource));
                collectionView = OCMPartialMock([[UIView alloc] init]);
                
                [coordinator setValue:draggingCollection forKey:@"_currentDraggingCollection"];
                [coordinator setValue:[NSValue valueWithCGPoint:dragOrigin] forKey:@"_currentDragOrigin"];
                [collections addObject:draggingCollection];

                OCMStub([draggingCollection collectionView]).andReturn(collectionView);
                OCMStub([draggingCollection dragDataSource]).andReturn(draggingDataSource);
                OCMStub([panGestureRecognizer state]).andReturn(UIGestureRecognizerStateEnded);
                
            });

            afterEach(^{
                
                draggingCollection = OCMProtocolMock(@protocol(I3Collection));
                draggingDataSource = OCMProtocolMock(@protocol(I3DragDataSource));
                collectionView = OCMPartialMock([[UIView alloc] init]);
            
            });
            
            it(@"should do handle drops for all appropriate states", ^{
                
                OCMStub([panGestureRecognizer state]).andReturn(UIGestureRecognizerStateEnded);
                [coordinator handlePan:coordinator.gestureRecognizer];
                OCMVerify([renderDelegate renderResetFromPoint:dragOrigin fromCoordinator:coordinator]);
                
                OCMStub([panGestureRecognizer state]).andReturn(UIGestureRecognizerStateFailed);
                [coordinator handlePan:coordinator.gestureRecognizer];
                OCMVerify([renderDelegate renderResetFromPoint:dragOrigin fromCoordinator:coordinator]);
                
                OCMStub([panGestureRecognizer state]).andReturn(UIGestureRecognizerStateCancelled);
                [coordinator handlePan:coordinator.gestureRecognizer];
                OCMVerify([renderDelegate renderResetFromPoint:dragOrigin fromCoordinator:coordinator]);
                
            });
            
            it(@"should reset the drag and render if there was no valid destination", ^{
                
                [coordinator handlePan:coordinator.gestureRecognizer];
                
                expect(coordinator.currentDraggingCollection).to.beNil();
                expect(coordinator.currentDragOrigin).to.equal(CGPointZero);

                OCMVerify([renderDelegate renderResetFromPoint:dragOrigin fromCoordinator:coordinator]);
                
            });
            
            it(@"should delegate the drop to the top-most intersecting collection and none underneith", ^{
                
                id bottomCollection = OCMProtocolMock(@protocol(I3Collection));
                id bottomDraggingDataSource = OCMProtocolMock(@protocol(I3DragDataSource));
                id bottomCollectionView = OCMPartialMock([[UIView alloc] init]);
                
                id topCollection = OCMProtocolMock(@protocol(I3Collection));
                id topDraggingDataSource = OCMProtocolMock(@protocol(I3DragDataSource));
                id topCollectionView = OCMPartialMock([[UIView alloc] init]);

                [collections insertObjects:@[topCollection, bottomCollection] atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]];
                
                OCMStub([bottomCollection collectionView]).andReturn(bottomCollectionView);
                OCMStub([bottomCollection dragDataSource]).andReturn(bottomDraggingDataSource);
                OCMStub([topCollection collectionView]).andReturn(topCollectionView);
                OCMStub([topCollection dragDataSource]).andReturn(topDraggingDataSource);

                /// Set both of the new dragging views to respond positively to the drop
                
                OCMStub([bottomDraggingDataSource canItemAtPoint:dragOrigin fromCollection:draggingCollection beDroppedToPoint:dropOrigin inCollection:bottomCollection]).andReturn(YES);
                OCMStub([bottomCollectionView pointInside:dropOrigin withEvent:nil]).andReturn(YES);
                OCMStub([topDraggingDataSource canItemAtPoint:dragOrigin fromCollection:draggingCollection beDroppedToPoint:dropOrigin inCollection:topCollection]);
                OCMStub([topCollectionView pointInside:dropOrigin withEvent:nil]).andReturn(YES);
                
                [[bottomDraggingDataSource reject] dropItemAtPoint:dragOrigin fromCollection:draggingCollection toPoint:dropOrigin inCollection:bottomCollection];
                [[renderDelegate reject] renderDropOnCollection:bottomCollection atPoint:dropOrigin fromCoordinator:coordinator];

                [coordinator handlePan:coordinator.gestureRecognizer];

                OCMVerify([topDraggingDataSource renderDropOnCollection:topCollection atPoint:dropOrigin fromCoordinator:coordinator]);
                OCMVerify([renderDelegate renderDropOnCollection:topCollection atPoint:dropOrigin fromCoordinator:coordinator]);
                
            });
            
            it(@"should not delete and render reset if collection dropped outside but there is no data source", ^{
                
                OCMStub([collectionView pointInside:dragOrigin withEvent:nil]).andReturn(NO);
                OCMStub([draggingCollection dragDataSource]).andReturn(nil); /// @note Re-stubbing method
                
                [[draggingDataSource reject] deleteItemAtPoint:dropOrigin inCollection:[OCMArg any]];
                [coordinator handlePan:coordinator.gestureRecognizer];

                OCMVerify([draggingCollection dragDataSource]);
                OCMVerify([renderDelegate renderResetFromPoint:dropOrigin fromCoordinator:coordinator]);

            });
            
            it(@"should not delete and render reset if data source does not implement can delete selector", ^{

                id dragSource = OCMClassMock([I3DragDataSourceJustDelete class]);
                
                OCMStub([collectionView pointInside:touchPoint withEvent:nil]).andReturn(NO);
                OCMStub([draggingCollection dragDataSource]).andReturn(dragSource);
                
                [[dragSource reject] deleteItemAtPoint:touchPoint inCollection:[OCMArg any]];
                [coordinator handlePan:coordinator.gestureRecognizer];

                OCMVerify([renderDelegate renderResetFromPoint:touchPoint fromCoordinator:coordinator]);

            });
            
            it(@"should not delete and render reset if data source does not implement delete selector", ^{

                id dragSource = OCMClassMock([I3DragDataSourceJustCanDelete class]);
                
                OCMStub([collectionView pointInside:touchPoint withEvent:nil]).andReturn(NO);
                OCMStub([draggingCollection dragDataSource]).andReturn(dragSource);
                OCMStub([dragSource canItemAtPoint:touchPoint beDeletedIfDroppedOutsideOfCollection:draggingCollection atPoint:touchPoint]).andReturn(YES);
                
                [[dragSource reject] deleteItemAtPoint:touchPoint inCollection:[OCMArg any]];
                [coordinator handlePan:coordinator.gestureRecognizer];

                OCMVerify([renderDelegate renderResetFromPoint:touchPoint fromCoordinator:coordinator]);

            });
            
            it(@"should not delete and render reset if the item in the data source is not deleteable", ^{
            
                OCMStub([collectionView pointInside:touchPoint withEvent:nil]).andReturn(NO);
                OCMStub([draggingCollection dragDataSource]).andReturn(draggingDataSource);
                OCMStub([draggingDataSource canItemAtPoint:touchPoint beDeletedIfDroppedOutsideOfCollection:draggingCollection atPoint:touchPoint]).andReturn(NO);
                
                [[draggingDataSource reject] deleteItemAtPoint:touchPoint inCollection:[OCMArg any]];
                [coordinator handlePan:coordinator.gestureRecognizer];

                OCMVerify([draggingDataSource canItemAtPoint:touchPoint beDeletedIfDroppedOutsideOfCollection:draggingCollection atPoint:touchPoint]);
                OCMVerify([renderDelegate renderResetFromPoint:touchPoint fromCoordinator:coordinator]);

            });
            
            it(@"should delete item if the its deleteable under the data source", ^{
            
                OCMStub([collectionView pointInside:touchPoint withEvent:nil]).andReturn(NO);
                OCMStub([draggingCollection dragDataSource]).andReturn(draggingDataSource);
                OCMStub([draggingDataSource canItemAtPoint:touchPoint beDeletedIfDroppedOutsideOfCollection:draggingCollection atPoint:touchPoint]).andReturn(YES);

                [coordinator handlePan:coordinator.gestureRecognizer];

                OCMVerify([draggingDataSource deleteItemAtPoint:touchPoint inCollection:draggingCollection]);
                OCMVerify([renderDelegate renderDeletionAtPoint:touchPoint fromCoordinator:coordinator]);
                
            });
            
            it(@"should rearranging and render if we're drag/dropping on the same collection and the data source allows", ^{
                
                OCMStub([collectionView pointInside:touchPoint withEvent:nil]).andReturn(YES);
                OCMStub([draggingCollection dragDataSource]).andReturn(draggingDataSource);
                OCMStub([draggingDataSource canItemFromPoint:touchPoint beRearrangedWithItemAtPoint:touchPoint inCollection:draggingCollection]).andReturn(YES);

                [coordinator handlePan:coordinator.gestureRecognizer];
                
                OCMVerify([draggingDataSource rearrangeItemAtPoint:touchPoint withItemAtPoint:touchPoint inCollection:draggingCollection]);
                OCMVerify([draggingDataSource canItemFromPoint:touchPoint beRearrangedWithItemAtPoint:touchPoint inCollection:draggingCollection]);
                OCMVerify([renderDelegate renderRearrangeOnPoint:touchPoint fromCoordinator:coordinator]);
                
            });
            
            it(@"should not rearrange and render reset if there is no data source", ^{
                
                OCMStub([collectionView pointInside:touchPoint withEvent:nil]).andReturn(YES);

                [[draggingDataSource reject] rearrangeItemAtPoint:touchPoint withItemAtPoint:touchPoint inCollection:draggingCollection];
                [coordinator handlePan:coordinator.gestureRecognizer];
                
                OCMVerify([draggingCollection dragDataSource]);
                OCMVerify([renderDelegate renderResetFromPoint:touchPoint fromCoordinator:coordinator]);

            });
            
            it(@"should not rearrange and render reset if the data source does not implement can rearrange", ^{

                id dragSource = OCMClassMock([I3DragDataSourceJustRearrange class]);
                
                OCMStub([collectionView pointInside:touchPoint withEvent:nil]).andReturn(YES);
                OCMStub([draggingCollection dragDataSource]).andReturn(dragSource);
                
                [[dragSource reject] rearrangeItemAtPoint:touchPoint withItemAtPoint:touchPoint inCollection:draggingCollection];
                [coordinator handlePan:coordinator.gestureRecognizer];

                OCMVerify([renderDelegate renderResetFromPoint:touchPoint fromCoordinator:coordinator]);

            });
            
            it(@"should not rearrange and render reset if the data source does not implement rearrange method", ^{
            
                id dragSource = OCMClassMock([I3DragDataSourceJustCanRearrange class]);

                OCMStub([collectionView pointInside:touchPoint withEvent:nil]).andReturn(YES);
                OCMStub([draggingCollection dragDataSource]).andReturn(dragSource);
                OCMStub([dragSource canItemFromPoint:touchPoint beRearrangedWithItemAtPoint:touchPoint inCollection:draggingCollection]).andReturn(YES);
                
                [[dragSource reject] rearrangeItemAtPoint:touchPoint withItemAtPoint:touchPoint inCollection:draggingCollection];
                [coordinator handlePan:coordinator.gestureRecognizer];
                
                OCMVerify([renderDelegate renderResetFromPoint:touchPoint fromCoordinator:coordinator]);

            });
            
            it(@"should not rearrange and render reset if the data source specifies the items as un-rearrangeable", ^{

                OCMStub([collectionView pointInside:touchPoint withEvent:nil]).andReturn(YES);
                OCMStub([draggingCollection dragDataSource]).andReturn(draggingDataSource);
                OCMStub([draggingDataSource canItemFromPoint:touchPoint beRearrangedWithItemAtPoint:touchPoint inCollection:draggingCollection]).andReturn(NO);
                
                [[draggingDataSource reject] rearrangeItemAtPoint:touchPoint withItemAtPoint:touchPoint inCollection:draggingCollection];
                [coordinator handlePan:coordinator.gestureRecognizer];
                
                OCMVerify([draggingDataSource canItemFromPoint:touchPoint beRearrangedWithItemAtPoint:touchPoint inCollection:draggingCollection]);
                OCMVerify([renderDelegate renderResetFromPoint:touchPoint fromCoordinator:coordinator]);

            });
            
            it(@"should not rearrange and render reset if we're dropping on the same item in the collection", ^{
            
                /// @todo Get this to pass
                
                CGPoint rearrangeDropPoint = CGPointMake(20, 20);
                
                OCMStub([panGestureRecognizer locationInView:collectionView]).andReturn(rearrangeDropPoint);
                OCMStub([collectionView pointInside:rearrangeDropPoint withEvent:nil]).andReturn(YES);

                NSLog(@"Trying to get the location: %@", NSStringFromCGPoint([panGestureRecognizer locationInView:collectionView]));
                
                OCMStub([draggingCollection dragDataSource]).andReturn(draggingDataSource);
                OCMStub([draggingDataSource canItemFromPoint:touchPoint beRearrangedWithItemAtPoint:rearrangeDropPoint inCollection:draggingCollection]).andReturn(YES);
                
                UIView *commonCollectionItem = [[UIView alloc] init];
                
                OCMStub([draggingCollection itemAtPoint:rearrangeDropPoint]).andReturn(commonCollectionItem);
                OCMStub([draggingCollection itemAtPoint:touchPoint]).andReturn(commonCollectionItem);
                
                [[draggingDataSource reject] rearrangeItemAtPoint:touchPoint withItemAtPoint:rearrangeDropPoint inCollection:draggingCollection];
                [coordinator handlePan:coordinator.gestureRecognizer];
                
                OCMVerify([draggingCollection itemAtPoint:rearrangeDropPoint]);
                OCMVerify([draggingCollection itemAtPoint:touchPoint]);
                
            });
            
            it(@"should not rearrange and render reset if we're dropping on an invalid location in the collection", ^{
                
                expect(NO).to.beTruthy;
                /// @todo ...
            });
            
            it(@"should exchange between collections if we're drag/dropping between different collections and data source allows", ^{
            
                id dstCollection = OCMProtocolMock(@protocol(I3Collection));
                OCMStub([dstCollection collectionView]).andReturn(collectionView);
                OCMStub([collectionView pointInside:touchPoint withEvent:nil]).andReturn(YES);
                [collections insertObject:dstCollection atIndex:0];
                
                OCMStub([draggingCollection dragDataSource]).andReturn(draggingDataSource);
                OCMStub([draggingDataSource canItemAtPoint:touchPoint fromCollection:draggingCollection beDroppedToPoint:touchPoint inCollection:dstCollection]).andReturn(YES);
                
                [coordinator handlePan:coordinator.gestureRecognizer];
                
                OCMVerify([draggingDataSource canItemAtPoint:touchPoint fromCollection:draggingCollection beDroppedToPoint:touchPoint inCollection:dstCollection]);
                OCMVerify([draggingDataSource dropItemAtPoint:touchPoint fromCollection:draggingCollection toPoint:touchPoint inCollection:dstCollection]);
                OCMVerify([renderDelegate renderDropOnCollection:dstCollection atPoint:touchPoint fromCoordinator:coordinator]);

            });
            
            it(@"should not exchange between and render reset if data source is not specified", ^{
            
                id dstCollection = OCMProtocolMock(@protocol(I3Collection));
                OCMStub([dstCollection collectionView]).andReturn(collectionView);
                OCMStub([collectionView pointInside:touchPoint withEvent:nil]).andReturn(YES);
                [collections insertObject:dstCollection atIndex:0];
                
                [[draggingDataSource reject] dropItemAtPoint:touchPoint fromCollection:draggingCollection toPoint:touchPoint inCollection:dstCollection];
                [coordinator handlePan:coordinator.gestureRecognizer];
                
                OCMVerify([draggingCollection dragDataSource]);
                OCMVerify([renderDelegate renderResetFromPoint:touchPoint fromCoordinator:coordinator]);

            });
            
            it(@"should not exchange between and render reset if data source does not implement drop selector", ^{

                id dstCollection = OCMProtocolMock(@protocol(I3Collection));
                OCMStub([dstCollection collectionView]).andReturn(collectionView);
                OCMStub([collectionView pointInside:touchPoint withEvent:nil]).andReturn(YES);
                [collections insertObject:dstCollection atIndex:0];
                
                id dragSource = OCMClassMock([I3DragDataSourceJustCanDrop class]);
                OCMStub([dragSource canItemAtPoint:touchPoint fromCollection:draggingCollection beDroppedToPoint:touchPoint inCollection:dstCollection]).andReturn(YES);
                OCMStub([draggingCollection dragDataSource]).andReturn(dragSource);
                
                [[draggingDataSource reject] dropItemAtPoint:touchPoint fromCollection:draggingCollection toPoint:touchPoint inCollection:dstCollection];
                [coordinator handlePan:coordinator.gestureRecognizer];
                OCMVerify([renderDelegate renderResetFromPoint:touchPoint fromCoordinator:coordinator]);

            });
            
            it(@"should not exchange between and render reset if data source does not implement can drop selector", ^{

                id dstCollection = OCMProtocolMock(@protocol(I3Collection));
                OCMStub([dstCollection collectionView]).andReturn(collectionView);
                OCMStub([collectionView pointInside:touchPoint withEvent:nil]).andReturn(YES);
                [collections insertObject:dstCollection atIndex:0];
                
                id dragSource = OCMClassMock([I3DragDataSourceJustDrop class]);
                OCMStub([draggingCollection dragDataSource]).andReturn(dragSource);
                
                [[draggingDataSource reject] dropItemAtPoint:touchPoint fromCollection:draggingCollection toPoint:touchPoint inCollection:dstCollection];
                [coordinator handlePan:coordinator.gestureRecognizer];

                OCMVerify([renderDelegate renderResetFromPoint:touchPoint fromCoordinator:coordinator]);

            });
            
            it(@"should not exchange between and render reset if data source specifies that cell is not exchangeable", ^{
                
                id dstCollection = OCMProtocolMock(@protocol(I3Collection));
                OCMStub([dstCollection collectionView]).andReturn(collectionView);
                OCMStub([collectionView pointInside:touchPoint withEvent:nil]).andReturn(YES);
                [collections insertObject:dstCollection atIndex:0];
                
                OCMStub([draggingDataSource canItemAtPoint:touchPoint fromCollection:draggingCollection beDroppedToPoint:touchPoint inCollection:dstCollection]).andReturn(NO);
                OCMStub([draggingCollection dragDataSource]).andReturn(draggingDataSource);
                
                [[draggingDataSource reject] dropItemAtPoint:touchPoint fromCollection:draggingCollection toPoint:touchPoint inCollection:dstCollection];
                [coordinator handlePan:coordinator.gestureRecognizer];

                OCMVerify([renderDelegate renderResetFromPoint:touchPoint fromCoordinator:coordinator]);

            });
            
            it(@"should not exchange and render reset if we're dropping on an invalid location in the dst collection", ^{
                
                expect(NO).to.beTruthy;
                /// @todo ...
            });
            
        });
        
        
        /// @note This describes different behaviour of the above describe block in that it
        /// it defines how the gesture should respond to the stopping of a drag that was never
        /// started in a valid state. This might occur, for example, if we drag from an empty area
        /// in a collection.
        
        describe(@"stopping a pan gesture", ^{
            
            it(@"should do nothing if no collection is currently being dragged", ^{
                
                [[renderDelegate reject] renderResetFromPoint:dragOrigin fromCoordinator:coordinator];
                [coordinator handlePan:coordinator.gestureRecognizer];
                
            });
            
        });

        describe(@"dragging", ^{
            
            it(@"should do nothing if no collection is current being dragged", ^{
                
                [[renderDelegate reject] renderDraggingFromCoordinator:coordinator];
                [coordinator handlePan:coordinator.gestureRecognizer];
                
            });
            
            it(@"should render dragging", ^{
                
                id draggingCollection = OCMProtocolMock(@protocol(I3Collection));
                
                [coordinator setValue:draggingCollection forKey:@"_currentDraggingCollection"];
                [coordinator setValue:[NSValue valueWithCGPoint:touchPoint] forKey:@"_currentDragOrigin"];
                
                OCMStub([panGestureRecognizer state]).andReturn(UIGestureRecognizerStateChanged);
                
                [coordinator handlePan:coordinator.gestureRecognizer];
                
                OCMVerify([renderDelegate renderDraggingFromCoordinator:coordinator]);
                
            });
            
        });
        
    });

SpecEnd
