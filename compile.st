" Methods for Class stream and all it's subclasses"

" $Id: compile.st,v 1.3 2000/08/29 01:06:52 rich Exp rich $ "

"
 $Log: compile.st,v $
 Revision 1.3  2000/08/29 01:06:52  rich
 Converted tokens to symbols.
 Made method to preform actions for tokens.
 Method to print out tokens.
 Cleaned up printing on symbols and code nodes.
 Fixed bug in removeNode.
 Converted optimizer from do: to loops.
 Fixed bug in relabel.
 Moved return self to compiler methods.
 When compiling for execution return tos not self.
 Code cleanup.
 Added code to print out a compiled method.

 Revision 1.2  2000/03/08 04:13:19  rich
 Major bug fixes.

 Revision 1.1  2000/02/01 18:12:03  rich
 Initial revision


"

Object subclass: 'SmallTalkToken'
       instanceVariableNames: 'token stream value curchar pushback'
       classVariableNames: 'chartable actiontable arraytable tokentable'
       poolDictionaries: '' category: nil !

!SmallTalkToken class methodsFor: 'creation' !

on: aStream
	^ super new initOn: aStream.
! !

!SmallTalkToken methodsFor: 'testing' !

isKeyString
	^ #KeyString = token
!

isKeyDollar
	^ #KeyDollar = token
!

isKeyDigit
	^ #KeyDigit = token
!

isKeySpace
	^ #KeySpace = token
!

isKeyComment
	^ #KeyComment = token
!

isKeyEOS
	^ #KeyEOS = token
!

isKeyLiteral
	^ #KeyLiteral = token
!

isKeyName
	^ #KeyName = token
!

isKeyKeyword
	^ #KeyKeyword = token
!

isKeyAssign
	^ #KeyAssign = token
!

isKeyRParen
	^ #KeyRParen = token
!

isKeyLParen
	^ #KeyLParen = token
!

isKeyReturn
	^ #KeyReturn = token
!

isKeyCascade
	^ #KeyCascade = token
!

isKeyPeriod
	^ #KeyPeriod = token
!

isKeySpecial
	^ #KeySpecial = token
!

isKeyRBrack
	^ #KeyRBrack = token
!

isKeyLBrack
	^ #KeyLBrack = token
!

isKeyVariable
	^ #KeyVariable = token
!

isKeyUnknown
	^ #KeyUnknown = token
!

" Determine if next token is a variable seperator. "
isVarSep
    ^ #KeySpecial = token and: [ value = '|' ].
! !

! SmallTalkToken methodsFor: 'Initialize' !

" Set up array of characters to speed up parsing "
initOn: aString
	stream <- ReadStream on: aString.
	token <- #KeyUnknown.
	pushback <- nil.
! !

! SmallTalkToken class methodsFor: 'Initialize' !

