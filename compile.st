" Methods for Class stream and all it's subclasses"

" $Id: $ "

"
 $Log: $

"

Object subclass: 'SmallTalkToken'
       instanceVariableNames: 'token stream value pushback'
       classVariableNames: 'chartable' poolDictionaries: '' category: nil !

! SmallTalkToken class methodsFor: 'creation'!

on: aStream
	^ super new initOn: aStream.
! !

! SmallTalkToken class methodsFor: 'Definitions' !

KeyEOS
	^ 0
!

KeyLiteral
	^ 1
!

KeyName
	^ 2
!

KeyKeyword
	^ 3
!

KeyAssign
	^ 4
!

KeyRParen
	^ 5
!

KeyLParen
	^ 6
!

KeyReturn
	^ 7
!

KeyCascade
	^ 8
!

KeyPeriod
	^ 9
!

KeySpecial
	^ 10
!

KeyRBrack
	^ 11
!

KeyLBrack
	^ 12
!

KeyVariable
	^ 13
!

KeyUnknown
	^ 14

! !
! SmallTalkToken methodsFor: 'testing'!

isKeyEOS
	^ SmallTalkToken KeyEOS = token
!

isKeyLiteral
	^ SmallTalkToken KeyLiteral = token
!

isKeyName
	^ SmallTalkToken KeyName = token
!

isKeyKeyword
	^ SmallTalkToken KeyKeyword = token
!

isKeyAssign
	^ SmallTalkToken KeyAssign = token
!

isKeyRParen
	^ SmallTalkToken KeyRParen = token
!

isKeyLParen
	^ SmallTalkToken KeyLParen = token
!

isKeyReturn
	^ SmallTalkToken KeyReturn = token
!

isKeyCascade
	^ SmallTalkToken KeyCascade = token
!

isKeyPeriod
	^ SmallTalkToken KeyPeriod = token
!

isKeySpecial
	^ SmallTalkToken KeySpecial = token
!

isKeyRBrack
	^ SmallTalkToken KeyRBrack = token
!

isKeyLBrack
	^ SmallTalkToken KeyLBrack = token
!

isKeyVariable
	^ SmallTalkToken KeyVariable = token
!

isKeyUnknown
	^ SmallTalkToken KeyUnknown = token
!

" Determine if next token is a variable seperator. "
isVarSep
    ^ SmallTalkToken KeySpecial = token and: [ value = '|' ].
! !

! SmallTalkToken methodsFor: 'Initialize' !

" Set up array of characters to speed up parsing "
initOn: aString
	stream <- ReadStream on: aString.
	token <- SmallTalkToken KeyUnknown.
	pushback <- nil.
! !

! SmallTalkToken class methodsFor: 'Initialize' !

initialize
	| tok table |
	table <- Array new: 128.
        table at: (Character space asciiValue) put: -2.
        table at: (Character tab asciiValue) put: -2.
        table at: (Character cr asciiValue) put: -2.
        table at: (Character nl asciiValue) put: -2.
        table at: ($( asciiValue) put: (SmallTalkToken KeyRParen ).
        table at: ($) asciiValue) put: (SmallTalkToken KeyLParen ).
        table at: ($; asciiValue) put: (SmallTalkToken KeyCascade ).
        table at: ($. asciiValue) put: (SmallTalkToken KeyPeriod ).
        table at: ($^ asciiValue) put: (SmallTalkToken KeyReturn ).
        table at: ($[ asciiValue) put: (SmallTalkToken KeyLBrack ).
        table at: ($] asciiValue) put: (SmallTalkToken KeyRBrack ).
        table at: ($^ asciiValue) put: (SmallTalkToken KeyReturn ).
	table at: ($< asciiValue) put: -7.
	table at: ($- asciiValue) put: -6.
	table at: ($+ asciiValue) put: (SmallTalkToken KeySpecial ).
	table at: ($/ asciiValue) put: (SmallTalkToken KeySpecial ).
	table at: ($\ asciiValue) put: (SmallTalkToken KeySpecial ).
	table at: ($* asciiValue) put: (SmallTalkToken KeySpecial ).
	table at: ($~ asciiValue) put: (SmallTalkToken KeySpecial ).
	table at: ($> asciiValue) put: (SmallTalkToken KeySpecial ).
	table at: ($= asciiValue) put: (SmallTalkToken KeySpecial ).
	table at: ($@ asciiValue) put: (SmallTalkToken KeySpecial ).
	table at: ($% asciiValue) put: (SmallTalkToken KeySpecial ).
	table at: ($? asciiValue) put: (SmallTalkToken KeySpecial ).
	table at: ($!! asciiValue) put: (SmallTalkToken KeySpecial ).
	table at: ($& asciiValue) put: (SmallTalkToken KeySpecial ).
	table at: ($| asciiValue) put: (SmallTalkToken KeySpecial ).
        table at: ($, asciiValue) put: (SmallTalkToken KeySpecial ).
	table at: ($# asciiValue) put: (SmallTalkToken KeyLiteral ).
	table at: ($$ asciiValue) put: -4.
	table at: ($: asciiValue) put: (SmallTalkToken KeyVariable ).
	table at: ($' asciiValue) put: -5.
	$0 asciiValue to: ($9 asciiValue) do: 
		[ :i | table at: i put:  -3].
	tok <- SmallTalkToken KeyName.
	$a asciiValue to: ($z asciiValue) do: 
		[ :i | table at: i put:  tok].
	$A asciiValue to: ($Z asciiValue) do: 
		[ :i | table at: i put:  tok].
	table at: ($"  asciiValue) put: -1.
	chartable <- table.
! !

SmallTalkToken initialize !

! SmallTalkToken methodsFor: 'private' !

" Read next char off stream. "
nextchar
	| char |
	pushback isNil ifFalse: [
		char <- pushback.
		pushback <- nil.
		^ char
	].
	stream atEnd ifTrue: [ ^ 0 asCharacter ].
	^ stream next
!

" Put character away to read again. "
pushback: aChar
	pushback <- aChar.
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

skipComment
	| char |
	[ (char <- self nextchar) isNil ] whileFalse: [ 
		char = $" ifTrue: [
			self peeknext = $" ifFalse: [ ^self].
			self nextchar.
	        ].
	]
!

" Convert a ordered collection into a fixed size array "
makeArray: aCollection
	| array index |
	array <- Array new: (aCollection size).
	index <- 1.
	aCollection do: [ :v | array at: index put: v.
				index <- index + 1 ].
	^ array
!
	
" Scan an array and return a literal token "
scanarray
     | char array |
     token <- SmallTalkToken KeyLiteral.
     array <- OrderedCollection new.
     [ char <- self nextchar.  char isNil ] whileFalse: [
	char = $" ifTrue: [ self skipComment ]
	          ifFalse: [
	   char = $( ifTrue: [ self scanarray ifFalse: [ ^false ]]
	             ifFalse: [ 
	     char = $- or: [ char isDigit ] ifTrue: [ self scannumber: char ]
	             ifFalse: [
	       char = $# ifTrue: [ self scanliteral ]
	                 ifFalse: [
		 char = $$ ifTrue: [ value <- self nextchar. ]
		         ifFalse: [ 
		    char = $' ifTrue: [ self scanstring ]
		              ifFalse: [
		      char = $) ifTrue: [ value <- self makeArray: array. 
					^ true ]
	                        ifFalse: [
			char isLetter ifTrue: [ self pushback: char.
						self scanliteral]
				       ifFalse: [ ^false ]
			]
		    ]
		 ]
	       ]
             ]
	   ]
	 ].
	array add: value.
     ].
     ^ false
!

scannumber: aChar
   | base integer fraction sign exp char multi eseen fseen dig done|
   token <- SmallTalkToken KeyLiteral.
   char <- aChar.
   sign <- false.
   integer <- 0.
   fraction <- 0.0.
   base <- 10.
   exp <- 0.
   eseen <- false.
   fseen <- false.
   char = $- ifTrue: [ sign <- true. char <- self nextchar ].
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
			   ]
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
    self pushback: char.

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
    
    self peeknext isLetter ifFalse: [
	 token <- SmallTalkToken KeyUnknown. 
	^ false ].
    char <- self nextchar.
    value <- ''.
    [ char isAlphaNumeric ] whileTrue: [ 
	value <- value , (char asString).
	char <- self nextchar ].
    self pushback: char.
    token <- SmallTalkToken KeyName.
    ^ true
!

" Scan a string and return a string object. "
scanstring
    | char done |
    done <- true.
    token <- SmallTalkToken KeyLiteral.
    [ done ] whileTrue: [
	char <- self nextchar.
	char = $' ifTrue: [
		self peeknext = $' ifTrue: [
			 char <- self nextchar. 
			 value <- value , (char asString) ]
				   ifFalse: [ done <- false ]]
	          ifFalse: [ value <- value , (char asString) ].
    ]
