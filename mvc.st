" Model View Controller methods for Smalltalk. "

" $Id: mvc.st,v 1.2 2002/02/17 13:41:59 rich Exp rich $ "

"
 $Log: mvc.st,v $
 Revision 1.2  2002/02/17 13:41:59  rich
 Major rewrite of TextView to be a full fledged editor.

 Revision 1.1  2002/01/29 16:41:34  rich
 Initial revision


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
    ^super new initialize: aRectangle ; yourself
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
    ^self update: name
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
  classVariableNames: 'BlueMenu'
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! TextController methodsFor: 'initialize' !

initialize
     super initialize.
     BlueMenu isNil ifTrue: [
          BlueMenu <- Menu labelArray: #( 'again' 'undo' 'copy'
				 'cut' 'paste' 'do it' 'print it' 'accept'
				 'cancel')
                                 lines: #( 2 5 7)
				 selectors: #(again undo copySelect cut paste
				   doit printit accept cancel).
     ].
     self blueButtonMenu: BlueMenu notifying: self.
! !

! TextController methodsFor: 'control' !

controlActivity
    Sensor keyboardPressed
        ifTrue: [ ^view keypress: Sensor keyboard ].
    super controlActivity
!

redButtonActivity
    | position oldPosition |
    oldPosition <- Sensor mousePoint.
    view setInsertPointFrom: oldPosition.
    [ Sensor waitMouse. Sensor redButtonPressed ]
           whileTrue: [  position <- Sensor mousePoint.
	                position = oldPosition
		            ifFalse: [ oldPosition <- position.
			               view setSelectionFrom: position ] ].
! !

! TextController methodsFor: 'editing' !

again
   view again
!

undo
   view undo
!

copySelect
   view copySelect
!

cut
   view cut
!

paste
   view paste
!

doit
   view doit
!

printit
   view printit
!

cancel
    view cancel
!

accept
    ^self changed
!

contents
    stdout nextPutAll: view contents. stdout nl
! !

View subclass: 'TextView'
  instanceVariableNames: 'buffer lineStart lineEnd lineHeight textHeight textWidth textTop insertPoint currentLine charScanner selectStart selectPoint beforeSize gapSize afterSize original cutbuffer againcmd'
  classVariableNames: 'InsertPoint'
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! TextView class methodsFor: 'initialize' !

initialize
    InsertPoint <- Form extent: 8@4
                      fromArray: #(
				2r00011000
				2r00111100
				2r01100110
				2r11000011)
		      offset: -4@0
! !

! TextView class methodsFor: 'displaying' !

on: aModel aspect: aName change: changeSelector
	menu: aMenu initialSelection: aItem
    | aView |
    aView <- super new.
    aView model: aModel ;
	  name: aName ;
          changed: changeSelector.
    aMenu isNil ifFalse: [ 
          aView controller blueButtonMenu: aMenu notifying: aView controller ].
    ^ aView
! !

! TextView methodsFor: 'initialising' !

initialize
    | code |
    " Initialize line arrays "
    super initialize.
    insetBox isNil ifTrue: [ insetBox <- Display boundingBox ].
    original <- ''.
    lineStart <- OrderedCollection new.
    lineHeight <- OrderedCollection new.
    insertPoint <- nil.
    currentLine <- 1.
    selectStart <- nil.
    selectPoint <- nil.
    gapSize <- 0.
    beforeSize <- 0.
    afterSize <- 0.
    buffer <- original copy.
    
    " Set up scanner "
    charScanner <- CharacterScanner text: buffer 
	destForm: Display font: Font systemFont
        combinationRule: Form over destOrigin: 0@0
        extent: ((self width)@(self height)) clipRect: nil.
    self setGap: self defaultGapSize.
    charScanner printing: false.
    charScanner stopcode: (Character backspace asciiValue + 1) put: #bs.
    charScanner stopcode: (Character tab asciiValue + 1) put: #tab.
    charScanner stopcode: (Character cr asciiValue + 1) put: #cr.
    charScanner stopcode: (Character nl asciiValue + 1) put: #nl.
    charScanner startX: 0.
    charScanner stopX: insetBox width.
    textWidth <- 0.
    textHeight <- 0.
    textTop <- 0.
    lineStart add: 1.
    lineStart add: 1.
    lineHeight add: 0.
    textHeight <- charScanner fontHeight.
