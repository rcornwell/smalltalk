" Model View Controller methods for Smalltalk. "

" $Id: $ "

"
 $Log: $

"

"place holders for some global objects"
Smalltalk at: #SystemFontHeight put: 10.
Smalltalk at: #SystemFontWidth put: 10.
Smalltalk at: #ScheduledControllers put: nil.

Object subclass: 'WindowTranslation'
  instanceVariableNames: 'translation scale'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! WindowTranslation class methodsFor: 'instance creation' !

translation: aOffset scale: aScale
   ^ super new translation: aOffset scale: aScale.
!

identity
   ^ super new translation: 0@0 scale: 1.0@1.0
! !

! WindowTranslation methodsFor: 'modifying' !

translation: aOffset
   translation <- aOffset
!

scale: aRectangle
   scale <- aRectangle
!

translation: aOffset scale: aScale
   translation <- aOffset.
   scale <- aScale
! !

! WindowTranslation methodsFor: 'translation' !

toDisplay: aObject
   | newObject |
   stderr nextPutAll: 'toDisplay '.
   translation printOn: stderr. stderr space.
   scale printOn: stderr. stderr space.
   aObject printOn: stderr. 
   newObject <- aObject scaleBy: scale.
   newObject <-  newObject translatedBy: translation
   newObject printOn: stderr. stderr nl.
   ^ newObject
!

fromDisplay: aObject
   | newObject |
   newObject <- aObject translatedBy: ((translation x negate)@
				       (translation y negate)).
   newObject <- newObject scaleBy: (1.0 / (scale x)@
				       (1.0 / (scale y))).
   ^ newObject
 
! !

! WindowTranslation methodsFor: 'accessing' !

translation
    ^ translation
!

scale
    ^ scale
!

rectangle
    ^ Rectangle origin: translation extent: scale

! !

Object subclass: 'ControlManager'
  instanceVariableNames: 'activeController controllers activeControllerProcess screenController'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! ControlManager class methodsFor: 'instance creation' !

new
    ^super new initialize; yourself
! !

! ControlManager methodsFor: 'initialising' !

initialize
    screenController <- Display controller.
    activeController <- nil.
    activeControllerProcess <- nil.
    controllers <- OrderedCollection new
! !

! ControlManager methodsFor: 'restoring display' !

restore
    Display fill: Display boundingBox
            rule: Form over
	    mask: Form lightGray.
    controllers isNil
        ifTrue: [ ^nil ].
    screenController view display.
    controllers reverseDo:
        [ :controller | controller ~~ screenController
	                    ifTrue: [ controller view display ] ]
! !

! ControlManager methodsFor: 'querying active controller' !

activeController
    ^activeController
!

activeControllerProcess
    ^activeControllerProcess
!

inActiveControllerProcess
    ^Processor activeProcess == activeControllerProcess
! !

! ControlManager methodsFor: 'querying controllers' !

scheduledControllers
    ^controllers copy
!

promote: aScheduledController
    | index newControllers |
    index <- controllers indexOf: aScheduledController.
    (index isNil or: [ index == 0 ])
        ifTrue: [ ^nil ].
    newControllers <- OrderedCollection new: controllers basicSize.
    1 to: index - 1 do: [ :i | newControllers add: (controllers at: i) ].
    index + 1 to: controllers size do:
        [ :i | newControllers add: (controllers at: i) ].
    newControllers addFirst: aScheduledController.
    controllers become: newControllers
!

pullBottomToTop
    controllers reverseDo:
        [ :controller | controller isControlWanted
	                    ifTrue: [ ^self promote: controller ] ]
!

activeController: aScheduledController
    | index |
    (activeController notNil
        and: [ activeController view notNil ])
	  ifTrue: [ activeController view deEmphasize ].
    index <- controllers indexOf: aScheduledController.
    (index isNil or: [ index == 0 ])
        ifTrue: [ controllers addFirst: aScheduledController ]
	ifFalse: [ self promote: aScheduledController ].
    activeController <- aScheduledController.
    activeControllerProcess <- [ activeController startUp.
                                 self searchForActiveController ].
    activeControllerProcess forkAt: (Processor userSchedulingPriority)
!