!

" Scan a literal, either a array or a symbol. "
scanliteral
     | char done |
     token <- SmallTalkToken KeyLiteral.
     char <- self nextchar.
     " Check if array "
     char = $( ifTrue: [ ^ self scanarray ].
     char isLetter ifTrue: [
    		[ char isAlphaNumeric or: [ char = $: ]]
			 whileTrue: [
				 value <- value , (char asString).
				 char <- self nextchar ].
		value <- value asSymbol.
		^ true ].
     char = $- ifTrue: [ value <- #-. ^true ].
     (self isSpecial: char) ifTrue: [
		value <- char asString.
		(self isSpecial: self peeknext) ifTrue: [
		    value <- value , (self nextchar asString).
		].
		value <- value asSymbol.
		^true.
	].
     token <- SmallTalkToken KeyUnknown.
     ^false
! !

! SmallTalkToken methodsFor: 'accessing' !

" Return the value of the token. "
value
    ^ value
!

" Return the next token from input stream. "
next
    | char |

    [ char <- self nextchar. 0 asCharacter ~= char ] whileTrue: [
	token <- chartable at: (char asciiValue).
	token isNil ifTrue: [ token <- SmallTalkToken KeyUnknown. ^ self ].
	token = -1 ifTrue: [ self skipcomment ].
	token = -2 ifTrue: [ " do nothing " ].
        token = -3 ifTrue: [ self scannumber: char. ^ self ].
	self isKeyLiteral ifTrue: [ self scanliteral. ^ self ].
	token = -4 ifTrue: [ value <- self nextchar.
			     token <- SmallTalkToken KeyLiteral.
			     ^ self ].
	token = -5 ifTrue: [ self scanstring. ^ self ].
	self isKeyName ifTrue: [ 
			self pushback: char.
			self scanname and: [ self peeknext = $: ] ifTrue: [
				char <- self nextchar.
				value <- value , ':'.
				token <- SmallTalkToken KeyKeyword.
			  ].
			^ self ].
	self isKeyVariable ifTrue: [
			self scanname ifFalse: [
				value <- ':'.
				token <- SmallTalkToken KeyUnknown.
				].
			^self ].
  	token = -6 ifTrue: [
			self peeknext isDigit ifTrue: [ self scannumber: char ]
			       ifFalse: [
				 token <- SmallTalkToken KeySpecial.
				 value <- '-' ].
			^ self
			].
        token = -7 ifTrue: [
			value <- char asString.
			char <- self nextchar.
			char = $- ifTrue: [ 
				token <- SmallTalkToken KeyAssign.
				^ self ].
			(self isSpecial: char)
			   ifTrue: [ value <- value , (char asString). ]
			   ifFalse: [ self pushback: char ].
			token <- SmallTalkToken KeySpecial.
			^ self ].
	self isKeySpecial ifTrue: [
			value <- char asString.
			(self isSpecial: self peeknext)
			  ifTrue: [ value <- value , (self nextchar asString) ].
			^ self ].
	token >= 0 ifTrue: [ ^self ]
    ].
    token <- SmallTalkToken KeyEOS.
    ^ self
! !

Object subclass: 'SmallTalkSymbol'
       instanceVariableNames: 'name type offset deleted'
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkSymbol class methodsFor: 'creation' ! 

new: aName type: aType
     ^ self new; name: aName type: aType offset: 0
!

new: aName type: aType offset: aOffset
     ^ self new; name: aName type: aType offset: aOffset
!
nilNode
     ^ self new; setnil 
!

stackNode
     ^ self new; setstack 
!

labelNode 
     ^ self new; setlabel
! !

! SmallTalkSymbol class methodsFor: 'Definitions' !

SymbolSelf
	^ 0
!

SymbolSuper
	^ 1
!

SymbolTrue
	^ 2
!

SymbolFalse
	^ 3
!

SymbolNil
	^ 4
!

SymbolArg
	^ 5
!

SymbolTemp
	^ 6
!

SymbolInst
	^ 7
!

SymbolVar
	^ 8
!

SymbolLiteral
	^ 9
!

SymbolStack
	^ 10
!

SymbolLabel
	^ 11
! !

! SmallTalkSymbol methodsFor: 'testing'!

isSymbolSelf
	^ SmallTalkSymbol SymbolSelf = type
!

isSymbolSuper
	^ SmallTalkSymbol SymbolSuper = type
!

isSymbolTrue
	^ SmallTalkSymbol SymbolTrue = type
!

isSymbolFalse
	^ SmallTalkSymbol SymbolFalse = type
!

isSymbolNil
	^ SmallTalkSymbol SymbolNil = type
!

isSymbolArg
	^ SmallTalkSymbol SymbolArg = type
!

isSymbolTemp
	^ SmallTalkSymbol SymbolTemp = type
!

isSymbolInst
	^ SmallTalkSymbol SymbolInst = type
!

isSymbolVar
	^ SmallTalkSymbol SymbolVar = type
!

isSymbolLiteral
	^ SmallTalkSymbol SymbolLiteral = type
!

isSymbolStack
	^ SmallTalkSymbol SymbolStack = type
!

isSymbolLabel
	^ SmallTalkSymbol SymbolLabel = type
!

isDeleted
	^ deleted
!

isActive
	^ deleted not
! !

! SmallTalkSymbol methodsFor: 'creation' !

name: aName type: aType offset: aOffset
	name <- aName.
	type <- aType.
	offset <- aOffset.
	deleted <- false.
!

setnil
	name <- 'Nil'.
	type <- SmallTalkSymbol SymbolNil.
	offset <- 0.
	deleted <- false.
!

setstack
	name <- 'Stack'.
	type <- SmallTalkSymbol SymbolStack.
	offset <- 0.
	deleted <- false.
!

setlabel
	name <- 'Label'.
	type <- SmallTalkSymbol SymbolLabel.
	offset <- 0.
	deleted <- false.
! !

! SmallTalkSymbol methodsFor: 'accessing' !

name
	^ name
!

type
	^ type
!

offset
	^ offset
!

deleted
	^ deleted
!
= aSymbol
	^ aSymbol name = name and: [ aSymbol type = type and: 
		[ aSymbol offset = offset ]]
!

" Do nothing, so Literal and symbols work same"
release
	^ nil

! !

! SmallTalkSymbol methodsFor: 'modifing' !

offset: aOffset
	^ offset <- aOffset
!

delete
	^ deleted <- true
!

" Delete if temporary and over offset. "
delete: aOffset
	self isSymbolTemp and: [ offset >= aOffset]
		 ifTrue: [ deleted <- true ]
! !

Object subclass: 'SmallTalkLiteral'
       instanceVariableNames: 'value offset usage'
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
	^  false
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
	^ true
!

isSymbolStack
	^ false
!

isSymbolLabel
	^ false
! !

! SmallTalkLiteral methodsFor: 'accessing' !

value
	^ value
!

offset
	^ offset
!

usage
	^ usage

! !

! SmallTalkLiteral methodsFor: 'modifing' !

offset: aOffset
	^ offset <- aOffset
!

used
	^ usage <- usage + 1
!

release
	^ usage <- usage - 1
!

= aLiteral
	^ self == aLiteral
! !


Object subclass: 'SmallTalkCodeNode'
       instanceVariableNames: 'next oper length offset refer argcount value'
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkCodeNode class methodsFor: 'creation'!

new: oper
	^ self new oper: oper value: (SmallTalkSymbol nilNode)
!
new: oper value: value 
	^ self new oper: oper value: value
! !

! SmallTalkCodeNode class methodsFor: 'Definitions' !

CodePush
	^ 0
!

CodeStore
	^ 1
!

CodeReturn
	^ 2
!

CodeSend
	^ 3
!

CodeJump
	^ 4
!

CodeJTrue
	^ 5
!

CodeJFalse
	^ 6
!

CodeBlockCopy
	^ 7
!

CodeDuplicate
	^ 8
!

CodePopStack
	^ 9
!

CodeSendSuper
	^ 10
!

CodeBlock
	^ 11
!

CodeSendSpec
	^ 12
!

CodeBreak
	^ 13
!

CodeNop
	^ 14
!

CodeBlockReturn
	^ 15
! !

! SmallTalkCodeNode methodsFor: 'testing'!

isCodePush
	^ SmallTalkCodeNode CodePush = oper
!

isCodeStore
	^ SmallTalkCodeNode CodeStore = oper
!

isCodeReturn
	^ SmallTalkCodeNode CodeReturn = oper
!

isCodeSend
	^ SmallTalkCodeNode CodeSend = oper
!

isCodeJump
	^ SmallTalkCodeNode CodeJump = oper
!

isCodeJTrue
	^ SmallTalkCodeNode CodeJTrue = oper
!

isCodeJFalse
	^ SmallTalkCodeNode CodeJFalse = oper
!

isCodeBlockCopy
	^ SmallTalkCodeNode CodeBlockCopy = oper
!

isCodeDuplicate
	^ SmallTalkCodeNode CodeDuplicate = oper
!

isCodePopStack
	^ SmallTalkCodeNode CodePopStack = oper
!

isCodeSendSuper
	^ SmallTalkCodeNode CodeSendSuper = oper
!

isCodeBlock
	^ SmallTalkCodeNode CodeBlock = oper
!

isCodeSendSpec
	^ SmallTalkCodeNode CodeSendSpec = oper
!

isCodeBreak
	^ SmallTalkCodeNode CodeBreak = oper
!

isCodeNop
	^ SmallTalkCodeNode CodeNop = oper
!

isCodeBlockReturn
	^ SmallTalkCodeNode CodeBlockReturn = oper
! !

! SmallTalkCodeNode methodsFor: 'accessing' !
oper: aOper
	^ oper <- aOper
!

oper: aOper value: aValue
	next <- nil.
	oper <- aOper.
	value notNil ifTrue: [
		self isCodeBlock ifFalse: [ value release ]].
	value <- aValue.
	offset <- 0.
	argcount <- 0.
	refer <- false.
	length <- 0.
	^ self
!

= aNode
	aNode isLabel ifTrue: [ ^ false ].
	^ aNode oper == oper and: [ aNode value == value ]
!
	
oper
	^ oper
!

offset: aOffset
	^ offset <- aOffset
!

offset
	^ offset
!

argcount: aCount
	^ argcount <- aCount
!

argcount
	^ argcount
!

length: size
	^ length <- size
!

length
	^ length
!

value: aValue
	value notNil ifTrue: [
		self isCodeBlock ifFalse: [ value release ]].
	^ value <- aValue
!

value
	^value
!

label
	refer <- true.
!

unlabel
	refer <- false.
! 

isLabel
	^ refer 
!

next
	^ next
!

next: aLink
	^ next <- aLink
!

release
	^ nil
!

size
    | len i |
    len <- length.
    value isNil ifTrue: [ ^ len ].
    i <- (offset + len).
    self isCodeJFalse or: [ self isCodeJTrue ] ifTrue: [
	i <- (value offset) - i.
	i between: 0 and: 16 ifTrue: [ ^ 1 ].
        i between: -127 and: 128 ifTrue: [ ^ 2 ].
	^ 4.
    ].
    self isCodeJump ifTrue: [
	i <- (value offset) - i.
	i between: 0 and: 16 ifTrue: [ ^ 1 ].
        i between: -127 and: 128 ifTrue: [ ^ 2].
        ^ 3.
    ].
    self isCodeBlockCopy ifTrue: [
	i <- (value offset) - i.
	i between: 0 and: 16 ifTrue: [ ^ 3 ].
        i between: -127 and: 128 ifTrue: [ ^ 5].
	^ 4.
    ].
    ^ len
!
	

" Check node is begining of block "
beginBlock
    self next notNil and: [self next isLabel] ifTrue: [ ^ true ]
	ifFalse: [ ^ false ].
! !

! SmallTalkCodeNode methodsFor: 'enumeration' !

do: aBlock
    | aLink |
    aLink <- self.
    [ aLink notNil] whileTrue: [
	aBlock value: aLink.
	aLink <- aLink next.
    ]
! !

! SmallTalkCodeNode methodsFor: 'generation' !
generateSend: opcode 
    | i opc opr len |
    opr <- value offset.
    opr > 17 ifTrue: [ opc <- opcode / 16. len <- 3 ]
            ifFalse: [ opc <- opcode + opr.  len <- 2. ].
    value <- ByteArray new: len.
    value at: 1 put: opc.
    i <- 2.
    len > 2 ifTrue: [ value at: 2 put: opr. i <- 3].
    value at: i put: argcount.
    length <- len.
    oper <- (SmallTalkCodeNode CodeBlock).
!

generateOpr: opcode
    | len opc opr|
    opr <- value offset.
    opr < 17 ifTrue: [ opc <- opcode + opr. len <- 1 ]
	     ifFalse: [ opc <- opcode / 16. len <- 2 ].
    value <- ByteArray new: len.
    value at: 1 put: opc.
    len > 1 ifTrue: [ value at: 2 put: opr ].
    length <- len.
    oper <- (SmallTalkCodeNode CodeBlock).
!

generateTwo: opcode operand: opr 
    value <- ByteArray new: 2.
    value at: 1 put: opcode.
    value at: 2 put: opr.
    length <- 2.
    oper <- (SmallTalkCodeNode CodeBlock).
!

generateJump: opcode operand: opr len: len extra: opt
    | i l |
    value unlabel.
    value <- ByteArray new: len.
    length <- len.
    l <- len.
    value at: 1 put: opcode.
    i <- 2.
   " Handle block copy "
    opcode = 16r0F ifTrue: [
	value at: i put: argcount.
	i <- i + 1.
	l <- l - 2.
    ].

   " Put out optional word "
    value at: i put: opt.
    i <- i + 1.
   " Put out rest of jump "
    l > 1 ifTrue: [ value at: i put: opr. i <- i + 1 ].
    l > 2 ifTrue: [ value at: i put: (opr / 256). i <- i + 1].
    oper <- (SmallTalkCodeNode CodeBlock).
!

generate: opcode
    value <- ByteArray new: 1.
    value at: 1 put: opcode.
    length <- 1.
    oper <- (SmallTalkCodeNode CodeBlock).
!
	
" Compile a node into binary from "
generate
	self isCodeStore ifTrue: [
	    value isSymbolTemp ifTrue: [ ^ self generateOpr: 16r60 ].
	    value isSymbolVar ifTrue: [ 
		^ self generateTwo: 16rF9 operand: (value offset offset) ].
	    ^ self generateOpr: 16r50
	].
	self isCodePush ifTrue: [
	    value isSymbolSelf ifTrue: [ ^self generate: 16rFA ].
	    value isSymbolNil ifTrue: [ ^self generate: 16rFB ].
	    value isSymbolTrue ifTrue: [ ^self generate: 16rFC ].
	    value isSymbolFalse ifTrue: [ ^self generate: 16rFD ].
	    value isSymbolTemp ifTrue: [ ^self generateOpr: 16r40 ].
	    value isSymbolInst ifTrue: [ ^self generateOpr: 16r30 ].
	    value isSymbolArg ifTrue: [ ^self generateOpr: 16r10 ].
	    value isSymbolLiteral ifTrue: [
		value value = 0 ifTrue: [ ^ self generate: 16rFE ].
		value value = 1 ifTrue: [ ^ self generate: 16rFF ].
		^ self generateOpr: 16r20
	    ].
	    value isSymbolVar ifTrue: [
		  ^ self generateTwo: 16rF8 operand: (value offset offset) ].
	].
	self isCodeDuplicate ifTrue: [ ^ self generate: 16rF6 ].
	self isCodePopStack ifTrue: [ ^ self generate: 16rF7 ].
	self isCodeBreak ifTrue: [ ^ self generate: 16rA0 ].
	self isCodeReturn ifTrue: [
	    value isSymbolSelf ifTrue: [ ^ self generate: 16rF0 ].
	    value isSymbolNil ifTrue: [ ^ self generate:  16rF4 ].
	    value isSymbolTrue ifTrue: [ ^ self generate: 16rF2 ].
	    value isSymbolFalse ifTrue: [ ^ self generate: 16rF3 ].
	    value isSymbolTemp ifTrue: [ ^ self generateOpr: 16r70 ].
	    value isSymbolStack ifTrue: [ ^ self generate: 16rF1 ].
        ].
	self isCodeBlockReturn ifTrue: [ ^ self generate: 16rF5 ].
	self isCodeSendSuper ifTrue: [
	    ^ self generateSend: 16rD0 ].
	self isCodeSend ifTrue: [
	    ^ self generateSend: 16rE0 ].
	self isCodeSendSpec ifTrue: [
 	    ^ self generateTwo: (16rB0 + value) operand: argcount.  ].
	self isCodeJump or: [self isCodeJFalse or: [self isCodeJTrue ]] ifTrue:
		[ length <- 1 ].
	self isCodeBlockCopy ifTrue: [  length <- 3 ].
!

" Compile a jump code into bytecodes "
generateJump
	| len operand opt |
	len <- length.
	self isCodeJTrue ifTrue: [
	        operand <- (value offset) - (self offset + len).
		len = 1 ifTrue: [ ^ self generate: (16r80 + operand) ].
		len = 4 ifTrue: [
	          ^ self generateJump: 16r93 operand: operand len: len opt: 0 ].
		^ self generateTwo: 16r08 operand: operand.
	].
	self isCodeJFalse ifTrue: [
	        operand <- (value offset) - (self offset + len).
		len = 1 ifTrue: [ ^ self generate: (16r90 + operand) ].
  	        len = 4 ifTrue: [ 
	          ^ self generateJump: 16r83 operand: operand len: len opt: 0 ].
		^ self generateTwo: 16r09 operand: operand.
	].
	self isCodeJump ifTrue: [
	        operand <- (value offset) - (self offset + len).
		len = 1 ifTrue: [ ^ self generate: (16rA0 + operand) ].
		len = 3 ifTrue: [ 
		      ^ self generateJump: 0 operand: operand len: len opt: 0 ].
		^ self generateTwo: 16r0A operand: operand.
	].
	self isCodeBlockCopy ifTrue: [
	        operand <- (value offset) - (self offset + len).
		len = 3 ifTrue: [ opt <- 16rA0 + operand ]
			ifFalse: [
		len = 5 ifTrue: [ opt <- 0. ]
		        ifFalse: [ opt <- 16r0A ]].
	        ^ self generateJump: 16r0F operand: operand len: len opt: opt
	].
! !

Object subclass: 'SmallTalkCodeTree'
       instanceVariableNames: 'list lastnode maxstack curstack'
       classVariableNames: '' poolDictionaries: '' category: nil !

! SmallTalkCodeTree class methodsFor: 'creation'!

new
	^ self basicNew init
! !

! SmallTalkCodeTree methodsFor: 'Initializing' !

init
	list <- nil.
	lastnode <- nil.
	maxstack <- 0.
	curstack <- 0.

! !

! SmallTalkCodeTree methodsFor: 'Generation' !

" Create a new code block node. "
genCode: aOper stack: amount
	^ self genCode: aOper stack: amount value: (SmallTalkSymbol nilNode).
!

" Create a new code block node. "
genCode: aOper stack: amount value: aValue
	| code |
	code <- SmallTalkCodeNode new: aOper value: aValue.
	list isNil ifTrue: [ list <- code. ]
		   ifFalse: [ lastnode next: code. ].
	lastnode <- code.
	curstack > maxstack ifTrue: [ maxstack <- curstack ].
	curstack <- curstack + amount.
	^ code
!

" Generate Empty location "
genNop
	^ self genCode: SmallTalkCodeNode CodeNop stack: 0
!

" Generate push nil opcode.  "
genPushNil
	^ self genCode: (SmallTalkCodeNode CodePush) 
	         stack: 1
!

" Generate return nil opcode.  "
genReturnNil
	 self genCode: (SmallTalkCodeNode CodeReturn)
	        stack: 0
!

" Generate return Top of stack opcode. "
genReturnTOS
	 ^ self genCode: (SmallTalkCodeNode CodeReturn)
	   stack: 0
	   value: (SmallTalkSymbol stackNode)
!

" Generate return Top of stack opcode. "
genReturnBlock
	 ^ self genCode: (SmallTalkCodeNode CodeBlockReturn)
	   stack: 0.
!

genPopTOS
	 ^ self genCode: (SmallTalkCodeNode CodePopStack) stack: -1
!

genDupTOS
	 ^ self genCode: (SmallTalkCodeNode CodeDuplicate) stack: 1
!

genJumpForw
	 ^ self genCode: (SmallTalkCodeNode CodeJump)
	   stack: 0
           value: (SmallTalkSymbol labelNode)
!

genJumpFForw
	 ^ self genCode: (SmallTalkCodeNode CodeJFalse)
	   stack: -1
	   value: (SmallTalkSymbol labelNode)
!

genJumpTForw
	 ^ self genCode: (SmallTalkCodeNode CodeJTrue)
	   stack: -1
	   value: (SmallTalkSymbol labelNode)
!

getCodeLabel
	^ lastnode
!

genStore: aSym
	 ^ self genCode: (SmallTalkCodeNode CodeStore) stack: -1 value: aSym
!

genPushLit: aLit
	 ^ self genCode: (SmallTalkCodeNode CodePush) stack: 1 value: aLit
!

genPush: aSym
	 ^ self genCode: (SmallTalkCodeNode CodePush) stack: 1 value: aSym
!

genSend: aLit argcount: count super: superFlag
	| node |
	superFlag ifTrue: [
	    node <- self genCode: (SmallTalkCodeNode CodeSendSuper)
	       stack: (count negated) 
	       value: aLit.
	] ifFalse: [
	    node <- self genCode: (SmallTalkCodeNode CodeSend)
	       stack: (count negated)
	       value: aLit.
	].
	node argcount: count.
	^ node
!

genBlockCopy: count
	| node |
	 node <- self genCode: (SmallTalkCodeNode CodeBlockCopy)
	       stack: 1
	       value: (SmallTalkSymbol labelNode).
	node argcount: count.
	(curstack + count) > maxstack ifTrue: [
		maxstack <- curstack + count ].
	^ node
!

genJump: aLabel
	| label |
	  label <- SmallTalkSymbol labelNode.
	  label argcount: 0.
	  label offset: aLabel.
	  aLabel label.
	 ^ self genCode: (SmallTalkCodeNode CodeJump) stack: 0 value: label
!

setJumpTarget: aLabel advance: amount
	aLabel notNil and: [ lastnode notNil ] ifTrue: [
		(aLabel value) offset: lastnode.
		aLabel isCodeBlockCopy ifFalse: [
		    aLabel argcount: amount
		]
	]
! !

! SmallTalkCodeTree methodsFor: 'Compiling' !

" Remove the next code node. "
removeNext: aNode
	| dead |
	dead <- aNode next.
	dead isNil ifFalse: [
	    dead value: nil. 
	    dead == lastnode ifTrue: [ lastnode <- aNode. ^ aNode next: nil ]
	                    ifFalse: [ ^aNode next: (dead next)].
	]
!

" Remove the next code node. "
removeCur: aNode
	| nxt cur |
	aNode isNil ifFalse: [
	    nxt <- aNode next.
	    aNode value: nil. 
	    aNode == list
		ifTrue: [ list <- nxt ]
 	        ifFalse: [
	            cur <- list.
	            [ cur notNil ] whileTrue: [
			cur next == aNode ifTrue: [
			    cur next: nxt.
			    lastnode == aNode ifTrue: [ lastnode <- cur ].
			].
			cur <- cur next.
		    ]
		].
	     cur <- list.
	     [ cur notNil ] whileTrue: [
		cur value isSymbolLabel and: [ cur value offset == aNode ]
		     ifTrue: [ (cur value) offset: nxt. nxt label ]].
	     ^ nxt
	].
	^ nil
!

" Combine blocks of code together into one huge block."
combineCode
    | nxt len newBlock base otherBlock |

   " Combine all code blocks into one bytearray. "
    len <- 0.
    list do: [ :cur | len <- len + (cur length) ].
    newBlock <- ByteArray new: len.
    base <- 0.
    list do: [ :cur |
	cur isCodeBlock ifTrue: [
	     otherBlock <- cur value.
	     1 to: (otherBlock size) do: [ :i |
		newBlock at: (i + base) put: (otherBlock at: i)].
	     base <- base + otherBlock size.
	]
    ].
   " Speed up freeing of block by unlinking list. "
    nxt <- list.
    [ nxt notNil ] whileTrue: [
	otherBlock <- nxt next.
	nxt next: nil.
	nxt <- otherBlock.
    ].

    list <- nil.
    ^ newBlock
!

" Fix jump targets to point to next instruction, also set referenced flag. "
fixjumps
    | nxt temp |
    list do: [ :cur |
	cur value isSymbolLabel ifTrue: [
	   temp <- cur value offset.
	   temp notNil and: [ temp next notNil ] ifTrue: [
		nxt <- temp next.
		cur isCodeBlockCopy not and: [cur argcount > 0 ] ifTrue: 
			[ nxt <- temp next. ].
		(cur value) offset: nxt.
		nxt label
	   ]
	]
     ].
!

peephole
    | superFlag i nxt temp temp1 |
" Preform optimization pass.
  1) Convert sends into sendSpecail if we can.
  2) Remove Dup/Pop pairs when second one is not referenced.
  3) Remove Push/Popstack pairs.
  4) Remove unreferenced code after a return.
  5) Remove unreferenced code after a jump.
  6) Release literals for push of 0 or 1.
  7) Convert Dup/Store/Pop into Store.
  8) Convert push special /return to return special.
 "
    superFlag <- false.
    list do: [ :node |
        nxt <- node next.
	node isCodePush ifTrue: [
	   " Remove unneded push/pop pairs "
	    node beginBlock and: [ nxt isPopStack ] ifTrue: [
		node <- self removeCur: node.
		node <- self removeCur: node.
		nxt <- node next.
	    ]
	].

	node isCodePush ifTrue: [
	    " Convert push x/ push x to push x/ dup "
	     node beginBlock and: [ node = nxt ]
		ifTrue: [ nxt oper: (SmallTalkCodeNode CodeDuplicate) 
				value: nil. ].
		
	   " Check if it could be a zero or a one. "
	    node value isSymbolLiteral ifTrue: [
		node value value = 0 or: [ node value value = 1 ]
		    ifTrue: [ node value release ].
		
	   " Check if we can shorten a return TOS "
	    node beginBlock and: [ nxt isCodeReturn and:
		 [ nxt value isSymbolStack ]]
		ifTrue: [
			temp <- node value.
			temp isSymbolSelf or: [ temp isSymbolTrue or: 
			    [ temp isSymbolFalse or: [ temp isSymbolNil or:
			        [ temp isSymbolTemp ]]]] ifTrue: [
			    nxt value: temp.
			    node <- self removeCur: node.
			    nxt <- node next.
			]
	          ]
	     ].

	     " Remove push bool, jcond "
	     node beginBlock and: [ nxt isCodeJTrue or: [ nxt isCodeJFalse]]
		ifTrue: [
		   node isSymbolTrue ifTrue: [
			nxt isCodeJTrue ifTrue: [
			    nxt oper: (SmallTalkCodeNode CodeJump) ]
				        ifFalse: [ self removeNext: node ].
			node <- self removeCur: node.
		   ] ifFalse: [
		      node isSymbolFalse ifTrue: [
			nxt isCodeJFalse ifTrue: [
			    nxt oper: (SmallTalkCodeNode CodeJump) ]
				        ifFalse: [ self removeNext: node ].
			node <- self removeCur: node.
		      ]
		   ]
	     ]
        ].

	node isCodeDuplicate ifTrue: [
	    " Remove dup before return "
	    node beginBlock and: [ nxt isCodeReturn ] ifTrue: [
		node <- self removeCur: node.
		nxt <- node next.
	    ].

	    " Remove dup/pop pairs "
	    node beginBlock and: [ nxt isCodePopStack ] ifTrue: [
		self removeNext: node.
	    ].

	    " Convert  Dup, Store x, Pop, Push x -> Dup, Store "
	    node beginBlock and: [ nxt isCodeStore  and: [
		nxt beginBlock and: [ nxt next isCodePopStack and: [
		nxt next beginBlock and: [ nxt next next isCodePush and: [
		   nxt next value = (nxt next next value)]]]]]] ifTrue: [
		self removeNext: nxt.
		self removeNext: nxt.
		nxt <- node next.
	    ].

       	    " Convert  Dup, Store, Pop -> Store "
	    node beginBlock and: [ nxt isCodeStore  and: [
		nxt beginBlock and: [ nxt next isCodePopStack ]]] ifTrue: [
		node <- self removeCur: node.
		self removeNext: node.
		nxt <- node next.
	    ]
        ].

	" Remove dead code after jump or return "
	node isCodeJump or: [ node isCodeReturn ] ifTrue: [
	    [ node beginBlock ] whileTrue:  [ self removeNext: node ].
	].

	" Save if we did a call to super "
	node isCodeSendSuper ifTrue: [ superFlag <- true ].

	" Check if we can replace send with send special "
        node isCodeSend ifTrue: [
	   " Scan for selector in specails. "
	   temp <- Smalltalk at: #SpecialSelectors ifAbsent: [ nil ].
	   temp notNil ifTrue: [
	       temp1 <- node value value.
	       i <- nil.
	       1 to: temp size do:
			 [ :sel | (temp at: sel) = temp1 ifTrue: [i <- sel]].
	       i notNil ifTrue: [
		    node oper: (SmallTalkCodeNode CodeSendSpec).
		    node value: (i - 1).
	      ]
	   ]
	].
    ].
    ^ superFlag
