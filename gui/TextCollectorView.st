StringHolderView subclass: 'TextCollectorView' 
  instanceVariableNames: ''
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics-Text'
!

! TextCollectorView methodsFor: 'updating' !

update: aSymbol
   aSymbol == #appendEntry ifTrue:
	[ (self controller isKindOf: TextCollectorController) ifTrue: 
		[ controller appendEntry.
		^ ScheduledControllers promote: self topView controller]].
   aSymbol == #update ifTrue:
	[(self controller isKindOf: TextCollectorController) ifTrue: 
		[ controller changeText: model contents asText
		^ ScheduledControllers promote: self topView controller]].
  ^ super update: aSymbol

! !

! TextCollectorView methodsFor: 'controller' !

defaultControllerClass
   ^ TextCollectorController
! !

! TextCollectorView class methodsFor: 'instance creation' !
open
	"Create and schedule an instance of me on a new TextCollector."

	^self open: TextCollector new label: 'TextCollector'
!

open: aTextCollector label: aString 
	"Answer an instance of me on the argument, aTextCollector. The
	label of the StandardSystemView should be aString."
	| topView aView |
	topView <- StandardSystemView new.
	topView model: aTextCollector.
	topView label: aString.
	topView minimumSize: 100 @ 50.
	aView <- self new model: aTextCollector.
	aView borderWidth: 2.
	topView addSubView: aView.
	topView controller open
! ! 

