" Methods for Behavior and Class"

" $Id: $ "
        
"
 $Log: $
"
!

! Behavior methodsFor: 'Creating Method Dictionary'!

methodDictionary: aDictionary
	" Set the method dictionary to a new dictionary. "
	^ methoddict <- aDictionary

!

addSelector: selector withMethod: compiledMethod
	"Adds the selector with compiled method to the class dictionary."
	methoddict at: selector put: compiledMethod.
!

removeSelector: selector
	"Removes the selector from the method."
	methoddict remove: selector.
! !

! Behavior methodsFor: 'Accessing method dictionary'!

selectors
	| sels |
	sels <- Set new.
	methoddict keysDo: [ :key | sels add: key ].
	^ sels
! !


! Behavior methodsFor: 'Accessing class heirarchy'!

allSubclasses
	"Return a set of all subclasses"
	| subs allsubs |
	allsubs <- Set new.
	self subclasses do: [ :subclass | 
		allsubs add: subclass.
		subclass allSubclasses do: [ :subsubc | allsubs add: subsubc]
	].
	^ allsubs
! !