!

" relabel jump targets "
relabel
    | nxt temp |
    list do: [ :cur | cur unlabel ].
    list do: [ :cur |
	cur value isSymbolLabel ifTrue: [ cur value offset label ]].
! 

" Optimize jump instructions. "
optimizeJump
    | superFlag i nxt temp temp1 valuenum changed |

  " Find index of value selector "
   valuenum <- -1.
   temp <- Smalltalk at: #SpecialSelectors ifAbsent: [ nil ].
   temp notNil ifTrue: [
       1 to: temp size do:
		 [ :sel | (temp at: sel) = #value ifTrue: [valuenum <- sel]].
   ].
" Preform optimization pass.
  1) Jumps to Jumps get repointed to second Jump.
  2) Condition jumps to conditional jumps get optimized.
  3) While Blocks get unblocked.
  4) Jumps to next location get removed. 
 "
    changed <- false.
    list do: [ :node |
        nxt <- node next.
	node isCodeJump ifTrue: [
	    node value offset isCodeJump ifTrue: [
		node value: (node value offset value).
		changed <- true.
	    ].
	    node value offset = node nxt ifTrue: [
		node <- self removeCur: node.
		nxt <- node nxt.
		changed <- true.
	    ]
	].

        node isCodeJTrue or: [ node isCodeJFalse ] ifTrue: [
	    node value offset isCodeJump ifTrue: [
		node value: (node value offset value).
		changed <- true.
	    ].
	    node value offset = node nxt ifTrue: [
		node oper: (SmallTalkCodeNode CodePopStack).
		node value: (SmallTalkSymbol nilNode).
		changed <- true.
	    ]
	].
	
	node isCodeDuplicate ifTrue: [
	    nxt notNil and: [nxt isCodeJTrue or: [ nxt isCodeJFalse 
		and: [ nxt next notNil and: [ nxt next isCodePopStack 
		and: [ nxt value offset isCodeJTrue or: 
		     [ nxt value offset isCodeJFalse and: 
			[ nxt value offset value notNil ]]]]]]] ifTrue: [
		" Remove Dup and Pop "
		node <- self removeCur: node.
		self removeNext: node.
		" Advance Jump forward one step "
		node isCodeJTrue and: [ node value offset isCodeJFalse ]
		  ifTrue: [
			node value offset: (node value offset next) ]
		  ifFalse: [
		    node isCodeJFalse and: [ node value offset isCodeJTrue ]
		    ifTrue: [
			node value offset: (node value offset next) ]
		    ifFalse: [ node value offset: (node value offset) ]]]].
			
	" Remove dead code after jump or return "
	node isCodeBlockCopy and: [ node argcount == 0 ] ifTrue: [
	    nxt <- node value offset.
	    nxt notNil and: [nxt isCodeDuplicate and: [
		nxt next isCodeSend and: [
	        nxt next value offset value == #value and: [
	        nxt next next isCodeJTrue or: [
		nxt next next isCodeJFalse and: [
		nxt next next value offset isCodePopStack ]]]]]] ifTrue:
	      [
		" Convert ret blk to Jump after send "
		temp <- node next.
		nxt <- nxt next.
		[ temp ~~ node next ] whileTrue: [
			temp isCodeReturnBlock ifTrue: [
			    temp oper: (SmallTalkCodeNode CodeJump).
			    temp value: (SmallTalkSymbol labelNode).
			    temp value offset: nxt.
			].
			temp <- temp next.
		].
		" Point all labels that point to Dup to just after block "
		temp <- node next.
		list do: [ :n1 | 
			n1 value isSymbolLabel and: 
				[ n1 value offset == nxt ] ifTrue: [
				    n1 value offset: temp ]].
		
		" Remove extra instructions "
		self removeCur: ( nxt next next value offset).
		self removeCur: ( node value offset next).
		self removeCur: ( node value offset).
		node <- self removeCur: node.
		changed <- true.
	      ] ifFalse: [
		    nxt notNil and: [nxt isCodeDuplicate and: [
			nxt next isCodeSendSpec and: [
			nxt next value offset value == valuenum and: [ 
		 	nxt next next isCodeJTrue or: [
			nxt next next isCodeJFalse and: [
			nxt next next value offset isCodePopStack ]]]]]] ifTrue:
	      	[
		" Convert ret blk to Jump after send "
		temp <- node next.
		nxt <- nxt next.
		[ temp ~~ node next ] whileTrue: [
			temp isCodeReturnBlock ifTrue: [
			    temp oper: (SmallTalkCodeNode CodeJump).
			    temp value: (SmallTalkSymbol labelNode).
			    temp value offset: nxt.
			].
			temp <- temp next.
		].
		" Point all labels that point to Dup to just after block "
		temp <- node next.
		list do: [ :n1 | 
			n1 value isSymbolLabel and: 
				[ n1 value offset == nxt ] ifTrue: [
				    n1 value offset: temp ]].
		
		" Remove extra instructions "
		self removeCur: ( nxt next next value offset).
		self removeCur: ( node value offset next).
		self removeCur: ( node value offset).
		node <- self removeCur: node.
		changed <- true.
	        ]
	     ]
	   ]
	].
    ^ changed