!

setContentsFrom: aString
    | code |
    " Initialize line arrays "
    insetBox isNil ifTrue: [ insetBox <- Display boundingBox ].
    original <- aString.
    lineStart <- OrderedCollection new.
    lineHeight <- OrderedCollection new.
    insertPoint <- nil.
    currentLine <- 1.
    selectStart <- nil.
    selectPoint <- nil.
    " Copy aString to work buffer "
    gapSize <- 0.
    beforeSize <- 0.
    afterSize <- aString size.
    buffer <- original copy.
    
    " Set up scanner "
    charScanner <- CharacterScanner text: buffer 
	destForm: Display font: Font systemFont
        combinationRule: Form over destOrigin: 0@0
        extent: ((self width)@(self height)) clipRect: nil.
    self setGap: self defaultGapSize.
    charScanner printing: false.
    charScanner stopcode: (Character backspace asciiValue + 1) put: #bs.
    charScanner stopcode: (Character tab asciiValue + 1) put: #tab.
    charScanner stopcode: (Character cr asciiValue + 1) put: #cr.
    charScanner stopcode: (Character nl asciiValue + 1) put: #nl.
    charScanner startX: 0.
    charScanner stopX: insetBox width.
    charScanner textPos: gapSize.
    textWidth <- 0.
    textHeight <- 0.
    textTop <- 0.
    lineStart add: 1.

    [ code <- charScanner scanword: buffer size.
      code == #endRun ] whileFalse: [
	textWidth <- textWidth max: charScanner destX.
	code == #stopX ifTrue: [
		lineHeight add: charScanner destY.
		lineStart add: charScanner textPos.
		charScanner nextline ].
        code == #nl ifTrue: [
		lineHeight add: charScanner destY.
		lineStart add: (charScanner textPos + 1).
		charScanner nextline ].
	code == #bs ifTrue: [ charScanner backspace ].
	code == #tab ifTrue: [ charScanner tab ].
	charScanner nextChar.
    ].
    lineHeight add: charScanner destY.
    charScanner nextline.
    lineStart add: (charScanner textPos) - 1.
    textHeight <- charScanner destY.
! !

! TextView methodsFor: 'accessing' !

defaultControllerClass
    ^ TextController
!

fullHeight
    textHeight == 0
        ifTrue: [ ^ self height ]
        ifFalse: [ ^ textHeight ]
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
    self showText.
    subviews isNil
        ifFalse: [ subviews do: [ :view | view display ] ]
!

