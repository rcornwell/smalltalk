TextController subclass: 'StringHolderController'
  instanceVariableNames: 'isLockingOn'
  classVariableNames: 'YellowMessages YellowMenu'
  poolDictionaries: ''
  category: 'Graphics-Text'
!

! StringHolderController methodsFor: 'initialize' !

initialize
  super initialize.
  isLockingOn <- true.
! !

! StringHolderController methodsFor: 'lock access' !

isLockingOff
   ^ isLockingOn not
!

isLockingOn
   ^ isLockingOn
!

lockModel
   isLockingOn: ifTrue: [ model lock ]
!

turnLockingOff
   isLockingOn <- false
!

turnLockingOn
   isLockingOn <- true
!

unlockModel
   isLockingOn ifTrue: [ model unlock ]
! !

! StringHolderController methodsFor: 'menu messages' !

accept
   super accept.
   model contents: paragraph string.
   self unlockModel
!

cancel
   super cancel.
   model unlockModel
!

doIt
!

inspectIt
!

printIt
! !

! StringHolderController methodsFor: 'model access' !

model: aModel
   super model: aModel.
   view displayContents == nil
     ifFalse: [ self changeParagraph: view displayContents]
! !

