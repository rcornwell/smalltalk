
ArrayedCollection subclass: 'RunArray'
                  instanceVariableNames: 'runs values lastIndex lastRun lastOffset'
	          classVariableNames: ''
                  poolDictionaries: ''
		  category: 'Collections' !
RunArray comment:
'My instances are compressed arrays. I work best when consecutive elements are
of the same value.'

! RunArray class methodsFor: 'instance creation' !

new: anInteger
	^ (super new) setSize: anInteger
!

new
	^ self new: 32
! !

! RunArray methodsFor: 'accessing' !

at: index
    | position i t |
    ((index < 1) or: [ index > lastOffset ] ifTrue: [
	^ self error: 'subscript out of range' ].
    position <- 1.
    i <- 1.
    [ (position > index) and: [ i < lastIndex ] ] whileTrue: [
	t <- position + (runs at: i).
	(t < index) ifTrue: [ ^ values at: i ].
	position <- t.
	i <- i + 1
    ].
    ^ values at: i
!

runLengthAt: index
    | position i t |
    ((index < 1) or: [ index > lastOffset ] ifTrue: [
	^ self error: 'subscript out of range' ].
    position <- 1.
    i <- 1.
    [ (position > index) and: [ i < lastIndex ] ] whileTrue: [
	t <- position + (runs at: i).
	(t < index) ifTrue: [ ^ (index - position) + (runs at: i) ].
	position <- t.
	i <- i + 1
    ].
    ^ 1
!

indexOf: anElement ifAbsent: exceptionBlock
    | position i |
    position <- 1.
    i <- 1.
    [ i < lastIndex ] whileTrue: [
	((values at: i) = anElement) ifTrue: [ ^ position ].
	position <- position + (runs at: i).
	i <- i + 1
    ].
    ^exceptionBlock value
!

size
    ^ lastOffset
! !

! RunArray methodsFor: 'adding' !

add: value
    ^ self addLast: value
!

addFirst: value
    | position i t |
    " Check if this is first one. "
    (lastIndex == 0) ifTrue: [
	" Easy, just set first element to value "
	lastIndex <- 1.
	runs at: 1 put: 1.
	values at: 1 put: value.
	^ value
    ].
    " Check if first element is same as this "
    ((values at: 1) = value) ifTrue: [
	lastIndex <- lastIndex + 1.
	runs at: 1 put: (1 + (runs at: 1)).
	^ value
    ].
    ((index < 1) or: [ index > lastOffset ] ifTrue: [
	^ self error: 'subscript out of range' ].
    position <- 1.
    i <- 1.
    [ (position > index) and: [ i < lastIndex ] ] whileTrue: [
	t <- position + (runs at: i).
	(t < index) ifTrue: [ ^ values at: i ].
	position <- t.
	i <- i + 1
    ].
    ^ values at: i
!

addLast: value
! !

! RunArray methodsFor: 'copying' !

shallowCopy
    | newArray |
    newArray <- self species new: self size.
    newArray replaceFrom: 1 to: self size with: self.
    ^newArray
! !

! RunArray methodsFor: 'modifying' !

at: index put: anObject
!

atAllPut: anObject
    1 to: self size do: [ :index | self at: index put: anObject ]
! !

! RunArray methodsFor: 'private' !

setSize: anInteger
     lastOffset <- anInteger.
     lastIndex <- 0.
     lastRun <- nil.
     runs <- Array new: 32.
     values <- Array new: 32.
! 

replaceFrom: start to: stop with: replacementCollection startingAt: repStart
    (self == replacementCollection and: [ repStart ~= 1 ])
        ifTrue: [ ^self error: 'replaceFrom:to:with:startingAt: called for 
in-place replacement, but starting index was not 1' ].
    "speed this up by making it zero based, otherwise we have to subtract
     1 from each use of index, and add one to the range"
    0 to: stop - start  do:
        [ :index |
          self at: (start + index)
               put: (replacementCollection at: (repStart + index)) ]
! !

! RunArray methodsFor: 'copying' !

, aRunArry
    | newCollection |
    newCollection <- self species new: (self size + aRunArry size)
.
    newCollection replaceFrom: 1 to: self size with: self.
    newCollection replaceFrom: (self size) + 1
                  to: self size + aRunArry size
                  with: aRunArry.
    ^newCollection
!

copyFrom: start to: stop
    | newCollection len |
    len <- stop - start + 1.
    newCollection <- self species new: len.
    newCollection replaceFrom: 1 to: len with: self startingAt: start.
    ^newCollection
!

copyReplaceAll: oldSubCollection with: newSubCollection
    | numOld newCollection sizeDifference newSubSize oldSubSize
      newStart oldStart copySize index |
    numOld <- self countSubCollectionOccurrencesOf: oldSubCollection.
    newSubSize <- newSubCollection size.
    sizeDifference <- newSubSize - oldSubCollection size + 1.
    newCollection <- self species new: (self size - (sizeDifference * numOld)).
    oldStart <- newStart <- 1.
    [ index <- self indexOfSubCollection: oldSubCollection
                   startingAt: oldStart.
      index > 0 ] whileTrue:
        [ copySize <- index - oldStart + 1.
          newCollection replaceFrom: newStart
                        to: newStart + copySize - 1
                        with: self
                        startingAt: oldStart.
          newStart <- newStart + copySize - 1.
          newCollection replaceFrom: newStart
                        to: newStart + newSubSize - 1
                        with newSubCollection.
          oldStart <- oldStart + copySize.
          newStart <- newStart + newSubSize ].
    "Copy the remaining part of self onto the tail of the new collection."
    newCollection replaceFrom: newStart
                 to: newCollection size
                 with: self
                 startingAt: oldStart.
    ^newCollection
!

copyReplaceFrom: start to: stop with: replacementCollection
    | newCollection newSize repSize |
    "### check for bounds "
    repSize <- replacementCollection size.
    newSize <- self size + repSize - (stop - start + 1).
    newCollection <- self species new: newSize.
    newCollection replaceFrom: 1 to: start - 1 with: self startingAt: 1.
    newCollection replaceFrom: start
                  to: start + repSize - 1
                  with: replacementCollection.
    newCollection replaceFrom: start + repSize
                  to: newCollection size
                  with: self
                  startingAt: stop + 1.
    ^newCollection
! !

! RunArray methodsFor: 'enumerating' !

do: aBlock
    "Evaluate aBlock for all elements in the sequenceable collection"
    1 to: self size do:
        [ :i | aBlock value: (self at: i) ]
!

findFirst: aBlock
    "Returns the index of the first element of the sequenceable collection
    for which aBlock returns true"
    1 to: self size do:
        [ :i | (aBlock value: (self at: i))
                 ifTrue: [ ^i ] ].
    ^0
!

findLast: aBlock
    self size to: 1 by: -1 do:
        [ :i | (aBlock value: (self at: i))
                 ifTrue: [ ^i ] ].
    ^0
!

reverseDo: aBlock
    self size to: 1 by: -1 do:
        [ :i | aBlock value: (self at: i) ]
!

with: aRunArry do: aBlock
    self size = aRunArry size
        ifFalse:
            [ ^self error: 'runArray collections must have same size' ].
    1 to: self size do:
        [ :i | aBlock value: (self at: i)
                      value: (aRunArry at: i) ]
! !

! RunArray methodsFor: 'private' !

countSubCollectionOccurrencesOf: aSubCollection
    | colIndex subColIndex count |
    colIndex <- 1.
    count <- 0.
    [ subColIndex <- self indexOfSubCollection: aSubCollection
                         startingAt: colIndex.
      subColIndex > 0 ] whileTrue:
        [ count <- count + 1.
          colIndex <- colIndex + aSubCollection size ].
    ^count
!

grow
    | newCollection |
    newCollection <- self species new: self basicSize + self growSize.
    newCollection replaceFrom: 1 to: self size with: self.
    ^self become: newCollection
!
    
growSize
    ^32

! !

Object subclass: 'TextStyle'
       instanceVariableNames: 'name size font bold italic align' 
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Graphic-Kernel' !

! TextStyle class methodsFor: 'access' !

systemFont
	^ self new systemFont
!

family: aName
	^ self new family: aName
!

family: aName size: aSize
	^ self new family: aName size: aSize
! !

! TextStyle methodsFor: 'access' !

size
	^ size
!

name
	^ name
!

align
	^ align
!

style
	| index |
	index <- 1.
	italic ifTrue: [ index <- index + 1 ].
	bold ifTrue: [ index <- index + 2 ].
	^ #( #normal #italic #bold #bolditalic ) at: index
!

italic
	^ italic
!

bold
	^ bold
!

font
	| index |
	index <- 1.
	italic ifTrue: [ index <- index + 1 ].
	bold ifTrue:  [ index <- index + 2 ].
	^ font at: index
! !

! TextStyle methodsFor: 'modifying' !

systemFont
	| family f |
	font <- Font systemFont.
	f <- font at: 1.
	name <- f name.
	size <- f size.
	bold <- false.
	italic <- false.
	align <- #normal
!

family: aName
	| family f |
	family <- FontFamilies at: aName asSymbol ifAbsent: [ nil ].
	family isNil ifFalse: [ family do: [ :e | font <- e ] ]
	    ifTrue: [ font <- SystemFont ].
	f <- font at: 1.
	name <- f name.
	size <- f size.
	bold <- false.
	italic <- false.
	align <- #normal
!

family: aName size: aSize
	| family f |
	family <- FontFamilies at: aName asSymbol ifAbsent: [ nil ].
	family isNil ifFalse: [
	    font <- family at: aSize ifAbsent: [ nil ].
	    font isNil ifTrue: [ family do: [ :e | font <- e ] ].]
	    ifTrue: [ font <- SystemFont ].
	f <- font at: 1.
	name <- f name.
	size <- f size.
	bold <- false.
	italic <- false.
	align <- #normal
!

size: aSize
	| family f |
	family <- FontFamilies at: name asSymbol ifAbsent: [ nil ].
	font <- family at: size ifAbsent: [ font ].
	f <- font at: 1.
	name <- f name.
	size <- f size.
!

style: aStyle
	aStyle == #Bold ifTrue: [ ^ self bold ].
	aStyle == #Italic ifTrue: [ ^ self italic ].
	aStyle == #BoldItalic ifTrue: [ ^ self bolditalic ].
	^ self none
!

align: aSymbol
	align <- aSymbol
!

none
	bold <- false.
	italic <- false.
!

normal
	align <- #normal
!

bolditalic
	bold <- true.
	italic <- true.
!

bold
	bold <- true.
!

italic
	italic <- true.
!

nobold
	bold <- false
!

noitalic
	italic <- false
! !

! TextStyle methodsFor: 'testing' !

= aTextStyle
    (self class = aTextStyle class ) ifFalse: [ ^ false ].
    italic = aTextStyle italic ifFalse: [ ^ false ].
    bold = aTextStyle bold ifFalse: [ ^ false ].
    align = aTextStyle align ifFalse: [ ^ false ].
    name = aTextStyle name ifFalse: [ ^ false ].
    size = aTextStyle size ifFalse: [ ^ false ].
    ^ true
! !

ArrayedCollection subclass: 'Text'
       instanceVariableNames: 'string runs'
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Collections' !

Text comment: 
'My instances represent text string with embeded font and formating rules.' !


! Text methodsFor: 'Conversion' !

asSymbol
	^ string asSymbol
! !

! Text methodsFor: 'accessing' !

size
    ^ string size
!

at: index
     ^ string at: index
!

basicAt: index
     ^ string basicAt: index
! !

! Text methodsFor: 'modifying' !

at: index put: value
    ^ string at: index put: value
!

basicAt: index put: value
    ^ string basicAt: index put: value
! !

! Text class methodsFor: 'instance creation' !

fromString: aString
    ^aString copyFrom: 1 to: aString size
!

readFrom: aStream
    ^ (String readFrom: aStream ) asText
! !

! Text methodsFor: 'comparing' !

< aText
    "Return true if the receiver is less than aString, ignoring case
    differences."
    self >= aText ifTrue: [ ^false ]
                    ifFalse: [ ^true ]
!

> aText
    "Return true if the receiver is greater than aString, ignoring case
    differences."
    self <= aText ifTrue: [ ^false ]
                    ifFalse: [ ^true ]
!

<= aText
    ^ string <= aText asString 
!

>= aText
    ^ string >= aText asString 
!

sameAs: aText
    "Returns true if the receiver is the same string as aString, ignoring
    case differences."
    self size ~= aText size ifTrue: [ ^false ].
    1 to: self size do:
        [ :i | (self at: i) asLowercase ~= (aText at: i) asLowercase
                ifTrue: [ ^false ] ].
    ^true
!


match: aText
    ^self asLowercase matchSubstring: 1 in: aText asLowercase at: 1
! !

! Text methodsFor: 'converting' !

asUppercase
    "Returns a copy of self as an uppercase string"
    | newStr |
    newStr <- self species new: self size.
    1 to: self size do:
        [ :i | newStr at: i put: (self at: i) asUppercase ].
    ^newStr
!

asLowercase
    "Returns a copy of self as a lowercase string"
    | newStr |
    newStr <- self species new: self size.
    1 to: self size do:
        [ :i | newStr at: i put: (self at: i) asLowercase ].
    ^newStr
!

asString
    ^string
!

asByteArray
    | byteArray size |
    size <- self size.
    byteArray <- ByteArray new: size.
    byteArray replaceFrom: 1 to: size withString: self startingAt: 1.
    ^byteArray
!

asInteger
    | result |
    result <- 0.
    self do: 
        [ :ch | ch isDigit
                    ifFalse: [ ^result ].
                result <- result * 10 + ch digitValue ].
    ^result
! !

! Text methodsFor: 'copying' !

shallowCopy
    | newStr |
    newStr <- self species new: self size.
    1 to: self size do:
        [ :i | newStr at: i put: (self at: i) ].
    ^newStr
!

deepCopy
    ^self shallowCopy
!

, aString
    "Join aString onto end of string"
    | newString index len |
    " Make new string "
    len <- self size + aString size. 
    newString <- String new: len.
    index <- 1.
    " Copy first string to new location "
    1 to: self size do: [ :i | newString at: index put: (self at: i ).
			  index <- index + 1].
    " Now copy over second string "
    1 to: aString size do: [ :i | newString at: index put: (aString at: i ).
			  index <- index + 1].
    ^ newString
! !


! Text methodsFor: 'printing' !

printOn: aStream
    self storeOn: aStream
! !

! Text methodsFor: 'storing' !

storeOn: aStream
    aStream nextPut: $'.
    self do:
        [ :char | char == $' ifTrue: [ aStream nextPut: char ].
                  aStream nextPut: char ].
    aStream nextPut: $'
! !

! Text methodsFor: 'private' !

matchSubstring: p in: aString at: s
    | pc |
    p > self size
        ifTrue: [ ^s > aString size ].
    pc <- self at: p.
    pc = $*
        ifTrue: [ s to: (aString size) + 1 do:
                    [ :ss | (self matchSubstring: p + 1
                                  in: aString
                                  at: ss)
                                ifTrue: [ ^true ] ].
                  ^false ].
    s > aString size ifTrue: [ ^false ].
    pc = $#
        ifTrue: [ ^self matchSubstring: p + 1 in: aString at: s + 1 ].

    pc = (aString at: s)
        ifTrue: [ ^self matchSubstring: p + 1 in: aString at: s + 1 ].
    ^false
! !

! Text methodsFor: 'emphasis' !

allBold
!

emphasisAt: index
!

emphasizeFrom: start to: stop: with emphasis
!

makeBoldFrom: start to: stop
!

runLengthFor: index
! !


DisplayObject subclass: 'DisplayText'
  instanceVariableNames: 'text form'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics-Kernel'
!

! DisplayText methodsFor: 'accessing' !

form
!

numberOfLines
!

string
!

text
!

numberOfLines
! !

! DisplayText methodsFor: 'modifying' !

text: aText
! !

! DisplayText methodsFor: 'display box' !

boundingBox
!

computeBoundingBox
! !

! DisplayText methodsFor: 'converting' !

asTextBuffer
! !

! DisplayText methodsFor: 'displaying' !

displayOn: aDisplayMedium
                at: aDisplayPoint
                clippingBox: clipRectangle
                rule: ruleInteger
                mask: aForm
                    "Display the receiver at location aDisplayPoint
                    with rule, ruleInteger, and halftone mask,
                    aForm.  Information to be displayed must be
                    confined to the area that intersects with
                    clipRectangle."
    (BitBlt destForm: aDisplayMedium sourceForm: self halftoneForm: aForm
            combinationRule: ruleInteger destOrigin: aDisplayPoint + offset
	    sourceOrigin: 0@0 extent: width @ height clipRect: clipRectangle)
	copyBits
!

displayOn: aDisplayMedium
                at: aDisplayPoint
                clippingBox: clipRectangle
                rule: ruleInteger
                    "As above with mask a black Form (nil)."
    self displayOn: aDisplayMedium at: aDisplayPoint
          clippingBox: clipRectangle rule: ruleInteger mask: nil
!

displayOn: aDisplayMedium
                at: aDisplayPoint
                clippingBox: clipRectangle
                    "As above with rule `over'."
    self displayOn: aDisplayMedium at: aDisplayPoint
          clippingBox: clipRectangle rule: Form over mask: nil
!

displayOn: aDisplayMedium
                at: aDisplayPoint
                    "As above with clipping rectangle the whole
                    of aDisplayMedium."
    self displayOn: aDisplayMedium at: aDisplayPoint
          clippingBox: aDisplayMedium boundingBox
	  rule: Form over mask: nil
!

displayOn: aDisplayMedium
                            "As above at point 0@0."
    self displayOn: aDisplayMedium at: 0@0
          clippingBox: aDisplayMedium boundingBox
	  rule: Form over mask: nil
!

displayAt: aDisplayPoint
                    "Display the receiver at location aDisplayPoint
                    with rule `over' or `storing'; halftone mask, a
                    black Form (nil); clipping rectangle the whole display
                    screen; onto the display screen (Display)."
    self displayOn: Display at: aDisplayPoint
          clippingBox: Display boundingBox
	  rule: Form over mask: nil
!

display
                    "Display the receiver at location 0@0."
    self displayOn: Display at: 0@0
          clippingBox: Display boundingBox
	  rule: Form over mask: nil
! !

! DisplayText class methodsFor: 'instance creation' !

text: aText
!

text: aText offset: aPoint
! !

DisplayText subclass: 'TextBuffer'
  instanceVariableNames: ''
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Graphics-Kernel'
!

! TextBuffer methodsFor: 'accessing' !

text

! !

! TextBuffer methodsFor: 'modifying' !

insertText: aText
!

deleteNext: aInteger
!

replaceFrom: start to: stop: with: aText displaying: aBoolean
!

text: aText
!

setInsertPoint: aIndex
! !

! TextBuffer methodsFor: 'selection' !
! !

! TextBuffer methodsFor: 'scrolling' !

scrollTo: anInteger
    textTop <- anInteger.
    textTop > textHeight
        ifTrue: [ textTop <- textHeight ].
    textTop < 0
        ifTrue: [ textTop <- 0 ].
    Display white: (offset extent: extent).
    Display border: (offset extent: extent)
            widthRectangle: borderWidth
	    mask: Form black.
    self showText
!

scrollPosition
    textTop isNil
        ifTrue: [ ^0 ]
	ifFalse: [ ^textTop ]
! !


ScrollController subclass: 'TextBufferEditor'
  instanceVariableNames: ''
  classVariableNames: 'BlueMenu'
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! TextBufferEditor methodsFor: 'initialize' !

initialize
     super initialize.
     BlueMenu isNil ifTrue: [
          BlueMenu <- Menu labelArray: #( 'again' 'undo' 'copy'
				 'cut' 'paste' 'do it' 'print it' 'accept'
				 'cancel')
                                 lines: #( 2 5 7)
				 selectors: #(again undo copySelect cut paste
				   doit printit accept cancel).
     ].
     self blueButtonMenu: BlueMenu notifying: self.
! !

! TextBufferEditor methodsFor: 'control' !

controlActivity
    Sensor keyboardPressed
        ifTrue: [ ^view keypress: Sensor keyboard ].
    super controlActivity
!

redButtonActivity
    | position oldPosition |
    oldPosition <- Sensor mousePoint.
    view setInsertPointFrom: oldPosition.
    [ Sensor waitMouse. Sensor redButtonPressed ]
           whileTrue: [  position <- Sensor mousePoint.
	                position = oldPosition
		            ifFalse: [ oldPosition <- position.
			               view setSelectionFrom: position ] ].
! !

! TextBufferEditor methodsFor: 'editing' !

again
   view again
!

undo
   view undo
!

copySelect
   view copySelect
!

cut
   view cut
!

paste
   view paste
!

doit
   view doit
!

printit
   view printit
!

cancel
    view cancel
!

accept
    ^self changed
!

contents
    stdout nextPutAll: view contents. stdout nl
! !

View subclass: 'TextView'
  instanceVariableNames: 'buffer lineStart lineEnd lineHeight textHeight textWidth textTop insertPoint currentLine charScanner selectStart selectPoint beforeSize gapSize afterSize original cutbuffer againcmd'
  classVariableNames: 'InsertPoint'
  poolDictionaries: ''
  category: 'Graphics Windows'
!

! TextView class methodsFor: 'initialize' !

initialize
    InsertPoint <- Form extent: 8@4
                      fromArray: #(
				2r00011000
				2r00111100
				2r01100110
				2r11000011)
		      offset: -4@0
! !

! TextView class methodsFor: 'displaying' !

on: aModel aspect: aName change: changeSelector
	menu: aMenu initialSelection: aItem
    | aView |
    aView <- super new.
    aView model: aModel ;
          changed: changeSelector;
	  name: aName .
    aMenu isNil ifFalse: [ 
          aView controller blueButtonMenu: aMenu notifying: aView controller ].
    ^ aView
! !

! TextView methodsFor: 'initialising' !

initialize
    | code |
    " Initialize line arrays "
    stderr nextPutAll: 'TextView initialize'.  stderr nl.
    super initialize.
    insetBox isNil ifTrue: [ insetBox <- Display boundingBox ].
    original <- ''.
    lineStart <- OrderedCollection new.
    lineHeight <- OrderedCollection new.
    insertPoint <- nil.
    currentLine <- 1.
    selectStart <- nil.
    selectPoint <- nil.
    gapSize <- 0.
    beforeSize <- 0.
    afterSize <- 0.
    buffer <- original copy.
    
    " Set up scanner "
    charScanner <- CharacterScanner text: buffer 
	destForm: Display font: Font systemFont
        combinationRule: Form over destOrigin: 0@0
        extent: ((self width)@(self height)) clipRect: nil.
    self setGap: self defaultGapSize.
    charScanner printing: false.
    charScanner stopcode: (Character backspace asciiValue + 1) put: #bs.
    charScanner stopcode: (Character tab asciiValue + 1) put: #tab.
    charScanner stopcode: (Character cr asciiValue + 1) put: #cr.
    charScanner stopcode: (Character nl asciiValue + 1) put: #nl.
    charScanner startX: 0.
    charScanner stopX: insetBox width.
    textWidth <- 0.
    textHeight <- 0.
    textTop <- 0.
    lineStart add: 1.
    lineStart add: 1.
    lineHeight add: 0.
    textHeight <- charScanner fontHeight.
!

setContentsFrom: aString
    | code |
    " Initialize line arrays "
    stderr nextPutAll: 'setContentsFrom: '. stderr nextPutAll: aString.
	stderr nl.
    insetBox isNil ifTrue: [ insetBox <- Display boundingBox ].
    original <- aString.
    lineStart <- OrderedCollection new.
    lineHeight <- OrderedCollection new.
    insertPoint <- nil.
    currentLine <- 1.
    selectStart <- nil.
    selectPoint <- nil.
    " Copy aString to work buffer "
    gapSize <- 0.
    beforeSize <- 0.
    afterSize <- aString size.
    buffer <- original copy.
    
    " Set up scanner "
    charScanner <- CharacterScanner text: buffer 
	destForm: Display font: Font systemFont
        combinationRule: Form over destOrigin: 0@0
        extent: ((self width)@(self height)) clipRect: nil.
    self setGap: self defaultGapSize.
    charScanner printing: false.
    charScanner stopcode: (Character backspace asciiValue + 1) put: #bs.
    charScanner stopcode: (Character tab asciiValue + 1) put: #tab.
    charScanner stopcode: (Character cr asciiValue + 1) put: #cr.
    charScanner stopcode: (Character nl asciiValue + 1) put: #nl.
    charScanner startX: 0.
    charScanner stopX: insetBox width.
    charScanner textPos: gapSize.
    textWidth <- 0.
    textHeight <- 0.
    textTop <- 0.
    lineStart add: 1.

    [ code <- charScanner scanword: buffer size.
      code == #endRun ] whileFalse: [
	textWidth <- textWidth max: charScanner destX.
	charScanner textPos printOn: stderr. stderr space.
	code printOn: stderr. stderr space.
	      code == #stopX ifTrue: [
		lineHeight add: charScanner destY.
		lineStart add: charScanner textPos.
		charScanner nextline ].
         code == #nl ifTrue: [
		lineHeight add: charScanner destY.
		lineStart add: (charScanner textPos + 1).
		charScanner nextline ].
	code == #bs ifTrue: [ charScanner backspace ].
	code == #tab ifTrue: [ charScanner tab ].
	    charScanner nextChar.
    ].
    stderr nl.
    lineHeight add: charScanner destY.
    charScanner nextline.
    lineStart add: (charScanner textPos) - 1.
    textHeight <- charScanner destY.
    lineStart printOn: stderr. stderr nl.
    lineHeight printOn: stderr. stderr nl.
    textHeight printOn: stderr. stderr nl.
    textWidth printOn: stderr. stderr nl.