!
" Optimize a code block. "
optimize
    | superFlag temp |
    self fixjumps.
    temp <- true.
    [ temp ] whileTrue: [
       superFlag <- self peephole.
       temp <- self optimizeJump.
       temp ifTrue: [ self relabel ].
    ].
    ^ superFlag.
!

" Generate a block of code. "
genblock
   | changed i j len |
   " Convert everything but jumps into code blocks "
    list do: [ :cur | cur generate ].
   
    changed <- true.
    [ changed ] whileTrue: [
	changed <- false. 

       " Set offsets of all blocks "
	i <- 0.
	list do: [ :cur | i <- (cur length) + (cur offset: i) ].

       " Convert everything but jumps into code blocks "
	list do: [ :cur |
	    len <- cur size.
	    cur length = len ifFalse: [ cur length: len. changed <- true ].
        ]
    ].

    " Convert jumps and remaining into code blocks "
    list do: [ :cur | cur generateJump ].

! !

! SmallTalkCodeTree methodsFor: 'Methods' !

" Check if code could be a get instance variable.
    psh ins #
    ret tos
"
 
isGetInst
   | cur inst |
    cur <- list.

    cur isCodePush and: [ cur value isSymbolInst ] ifFalse: [ ^ nil ].
    inst <- cur value offset.
    cur <- cur next.
    cur isNil ifTrue: [ ^ nil ].
    cur isCodeReturn and: [ cur value isSymbolStack ] ifFalse: [ ^ nil ].
    cur <- cur next.
    cur notNil ifTrue: [ ^ nil ].
    " Build method "
    ^ CompiledMethod newMethod: 0 header: ((inst * 256) + 16r68000000)
