Object subclass: 'View'
  instanceVariableNames: 'model controller superview subviews borderWidth
 transform displayTransform insetBox boundingBox name location window
  backform viewport minSize'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! View class methodsFor: 'instance creation' !

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
!

model: aModel minimumSize: aSize
    ^super new initialize; 
	model: aModel ;
	minimumSize: aSize ; 
	yourself
! !

! View methodsFor: 'initialise-release' !

initialize
    self release.
    transform <- WindowTranslation identity.
    self borderWidth: 0.
    self location: (0@0 extent: 1@1).
!


release
    model isNil
        ifFalse: [ model removeDependent: self ].
    model <- nil.
    controller isNil
        ifFalse: [ controller release ].
    controller <- nil.
    subviews isNil
        ifFalse: [ subviews do:
	              [ :view | view release ]].
    subviews <- nil.
! !

! View methodsFor: 'accessing model' !

model
    ^model
!

model: aModel
    model isNil
        ifFalse: [ model removeDependent: self ].
    model <- aModel.
    self controller model: aModel.
    aModel addDependent: self.
! !

! View methodsFor: 'cursor access' !

containsPoint: aPoint
    ^ self insetBox containsPoint: aPoint
! !

! View methodsFor: 'accessing controller' !

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
!

model: aModel controller: aController
    model isNil
        ifFalse: [ model removeDependent: self ].
    model <- aModel.
    aModel addDependent: self.
    self controller: aController.
!

defaultController
    ^self defaultControllerClass new
!

defaultControllerClass
    ^Controller
! !

! View methodsFor: 'accessing name' !

name
    ^name
!

name: aSymbol
    name <- aSymbol.
    self update: name
! !

! View methodsFor: 'updating' !

update: aSymbol
    ^ self
!

update
    ^self update: name
! !

! View methodsFor: 'control' !

subViewWantingControl
    subviews isNil
        ifTrue: [ ^nil ].
    controller status == #collapsed
        ifTrue: [ ^nil ].
    subviews do:
        [ :view | view controller isControlWanted
	              ifTrue: [ ^view ] ].
    ^nil
! !

! View methodsFor: 'superView access' !

isTopView
    ^superview isNil
!

superview
    ^superview
!

superview: aView
    superview <- aView
    self unlock
!

topView
    self isTopView
        ifTrue: [ ^self ].
    ^superview topView
! !

! View methodsFor: 'subView access' !

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

subViewContaining: aPoint
    subviews isNil
        ifTrue: [ ^nil ].
    subviews do:
	[ :view | (view containsPoint: aPoint)
		      ifTrue: [ ^view ] ].
    ^nil
! !

! View methodsFor: 'locking' !

isUnLocked
    ^displayTransform isNil and: [ insetBox isNil]
!

isLocked
    ^ self isUnlocked not
!