showText
    | start end second last line lineLen temp textBottom moreText |
    " Set up scanner. "

    lineStart size = 1 ifTrue: [ ^ self ].
    " Compute where we need to display "
    start <- 1.
    end <- lineHeight size.
    textBottom <- textTop + insetBox height.
    1 to: lineHeight size do: [ :t |
	 temp <- lineHeight at: t.
	 temp < textTop ifTrue: [ start <- t ].
	 temp <= textBottom ifTrue: [ end <- t ].
    ].
    " Do dirty work of displaying text "
    line <- start.
    start <- lineStart at: start.
    end <- lineStart at: (end + 1).
   
    " Set up scanner to correct start point.  "
    charScanner printing: true.
    temp <- textTop - (lineHeight at: line).
    charScanner setRect: insetBox offset: temp negated.

    insertPoint <- nil.

    second <- start > (beforeSize + gapSize).
    " Set end of line, but don't go into gap "
    lineLen <- lineStart at: (line + 1).
    (second not and: [ lineLen > beforeSize ]) ifTrue: [ lineLen <- beforeSize + 1].

    charScanner textPos: start.

    " Check if at insert point "
    start == lineLen ifTrue: [
	insertPoint <- (0@(charScanner fontHeight)) + charScanner destPoint.
	second <- true.
	charScanner textPos: (beforeSize + gapSize).
	lineLen <- lineStart at: (line + 1).
    ]. 
    moreText <- true.
    [ moreText ] whileTrue: [
       [ temp <- charScanner scanword: (lineLen - 1).
          (temp == #endRun or: [ temp == #stopX ] ) ] whileFalse: [
	   " temp == #nl ifTrue: [ charScanner nextline ]."
	    temp == #bs ifTrue: [ charScanner backspace ].
	    temp == #tab ifTrue: [ charScanner tab ].
	    charScanner nextChar.
	].
	
  
	(second not and: [charScanner textPos = (beforeSize + 1)]) ifTrue: [
		insertPoint <- (0@(charScanner fontHeight)) + charScanner destPoint.
		second <- true.
		charScanner textPos: (beforeSize + gapSize).
		lineLen <- lineStart at: (line + 1).
	] ifFalse: [
            charScanner textPos >= end 
	ifTrue: [ moreText <- false ]
	ifFalse: [
		temp == #endRun ifTrue: [ charScanner nextline. ].
		 line <- line + 1.
                               lineLen <- lineStart at: (line + 1).
		(second not and: [ lineLen > beforeSize ]) ifTrue: [ lineLen <- beforeSize + 1].
	].
            ].
    ].

    insertPoint isNil ifFalse: [ InsertPoint displayOn: Display at: insertPoint
			       clippingBox: insetBox rule: Form reverse.
	self reverseSelection.

    ].
!

clearSelection
	selectStart isNil ifFalse: [ self reverseSelection ].
	selectStart <- nil.
	selectPoint <- nil.
!

reverseSelection
	| temp start |

        " Display highlighted section "
	insertPoint isNil ifTrue: [
		selectStart <- nil.
		selectPoint <- nil.
		^ self ].	
        selectStart isNil ifTrue: [ ^self ].
	selectStart == beforeSize ifTrue: [ ^ self ].
	selectPoint <- self indexToPoint: selectStart + 1.

    " Set up scanner to correct start point.  "
   	charScanner printing: false.
	charScanner setRect: insetBox offset: 0.
	charScanner destOrigin: selectPoint. 
	charScanner textPos: selectStart + 1.
	start <- charScanner destPoint.
    	[ temp <- charScanner scanword: beforeSize.
     	     temp == #endRun ] whileFalse: [
	    (temp == #nl or: [ temp == #stopX ] ) ifTrue: [
   		 (BitBlt destForm: Display sourceForm: nil 
			 halftoneForm: Form black combinationRule: Form reverse
			 destOrigin: start sourceOrigin: start extent: 
			(charScanner destX - start x) @ (charScanner fontHeight)
	   		 clipRect: insetBox )
			copyBits.
		 charScanner nextline.
		 start <- charScanner destPoint.
	    ].
	    temp == #bs ifTrue: [ charScanner backspace ].
	    temp == #tab ifTrue: [ charScanner tab ].
	    charScanner nextChar.
	].
	(BitBlt destForm: Display sourceForm: nil halftoneForm: Form black
        	combinationRule: Form reverse destOrigin: start
	    	sourceOrigin: start extent: 
		(charScanner destX - start x) @ (charScanner fontHeight)
	   	 clipRect: insetBox )
		copyBits. 
	
! !

! TextView methodsFor: 'mouse-action' !

getSelection
	| selection |
	selectStart isNil ifTrue: [ ^ cutbuffer ].
	selection <- buffer species new: (beforeSize - selectStart).
	selection replaceFrom: 1 to: selection size with: buffer
		startingAt: selectStart + 1.
	^ selection
!

again
!

undo
!

copySelect
	cutbuffer <- self getSelection.
	selectStart isNil ifTrue: [
		self reverseSelection.
		selectStart <- nil.
	]
!

cut
	" Check if we have a selection. "
	cutbuffer <- self getSelection.
	selectStart isNil ifTrue: [ ^ self ].
	self deleteBefore: (beforeSize - selectStart).
	selectStart <- nil.
!

paste
	self clearSelection.
	cutbuffer isNil ifFalse: [ self insertString: cutbuffer ].
!

doit
	| cmd |
	cmd <- self getSelection.
	Compiler evaluate: cmd.
!

printit
	| cmd result sel |
	cmd <- self getSelection.
	self clearSelection.
	result <- (Compiler evaluate: cmd) printString.
	sel <- beforeSize.
	self insertString: result.
	selectStart <- sel.
	self reverseSelection.
!

keypress: aKey
    | aStream aChar moveChar aString |
    aChar <- aKey asCharacter.
    Character cr = aChar ifTrue: [ aChar <- Character nl ].
    Character backspace = aChar ifTrue: [
	self deleteBefore: 1.
	^ aKey
    ].
    aKey = 127 ifTrue: [ 
	self deleteAfter: 1.
	^ aKey
    ].
    aKey = 128 ifTrue: [
	" Begining of line "
	self setInsertPoint: (lineStart at: currentLine).
	^ aKey
    ].
    aKey = 129 ifTrue: [
	" Left "
	self setInsertPoint: beforeSize - 1.
	^ aKey
    ].
    aKey = 130 ifTrue: [
	" up "
	^ aKey
    ].
    aKey = 131 ifTrue: [
	" Right "
	self setInsertPoint: beforeSize + 1.
	^ aKey
    ].
    aKey = 132 ifTrue: [
	" Down "
	^ aKey
    ].
    aKey = 133 ifTrue: [
	" Page Up "
	^ aKey
    ].
    aKey = 134 ifTrue: [
	" Page Down "
	^ aKey
    ].
    aKey = 135 ifTrue: [
	" End "
	self setInsertPoint: (lineStart at: currentLine + 1).
	^ aKey
    ].
    aKey = 136 ifTrue: [
	" Begin "
	self setInsertPoint: 0.
	^ aKey
    ].
     self insertString: aChar asString.
    ^aKey
!

setSelectionFrom: newPoint
    | newStart temp |
    newStart <- self pointToIndex: newPoint.
    self reverseSelection.
    newStart > selectStart ifTrue: [ 
	self setInsertPoint: newStart.
     ] ifFalse: [
	 selectStart <- newStart.
     ].
     self reverseSelection.
!

setInsertPointFrom: newPoint
    | aPoint line temp moreText second lineLen  |
    self clearSelection.
    aPoint <- (newPoint - insetBox origin) + (0@textTop).
    " Compute line and offset into line of point "
    line <- 1.
    1 to: lineHeight size do: [ :t |
	 (lineHeight at: t) < aPoint y  ifTrue: [ line <- t ].
    ].
    line > lineStart size ifTrue: [ line <- lineStart size ].
    " Set up scanner to correct start point.  "
    charScanner printing: false.
    charScanner setRect: (0@0 extent: insetBox extent) offset: 0.
    temp <- lineStart at: line.
    
    second <- temp > (beforeSize + gapSize).
    " Set end of line, but don't go into gap "
    lineLen <- lineStart at: (line + 1).
    (second not and: [ lineLen > beforeSize ]) ifTrue:
		 [ lineLen <- beforeSize + 1].

    " Check if at insert point "
    temp == lineLen ifTrue: [
	second <- true.
	temp <- beforeSize + gapSize.
	lineLen <- lineStart at: (line + 1).
    ]. 
    charScanner textPos: temp.

    moreText <- true.
    [ moreText ] whileTrue: [
       [ temp <- charScanner scanword: (lineLen - 1).
          temp == #endRun or: [ temp == #stopX]  ] whileFalse: [
	    temp == #nl ifTrue: [ charScanner nextline  ].
	    temp == #bs ifTrue: [ charScanner backspace ].
	    temp == #tab ifTrue: [ charScanner tab ].
	    charScanner nextChar.
	].
	(second not and: [charScanner textPos = (beforeSize + 1)]) ifTrue: [
		charScanner textPos: (beforeSize + gapSize).
		lineLen <- lineStart at: (line + 1).
		second <- true.
	] ifFalse: [ 
                              moreText <- false.
	].
    ].


    temp <- charScanner textPos.
    temp > beforeSize ifTrue: [ temp <- temp - gapSize ].
    temp < beforeSize ifTrue: [ temp <- temp - 1].
    self setInsertPoint: temp.
    selectStart <- temp.
!

setCurrentInsert
    | aString x y leftString rightString |
	^self.
    x <- insertPoint x // SystemFontWidth.
    y <- insertPoint y + textTop // SystemFontHeight.
    [ lineStart size <= y ]
        whileTrue: [ lineStart add: '' ].
    "lineNumber <- y + 1.
    aString <- lineStart at: lineNumber."
    leftString <- aString copyFrom: 1 to: x.
    rightString <- aString copyFrom: x + 1 to: aString size.
    currentLine at: 1 put: (WriteStream on: (String new: 0)).
    (currentLine at: 1) nextPutAll: leftString.
    currentLine at: 2 put: (WriteStream on: (String new: 0)).
    (currentLine at: 2) nextPutAll: rightString
! !

! TextView methodsFor: 'accessing' !

contents
    | aString |
    " Copy aString to work buffer "
    aString <- buffer species new: afterSize + beforeSize.
    aString replaceFrom: 1 to: beforeSize 
	with: buffer startingAt: 1.
    aString replaceFrom: beforeSize + 1 to: beforeSize + afterSize
	with: buffer startingAt: beforeSize + 1.
    ^aString
! !

! TextView methodsFor: 'scrolling' !

scrollTo: anInteger
    textTop <- anInteger.
    textTop > textHeight
        ifTrue: [ textTop <- textHeight ].
    textTop < 0
        ifTrue: [ textTop <- 0 ].
    Display white: (offset extent: extent).
    Display border: (offset extent: extent)
            widthRectangle: borderWidth
	    mask: Form black.
    self showText
!

scrollPosition
    textTop isNil
        ifTrue: [ ^0 ]
	ifFalse: [ ^textTop ]
! !

! TextView methodsFor: 'updating' !

cancel
    self setContentsFrom: original.
!

changed
    | selection |
    (model notNil and: [ name notNil and: [ change notNil ] ])
        ifTrue:
	   [ original <- self contents.
	     model preform: change with: original with: controller ]
! !

! TextView methodsFor: 'private' !

indexToPoint: aIndex
   | line start temp lineLen second moreText |

   " Compute line number of aIndex "
   line <- 1.
   1 to: lineStart size do: [:i |
	(lineStart at: i) < aIndex ifTrue: [ line <- i ].
   ].

    " Recompute carret "
    start <- lineStart at: line.
   " normalize to scrolling top "
    temp <- (lineHeight at: line) - textTop.
    
 
    " Set up scanner to correct start point.  "
    charScanner printing: false.
    charScanner setRect: insetBox offset: temp.
    "charScanner destY: (insetBox top + temp). "

    charScanner textPos: start.

    " Check if at insert point "
    start == aIndex ifTrue: [ ^ charScanner destPoint ].

    lineLen <- aIndex.
    second <- true.
    (lineLen > beforeSize and: [ start <= beforeSize ]) ifTrue: [
	second <- false.
	 lineLen <- beforeSize ].
    " Scan rest of line "
    moreText <- true.
    [ moreText ] whileTrue: [
	
       [ temp <- charScanner scanword: (lineLen - 1).
          temp == #endRun ] whileFalse: [
	  temp == #stopX ifTrue: [ charScanner nextline ].
	    temp == #bs ifTrue: [ charScanner backspace ].
	    temp == #tab ifTrue: [ charScanner tab ].
	    charScanner nextChar.
	].
	(second not and: [charScanner textPos = (beforeSize + 1)]) ifTrue: [
		second <- true.
		charScanner textPos: (beforeSize + gapSize).
		lineLen <- aIndex.
	] ifFalse: [ moreText <- false ].
    ].
    ^ charScanner destPoint
!

pointToIndex: newPoint
    | aPoint line temp moreText second lineLen  |
    aPoint <- (newPoint - insetBox origin) + (0@textTop).
    " Compute line and offset into line of point "
    line <- 1.
    1 to: lineHeight size do: [ :t |
	 (lineHeight at: t) < aPoint y  ifTrue: [ line <- t ].
    ].
    line > lineStart size ifTrue: [ line <- lineStart size ].
    " Set up scanner to correct start point.  "
    charScanner printing: false.
    charScanner startX: 0.
    charScanner stopX: aPoint x.
    charScanner width: insetBox width.
    charScanner height: insetBox height.
    charScanner destX: 0.
    charScanner destY: 0. 
    temp <- lineStart at: line.
    
    second <- temp > (beforeSize + gapSize).
    " Set end of line, but don't go into gap "
    lineLen <- lineStart at: (line + 1).
    (second not and: [ lineLen > beforeSize ]) ifTrue: [ lineLen <- beforeSize + 1].

    " Check if at insert point "
    temp == lineLen ifTrue: [
	second <- true.
	temp <- beforeSize + gapSize.
	lineLen <- lineStart at: (line + 1).
    ]. 
    charScanner textPos: temp.

    moreText <- true.
    [ moreText ] whileTrue: [
       [ temp <- charScanner scanword: (lineLen - 1).
          temp == #endRun or: [ temp == #stopX]  ] whileFalse: [
	    temp == #nl ifTrue: [ charScanner nextline  ].
	    temp == #bs ifTrue: [ charScanner backspace ].
	    temp == #tab ifTrue: [ charScanner tab ].
	    charScanner nextChar.
	].
	(second not and: [charScanner textPos = (beforeSize + 1)]) ifTrue: [
		charScanner textPos: (beforeSize + gapSize).
		lineLen <- lineStart at: (line + 1).
		second <- true.
	] ifFalse: [ 
                              moreText <- false.
	].
    ].


    temp <- charScanner textPos.
    temp > beforeSize ifTrue: [ temp <- temp - gapSize ].
    temp < beforeSize ifTrue: [ temp <- temp - 1].
    ^ temp
!

defaultGapSize
       ^ 10
!

setGap: aInteger
      | newSize newBuffer temp |
      " Don't bother if gap already large enough "
     gapSize > aInteger ifTrue: [ ^ self ].
     newSize <- aInteger max: self defaultGapSize.
     newBuffer <- buffer species new: beforeSize + afterSize + newSize.
     beforeSize > 0 ifTrue: [
    	newBuffer replaceFrom: 1 to: beforeSize with: buffer
	startingAt: 1
	].
     1 to: newSize do: [ :i | newBuffer at: beforeSize + i put: $& ].
     afterSize > 0 ifTrue: [
    	newBuffer replaceFrom: beforeSize + newSize to: newBuffer size
		 with: buffer startingAt: beforeSize + gapSize + 1 ].
	" Readjust start line vector "
	1 to: lineStart size do: [ :i |
		temp <- lineStart at: i.
		temp > (beforeSize + gapSize) ifTrue:
			[ lineStart at: i put:  temp + newSize ].
	].
	buffer <- newBuffer.
	charScanner text: buffer.
	gapSize <- newSize.
! !

! TextView methodsFor: 'editing' !

setInsertPoint: aPosition
     " Set insert point to a given spot. "
    | distance gapEnd newPoint temp start |

    " Sanity check new position "
    newPoint <- aPosition.
    newPoint < 0 ifTrue: [ newPoint <- 0 ].
    newPoint > (beforeSize + afterSize) ifTrue: [ newPoint <- beforeSize + afterSize ].
    gapEnd <- beforeSize + gapSize.
    (newPoint == gapEnd or: [ newPoint == beforeSize ] ) ifTrue: [ ^ self ].

    " Clear old carret if set "
    insertPoint isNil ifFalse: [ InsertPoint displayOn: Display at: insertPoint
			       clippingBox: insetBox rule: Form reverse ].
    insertPoint <- nil.
    " Check if we need to move forward or backward in text "
    newPoint < beforeSize ifTrue: [
	" Move towards front of document. "
	distance <- beforeSize - newPoint.
	temp <- buffer species new: distance.
	temp replaceFrom: 1 to: distance with: buffer startingAt: newPoint + 1.
	buffer replaceFrom: gapEnd - distance to: gapEnd - 1 with: temp startingAt: 1.
	" Adjust line start array. "
	currentLine <- 1.
	newPoint <- newPoint + 1.
	1 to: lineStart size do: [ :t |
		temp <- lineStart at: t.
		(temp > newPoint and: [ temp < gapEnd ]) ifTrue:
			[ lineStart at: t put: temp + gapSize ].
		temp < newPoint ifTrue: [ currentLine <- t ].
	].
	newPoint <- newPoint - 1.
                afterSize <- afterSize + distance.
     ] ifFalse: [
	" Move towards back of document. "
	distance <- newPoint - beforeSize.
	temp <- buffer species new: distance.
	temp replaceFrom: 1 to: distance with: buffer startingAt: gapEnd.
	buffer replaceFrom: beforeSize + 1 to: beforeSize + 1 + distance
		with: temp startingAt: 1.
	buffer replaceFrom: beforeSize + 1 + distance to: gapEnd + distance - 1 with: '##########' startingAt: 1.
	" Adjust line start array. "
	currentLine <- 1.
	newPoint <- newPoint + gapSize.
	1 to: lineStart size do: [ :t |
		temp <- lineStart at: t.
		(temp < newPoint and: [ temp > (beforeSize + 1) ]) ifTrue:
			[ lineStart at: t put: temp - gapSize ].
		temp < newPoint ifTrue: [ currentLine <- t ].
	].
	newPoint <- newPoint - gapSize.
	afterSize <- afterSize - distance.
     ].
     beforeSize <- newPoint.
     


    " Set up scanner. "

    " Recompute carret "
    start <- lineStart at: currentLine.
   " normalize to scrolling top "
    temp <- (lineHeight at: currentLine) - textTop.

    " Set up scanner to correct start point.  "
    charScanner printing: false.
    charScanner setRect: insetBox offset: temp.

    charScanner textPos: start.

    " Check if at insert point "
    start == (beforeSize + 1) ifFalse: [
       [ temp <- charScanner scanword: beforeSize.
          temp == #endRun ] whileFalse: [
	    temp == #bs ifTrue: [ charScanner backspace ].
	    temp == #tab ifTrue: [ charScanner tab ].
	    charScanner nextChar.
	].
       ].

    insertPoint <- (0@(charScanner fontHeight)) + charScanner destPoint.
   InsertPoint displayOn: Display at: insertPoint
		  clippingBox: insetBox rule: Form reverse.
!

reformatAfter
    | start end second last line lineLen temp textBottom moreText
	newStart newHeight |
    " Set up scanner. "
    newStart <- OrderedCollection new.
    newHeight <- OrderedCollection new.

    " Clear cursor "
    insertPoint isNil ifFalse: [ InsertPoint displayOn: Display at: insertPoint
			       clippingBox: insetBox rule: Form reverse ].
    " Copy stuff before we changed it "
    1 to: currentLine do: [ :i |
	newStart add: (lineStart at: i ).
	newHeight add: (lineHeight at: i).
    ].
    textBottom <- textTop + insetBox height.
    " Do dirty work of displaying text "
    line <- currentLine.
    start <- newStart at: currentLine.
    temp <- (lineHeight at: currentLine) - textTop.
    
   
    " Set up scanner to correct start point.  "
    charScanner printing: true.
    charScanner setRect: insetBox offset: temp.

    insertPoint <- nil.

    second <- start > (beforeSize + gapSize).
    " Set end of line, but don't go into gap "
    second ifFalse: [ lineLen <- beforeSize ]
    	   ifTrue: [ lineLen <- buffer size  ].

    charScanner textPos: start.

    " Check if at insert point "
    start > lineLen ifTrue: [
	insertPoint <- (0@(charScanner fontHeight)) + charScanner destPoint.
	second <- true.
	charScanner textPos: (beforeSize + gapSize).
	lineLen <- buffer size.
    ]. 
    (BitBlt destForm: Display sourceForm: nil halftoneForm: Form white
            combinationRule: Form over destOrigin: charScanner destPoint
	    sourceOrigin: charScanner destPoint extent: 
	     (insetBox width) @ (charScanner fontHeight)
	    clipRect: insetBox )
		copyBits. 
    moreText <- true.
    [ moreText ] whileTrue: [
       [ temp <- charScanner scanword: lineLen.
          temp == #endRun ] whileFalse: [
	    temp == #stopX ifTrue: [
		newHeight add: charScanner destY.
		newStart add: charScanner textPos.
		charScanner nextline.
		charScanner destY > textBottom ifTrue: [
			charScanner printing: false
		].
    (BitBlt destForm: Display sourceForm: nil halftoneForm: Form white
            combinationRule: Form over destOrigin: charScanner destPoint
	    sourceOrigin: charScanner destPoint extent: 
	     (insetBox width) @ (charScanner fontHeight)
	    clipRect: insetBox )
		copyBits. 
	     ].
             temp == #nl ifTrue: [
		newHeight add: charScanner destY.
		newStart add: (charScanner textPos + 1).
		charScanner nextline.
		charScanner destY > textBottom ifTrue: [
			charScanner printing: false
		].
    (BitBlt destForm: Display sourceForm: nil halftoneForm: Form white
            combinationRule: Form over destOrigin: charScanner destPoint
	    sourceOrigin: charScanner destPoint extent: 
	     (insetBox width) @ (charScanner fontHeight)
	    clipRect: insetBox )
		copyBits. 
	    ].
	    temp == #bs ifTrue: [ charScanner backspace ].
	    temp == #tab ifTrue: [ charScanner tab ].
	    charScanner nextChar.
	].
	
	second not ifTrue: [
		insertPoint <- (0@(charScanner fontHeight)) + charScanner destPoint.
		second <- true.
		charScanner textPos: (beforeSize + gapSize).
		lineLen <- buffer size.
		afterSize == 0 ifTrue: [ moreText <- false ].
	] ifFalse: [
		moreText <- false 
	].
    ].

    newHeight add: charScanner destY.
    charScanner nextline.
    newStart add: (charScanner textPos) - 1.
    textHeight <- charScanner destY.
 
    lineHeight <- newHeight.
    lineStart <- newStart.
    insertPoint isNil ifFalse: [ InsertPoint displayOn: Display at: insertPoint
			       clippingBox: insetBox rule: Form reverse.
	self reverseSelection.

    ].