!

" Check if code could be a set instance variable.
 
   psh arg 0       psh arg 0
   str ins #	   dup
   psh arg 0	   str arg 0
   ret tos         ret tos
"
isSetInst
   | cur inst |
    cur <- list.

    cur isCodePush and: [ cur value isSymbolArg and: [ cur value offset = 0]]
	 ifFalse: [ ^ nil ].
    cur <- cur next.
    cur isNil ifTrue: [ ^ nil ].
    cur isCodeStore and: [ cur value isSymbolInst ] ifTrue: [
        inst <- cur value offset.
	cur <- cur next.
        cur isCodePush and: [ cur value isSymbolArg and:
	    [ cur value offset = 0]] ifFalse: [ ^ nil ].
    ] ifFalse: [
    	cur isCodeDuplicate
	  ifTrue: [
	    cur <- cur next.
            cur isNil ifTrue: [ ^ nil ].
            cur isCodeStore and: [ cur value isSymbolInst ]
	       ifTrue: [ inst <- cur value offset. ]
	       ifFalse: [ ^ nil ] ]
          ifFalse: [ ^ nil ].
    ].
    cur isCodeReturn and: [ cur value isSymbolStack ] ifFalse: [ ^ nil ].
    cur <- cur next.
    cur notNil ifTrue: [ ^ nil ].
    " Build method "
    ^ CompiledMethod newMethod: 0 header: ((inst * 256) + 16r70000000)
