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