unschedule: aScheduledController
    | index newControllers |
    index <- controllers indexOf: aScheduledController.
    (index isNil or: [ index == 0 ])
        ifTrue: [ ^nil ].
    newControllers <- OrderedCollection new: controllers basicSize.
    1 to: index - 1 do: [ :i | newControllers add: (controllers at: i) ].
    index + 1 to: controllers size do:
        [ :i | newControllers add: (controllers at: i) ].
    controllers become: newControllers.
    aScheduledController = activeController
        ifTrue: [ activeController <- nil.
	          activeControllerProcess <- nil ].
    self restore
! !

! ControlManager methodsFor: 'scheduling controllers' !

schedulePassive: aController
    controllers addFirst: aController
!

scheduleActive: aController
    self activeController: aController.
    Processor terminateActive
!

sceduleActiveNoTerminate: aController
    self activeController: aController
!

scheduleOnBottom: aController
    controllers addLast: aController
! !

! ControlManager methodsFor: 'scheduling controllers' !

searchForActiveController
    | aController |
    activeController <- nil.
    activeControllerProcess <- nil.
    [ aController <-
          controllers
	      detect: [ :candidate |
	                    candidate isControlWanted
			        and: [ candidate ~~ screenController ] ]
	      ifNone: [ screenController isControlWanted
			    ifTrue: [ screenController ]
			    ifFalse: [ nil ] ].
      aController isNil ] whileTrue: [ Sensor waitEvent ].
    self activeController: aController.
    Processor terminateActive
! !

Object subclass: 'Controller'
  instanceVariableNames: 'model view status'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! Controller class methodsFor: 'instance creation' !

new
    ^super new initialize; yourself
! !

! Controller methodsFor: 'initialise-release' !

initialize
    self release.
    model <- nil.
    view <- nil
!

release
    model isNil
        ifFalse: [ model removeDependent: self ].
    view <- nil     "don't release view as it is view's job
                     to release controller"
! !

! Controller methodsFor: 'accessing' !

model
    ^model
!

model: aModel
    model <- aModel.
    ^self
!

view
    ^view
!

view: aView
    view <- aView
!

status
    ^status
! !

! Controller methodsFor: 'control' !

isControlWanted
    ^self viewHasCursor
!

isControlActive
    ^self viewHasCursor and: [ Sensor blueButtonPressed not ]
!

startUp
    self controlInitialize.
    self controlLoop.
    self controlTerminate
!

controlInitialize
    ^self
!

controlLoop
    [ self isControlActive ]
        whileTrue: [ 
	Processor yield. 
	Sensor waitEvent. 
	self controlActivity ]
!

controlTerminate
    ^self
!

controlActivity
    self controlToNextLevel
!

controlToNextLevel
    | aView |
    view isNil
        ifTrue: [ ^nil ].
    aView <- view subViewWantingControl.
    aView ~~ nil ifTrue: [ aView controller startUp ]
! !

! Controller methodsFor: 'cursors' !

centerCursorInView
    ^nil
!

viewHasCursor
    view isNil
        ifTrue: [ ^false ].
    ^view containsPoint: Sensor mousePoint
! !

Controller subclass: 'ScreenController'
  instanceVariableNames: ''
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! ScreenController methodsFor: 'control' !

isControlWanted
    | cw |
    cw <- super isControlWanted.
    ^ cw and: [ Sensor redButtonPressed ]
!

isControlActive
    | cw |
    cw <- super isControlWanted.
    ^ cw and: [ Sensor redButtonPressed ]
!

controlActivity
    view preformMenu
! !

! ScreenController methodsFor: 'cursors' !

viewHasCursor
    ^true
! !

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

Controller subclass: 'MouseMenuController'
  instanceVariableNames: 'redButtonMenu yellowButtonMenu blueButtonMenu redMenuNotify yellowMenuNotify blueMenuNotify'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Windows'
!


! MouseMenuController methodsFor: 'control' !

isControlActive
    ^self viewHasCursor
!

controlActivity
    Sensor redButtonPressed
        ifTrue: [ ^self redButtonActivity ].
    Sensor yellowButtonPressed
        ifTrue: [ ^self yellowButtonActivity ].
    Sensor blueButtonPressed
        ifTrue: [ ^self blueButtonActivity ].
    self controlToNextLevel
!

redButtonActivity
    | menu |
    redMenuNotify isNil
        ifTrue: [ redMenuNotify <- self ].
    menu <- redButtonMenu.
    (menu isKindOf: Symbol)
	ifTrue: [ menu <- redMenuNotify preform: menu ].
    (menu isKindOf: Menu)
        ifTrue: [ menu popUpAt: Sensor mousePoint for: redMenuNotify ]
!

