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
    " Refresh the screen "
    screenController view display.
    controllers isNil
        ifTrue: [ ^nil ].
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
    " Make aScheduledcontroller the top window"
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
    " Reverse order of windows"
    controllers reverseDo:
        [ :controller | controller isControlWanted
	                    ifTrue: [ ^self promote: controller ] ]
!

activeController: aScheduledController
    " Make aScheduledController the top active window"
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
   " Stop aScheduledController from running"
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
    " Schedule the controller to run, but don't terminate process who
	initiated the request, aController does not do anything."
    controllers addFirst: aController
!

scheduleActive: aController
   " Schedule the controller, then terminate the process that requested
    the controller"
    self activeController: aController.
    Processor terminateActive
!

sceduleActiveNoTerminate: aController
	" Make aController the new active controller, but don't terminate
	the process"
    self activeController: aController
!

scheduleOnBottom: aController
	" Schedule the controller to run as lowest window."
    controllers addLast: aController
! !

! ControlManager methodsFor: 'scheduling controllers' !

searchForActiveController
	" Find a controller to run. If nothing found, wait for some external
	event to wake us up and try again"
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