! !

! TextView methodsFor: 'accessing' !

defaultControllerClass
    ^TextController
!

fullHeight
    textHeight == 0
        ifTrue: [ ^self height ]
        ifFalse: [ ^textHeight ]
! !

! TextView methodsFor: 'displaying' !

display
    displayed <- true.
    extent isNil
        ifTrue: [ self error: 'TextView has no extent!!' ].
    Display white: (offset extent: extent).
    Display border: (offset extent: extent)
            widthRectangle: borderWidth
	    mask: Form black.
    textTop isNil
        ifTrue: [ textTop <- 0 ].
    self showText.
    subviews isNil
        ifFalse: [ subviews do: [ :view | view display ] ]
!

displayString: aString at: newPoint
!

showText
    | start end second last line lineLen temp textBottom moreText |
    " Set up scanner. "
   stderr nextPutAll: 'showText '.
    buffer printOn: stderr. stderr nl.
    beforeSize printOn: stderr. stderr space.
    afterSize printOn: stderr. stderr space.

    lineStart size = 1 ifTrue: [ ^ self ].
    " Compute where we need to display "
    start <- 1.
    end <- lineHeight size.
    textBottom <- textTop + insetBox height.
    textTop printOn: stderr. stderr space.
    textBottom printOn: stderr. stderr space.
    1 to: lineHeight size do: [ :t |
	 temp <- lineHeight at: t.
	 temp < textTop ifTrue: [ start <- t ].
	 temp <= textBottom ifTrue: [ end <- t ].
    ].
    " Do dirty work of displaying text "
    line <- start.
    start <- lineStart at: start.

    
   stderr nextPutAll: 'start='.
   start printOn: stderr. stderr space.
   end printOn: stderr. stderr space.
   end <- lineStart at: (end + 1).
   line printOn: stderr. stderr space.
   
    " Set up scanner to correct start point.  "
    charScanner printing: true.
    temp <- textTop - (lineHeight at: line).
    charScanner setRect: insetBox offset: temp negated.

    charScanner destRect printOn: stderr. stderr space.
    insertPoint <- nil.

    second <- start > (beforeSize + gapSize).
    " Set end of line, but don't go into gap "
    lineLen <- lineStart at: (line + 1).
    (second not and: [ lineLen > beforeSize ]) ifTrue: [ lineLen <- beforeSize + 1].
    second printOn: stderr. stderr space.

    charScanner textPos: start.

    " Check if at insert point "
    start == lineLen ifTrue: [
	insertPoint <- (0@(charScanner fontHeight)) + charScanner destPoint.
	second <- true.
	charScanner textPos: (beforeSize + gapSize).
	lineLen <- lineStart at: (line + 1).
    ]. 
    stderr nextPutAll: 'text='.
    charScanner textPos printOn: stderr. stderr space.
    lineLen printOn: stderr. stderr nl.
    moreText <- true.
    [ moreText ] whileTrue: [
	stderr nextPutAll: 'Scanning start at: '.
    charScanner textPos printOn: stderr. stderr space.
	lineLen printOn: stderr. stderr space.
       [ temp <- charScanner scanword: (lineLen - 1).
          (temp == #endRun or: [ temp == #stopX ] ) ] whileFalse: [
	   " temp == #nl ifTrue: [ charScanner nextline ]."
	    temp == #bs ifTrue: [ charScanner backspace ].
	    temp == #tab ifTrue: [ charScanner tab ].
	    charScanner nextChar.
	].
	 temp printOn: stderr. stderr space.
	
  
         charScanner textPos printOn: stderr. stderr space.
         second printOn: stderr. stderr nl.
	(second not and: [charScanner textPos = (beforeSize + 1)]) ifTrue: [
		stderr nextPutAll: 'Set Ip'. stderr nl.
		insertPoint <- (0@(charScanner fontHeight)) + charScanner destPoint.
		second <- true.
		charScanner textPos: (beforeSize + gapSize).
		lineLen <- lineStart at: (line + 1).
	] ifFalse: [
            charScanner textPos >= end 
	ifTrue: [ moreText <- false ]
	ifFalse: [
		temp == #endRun ifTrue: [ charScanner nextline. ].
		 line <- line + 1.
                               lineLen <- lineStart at: (line + 1).
		(second not and: [ lineLen > beforeSize ]) ifTrue: [ lineLen <- beforeSize + 1].
	].
            ].
    ].

    insertPoint printOn: stderr. stderr nl.
    insertPoint isNil ifFalse: [ InsertPoint displayOn: Display at: insertPoint
			       clippingBox: insetBox rule: Form reverse.
	self reverseSelection.

    ].
!

clearSelection
	selectStart isNil ifFalse: [ self reverseSelection ].
	selectStart <- nil.
	selectPoint <- nil.
!

reverseSelection
	| temp start |

        " Display highlighted section "
	insertPoint isNil ifTrue: [
		selectStart <- nil.
		selectPoint <- nil.
		^ self ].	
        selectStart isNil ifTrue: [ ^self ].
	selectStart == beforeSize ifTrue: [ ^ self ].
	selectPoint <- self indexToPoint: selectStart + 1.

    " Set up scanner to correct start point.  "
   	charScanner printing: false.
	charScanner setRect: insetBox offset: 0.
	charScanner destOrigin: selectPoint. 

	charScanner textPos: selectStart + 1.
	start <- charScanner destPoint.
    	[ temp <- charScanner scanword: beforeSize.
     	     temp == #endRun ] whileFalse: [
	    (temp == #nl or: [ temp == #stopX ] ) ifTrue: [
   		 (BitBlt destForm: Display sourceForm: nil 
			 halftoneForm: Form black combinationRule: Form reverse
			 destOrigin: start sourceOrigin: start extent: 
			(charScanner destX - start x) @ (charScanner fontHeight)
	   		 clipRect: insetBox )
			copyBits.
		 charScanner nextline.
		 start <- charScanner destPoint.
	    ].
	    temp == #bs ifTrue: [ charScanner backspace ].
	    temp == #tab ifTrue: [ charScanner tab ].
	    charScanner nextChar.
	].
	(BitBlt destForm: Display sourceForm: nil halftoneForm: Form black
        	combinationRule: Form reverse destOrigin: start
	    	sourceOrigin: start extent: 
		(charScanner destX - start x) @ (charScanner fontHeight)
	   	 clipRect: insetBox )
		copyBits. 
	
! !

! TextView methodsFor: 'mouse-action' !

getSelection
	| selection |
	selectStart isNil ifTrue: [ ^ cutbuffer ].
	selection <- buffer species new: (beforeSize - selectStart).
	selection size printOn: stderr. stderr space.
	selection replaceFrom: 1 to: selection size with: buffer
		startingAt: selectStart + 1.
	selection printOn: stderr. stderr nl.
	^ selection
!

again
!

undo
!

copySelect
	cutbuffer <- self getSelection.
	selectStart isNil ifTrue: [
		self reverseSelection.
		selectStart <- nil.
	]
!

cut
	" Check if we have a selection. "
	cutbuffer <- self getSelection.
	selectStart isNil ifTrue: [ ^ self ].
	self deleteBefore: (beforeSize - selectStart).
	selectStart <- nil.
!

paste
	self clearSelection.
	cutbuffer isNil ifFalse: [ self insertString: cutbuffer ].
!

doit
	| cmd |
	cmd <- self getSelection.
	Compiler evaluate: cmd.
!

printit
	| cmd result sel |
	cmd <- self getSelection.
	self clearSelection.
	result <- (Compiler evaluate: cmd) printString.
	sel <- beforeSize.
	self insertString: result.
	selectStart <- sel.
	self reverseSelection.
!

keypress: aKey
    | aStream aChar moveChar aString |
    stderr nextPutAll: 'TextView keypress: '.
     aKey printOn: stderr.  stderr space.
     aKey class printOn: stderr. stderr nl.
    aChar <- aKey asCharacter.
    Character cr = aChar ifTrue: [ aChar <- Character nl ].
    Character backspace = aChar ifTrue: [
	self deleteBefore: 1.
	^ aKey
    ].
    aKey = 127 ifTrue: [ 
	self deleteAfter: 1.
	^ aKey
    ].
    aKey = 128 ifTrue: [
	" Begining of line "
	self setInsertPoint: (lineStart at: currentLine).
	^ aKey
    ].
    aKey = 129 ifTrue: [
	" Left "
	self setInsertPoint: beforeSize - 1.
	^ aKey
    ].
    aKey = 130 ifTrue: [
	" up "
	^ aKey
    ].
    aKey = 131 ifTrue: [
	" Right "
	self setInsertPoint: beforeSize + 1.
	^ aKey
    ].
    aKey = 132 ifTrue: [
	" Down "
	^ aKey
    ].
    aKey = 133 ifTrue: [
	" Page Up "
	^ aKey
    ].
    aKey = 134 ifTrue: [
	" Page Down "
	^ aKey
    ].
    aKey = 135 ifTrue: [
	" End "
	self setInsertPoint: (lineStart at: currentLine + 1).
	^ aKey
    ].
    aKey = 136 ifTrue: [
	" Begin "
	self setInsertPoint: 0.
	^ aKey
    ].
     self insertString: aChar asString.
    ^aKey
!

setSelectionFrom: newPoint
    | newStart temp |
     stderr nextPutAll: 'setSelectionFrom: '.
	newPoint printOn: stderr. stderr space.
	selectStart printOn: stderr. stderr space.
	beforeSize printOn: stderr. stderr nl.
    newStart <- self pointToIndex: newPoint.
    newStart printOn: stderr. stderr nl.
    self reverseSelection.
    newStart > selectStart ifTrue: [ 
	self setInsertPoint: newStart.
     ] ifFalse: [
	 selectStart <- newStart.
     ].
     stderr nextPutAll: 'newSelection: '.
	selectStart printOn: stderr. stderr space.
	beforeSize printOn: stderr. stderr nl.
     self reverseSelection.
!

setInsertPointFrom: newPoint
    | aPoint line temp moreText second lineLen  |
    self clearSelection.
    stderr nextPutAll: 'setInsertPointFrom: '.
    newPoint printOn: stderr.  stderr space.
    aPoint <- (newPoint - insetBox origin) + (0@textTop).
    aPoint printOn: stderr. stderr space.
    " Compute line and offset into line of point "
    line <- 1.
    1 to: lineHeight size do: [ :t |
	 (lineHeight at: t) < aPoint y  ifTrue: [ line <- t ].
    ].
    line printOn: stderr. stderr nl.
    line > lineStart size ifTrue: [ line <- lineStart size ].
    " Set up scanner to correct start point.  "
    charScanner printing: false.
    charScanner startX: 0.
    charScanner stopX: aPoint x.
    charScanner width: insetBox width.
    charScanner height: insetBox height.
    charScanner destX: 0.
    charScanner destY: 0. 
    temp <- lineStart at: line.
    
    second <- temp > (beforeSize + gapSize).
    " Set end of line, but don't go into gap "
    lineLen <- lineStart at: (line + 1).
    (second not and: [ lineLen > beforeSize ]) ifTrue: [ lineLen <- beforeSize + 1].
    second printOn: stderr. stderr space.

    " Check if at insert point "
    temp == lineLen ifTrue: [
	second <- true.
	temp <- beforeSize + gapSize.
	lineLen <- lineStart at: (line + 1).
    ]. 
    charScanner textPos: temp.

    stderr nextPutAll: 'text='.
    charScanner textPos printOn: stderr. stderr space.
    lineLen printOn: stderr. stderr nl.
    moreText <- true.
    [ moreText ] whileTrue: [
	stderr nextPutAll: 'Scanning start at: '.
    charScanner textPos printOn: stderr. stderr space.
	lineLen printOn: stderr. stderr space.
       [ temp <- charScanner scanword: (lineLen - 1).
          temp == #endRun or: [ temp == #stopX]  ] whileFalse: [
	    temp == #nl ifTrue: [ charScanner nextline  ].
	    temp == #bs ifTrue: [ charScanner backspace ].
	    temp == #tab ifTrue: [ charScanner tab ].
	    charScanner nextChar.
	].
         charScanner textPos printOn: stderr. stderr space.
         second printOn: stderr. stderr nl.
	(second not and: [charScanner textPos = (beforeSize + 1)]) ifTrue: [
		charScanner textPos: (beforeSize + gapSize).
		lineLen <- lineStart at: (line + 1).
		second <- true.
	] ifFalse: [ 
                              moreText <- false.
	].
    ].

     charScanner textPos printOn: stderr. stderr space.
     charScanner destX printOn: stderr. stderr nl.

    temp <- charScanner textPos.
    temp > beforeSize ifTrue: [ temp <- temp - gapSize ].
    temp < beforeSize ifTrue: [ temp <- temp - 1].
    self setInsertPoint: temp.
    selectStart <- temp.
!

setCurrentInsert
    | aString x y leftString rightString |
	^self.
    x <- insertPoint x // SystemFontWidth.
    y <- insertPoint y + textTop // SystemFontHeight.
    [ lineStart size <= y ]
        whileTrue: [ lineStart add: '' ].
    "lineNumber <- y + 1.
    aString <- lineStart at: lineNumber."
    leftString <- aString copyFrom: 1 to: x.
    rightString <- aString copyFrom: x + 1 to: aString size.
    currentLine at: 1 put: (WriteStream on: (String new: 0)).
    (currentLine at: 1) nextPutAll: leftString.
    currentLine at: 2 put: (WriteStream on: (String new: 0)).
    (currentLine at: 2) nextPutAll: rightString
! !

! TextView methodsFor: 'accessing' !

contents
    | aString |
    " Copy aString to work buffer "
    aString <- buffer species new: afterSize + beforeSize.
    aString replaceFrom: 1 to: beforeSize 
	with: buffer startingAt: 1.
    aString replaceFrom: beforeSize + 1 to: beforeSize + afterSize
	with: buffer startingAt: beforeSize + 1.
    ^aString
! !

! TextView methodsFor: 'scrolling' !

scrollTo: anInteger
    textTop <- anInteger.
    textTop > textHeight
        ifTrue: [ textTop <- textHeight ].
    textTop < 0
        ifTrue: [ textTop <- 0 ].
    Display white: (offset extent: extent).
    Display border: (offset extent: extent)
            widthRectangle: borderWidth
	    mask: Form black.
    self showText
!

scrollPosition
    textTop isNil
        ifTrue: [ ^0 ]
	ifFalse: [ ^textTop ]
! !

! TextView methodsFor: 'updating' !

cancel
    self setContentsFrom: original.
!

changed
    | selection |
    (model notNil and: [ name notNil and: [ change notNil ] ])
        ifTrue:
	   [ original <- self contents.
	     model preform: change with: original with: controller ]
! !

! TextView methodsFor: 'private' !

indexToPoint: aIndex
   | line start temp lineLen second moreText |
    stderr nextPutAll: 'indexToPoint: '.
    aIndex printOn: stderr. stderr space.

   " Compute line number of aIndex "
   line <- 1.
   1 to: lineStart size do: [:i |
	(lineStart at: i) < aIndex ifTrue: [ line <- i ].
   ].

    line printOn: stderr. stderr space.
    " Recompute carret "
    start <- lineStart at: line.
 stderr nextPutAll: 'start='.
   start printOn: stderr. stderr space.
   " normalize to scrolling top "
    temp <- (lineHeight at: line) - textTop.
  temp printOn: stderr. stderr nl.
    
 
    " Set up scanner to correct start point.  "
    charScanner printing: false.
    charScanner setRect: insetBox offset: temp.

    charScanner destRect printOn: stderr. stderr space.
    charScanner textPos: start.

    " Check if at insert point "
    start == aIndex ifTrue: [ ^ charScanner destPoint ].

    lineLen <- aIndex.
    second <- true.
    (lineLen > beforeSize and: [ start <= beforeSize ]) ifTrue: [
	second <- false.
	 lineLen <- beforeSize ].
    " Scan rest of line "
    moreText <- true.
    [ moreText ] whileTrue: [
	stderr nextPutAll: 'Scanning start at: '.
    charScanner textPos printOn: stderr. stderr space.
	lineLen printOn: stderr. stderr space.
	
       [ temp <- charScanner scanword: (lineLen - 1).
          temp == #endRun ] whileFalse: [
	  temp == #stopX ifTrue: [ charScanner nextline ].
	    temp == #bs ifTrue: [ charScanner backspace ].
	    temp == #tab ifTrue: [ charScanner tab ].
	    charScanner nextChar.
	].
	 temp printOn: stderr. stderr space.
         charScanner textPos printOn: stderr. stderr space.
         second printOn: stderr. stderr nl.
	(second not and: [charScanner textPos = (beforeSize + 1)]) ifTrue: [
		stderr nextPutAll: 'Set Ip'. stderr nl.
		second <- true.
		charScanner textPos: (beforeSize + gapSize).
		lineLen <- aIndex.
	] ifFalse: [ moreText <- false ].
    ].
	charScanner destPoint printOn: stderr. stderr nl.
    ^ charScanner destPoint
!

pointToIndex: newPoint
    | aPoint line temp moreText second lineLen  |
    stderr nextPutAll: 'pointToIndex: '.
    newPoint printOn: stderr.  stderr space.
    aPoint <- (newPoint - insetBox origin) + (0@textTop).
    aPoint printOn: stderr. stderr space.
    " Compute line and offset into line of point "
    line <- 1.
    1 to: lineHeight size do: [ :t |
	 (lineHeight at: t) < aPoint y  ifTrue: [ line <- t ].
    ].
    line printOn: stderr. stderr nl.
    line > lineStart size ifTrue: [ line <- lineStart size ].
    " Set up scanner to correct start point.  "
    charScanner printing: false.
    charScanner startX: 0.
    charScanner stopX: aPoint x.
    charScanner width: insetBox width.
    charScanner height: insetBox height.
    charScanner destX: 0.
    charScanner destY: 0. 
    temp <- lineStart at: line.
    
    second <- temp > (beforeSize + gapSize).
    " Set end of line, but don't go into gap "
    lineLen <- lineStart at: (line + 1).
    (second not and: [ lineLen > beforeSize ]) ifTrue: [ lineLen <- beforeSize + 1].
    second printOn: stderr. stderr space.

    " Check if at insert point "
    temp == lineLen ifTrue: [
	second <- true.
	temp <- beforeSize + gapSize.
	lineLen <- lineStart at: (line + 1).
    ]. 
    charScanner textPos: temp.

    stderr nextPutAll: 'text='.
    charScanner textPos printOn: stderr. stderr space.
    lineLen printOn: stderr. stderr nl.
    moreText <- true.
    [ moreText ] whileTrue: [
	stderr nextPutAll: 'Scanning start at: '.
    charScanner textPos printOn: stderr. stderr space.
	lineLen printOn: stderr. stderr space.
       [ temp <- charScanner scanword: (lineLen - 1).
          temp == #endRun or: [ temp == #stopX]  ] whileFalse: [
	    temp == #nl ifTrue: [ charScanner nextline  ].
	    temp == #bs ifTrue: [ charScanner backspace ].
	    temp == #tab ifTrue: [ charScanner tab ].
	    charScanner nextChar.
	].
         charScanner textPos printOn: stderr. stderr space.
         second printOn: stderr. stderr nl.
	(second not and: [charScanner textPos = (beforeSize + 1)]) ifTrue: [
		charScanner textPos: (beforeSize + gapSize).
		lineLen <- lineStart at: (line + 1).
		second <- true.
	] ifFalse: [ 
                              moreText <- false.
	].
    ].

     charScanner textPos printOn: stderr. stderr space.
     charScanner destX printOn: stderr. stderr nl.

    temp <- charScanner textPos.
    temp > beforeSize ifTrue: [ temp <- temp - gapSize ].
    temp < beforeSize ifTrue: [ temp <- temp - 1].
    ^ temp
!

defaultGapSize
       ^ 10
!

setGap: aInteger
      | newSize newBuffer temp |
      " Don't bother if gap already large enough "
     gapSize > aInteger ifTrue: [ ^ self ].
     newSize <- aInteger max: self defaultGapSize.
     newBuffer <- buffer species new: beforeSize + afterSize + newSize.
     beforeSize > 0 ifTrue: [
    	newBuffer replaceFrom: 1 to: beforeSize with: buffer
	startingAt: 1
	].
     1 to: newSize do: [ :i | newBuffer at: beforeSize + i put: $& ].
     afterSize > 0 ifTrue: [
    	newBuffer replaceFrom: beforeSize + newSize to: newBuffer size
		 with: buffer startingAt: beforeSize + gapSize + 1 ].
	" Readjust start line vector "
	1 to: lineStart size do: [ :i |
		temp <- lineStart at: i.
		temp > (beforeSize + gapSize) ifTrue:
			[ lineStart at: i put:  temp + newSize ].
	].
	buffer <- newBuffer.
	charScanner text: buffer.
	gapSize <- newSize.
! !

! TextView methodsFor: 'editing' !

setInsertPoint: aPosition
     " Set insert point to a given spot. "
    | distance gapEnd newPoint temp start |

    stderr nextPutAll: 'Set insertPoint: '. aPosition printOn: stderr. stderr space.
    " Sanity check new position "
    newPoint <- aPosition.
    newPoint < 0 ifTrue: [ newPoint <- 0 ].
    newPoint > (beforeSize + afterSize) ifTrue: [ newPoint <- beforeSize + afterSize ].
    gapEnd <- beforeSize + gapSize.
    newPoint printOn: stderr. stderr space.
    (newPoint == gapEnd or: [ newPoint == beforeSize ] ) ifTrue: [ stderr nl. ^ self ].

    " Clear old carret if set "
    insertPoint printOn: stderr. stderr nl.
    insertPoint isNil ifFalse: [ InsertPoint displayOn: Display at: insertPoint
			       clippingBox: insetBox rule: Form reverse ].
    insertPoint <- nil.
	stderr nextPutAll: ' textsize= '.
 beforeSize printOn: stderr. stderr space.
 gapSize printOn: stderr. stderr space.
 afterSize printOn: stderr. stderr nl.
	buffer printOn: stderr. stderr space. buffer size printOn: stderr. stderr nl.
    " Check if we need to move forward or backward in text "
    newPoint < beforeSize ifTrue: [
	" Move towards front of document. "
	stderr nextPutAll: ' toward front '.
	distance <- beforeSize - newPoint.
	distance printOn: stderr. stderr space.
	temp <- buffer species new: distance.
	temp replaceFrom: 1 to: distance with: buffer startingAt: newPoint + 1.
	temp printOn: stderr. stderr nl.
	buffer replaceFrom: gapEnd - distance to: gapEnd - 1 with: temp startingAt: 1.
	buffer printOn: stderr. stderr space. buffer size printOn: stderr. stderr nl.
	buffer replaceFrom: newPoint + 1 to: gapEnd - distance - 2 with: '$$$$$$$$$$' startingAt: 1.
	" Adjust line start array. "
	currentLine <- 1.
	newPoint <- newPoint + 1.
	1 to: lineStart size do: [ :t |
		temp <- lineStart at: t.
		(temp > newPoint and: [ temp < gapEnd ]) ifTrue:
			[ lineStart at: t put: temp + gapSize ].
		temp < newPoint ifTrue: [ currentLine <- t ].
	].
	newPoint <- newPoint - 1.
                afterSize <- afterSize + distance.
     ] ifFalse: [
	" Move towards back of document. "
	stderr nextPutAll: ' toward back '.
	distance <- newPoint - beforeSize.
	distance printOn: stderr. stderr space.
	temp <- buffer species new: distance.
	temp replaceFrom: 1 to: distance with: buffer startingAt: gapEnd.
	buffer replaceFrom: beforeSize + 1 to: beforeSize + 1 + distance
		with: temp startingAt: 1.
	buffer replaceFrom: beforeSize + 1 + distance to: gapEnd + distance - 1 with: '##########' startingAt: 1.
	" Adjust line start array. "
	currentLine <- 1.
	newPoint <- newPoint + gapSize.
	1 to: lineStart size do: [ :t |
		temp <- lineStart at: t.
		(temp < newPoint and: [ temp > (beforeSize + 1) ]) ifTrue:
			[ lineStart at: t put: temp - gapSize ].
		temp < newPoint ifTrue: [ currentLine <- t ].
	].
	newPoint <- newPoint - gapSize.
	afterSize <- afterSize - distance.
     ].
     currentLine printOn: stderr. stderr space.
     lineStart printOn: stderr. stderr space.
     beforeSize <- newPoint.
     


    " Set up scanner. "
	stderr nextPutAll: ' textsize= '.
 beforeSize printOn: stderr. stderr space.
 gapSize printOn: stderr. stderr space.
 afterSize printOn: stderr. stderr nl.
 buffer printOn: stderr. stderr nl.

    " Recompute carret "
    start <- lineStart at: currentLine.
   " normalize to scrolling top "
    temp <- (lineHeight at: currentLine) - textTop.
  temp printOn: stderr. stderr nl.

"    (temp < 0 or: [ temp > insetBox height]) ifTrue: [ ^self ]."
    
   stderr nextPutAll: 'start='.
   start printOn: stderr. stderr space.
   
    " Set up scanner to correct start point.  "
    charScanner printing: false.
    charScanner setRect: insetBox offset: temp.

    charScanner destRect printOn: stderr. stderr space.

    charScanner textPos: start.

    " Check if at insert point "
    start == (beforeSize + 1) ifFalse: [
        stderr nextPutAll: 'text='.
        charScanner textPos printOn: stderr. stderr nl.
       [ temp <- charScanner scanword: beforeSize.
          temp == #endRun ] whileFalse: [
	temp printOn: stderr. stderr space.
	    temp == #bs ifTrue: [ charScanner backspace ].
	    temp == #tab ifTrue: [ charScanner tab ].
	    charScanner nextChar.
	].
       ].

    insertPoint <- (0@(charScanner fontHeight)) + charScanner destPoint.
    insertPoint printOn: stderr. stderr nl.
   InsertPoint displayOn: Display at: insertPoint
		  clippingBox: insetBox rule: Form reverse.
!

reformatAfter
    | start end second last line lineLen temp textBottom moreText
	newStart newHeight |
    " Set up scanner. "
   stderr nextPutAll: 'reformatAfter '.
    buffer printOn: stderr. stderr nl.
    beforeSize printOn: stderr. stderr space.
    gapSize printOn: stderr. stderr space.
    afterSize printOn: stderr. stderr space.
    newStart <- OrderedCollection new.
    newHeight <- OrderedCollection new.

    " Clear cursor "
    insertPoint isNil ifFalse: [ InsertPoint displayOn: Display at: insertPoint
			       clippingBox: insetBox rule: Form reverse ].
    " Copy stuff before we changed it "
    1 to: currentLine do: [ :i |
	newStart add: (lineStart at: i ).
	newHeight add: (lineHeight at: i).
    ].
    textBottom <- textTop + insetBox height.
    textBottom printOn: stderr. stderr space.
    " Do dirty work of displaying text "
    line <- currentLine.
    start <- newStart at: currentLine.
    temp <- (lineHeight at: currentLine) - textTop.
    
   stderr nextPutAll: 'start='.
   start printOn: stderr. stderr space.
   
    " Set up scanner to correct start point.  "
    charScanner printing: true.
    charScanner setRect: insetBox offset: temp.

    charScanner destRect printOn: stderr. stderr space.
    insertPoint <- nil.

    second <- start > (beforeSize + gapSize).
    " Set end of line, but don't go into gap "
    second ifFalse: [ lineLen <- beforeSize ]
    	   ifTrue: [ lineLen <- buffer size  ].
    second printOn: stderr. stderr space.

    charScanner textPos: start.

    " Check if at insert point "
    start > lineLen ifTrue: [
	insertPoint <- (0@(charScanner fontHeight)) + charScanner destPoint.
	second <- true.
	charScanner textPos: (beforeSize + gapSize).
	lineLen <- buffer size.
    ]. 
    stderr nextPutAll: 'text='.
    charScanner textPos printOn: stderr. stderr space.
    lineLen printOn: stderr. stderr nl.
    (BitBlt destForm: Display sourceForm: nil halftoneForm: Form white
            combinationRule: Form over destOrigin: charScanner destPoint
	    sourceOrigin: charScanner destPoint extent: 
	     (insetBox width) @ (charScanner fontHeight)
	    clipRect: insetBox )
		copyBits. 
    moreText <- true.
    [ moreText ] whileTrue: [
	stderr nextPutAll: 'Scanning start at: '.
    charScanner textPos printOn: stderr. stderr space.
	lineLen printOn: stderr. stderr space.
       [ temp <- charScanner scanword: lineLen.
          temp == #endRun ] whileFalse: [
		temp printOn: stderr. stderr space.
	    temp == #stopX ifTrue: [
		newHeight add: charScanner destY.
		newStart add: charScanner textPos.
		charScanner nextline.
		charScanner destY > textBottom ifTrue: [
			charScanner printing: false
		].
    (BitBlt destForm: Display sourceForm: nil halftoneForm: Form white
            combinationRule: Form over destOrigin: charScanner destPoint
	    sourceOrigin: charScanner destPoint extent: 
	     (insetBox width) @ (charScanner fontHeight)
	    clipRect: insetBox )
		copyBits. 
	     ].
             temp == #nl ifTrue: [
		newHeight add: charScanner destY.
		newStart add: (charScanner textPos + 1).
		charScanner nextline.
		charScanner destY > textBottom ifTrue: [
			charScanner printing: false
		].
    (BitBlt destForm: Display sourceForm: nil halftoneForm: Form white
            combinationRule: Form over destOrigin: charScanner destPoint
	    sourceOrigin: charScanner destPoint extent: 
	     (insetBox width) @ (charScanner fontHeight)
	    clipRect: insetBox )
		copyBits. 
	    ].
	    temp == #bs ifTrue: [ charScanner backspace ].
	    temp == #tab ifTrue: [ charScanner tab ].
	    charScanner nextChar.
	].
	 temp printOn: stderr. stderr space.
	
         charScanner textPos printOn: stderr. stderr space.
         second printOn: stderr. stderr nl.
	second not ifTrue: [
		stderr nextPutAll: 'Set Ip'. stderr nl.
		insertPoint <- (0@(charScanner fontHeight)) + charScanner destPoint.
		second <- true.
		charScanner textPos: (beforeSize + gapSize).
		lineLen <- buffer size.
		afterSize == 0 ifTrue: [ moreText <- false ].
	] ifFalse: [
		moreText <- false 
	].
    ].

    newHeight add: charScanner destY.
    charScanner nextline.
    newStart add: (charScanner textPos) - 1.
    textHeight <- charScanner destY.
 
    lineHeight <- newHeight.
    lineStart <- newStart.
    insertPoint printOn: stderr. stderr nl.
    insertPoint isNil ifFalse: [ InsertPoint displayOn: Display at: insertPoint
			       clippingBox: insetBox rule: Form reverse.
	self reverseSelection.

    ].