yellowButtonActivity
    | menu |
    yellowMenuNotify isNil
        ifTrue: [ yellowMenuNotify <- self ].
    menu <- yellowButtonMenu.
    (menu isKindOf: Symbol)
	ifTrue: [ menu <- yellowMenuNotify preform: menu ].
    (menu isKindOf: Menu)
        ifTrue: [ menu popUpAt: Sensor mousePoint for: yellowMenuNotify ]
!

blueButtonActivity
    | menu |
    blueMenuNotify isNil
        ifTrue: [ blueMenuNotify <- self ].
    menu <- blueButtonMenu.
    (menu isKindOf: Symbol)
	ifTrue: [ menu <- blueMenuNotify preform: menu ].
    (menu isKindOf: Menu)
        ifTrue: [ menu popUpAt: Sensor mousePoint for: blueMenuNotify ]
! !

! MouseMenuController methodsFor: 'menu setting' !

redButtonMenu: aMenu
    self redButtonMenu: aMenu notifying: self
!

yellowButtonMenu: aMenu
    self yellowButtonMenu: aMenu notifying: self
!

blueButtonMenu: aMenu
    self blueButtonMenu: aMenu notifying: self
!

redButtonMenu: aMenu notifying: anObject
    redButtonMenu <- aMenu.
    redMenuNotify <- anObject
!

yellowButtonMenu: aMenu notifying: anObject
    yellowButtonMenu <- aMenu.
    yellowMenuNotify <- anObject
!

blueButtonMenu: aMenu notifying: anObject
    blueButtonMenu <- aMenu.
    blueMenuNotify <- anObject
! !

MouseMenuController subclass: 'StandardSystemController'
  instanceVariableNames: ''
  classVariableNames: 'OpenMenu CollapsedMenu'
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! StandardSystemController class methodsFor: 'initialising' !

initMenus
    OpenMenu <- Menu labelArray: #('move' 'close' 'collapse'
                                   'expand' 'under')
	             lines: #()
		     selectors: #(move close collapse
		                  expand under).
    CollapsedMenu <- Menu labelArray: #('move' 'close' 'open'
                                        'expand' 'under')
			  lines: #()
			  selectors: #(move close open
			               expand under)
! !

! StandardSystemController methodsFor: 'control' !

initialize
    super initialize.
    self initializeBlueButtonMenu.
    status <- #active.
!

isControlActive
    ^status ~= #inactive and:
        [self viewHasCursor
            or: [ Sensor noButtonPressed ] ]
!

controlInitialize
    view display.
    view emphasize
!

controlTerminate
    view isNil
        ifFalse: [ view deEmphasize ]
! !

! StandardSystemController methodsFor: 'initialisation' !

initializeBlueButtonMenu
    self blueButtonMenu: OpenMenu
! !

! StandardSystemController methodsFor: 'blue button menu items' !

move
!

close
    view release.
    self release.
    status <- #inactive.
    ScheduledControllers unschedule: self
!

collapse
    status <- #collapsed.
    self blueButtonMenu: CollapsedMenu.
    ScheduledControllers restore.
    ScheduledControllers searchForActiveController
!

expand
!

under
!

open
    status <- #active.
    self blueButtonMenu: OpenMenu.
    ScheduledControllers restore.
    ScheduledControllers searchForActiveController
! !

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
    view isNil
        ifTrue: [ ^nil ].
    scrollHeight <- view height.
    scrollBar <- view offset - (30@0)
                   extent: (30 @ scrollHeight).
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
    hiddenArea <- Form fromDisplay: scrollBar.
    hiddenArea offset: scrollBar origin.
    Display white: scrollBar.
    Display border: scrollBar width: 1.
    Display gray: marker
    "make scrollbar visible"
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
        whileTrue:
	  [ Sensor waitMouse.
	    xPosition <- Sensor mousePoint x.
	    xPosition < marker left
	        ifTrue: [ self scrollUp ]
		ifFalse: [ xPosition < marker right
		               ifTrue: [ self scrollAbsolute ]
			       ifFalse: [ self scrollDown ]. ]. ].
     Sensor currentCursor: oldCursor.
!

canScroll
    ^markerHeight < (scrollHeight - 2)
!

scrollView
    self scrollView: viewDelta
!

scrollView: anInteger
    view isNil
        ifTrue: [ ^nil ].
    view scrollTo: anInteger.
    viewDelta <- viewDelta - anInteger
!

viewDelta
    ^viewDelta
!

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
    ^(view viewDelta * markerHeight / scrollHeight) truncated
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

