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