!

deleteAfter: aNumber
	" Delete aNumber characters after insert point. "
     | amount |
     amount <- aNumber.
     amount < 0 ifTrue: [ ^ self ].
     amount > afterSize ifTrue: [ amount <- afterSize ].
     afterSize <- afterSize - amount.
     gapSize <- gapSize + amount.
     self reformatAfter.
!

deleteBefore: aNumber
	" Delete aNumber characters before insert point. "
     | amount |
	stderr nextPutAll: 'deleteBefore: '.
	aNumber printOn: stderr. stderr space.
     amount <- aNumber.
     amount < 0 ifTrue: [ ^ self ].
     amount > beforeSize ifTrue: [ amount <- beforeSize ].
	beforeSize printOn: stderr. stderr space.
     beforeSize <- beforeSize - amount.
     gapSize <- gapSize + amount.
	beforeSize printOn: stderr. stderr space.
	gapSize printOn: stderr. stderr space.
     currentLine <- 1.
     1 to: lineStart size do: [ :i |
	(lineStart at: i) < beforeSize ifTrue: [ currentLine <- i]. ].
	currentLine printOn: stderr. stderr nl.
     self reformatAfter.
!

insertString: aString
     | newSize |
     newSize <- aString size.
	stderr nextPutAll: 'insert string: '. aString printOn: stderr.
	stderr space. newSize printOn: stderr. stderr space.
	beforeSize printOn: stderr. stderr space.
     self setGap: newSize.
	beforeSize printOn: stderr. stderr nl.
     buffer replaceFrom: beforeSize + 1 to: beforeSize + newSize + 1
		 with: aString startingAt: 1.
     beforeSize <- beforeSize + newSize.
     gapSize <- gapSize - newSize.
     selectStart <- nil.
     self reformatAfter.