!

deleteAfter: aNumber
	" Delete aNumber characters after insert point. "
     | amount |
     amount <- aNumber.
     amount < 0 ifTrue: [ ^ self ].
     amount > afterSize ifTrue: [ amount <- afterSize ].
     afterSize <- afterSize - amount.
     gapSize <- gapSize + amount.
     self reformatAfter.
!

deleteBefore: aNumber
	" Delete aNumber characters before insert point. "
     | amount |
     amount <- aNumber.
     amount < 0 ifTrue: [ ^ self ].
     amount > beforeSize ifTrue: [ amount <- beforeSize ].
     beforeSize <- beforeSize - amount.
     gapSize <- gapSize + amount.
     currentLine <- 1.
     1 to: lineStart size do: [ :i |
	(lineStart at: i) < beforeSize ifTrue: [ currentLine <- i]. ].
     self reformatAfter.
!

insertString: aString
     | newSize |
     newSize <- aString size.
     self setGap: newSize.
     buffer replaceFrom: beforeSize + 1 to: beforeSize + newSize + 1
		 with: aString startingAt: 1.
     beforeSize <- beforeSize + newSize.
     gapSize <- gapSize - newSize.
     selectStart <- nil.
     self reformatAfter.
! !

TextView initialize !

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
!

currentSelection
    ^currentSelection 
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


