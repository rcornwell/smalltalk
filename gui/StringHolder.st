Object subclass: 'StringHolder'
  instanceVariableNames: 'contents isLocked'
  classVariableNames: 'Workspace'
  poolDictionaries: ''
  category: 'Graphics-Text'
!

StringHolder comment:
'I hold strings that are being shown or edited.'
!

! StringHolder methodsFor: 'initialize' !

initialize
 "Initialize the state to be unlocked and default text"
   isLocked <- false.
   contents <- self defaultContents

! !

! StringHolder methodsFor: 'accessing' !

contents
  "Answer the contents of the string. "
    ^ contents
!

contents: aString
  "Set contents to aString"
   contents <- aString
! !

! StringHolder methodsFor: 'doit' !

doItContext
   "The context that doit should be run from"
   ^ nil
!

doItReceiver
   "The context that should recieve the result of doit"
   ^ nil
! !

! StringHolder methodsFor: 'lock access' !

hasBeenchanged
   " Answer whether the reciever has been changed"
   ^ self isUnlocked not
!

isLocked
   " Answer whether the reciever is locked or not."
   ^ isLocked
!

isUnlocked
  " Answer whether the reciever is unlocked"
   ^ isLocked not
!

lock
   "Note that the reciever has been modified"
   isLocked <- true.
!

okToChange
   self isUnlocked ifTrue: [ ^ true ].
   self changed: #wantToChange.  " Ask if ok to change"
   ^ self isUnlocked
!

unlock
   "Unlock the reciever so it can be changed"
   isLocked <- false.
! !

! StringHolder methodsFor: 'private' !

defaultContents
  ^ ''
! !

! StringHolder class methodsFor: 'class initialize' !

initialize
    WorkSpace <- StringHolder new.
! !

! StringHolder class methodsFor: 'instance creation' !

new
   ^ super new initialize
! !

! StringHolder class methodsFor: 'workspace constants' !

originalWorkspaceContents
    ^ ''.
! !