!

" Convert codetree into a method. "
makeMethod: lits argcount: count temps: tempcount for: primitive
    | bytecodes header eheader method litcount |

    " Convert code into byte codes. "
    self genblock.
    " Combine remaining code blocks, should have only one block left "
    bytecodes <- self combineCode.
    litcount <- lits size.
    primitive > 0 or: [ count > 12 ] ifTrue: [ 
	eheader <- primitive + (count bitShift: 16).
        header <- litcount + 1 + (tempcount bitShift: 8) +
		   (maxstack bitShift: 16) + 16rE8000000.
    ] ifFalse: [
        header <- litcount + (tempcount bitShift: 8) + (maxstack bitShift: 16) +
		   (count bitShift: 27).
	eheader <- 0.
    ].
    " Build method "
    method <- CompiledMethod newMethod: bytecodes size header: header.
    1 to: litcount do: [ :i |
	 method objectAt: (i + 1) put: ((lits at: i) value)].
    eheader = 0 ifFalse: [ method objectAt: (litcount + 2) put: eheader ].
    " Copy over code "
    1 to: bytecodes size do: [ :i | method byteAt: i put: (bytecodes at: i)].
    ^ method
! !


Object subclass: 'Compiler'
       instanceVariableNames: 'code token lits syms tempcount argcount class primnum sel inBlock optimBlk method error'
       classVariableNames: '' poolDictionaries: '' category: nil !

! Compiler class methodsFor: 'creation'!

evaluate: aString
    | comp |
    comp <- self new.
    (comp compileForExecute: aString) ifFalse: [ ^ comp error ].
    comp method DumpObject.
    ^ comp method evaluate
!

compile: aString forClass: aClass classified: aCategory
    | comp |
    comp <- self new.
    (comp compile: aString forClass: aClass) ifFalse: [ ^ comp error ].
    comp method description:
	    (MethodInfo sourceCode: aString forCategory: aCategory).
    aClass addSelector: comp sel withMethod: comp method classified: aCategory.
    ^ self.
!

compile: aString forClass: aClass classified: aCategory notify: aBlock
    | comp |
    comp <- self new.
    (comp compile: aString forClass: aClass) ifFalse:
	 [ ^ aBlock value: comp errorstr ].
    comp method description:
	    (MethodInfo sourceCode: aString forCategory: aCategory).
    aClass addSelector: comp sel withMethod: comp method classified: aCategory.
    ^ self.
!

compile: aString forClass: aClass
    | comp |
    comp <- self new.
    (comp compile: aString forClass: aClass) ifFalse: [ ^ comp error ].
    comp method description:
	    (MethodInfo sourceCode: aString).
    aClass addSelector: comp sel withMethod: comp method.
    ^ self.
!

compile: aString forClass: aClass notify: aBlock
    | comp |
    comp <- self new.
    (comp compile: aString forClass: aClass) ifFalse:
	 [ ^ aBlock value: comp errorstr ].
    comp method description:
	    (MethodInfo sourceCode: aString).
    aClass addSelector: comp sel withMethod: comp method.
    ^ self.
! !