initialize
	| tok table |
 	table <- IdentityDictionary new: 21.
	table at: #KeyEOS put: 1.
	table at: #KeyLiteral put: 2.
	table at: #KeyName put: 3.
	table at: #KeyKeyword put: 4.
	table at: #KeyAssign put: 5.
	table at: #KeyRParen put: 6.
	table at: #KeyLParen put: 7.
	table at: #KeyReturn put: 8.
	table at: #KeyCascade put: 9.
	table at: #KeyPeriod put: 10.
	table at: #KeySpecial put: 11.
	table at: #KeyRBrack put: 12.
	table at: #KeyLBrack put: 13.
	table at: #KeyVariable put: 14.
	table at: #KeyUnknown put: 15.
	table at: #KeyString put: 16.
	table at: #KeyDollar put: 17.
	table at: #KeyDigit put: 18.
	table at: #KeySpace put: 19.
	table at: #KeyComment put: 20.
	tokentable <- table.
	table <- Array new: 128.
        table at: (Character space asciiValue) put: (#KeySpace).
        table at: (Character tab asciiValue) put: (#KeySpace).
        table at: (Character cr asciiValue) put: (#KeySpace).
        table at: (Character nl asciiValue) put: (#KeySpace).
        table at: ($( asciiValue) put: (#KeyRParen).
        table at: ($) asciiValue) put: (#KeyLParen).
        table at: ($; asciiValue) put: (#KeyCascade).
        table at: ($. asciiValue) put: (#KeyPeriod).
        table at: ($^ asciiValue) put: (#KeyReturn).
        table at: ($[ asciiValue) put: (#KeyLBrack).
        table at: ($] asciiValue) put: (#KeyRBrack).
        table at: ($^ asciiValue) put: (#KeyReturn).
	table at: ($< asciiValue) put: (#KeySpecial).
	table at: ($- asciiValue) put: (#KeyDigit).
	table at: ($+ asciiValue) put: (#KeySpecial).
	table at: ($/ asciiValue) put: (#KeySpecial).
	table at: ($\ asciiValue) put: (#KeySpecial).
	table at: ($* asciiValue) put: (#KeySpecial).
	table at: ($~ asciiValue) put: (#KeySpecial).
	table at: ($> asciiValue) put: (#KeySpecial).
	table at: ($= asciiValue) put: (#KeySpecial).
	table at: ($@ asciiValue) put: (#KeySpecial).
	table at: ($% asciiValue) put: (#KeySpecial).
	table at: ($? asciiValue) put: (#KeySpecial).
	table at: ($!! asciiValue) put: (#KeySpecial).
	table at: ($& asciiValue) put: (#KeySpecial).
	table at: ($| asciiValue) put: (#KeySpecial).
        table at: ($, asciiValue) put: (#KeySpecial).
	table at: ($# asciiValue) put: (#KeyLiteral).
	table at: ($$ asciiValue) put: (#KeyDollar).
	table at: ($: asciiValue) put: (#KeyName).
	table at: ($' asciiValue) put: (#KeyString).
	$0 asciiValue to: ($9 asciiValue) do: 
		[ :i | table at: i put:  (#KeyDigit) ].
	tok <- #KeyName.
	$a asciiValue to: ($z asciiValue) do: 
		[ :i | table at: i put:  tok].
	$A asciiValue to: ($Z asciiValue) do: 
		[ :i | table at: i put:  tok].
	table at: ($"  asciiValue) put: (#KeyComment).
	chartable <- table.
	actiontable <- #(
	scantoken	"KeyEOS"
	scanliteral	"KeyLiteral"
	scanname	"KeyName"
	scantoken	"KeyKeyword"
	scantoken	"KeyAssign"
	scantoken	"KeyRParen"
	scantoken	"KeyLParen"
	scantoken	"KeyReturn"
	scantoken	"KeyCascade"
	scantoken	"KeyPeriod"
	scanspecial	"KeySpecial"
	scantoken	"KeyRBrack"
	scantoken	"KeyLBrack"
	scantoken	"KeyVariable"
	scantoken	"KeyUnknown"
	scanstring	"KeyString"
	scanchar	"KeyDollar"
	scannumber	"KeyDigit"
	scanspace	"KeySpace"
	scancomment	"KeyComment"
        ).
	arraytable <- #(
	scantoken	"KeyEOS"
	scanliteral	"KeyLiteral"
	scanname	"KeyName"
	scantoken	"KeyKeyword"
	scantoken	"KeyAssign"
	scanarray	"KeyRParen"
	scantoken	"KeyLParen"
	scantoken	"KeyReturn"
	scantoken	"KeyCascade"
	scantoken	"KeyPeriod"
	scanspecial	"KeySpecial"
	scantoken	"KeyRBrack"
	scantoken	"KeyLBrack"
	scantoken	"KeyVariable"
	scantoken	"KeyUnknown"
	scanstring	"KeyString"
	scanchar	"KeyDollar"
	scannumber	"KeyDigit"
	scanspace	"KeySpace"
	scancomment	"KeyComment"
        ).
! !


! SmallTalkToken methodsFor: 'private' !

" Preform the action given by the table "
action: aTable with: char
	| index action |
	" Pick up next character and convert to symbol. "
	token <- chartable at: (char asciiValue).
	token isNil ifTrue: [ token <- #KeyUnknown. ].
	" Look up symbol to get index "
	index <- tokentable at: token.
	index isNil ifTrue: [ ^ true ].
	" Do action at given table "
	action <- aTable at: index.
	action notNil ifTrue: [ self preform: action ].
	^ true
!

" Read next char off stream. "
nextchar
	pushback isNil ifFalse: [
	    curchar <- pushback.
	    pushback <- nil.
	] ifTrue: [
	    stream atEnd ifTrue: [ curchar <- 0 asCharacter ]
	    		 ifFalse: [ curchar <- stream next].
	].
	^ curchar
!

" Put character away to read again. "
pushback
	pushback <- curchar.
!

" Peek at the next character without actualy reading it. "
peeknext
	pushback isNil ifFalse: [ ^ pushback ].
	stream atEnd ifTrue: [ ^ 0 asCharacter ].
	^ stream peek
!

isSpecial: aChar
	#( $+ $/ $\ $* $~ $< $> $= $@ $% $& $? $!! ) do:
		[ :i | (aChar = i) ifTrue: [^ true ]].
	^ false
!

scancomment
	| char |
	token <- #KeyEOS.
	[ (char <- self nextchar) isNil ] whileFalse: [ 
		char = $" ifTrue: [
			self peeknext = $" ifFalse: [ ^self].
			self nextchar.
	        ].
	]
!

scanspace
	token <- #KeyEOS.
!

scantoken
	^ self
!

scannumber
   | base integer fraction sign exp char multi eseen fseen dig done|
   token <- #KeyLiteral.
   char <- curchar.
   sign <- false.
   integer <- 0.
   fraction <- 0.0.
   base <- 10.
   exp <- 0.
   eseen <- false.
   fseen <- false.
   " If first char is minus check if number following "
   char = $- ifTrue: [
	self peeknext isDigit ifFalse: [
	" Nope, make it a special token "
		^ self scanspecial
	] ifTrue: [
		sign <- true.
	 	char <- self nextchar.
	]
   ].

   " Scan first part of number. "
   done <- true.
   [ done and: [char isDigit or: [ char isUppercase ]]] whileTrue: [
        dig <- char digitValue.
        dig > base
           ifTrue: [ done <- false. ]
           ifFalse: [
     		integer <- (integer * 10) + dig.  char <- self nextchar.  ]
   ].

   " Check if radix value "
    char = $r ifTrue: [
	base <- integer.
	integer <- 0.
	done <- true.
	char <- self nextchar.
        " Scan integer part of number. "
        [ done and: [char isDigit or: [ char isUppercase ]]] whileTrue: [
	     dig <- char digitValue.
	     dig > base ifTrue: [ done <- false. ]
	           ifFalse: [
	     		integer <- (integer * base) + dig.
	     		char <- self nextchar.
		   ]
        ]
    ].

   " Check if fractional value "
    char = $. ifTrue: [
	char <- self peeknext.
	" Check if period at end of line "
	char isDigit or: [ char isUppercase ] ifTrue: [
		char <- self nextchar.
	        multi <- 1.0 / (base asFloat).
		done <- true.
		fseen <- true.
              " Scan fraction part of number. "
              [ done and: [ char isDigit or: [ char isUppercase ]]] whileTrue: [
		     dig <- char digitValue.
		     dig > base ifTrue: [ done <- false. ]
		           ifFalse: [
       	           		fraction <- fraction + (multi * (dig asFloat)).
		   		multi <- multi / (base asFloat).
			   ].
		     char <- self nextchar.
              ]
	 ] ifFalse: [ char <- $. ].
    ].

   " Check if exponent "
    char = $e ifTrue: [
	char <- self nextchar.
	eseen <- false.		" Grab variable for sec "
	char = $- ifTrue: [ eseen <- true. char <- self nextchar ].
        " Scan exponent. "
        [ char isDigit ] whileTrue: [
	     exp <- (exp * 10) + (char digitValue).
	     char <- self nextchar.
        ].
	eseen ifTrue: [ exp <- exp negated ].
	eseen <- true.
    ].
	
   " We read one char to many, put it back "
    self pushback.

   " Got a number now convert it to a object "
    fseen or: [eseen] ifTrue: [
	 value <- integer asFloat + fraction.
	 eseen ifTrue: [ value <- value raisedToInteger: exp ].
    ] ifFalse: [ value <- integer ].
    sign ifTrue: [ value <- value negated ].
!

" Scan a name and return it in string. "
scanname
    | char |

    " Check if it is a variable name "
    value <- WriteStream on: (String new: 0).
    curchar = $: ifTrue: [
	  token <- #KeyVariable.
          self peeknext isLetter ifFalse: [
	       token <- #KeyUnknown. 
	       value nextPut: $:.
	      ^ self
	  ] ifTrue: [ 
		self nextchar.
	  ].
    ] ifFalse: [    
          token <- #KeyName.
    ].

    [ curchar isAlphaNumeric ] whileTrue: [ 
	value nextPut: curchar.
	curchar <- self nextchar ].

   " Convert it to a keyword if a : follows it and it is not a variable "
    curchar = $: and: [ #KeyName = token ] ifTrue: [
	value nextPut: curchar.
	token <- #KeyKeyword
    ] ifFalse: [
	self pushback
    ].
    value <- value contents.
!

" Scan a string and return a string object. "
scanstring
    | char done |
    done <- true.
    token <- #KeyLiteral.
    value <- WriteStream on: (String new: 0).
    [ done ] whileTrue: [
	char <- self nextchar.
	char = $'
	   ifTrue: [
		self peeknext = $' ifTrue: [ value nextPut: (self nextchar).  ]
				   ifFalse: [ done <- false ]
	        ]
	   ifFalse: [ value nextPut: char ]
    ].
    value <- value contents.
!

" Scan a literal, either a array or a symbol. "
scanliteral
     | char done |
     token <- #KeyLiteral.
     char <- self nextchar.
     " Check if array "
     char = $( ifTrue: [ ^ self scanarray ].
     char isLetter ifTrue: [
		value <- WriteStream on: (String new: 0).
    		[ char isAlphaNumeric or: [ char = $: ]]
			whileTrue: [
				 value nextPut: char.
				 char <- self nextchar ].
		self pushback.
		value <- value contents asSymbol.
		^ self ].
     (self isSpecial: char) ifTrue: [
		self scanspecial.
		value <- value asSymbol.
     		token <- #KeyLiteral.
     ] ifFalse: [
                 token <- #KeyUnknown.
     ].
!

" Scan a char constant "
scanchar
    value <- self nextchar.
    token <- #KeyLiteral.
!

" Scan a special, check if it is a <- and convert over to a assignment "
scanspecial
    curchar = $< and: [self peeknext = $- ] ifTrue: [
	self nextchar.
	token <- #KeyAssign.
    ] ifFalse: [
	(self isSpecial: self peeknext)
	   ifTrue: [
		value <- String new: 2.
		value at: 1 put: curchar.
	   	value at: 2 put: (self nextchar).
	    ]
	   ifFalse: [
		value <- curchar asString.
	  ].
          token <- #KeySpecial.
    ]
!


" Scan an array and return a literal token "
scanarray
     | char array |
     token <- #KeyLiteral.
     array <- OrderedCollection new.
     [ char <- self nextchar. 0 asCharacter ~= char ] whileTrue: [
	" Do this first since rest will set themself to literal "
	self action: arraytable with: char.

        " Clean up names and keywords. "
	self isKeyName or: [ self isKeyKeyword ]
	    ifTrue: [ array add: (value asSymbol) ]
	    ifFalse: [

	" All done scanning, see if we should add it "
	    self isKeyLiteral
	        ifTrue: [ array add: value ]
	        ifFalse: [
        	     self isKeyLParen ifTrue: [
			    value <- WriteStream on: (Array new: (array size)).
			    array do: [ :v | value nextPut: v ].
			    value <- value contents.
			    token <- #KeyLiteral.
		     ].
		     self isKeyEOS ifFalse: [ ^ self ]
	       ]
	 ].
     ].
! !

! SmallTalkToken methodsFor: 'accessing' !

" Return the value of the token. "
value
    ^ value
!

" Print out a token "
print
	| str |
	str <- 'Token: ' , (token asString).
	self isKeyLiteral or: [ self isKeyName or: 
		[ self isKeyKeyword or: [ self isKeySpecial or:
			[self isKeyVariable ]]]] ifTrue:
		[ str <- str , ' '. str <- str , (value printString)].
	str print.
!

nextchunk
	| str pos cnt |
	str <- WriteStream on: (String new: 0).
	pos <- stream position.	 " Save the position. "
	cnt <- 0.
	[ cnt < 20 and: [ stream atEnd not]] whileTrue: [
		str nextPut: stream next ].
	stream position: pos.	" Back up. "
	^ str contents
!

" Return the next token from input stream. "
next
    | char action |

    [ char <- self nextchar. 0 asCharacter ~= char ] whileTrue: [
	self action: actiontable with: char.
	self isKeyEOS ifFalse: [ ^self ]
    ].
    token <- #KeyEOS.
    ^ self
! !

Object subclass: 'SmallTalkSymbol'
       instanceVariableNames: ''
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkSymbol methodsFor: 'testing'!

isSymbolSelf
	^ false
!

isSymbolSuper
	^ false
!

isSymbolTrue
	^ false
!

isSymbolFalse
	^ false
!

isSymbolNil
	^ false
!

isSymbolArg
	^ false
!

isSymbolTemp
	^ false
!

isSymbolInst
	^ false
!

isSymbolVar
	^  false
!

isSymbolLiteral
	^ false
!

isSymbolStack
	^ false
!

isSymbolLabel
	^ false
!

isSymbolSpecail
	^ false
!

" Override this in the class if we can assign to it "
canAssign
	^ false
!

" Override this in the class if we can directly return this type"
canReturn
	^ false
! !

! SmallTalkSymbol methodsFor: 'accessing' !

offset
	^ 0
!

= aSymbol
	^ aSymbol class == (self class) 
!

printOn: aStream
	aStream nextPutAll: (self name) 
!

" Do nothing, so Literal and symbols work same"
release
	^ nil

! !

! SmallTalkSymbol methodsFor: 'modifing' !

offset: aOffset
    self parseError: ('Internal error can''t set offset on ', (self name)).
! !

! SmallTalkSymbol methodsFor: 'compiling' !

genByte: aByte
   | array |
   array <- ByteArray new: 1.
   array at: 1 put: aByte.
   ^ array
!

genTwo: byteOne and: byteTwo
   | array |
   array <- ByteArray new: 2.
   array at: 1 put: byteOne.
   array at: 2 put: byteTwo.
   ^ array
!


genPush
   self parseError: ('can''t push ', (self name)).
!

genReturn
    self parseError: ('Internal error can''t return ', (self name)).
!

genStore
    self parseError: ('Can''t modify ', (self name)).
!

genSend: superFlag argcount: count
    self parseError: ('Can''t send to ', (self name)).
!

" Return number of bytes to compile operation on object "
genSize
    ^ 1
! !

SmallTalkSymbol subclass: 'SmallTalkSymbolSuper'
       instanceVariableNames: ''
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkSymbolSuper methodsFor: 'testing'!

isSymbolSuper
	^ true
! !

! SmallTalkSymbolSuper methodsFor: 'accessing' !

name
	^ 'super'
! !

! SmallTalkSymbolSuper methodsFor: 'compiling' !

" Same as push self "
genPush
    ^ self genByte: 16rFA.
! !


SmallTalkSymbol subclass: 'SmallTalkSymbolSelf'
       instanceVariableNames: ''
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkSymbolSelf methodsFor: 'testing'!

isSymbolSelf
	^ true
!

canReturn
	^true
! !

! SmallTalkSymbolSelf methodsFor: 'accessing' !

name
	^ 'self'
! !

! SmallTalkSymbolSelf methodsFor: 'compiling' !

genPush
    ^ self genByte: 16rFA.
!

genReturn
    ^ self genByte: 16rF0.
! !

SmallTalkSymbol subclass: 'SmallTalkSymbolNil'
       instanceVariableNames: ''
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkSymbolNil methodsFor: 'testing'!

isSymbolNil
	^ true
!

canReturn
	^true
! !

! SmallTalkSymbolNil methodsFor: 'accessing' !

name
	^ 'nil'
! !

! SmallTalkSymbolNil methodsFor: 'compiling' !

genPush
    ^ self genByte: 16rFB.
!

genReturn
    ^self genByte: 16rF4.
! !

SmallTalkSymbol subclass: 'SmallTalkSymbolTrue'
       instanceVariableNames: ''
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkSymbolTrue methodsFor: 'testing'!

isSymbolTrue
	^ true
!

canReturn
	^true
! !

! SmallTalkSymbolTrue methodsFor: 'accessing' !

name
	^ 'true'
! !

! SmallTalkSymbolTrue methodsFor: 'compiling' !

genPush
    ^ self genByte: 16rFC.
!

genReturn
    ^ self genByte: 16rF2.
! !

SmallTalkSymbol subclass: 'SmallTalkSymbolFalse'
       instanceVariableNames: ''
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkSymbolFalse methodsFor: 'testing'!

isSymbolFalse
	^ true
!

canReturn
	^true
! !

! SmallTalkSymbolFalse methodsFor: 'accessing' !

name
	^ 'false'
! !

! SmallTalkSymbolFalse methodsFor: 'compiling' !

genPush
    ^ self genByte: 16rFD.
!

genReturn
    ^ self genByte: 16rF3.
! !

SmallTalkSymbol subclass: 'SmallTalkSymbolStack'
       instanceVariableNames: ''
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkSymbolStack methodsFor: 'testing'!

isSymbolStack
	^ true
!

canReturn
	^ true

! !

! SmallTalkSymbolStack methodsFor: 'accessing' !

name
	^ 'stack'
! !

! SmallTalkSymbolStack methodsFor: 'compiling' !

genPush
    ^ self genByte: 16rF6.	"Dup"
!

genReturn
    ^ self genByte: 16rF1.
! !

SmallTalkSymbol subclass: 'SmallTalkSymbolLabel'
       instanceVariableNames: 'offset'
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkSymbolLabel class methodsFor: 'creation' !

new: aOffset
    " Fix this after cascading is fixed to work correctly "
     | temp |
     temp <- self new.
     temp offset: aOffset.
     ^temp
! !

! SmallTalkSymbolLabel methodsFor: 'testing'!

isSymbolLabel
	^ true
!

printOn: aStream
	aStream nextPutAll: 'LabelNode: '.
	offset asOop printOn: aStream.
!

= aSymbol
	^ aSymbol isSymbolLabel and: [ aSymbol offset = offset ] 
! !

! SmallTalkSymbolLabel methodsFor: 'accessing' !

name
	^ 'Label:'
!

offset
	^ offset
! !

! SmallTalkSymbolLabel methodsFor: 'modifing' !

offset: aOffset
	offset notNil ifTrue: [ offset unlabel ].
	aOffset notNil ifTrue: [ aOffset label ].
	^ offset <- aOffset.
! !

SmallTalkSymbol subclass: 'SmallTalkSymbolVarNode'
       instanceVariableNames: 'name offset'
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkSymbolVarNode class methodsFor: 'creation' ! 

new: aName
     ^ self new; name: aName offset: 0
!

new: aName offset: aOffset
     ^ self new; name: aName offset: aOffset
! !


! SmallTalkSymbolVarNode methodsFor: 'creation' !

name: aName offset: aOffset
	name <- aName.
	offset <- aOffset.
! !

! SmallTalkSymbolVarNode methodsFor: 'accessing' !

name
	^ name
!

offset
	^ offset
!

= aSymbol
	^ aSymbol name = name and: [ aSymbol class == (self class) and: 
		[ aSymbol offset = offset ]]
!

" Do nothing, so Literal and symbols work same"
release
	^ nil

! !

! SmallTalkSymbolVarNode methodsFor: 'modifing' !

offset: aOffset
	^ offset <- aOffset
! !

! SmallTalkSymbolVarNode methodsFor: 'compiling' !

genOpr: byteOne
   | array len opc |
   (offset between: 0 and: 15)
	 ifTrue: [ len <- 1.  opc <- byteOne bitOr: offset ]
	 ifFalse: [ len <- 2.  opc <- byteOne bitShift: -4 ].
   array <- ByteArray new: len.
   array at: 1 put: opc.
   len == 2 ifTrue: [ array at: 2 put: offset ].
   ^ array
!

genSize
    offset < 17 ifTrue: [ ^ 1 ]
 	       ifFalse: [ ^ 2 ].
! !

SmallTalkSymbolVarNode subclass: 'SmallTalkSymbolArg'
       instanceVariableNames: ''
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkSymbolArg methodsFor: 'testing'!

isSymbolArg
	^ true
! !

! SmallTalkSymbolArg methodsFor: 'compiling' !

genPush
   ^ self genOpr: 16r10
! !

SmallTalkSymbolVarNode subclass: 'SmallTalkSymbolTemp'
       instanceVariableNames: ''
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkSymbolTemp methodsFor: 'testing'!

isSymbolTemp
	^ true
!

canAssign
	^ true
!

canReturn
	^ true
! !

! SmallTalkSymbolTemp methodsFor: 'compiling' !

genPush
   ^ self genOpr: 16r40.
!

genReturn
   ^ self genOpr: 16r70.
!

genStore
   ^ self genOpr: 16r60.
! !

SmallTalkSymbolVarNode subclass: 'SmallTalkSymbolInst'
       instanceVariableNames: ''
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkSymbolInst methodsFor: 'testing'!

isSymbolInst
	^ true
!

canAssign
	^ true
! !

! SmallTalkSymbolInst methodsFor: 'compiling' !

genPush
   ^self genOpr: 16r30.
!

genStore
   ^self genOpr: 16r50.
! !

SmallTalkSymbolVarNode subclass: 'SmallTalkSymbolVar'
       instanceVariableNames: ''
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkSymbolVar methodsFor: 'testing'!

isSymbolVar
	^ true
!

canAssign
	^ true
! !

! SmallTalkSymbolVar methodsFor: 'compiling' !

genSize
	^ 2
!

genPush
   ^self genTwo: 16rF8 and: (offset offset).
!

genStore
   ^self genTwo: 16rF9 and: (offset offset).
! !

SmallTalkSymbolVarNode subclass: 'SmallTalkLiteral'
       instanceVariableNames: 'value usage'
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkLiteral class methodsFor: 'creation' ! 

new: aValue 
     ^ self new value: aValue 
! !

! SmallTalkLiteral methodsFor: 'creation' !

value: aValue 
	value <- aValue.
	offset <- 0.
	usage <- 1.
! !

! SmallTalkLiteral methodsFor: 'testing' !

isSymbolLiteral
	^ true
! !

! SmallTalkLiteral methodsFor: 'accessing' !

printOn: aStream
	aStream nextPutAll: 'Literal:'.
	value printOn: aStream.
!

value
	^ value
!

usage
	^ usage

! !

! SmallTalkLiteral methodsFor: 'modifing' !

used
	^ usage <- usage + 1
!

release
	^ usage <- usage - 1
!

= aLiteral
	^ self isSymbolLiteral and: [ aLiteral value == value ]
! !

! SmallTalkLiteral methodsFor: 'compiling' !

genSize
     value == 0 or: [ value == 1 ] ifTrue: [ ^ 1 ].
     offset < 17 ifTrue: [ ^ 1 ]
  	        ifFalse: [ ^ 2 ].
!

genPush
     value == 0 ifTrue: [ ^self genByte: 16rFF ].
     value == 1 ifTrue: [ ^self genByte: 16rFE ].
     ^self genOpr: 16r20.
!

genSend: superFlag argcount: count
   | opr array len |
   superFlag ifTrue: [ opr <- 16rD0 ] ifFalse: [ opr <- 16rE0 ].
   (offset between: 0 and: 15)
	 ifTrue: [ len <- 2.  opr <- opr bitOr: offset]
	 ifFalse: [ len <- 3.  opr <- opr bitShift: -4 ].
   array <- ByteArray new: len.
   array at: 1 put: opr.
   len == 3 ifTrue: [ array at: 2 put: offset ].
   array at: len put: count.
   ^ array
! !

SmallTalkSymbol subclass: 'SmallTalkSymbolSpecial'
       instanceVariableNames: 'value index'
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkSymbolSpecial class methodsFor: 'creation' !

index: aIndex value: aValue
	^ self new; index: aIndex value: aValue
! !

! SmallTalkSymbolSpecial methodsFor: 'creation' !

index: aIndex value: aValue
	index <- aIndex.
	value <- aValue.
! !

! SmallTalkSymbolSpecial methodsFor: 'testing'!

isSymbolSpecial
	^ true
!

index
	^ index
!

value
	^ value
!

printOn: aStream
	aStream nextPutAll: 'Special: '.
	value printOn: aStream
!

= aSymbol
	^ aSymbol isSymbolSpecial and: [ aSymbol value = value ]
! !

! SmallTalkSymbolSpecial methodsFor: 'compiling' !

genSize
     ^ 1
!

genSend: superFlag argcount: count
     ^ self genTwo: (16rB0 + index) and: count.
! !

Link subclass: 'SmallTalkCodeNode'
       instanceVariableNames: 'length offset refer'
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkCodeNode class methodsFor: 'creation'!

new
	^ super new; init.
! !

! SmallTalkCodeNode methodsFor: 'testing'!

isCodePush
	^ false
!

isCodeStore
	^ false
!

isCodeReturn
	^ false
!

isCodeSend
	^ false
!

isCodeJump
	^ false
!

isCodeJTrue
	^ false
!

isCodeJFalse
	^ false
!

isCodeBlockCopy
	^ false
!

isCodePopStack
	^ false
!

isCodeSendSuper
	^ false
!

isCodeBlock
	^ false
!

isCodeBlockReturn
	^ false
!

" Additional time saving checks. "
isCodePushStack
	^ false
!

isCodeSend: aSymbol
	^ false
!

isCodeJcond
	^ false
!

isCodeReturnStack
	^ false
!

isSymbolSelf
	^ false
!

isSymbolSuper
	^ false
!

isSymbolTrue
	^ false
!

isSymbolFalse
	^ false
!

isSymbolNil
	^ false
!

isSymbolArg
	^ false
!

isSymbolTemp
	^ false
!

isSymbolInst
	^ false
!

isSymbolVar
	^ false
!

isSymbolLiteral
	^ false
!

isSymbolStack
	^ false
!

isSymbolLabel
	^ false
!

isSymbolSpecail
	^ false
!

= aNode
	aNode isNil or: [ aNode isLabel ] ifTrue: [ ^ false ].
	^ aNode class == (self class).
!

" Override this in the class if we can assign to it "
canAssign
	^  false
!

" Override this in the class if we can directly return this type"
canReturn
	^ false
! !

! SmallTalkCodeNode methodsFor: 'accessing' !

offset
	^ offset
!

argcount
	^ 0
!

name
	^ 'codenode'
!

length
	^ length
!

value
	^ SmallTalkSymbolNil new.
!

isLabel
	^ refer ~= 0
!

release
	^ self
!

stack: max
	^ max
!

" Note wether node is a label or not "
printLabel: aStream
	| l |
	self asOop printOn: aStream.
	l <- self isLabel ifTrue: [ $* ] ifFalse: [ $  ].
	aStream nextPut: l
!

printOn: aStream
	self printLabel: aStream.
	aStream nextPutAll: (self name).
!

" Check node is begining of block "
beginBlock
    self nextLink notNil and: [self nextLink isLabel not] ifTrue: [ ^ true ]
	ifFalse: [ ^ false ].
! !

! SmallTalkCodeNode methodsFor: 'modifing' !

init
	offset <- 0.
	refer <- 0.
	length <- 0.
	^ self
!
	
offset: aOffset
	^ offset <- aOffset
!

value: aValue
	^ aValue.
!

length: size
	^ length <- size
!

label
	refer <- refer + 1.
!

unlabel
	refer <- refer - 1.
! 

advance: aDistance
	^ aDistance
!

advance
	^ self
!

" Replace current node with a new node "
replace: aNode
	aNode nextLink: self nextLink.
	self value: nil.
	self become: aNode.
	^ self
!

" Remove current node. "
removeSelf
        self value: nil.
        self become: self nextLink
!

" Remove the next node in list "
removeNext
	self nextLink value: nil.
	self nextLink: (self nextLink nextLink).
!

optimize
	^false
! !

SmallTalkCodeNode subclass: 'SmallTalkCodeOper'
       instanceVariableNames: 'value'
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkCodeOper class methodsFor: 'creation'!

new: aSym
	^ super new; value: aSym
! !

! SmallTalkCodeOper methodsFor: 'testing' !

isSymbolSelf
	^ value isSymbolSelf
!

isSymbolSuper
	^ value isSymbolSuper
!

isSymbolTrue
	^ value isSymbolTrue
!

isSymbolFalse
	^ value isSymbolFalse
!

isSymbolNil
	^ value isSymbolNil
!

isSymbolArg
	^ value isSymbolArg
!

isSymbolTemp
	^ value isSymbolTemp
!

isSymbolInst
	^ value isSymbolInst
!

isSymbolVar
	^ value isSymbolVar
!

isSymbolLiteral
	^ value isSymbolLiteral
!

isSymbolStack
	^ value isSymbolStack
!

isSymbolLabel
	^ value isSymbolLabel
!

isSymbolSpecail
	^ value isSymbolSpecial
!

= aNode
	aNode isNil or: [ aNode isLabel ] ifTrue: [ ^ false ].
	^ aNode class == (self class) and: [ aNode value == value ]
!
	
canAssign
	^ value canAssign
!

canReturn
	^ value canReturn
! !

! SmallTalkCodeOper methodsFor: 'accessing' !

value
	^value
!

size
    ^ value genSize.
!

printOn: aStream
	| v |
	self printLabel: aStream.
	aStream nextPutAll: (self name).
	v <- value.
	v isNil ifTrue: [ v <- 'XXXnilXXX' ].
	value printOn: aStream.
! !

! SmallTalkCodeOper methodsFor: 'modifing' !

value: aValue
	value notNil ifTrue: [ value release ].
	value <- aValue.
	^ self
! !

SmallTalkCodeOper subclass: 'SmallTalkCodePush'
       instanceVariableNames: ''
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkCodePush methodsFor: 'testing'!

isCodePush
	^ true
!

" Additional time saving checks. "
isCodePushStack
	^ value isSymbolStack
! !


! SmallTalkCodePush methodsFor: 'accessing' !

name
     ^ 'push '
!

stack: max
	| size |
	size <- self nextLink stack: (max + 1).
	^ max + 1 max: size
! !

! SmallTalkCodePush methodsFor: 'compiling' !

advance
   " Check if it could be a zero or a one. "
    self isSymbolLiteral ifTrue: [
	value value == 0 or: [ value value == 1 ]
		    ifTrue: [ value release ]
    ].
!

optimize
   | nxt |
   " If next node is a begining of a block, just return. "
   self beginBlock ifFalse: [ ^ false ].

   nxt <- self nextLink.
   " Remove unneded push/pop pairs "
   nxt isCodePopStack ifTrue: [
	nxt removeSelf.
	self removeSelf.
	^ true.
    ].

    " Convert push x/ push x to push x/ dup "
    self = nxt
	 ifTrue: [ nxt value: (SmallTalkSymbolStack new).  ^ true ].
		
   " Remove dups before returns "
    self isSymbolStack and: [
	(nxt isCodeReturn or: [ nxt isCodeBlockReturn])] ifTrue: [
		self removeSelf.
		^ true
    ].

   " Check if we can shorten a return TOS "
    nxt isCodeReturnStack and: [ self canReturn ] ifTrue: [
		  nxt value: (self value).
		  self removeSelf.
		  ^ true.
    ].

     " Remove push bool, jcond "
     nxt isCodeJcond ifTrue: [
	   self isSymbolTrue ifTrue: [
		nxt isCodeJTrue ifTrue: [ nxt cond: nil ]
				     ifFalse: [ self removeNext ].
		self removeSelf.
		^ true
	   ].
           self isSymbolFalse ifTrue: [
		nxt isCodeJFalse ifTrue: [ nxt cond: nil ]
				      ifFalse: [ self removeNext ].
		self removeSelf.
	        ^ true
	   ].
      ].

      self isSymbolStack and: [ nxt notNil ] ifFalse: [ ^ false ].

      " Convert  Dup, Store, Pop -> Store "
      nxt isCodeStore and: [ nxt beginBlock and: [
	 nxt nextLink isCodePopStack ]] ifTrue: [
		nxt removeNext.
		self removeSelf.
		^ true.
      ].


	" Check for: dup       Replace with:    jcond x + 1 if cond1 =~ cond2
		     jcond1 x		 or:    jcond y     if cond1 = cond2
		     pop
		     ----
		  x: jcond2 y
	"
     nxt isCodeJcond and: [ nxt nextLink notNil and: [
	     nxt nextLink isCodePopStack and: [
	     nxt value offset isCodeJcond and: [
	     nxt value offset value notNil ]]]] ifTrue: [
"		'checking pop/jump' print. "
		" Remove Dup and Pop "
		nxt removeNext.
		" Advance Jump forward one step "
		nxt cond = (nxt value offset cond)
		  ifTrue: [ nxt value offset: (nxt value offset) ]
		  ifFalse: [ nxt value offset: (nxt value offset nextLink) ].
		self removeSelf.
		^ true
     ].

     ^ false
!
    		
" Compile a node into binary from "
generate
	^ value genPush.
! !

SmallTalkCodeOper subclass: 'SmallTalkCodeStore'
       instanceVariableNames: ''
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkCodeStore methodsFor: 'testing'!

isCodeStore
	^ true
! !

! SmallTalkCodeStore methodsFor: 'accessing' !

name
	^ 'store '
!

stack: max
	^ self nextLink stack: max
! !

! SmallTalkCodeStore methodsFor: 'compiling' !

optimize
  | temp |
  " Convert  Store x, Push x -> Dup, Store x "
   self beginBlock and: [ self nextLink isCodePush and: [
	        self value = (self nextLink value)]]
       ifTrue: [
		temp <- self value.
	 	self replace: (SmallTalkCodePush new: 
				(SmallTalkSymbolStack new)).
		self nextLink replace: (SmallTalkCodeStore new: temp). 
		^ true
	].
   ^ false
!

" Compile a node into binary from "
generate
	^ value genStore.
! !


SmallTalkCodeOper subclass: 'SmallTalkCodeReturn'
       instanceVariableNames: ''
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkCodeReturn methodsFor: 'testing'!

isCodeReturn
	^ true
!

isCodeBlockReturn
	^ false
!

isCodeReturnStack
	^ value isSymbolStack
! !

! SmallTalkCodeReturn methodsFor: 'accessing' !

name
	^ 'return '
! !

! SmallTalkCodeReturn methodsFor: 'compiling' !
	
optimize
" Remove dead code after jump or return "
    | changed |
    changed <- false.
    [ self beginBlock ] whileTrue: [
	 self removeNext.
	 changed <- true. ].
    ^ changed
!

" Compile a node into binary from "
generate
	^ value genReturn
! !

SmallTalkCodeNode subclass: 'SmallTalkCodePopStack'
       instanceVariableNames: ''
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkCodePopStack methodsFor: 'testing'!

isCodePopStack
	^ true
!

= aNode
	aNode isNil or: [ aNode isLabel ] ifTrue: [ ^ false ].
	^ aNode isCodePopStack
! !

! SmallTalkCodePopStack methodsFor: 'accessing' !

name
    ^ 'pop'
!

size
    ^ 1
!

stack: max
	^ self nextLink stack: max.
! !

! SmallTalkCodePopStack methodsFor: 'compiling' !
	
" Compile a node into binary from "
generate
	| array |
	array <- ByteArray new: 1.
	array at: 1 put: 16rF7.
	^array
! !

SmallTalkCodeOper subclass: 'SmallTalkCodeJump'
       instanceVariableNames: 'type advance'
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkCodeJump class methodsFor: 'creation' !

cond: aValue
     ^ super new; value: (SmallTalkSymbolLabel new) cond: aValue advance: 0
!

new: aLabel cond: aValue
     ^ super new; value: (SmallTalkSymbolLabel new: aLabel) cond: aValue advance: 0
!

new: aLabel cond: aValue advance: aAmount
     ^ super new; value: (SmallTalkSymbolLabel new: aLabel) cond: aValue advance: aAmount
! !

! SmallTalkCodeJump methodsFor: 'testing'!

isCodeJump
	^ type isNil
!

isCodeJTrue
	^ type == true
!

isCodeJFalse
	^ type == false
!

isCodeJcond
	^ type notNil
!

= aNode
	aNode isNil or: [ aNode isLabel ] ifTrue: [ ^ false ].
	^ aNode class == SmallTalkCodeJump and: [ aNode value == value and: [
		aNode cond == type ]].
! !

! SmallTalkCodeJump methodsFor: 'accessing' !

cond
	^ type
!

size
    | i |
    i <- value offset offset - (offset + length).
    (i between: 0 and: 15) ifTrue: [ ^ 1 ].
    (i between: -127 and: 128) ifTrue: [ ^ 2].
    type isNil ifTrue: [ ^ 3.  ] ifFalse: [ ^ 4.  ].
!

stack: max
	type isNil ifTrue: [ ^ max ]
	          ifFalse: [ ^ self nextLink stack: max ]
!

name
	type isNil ifTrue: [ ^ 'Jump ' ].
        type ifTrue: [ ^ 'JTrue ' ].
	^ 'JFalse '.
! !

! SmallTalkCodeJump methodsFor: 'modification' !

value: aValue cond: aCond advance: aAmount
	self value: aValue.
	type <- aCond.
	advance <- aAmount.
!

value: aValue cond: aCond
	self value: aValue.
	type <- aCond.
!

cond: aCond 
	type <- aCond.
!

advance: aDistance
	^ advance <- aDistance
!

advance
	| i |
	i <- 0.
	[ i < advance ] whileTrue: [
		 value offset: value offset nextLink.
		 i <- i + 1 ].
! !

! SmallTalkCodeJump methodsFor: 'generation' !

optimize
" Remove dead code after jump or return "
    | changed where |
    changed <- false.

    where <- self value offset.
    " Redirect jump to a jump "
    where isCodeJump ifTrue: [
	self value: (where value).
	where <- self value offset.
	changed <- true.
    ].

    " Remove dead code after this jump "
    [ self beginBlock ] whileTrue: [
	 self removeNext.
	 changed <- true. ].

   " A Jump to next can be cleaned up "
    self nextLink == where ifTrue: [
    " JCond to next is just a pop "
	 self isCodeJcond ifTrue: [
	     self replace: (SmallTalkCodePopStack new).
	] ifFalse: [
      	     self removeSelf.
	].
	^ true.
     ].

    ^ changed
!

" Compile a node into binary from "
generate
	| array len opc operand place |
        operand <- value offset offset - (offset + length).
	array <- ByteArray new: length.
	" Set the opcode "
	type isNil ifTrue: [ opc <- 16rA0 ]
		   ifFalse: [ type ifTrue: [ opc <- 16r80 ]
				  ifFalse: [ opc <- 16r90 ]].
	place <- 2.

	" Fix opcode based on size of jump "
	length = 1
	     ifTrue: [  opc <- opc bitOr: operand ]
	     ifFalse: [
	        length = 2
		 ifTrue: [ opc <- opc bitShift: -4 ]
		 ifFalse: [
			type isNil ifTrue: [ opc <- 0 ]
				   ifFalse: [ opc <- opc bitXor: 16r10 + 3.
					      array at: 2 put: 0.
					      place <- 3 ].
		 ]].

	" Fill in array "
	array at: 1 put: opc.
	length > 1 ifTrue: [ array at: place put: operand ].
	length > 2 ifTrue: [ array at: (place + 1) put: (operand bitShift: -8)].
	^ array
! !

SmallTalkCodeOper subclass: 'SmallTalkCodeBlock'
       instanceVariableNames: 'argcount'
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkCodeBlock class methodsFor: 'creation'!

new: value argcount: count 
	^ super new; value: value argcount: count 
! !

! SmallTalkCodeBlock methodsFor: 'testing'!

isCodeBlockCopy
	^ true
! !

! SmallTalkCodeBlock methodsFor: 'accessing' !

argcount
	^ argcount
!

size
    | i |
    i <- value offset offset - (offset + length).
    (i between: 0 and: 15) ifTrue: [ ^ 3 ].
    (i between: -127 and: 128) ifTrue: [ ^ 4].
    ^ 5.
!

stack: max
	^ (value offset stack: (max + 1)) max: argcount
!

name
	^ 'block '
! !

! SmallTalkCodeBlock methodsFor: 'modifing' !

value: aValue argcount: aCount
	self value: aValue.
	argcount <- aCount.
	^ self
!

advance
	value offset: value offset nextLink.
!

argcount: aCount
	^ argcount <- aCount
! !

! SmallTalkCodeBlock methodsFor: 'compiling' !

" Optimize block loops, this is done here before any jumps are modified"
optimize
	| nxt temp ptr |
	" Check for: blk 0, x	Replace with:   z: 
		     {C1}			   {C1}
		     retblk			   jmp x
		  x: dup                           ----
		     send value			   ----
		     jcond y			x: jcond y
		     {C2}			   {C2}
		     jmp x			   jmp z
		  y: pop			y:
	"
		
	self argcount == 0 ifFalse: [ ^false ].
"	    'Checking block' print. "
	" Point nxt to instruction after block. x"
	nxt <- self value offset.
	nxt notNil and: [nxt isCodePushStack and: [
	    (nxt nextLink isCodeSend: #value ) and: [ 
	     nxt nextLink nextLink isCodeJcond and: [
	     nxt nextLink nextLink value offset isCodePopStack ]]]]
		 ifFalse: [ ^ false ].

"		'Optimizing loop' print. "
	" Point to after blk instruction (z + 1)"
	temp <- self nextLink.

	" Point all labels that point to Dup to just after block z"
	ptr <- nxt.
	[ ptr notNil ] whileTrue: [
		ptr isSymbolLabel and: [ ptr value offset == nxt ]
			ifTrue: [ ptr value offset: temp ].
		ptr <- ptr nextLink.
	].

	" Convert all ret blk to Jump condition "
	nxt <- nxt nextLink nextLink.
	[ temp notNil and: [temp ~= nxt] ] whileTrue: [
		temp isCodeBlockReturn ifTrue: [
		    temp replace: (SmallTalkCodeJump new: nxt cond: nil).
		].
		temp <- temp nextLink.
	].
		
	" Remove extra instructions "
	nxt value offset removeSelf.    " last Pop "
	self removeSelf.		" Blk "
	^ true
!

" Compile a node into binary from "
generate
	| array opc operand |
        operand <- (value offset offset) - (offset + length).
	( operand between: 0 and: 15) 
	     ifTrue: [ opc <- 16rA0 bitOr: operand ]
	     ifFalse: [
	        (operand between: -127 and: 128)
		 ifTrue: [ opc <- 16r0A ]
		 ifFalse: [
			array <- ByteArray new: 5.
			array at: 1 put: 16r0F.
			array at: 2 put: argcount.
			array at: 3 put: 0.
			array at: 4 put: operand.
			array at: 5 put: (operand bitShift: -8).
			^ array
		 ]].
	array <- ByteArray new: length.
	array at: 1 put: 16r0F.
	array at: 2 put: argcount.
	array at: 3 put: opc.
	length == 4 ifTrue: [ array at: 2 put: operand ].
	^ array
! !

SmallTalkCodeBlock subclass: 'SmallTalkCodeSend'
       instanceVariableNames: 'superFlag'
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkCodeSend class methodsFor: 'creation'!

new: value argcount: count super: superFlag
	^ super new; value: value argcount: count super: superFlag
! !

! SmallTalkCodeSend methodsFor: 'testing'!

isCodeSend
	^ super == false
!

isCodeSendSuper
	^ super == true
!

isCodeSend: aSymbol
	| temp |
	superFlag ifTrue: [ ^ false ].
	value value == aSymbol ifTrue: [^ true].
	^ false
!

isCodeBlockCopy
	^ false
! !

! SmallTalkCodeSend methodsFor: 'accessing' !

size
    ^ value genSize + 1
!

stack: max
     | size |
     size <- max - argcount min: 1.
     size <- (self nextLink stack: size) + argcount.
     ^ size max: max.
!

name
	^ superFlag ifTrue: [ 'SSend ' ] ifFalse: [ 'Send ' ]
! !

! SmallTalkCodeSend methodsFor: 'modifing' !

value: aValue argcount: aCount super: ss
	self value: aValue argcount: aCount.
	superFlag <- ss.
	^ self
! !

! SmallTalkCodeSend methodsFor: 'compiling' !

advance
    | temp sym |
    superFlag ifTrue: [ ^ self ].
    sym <- value value.
    temp <- Smalltalk at: #SpecialSelectors ifAbsent: [ Array new: 0 ].
    1 to: temp size do:
	 [ :sel | (temp at: sel) = sym
   	       ifTrue: [ self value:
		 (SmallTalkSymbolSpecial index: (sel - 1)  value: sym)]].
!

" There is nothing we can optimize "
optimize
     ^ false
!

generate
     ^ value genSend: superFlag argcount: argcount
! !

SmallTalkCodeNode subclass: 'SmallTalkCodeBlockReturn'
       instanceVariableNames: ''
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkCodeBlockReturn methodsFor: 'testing'!

isCodeBlockReturn
	^ true
!

= aNode
	aNode isNil or: [ aNode isLabel ] ifTrue: [ ^ false ].
! !

! SmallTalkCodeBlockReturn methodsFor: 'accessing' !

	
size
        ^ 1
!

name
	^ 'BReturn'
! !

! SmallTalkCodeBlockReturn methodsFor: 'compiling' !

optimize
" Remove dead code after jump or return "
    | changed |
    changed <- false.
    [ self beginBlock ] whileTrue: [
	 self removeNext.
	 changed <- true. ].
    ^ changed
!
	
" Compile a node into binary from "
generate
	| array |
	array <- ByteArray new: 1.
	array at: 1 put: 16rF5.
	^ array 
! !


LinkedList subclass: 'SmallTalkCodeTree'
       instanceVariableNames: 'superFlag lits'
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkCodeTree class methodsFor: 'creation'!

new
	^ super new init
! !

! SmallTalkCodeTree methodsFor: 'Initializing' !

init
	superFlag <- false.
        lits <- Bag new.
! !

! SmallTalkCodeTree methodsFor: 'Generation' !

" Add a new literal table node. "
addLiteral: aObject
    | newLit |
    newLit <- lits detect: [ :el | el value class == (aObject class)
			 and: [el value = aObject] ]
	 ifNone: [ nil ].
    newLit notNil ifTrue: [ newLit used. ^ newLit ].
    newLit <- SmallTalkLiteral new: aObject.
    lits add: newLit.
    ^ newLit
! 

" Generate Empty location "
genPush: aSym
	^ self addLast: (SmallTalkCodePush new: aSym).
!

genPushLit: aLit
	^ self addLast: (SmallTalkCodePush new: (self addLiteral: aLit)).
!

" Generate push nil opcode.  "
genPushNil
	^ self genPush: (SmallTalkSymbolNil new) 
!

" Generate push self opcode.  "
genPushSelf
	^ self genPush: (SmallTalkSymbolSelf new) 
!

genDupTOS
	 ^ self genPush: (SmallTalkSymbolStack new)
!

" Generate return nil opcode.  "
genReturnNil
	 ^ self addLast: (SmallTalkCodeReturn new: (SmallTalkSymbolNil new))
!

" Generate return Top of stack opcode. "
genReturnTOS
	 ^ self addLast: (SmallTalkCodeReturn new: (SmallTalkSymbolStack new))
!

" Generate return Top of stack opcode. "
genReturnBlock
	 ^ self addLast: (SmallTalkCodeBlockReturn new)
!

genPopTOS
	 ^ self addLast: (SmallTalkCodePopStack new)
!

genJumpForw
	 ^ self addLast: (SmallTalkCodeJump cond: nil)
!

genJumpCond: aBoolean
	 ^ self addLast: (SmallTalkCodeJump cond: aBoolean).
!

getCodeLabel
	^ lastLink
!

genStore: aSym
	 ^ self addLast: (SmallTalkCodeStore new: aSym)
!

genSend: aMsg argcount: count super: ss
	^ self addLast: (SmallTalkCodeSend new: 
			(self addLiteral: aMsg asSymbol)
			   argcount: count super: ss)
!

genBlockCopy: count
	" Fix stack so we have enough space to push arguments "
	^ self addLast: (SmallTalkCodeBlock new: 
				(SmallTalkSymbolLabel new)
				argcount: count).
!

genJump: aLabel
	 ^ self addLast: (SmallTalkCodeJump new: aLabel cond: nil).
!

setJumpTarget: aLabel advance: amount
	aLabel value: (SmallTalkSymbolLabel new: lastLink).
	aLabel advance: amount 
! !

! SmallTalkCodeTree methodsFor: 'Compiling' !



" Optimize a code block. "
optimize
    | temp |
    " Fix jump targets to point to next instruction, also set referenced flag. "
   " Adjust jump and Send instructions "
    self do: [ :cur | cur advance ].
   " self do: [ :cur | cur print ]."

    " Continue to optimize blocks until there are no changes. "
    temp <- true.
    [ temp ] whileTrue: [
       temp <- false.
    "   self do: [ :cur | cur optimize ifTrue: [ temp <- true] ]."
    "   self do: [ :cur | cur print ]. "
    ].
!

" Sort literals by usage count. "
sortLiterals: superClass 
   | sort found index last litcount|

   " Count number of used literals "
   found <- nil.
   litcount <- 0.
   lits do: [ :lp |
	(lp value) == superClass ifTrue: [ found <- lp. lp used ].
	(lp usage) > 0 ifTrue: [ litcount <- litcount + 1 ].
   ].

   " Add in superclass if we need it "
    superFlag and: [ found isNil] ifTrue: [
	found <- self addLiteral: superClass.
	litcount <- litcount + 1.
    ].
   
   " Build an array to sort them "
    sort <- Array new: litcount.
    lits do: [ :lp |
        lp == found ifTrue: [ sort at: litcount put: lp ]
	   ifFalse: [
	      (lp usage) > 0 ifTrue: [
	           " Find slot to put it in "
	           index <- 1.
		   [ index < litcount and: [ (sort at: index) notNil ]]
		       whileTrue: [
	                   (sort at: index) usage > (lp usage) ifTrue: [
			    " Find first empty spot"
			     last <- index + 1.
			     [ last < litcount and: [ (sort at: last) notNil ]]
			         whileTrue: [ last <- last + 1 ].
				
			     " Move up one spot to make room "
			     last to: (index + 1) by: -1 do: [ :j |
				   sort at: j put: (sort at: (j - 1)) ].
			     sort at: index put: nil.
	                    ] ifFalse: [ index <- index + 1].
		     ].
		     sort at: index put: lp.
		]
	   ]
     ].
					
   " Now set offsets based on index into litarray "
    1 to: litcount do: [ :i | (sort at: i) offset: (i - 1) ].
    lits <- sort.
!

" Generate a block of code. "
generate
   | changed i j len arrayStream |
   
    changed <- true.
    [ changed ] whileTrue: [
"	'Optimizing size' print. "
	changed <- false. 

       " Set offsets of all blocks "
	i <- 0.
	self do: [ :cur | i <- (cur length) + (cur offset: i) ].

       " Readjust lengths until they don't change anymore "
	self do: [ :cur |
	    len <- cur size.
	    cur length = len ifFalse: [ cur length: len. changed <- true ].
        ]
    ].

    arrayStream <- WriteStream on: (ByteArray new: 0).

    " Convert everything into code blocks "
    self do: [ :cur | arrayStream nextPutAll: (cur generate) ].
    ^ arrayStream contents
! !

! SmallTalkCodeTree methodsFor: 'Methods' !

" Check if code could be a get instance variable.
    psh ins #
    ret tos
"
 
isGetInst
   | cur inst |
    cur <- firstLink.

    cur isCodePush and: [ cur isSymbolInst ] ifFalse: [ ^ nil ].
    inst <- cur value offset.
    cur <- cur nextLink.
    cur isNil ifTrue: [ ^ nil ].
    cur isCodeReturnStack ifFalse: [ ^ nil ].
    " Build method "
    ^ CompiledMethod newMethod: 0 header: ((inst * 256) + 16r34000000)
!

" Check if code could be a set instance variable.
 
   psh arg 0       psh arg 0
   str ins #	   dup
   psh arg 0	   str ins #
   ret tos         ret tos
"
isSetInst
   | cur inst |
    cur <- firstLink.

    cur isCodePush and: [ cur isSymbolArg and: [ cur value offset = 0]]
	 ifFalse: [ ^ nil ].
    cur <- cur nextLink.
    cur isNil ifTrue: [ ^ nil ].
    cur isCodeStore and: [ cur isSymbolInst ] ifTrue: [
        inst <- cur value offset.
	cur <- cur nextLink.
        cur isCodePush and: [ cur isSymbolArg and:
	    [ cur value offset = 0]] ifFalse: [ ^ nil ].
    ] ifFalse: [
    	cur isCodePushStack
	  ifTrue: [
	    cur <- cur nextLink.
            cur isNil ifTrue: [ ^ nil ].
            cur isCodeStore and: [ cur isSymbolInst ]
	       ifTrue: [ inst <- cur value offset. ]
	       ifFalse: [ ^ nil ] ]
          ifFalse: [ ^ nil ].
    ].
    cur nextLink isCodeReturnStack ifFalse: [ ^ nil ].
    " Build method "
    ^ CompiledMethod newMethod: 0 header: ((inst * 256) + 16r38000000)
!

" Convert codetree into a method. "
makeMethod: aClass argcount: count temps: tempcount for: primitive
    | bytecodes header eheader method litcount maxstack |

    " Clean up generated code. "
    self optimize.
    " Check if we can shortcut this method "
    tempcount = 0 ifTrue: [
	(method <- self isGetInst) notNil ifTrue: [ ^ method ].
	(method <- self isSetInst) notNil ifTrue: [ ^ method ]
    ].

    " Sort literals by usage "
    self sortLiterals: aClass.
    litcount <- lits size.
    maxstack <- firstLink stack: 0.
    primitive > 0 or: [ count > 12 ] ifTrue: [ 
        header <- litcount + 1 + (tempcount bitShift: 8) +
		   (maxstack bitShift: 16) + 16r3C000000.
	eheader <- primitive + (count bitShift: 16).
    ] ifFalse: [
        header <- litcount + (tempcount bitShift: 8) + (maxstack bitShift: 16)
			+ (count bitShift: 26).
	eheader <- nil.
    ].

    " Convert code into byte codes. "
    bytecodes <- self generate.

    " Build method "
    method <- CompiledMethod newMethod: bytecodes size header: header.
    1 to: litcount do: [ :i |
	 method objectAt: (i + 1) put: ((lits at: i) value)].
    eheader notNil ifTrue: [ method objectAt: (litcount + 2) put: eheader ].
    " Copy over code "
    1 to: bytecodes size do: [ :i | method byteAt: i put: (bytecodes at: i)].
    ^ method
! !


Object subclass: 'Compiler'
       instanceVariableNames: 'code token syms tempcount argcount class primnum sel inBlock optimBlk method error'
       classVariableNames: '' poolDictionaries: '' category: nil !

! Compiler class methodsFor: 'creation'!

evaluate: aString
    | comp |
    comp <- self new.
    aString print.
    (comp compileForExecute: aString) ifFalse: [ ^ comp error ].
    "comp method print."
    ^ comp method evaluate.
!

compile: aString forClass: aClass classified: aCategory
    | comp |
    comp <- self new.
    (comp compile: aString forClass: aClass) ifFalse:
	 [ ^ self ].
    comp method print.
    comp method description:
	    (MethodInfo sourceCode: aString forCategory: aCategory).
    aClass addSelector: comp select
           withMethod: comp method
           classified: aCategory.
    ^ self.
!

compile: aString forClass: aClass
    ^ self compile: aString forClass: aClass classified: nil
!

compile: aString forClass: aClass notify: aBlock
    ^ self compile: aString forClass: aClass classified: nil notify: aBlock
!

compile: aString forClass: aClass classified: aCategory notify: aBlock
    | comp |
    comp <- self new.
    (comp compile: aString forClass: aClass) ifFalse:
	 [ ^ aBlock value: comp errorstr ].
    comp method description:
	    (MethodInfo sourceCode: aString forCategory: aCategory).
    aClass addSelector: comp select
           withMethod: comp method
           classified: aCategory.
    ^ self.
! !

! Compiler methodsFor: 'initialize' !

init: aString
    code <- SmallTalkCodeTree new.
    token <- SmallTalkToken on: aString.
    syms <- Dictionary new.
    tempcount <- 0.
    argcount <- 0.
    class <- Object.
    sel <- nil.
    inBlock <- false.
    optimBlk <- false.
    method <- nil.
    primnum <- 0.

    " Add in defined objects "
    self addSym: (SmallTalkSymbolSelf new).
    self addSym: (SmallTalkSymbolSuper new).
    self addSym: (SmallTalkSymbolTrue new).
    self addSym: (SmallTalkSymbolFalse new).
    self addSym: (SmallTalkSymbolNil new).

    token next.
! !

! Compiler methodsFor: 'access'!

method
    ^ method
!

select
    ^ sel
!

error
    self error: error
!

errorstr
    ^ error

! !

! Compiler methodsFor: 'compile'!

" Compile a string for a class. "
compile: aString forClass: aClass
    | offset |
    "stdout nextPutAll: aString."
    self init: aString.
    (class <- aClass) notNil ifTrue: [
         offset <- 0.
         class allInstVarNames do: [ :var |
	    self addSym: (SmallTalkSymbolInst new: var offset: offset).
	    offset <- offset + 1.
         ]
    ].
    self messagePattern ifFalse: [ ^ false ].
    sel <- sel asSymbol.
    self doTemps ifFalse: [ ^ false ].
    " Check if primitive method. "
    self parsePrimitive ifFalse: [ ^ false ].
    self doBody ifFalse: [ ^ false ].
    code genPopTOS.
    " Shove a return of self on end of method. "
    code genPushSelf.
    code genReturnTOS.
    token <- nil.
    method <- code makeMethod: aClass superclass
		   argcount: argcount
		   temps: tempcount
	           for: primnum.
    "method print."
    syms <- code <- nil.
    stdout nextPutAll: 'Class '.
    stdout nextPutAll: (aClass name).
    stdout nextPut: ' '.
    stdout nextPutAll: sel asString.
    stdout nl.
    ^ true 
!

" Compile for execute. "
compileForExecute: aString
    self init: aString.
    self doTemps.
    self doBody ifFalse: [ ^ false].
    code genReturnTOS.
    token <- nil.
    method <- code makeMethod: nil argcount: 0 temps: tempcount for: primnum.
    syms <- code <- nil.
    ^ true  
!

parseError: aMessage
    error <- aMessage. 
    error printOn: stderr.
    stderr nl.
    ^ false
! !

! Compiler methodsFor: 'symbol table' !

" Add a symbol node "
addSym: aSym 
     | node sym |
     sym <- aSym name asSymbol.
     node <- syms associationAt: sym ifAbsent: [ nil ].
     node isNil 
	ifTrue: [ syms at: sym put: aSym. ^ aSym ]
     	ifFalse: [ self parseError: ((aSym name) , ' multiply defined'). ^ nil].
!

" Add a new temp symbol table node. "
addTemp
     | sym |
     sym <- SmallTalkSymbolTemp new: (token value) offset: tempcount.
     token next.
     tempcount <- tempcount + 1.
     ^ self addSym: sym.
!

" Add a argument node "
addArg
     | sym |
     sym <- SmallTalkSymbolArg new: (token value) offset: argcount.
     token next.
     argcount <- argcount + 1.
     ^ self addSym: sym.
!

" Remove a symbol from symbol table "
removeSym: aSym
    | sym |
    sym <- aSym name asSymbol.
    syms removeKey: sym ifAbsent: [ ^ nil ].
!

" Lookup symbol in symbol table. "
findSymbol
    | var sym name temp |
    name <- token value asSymbol.
    sym <- syms associationAt: name ifAbsent: [ nil ].

    sym notNil ifTrue: [ ^ sym value ].

    " See if it is a class variable "
    var <- nil.
    class notNil ifTrue: [
	temp <- class.
	[ var isNil and: [ temp notNil ]] whileTrue: [
	    (var <- temp classPool) notNil ifTrue: [
	       var <- var associationAt: name ifAbsent: [nil]].
	    temp <- temp superclass.	"Walk up class chain "
	]
    ]. 

    " See if it is a pool variable "
     var isNil ifTrue: [
        " See if it is a shared pool "
        class allSharedPools do: [ :pool |
  	  var <- Smalltalk at: pool ifAbsent: [nil].
	  var notNil ifTrue: [
	      var <- var associationAt: name ifAbsent: [ nil ].
	      " If we found it, add it into symbol table "
	      var notNil ifTrue: [
		^ syms at: name put: (SmallTalkSymbolVar new: name asString 
				offset: (code addLiteral: var)).
	      ]
	  ] 
	]
    ].

    " If not found try Smalltalk dictionary "
    var isNil ifTrue: [
	 var <-  Smalltalk associationAt: name ifAbsent: [nil]].
    
    " If we found something, add it in "
    var notNil ifTrue: [
	^ syms at: name put: (SmallTalkSymbolVar new: name asString
					offset: (code addLiteral: var)).
    ].
    self parseError: ('Unable to find symbol ' , name).
    ^ nil
! !

! Compiler methodsFor: 'private' !

" Parse the message pattern. "
messagePattern
    token isKeyName
       ifTrue: [ sel <- token value.  token next. ]
       ifFalse: [ token isKeyKeyword
	 ifTrue: [ ^ self keyMessage ]
	 ifFalse: [ token isKeySpecial 
	   ifTrue: [
		sel <- token value. 
		token next isKeyName ifTrue: [ self addArg ]
	           ifFalse: [ ^ self parseError: 'Binary not followed by name' ]
	        ]
           ifFalse: [ ^ self parseError: 'Illegal message selector' ]
	   ]
      ].
    ^ true
!

" Parse a keywork selector pattern. "
keyMessage
    sel <- token value.
    [ token next isKeyName ] whileTrue: [
	self addArg.
	token isKeyKeyword ifFalse: [ ^ true ].
	sel <- sel , (token value).
    ].
    self parseError: 'Keyword message pattern not followed by a name'.
    ^ false
!

" Parse temporaries.   "
doTemps
    token isVarSep ifTrue: [
	token next.
	[ token isKeyName ] whileTrue: [ self addTemp ].
	token isVarSep ifTrue: [ token next ]
		       ifFalse: [ ^self parseError: 'Needs to be name or |' ].
    ].
    ^ true
!

" Parse a primitive declaration. "
parsePrimitive
    token isKeySpecial and: [token value = '<'] ifTrue: [
	" Handle Primitive "
	token next isKeyName and: [token value = 'primitive' ] ifTrue: [
	    token next isKeyLiteral and:
			 [ token value class == SmallInteger ] ifTrue: [
		primnum <- token value.
		token next isKeySpecial and: [ token value = '>' ] ifTrue: [
			token next.
			^ true
		]
            ]
        ].
	^ self parseError: 'Invalid primitive'
    ].
    ^ true
!

" Parse body of definition. "
doBody
    " If we reached end of stream, then just return "
    token isKeyEOS ifTrue: [ ^ true ].

    " If we are at the end of a block already, assume empty block and push
       a nil term. "
    token isKeyRBrack ifTrue: [
	code genPushNil.
        inBlock not ifTrue: [ ^ self parseError: 'Mismatched ]' ].
	^ true
    ].
    [ true ] whileTrue: [
	token isKeyReturn ifTrue: [
		token next.
		self doExpression ifFalse: [ ^ false ].
		code genDupTOS.
	        code genReturnTOS.
	] ifFalse: [
		self doExpression ifFalse: [ ^ false ]. 
	].

	token isKeyEOS ifTrue: [
		^ true
	] ifFalse: [
	    token isKeyPeriod ifTrue: [
		code genPopTOS.
		" End of Block "
	        token next isKeyRBrack ifTrue: [
		    code genPushNil.
		    ^ true
	        ] ifFalse: [
  	        " End of method? "
	            token isKeyEOS ifTrue: [ ^ true ]
	        ].
   	    ] ifFalse: [
		token isKeyRBrack
		   ifTrue: [
		       inBlock ifFalse: [ ^ self parseError: 'Extra ]' ].
	   	       ^ true ]
	           ifFalse: [ ^ self parseError: 'Invalid statement ending'.  ]
	    ]
	]
   ]
!

" Parse Expression. "
doExpression
    | superFlag asgname |

    superFlag <- false.
    token isKeyName ifTrue: [
	asgname <- self findSymbol.
	asgname isNil ifTrue: [
            ^ self parseError: ('Invalid asgname ' , token value).
        ].
	token next isKeyAssign ifTrue: [
	    asgname canAssign ifFalse: [
            	^ self parseError: 'Invalid asignment name ',  (asgname name).
	    ].
	    token next.
	    self doExpression ifFalse: [ ^ false ].
	    code genDupTOS.
	    code genStore: asgname.
 	    ^ true
        ] ifFalse: [ superFlag <- self nameTerm: asgname ].
    ] ifFalse: [ superFlag <- self doTerm ].
    superFlag isNil ifTrue: [ ^ false ]
                    ifFalse: [ ^self doContinue: superFlag ].
!

" Parse a term. "
doTerm
    | superFlag sym |

    token isKeyLiteral ifTrue: [
	  code genPushLit: token value.
	  token next.
	  ^ false ].
    token isKeyName ifTrue: [
	  sym <- self findSymbol.
	  sym isNil ifTrue: [
            ^ self parseError: 'Invalid name ' , token value.
	  ].
	  superFlag <- self nameTerm: sym.
	  token next.
	  ^ superFlag ].
    token isKeyLBrack ifTrue: [ ^self doBlock ].
    token isKeyRParen ifTrue: [
	  token next.
          self doExpression ifFalse: [ ^ nil ].
	  token isKeyLParen ifFalse: [ self parseError: 'Missing )'. ^ nil ]].
	  token next.
	  ^ false. ].
    token isKeyLParen ifTrue: [ ^ false ].
    token isKeyRBrack ifTrue: [ ^ false ].
    token isKeyEOS ifTrue: [ ^ false ].
    token isKeyPeriod ifTrue: [ ^ false ].
    self parseError: 'Invalid terminal'.
    ^ nil
!


" Parse a name terminal. "
nameTerm: aSym 
    aSym isNil ifTrue: [
	self parseError: 'Invalid name terminal'.
	^ nil
    ].
    code genPush: aSym.
    ^ aSym isSymbolSuper
!

" Handle rest of expression.
  message expression or
  message expression ; message expression "
doContinue: superFlag
   | s |
    s <- self keyContinue: superFlag.
    s isNil ifTrue: [ ^ false ].
    [ s not and: [ token isKeyCascade ] ] whileTrue: [
	token next.
	code genDupTOS.
	s <- self keyContinue: superFlag.
	code genPopTOS.
        s isNil ifTrue: [ ^ false ].
    ].
    ^ true
!

" Handle keyword continuation. "
keyContinue: superFlag
    | argc key pat s|

    superFlag isNil ifTrue: [ ^ nil ].		" Parse error, quick exit"

    (s <- self doBinaryContinue: superFlag) isNil ifTrue: [ ^ nil ].
    token isKeyKeyword ifFalse: [ ^ false ].

   " Check if it is a built in keyword message "
    key <- token value.
    key = 'ifTrue:' or: [ key = 'ifFalse:'] ifTrue: [ ^ self doIfCond: key ].
    key = 'whileTrue:' ifTrue: [ ^ self doWhile: false ].
    key = 'whileFalse:' ifTrue: [ ^ self doWhile: true ].
    key = 'and:' or: [ key = 'or:' ] ifTrue: [ ^ self doAndOr: key ].

    pat <- ''.
    argc <- 0.
    [ token isKeyKeyword ] whileTrue: [
	pat <- pat , (token value).
	argc <- argc + 1.
	token next.
	(self doBinaryContinue: self doTerm) isNil ifTrue: [ ^ nil ].
    ].
    code genSend: pat argcount: argc super: s.
    ^ false
!

" Handle binary continuation "
doBinaryContinue: superFlag
    | msg s s2 |

    (s <- self doUnaryContinue: superFlag) isNil ifTrue: [ ^ nil ].
    [ token isKeySpecial ] whileTrue: [
	msg <- token value.
	token next.
	(self doUnaryContinue: self doTerm) isNil ifTrue: [ ^ nil ].
        code genSend: msg argcount: 1 super: s.
    ].
    ^ s
!

" Handle unary continuations. "
doUnaryContinue: superFlag
    | s |
 
    (s <- superFlag) isNil ifTrue: [ ^ nil ].
    [ token isKeyName ] whileTrue: [
        code genSend: (token value) argcount: 0 super: s.
	s <- false.
	token next.
    ].
    ^ s
!

" Parse a block of code. "
doBlock
    | savetemps argc saveInblock saveOptimBlk block args |
    " savetemps <- tempcount. "
    argc <- 0.
    args <- OrderedCollection new.
    saveInblock <- inBlock.
    saveOptimBlk <- optimBlk.

    token next.
    [ token isKeyVariable ] whileTrue: [
	args add: (self addTemp).
	argc <- argc + 1.
    ].

    token isVarSep ifTrue: [
	argc = 0 ifTrue: [ self parseError: 'No arguments defined.'. ^nil ].
	token next.
    ] ifFalse: [
	argc > 0 ifTrue: [ self parseError: 'Need var seperator'. ^nil ]
    ].

    " Jump forward to end of block. "
    block <- code genBlockCopy: argc.

   " Store arguments from stack into temps. "
    args reverseDo: [ :a | code genStore: a ].

    " Do body of block "
    inBlock <- true.
    optimBlk <- false.
    self doBody ifFalse: [ ^ false ].
    inBlock <- saveInblock.
    optimBlk <- saveOptimBlk.

    token isKeyRBrack ifFalse:
		 [ self parseError: 'Block must end with ]'. ^nil ].
    code genReturnBlock.
    code setJumpTarget: block advance: 0.
    " Clean out symbols defined after offset. "
    args do: [ :a | self removeSym: a ].
    token next.
    ^ false
!

" Compile a optimized block. "
optimBlock
    | saveInblock saveOptimBlk |
    saveInblock <- inBlock.
    saveOptimBlk <- optimBlk.

   " Make sure we start with a block "
    token next isKeyLBrack ifFalse: [ ^ self parseError: 'Error missing ['. ].
    token next.

   " Do body of block "
    inBlock <- true.
    optimBlk <- true.
    self doBody ifFalse: [ ^false ].
    inBlock <- saveInblock.
    optimBlk <- saveOptimBlk.

    token isKeyRBrack ifFalse: [ ^ self parseError: 'Block must end with ]'. ].
    token next.

    ^ true
!

" Compile ifTrue: or ifFalse: as a built in. "
doIfCond: key
    | block cond else adv |

    adv <- 2.
    key = 'ifTrue:' ifTrue: [ cond <- false. else <- 'ifFalse:' ]
		    ifFalse: [ cond <- true. else <- 'ifTrue:' ].
    block <- code genJumpCond: cond.    " Jump forward to end of block. "
    self optimBlock ifFalse: [ ^ false ].

    token isKeyKeyword and: [ token value = else ] ifTrue: [
	code setJumpTarget: block advance: 2.
	block <- code genJumpForw.	" Skip around else block "
	self optimBlock ifFalse: [ ^ false ].	" Do else part "
	adv <- 1.
    ] . 
    code setJumpTarget: block advance: adv.
    ^ true

!

" Compile whileTrue: and whileFalse: as built in. "
doWhile: aBoolean
    | loop block |
    code genDupTOS.
    loop <- code getCodeLabel.
    code genSend: 'value' argcount: 0 super: false.
    block <- code genJumpCond: aBoolean.  " Jump forward to end of block. "
    self optimBlock ifFalse: [ ^ false ]." Block body "
    code genPopTOS.			" Remove results of block. "
    code genJump: loop.			" Jump to start of block "
    code setJumpTarget: block advance: 2.
    ^ true
!

"  Compile and: and or: as a built in.
 
   expression
   DupTOS
   JF          L1
   PopTOS
   block
  L1:
"   
doAndOr: key
   | block kword |
    [ token isKeyKeyword and: [key = 'and:' or: [ key = 'or:' ]]] whileTrue: [
        code genDupTOS.
 	" Jump forward to end of block. "
        block <- code genJumpCond: (key = 'or:').
        code genPopTOS.
        self optimBlock ifFalse: [ ^ false ].
        code setJumpTarget: block advance: 1.
     ].
     " Keep grabing if we got another builtin "
     token isKeyKeyword ifTrue: [
         kword <- token value.
         kword = 'ifTrue:' or: [ kword = 'ifFalse:' ]  ifTrue:
	     [ ^ self doIfCond: kword ]
     ].
    ^ true
! !

SmallTalkToken initialize !

! CompiledMethod methodsFor: 'Printing' !

printOn: aStream
	| lits byte done basic op opr len temp |
	lits <- self literals.
	done <- self bytecodes.
	aStream nextPutAll: 'Flags '.
	(self flags) printOn: aStream.
	aStream nextPutAll: ' Args '.
	(self argcount) printOn: aStream.
	aStream nextPutAll: ' Lits '.
	lits printOn: aStream.
	aStream nextPutAll: ' Stack '.
	(self stacksize) printOn: aStream.
	aStream nextPutAll: ' Temps '.
	(self temporaries) printOn: aStream.
	aStream nextPutAll: ' Bytes '.
	done printOn: aStream.
        self flags = 16rF ifTrue: [ 
		aStream nextPutAll: ' Primitive '.
		(self primitiveOf) printOn: aStream.
	     ].
	aStream nl.
	1 to: lits do: [ :i |
		aStream nextPutAll: ' Lit '.
		(i - 1) printOn: aStream.
		aStream nextPutAll: ': #'.
		(self objectAt: (i + 1)) printOn: aStream.
		aStream nl.
	].
	basic <- #( jmpl psharg pshlit pshinst pshtmp stinst strtmp
		    rettmp jmpt jmpf jmp sndspc sndspc2 sndsup sndlit blk
		    retself rettos rettrue retfalse retnil retblk dup pop
		    pshvar stvar pshself pshnil pshtrue pshfalse pshone pshzero).
	byte <- 1.
	[ byte <= done ] whileTrue: [
		op <- self byteAt: byte.
		opr <- op bitAnd: 16rF.
		len <- 1.
		op <- op bitShift: -4.
		op = 0 ifTrue: [
			opr = 0 ifTrue: [
			    len <- 3.
			    byte + len > done
				ifTrue: [ opr <- 0 ]
			        ifFalse: [opr <- self byteAt: (byte + 1).
			            opr <- opr + (self byteAt: (byte + 2)).
			            opr > 32768 ifTrue: [ opr <- opr - 65536 ].
			    ]
			] ifFalse: [
			    op <- opr.
			    opr <- self byteAt: (byte + 1).
			    len <- 2.
			]
		] ifFalse: [
			" Check if group 2 "
			op = 16rF ifTrue: [
				op <- opr + 16.
				opr <- nil.
				" Variable operate inst "
				op = 24 or: [op = 25 ] ifTrue: [
			    		opr <- self byteAt: (byte + 1).
			    		len <- 2.
				].
			].
		].
		" Check if send special "
		op = 12 ifTrue: [ op <- op - 1. opr <- opr + 16. ].
		op = 11 ifTrue: [
			temp <- Smalltalk at: #SpecialSelectors
					 ifAbsent: [ Array new: 0 ].
			temp size <= opr ifFalse: [
				temp <- temp at: (opr + 1).
				opr <- '#' , temp asString.
				opr <- opr asSymbol ].
		].
		" Convert jump argument to bytecode index "
		op = 8 or: [ op = 9 or: [ op = 10 ]] ifTrue: [
			opr > 127 ifTrue: [ opr <- opr - 256 ]].
		op = 0 or: [op = 8 or: [ op = 9 or: [ op = 10 ]]] ifTrue: [
			opr <- byte + len + opr ].
		aStream nextPutAll: ' Byte '.
		byte printOn: aStream.
		aStream nextPutAll: ':  '.
		(basic at: (op + 1)) printOn: aStream.
		opr notNil ifTrue: [
		    aStream nextPutAll: '  '.
		    opr printOn: aStream.
		    " Handle sends "
		    op = 11 or: [ op = 13 or: [ op = 14]] ifTrue: [
			aStream nextPut: $(.
			(self byteAt: (byte + len)) printOn: aStream.
			aStream nextPut: $).
			len <- len + 1.
		    ].
		].
		aStream nl.
		byte <- byte + len.
	]
! !

