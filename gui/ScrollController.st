StandardSystemController subclass: 'ScrollController'
  instanceVariableNames: 'scrollBar marker scrollHeight markerHeight markerTop hiddenArea viewDelta'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! ScrollController methodsFor: 'control' !

initialize
    super initialize.
    redButtonMenu <- nil.
    yellowButtonMenu <- nil.
    blueButtonMenu <- nil.
    markerTop <- 1
!

isControlActive
    ^status ~= #inactive and:
        [self viewHasCursor
	    and: [ Sensor blueButtonPressed not ] ]
!

controlInitialize
    | temp |
    view isNil
        ifTrue: [ ^ self ].
    " Compute how big to make scroll bar. "
    scrollBar <- view insetBox translateBy: (30 @ 0).
    temp <- scrollBar extent.
    temp x: 30.
    scrollBar <- Rectangle origin: scrollBar origin extent: temp.
    scrollHeight <- scrollBar height.
    view fullHeight == 0
	ifTrue: [
	    markerHeight <- 1 ]
	ifFalse: [
	    markerHeight <- ((scrollHeight * scrollHeight) / view fullHeight)
                          truncated
	].
    markerHeight > (scrollHeight - 2)
        ifTrue: [ markerHeight <- scrollHeight - 2 ].
    markerHeight < 1
        ifTrue: [ markerHeight <- 1 ].
    markerTop <- view scrollPosition * markerHeight // scrollHeight.
    markerTop > (scrollHeight - (markerHeight + 1))
        ifTrue: [ markerTop <- scrollHeight - (markerHeight + 1) ].
    markerTop < 1
        ifTrue: [ markerTop <- 1 ].
    marker <- self computeMarkerRegion.
    " Save area under where we are going to draw "
    hiddenArea <- Form fromDisplay: scrollBar.
    hiddenArea offset: scrollBar origin.
    "make scrollbar visible"
    Display white: scrollBar.
    Display border: scrollBar width: 1.
    Display gray: marker
!

controlTerminate
    hiddenArea display
!

controlActivity
    self scrollBarContainsCursor
	  ifTrue: [ ^self scroll ].
    super controlActivity
! !

! ScrollController methodsFor: 'scrolling' !

scroll
    | xPosition oldCursor |
    oldCursor <- Sensor currentCursor.
    [ self scrollBarContainsCursor ]
        whileTrue: [ 
	    xPosition <- Sensor mousePoint x.
	    xPosition < marker left
	        ifTrue: [ self scrollUp ]
		ifFalse: [ xPosition < marker right
		               ifTrue: [ self scrollAbsolute ]
			       ifFalse: [ self scrollDown ] ].
	    Sensor waitMouse.
        ].
     Sensor currentCursor: oldCursor.
!

canScroll
    ^markerHeight < (scrollHeight - 2)
!

scrollView
    self scrollView: viewDelta
!

scrollView: anInteger
    view isNil ifFalse: [
        view scrollTo: anInteger.
        viewDelta <- viewDelta - anInteger
    ]
!

viewDelta
    ^viewDelta
! !

! ScrollController methodsFor: 'private' !

moveMarker
    self moveMarker: self markerDelta negated
!

moveMarker: anInteger
    | oldMarker whiteMarker grayMarker |
    oldMarker <- marker.
    markerTop <- markerTop + anInteger.
    marker <- self computeMarkerRegion.
    oldMarker top == marker top
        ifTrue: [ ^nil ].
    (oldMarker top > marker bottom
        or: [ oldMarker bottom < marker top ])
        ifTrue: [ whiteMarker <- oldMarker.
	          grayMarker <- marker ]
        ifFalse:
	   [ oldMarker top > marker top
                  ifTrue: [ whiteMarker <- marker bottomLeft
	                              corner: oldMarker corner.
		            grayMarker <- marker origin
		                      corner: oldMarker topRight ]
                  ifFalse: [ grayMarker <- oldMarker bottomLeft
	                              corner: marker corner.
		             whiteMarker <- oldMarker origin
		                      corner: marker topRight ] ].
    Display white: whiteMarker.
    Display gray: grayMarker