scrollViewDown
!

scrollViewUp
!

scrollAmount
    ^(Sensor mousePoint y - scrollBar top) truncated
! !

! ScrollController methodsFor: 'cursors' !

markerContainsCursor
    marker isNil
        ifTrue: [ ^false ].
    ^marker containsPoint: Sensor mousePoint
!

scrollBarContainsCursor
    scrollBar isNil
        ifTrue: [ ^false ].
    ^scrollBar containsPoint: Sensor mousePoint
!

viewHasCursor
    view isNil
        ifTrue: [ ^false ].
    ^(view containsPoint: Sensor mousePoint)
          or: [ self scrollBarContainsCursor ]
! !

Object subclass: 'View'
  instanceVariableNames: 'model controller superview subviews borderWidth offset extent insetBox viewDelta name change displayed minsize window label'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! View class methodsFor: 'instance creation' !

new
    ^super new initialize; yourself
!

new: aRectangle
    ^super new initialize: aRectangle; open ; yourself
!

model: aModel label: aString minimumSize: aSize
    ^super new initialize; 
	model: aModel ;
	label: aString ;
	minimumSize: aSize ; 
	yourself
!

model: aModel label: aString
    ^super new initialize; 
	model: aModel ;
	label: aString ;
	yourself
!

model: aModel
    ^super new initialize; 
	model: aModel ;
	yourself
! !

! View methodsFor: 'initialise-release' !

initialize
    self release.
    subviews <- nil.
    superview <- nil.
    model <- nil.
    controller <- nil.
    viewDelta <- 0.
    displayed <- false.
    offset <- 0@0.
    borderWidth <- 1@1 corner: 1@1.
    offset <- nil.
    extent <- 10@10.
    insetBox <- nil.
    window <- 0@0 corner: 1@1.
!

initialize: aRectangle
    self initialize.
    self setSize: aRectangle
!

open
    offset isNil ifTrue: [ self setSize: Rectangle fromUser ].
    "subviews isNil ifFalse: [ subviews do: [ :view | view open ] ].
    model notNil ifTrue: [ self update ]."
    ScheduledControllers scheduleActive: self controller
!

setSize: aRectangle
    offset <- (aRectangle origin + (window origin * (aRectangle extent)))
		grid: 1@1.
    extent <- (window extent * (aRectangle extent)) grid: 1@1.
    insetBox <- (offset + borderWidth origin)
                     extent: (extent - (borderWidth origin
		                        + borderWidth corner)).
    subviews isNil ifFalse: [
	subviews do: [ :view | view setSize: (offset extent: extent) ] ].
!

release
    model isNil
        ifFalse: [ model removeDependent: self ].
    controller isNil
        ifFalse: [ controller release ].
    subviews isNil
        ifFalse: [ subviews do:
	              [ :view | view release ]]
! !

! View methodsFor: 'accessing' !

name
    ^name
!

name: aSymbol
    name <- aSymbol.
    self update: name
!

change: aSymbol
    change <- aSymbol
!

model
    ^model
!

model: aModel
    model isNil
        ifFalse: [ model removeDependent: self ].
    model <- aModel.
    self controller model: aModel.
    aModel addDependent: self.
    ^self
!

controller
    controller isNil
        ifTrue: [ self controller: self defaultController ].
    ^controller
!

controller: aController
    controller isNil
        ifFalse: [ controller release ].
    controller <- aController.
    controller view: self.
    model isNil
        ifFalse: [ controller model: model ].
    ^self
!

model: aModel controller: aController
    model isNil
        ifFalse: [ model removeDependent: self ].
    model <- aModel.
    aModel addDependent: self.
    self controller: aController.
    ^self
!

defaultController
    ^self defaultControllerClass new
!

defaultControllerClass
    ^Controller
!

containsPoint: aPoint
    ^ (offset extent: extent) containsPoint: aPoint
!

subViewContaining: aPoint
    subviews isNil
        ifTrue: [ ^nil ].
    subviews do:
	[ :view | (view containsPoint: aPoint)
		      ifTrue: [ ^view ] ].
    ^nil
!

subViewWantingControl
    subviews isNil
        ifTrue: [ ^nil ].
    controller status == #collapsed
        ifTrue: [ ^nil ].
    subviews do:
        [ :view | view controller isControlWanted
	              ifTrue: [ ^view ] ].
    ^nil
!

update
    ^self update: self
!

update: aParameter
    ^nil
