Object subclass: 'Controller'
  instanceVariableNames: 'model view'
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

! Controller methodsFor: 'model accessing' !

model
    ^model
!

model: aModel
    model <- aModel.
    ^self
! !

! Controller methodsFor: 'view accessing' !

view
    ^view
!

view: aView
    view <- aView
!

inspectView
    view notNil ifTrue: [ ^ view inspect ]
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

