Collection subclass: 'Text'
	instanceVariableNames: 'string runs'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections'
!

Text comment: 'I represent strings with formating information'. !

! Text class methodsFor: 'emphasis helper' !

addEmphasis: e1 to: e2
    "merge two emphasis's into one"

    | ne ce1 ce2 | 

    e1 isNil ifTrue: [^ e2].
    e2 isNil ifTrue: [^ e1].
    e1 == e2 ifTrue: [^ e1].

    ce1 <- e1 class.
    ce2 <- e2 class.

    (ce1 == Symbol 
     or: [ce1 == Association]) ifTrue: [
        (ce2 == Symbol 
         or: [ce2 == Association]) ifTrue: [
            ^ Array with: e1 with: e2
        ].
        (e2 includes: e1) ifTrue: [^ e2].
        ^ e2 copyWith: e1
    ].
    (ce2 == Symbol 
     or: [ce2 == Association]) ifTrue: [
        (e1 includes: e2) ifTrue: [^ e1].
        ^ e1 copyWith: e2
    ].

    ne <- e1.
    e2 do: [ :e |
        (ne includes: e) ifFalse: [
           ne <- ne copyWith: e
        ]
    ].
    ^ ne.

    "
     Text addEmphasis: #bold to: #bold           
     Text addEmphasis: #bold to: #italic         
     Text addEmphasis: #bold to: #(italic strikeout)   
     Text addEmphasis: #italic to: #(italic strikeout) 
     Text addEmphasis: #(italic strikeout) to: #bold  
     Text addEmphasis: #(italic strikeout) to: #italic 
     Text addEmphasis: #(italic strikeout) to: #(bold underline) 
    "
!

emphasis: e1 includes: e2
    "return true, if e1 includes e2.
     e2 should be a single emphasis."
    | ce1 ce2 |

    e1 isNil ifTrue: [^ false].
    e2 isNil ifTrue: [^ false].
    e1 == e2 ifTrue: [^ true].

    ce1 <- e1 class.
    ce2 <- e2 class.
    (ce1 == Symbol 
     or: [ce1 == Association]) ifTrue: [
        ^ false
    ].
    (ce2 == Symbol 
     or: [ce2 == Association]) ifTrue: [
        ^ (e1 includes: e2)
    ].
    ^ false

    "
     Text emphasis: #bold includes: #bold           
     Text emphasis: #bold includes: #ialic         
     Text emphasis: #(italic strikeout) includes: #bold  
     Text emphasis: #(italic strikeout) includes: #italic 
    "
!

extractEmphasis: key from: e
    "if key is included in the emphasis, e then return the key.
     Otherwise, if a n association with that key is included, return the value.
     Otherwise, return nil."

    e isNil ifTrue: [^ nil].
    key == e ifTrue: [^ e].

    e class == Association ifTrue: [
        e key == key ifTrue: [^ e value].
        ^ nil
    ].
    (e includes: key) ifTrue: [^ key].
    e do: [ :entry | 
        entry class == Association ifTrue: [
            entry key == key ifTrue: [
                ^ entry value
            ]
        ]
    ].
    ^ nil

    "
     Text extractEmphasis: #bold  from: #bold           
     Text extractEmphasis: #bold  from: #italic           
     Text extractEmphasis: #bold  from: #(italic strikeout)           
     Text extractEmphasis: #bold  from: #(italic bold)           
    "
!