! !

TextView initialize !

Model subclass: 'StringHolder'
      instanceVariableNames: 'contents isLocked'
      classVariableNames: 'WorkSpace'
      poolDictionaries: ''
      category: 'Graphics' !

! StringHolder methodsFor: 'accessing' !

contents
! !

! StringHolder methodsFor: 'modifying' !

contents: aText
! !

! StringHolder methodsFor: 'locking' !

isLocked
!

isUnlocked
!

lock
!

okToChange
!

unlock
! !

StringHolder subclass: 'TextCollector'
	instanceVariableNames: 'transcriptOpen'
	classVariableNames: ''
	poolDictionary: ''
	category: 'Graphics'
!

! TextCollector methodsFor: 'accessing' !

next: anInteger put: aCharacter
!

nextPut: aCharacter
!

nextPutAll: aCollection
!

show: aString
!

clear
! !

! TextCollector methodsFor: 'Character writing' !

bs
!

cr
!

crtab
!

space
!

tab
! !

! TextCollector methodsFor: 'close' !

okToChange
! !

! TextCollector methodsFor: 'private' !

aTranscriptIsOpen
!

transcriptOpen
! !

! TextCollector class methodsFor: 'system' !

newTranscript: aTextCollector
! !



TextBufferController subclass: 'StringHolderController'
	instanceVariableNames: 'isLockingOn'
	classVariableNames: ''
	poolDictionary: ''
	category: 'Graphics'