! Compiler methodsFor: 'initialize' !
init: aString
    code <- SmallTalkCodeTree new.
    token <- SmallTalkToken on: aString.
    lits <- Bag new.
    syms <- Bag new.
    tempcount <- 0.
    argcount <- 0.
    class <- nil.
    sel <- nil.
    inBlock <- false.
    optimBlk <- false.
    method <- nil.
    primnum <- 0.

    " Add in defined objects "
    self add: 'self' type: SmallTalkSymbol SymbolSelf.
    self add: 'super' type: SmallTalkSymbol SymbolSuper.
    self add: 'true' type: SmallTalkSymbol SymbolTrue.
    self add: 'false' type: SmallTalkSymbol SymbolFalse.
    self add: 'nil' type: SmallTalkSymbol SymbolNil.
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
    | superFlag offset |
    self init: aString.
    (class <- aClass) notNil ifTrue: [
         offset <- 0.
         class allInstVarNames do: [ :var |
	    self add: var type: (SmallTalkSymbol SymbolInst) offset: offset.
	    offset <- offset + 1.
         ]
    ].
    token next.
    self messagePattern ifFalse: [ ^ false ].
    self doTemps ifFalse: [ ^ false ].
    " Check if primitive method. "
    self parsePrimitive ifFalse: [ ^ false ].
    self doBody ifFalse: [ ^ false ].
    token <- nil.
    code genPush: (SmallTalkSymbol new: 'self' 
				  type: SmallTalkSymbol SymbolSelf).
    code genReturnTOS.
    " Optimize out literals"
    superFlag <- code optimize.
    " Check if we can shortcut this method "
    tempcount = 0 ifTrue: [
	method <- code isGetInst
	method notNil ifTrue: [ syms <- code <- nil. ^ true ].
	method <- code isSetInst.
	method notNil ifTrue: [ syms <- code <- nil. ^ true ]
    ].
    self sortLiterals: aClass superclass needSuper: superFlag.
    method <- code makeMethod: lits argcount: argcount temps: tempcount
	 for: primnum.
    syms <- code <- nil.
    ^ true 
!

" Compile for execute. "
compileForExecute: aString
    | superFlag |
    self init: aString.
    token next.
    self doTemps.
    self doBody ifFalse: [ ^ false].
    token <- nil.
    code genPush: (SmallTalkSymbol new: 'self' 
				  type: SmallTalkSymbol SymbolSelf).
    code genReturnTOS.
   " Optimize out literals"
    superFlag <- code optimize.
    self sortLiterals: nil needSuper: superFlag.
    method <- code makeMethod: lits argcount: 0 temps: tempcount for: primnum.
    syms <- code <- nil.
    ^ true  
!

parseError: aMessage
    error <- aMessage. 
    ^ false
! !

! Compiler methodsFor: 'symbol table' !

" Add a new symbol table node. "
add: aName type: aType
      ^ SmallTalkSymbol new: aName type: aType offset: 0.
!

add: aName type: aType offset: aOffset
     | offset node sym |
      sym <- syms detect: [ :s | s isActive and: [ (s name) = aName ]]
	ifNone: [ nil ].
     sym notNil ifTrue: [ 
	self parseError: (aName , ' multiply defined'). ^ sym ].
  
     node <- SmallTalkSymbol new: aName type: aType offset: aOffset.
     node isSymbolArg ifTrue: [
		 node offset: argcount.
		 argcount <- argcount + 1. ].
     node isSymbolTemp ifTrue: [
		 node offset: tempcount.
		 tempcount <- tempcount + 1. ].
     syms add: node.
     ^ node
!

" Clean out symbols defined after offset. "
cleanafter: aOffset
    syms do: [ :s | s delete: aOffset ].
!

" Lookup symbol in symbol table. "
findSymbol
    | var sym name|
    name <- token value.
    sym <- syms detect: [ :s | s isActive and: [ (s name) = name ]]
	ifNone: [ nil ].
    sym notNil ifTrue: [ ^ sym ].

    " See if it is a class variable "
    var <- nil.
    class notNil and: [(var <- class classPool) notNil] ifTrue: [
	var <- var associationAt: (name asSymbol) ifAbsent: [nil]
	var isNil ifTrue: [
           " See if it is a shared pool "
	   class allSharedPools do: [ :pool |
		var <- Smalltalk at: pool ifAbsent: [nil].
		var notNil ifTrue: [
		   var <- var associationAt: name ifAbsent: [ nil ].
		  " If we found it, add it into symbol table "
		   var notNil ifTrue: [
			^ self add: name type: (SmallTalkSymbol SymbolVar)
					 offset: (self addLiteral: var)
		   ]
		] 
	    ]
	]
    ]. 

 
    " If not found try Smalltalk dictionary "
    var isNil ifTrue: [
	 var <-  Smalltalk associationAt: (name asSymbol) ifAbsent: [nil]].
    
    " If we found something, add it in "
    var notNil ifTrue: [
	^ self add: name type: (SmallTalkSymbol SymbolVar)
					 offset: (self addLiteral: var)
    ].
    ^ nil
!

" Lookup symbol in symbol table, by offset. "
findAt: aOffset
    | sym | 
    sym <- nil.
    syms do: [ :s |
	s isSymbolTemp and: [ (s offset) = aOffset ] ifTrue: [ sym <- s ]].
    ^ sym
!

" Add a new literal table node. "
addLiteral: aObject
    | newLit |
    newLit <- lits detect: [ :el | el value class == (aObject class)
			 and: [el value = aObject] ]
	 ifNone: [ SmallTalkLiteral new: aObject ].
    lits add: newLit.
    newLit usage.
    " newLit notNil ifTrue: [ newLit used. ^ newLit ]. "
    " newLit <- SmallTalkLiteral new: aObject."
    "lits at: aObject put: newLit."
    ^ newLit
! 