removeEmphasis: e1 from: e2
    "remove an emphasis; if it was not in e1, do nothing"

    |ne ce1 ce2|

    e1 isNil ifTrue: [^ nil].
    e2 isNil ifTrue: [^ e1].
    e1 == e2 ifTrue: [^ nil].

    ce1 <- e1 class.
    ce2 <- e2 class.

    (ce2 == Symbol 
     or: [ce2 == Association]) ifTrue: [
        (e1 includes: e2) ifTrue: [^ nil].
        ^ e2
    ].
    (ce1 == Symbol 
     or: [ce1 == Association]) ifTrue: [
        (e2 includes: e1) ifTrue: [
            ne <- e2 copyWithout: e1.
            ne size == 1 ifTrue: [^ ne at: 1].
            ne size == 0 ifTrue: [^ nil].
            ^ ne
        ].
        ^ e2
    ].

    ne <- e2.
    e1 do: [ :e |
        (ne includes: e) ifTrue: [
           ne <- ne copyWithout: e
        ]
    ].
    ne size == 1 ifTrue: [^ ne at: 1].
    ne size == 0 ifTrue: [^ nil].
    ^ ne.

    "
     Text removeEmphasis: #bold from: #bold           
     Text removeEmphasis: #bold from: #italic         
     Text removeEmphasis: #bold from: #(italic strikeout)   
     Text removeEmphasis: #italic from: #(italic strikeout) 
     Text removeEmphasis: #(italic strikeout) from: #bold  
     Text removeEmphasis: #(italic strikeout) from: #italic  
     Text removeEmphasis: #(italic strikeout) from: #(bold underline) 
     Text removeEmphasis: #(italic strikeout bold) from: #(bold underline) 
     Text removeEmphasis: #(italic strikeout bold underline) from: #(bold underline) 
    "
! !

! Text methodsFor: 'comparing' !

= aStringOrText
    "compare the receiver and the argument, ignoring emphasis"

    aStringOrText isString ifFalse: [^ false].
    ^ string = aStringOrText string


    "
     'hello' asText = 'hello'        
     'hello' asText = 'hello' asText 
     'hello' asText allBold = 'hello' 
    "
! !

! Text methodsFor: 'converting' !

asText
    "return the receiver itself - it is already a text object"

    ^ self
! !

! Text methodsFor: 'copying' !

, aStringOrText
    "concatenate the receivers characters with the arguments characters, 
     and return string or text object containing those characters.
     If either the receiver or the argument contains emphasis information,
     a text object will be returned. Otherwise, a string (i.e. without emphasis)
     is returned."

    |newRuns|

    aStringOrText hasChangeOfEmphasis ifTrue: [    
        ^ self species new
            string: (string , aStringOrText)
            emphasisCollection: (runs , aStringOrText emphasisCollection)
    ].
    runs notNil "self hasChangeOfEmphasis" ifTrue: [ 
        newRuns <- runs copyFrom: 1 to: (runs size).
	newRuns add: (TextStyle new) withOccurrences: (aStringOrText size).
        
        ^ self species new
            string: (string , aStringOrText)
            emphasisCollection: newRuns
    ].
    ^ string , aStringOrText string

    "
     ('hello' asText allBold) , ' world'    
     'hello' , (' world' asText allBold)
     'hello' , ' world'
     ('hello' asText allBold) , (' world' asText allBold)
    "
!

