StringHolderController subclass: 'TextCollectorController' !
  instanceVariableNames: ''
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics-Text'
!

! TextCollectorController methodsFor: 'entry control' !

appendEntry
   " Append the text in models WriteStream to the editable window"
   text appendEntry.
   view displayView
!

changeText: aText
    text text: aText.
    view displayView
! !

