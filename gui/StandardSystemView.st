View subclass: 'StandardSystemView'
  instanceVariableNames: 'label labelForm'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! StandardSystemView methodsFor: 'initialise-release' !

label: aString
    | aForm |
    label <- aString.
    aForm <- Form fromString: label.
    labelForm <- Form extent: aForm extent + 4.
    labelForm border: labelForm boundingBox width: 1.
    aForm displayOn: labelForm at: 2@2
! !

! StandardSystemView methodsFor: 'accessing' !

defaultControllerClass
    ^StandardSystemController
!

label
    ^ label
!

containsPoint: aPoint
    ^((labelForm boundingBox
	           translateBy: offset - (0 @ labelForm height))
         containsPoint: aPoint)
	 or: [ controller status ~= #collapsed
	           and: [ super containsPoint: aPoint ] ]
! !

! StandardSystemView methodsFor: 'displaying' !

display
    labelForm isNil
        ifTrue: [ self label: 'Demo View' ].
    labelForm displayAt: offset - (0 @ labelForm height).
    controller status ~= #collapsed
        ifTrue: [ super display ]
!

emphasize
    self emphasizeView.
    controller status ~= #collapsed
        ifTrue: [ self emphasizeSubViews ]
!

emphasizeView
    | labelInset |
    labelInset <- labelForm boundingBox.
    labelInset moveBy: offset - (0 @ labelForm height).
    labelInset <- labelInset insetBy: 2.
    Display reverse: labelInset
!

deEmphasizeView
    | labelInset |
    labelInset <- labelForm boundingBox.
    labelInset moveBy: offset - (0 @ labelForm height).
    labelInset <- labelInset insetBy: 2.
    Display reverse: labelInset
! !

! StandardSystemView methodsFor: 'window access' !

defaultWindow
    | aRectangle |
    window isNil ifTrue: [ 
	aRectangle <- self minimumSize. 
	aRectangle isNil ifTrue: [ ^ Rectangle fromUser ]
			 ifFalse: [ ^ Rectangle fromUserMin: aRectangle ]
    ].
    ^ window
!

move
    self setWindow: self window originFromUser
!

resize
    | aRectangle aWindow |
    aRectangle <- self minimumSize. 
    aWindow <- self window.
    aRectangle isNil ifTrue: [ aWindow cornerFromUser ]
		 ifFalse: [ aWindow cornerFromUserMin: aRectangle ].
    self setWindow: aWindow.
!

open
    model notNil ifTrue: [ self update ].
    ScheduledControllers scheduleActive: self controller
! !