!

offset
    ^offset
!

extent
    ^extent
!

width
    ^extent x
!

height
    ^extent y
!

fullHeight
    ^extent y
!

label
    ^ label
!

label: aString
    ^ label <- aString
!

borderWidth: aWidth
    borderWidth <- aWidth @ aWidth extent: aWidth @ aWidth.
!

window: aRectangle
    window <- aRectangle
! !

! View methodsFor: 'displaying' !

display
    window isNil
        ifTrue: [ self initialize: Rectangle fromUser ].
    Display white: (offset extent: extent).
    Display border: (offset extent: extent)
            widthRectangle: borderWidth
	    mask: Form black.
    subviews isNil
        ifFalse: [ subviews do: [ :view | view display ] ]
!

highlight
    Display reverse: insetBox
!

flash
    self highlight.
    self highlight
!

emphasize
    self emphasizeView.
    self emphasizeSubViews
!

emphasizeView
    ^nil
!

emphasizeSubViews
    subviews isNil
        ifTrue: [ ^nil ].
    subviews do: [ :view | view emphasize ]
!

deEmphasize
    self deEmphasizeView.
    self deEmphasizeSubViews
!

deEmphasizeView
    ^nil
!

deEmphasizeSubViews
    subviews isNil
        ifTrue: [ ^nil ].
    subviews do: [ :view | view deEmphasize ]
! !

! View methodsFor: 'subviews and superviews' !

isTopView
    ^superview isNil
!

superview
    ^superview
!

superview: aView
    superview <- aView
!

topView
    self isTopView
        ifTrue: [ ^self ].
    ^superview topView
!

firstSubView
    subviews isNil
        ifTrue: [ ^nil ].
    ^subviews first
!

lastSubView
    subviews isNil
        ifTrue: [ ^nil ].
    ^subviews last
!

subViews
    ^subviews
!

addSubView: aSubView
    self addSubView: aSubView in: (0@0 extent: 1@1) borderWidth: 1
!

addSubView: aSubView in: aRectangle
    self addSubView: aSubView in: aRectangle borderWidth: 1
!

addSubView: aSubView in: aRectangle borderWidth: aWidth
    subviews isNil
        ifTrue: [ subviews <- OrderedCollection new ].
    subviews add: aSubView.
    aSubView superview: self.
    aSubView window: aRectangle.
    aSubView borderWidth: aWidth.
! !

! View methodsFor: 'scrolling' !

viewDelta
    ^viewDelta
!

scrollTo: anInteger
    ^nil
!

scrollPosition
    ^0
! !

! View methodsFor: 'updating' !

update: aSymbol
    name == aSymbol
        ifTrue: [ self setContentsFrom: (model preform: aSymbol).
	          displayed
		      ifTrue: [ self display ] ]
! !

View subclass: 'StandardSystemView'
  instanceVariableNames: 'labelForm'
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

ScrollController subclass: 'TextController'
  instanceVariableNames: ''
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! TextController methodsFor: 'initialise-release' !