!

!StringHolderController methodsFor: 'initialize-release'!
initialize

        super initialize.
        isLockingOn _ true
! !

!StringHolderController methodsFor: 'lock access'!

isLockingOff
        "Answer whether no unsaved modifications have been carried out using
        the receiver."

        ^isLockingOn not
!

isLockingOn
        "Answer whether unsaved modifications have been carried out using the
        receiver."

        ^isLockingOn
!

lockModel
        "If the receiver is lock, do so to the receiver's model."

        isLockingOn ifTrue: [model lock]
!

turnLockingOff
        "Turn off the receiver's indication that it is locked."

        isLockingOn <- false
!

turnLockingOn
        "Turn on the receiver's indication that it is locked."

        isLockingOn <- true
!

unlockModel
        "If the receiver is locked, then the model probably is, but should not b
e,
        so unlock the model."

        isLockingOn ifTrue: [model unlock]
! !

! StringHolderController methodsFor: 'menu messages' !

accept
!

cancel
!

doIt
!

printIt
!

inspectIt
! !

! StringHolderController methodsFor: 'private' !

afterSelectionInsertAndSelect: aString
!

insertAndSelect: aString at: index
! !

StringHolderController subclass: 'TextController'
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphiscs'
!

StringHolderController subclass: 'TextCollectorController'
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphiscs'
!