" Sort literals by usage count. "
sortLiterals: superClass needSuper: superFlag
   | sort found index last litcount|


   " Count number of used literals "
   found <- nil.
   litcount <- 0.
   lits do: [ :lp |
	(lp value) == superClass ifTrue: [ found <- lp. lp used ].
	(lp usage) > 0 ifTrue: [ litcount <- litcount + 1 ].
   ].

   " Add in superclass if we need it "
    superFlag and: [ superClass notNil and: [ found isNil]] ifTrue: [
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
! !


! Compiler methodsFor: 'private' !

" Parse the message pattern. "
messagePattern
    token isKeyName
       ifTrue: [ sel <- token value.  token next. ]
       ifFalse: [ token isKeyKeyword
	 ifTrue: [ self keyMessage. ]
	 ifFalse: [ token isKeySpecial 
	   ifTrue: [
		sel <- token value. 
		token next isKeyName ifTrue: [
	    	   self add: (token value) type: (SmallTalkSymbol SymbolArg).
		   token next. ]
	           ifFalse: [ ^ self parseError: 'Binary not followd by name' ]
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
	self add: (token value) type: (SmallTalkSymbol SymbolArg).
	token next.
	token isKeyKeyWord ifFalse: [ ^ true ].
	sel <- sel , (token value)
    ].
    self parseError: 'Keyword message pattern not followed by a name'.
    ^ false
!

" Parse temporaries.   "
doTemps
    token isVarSep ifTrue: [
	[ token next isKeyName ] whileTrue: [
	    self add: (token value) type: (SmallTalkSymbol SymbolTemp).
	].
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
			 [ token value class = Integer ] ifTrue: [
		primnum <- token value.
		token next isSpecial and: [ token value = '>' ] ifTrue: [
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
    token isKeyEOS ifTrue: [ ^ true ].

    token isKeyRBrack ifTrue: [
	code genPushNil.
        inBlock not ifTrue: [ ^ self parseError: 'Mismatched ]' ].
	^ true
    ].
    [ true ] whileTrue: [
	token isKeyReturn ifTrue: [
		token next.
		self doExpression ifFalse: [ ^ false ].
	        code genDuplicate.
		inBlock and: [ optimBlk not ]
		    ifTrue: [ code genReturnBlock ]
	            ifFalse: [ code genReturnTOS ]
	] ifFalse: [
		self doExpression ifFalse: [ ^ false ]. 
	].

	token isKeyEOS ifTrue: [
		code genPopTOS.
		^ true
	] ifFalse: [
	    token isKeyPeriod ifTrue: [
		code genPopTOS.
		" End of Block "
	        token next isKeyRBrack ifTrue: [
		    [ code genPushNil ].
		    ^ true
	        ] ifFalse: [
  	        " End of method "
	            token isKeyEOS ifTrue: [ ^ true ]
	        ].
   	    ] ifFalse: [
		token isKeyRBrack
		   ifTrue: [ ^ true ]
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
            ^ self parseError: 'Invalid name ' , token value.
        ].
	token next isKeyAssign ifTrue: [
	    asgname isSymbolInst or: [ asgname isSymbolTemp or: [
		asgname isSymbolVar ]] ifFalse: [
            	^ self parseError: 'Invalid asignment name ',  (asgname name).
	    ].
	    token next.
	    self doExpression ifFalse: [ ^ false ].
	    code genDupTOS.
	    self genStore: asgname.
 	    ^ true
        ] ifFalse: [ superFlag <- self nameTerm: asgname ].
    ] ifFalse: [ superFlag <- self doTerm ].
    superFlag isNil ifTrue: [ ^ false ]
                    ifFalse: [ ^self doContinue: superFlag ].
!

" Parse a term. "
doTerm
    | superFlag value |

    token isKeyLiteral ifTrue: [
          value <- self addLiteral: token value.
	  code genPushLit: value.
	  token next.
	  ^ false ].
    token isKeyName ifTrue: [
	  superFlag <- self nameTerm: (self findSymbol).
	  token next.
	  ^ superFlag ].
    token isKeyLBrack ifTrue: [
	  self doBlock not ifTtrue: [ ^ nil ]
		           ifFalse: [ token next. ^ false ]].
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
	s <- self keyContinue: superFlag.
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
    key = 'ifTrue:' ifTrue: [ ^ self doIfTrue ].
    key = 'ifFalse:' ifTrue: [ ^ self doIfFalse ].
    key = 'whileTrue:' ifTrue: [ ^ self doWhileTrue ].
    key = 'whileFalse:' ifTrue: [ ^ self doWhileFalse ].
    key = 'and:' ifTrue: [ ^ self doAnd ].
    key = 'or:' ifTrue: [ ^ self doOr ].

    pat <- ''.
    argc <- 0.
    [ token isKeyKeyword ] whileTrue: [
	pat <- pat , (token value).
	argc <- argc + 1.
	token next.
	(self doBinaryContinue: self doTerm) isNil ifTrue: [ ^ nil ].
    ].
    code genSend: (self addLiteral: (pat asSymbol)) argcount: argc super: s.
    ^ false
!

" Handle binary continuation "
doBinaryContinue: superFlag
    | lit s |

    (s <- self doUnaryContinue: superFlag) isNil ifTrue: [ ^ nil ].
    [ token isKeySpecial ] whileTrue: [
	lit <- self addLiteral: (token value asSymbol).
	token next.
	(s <- self doUnaryContinue: self doTerm) isNil ifTrue: [ ^ nil ].
        code genSend: lit argcount: 1 super: s.
    ].
    ^ s
!

" Handle unary continuations. "
doUnaryContinue: superFlag
    | s |
    (s <- superFlag) isNil ifTrue: [ ^ nil ].
    [ token isKeyName ] whileTrue: [
        code genSend: (self addLiteral: (token value asSymbol))
		 argcount: 0 super: s.
	s <- false.
	token next.
    ].
    ^ s
!

" Parse a block of code. "
doBlock
    | savetemps argc saveInblock saveOptimBlk block |
    savetemps <- tempcount.
    argc <- 0.
    saveInblock <- inBlock.
    saveOptimBlk <- optimBlk.

    [ token next isKeyVariable ] whileTrue: [
	self add: (token value) type: (SmallTalkSymbol SymbolTemp).
	argc <- argc + 1.
    ].

    token isVarSep ifTrue: [
	argc = 0 ifTrue: [ ^ self parseError: 'No arguments defined.' ].
	token next.
    ] ifFalse: [
	argc > 0 ifTrue: [ ^ self parseError: 'Need var seporator'.  ]
    ].

    " Jump forward to end of block. "
    block <- code genBlockCopy: argc.

   " Store arguments from stack into temps. "
    0 to: argc do: [ :i | code genStore: (self findAt: ( i + savetemps - 1)) ].

    " Do body of block "
    inBlock <- true.
    optimBlk <- false.
    self doBody ifFalse: [ ^ false ].
    inBlock <- saveInblock.
    optimBlk <- saveOptimBlk.

    token isKeyRBrack ifFalse: [ ^ self parseError: 'Block must end with ]'. ].
    code genReturnBlock.
    code setJumpTarget: block advance: 0.
    self cleanAfter: savetemps.
    ^ true
!

" Compile a optimized block. "
optimBlock
    | saveInblock saveOptimBlk |
    saveInblock <- inBlock.
    saveOptimBlk <- optimBlk.

   " Make sure we start with a block "
    token isKeyLBrack ifFalse: [ ^ self parseError: 'Error missing ['. ].
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

" Compile ifTrue: as a built in. "
doIfTrue
    | block |

    block <- code genJumpFForw.	" Jump forward to end of block. "
    self optimBlock ifFalse: [ ^ false ].

    token isKeyKeyword and: [ token value = 'ifFalse:' ] ifTrue: [
        code genDupTOS.
	code setJumpTarget: block advance: 1.
	block <- code genJumpForw.	" Skip around else block "
	self optimBlock ifFalse: [ ^ false ].	" Do else part "
    ].
    code setJumpTarget: block advance: 1.
    ^ true

!

" Compile ifFalse: as a built in. "
doIfFalse
    | block |

    block <- code genJumpTForw.	" Jump forward to end of block. "
    self optimBlock ifFalse: [ ^ false ]. 

    token isKeyKeyword and: [ token value = 'ifTrue:' ] ifTrue: [
        code genDupTOS.
	code setJumpTarget: block advance: 1.
	block <- code genJumpForw.	" Skip around else block "
	self optimBlock ifFalse: [ ^false ].	" Do else part "
    ].
    code setJumpTarget: block advance: 1.
    ^ true
!

" Compile whileTrue: as built in. "
doWhileTrue
    | loop block |
    loop <- code getCodeLabel.
    code genDupTOS.
    code genSend: (self addLiteral: #value) argcount: 0 super: false.
    block <- code genJumpFForw.		" Jump forward to end of block. "
    self optimBlock ifFalse: [ ^ false ]." Block body "
    code genPopTOS.			" Remove result of block "
    code setJumpTarget: block advance: 1.
    code genJump: loop.			" Jump to start of block "
    ^ true
!

" Compile whileFalse: as built in. "
doWhileFalse
    | loop block |
    loop <- code getCodeLabel.
    code genDupTOS.
    code genSend: (self addLiteral: #value) argcount: 0 super: false.
    block <- code genJumpTForw.		" Jump forward to end of block. "
    self optimBlock ifFalse: [ ^false ]." Block body "
    code genPopTOS.			" Remove result of block "
    code setJumpTarget: block advance: 1.
    code genJump: loop.			" Jump to start of block "
    ^ true
!

"  Compile and: as a built in.
 
   expression
   DupTOS
   JF          L1
   PopTOS
   block
  L1:
"   
doAnd
   | block key |

    code genDupTOS.
    block = code genJumpFForw.	" Jump forward to end of block. "
    code genPopTOS.
    self optimBlock ifFalse: [ ^ false ].
    code setJumpTarget: block advance: 0.

    " Keep grabing if we got another builtin "
    token isKeyKeyword ifTrue: [
	key <- token value.
    	key = 'ifTrue:' ifTrue: [ ^ self doIfTrue ].
    	key = 'ifFalse:' ifTrue: [ ^ self doIfFalse ].
    	key = 'and:' ifTrue: [ ^ self doAnd ].
    	key = 'or:' ifTrue: [ ^ self doOr ].
    ].
    ^ true
!

" Compile or: as a built in. "
doOr
   | block key |

    code genDupTOS.
    block <- code genJumpTForw.	" Jump forward to end of block. "
    code genPopTOS.
    self optimBlock ifFalse: [ ^ false ].
    code setJumpTarget: block advance: 0.

    " Keep grabing if we got another builtin "
    token isKeyKeyword ifTrue: [
	key <- token value.
    	key = 'ifTrue:' ifTrue: [ ^ self doIfTrue ].
    	key = 'ifFalse:' ifTrue: [ ^ self doIfFalse ].
    	key = 'and:' ifTrue: [ ^ self doAnd ].
    	key = 'or:' ifTrue: [ ^ self doOr ].
    ].
    ^ true
! !