initialize
    super initialize.
    self yellowButtonMenu: (Menu labelArray: #('contents' 'accept')
                                 lines: #()
				 selectors: #(contents accept))
! !

! TextController methodsFor: 'control' !

controlActivity
    Sensor keyboardPressed
        ifTrue: [ ^view nextPut: Sensor keyboard ].
    super controlActivity
!

redButtonActivity
    view setInsertPointFrom: Sensor mousePoint.
    Sensor waitNoButton
! !

! TextController methodsFor: 'editing' !

accept
    ^self changed
!

contents
    stdout nextPutAll: view contents. stdout nl
! !

View subclass: 'TextView'
  instanceVariableNames: 'lineSequence textForm textTop insertPoint currentLine lineNumber'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! TextView class methodsFor: 'displaying' !

on: aModel aspect: aName change: changeSelector
	menu: aMenu initialSelection: aItem
    | aView |
    aView <- super new.
    aView model: aModel ;
	  name: aName ;
          changed: changeSelector ;
     	  controller blueButtonMenu: aMenu notifying: aModel.
    ^ aView
! !

! TextView methodsFor: 'initialising' !

initialize
    insertPoint <- 0 @ 0.
    ^super initialize
!

initialize: aRectangle
    insertPoint <- 0 @ 0.
    ^super initialize: aRectangle
!

setContentsFrom: aString
    | width height aLine lineStr |
    lineSequence <- OrderedCollection new.
    width <- 0.
    aLine <- WriteStream on: (String new: 0).
    aString do:
       [ :char | char == Character nl
                   ifTrue: [ lineStr <- aLine contents.
		             lineSequence add: lineStr.
		             aLine <- WriteStream on: (String new: 0).
			     width <- width max: lineStr size ]
		   ifFalse: [ char == Character tab
		                 ifTrue: [ aLine nextPutAll: '        ' ]
				 ifFalse: [ aLine nextPut: char ] ] ].
    lineStr <- aLine contents.
    lineStr size == 0
       ifFalse: [ lineSequence add: lineStr ].
    textTop <- 0.
    insertPoint <- 0 @ 0.
    currentLine <- Array new: 2.
    self setCurrentLine.
    height <- lineSequence size + 1 * SystemFontHeight.
    height <- height max: extent y.
    width <- width * SystemFontWidth.
    width <- width max: extent x.
    textForm <- Form extent: width @ height.
    textForm white.
    1 to: lineSequence size do:
        [ :x | (lineSequence at: x)
	             displayOn: textForm
		     at: 0 @ (x - 1 * SystemFontHeight) ]
! !

! TextView methodsFor: 'accessing' !

defaultControllerClass
    ^TextController
!

fullHeight
    textForm isNil
        ifTrue: [ ^self height ]
        ifFalse: [ ^textForm height ]
! !

! TextView methodsFor: 'displaying' !

display
    displayed <- true.
    extent isNil
        ifTrue: [ self error: 'TextView has no extent!!' ].
    Display white: (offset extent: extent).
    Display border: (offset extent: extent)
            widthRectangle: borderWidth
	    mask: Form black.
    textTop isNil
        ifTrue: [ textTop <- 0 ].
    textForm isNil
        ifTrue: [ textForm <- Form extent: extent ].
    self showText.
    subviews isNil
        ifFalse: [ subviews do: [ :view | view display ] ]
!

showText
    (BitBlt destForm: Display sourceForm: textForm
            halftoneForm: Form black combinationRule: Form over
	    destOrigin: insetBox origin sourceOrigin: 0@textTop
	    extent: insetBox extent clipRect: insetBox)
	copyBits
! !

! TextView methodsFor: 'displaying-nextPut' !

nextPut: aCharacter
    | aStream aString moveChar |
    (aCharacter isKindOf: Character)
        ifFalse: [ ^nil ].
    (aCharacter == Character nl
        or: [ aCharacter == Character cr ])
	  ifTrue: [ insertPoint <- 0 @ (insertPoint y + SystemFontHeight).
	            self updateCurrentLine; setCurrentLine.
	            ^aCharacter ].
    aCharacter == Character tab
        ifTrue: [ self nextPutAll: '        '.
	          (currentLine at: 1) nextPutAll: '        '.
	          ^aCharacter ].
    aCharacter == Character backspace
        ifTrue: [ insertPoint x > 0
	              ifFalse: [ ^aCharacter ].
	          insertPoint <- insertPoint - (SystemFontWidth @ 0).
		  aString <- (currentLine at: 1) contents.
		  moveChar <- aString last.
		  aString <- aString copyFrom: 1 to: aString size - 1.
		  currentLine at: 1 put: (WriteStream on: aString).
		  aStream <- WriteStream on: (String new: 0).
		  aStream nextPut: moveChar.
		  aStream nextPutAll: (currentLine at: 2) contents.
		  currentLine at: 2 put: aStream.
	          ^aCharacter ].
    aCharacter == (Character value: 127)
        ifTrue: [ insertPoint x > 0
	              ifFalse: [ ^aCharacter ].
	          insertPoint <- insertPoint - (SystemFontWidth @ 0).
	          self displayString: ' ' at: insertPoint.
		  aString <- (currentLine at: 1) contents.
		  aString <- aString copyFrom: 1 to: aString size - 1.
		  currentLine at: 1 put: (WriteStream on: (String new: 0)).
		  (currentLine at: 1) nextPutAll: aString.
		  ^aCharacter ].
    aStream <- WriteStream on: (String new: 0).
    aStream nextPut: aCharacter.
    (currentLine at: 1) nextPut: aCharacter.
    self displayString: aStream contents
         at: insertPoint.
    insertPoint <- insertPoint + (SystemFontWidth @ 0).
    ^aCharacter
!

nextPutAll: aString
    self displayString: aString at: insertPoint.
    insertPoint <- insertPoint + (SystemFontWidth * aString size @ 0).
    ^aString
! !

! TextView methodsFor: 'displaying-display' !

displayString: aString at: newPoint
    aString displayOn: textForm at: newPoint.
    aString displayAt: insetBox origin + newPoint
!

setInsertPointFrom: newPoint
    | aPoint |
    aPoint <- newPoint - insetBox origin.
    insertPoint <- ((aPoint x // SystemFontWidth) * SystemFontWidth)
                   @ ((aPoint y // SystemFontHeight) * SystemFontHeight).
    self updateCurrentLine; setCurrentLine
!

setCurrentLine
    | aString x y leftString rightString |
    x <- insertPoint x // SystemFontWidth.
    y <- insertPoint y + textTop // SystemFontHeight.
    [ lineSequence size <= y ]
        whileTrue: [ lineSequence add: '' ].
    lineNumber <- y + 1.
    aString <- lineSequence at: lineNumber.
    leftString <- aString copyFrom: 1 to: x.
    rightString <- aString copyFrom: x + 1 to: aString size.
    currentLine at: 1 put: (WriteStream on: (String new: 0)).
    (currentLine at: 1) nextPutAll: leftString.
    currentLine at: 2 put: (WriteStream on: (String new: 0)).
    (currentLine at: 2) nextPutAll: rightString
! !

! TextView methodsFor: 'displaying-update' !

updateCurrentLine
    lineSequence at: lineNumber
                 put: (currentLine at: 1) contents,
		      (currentLine at: 2) contents
!

contents
    | aString |
    self updateCurrentLine.
    aString <- (String new: 0).
    lineSequence do:
        [ :line | aString <- aString , line , '
' ].
    ^aString
! !

! TextView methodsFor: 'scrolling' !

scrollTo: anInteger
    textTop <- anInteger.
    textTop > (textForm height - extent y)
        ifTrue: [ textTop <- textForm height - extent y ].
    textTop < 0
        ifTrue: [ textTop <- 0 ].
    self showText
!

scrollPosition
    textTop isNil
        ifTrue: [ ^0 ]
	ifFalse: [ ^textTop ]
! !

! TextView methodsFor: 'updating' !

changed
    | selection |
    (model notNil and: [ name notNil and: [ change notNil ] ])
        ifTrue:
	   [ model preform: change
	           with: self contents
		   with: controller ]
! !

ScrollController subclass: 'ListController'
  instanceVariableNames: ''
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! ListController methodsFor: 'control' !

redButtonActivity
    view select.
    Sensor waitNoButton
! !

View subclass: 'ListView'
  instanceVariableNames: 'displayList listForm listTop currentSelection pendingSelection lineHeight'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! ListView class methodsFor: 'instance creation' !

new: aRectangle on: anArray
    | aView |
    aView <- super new: aRectangle.
    aView setContentsFrom: anArray.
    ^aView
!

on: aModel aspect: aName change: changeSelector
	list: aList menu: aMenu initialSelection: aItem
    | aView |
    aView <- super new.
    aView model: aModel ;
          name: aList ;
          change: changeSelector ;
     	  controller blueButtonMenu: aMenu notifying: aModel.
    ^ aView
! !

! ListView methodsFor: 'initialising' !

setContentsFrom: aCollection
    | width temp |
    currentSelection isNil
        ifFalse: [ self reverseItem: currentSelection.
	           currentSelection <- nil ].
    displayList = aCollection
        ifTrue: [ ^self ].
    displayList <- aCollection asOrderedCollection.
    listTop <- 0.
    currentSelection <- nil.
    lineHeight <- 0.
    width <- 1.
	
    displayList do: [ :string |
		temp <- string displayExtent.
		width <- width max: temp x.
		lineHeight <- lineHeight max: temp y ].
    " Make sure the form has some size "
    listForm <- Form extent: width @ (displayList size * lineHeight + 1).
    listForm white.
    1 to: displayList size do:
      [ :x | (displayList at: x)
                  displayOn: listForm
		  at: 0 @ (x - 1 * lineHeight) ]
! !

! ListView methodsFor: 'accessing' !

defaultControllerClass
    ^ListController
!

fullHeight
    listForm isNil
        ifTrue: [ ^self height ]
	ifFalse: [ ^listForm height ]
! !

! ListView methodsFor: 'displaying' !

display
    displayed <- true.
    extent isNil
        ifTrue: [ self error: 'ListView has no extent!!' ].
    Display white: (offset extent: extent).
    Display border: (offset extent: extent)
            widthRectangle: borderWidth
	    mask: Form black.
    listTop isNil
        ifTrue: [ listTop <- 0 ].
    pendingSelection isNil
        ifFalse: [ self select: pendingSelection.
	           pendingSelection <- nil ].
    self showList.
    subviews isNil
        ifFalse: [ subviews do: [ :view | view display ] ]
!

showList
    (BitBlt destForm: Display sourceForm: listForm
            halftoneForm: Form black combinationRule: Form over
	    destOrigin: insetBox origin sourceOrigin: 0@listTop
	    extent: insetBox extent clipRect: insetBox)
	copyBits
!

emphasize
    currentSelection isNil
        ifTrue: [ ^nil ].
    self unGrayItem: currentSelection.
    self reverseItem: currentSelection.
    self showList
!

deEmphasize
    currentSelection isNil
        ifTrue: [ ^nil ].
    self reverseItem: currentSelection.
    self grayItem: currentSelection.
    self showList
! !

! ListView methodsFor: 'scrolling' !

scrollTo: anInteger
    listTop <- anInteger.
    listTop > (listForm height - extent y)
        ifTrue: [ listTop <- listForm height - extent y ].
    listTop < 0
        ifTrue: [ listTop <- 0 ].
    self showList
!

scrollPosition
    listTop isNil
        ifTrue: [ ^0 ]
	ifFalse: [ ^listTop ]
! !

! ListView methodsFor: 'selecting' !

select
    | aPoint selection |
    aPoint <- Sensor mousePoint.
    (insetBox containsPoint: aPoint)
        ifFalse: [ ^nil ].
    selection <- aPoint y - offset y + listTop.
    selection <- selection // lineHeight + 1.
    (selection < (displayList size + 1) and: [ selection > 0 ])
        ifFalse: [ ^nil ].
    currentSelection isNil            "deselect current selection"
	ifFalse: [ self reverseItem: currentSelection ].
    currentSelection == selection      "deselecting?"
        ifTrue: [ currentSelection <- nil ]
	ifFalse: [ currentSelection <- selection.
                   self reverseItem: currentSelection ].
    self showList.
    self changed
!

setSelection: anInteger
    anInteger isNil
        ifTrue: [ ^nil ].
    pendingSelection <- anInteger
!

select: anInteger
    anInteger isNil
        ifTrue: [ ^nil ].
    (anInteger < (displayList size + 1) and: [ anInteger > 0 ])
        ifFalse: [ ^nil ].
    currentSelection isNil
        ifFalse: [ self reverseItem: currentSelection ].
    currentSelection == anInteger
        ifTrue: [ currentSelection <- nil ]
	ifFalse: [ currentSelection <- anInteger.
	           self reverseItem: currentSelection ].
    self changed
!

reverseItem: selection
    listForm reverse: (0 @ (selection - 1 * lineHeight)
                         extent: (listForm width @ lineHeight)).
!

grayItem: selection
    listForm fill: (0 @ (selection - 1 * lineHeight)
                      extent: (listForm width @ lineHeight))
	     rule: Form under
	     mask: Form veryLightGray
!

unGrayItem: selection
    listForm white: (0 @ (selection - 1 * lineHeight)
                      extent: (listForm width @ lineHeight)).
    (displayList at: selection) displayOn: listForm
                                at: 0 @ (selection - 1 * lineHeight)
! !

! ListView methodsFor: 'updating' !

changed
    | selection |
    (model notNil and: [ name notNil and: [ change notNil ] ])
        ifTrue:
	   [ currentSelection isNil
	         ifTrue: [ selection <- nil ]
		 ifFalse: [ selection <- displayList at: currentSelection ].
	     model preform: change with: selection ]
! !

StandardSystemController subclass: 'PrompterController'
  instanceVariableNames: ''
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! PrompterController methodsFor: 'control' !

isControlWanted
    ^true
!

isControlActive
    ^status ~= #inactive
!

controlActivity
    self viewHasCursor
        ifTrue: [ super controlActivity ]
! !

! PrompterController methodsFor: 'blue button menu items' !

accept
    model accept.
    view release.
    self release.
    status <- #inactive
! !

TextView subclass: 'PrompterView'
  instanceVariableNames: ''
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! PrompterView methodsFor: 'accessing' !

nextPut: aCharacter
    (aCharacter == Character nl
        or: [ aCharacter == Character cr ])
	  ifTrue: [ ^controller accept ].
    super nextPut: aCharacter
! !

