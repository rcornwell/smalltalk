Object subclass: 'Notifier'
instanceVariableNames: 'status theMessage backtraceList proceedValue'
classVariableNames: ''
poolDictionaries: ''
category: 'Graphics Windows'
!

! Notifier methodsFor: 'accessing' !

proceedValue
	^ proceedValue
! !

! Notifier methodsFor: 'modifying' !

proceedValue: anObject
	^ proceedValue <- anObject
! !

! Notifier methodsFor: 'initialising' !

message: aString
    | aStream contentsList topView subView |
	stderr nextPutAll: 'Notifier: '.
	stderr nextPutAll: aString.
	stderr nl.
    theMessage <- aString.
    proceedValue <- nil.
    contentsList <- thisContext sender sender newBacktrace.
    aStream <- WriteStream on: (String new: 0).
    1 to: (contentsList size max: 10) do:
        [ :line | aStream nextPutAll: (contentsList at: line). aStream nl ].
    backtraceList <- aStream contents.
	stderr nextPutAll: backtraceList. stderr nl.
	stderr nextPutAll: 'makeing views '.
    topView <- StandardSystemView new: (100@100 extent: 300@200);
                                  label: theMessage;
				  model: self ;
				  yourself.
	stderr nextPutAll: 'text '.
    subView <- TextView on: self aspect: #backTrace change: nil
				menu: nil initialSelection: nil.
    topView addSubView: subView in: (0@0 extent: 1.0@1.0).
    topView setSize: (100@100 extent: 300@200).
    topView controller: NotifyController new.
    subView controller blueButtonMenu:
                              (Menu labelArray: #('proceed' 'debug'
			                          'trace dump')
                                    lines: #(2)
		                    selectors: #(proceed debug
				                 traceDump))
		       notifying: topView controller.
	stderr nextPutAll: 'startup'. stderr nl.
    topView controller startUp.
    stderr nextPutAll: 'notifier terminated: ' , theMessage. stderr nl.
    stderr nextPutAll: 'status now is to: '.
    status printOn: stderr. stderr nl.
    status == #debug ifTrue: [ Debugger	message: theMessage 
				notifying: self 
				stack: contentsList
				on: thisContext
				process:  Processor activeProcess ].
    ScheduledControllers restore.
    ^ proceedValue
! !

! Object methodsFor: 'Error Handling' !

error: aString
    ^ self notify: (self printString, ' error: ', aString)
! !

! Object methodsFor: 'notifiers' !

notify: aString
    ^Notifier message: aString
! !