concatenateFromString: aString
    "return the concatenation of aString and myself.
     This may be a Text (if I have emphasis) or a string (if not)."
    | newRuns |

    self hasChangeOfEmphasis ifTrue: [
	newRuns <- RunArray new.
	newRuns add: (TextStyle new) withOccurrences: (aString size).

        ^ self species new
                string: (aString , string)
                emphasisCollection: ((newRuns , runs).
    ].
    ^ aString , string
!

copyFrom: start to: stop
    "return the subcollection starting at index start, anInteger and ending
     at stop, anInteger."

    self hasChangeOfEmphasis ifTrue: [
        ^ self species new
                string: (string copyFrom: start to: stop)
                emphasisCollection: (runs copyFrom: start to: stop).
    ].
    ^ string copyFrom: start to: stop
!

postCopy
    string <- string copy.
    runs <- runs copy
! !

! Text methodsFor: 'displaying' !

display
    ^self displayOn: Display at: 0@0
                 clippingBox: Display boundingBox
		 rule: Form over
		 mask: Form black
!

displayAt: aPoint
    ^self displayOn: Display at: aPoint
                 clippingBox: Display boundingBox
		 rule: Form over
		 mask: Form black
!

displayOn: aForm
    ^self displayOn: aForm at: 0@0
                 clippingBox: aForm boundingBox
		 rule: Form over
		 mask: Form black
!

displayOn: aForm at: aPoint
    ^self displayOn: aForm at: aPoint
                 clippingBox: aForm boundingBox
		 rule: Form over
		 mask: Form black
!

displayOn: aForm at: aPoint
                 clippingBox: clipRectangle
    ^self displayOn: aForm at: aPoint
                 clippingBox: clipRectangle
		 rule: Form over
		 mask: Form black
!

displayOn: aForm at: aPoint
                 clippingBox: clipRectangle
		 rule: rule
    ^self displayOn: aForm at: aPoint
                 clippingBox: clipRectangle
		 rule: rule
		 mask: Form black
!

displayOn: aForm at: aPoint
                 clippingBox: clipRectangle
		 rule: rule
		 mask: aMask
   | dt |
   dt <- DisplayText new.
   dt text: self.
   ^ dt displayOn: aForm at: aPoint
                 clippingBox: clipRectangle
		 rule: rule
		 mask: aMask
! !

! Text methodsFor: 'emphasis' !

allBold
    "make all characters bold"

    self emphasizeAllWith: #Bold

    "
     (Text string: 'hello') allBold
    "
!

emphasis
    "return the emphasis"

    ^ runs

    "
     (Text string: 'hello') allBold emphasis 
     'hello' emphasis   
    "
!

emphasisAt: characterIndex
    "return the emphasis at some index"

    ^ runs at: characterIndex

    "
     (Text string: 'hello') allBold emphasisAt: 2 
    "
!

emphasisAt: characterIndex add: newEmphasis
    "add to the emphasis at some index. return the receiver"

    |e prevE|

    e <- runs at: characterIndex.
    e <- e copy addEmphasis: newEmphasis.

    "if its equal to the previous emphasis, make it identical."

    characterIndex > 1 ifTrue: [
        prevE <- runs at: characterIndex-1.
        e = prevE ifTrue: [
            e <- prevE
        ]
    ].
    runs at: characterIndex put: e

    "
     (Text string: 'hello') allBold emphasisAt: 2 add: #italic
    "
!

emphasisAt: characterIndex put: emphasis
    "change the emphasis at some index. return the receiver"

    |e prevE|

    e <- TextStyle new addEmphasis: emphasis.

    "if its equal to the previous emphasis, make it identical."

    characterIndex > 1 ifTrue: [
        prevE <- runs at: characterIndex-1.
        emphasis = prevE ifTrue: [
            e <- prevE
        ]
    ].
    runs at: characterIndex put: e

    "
     (Text string: 'hello') allBold emphasisAt: 2 put: #italic
    "
!

emphasisAt: characterIndex remove: emphasisToRemove
    "remove from the emphasis at some index. return the receiver"

    |e prevE|

    e <- runs at: characterIndex.
    e <- e copy removeEmphasis: emphasisToRemove.
    "if its equal to the previous emphasis, make it identical."

    characterIndex > 1 ifTrue: [
        prevE <- runs at: characterIndex-1.
        e = prevE ifTrue: [
            e <- prevE
        ]
    ].

    runs at: characterIndex put: e

    "
     (Text string: 'hello') 
        allBold emphasisAt: 2 remove: #bold

     (Text string: 'hello' emphasis: #(bold italic)) 
        emphasisAt: 2 remove: #bold
    "
!

emphasisCollection
    "return the emphasis"

    ^ runs

    "
     (Text string: 'hello') allBold emphasis 
     'hello' emphasis   
    "
!

emphasizeAllWith: emphasis
    "change the emphasis of all characters"
    | e |
    
    e <- TextStyle new addEmphasis: emphasis.
    runs <- (RunArray new: (string size)) atAllPut: e

    "
     (Text string: 'hello') allBold emphasizeAllWith: #italic 
    "
!

emphasizeFrom: start count: count with: emphasis
    "change the emphasis of a range of characters, given startIndex and count."

    self emphasizeFrom: start to: (start + count - 1) with: emphasis

    "
     (Text string: 'hello world') 
        emphasizeFrom: 1 count: 5 with: #bold;
        emphasizeFrom: 7 count: 5 with: #italic
    "
!

emphasizeFrom: start to: stop with: emphasis
    "change the emphasis of a range of characters"

    | e |
    e <- TextStyle new addEmphasis: emphasis.
    runs from: start to: stop put: e.
!

emphasizeFrom: start with: emphasis
    "change the emphasis of some characters upTo the end"

    self emphasizeFrom: start to: (self size) with: emphasis

    "
     (Text string: 'hello world') 
        emphasizeFrom: 1 count: 5 with: #bold;
        emphasizeFrom: 7 with: #italic
    "
! !

! Text methodsFor: 'printing' !

printOn: aStream
    "print the receivers characters (including emphasis) on
     aStream. 
     Notice, that some streams simply ignore the emphasis 
     (Transcript currently does)."

    |pos nextPos|

    pos <- 1.

    runs runsDo: [ :len :emphasis |
        nextPos <- pos + len.

        aStream emphasis: emphasis.
        aStream nextPutAll: string startingAt: pos to: nextPos - 1.
        pos <- nextPos
    ].

    "
     Transcript showCR: 'hello world'.
     Transcript showCR: 'hello world' asText allBold.
     Transcript showCR: ('hello world' asText emphasizeAllWith: #italic).
    "
!

storeOn: aStream
    "append a printed representation from which the receiver can be reconstructed
     to aStream."

    aStream nextPutAll: '(Text string: '.
    string storeOn: aStream.
    aStream nextPutAll: ' runs: '.
    runs storeOn: aStream.
    aStream nextPutAll: ')'.
! !

! Text methodsFor: 'private accessing' !

emphasisCollection: emphasisCollection
    "set the string and emphasis collection.
     The emphasis collection contains per-character information."

    runs <- emphasisCollection
!

string: aString emphasis: emphasis
    "set the string and emphasis. The emphasis is applied to all characters."

    | e |

    e <- TextStyle new addEmphasis: emphasis.
    string <- aString string.
    runs   <- (RunArray new: string size) atAllPut: e

    "
     |t|

     t <- Text new string: 'hello' emphasis: #bold.
     t emphasisAt: 2.
    "
!

string: aString emphasisCollection: emphasisCollection
    "set the string and emphasis collection.
     The emphasis collection contains per-character information."

    string <- aString string.
    runs <- emphasisCollection asRunArray

    "
     |t|

     t <- Text new string: 'hello' emphasisCollection: (#bold #bold #bold #italic #italic).
     t emphasisAt: 2.
    "
! !

! Text methodsFor: 'queries' !

hasChangeOfEmphasis
    "return true, if the receiver contains non-empty emphasis information"

    ^ (runs notNil
       and: [(runs findFirst: [ :e | e notNil]) ~~ 0])
!

indexOf: aCharacter startingAt: index
    "search aCharacters index in the underlying string"

    ^ string indexOf: aCharacter startingAt: index
!

isText
    "return true if this is a Text object - always true here"

    ^ true
!

occurrencesOf: aCharacter
    "count & return the number of occurrences of aCharacter in the 
     underlying string"

    ^ string occurrencesOf: aCharacter
!

size
    "return the number of characters in the underlying string"

    ^ string size
!

string
    "return the receiver without any emphasis information
     i.e. the underlying string."

    ^ string
!

width
    "return the number of device units, required on aGC's device"

    |savedFont boldFont italicFont bold italic pos f l device|

! !

! Text methodsFor: 'replacing' !

replaceFrom: start to: stop with: aCollection startingAt: startIndex
    "replace a range of characters, from another string or text object.
     The corresponding characters' emphasis information is also copied.
     Return the receiver."

    |idx|

    aCollection isText ifTrue: [
        aCollection hasChangeOfEmphasis ifTrue: [
            string replaceFrom: start to: stop with: aCollection startingAt: startIndex.
            idx <- startIndex.
            start to: stop do: [ :col |
                self emphasisAt: col put: (aCollection emphasisAt: idx).
                idx <- idx + 1.
            ].
            ^ self.
        ]
    ].

    string replaceFrom: start to: stop with: aCollection startingAt: startIndex.
    runs from: start to: stop put: nil.

    "
     ((Text string: 'hello') allBold emphasisAt: 2 put: #italic)
        copyFrom: 1 to: 3
    "
! !

! String methodsFor: 'testing' !

isString
	^ true
!

isText
	^ false
!

hasChangeOfEmphasis
	^ false
! !

! Text methodsFor: 'display sizing' !

displayExtent
    | scanner code width |
    width <- 0.
    scanner <- CharacterScanner text: self 
	destForm: Display font: Font systemFont.
    scanner printing: false.
    scanner stopcode: (Character backspace asciiValue + 1) put: #bs.
    scanner stopcode: (Character tab asciiValue + 1) put: #tab.
    scanner stopcode: (Character cr asciiValue + 1) put: #nl.
    scanner stopcode: (Character nl asciiValue + 1) put: #nl.
    [ code <- scanner scanword: self size.
      code == #endRun ] whileFalse: [
	width <- width max: scanner destX.
	(code == #stopX or: [ code == #nl ]) ifTrue: [ scanner nextline ].
	code == #bs ifTrue: [ scanner backspace ].
	code == #tab ifTrue: [ scanner tab ].
    ].
    width <- width max: scanner destX.
    scanner nextline.
    ^ width @ scanner destY
! !

! Font class methodsFor: 'creating' !

getStyle: emphasis
	| font c key |
	font <- self new systemFont.
	" If no emphasis, just return system font. "
	emphasis isNil ifTrue: [ ^ font ].
        c <- emphasis class.
	c == Symbol ifTrue: [ ^ font style: emphasis ].
	c == Association ifTrue: [
	    key <- emphasis key.
	    key == #Name ifTrue: [ ^ font family: emphasis value ].
	    key == #Size ifTrue: [ ^ font size: emphasis value ]
	].
        emphasis do: [ :e | 
            c <- e class.
	    c == Symbol ifTrue: [ font style: e ].
	    c == Association ifTrue: [
		key <- e key.
		key == #Name ifTrue: [ font family: e value ].
		key == #Size ifTrue: [ font size: e value ]
	].
	^ font
! !

! Text class methodsFor: 'instance creation' !

new
    ^ super new string: (String new) emphasis: nil
! !

! Text class methodsFor: 'instance creation' !

new: size
    ^ super new string: (String new: size) emphasis: nil
! !

! Text class methodsFor: 'instance creation' !

string: aString 
    ^ super new string: aString emphasis: nil
! !

! Text class methodsFor: 'instance creation' !

string: aString emphasis: attribute
    ^ super new string: aString emphasis: attribute
! !

! Text class methodsFor: 'instance creation' !

string: aString emphasisCollection: attributeCollection
    "create a Text instance, for the characters in aString,
     which are individually emphasized as described by attributeCollection."

    ^ super new string: aString emphasisCollection: attributeCollection

    "
     Text 
        string: 'hello' 
        emphasisCollection: #(#bold #bold #italic #italic #italic)"
! !

! Text class methodsFor: 'instance creation' !

string: aString runs: aRun
    "create a Text instance, for the characters in aString,
     which are individually emphasized as described by attributeCollection."

    ^ super new string: aString emphasisCollection: aRun.
! !

! Text class methodsFor: 'instance creation' !

fromString: aString 
    "create a Text instance, for the characters in aString,
     without emphasis."
    ^ super new string: aString emphasis: nil

    " Text fromString: 'hello'
    "
! !