!

markerDelta
    ^(viewDelta * markerHeight / scrollHeight) truncated
!

computeMarkerRegion
    ^scrollBar origin + (10 @ markerTop)
                extent: 10 @ markerHeight
!

markerRegion: aRectangle
    markerTop <- aRectangle top.
    markerHeight <- aRectangle height.
    self moveMarker: 0
!

scrollAbsolute
    | moveDelta |
    Sensor currentCursor: Cursor menu.
    (self canScroll and: [ Sensor anyButtonPressed ])
      ifTrue:
	[ [ Sensor anyButtonPressed ]
	   whileTrue:
	    [ moveDelta <- (Sensor mousePoint y - marker center y)
	                          truncated.
	      markerTop + moveDelta > 0
		  ifFalse: [ moveDelta <- 1 - markerTop ].
	      markerTop + moveDelta + markerHeight < scrollHeight
		  ifFalse: [ moveDelta <- scrollHeight -
		                     (markerTop + markerHeight + 1) ].
	      moveDelta == 0
		ifFalse:
		 [ markerTop <- markerTop + moveDelta.
		   viewDelta <- (markerTop - 1 * scrollHeight / markerHeight)
		                     truncated.
		   self moveMarker: 0.
		   self scrollView ].
	       Sensor waitMouse
	   ]
	 ]
!

scrollDown
    | moveDelta |
    Sensor currentCursor: Cursor up.
    (self canScroll and: [ Sensor anyButtonPressed ])
      ifTrue:
        [ Sensor waitNoButton.
	  viewDelta <- self scrollAmount.
	  moveDelta <- viewDelta * markerHeight / scrollHeight.
	  markerTop + moveDelta > 0
	      ifFalse: [ moveDelta <- 1 - markerTop ].
	  markerTop + moveDelta + markerHeight < scrollHeight
	      ifFalse: [ moveDelta <- scrollHeight -
		                     (markerTop + markerHeight + 1) ].
	  markerTop <- (markerTop + moveDelta) truncated.
	  viewDelta <- (markerTop - 1 * scrollHeight / markerHeight)
	                    truncated.
	  self moveMarker: 0.
	  self scrollView
	  ]
!

scrollUp
    | moveDelta |
    Sensor currentCursor: Cursor down.
    (self canScroll and: [ Sensor anyButtonPressed ])
      ifTrue:
        [ Sensor waitNoButton.
	  viewDelta <- self scrollAmount negated.
	  moveDelta <- viewDelta * markerHeight / scrollHeight.
	  markerTop + moveDelta > 0
	      ifFalse: [ moveDelta <- 1 - markerTop ].
	  markerTop + moveDelta + markerHeight < scrollHeight
	      ifFalse: [ moveDelta <- scrollHeight -
		                     (markerTop + markerHeight + 1) ].
	  markerTop <- (markerTop + moveDelta) truncated.
          viewDelta <- (markerTop - 1 * scrollHeight / markerHeight)
	                    truncated.
	  self moveMarker: 0.
	  self scrollView
     	  ]
!

scrollAmount
    ^(Sensor mousePoint y - scrollBar top) truncated
! !

! ScrollController methodsFor: 'cursors' !

markerContainsCursor
    marker isNil ifTrue: [ ^false ].
    ^marker containsPoint: Sensor mousePoint
!

scrollBarContainsCursor
    scrollBar isNil ifTrue: [ ^false ].
    ^scrollBar containsPoint: Sensor mousePoint
!

viewHasCursor
    view isNil ifTrue: [ ^false ].
    ^(view containsPoint: Sensor mousePoint)
          or: [ self scrollBarContainsCursor ]
! !

