StringHolder subclass: 'TextCollector'
   instanceVariableNames: 'stream isOpen'
   classVariableNames: ''
   poolDictionaries: ''
   category: 'Graphics-Text'
!

TextCollector comment:
'I represent a StringHolder into which text can be gathered' !

! TextCollector methodsFor: 'initialize' !

initialize
    super initialize.
    isOpen <- false.
    self beginEntry
! !

! TextCollector methodsFor: 'accessing' !

next: anInteger put: aChar
    stream next: anInteger put: aChar
!

nextPut: aChar
    stream nextPut: aChar
!

nextPutAll: aCollection
    stream nextPutAll: aCollection
!

show: aString
    self nextPutAll: aString.
    self endEntry 
! !

! TextCollector methodsFor: 'clearing' !

clear 
    contents <- Text new.
    self beginEntry.
    self changed: #update.
!

refresh
    self changed: #refresh.
! !

! TextCollector methodsFor: 'entry control' !

appendEntry
    contents <- contents , self nextEntry asText.
    contents size > self characterLimit
      ifTrue: [ contents <- contents 
		           copyFrom: contents size - (self characterLimit // 2)
			   to: contents size].
    self beginEntry 
!

beginEntry
    stream <- WriteStream on: (String new: 200)
!

endEntry
    stream isEmpty ifFalse: [
	 self changed: #appendEntry.
         self beginEntry] 
!

nextEntry
    ^ stream contents
! !

! TextCollector methodsFor: 'character writing' !

bs
    contents <- contents copyFrom: 1 to: contents size - 1.
    self changed: #update
!

cr
    ^ stream cr
!

crTab
    ^ stream crTab
!

nl
    ^ stream nl
!

nlTab
    ^ stream nlTab
!

tab
    ^ stream tab
!

space
    ^ stream space
! !

! TextCollector methodsFor: 'printing' !

print: anObject
    ^ stream print: anObject
!

store: anObject
    ^ anObject storeOn: self
! !

! TextCollector methodsFor: 'close' !

okToChange
    isOpen <- false.
    ^ super okToChange
! !

! TextCollector methodsFor: 'private' !

transcriptIsOpen
   isOpen <- true
!

characterLimit
   ^ 5000 
!

transcriptOpen
   ^ isOpen
! !

! TextCollector class methodsFor: 'system' !

newTranscript: aTextCollector
   Smalltalk at: #Transcript put: aTextCollecor
! !