lock
    self isUnlocked ifFalse: [ ^ self ].
    displayTransform <- self computeDisplayTransform.
    insetBox <- self computeInsetBox.
    subviews notNil ifTrue: [ subviews do: [ aview: aview lock ].
!

unlock
    displayTransform <- nil.
    insetBox <- nil.
    subviews notNil ifTrue: [ subviews do: [ aview: aview unlock ].
! !

! View methodsFor: 'window access' !

defaultWindow
    | aRectangle aWindow |
    self isTopView ifTrue: [ ^ Display boundingBox ].
    " Get superview window location. "
    aRectangle <- superview insetWindow.
    " Scale location, location is rectangle defining position in parent.
    aWindow <- (location scaleBy: aRectangle extent) round.
    " Move to correct place.
    aWindow <- aWindow translateBy: arectangle origin.
    ^ aWindow 
!

insetWindow
   ^ self getWindow insetBy: borderWidth
!

window
   ^ self getWindow copy
!

window: aRectangle
    self setWindow: aRectangle copy
!

setWindow: aWindow
    window <- aWindow.
    viewport <- nil.
    self unlock.
!

getWindow
    window isNil ifTrue: [ self setWindow: self defaultWindow ].
    ^ window
!

minimumSize: aSize 
    minSize <- aSize.
    self unlock.
!

minimumSize
    ^ minSize
! !

! View methodsFor: 'transformation' !

displayTransform: anObject
   ^ (self displayTransform applyTo: anObject)
!

computeDisplayTransform
    self isTopView ifTrue: [ ^ transform ]
		   ifFalse: [ ^ superview displayTransform merge: transform ]
!

displayTransform
   displayTransform isNil ifTrue: 
		[displayTransform <- self computeDisplayTransform ].
   ^ displaytransform
!

inverseDisplaytransform: anObject
   ^ (self displayTransform applyInverseTo: anObject)
!

transform
   ^ transform
!

setTransform: aTransform
   transform <- aTransform.
   self unlock.
   viewport <- nil.
! 

transform: aView
   ^ transform applyTo: aView
!

align: point1 with: point2
   self setTransform: (transform align: point1 with point2).
!

scaleBy: aScale
   self setTransform: (transform scaleBy: aScale).
!

translateBy: aPoint
    self setTransform: (transform translateBy: aPoint).
!

applyTo: anObject
    ^ self transform applyTo: anObject
!

applyInverseTo: anObject
    ^ self transform applyInverseTo: anObject
!

window: aWindow viewport: aViewport
    self window: aWindow.
    self setTransform: (WindowTranslation window: aWindow viewport: aViewport).
    self getViewport
! !

! View methodsFor: 'viewport access' !

viewport
   ^ self getViewport copy
!

getViewport
    viewport isNil ifTrue: [
		 viewport <- (self applyTo: self getWindow) truncate ].
    ^ viewport
! !

! View methodsFor: 'displayBox access'

boundingBox
    boundingBox == nil ifTrue: [ self computeBoundingBox ].
    ^ boundingBox
!

computeBoundingBox
    | aRectangle |
    subViews isNil ifTrue: [ ^ self getWindow ].
    aRectangle <- self firstSubView transform: self firstSubView boundingBox.
    subViews do: [:aView | 
		aRectangle <- aRectangle merge: 
				(aView transform: aView boundingBox).].
    ^ aRectangle expandBy: borderWidth
!

insetBox
    insetBox isNil ifTrue: [ insetBox <- self computeInsetBox ].
    ^ insetBox
!

computeInsetBox
    | box |
    box <- ((self displayTransform: self getWindow) insetBy: borderWidth)
    self isTopView ifFalse: [ box <- superview insetBox intersect: box].
    ^ box
!

displayBox
    ^ self insetBox expandBy: borderWidth
! !

! View methodsFor: 'misc' !

backform: aForm
   ^ backform <- aForm
!

backfrom
    backform isNil ifTrue: [ 
	superview isNil ifTrue: [ ^ Display white ]
			ifFalse: [ ^ superview backform ]].
    ^ backform
!

location: aRectangle
    location <- aRectangle.
    self unlock.
    ^ aRectangle
!

location
    ^ location.
!

borderWidth: aWidth
    borderWidth <- aWidth
!

window: aRectangle
    self setWindow: aRectangle
! !

! View methodsFor: 'displaying' !

display
    self lock.
    self displayBorder.
    self displayView.
    self displaySubViews
!

displayBorder
    Display fill: self displayBox mask: self backform.
    borderWidth = 0 ifFalse: [
	Display border: self displayBox
		with: borderWidth
		mask: Form black.
!

displaySubViews
    subviews isNil
        ifFalse: [ subviews do: [ :view | view display ] ]
!

displayView
    ^ self
!

clear
    Display fill: self displayBox mask: self backform.
!

highlight
    Display reverse: self insetBox
!

flash
    self highlight.
    Delay forSeconds: 0.1 .
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

! View methodsFor: 'subviews' !

addSubView: aSubView
    self addSubView: aSubView in: (0@0 extent: 1@1) borderWidth: 1
!

addSubView: aSubView in: aRectangle
    self addSubView: aSubView in: aRectangle borderWidth: 1
!

addSubView: aSubView in: aRectangle borderWidth: aWidth
    subviews isNil ifTrue: [ subviews <- OrderedCollection new ].
    aSubView removeFromSuperView.
    subviews add: aSubView.
    aSubView superview: self.
    aSubView borderWidth: aWidth.
    aSubView location: aRectangle.
    aSubView unlock.
!

removeFromSuperView
     superview notNil ifTrue: [ superview removeSubView: self ].
!

removeSubView: aView
     subviews notNil ifTrue: [ subviews remove: aView ].
     aView superView: nil.
     aView unlock
! !

! View methodsFor: 'scrolling' !

scrollBy: aPoint
    | aRect |
    aRect <- insetBox.
    transform <- transform scrollBy: aPoint.
    window <- self getWindow translateBy: aPoint x negated @ (aPoint y negated).
    self unlock.
    insetBox <- aRect.
    ^ true
! !