! TextCollectionController methodsFor: 'entry control' !

appendEntry
!

changeText: aText
! !

TextController subclass: 'CodeController'
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphiscs'
!

View subclass: 'StringHolderView'
	instanceVariableNames: 'displayContents'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics'
!

! StringHolderView methodsFor: 'update' !

promptForCancel
!

update: aSymbol
! !

! StringHolderView methodsFor: 'controller' !

defaultController
! !

! StringHolderView methodsFor: 'displaying' !

display
! !

StringHolderView subclass: 'TextView'
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics'
!

! TextView methodsFor: 'update' !

update: aSymbol
! !

! TextView methodsFor: 'controller' !

defaultController
! !

! TextView methodsFor: 'displaying' !

display
! !

! TextView class methodsFor: 'instance creation' !

open

!

open: aTextBuffer label: aString
! !

TextView subclass: 'CodeView'
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics'
!

! CodeView methodsFor: 'update' !

update: aSymbol
! !

! CodeView methodsFor: 'controller' !

defaultController
! !

! CodeView methodsFor: 'displaying' !

display
! !

! CodeView class methodsFor: 'instance creation' !

open

!

open: aTextBuffer label: aString
! !

StringHolderView subclass: 'TextCollectorView'
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics'
!

! TextCollectorView methodsFor: 'update' !

update: aSymbol
! !

! TextCollectorView methodsFor: 'controller' !

defaultController
! !

! TextCollectorView methodsFor: 'displaying' !

display
! !

! TextCollectorView class methodsFor: 'instance creation' !

open

!

open: aTextCollector label: aString
! !


