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

