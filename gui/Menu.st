Object subclass: 'Menu'
  instanceVariableNames: 'menuForm hiddenArea currentLine selectors frame border offset lineHeight'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! Menu class methodsFor: 'instance creation' !

labelArray: labelArray lines: lineArray selectors: selectorArray
    ^self new labelArray: labelArray
              lines: lineArray
	      selectors: selectorArray; yourself
! !

! Menu methodsFor: 'initialising' !

labelArray: labelArray lines: lineArray selectors: selectorArray
    | width shadow aRectangle extent |
    selectors <- selectorArray.
    shadow <- 3.      "Width of shadow on right and bottom."
    border <- 2.      "Space around text."
    lineHeight <- 0.
    width <- 0.
    labelArray do:
        [ :string | extent <- string displayExtent.
		width <- width max: extent x.
		lineHeight <- lineHeight max: extent y ].
    frame <- width @ (labelArray size * lineHeight).
    menuForm <- Form new
                   extent: frame + (shadow + (2 * border))
	           offset: 0@0.
    "Clear menuForm"
    menuForm white.
    "Put border round menuForm"
    aRectangle <- 0@0 extent: frame + (2 * border).
    menuForm border: aRectangle width: 1.
    "Add a shadow"
    aRectangle <- aRectangle width @ border
                         extent: shadow @ lineHeight + border.
    menuForm fill: aRectangle rule: Form over mask: nil.
    aRectangle <- border @ lineHeight + (2 * border)
                      extent: width + (shadow + border) @ shadow.
    menuForm fill: aRectangle rule: Form over mask: nil.
    1 to: labelArray size do:
        [ :x | (labelArray at: x)
	            displayOn: menuForm
		    at: border @ (((x - 1) * lineHeight) + border) ].
    lineArray do:
        [ :x | menuForm fill: (border @ ((x * lineHeight) + 1 + border)
                                         extent: width @ 1)
			rule: Form over
			mask: nil ]
! !

! Menu methodsFor: 'displaying' !

displayAt: aPoint
    | aRectangle |
    aRectangle <- aPoint extent: menuForm extent.
    offset <- aPoint + border.
    hiddenArea <- Form fromDisplay: aRectangle.
    hiddenArea offset: aPoint.
    menuForm displayAt: aPoint
!

disappear
    hiddenArea display.
    hiddenArea <- nil
!

reverse: aLine
    aLine isNil
        ifTrue: [ ^nil ].    "currentLine could be nil"
    Display reverse: (offset x @ (offset y + ((aLine - 1) * lineHeight))
                      extent: frame x @ lineHeight)
!

showLineAt: aPoint
    | newLine |
    (self containsPoint: aPoint)
        ifFalse: [ self reverse: currentLine.
	           currentLine <- nil.
		   ^nil ].
    newLine <- (aPoint y - offset y) // lineHeight + 1.
    newLine == currentLine
        ifFalse: [ self reverse: currentLine.
	           currentLine <- newLine.
		   self reverse: currentLine ]
!

popUpAt: aPoint for: anObject
    | selection |
    selection <- self popUpAt: aPoint.
    selection notNil
        ifTrue: [ anObject preform: selection ]
!

popUpAt: aPoint
    | position oldPosition |
    self displayAt: aPoint.
    currentLine <- nil.
    oldPosition <- 0@0.
    Cursor menu showWhile: [
       [ Sensor waitMouse. Sensor anyButtonPressed ]
           whileTrue: [ position <- Sensor mousePoint.
	                position = oldPosition
		            ifFalse: [ oldPosition <- position.
			               self showLineAt: position ] ].
       self disappear
    ].
    currentLine isNil
        ifTrue: [ ^nil ]
	ifFalse: [ ^selectors at: currentLine ]
! !

! Menu methodsFor: 'accessing' !

containsPoint: aPoint
    ^(aPoint x >= offset x)
        and: [ (aPoint y >= offset y)
	           and: [ (aPoint x < (offset + frame) x)
		              and: [ aPoint y < (offset + frame) y ] ] ]
! !

