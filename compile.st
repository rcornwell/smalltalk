" Methods for Class stream and all it's subclasses"

" $Id: compile.st,v 1.9 2002/02/17 13:41:59 rich Exp rich $ "

"
 $Log: compile.st,v $
 Revision 1.9  2002/02/17 13:41:59  rich
 Added SyntaxError class.
 Started adding error handling for GUI subsystem.

 Revision 1.8  2001/08/29 20:16:34  rich
 Added class definitions
 Fixed bug with floating point numbers.

 Revision 1.7  2001/08/18 16:17:01  rich
 Placed classes and methods in correct categories.
 Added compiler error dump.
 Fixed compiler bug in emiting conditionals for results.
 Fixed compiler bug causing infinite loop on some errors.

 Revision 1.6  2001/08/01 16:42:31  rich
 Added Pshint instruction.
 Moved sendsuper to group 2.
 Added psh context instruction.

 Revision 1.5  2001/07/31 14:09:48  rich
 Total rewrite of parser and code generator.

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

Object subclass: 'SyntaxError'
       instanceVariableNames: ''
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Compiler'. !

! SyntaxError class methodsFor: 'messages' !

error: aMessage at: aPosition on: aString
    | start stream i |
    start <- aPosition.
    stream <- ReadStream on: aString.
    i <- 1.
    [ stream atEnd ] whileFalse: [
	 i == start ifTrue: [ stderr nextPutAll: ' **> '.
			      stderr nextPutAll: aMessage.
			      stderr nextPutAll: ' <** ' ].
	 stderr nextPut: (stream next).
	 i <- i + 1.
    ].
! !

Object subclass: 'SmallTalkCodePosition'
       instanceVariableNames: 'start end'
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Compiler' !

! SmallTalkCodePosition class methodsFor: 'creation' !

start: position1 end: position2
	^ self new start: position1 end: position2 
!

start: position1
	^ self new start: position1 
! !

! SmallTalkCodePosition methodsFor: 'access' !

start
	^ start
!

end
	^ end
! !

! SmallTalkCodePosition methodsFor: 'modifying' !

start: position1 end: position2
	start <- position1.
	end <- position2
!

start: position1
	start <- position1
!

end: position2
	end <- position2
! !

! SmallTalkCodePosition methodsFor: 'printing' !

printOn: aStream
	aStream nextPut: $(.
	start printOn: aStream.
	aStream nextPutAll: ', '.
	end printOn: aStream.
	aStream nextPut: $)
! !


Object subclass: 'SmallTalkToken'
       instanceVariableNames: 'token stream value curchar pushback first'
       classVariableNames: 'chartable actiontable arraytable tokentable'
       poolDictionaries: ''
       category: 'Compiler' !

SmallTalkToken comment: 
 	'I assist in parsing smalltalk methods by breaking Strings into a 
series of tokens.' !

! SmallTalkToken class methodsFor: 'creation' !

on: aStream
	^ super new initOn: aStream.
! !

! SmallTalkToken methodsFor: 'testing' !

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
	first <- 1.
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
	    		 ifFalse: [ curchar <- stream next.
				    ].
	].
	^ curchar
!

" Put character away to read again. "
pushback
	pushback <- curchar.
!

" Peek at the next character without actualy reading it. "
peeknext
	| c |
	pushback isNil ifFalse: [ ^ pushback ].
	stream atEnd ifTrue: [ ^ 0 asCharacter ].
	^ stream peek
!

isSpecial: aChar
	#( $+ $/ $\ $* $~ $< $> $= $@ $% $& $? $!! $- ) do:
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
	 	char <- self nextchar
	]
   ].

   " Scan first part of number. "
   done <- true.
   [ done and: [char isDigit or: [ char isUppercase ]]] whileTrue: [
        dig <- char digitValue.
        dig > base
           ifTrue: [ done <- false ]
           ifFalse: [
     		integer <- (integer * 10) + dig.  char <- self nextchar  ]
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
	     dig > base ifTrue: [ done <- false ]
	           ifFalse: [
	     		integer <- (integer * base) + dig.
	     		char <- self nextchar
		   ]
        ]
    ].

   " Check if fractional value "
    char = $. ifTrue: [
	char <- self peeknext.
	" Check if period at end of line "
	(char isDigit or: [ char isUppercase ]) ifTrue: [
		char <- self nextchar.
	        multi <- 1.0 / (base asFloat).
		done <- true.
		fseen <- true.
              " Scan fraction part of number. "
              [ done and: [ char isDigit or: [ char isUppercase ]]] whileTrue: [
		     dig <- char digitValue.
		     dig > base ifTrue: [ done <- false ]
		           ifFalse: [
       	           		fraction <- fraction + (multi * (dig asFloat)).
		   		multi <- multi / (base asFloat)
			   ].
		     char <- self nextchar
              ]
	 ] ifFalse: [ char <- $. ]
    ].

   " Check if exponent "
    char = $e ifTrue: [
	char <- self nextchar.
	eseen <- false.		" Grab variable for sec "
	char = $- ifTrue: [ eseen <- true. char <- self nextchar ].
        " Scan exponent. "
        [ char isDigit ] whileTrue: [
	     exp <- (exp * 10) + (char digitValue).
	     char <- self nextchar
        ].
	eseen ifTrue: [ exp <- exp negated ].
	eseen <- true
    ].
	
   " We read one char to many, put it back "
    self pushback.

   " Got a number now convert it to a object "
    (fseen or: [eseen]) ifTrue: [
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
    (curchar = $: and: [ #KeyName = token ]) ifTrue: [
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
    (curchar = $< and: [self peeknext = $- ]) ifTrue: [
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
	(self isKeyName or: [ self isKeyKeyword ])
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

" Return the value and advance the token to next one. "
valueNext
     | v |
     v <- value.
     self next.
     ^ v
!

" Return the start of current token. "
first
	^ first
!

position
	^ stream position
!

" Print out a token "
print
	| str |
	str <- 'Token: ' , (token asString).
	(self isKeyLiteral or: [ self isKeyName or: 
		[ self isKeyKeyword or: [ self isKeySpecial or:
			[self isKeyVariable ]]]]) ifTrue:
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
    	first <- stream position.
	self action: actiontable with: char.
	self isKeyEOS ifFalse: [ ^self ]
    ].
    token <- #KeyEOS.
    ^ self
! !

! SmallTalkToken methodsFor: 'error handling' !

errorDumpOn: aStream
    | start finish i |
    start <- first.
    finish <- stream position.
    stream reset.
    i <- 1.
    [ stream atEnd ] whileFalse: [
	 i == start ifTrue: [ aStream nextPutAll: ' **> ' ].
	 aStream nextPut: (stream next).
	 i == finish ifTrue: [ aStream nextPutAll: ' <** ' ].
	 i <- i + 1.
    ].
    stream position: finish.
! !

SmallTalkToken initialize !

Object subclass: 'SmallTalkParseStack'
       instanceVariableNames: 'position top'
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Compiler' !

SmallTalkParseStack comment:
	'I compute the size of the stack required to evaluate a method'. !

! SmallTalkParseStack class methodsFor: 'creation' !

new
	^ super new init
! !

! SmallTalkParseStack methodsFor: 'access' !

stacksize
	^ top
! !

! SmallTalkParseStack methodsFor: 'modifying' !

pop
	self pop: 1
!

pop: n
	position <- position - n
!

push
	self push: 1
!

push: n
	position <- position + n.
	position > top ifTrue: [ top <- position ]
!

init
	position <- 0.
	top <- 0.
! !

Object subclass: 'SmallTalkParseNode'
       instanceVariableNames: 'symbols node pos'
       classVariableNames: 'ptmp rtmp stmp parg plit pins pint sins jpt jpf jmp sdspc sdsup snd blk rets ret rett retf retn retb pop pvar pself dup pt pf pn pc svar specs'
       poolDictionaries: ''
       category: 'Compiler' !

! SmallTalkParseNode class methodsFor: 'creation' !

new: aTable
	^self new init: aTable
!

new: aTree table: aTable 
	^ self new init: aTree table: aTable
!

new: aTable start: aPosition
	^self new init: aTable start: aPosition
!

new: aTree table: aTable  start: aPosition
	^ self new init: aTree table: aTable start: aPosition
!

new: aTree table: aTable  start: aPosition end: aPosition2
	^ self new init: aTree table: aTable start: aPosition end: aPosition2
! !

! SmallTalkParseNode class methodsFor: 'Initialize' !

initialize
	| tmp |
	ptmp <- 16r10.
	rtmp <- 16r20.
	stmp <- 16r30.
	parg <- 16r40.
	plit <- 16r50.
	pins <- 16r60.
	sins <- 16r70.
	jpt  <- 16r80.
	jpf  <- 16r90.
	jmp  <- 16rA0.
	sdspc <- 16rB0.
	pint <- 16rD0.
	snd  <- 16rE0.
	blk  <- 16r0F.
        rets <- 16rF0.
	ret  <- 16rF1.
	rett <- 16rF2.
	retf <- 16rF3.
	retn <- 16rF4.
	retb <- 16rF5.
	pop  <- 16rF6.
	pvar <- 16rF7.
	pself <- 16rF8.
	dup  <- 16rF9.
	pt   <- 16rFA.
	pf   <- 16rFB.
	pn   <- 16rFC.
	sdsup <- 16rFD.
	pc   <- 16rFE.
	svar <- 16rFF.
	specs <- Dictionary new.
	tmp <- Smalltalk at: #SpecialSelectors
			 ifAbsent: [ Array new: 0 ].
	1 to: tmp size do: [ :i | specs at: (tmp at: i) put: (i - 1) ].
! !

! SmallTalkParseNode methodsFor: 'private' !

init: aTable
	symbols <- aTable.
	pos <- SmallTalkCodePosition new.
	node <- nil
!

init: aTree table: aTable
	symbols <- aTable.
	pos <- SmallTalkCodePosition new.
	node <- aTree
!

init: aTable start: aPosition
	symbols <- aTable.
	pos <- SmallTalkCodePosition start: aPosition.
	node <- nil
!

init: aTree table: aTable start: aPosition
	symbols <- aTable.
	pos <- SmallTalkCodePosition start: aPosition.
	node <- aTree
!

init: aTree table: aTable start: aPosition end: aPosition2
	symbols <- aTable.
	pos <- SmallTalkCodePosition start: aPosition end: aPosition2.
	node <- aTree
! !

! SmallTalkParseNode methodsFor: 'testing' !

isLeaf
	^ false
!

isBlock
	^ false
!

isSuper
	^ false
!

isGetInst
	^ false
!

isSetInst
	^ false
!

isArgOne
	^ false
!

canStore
	^ false
!

canReturn
 	^ false
!

canCascade
	^ false
! !

! SmallTalkParseNode methodsFor: 'access' !

start
	^pos start
!

end
	^pos end
!

node
	^ node
!

getInst
	^ -1
! !

! SmallTalkParseNode methodsFor: 'modifying' !

start: aInteger
	^ pos start: aInteger
!

end: aInteger
	^ pos end: aInteger
!

node: aExpr
	^ node <- aExpr
! !

! SmallTalkParseNode methodsFor: 'generation' !

optimize
	^ self
!

stack: stack forEffect: result
	result ifFalse: [ stack push ].
!

sizeForEffect: result
	^ 0
!

sizeForReturn
	^ 1 + (self sizeForEffect: false)
!

sizeJump: dist
	(dist > 0 and: [ dist < 16 ]) ifTrue: [ ^ 1 ].
	(dist > 127 or: [ dist < -127 ]) ifTrue: [ ^ 3 ].
	^ 2
!

sizeJumpCond: dist
	(dist > 0 and: [ dist < 16 ]) ifTrue: [ ^ 1 ].
	(dist > 127 or: [ dist < -127 ]) ifTrue: [ ^ 4 ].
	^ 2
!

emitOn: aStream position: codePosition forEffect: result
	self subclassResponsablity
!

emitForReturn: aStream position: codePosition
	self emitOn: aStream position: codePosition forEffect: false.
	aStream nextPut: ret.
	codePosition at: aStream position put: pos
!

emitStore: aStream position: codePosition
	self subclassResponsablity
!

emitOpcode: aStream opc: opc offset: offset
	(offset > 15 or: [ offset < 0])
	     ifTrue: [
		aStream nextPut: (opc bitShift: -4).
		aStream nextPut: (offset bitAnd: 16rFF)]
	     ifFalse: [
		aStream nextPut: (opc + (offset bitAnd: 16r0F))
	     ]
!

emitJump: aStream distance: dist
	(dist > 127 or: [ dist < -127 ])
	    ifTrue: [
		aStream nextPut: 0.
		aStream nextPut: (dist bitAnd: 16rFF).
		aStream nextPut: ((dist bitShift: -8) bitAnd: 16rFF) ]
	    ifFalse: [
		self emitOpcode: aStream opc: jmp offset: dist  ].
!

emitJump: aStream distance: dist cond: aBoolean
	(dist > 127 or: [ dist < -127 ])
	    ifTrue: [
		aBoolean ifTrue: [ aStream nextPut: jpf + 3 ]
			 ifFalse: [ aStream nextPut: jpt + 3 ].
		aStream nextPut: 0.
		aStream nextPut: (dist bitAnd: 16rFF).
		aStream nextPut: ((dist bitShift: -8) bitAnd: 16rFF) ]
	    ifFalse: [
		aBoolean ifTrue: [
			     self emitOpcode: aStream opc: jpt offset: dist ]
			ifFalse: [
			     self emitOpcode: aStream opc: jpf offset: dist ]
	    ]
! !

SmallTalkParseNode initialize !

SmallTalkParseNode subclass: 'SmallTalkAssignNode'
       instanceVariableNames: 'expr'
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Compiler' !

! SmallTalkAssignNode class methodsFor: 'creation' !

new: aSymbol expr: aExpr table: aTable start: position1 end: position2
	^ self new init: aSymbol 
		   expr: aExpr 
		   table: aTable
		   start: position1
		   end: position2
! !

! SmallTalkAssignNode methodsFor: 'modifying' !

init: aSymbol expr: aExpr table: aTable start: position1 end: position2
	symbols <- aTable.
	node <- aSymbol.
	expr <- aExpr.
	pos <- SmallTalkCodePosition start: position1 end: position2
! !

! SmallTalkAssignNode methodsFor: 'accessing' !

getInst
	^ node getInst
! !

! SmallTalkAssignNode methodsFor: 'testing' !

isGetInst
	^ node isGetInst
!

isSetInst
	^ node isGetInst and: [ expr isArgOne ]
! !

! SmallTalkAssignNode methodsFor: 'generation' !

stack: stack forEffect: result
	expr stack: stack forEffect: false.
	result ifTrue: [ stack pop ].
!

sizeForEffect: result
	| c |
	c <- (expr sizeForEffect: false) + (node sizeForEffect: false).
	result ifFalse: [ c <- c + 1 ].
	^ c
!

emitOn: aStream position: codePosition forEffect: result
	expr emitOn: aStream position: codePosition forEffect: false.
	result ifFalse: [ 
	      aStream nextPut: dup.
	      codePosition at: aStream position put: pos
	].
	node emitStore: aStream position: codePosition.
	codePosition at: aStream position put: pos
! !

! SmallTalkAssignNode methodsFor: 'printing' !

printOn: aStream
	node printOn: aStream.
	aStream nextPutAll: ' <- '.
	expr printOn: aStream
! !

SmallTalkParseNode subclass: 'SmallTalkBlockNode'
       instanceVariableNames: 'args hasreturn'
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Compiler' !

! SmallTalkBlockNode class methodsFor: 'creation' !

new: aTable start: aPosition
	^ self new init: aTable start: aPosition
! !

! SmallTalkBlockNode methodsFor: 'private' !

init: aTable start: aPosition
	symbols <- aTable.
	node <- OrderedCollection new.
	args <- OrderedCollection new.
	pos <- SmallTalkCodePosition start: aPosition.
	hasreturn <- false.
! !

! SmallTalkBlockNode methodsFor: 'accessing' !

body
	^ node
!

hasreturn
	^ hasreturn
!

argcount
	^ args size
! !

! SmallTalkBlockNode methodsFor: 'modifying' !

addArg: aSymbol
	args add: aSymbol
!

add: aExpr
	hasreturn ifFalse: [ node add: aExpr ].
!

returned
	hasreturn <- true.
!

cleanSymbols
    node size == 0 ifTrue: [ node add: symbols nilnode ].
    args do: [ :a | symbols removeSym: a ].
! !

! SmallTalkBlockNode methodsFor: 'testing' !

isBlock
	^ args size == 0
! !

! SmallTalkBlockNode methodsFor: 'generation' !

stack: stack forEffect: result
	| flag nstack |
	stack push.
	nstack <- SmallTalkParseStack new.
	1 to: node size do: 
		[ :i | (node at: i) stack: nstack forEffect: true ]. 
	stack push: nstack stacksize.
	stack pop: nstack stacksize.
	result ifTrue: [ stack pop ]
!

sizeForEffect: result
	| c |
	c <- 0.
	" Count stores for arguments "
	args do: [ :a | c <- c + (a sizeForEffect: false) ].
	1 to: node size - 1 do:
			 [ :i | c <- c + ((node at: i) sizeForEffect: true) ]. 
	hasreturn ifTrue: 
		[ c <- c + ((node at: (node size)) sizeForEffect: true) ]
		  ifFalse:
		[ c <- c + 1 + ((node at: (node size)) sizeForEffect: false) ].
	" Add on size of jump instruction. "
	c <- c + (self sizeJump: c).
	" Add on the jump instruction and the block copy "
	c <- c + 2.
	^ c
!

emitOn: aStream position: codePosition forEffect: result
	| c flag |
	c <- 0.
	" Count stores for arguments "
	args do: [ :a | c <- c + (a sizeForEffect: false) ].
	1 to: node size - 1 do:
		 [ :i | c <- c + ((node at: i) sizeForEffect: true) ]. 
	hasreturn ifTrue: 
		[ c <- c + ((node at: (node size)) sizeForEffect: true) ]
		  ifFalse: 
		[ c <- c + 1 + ((node at: (node size)) sizeForEffect: false) ].
	" Now we know the size, put out block copy "
	aStream nextPut: blk.
	aStream nextPut: (args size).
	codePosition at: aStream position put: pos.
	" Now jump around the block "
	self emitJump: aStream distance: c.
	args do: [ :a | self emitOpcode: aStream opc: stmp offset: a offset ].
	c <- node size.
	1 to: c do: 
		[ :i | 
		     c == i ifTrue: [ flag <- hasreturn or: [ result]]
		 	    ifFalse: [ flag <- true].
		  (node at: i) emitOn: aStream position: codePosition forEffect: flag.
		    (c == i and: [ hasreturn not ]) ifTrue: [
			     aStream nextPut: retb.
			     codePosition at: aStream position put: pos
			].
		].
! !

! SmallTalkBlockNode methodsFor: 'printing' !

printOn: aStream
	| s |
	" Print out arguments first. "
	aStream nextPutAll: '[ '.
	s <- args size.
	1 to: s do: [ :i |
		aStream nextPut: $:.
		aStream nextPutAll: (args at: i) node.
		aStream	nextPut: $ .
		i == s ifTrue: [
			aStream nextPut: $|.
			aStream nl
		]
	].
	s <- node size.
	" Now print out body. "
	1 to: s do: [ :i |
		(node at: i ) printOn: aStream.
		i ~= s ifTrue: [
			aStream nextPut: $. .
			aStream nl
		] ifFalse: [
			aStream nextPut: $ .   " Blank "
		]
	].
	" Finish off the block. "
	aStream nextPut: $] .
	aStream nl.
! !

SmallTalkParseNode subclass: 'SmallTalkTermNode'
       instanceVariableNames: ''
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Compiler' !

! SmallTalkTermNode class methodsFor: 'creation' !

new: aNode start: start end: end
	^self new node: aNode start: start end: end
! !

! SmallTalkTermNode methodsFor: 'accessing' !

getInst
	^ node getInst
! !

! SmallTalkTermNode methodsFor: 'modifying' !

node: aNode start: start end: end
	node <- aNode.
	pos <- SmallTalkCodePosition start: start end: end.
! !


! SmallTalkTermNode methodsFor: 'printing' !

printOn: aStream
	node printOn: aStream
! !

! SmallTalkTermNode methodsFor: 'generation' !

stack: stack forEffect: result
	node stack: stack forEffect: result
!

sizeForEffect: result
	^ node sizeForEffect: result
!

emitOn: aStream position: codePosition forEffect: result
	result ifFalse: [ 
		node emitOn: aStream position: codePosition forEffect: result.
	        codePosition at: aStream position put: pos
	]
		
!

sizeForReturn
	^ node sizeForReturn
!

emitForReturn: aStream position: codePosition
	node emitForReturn: aStream position: codePosition.
        codePosition at: aStream position put: pos
!

emitStore: aStream position: codePosition
	node emitStore: aStream position: codePosition.
        codePosition at: aStream position put: pos
! !

! SmallTalkTermNode methodsFor: 'testing' !

isLeaf
	^ node isLeaf
!

isGetInst
	^ node isGetInst
!

isArgOne
	^ node isArgOne
!

canStore
	^ node canStore
!

canReturn
	^ node canReturn
!

isSuper
	^ node isSuper
! !

! SmallTalkTermNode methodsFor: 'testing' !

optimize
	node <- node optimize.
	^ self
! !

SmallTalkParseNode subclass: 'SmallTalkLeafNode'
       instanceVariableNames: 'offset'
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Compiler' !

! SmallTalkLeafNode class methodsFor: 'creation' !

new: aValue offset: aOffset table: aTable 
	^self new init: aValue offset: aOffset table: aTable
!

new: aValue offset: aOffset table: aTable start: aPosition
	^self new init: aValue offset: aOffset table: aTable start: aPosition
! !

! SmallTalkLeafNode methodsFor: 'testing' !

isLeaf
	^ true
! !

! SmallTalkLeafNode methodsFor: 'accessing' !

offset
	^ offset
! !

! SmallTalkLeafNode methodsFor: 'modifying' !

init: aSymbol offset: aOffset table: aTable
	symbols <- aTable.
	offset <- aOffset.
	node <- aSymbol.
	pos <- SmallTalkCodePosition new.
!

init: aSymbol offset: aOffset table: aTable start: aPosition
	symbols <- aTable.
	offset <- aOffset.
	node <- aSymbol.
	pos <- SmallTalkCodePosition start: aPosition.
!

offset: aOffset
	offset <- aOffset.
! !


! SmallTalkLeafNode methodsFor: 'printing' !

printOn: aStream
	aStream nextPutAll: node asString
! !

! SmallTalkLeafNode methodsFor: 'generation' !

stack: stack forEffect: result
	result ifFalse: [ stack push ].
! !

SmallTalkLeafNode subclass: 'SmallTalkLiteralNode'
       instanceVariableNames: ''
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Compiler' !

! SmallTalkLiteralNode methodsFor: 'generation' !

sizeForEffect: result
	result ifFalse: [ offset > 15 ifTrue: [ ^ 2 ] ifFalse: [ ^ 1 ]]
	       ifTrue: [ ^ 0 ].
!

emitOn: aStream position: codePosition forEffect: result
	result ifFalse: [ self emitOpcode: aStream opc: plit offset: offset ]
! !

! SmallTalkLiteralNode methodsFor: 'printing' !

printOn: aStream
	node storeOn: aStream
! !

SmallTalkLeafNode subclass: 'SmallTalkConstantNode'
       instanceVariableNames: ''
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Compiler' !

! SmallTalkConstantNode methodsFor: 'generation' !

sizeForEffect: result
	result ifFalse: [ 
		(node > -8 and: [node < 8])
		    ifTrue: [ ^ 1] ifFalse: [ ^ 2]]
	       ifTrue: [ ^ 0 ].
!

emitOn: aStream position: codePosition forEffect: result
	| operand |
	result ifFalse: [ 
		operand <- node.
		(node > -8 and: [ node < 0])
		     ifTrue: [ 
			 aStream nextPut: (pint + (operand + 16)).
			 ^self ].
		(node >= 0 and: [ node < 8])
		     ifTrue: [
			 aStream nextPut: (pint + operand).
			 ^self  ].
		operand < 0 ifTrue: [ operand <- operand + 256 ].
	 	aStream nextPut: (pint bitShift: -4).
		aStream nextPut: (operand bitAnd: 16rFF).
	]
! !

! SmallTalkConstantNode methodsFor: 'printing' !

printOn: aStream
	node printOn: aStream
! !

SmallTalkLeafNode subclass: 'SmallTalkVariableNode'
       instanceVariableNames: 'type name'
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Compiler' !

! SmallTalkVariableNode class methodsFor: 'creation' !

new: aString type: aSymbol offset: aNumber table: aTable
	^super new name: aString type: aSymbol offset: aNumber table: aTable
! !

! SmallTalkVariableNode methodsFor: 'accessing' !

name
	^ node asString
!

getInst
	type == #inst ifTrue: [ ^ offset ]
		      ifFalse: [ ^ -1 ].
! !

! SmallTalkVariableNode methodsFor: 'modifying' !

name: aString type: aSymbol offset: aNumber table: aTable
	super init: aSymbol offset: aNumber table: aTable.
	node <- aString.
	type <- aSymbol
! !

! SmallTalkVariableNode methodsFor: 'testing' !

isGetInst
	^ type == #inst
!

isArgOne
	^ type == #arg and: [ offset == 0 ]
!

canStore
	^ type == #temp or: [ type == #inst or: [ type == #var ]]
!

canReturn
	^ type == #temp
! !

! SmallTalkVariableNode methodsFor: 'generation' !

sizeForEffect: result
	result ifTrue: [ ^ 0 ]
	       ifFalse: [
		 type == #var ifTrue: [ ^ 2 ].
		 offset > 15 ifTrue: [ ^ 2 ] ifFalse: [ ^ 1 ]]
!

sizeForReturn
	type == #temp
		ifTrue: [ offset > 15 ifTrue: [ ^ 2 ] ifFalse: [ ^ 1] ]
		ifFalse: [ ^ 1 + (self sizeForEffect: false) ].
!

emitForReturn: aStream position: codePosition
	type == #temp
	    ifTrue: [ self emitOpcode: aStream opc: rtmp offset: offset ]
	    ifFalse: [ self emitOn: aStream position: codePosition 
					forEffect: false.
		       aStream nextPut: ret ].
!

emitStore: aStream position: codePosition
	| opc |
	type == #var ifTrue: [
		aStream nextPut: svar.
		aStream nextPut: offset offset.
		^ self
		].
	type == #temp ifTrue: [ opc <- stmp ].
	type == #inst ifTrue: [ opc <- sins ].
	self emitOpcode: aStream opc: opc offset: offset
!

emitOn: aStream position: codePosition forEffect: result
	| opc |
	result ifFalse: [
		type == #var ifTrue: [
			aStream nextPut: pvar.
			aStream nextPut: offset offset.
			^ self
			].
		type == #temp ifTrue: [ opc <- ptmp ].
		type == #inst ifTrue: [ opc <- pins ].
		type == #arg ifTrue: [ opc <- parg ].
		self emitOpcode: aStream opc: opc offset: offset
	]
! !

SmallTalkLeafNode subclass: 'SmallTalkBuiltinNode'
       instanceVariableNames: ''
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Compiler' !

! SmallTalkBuiltinNode methodsFor: 'testing' !

isSuper
	^ node == #super
!

canReturn
	^ node ~= #super and: [ node ~= #thisContext ]
! !

! SmallTalkBuiltinNode methodsFor: 'access' !

name
	^ node asString
! !

! SmallTalkBuiltinNode methodsFor: 'generation' !

sizeForEffect: result
	result ifTrue: [ ^ 0 ] ifFalse: [ ^ 1 ].
!

sizeForReturn
	^ 1
!

emitOn: aStream position: codePosition forEffect: result
	result ifFalse: [
		node == #super ifTrue: [ aStream nextPut: pself ].
		node == #self ifTrue: [ aStream nextPut: pself ].
		node == #true ifTrue: [ aStream nextPut: pt ].
		node == #false ifTrue: [ aStream nextPut: pf ].
		node == #nil ifTrue: [ aStream nextPut: pn ].
		node == #thisContext ifTrue: [ aStream nextPut: pc ]
	]
!

emitForReturn: aStream position: codePosition
	node == #self ifTrue: [ aStream nextPut: rets ].
	node == #true ifTrue: [ aStream nextPut: rett ].
	node == #false ifTrue: [ aStream nextPut: retf ].
	node == #nil ifTrue: [ aStream nextPut: retn ].
! !

SmallTalkBlockNode subclass: 'SmallTalkValueNode'
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Compiler' !

! SmallTalkValueNode class methodsFor: 'creation' !

newFrom: aBlock
   ^ super new from: aBlock
! !

! SmallTalkValueNode methodsFor: 'modifying' !

from: aBlock
	node <- aBlock body.
	hasreturn <- aBlock hasreturn.
! !

! SmallTalkValueNode methodsFor: 'generation' !

stack: stack forEffect: result
	| flag |
	1 to: node size do: 
		[ :i | 
		  node size == i ifTrue: [ flag <- hasreturn or: [ result]]
				ifFalse: [ flag <- true].
		 (node at: i) stack: stack forEffect: flag ]. 
!

sizeForEffect: result
	| c flag |
	c <- 0.
	1 to: node size do: 
		[ :i | 
		  node size == i ifTrue: [ flag <- hasreturn or: [ result]]
				ifFalse: [ flag <- true].
		  c <- c + ((node at: i) sizeForEffect: flag) ]. 
	^ c
!

emitOn: aStream position: codePosition forEffect: result
	| flag |
	1 to: node size do: 
		[ :i | 
		  node size == i ifTrue: [ flag <- hasreturn or: [ result]]
				ifFalse: [ flag <- true].
		  (node at: i) emitOn: aStream position: codePosition forEffect: flag ].
! !


SmallTalkParseNode subclass: 'SmallTalkCondNode'
	instanceVariableNames: 'trueClause falseClause'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Compiler' !

! SmallTalkCondNode class methodsFor: 'creation' !

new: aExpr trueClause: aTBlock falseClause: aFBlock table: aTable pos: aPosition
 ^ super new init: aExpr trueClause: aTBlock falseClause: aFBlock table: aTable pos: aPosition
! !

! SmallTalkCondNode methodsFor: 'modifying' !

init: aExpr trueClause: aTBlock falseClause: aFBlock table: aTable pos: aPosition
	symbols <- aTable.
	node <- aExpr.
        pos <- aPosition.
	aTBlock isNil 
	     ifTrue: [ trueClause <- nil ]
	     ifFalse: [ trueClause <- SmallTalkValueNode newFrom: aTBlock].
	aFBlock isNil
	     ifTrue: [ falseClause <- nil ]
	     ifFalse: [	falseClause <- SmallTalkValueNode newFrom: aFBlock].
! !

! SmallTalkCondNode methodsFor: 'generation' !

stack: stack forEffect: result
	node stack: stack forEffect: result.
	" If we are going for results, make sure both clauses have values"
	(result not and: [ (trueClause isNil or: [ falseClause isNil])])
		ifTrue: [
			trueClause isNil ifTrue: [
						trueClause <- symbols nilnode ].
			falseClause isNil ifTrue: [
						falseClause <- symbols nilnode ]
		].
	trueClause isNil ifFalse:
		 [ trueClause stack: stack  forEffect: true].
	falseClause isNil ifFalse:
		 [ falseClause stack: stack forEffect: true ]
!

sizeForEffect: result
	| cc ct ce rt |
	" Size of conditional "
	cc <- node sizeForEffect: false.
	" Size of then clause "
	trueClause isNil
		ifTrue: [ ct <- 0. rt <- false ]
		ifFalse: [ ct <- trueClause sizeForEffect: result.
			   rt <- trueClause hasreturn ].
	" Size of else clause "
	falseClause isNil
		ifTrue: [ ce <- 0 ]
		ifFalse: [ ce <- falseClause sizeForEffect: result ].
	" Check if we only have one clause "
	(ct == 0 or: [ ce == 0 ]) ifTrue: [
		ct <- ct + ce.
		cc <- cc + (self sizeJumpCond: ct).
		^ cc + ct ].
	" Ok we got two... see if then clause returns "
	rt ifFalse: [
		" Add on size of jump around else. "
		ct <- ct + (self sizeJump: ce).
	].
	" Add size of jump to else clause "
	cc <- cc + (self sizeJumpCond: ct).
	^ cc + ce + ct
!

emitOn: aStream position: codePosition forEffect: result
	| ct ce jmptype joff rt |
	" Emit condtional part first. "
	node emitOn: aStream position: codePosition forEffect: false.
	trueClause isNil
		ifTrue: [ ct <- 0.
			 rt <- false ]
		ifFalse: [ ct <- trueClause sizeForEffect: result.
			   rt <- trueClause hasreturn ].
	falseClause isNil
		ifTrue: [ ce <- 0 ]
		ifFalse: [ ce <- falseClause sizeForEffect: result ].
	jmptype <- false.
	ct == 0 ifTrue: [ jmptype <- true.  joff <- ce ]
		ifFalse: [ 
			" Add on jump to final if no return "
			(ce == 0 or: [rt]) ifFalse: [
					 ct <- ct + (self sizeJump: ce) ].
			joff <- ct
		 ].
	" Now jump around body. "
	self emitJump: aStream distance: joff cond: jmptype.
	codePosition at: aStream position put: pos.
	trueClause isNil ifFalse: [
		 trueClause emitOn: aStream
		            position: codePosition
			    forEffect: result.
		 (ce == 0 or: [ rt ]) ifFalse: [
			self emitJump: aStream distance: ce.
			codePosition at: aStream position put: pos
		]
	].
	falseClause isNil ifFalse:
		 [ falseClause emitOn: aStream
			       position: codePosition
			       forEffect: result ]
! !

! SmallTalkCondNode methodsFor: 'printing' !

printOn: aStream
	node printOn: aStream.
	aStream nl.
	trueClause isNil ifFalse: [
		aStream nextPutAll: ' ifTrue: '.
		trueClause printOn: aStream.
		aStream nl
	].
	falseClause isNil ifFalse: [
		aStream nextPutAll: ' ifFalse: '.
		falseClause printOn: aStream.
		aStream nl
	]
! !

SmallTalkParseNode subclass: 'SmallTalkLoopNode'
	instanceVariableNames: 'type body'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Compiler' !

! SmallTalkLoopNode class methodsFor: 'creation' !

new: aExpr type: aBoolean body: aBlock table: aTable pos: aPosition
   ^ super new init: aExpr type: aBoolean body: aBlock table: aTable pos: aPosition
! !

! SmallTalkLoopNode methodsFor: 'modifying' !

init: aExpr type: aBoolean body: aBlock table: aTable pos: aPosition
	symbols <- aTable.
	node <- SmallTalkValueNode newFrom: aExpr.
	type  <- aBoolean.
	body <- SmallTalkValueNode newFrom: aBlock.
	pos <- aPosition.
! !

! SmallTalkLoopNode methodsFor: 'generation' !

stack: stack forEffect: result
	node stack: stack forEffect: false.
	stack pop.
	body stack: stack forEffect: true.
!

sizeForEffect: result
	| cb cc |
	" Cond "
	cc <- 1 + (node sizeForEffect: false).
	" Body "
	cb <- 2 + (body sizeForEffect: true).
	" If body is over byte offset, then add 2 to condition "
	cb > 15 ifTrue: [ cc <- cc + 1 ].
	cb > 126 ifTrue: [ cc <- cc + 2 ].
	" If body plus condition is over 127 then add one to body "
	(cc + cb) > 127 ifTrue: [ cb <- cb + 1 ].
	^ cc + cb
!

emitOn: aStream position: codePosition forEffect: result
	| cb cc |
	" Cond plus short jump "
	cc <- 1 + (node sizeForEffect: false).
	" Body plus a jump back "
	cb <- 2 + (body sizeForEffect: true).
	" If body is over byte offset, then add 2 to condition "
	cb > 15 ifTrue: [ cc <- cc + 1 ].
	cb > 126 ifTrue: [ cc <- cc + 2 ].
	" If body plus condition is over 127 then add one to body "
	(cc + cb) > 127 ifTrue: [ cb <- cb + 1 ].
	" Now that we know sizes, generate actual code. "
	" Emit condition. "
	node emitOn: aStream position: codePosition forEffect: false.
	" Now jump around body. "
	codePosition at: aStream position put: pos.
	self emitJump: aStream distance: cb cond: type not.
	" Now we can output body "
	body emitOn: aStream position: codePosition forEffect: true.
	" Lastly put a jump back to very begining. "
	codePosition at: aStream position put: pos.
	self emitJump: aStream distance: ((cb + cc) negated).
! !

! SmallTalkLoopNode methodsFor: 'printing' !

printOn: aStream
	node printOn: aStream.
	type ifTrue: [ aStream nextPutAll: ' whileTrue: ' ]
	     ifFalse: [ aStream nextPutAll: ' whileFalse: ' ].
	aStream nl.
	body printOn: aStream
! !

SmallTalkParseNode subclass: 'SmallTalkAndOrNode'
	instanceVariableNames: 'second type'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Compiler' !

! SmallTalkAndOrNode class methodsFor: 'creation' !

new: aExpr second: aBlock type: aBoolean table: aTable pos: aPosition
   ^ self new init: aExpr second: aBlock type: aBoolean table: aTable pos: aPosition
! !

! SmallTalkAndOrNode methodsFor: 'modifying' !

init: aExpr second: aBlock type: aBoolean  table: aTable pos: aPosition
	symbols <- aTable.
	node <- aExpr.
	second <- SmallTalkValueNode newFrom: aBlock.
	type <- aBoolean.
	pos <- aPosition
! !

! SmallTalkAndOrNode methodsFor: 'generation' !

stack: stack forEffect: result
	node stack: stack forEffect: false.
	stack push.
	stack pop.
	second stack: stack forEffect: result.
!

sizeForEffect: result
	| cc c2 |
	cc <- 2 + (node sizeForEffect: false).
	c2 <- 1 + (second sizeForEffect: false).
	c2 > 127 ifTrue: [ cc <- cc + 2 ].
	c2 > 15 ifTrue: [ cc <- cc + 1 ].
	result ifTrue: [ c2 <- c2 + 1].
	^ cc + c2
!

emitOn: aStream position: codePosition forEffect: result
	| c2 |
	node emitOn: aStream position: codePosition forEffect: false.
	aStream nextPut: dup.
	codePosition at: aStream position put: pos.
	c2 <- 1 + (second sizeForEffect: false).
	" Now jump around body. "
	self emitJump: aStream distance: c2 cond: type.
	codePosition at: aStream position put: pos.
	aStream nextPut: pop.
	codePosition at: aStream position put: pos.
	second emitOn: aStream position: codePosition forEffect: false.
	result ifTrue: [ 
		aStream nextPut: pop 
		codePosition at: aStream position put: pos.
	].
! !

! SmallTalkAndOrNode methodsFor: 'printing' !

printOn: aStream
	node printOn: aStream.
	type ifTrue: [ aStream nextPut: ' or: ' ]
	     ifFalse: [ aStream nextPut: ' and: ' ].
	second printOn: aStream.
! !

SmallTalkParseNode subclass: 'SmallTalkMessageNode'
       instanceVariableNames: 'selector args type'
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Compiler' !

! SmallTalkMessageNode class methodsFor: 'creation' !

new: aExpr table: aTable start: aPosition
	^ self new init: aExpr selector: nil table: aTable start: aPosition

!

new: aExpr selector: aSymbol table: aTable start: aPosition
	^ self new init: aExpr selector: aSymbol table: aTable start: aPosition
! !

! SmallTalkMessageNode methodsFor: 'modifying' !

init: aExpr selector: aSymbol table: aTable start: aPosition
	symbols <- aTable.
	args <- OrderedCollection new.
	node <- aExpr.
	selector <- aSymbol.
	type <- #simple.
	pos <- SmallTalkCodePosition start: aPosition
!

selector: aSymbol
	selector <- aSymbol
!

addArg: aExpr
	args add: aExpr
! !

! SmallTalkMessageNode methodsFor: 'testing' !

canCascade
	^ true
! !

! SmallTalkMessageNode methodsFor: 'generation' !

optimize
	| argc b1 b2 |
	argc <- args size.
	" Set flags to save checks. "
	argc > 0 ifTrue: [ b1 <- (args at: 1) isBlock ]
		 ifFalse: [ b1 <- false ].
	argc > 1 ifTrue: [ b2 <- (args at: 2) isBlock ]
		 ifFalse: [ b2 <- false ].
	" Check if block value or while "
	node isBlock ifTrue: [
		(argc == 0 and: [ selector == #value ]) ifTrue: [
			^ SmallTalkValueNode from: node ].
		(argc == 1 and: [ b1 and:
			[ (selector == #whileTrue: or: 
			  [ selector == #whileFalse: ])]]) ifTrue: [
			^ SmallTalkLoopNode new: node
				 type: selector == #whileTrue:
				 body: (args at: 1) 
				 table: symbols
				 pos: pos ]
	].
	" Single clause if or and/or "
	(argc == 1 and: [ b1 ]) ifTrue: [
		selector == #ifTrue: ifTrue: [
			^ SmallTalkCondNode new: node
				    trueClause: (args at: 1)
				    falseClause: nil
				    table: symbols
				    pos: pos
		].
		selector == #ifFalse: ifTrue: [
			^ SmallTalkCondNode new: node
				    trueClause: nil
				    falseClause: (args at: 1)
				    table: symbols
				    pos: pos
		].
		selector == #and: ifTrue: [
			^ SmallTalkAndOrNode new: node
				    second: (args at: 1)
				    type: false
				    table: symbols
				    pos: pos
		].
		selector == #or: ifTrue: [
			^ SmallTalkAndOrNode new: node
				    second: (args at: 1)
				    type: true
				    table: symbols
				    pos: pos
		].
	].
	" Full if/else. "
	(argc == 2 and: [ b1 and: [ b2 ]]) ifTrue: [
		selector == #ifTrue:ifFalse: ifTrue: [
			^ SmallTalkCondNode new: node
				    trueClause: (args at: 1)
				    falseClause: (args at: 2)
				    table: symbols
				    pos: pos
		].
		selector == #ifFalse:ifTrue: ifTrue: [
			^ SmallTalkCondNode new: node
				    trueClause: (args at: 2)
				    falseClause: (args at: 1)
				    table: symbols
				    pos: pos
		].
	].
	
	node isSuper 
		ifTrue: [
			type <- #super.
			selector <- symbols addLit: selector forTerm: false ]
		ifFalse: [
	       		b1 <- specs associationAt: selector ifAbsent: [ nil ].
			b1 isNil
			        ifTrue: [
				   type <- #simple.
				   selector <- symbols addLit: selector
							   forTerm: false ]
				ifFalse: [
				   type <- #spec.
    				   selector <- SmallTalkLiteralNode 
								new: b1 key
								offset: b1 value
								table: self ].
		].
	^ self
!

stack: stack forEffect: result
	node stack: stack forEffect: false.
	args do: [ :a | a stack: stack forEffect: false ].
	stack pop: args size.
	result ifTrue: [ stack pop ].
!

sizeForEffect: result
	| c |
	c <- node sizeForEffect: false.
	args do: [ :a | c <- c + (a sizeForEffect: false) ].
	c <- c + 2.
	(type == #simple and: [ selector offset > 15 ]) ifTrue: [ c <- c + 1 ].
	(type == #super) ifTrue: [ c <- c + 1 ].
	result ifTrue: [ c <- c + 1 ].
	^ c
!

emitOn: aStream position: codePosition forEffect: result
	| opc off |
	node emitOn: aStream position: codePosition forEffect: false.
	args do: [ :a | a emitOn: aStream position: codePosition forEffect: false ].
	off <- selector offset.
	opc <- snd.
	type == #super
		ifTrue: [ 
			aStream nextPut: sdsup.
			aStream nextPut: off ]
		ifFalse: [
			type == #spec ifTrue: [ opc <- sdspc + off. off <- 0 ].
			self emitOpcode: aStream opc: opc offset: off
		].
	aStream nextPut: args size.
	codePosition at: aStream position put: pos.
	result ifTrue: [
		aStream nextPut: pop.
		codePosition at: aStream position put: pos
	].
! !

! SmallTalkMessageNode methodsFor: 'printing' !

printOn: aStream
	| sel s c t n |
	node isLeaf ifTrue: [ node printOn: aStream ]
		    ifFalse: [ aStream nextPutAll: '( '. 
			       node printOn: aStream.
			       aStream nextPutAll: ' )'].
	aStream nextPut: $ .
	" Split pattern into chunks. "
	sel <- OrderedCollection new.
	s <- ReadStream on: (selector node asString).
	t <- WriteStream on: (String new: 0).
	[ s atEnd ] whileFalse: [
		c <- s next.
		t nextPut: c.
		c == $: ifTrue: [
			sel add: t contents.
			t <- WriteStream on: (String new: 0).
		]
	].
	t isEmpty ifFalse: [ sel add: t contents ].
	s <- ReadStream on: sel.
	t <- ReadStream on: args.
	" Print out argument with selector. "
	[ t atEnd ] whileFalse: [
		aStream nextPutAll: s next.
		aStream nextPut: $ .
		n <- t next.
		n isLeaf ifTrue: [ n printOn: aStream ]
			ifFalse: [ aStream nextPutAll: '( '. 
				   n printOn: aStream.
				   aStream nextPutAll: ' )'].
		aStream nextPut: $ .
	].
	s atEnd ifFalse: [ aStream nextPutAll: s next ]
! !

SmallTalkMessageNode subclass: 'SmallTalkCascadeNode'
       instanceVariableNames: ''
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Compiler' !

! SmallTalkCascadeNode methodsFor: 'generation' !

optimize
	| sp |
	sp <- specs associationAt: selector ifAbsent: [ nil ].
	sp isNil
	    ifTrue: [
		   type <- #simple.
		   selector <- symbols addLit: selector forTerm: false ]
	    ifFalse: [
		   type <- #spec.
    		   selector <- SmallTalkLiteralNode 
						new: sp key
						offset: sp value
						table: self
						start: pos start
						end: pos end ].
	^ self
! !

! SmallTalkCascadeNode methodsFor: 'printing' !

printOn: aStream
	| sel s c t n |
	node printOn: aStream.
	aStream nextPutAll: '; '.
	sel <- OrderedCollection new.
	s <- ReadStream on: (selector node asString).
	t <- WriteStream on: (String new: 0).
	[ s atEnd ] whileFalse: [
		c <- s next.
		t nextPut: c.
		c == $: ifTrue: [
			sel add: t contents.
			t <- WriteStream on: (String new: 0).
		]
	].
	t isEmpty ifFalse: [ sel add: t contents ].
	s <- ReadStream on: sel.
	t <- ReadStream on: args.
	" Print out argument with selector. "
	[ t atEnd ] whileFalse: [
		aStream nextPutAll: s next.
	        aStream nextPut: $ .
		n <- t next.
		n isLeaf ifTrue: [ n printOn: aStream ]
			ifFalse: [ aStream nextPutAll: '( '. 
				   n printOn: aStream.
				   aStream nextPutAll: ' )'].
		aStream nextPut: $ .
	].
	s atEnd ifFalse: [ aStream nextPutAll: s next ]
! !

SmallTalkParseNode subclass: 'SmallTalkMethodNode'
       instanceVariableNames: 'hasreturn'
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Compiler' !

! SmallTalkMethodNode methodsFor: 'accessing' !

getInst
	^ (node at: (node size)) getInst
! !

! SmallTalkMethodNode methodsFor: 'modifying' !

init: aTable
	super init: OrderedCollection new table: aTable.
	hasreturn <- false.
!

add: aExpr
	hasreturn ifFalse: [ node add: aExpr ].
!

returned
	hasreturn <- true.
! !

! SmallTalkMethodNode methodsFor: 'testing' !

isGetInst
	| s |
	" We can only have one statement, and it has to be a return"
	(node size > 1 or: [ hasreturn not ]) ifTrue: [ ^ false ].
	^ (node at: 1) isGetInst
!

isSetInst
	| s v |
	"We can have one or two statements here, but have to have a return. "
	(node size > 2 or: [ hasreturn not ]) ifTrue: [ ^ false ].
	s <- node at: 1.
	" Check that it is an argument 1 "
	s isSetInst ifFalse: [ ^ false ].
	v <- s getInst.
	" Make sure last statement is a get instance and of same number "
	s <- node at: node size.
	(s isGetInst and: [ s getInst == v ]) ifTrue: [ ^ true ]
		  			      ifFalse: [ ^ false ].
! !

! SmallTalkMethodNode methodsFor: 'generation' !

stack: stack forEffect: result
	node do: [ :s | s stack: stack forEffect: true ].
!

sizeForEffect: result
	| c |
	c <- 0.
	node do: [ :s | c <- c + (s sizeForEffect: true) ].
	hasreturn ifFalse: [ c <- c + 1 ].
	^ c
!

emitOn: aStream position: codePosition forEffect: result
	| s |
	s <- node size.
	s > 1 ifTrue: [
		1 to: s - 1 do: 
			[ :i | (node at: i) emitOn: aStream position: codePosition forEffect: true ]
	].
	hasreturn ifTrue:
		 [ (node at: s) emitOn: aStream position: codePosition forEffect: true ]
		  ifFalse: 
		 [ s > 0 ifTrue: [
			(node at: s) emitOn: aStream position: codePosition forEffect: result].
		   result ifTrue: [ aStream nextPut: rets]
			  ifFalse: [ aStream nextPut: ret ]
		].
! !

! SmallTalkMethodNode methodsFor: 'printing' !

printOn: aStream
	" Print out body. "
	| s |
	s <- node size.
	s = 0 ifTrue: [ aStream nl. ^ self ].
	1 to: (s - 1) do: [ :i |
		(node at: i ) printOn: aStream.
		aStream nextPut: $. .
		aStream nl
	].
	" Print out last statment. "
	(node at: s) printOn: aStream.
	aStream nl.
! !

SmallTalkParseNode subclass: 'SmallTalkReturnNode'
       instanceVariableNames: ''
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Compiler' !

! SmallTalkReturnNode methodsFor: 'accessing' !

getInst
	^ node getInst
! !

! SmallTalkReturnNode methodsFor: 'testing' !

isGetInst
	^ node isGetInst
!

isSetInst
	^ node isSetInst
! !

! SmallTalkReturnNode methodsFor: 'generation' !

stack: stack forEffect: result
	node canReturn ifFalse: [
	    node stack: stack forEffect: false.
	    stack pop
	]
!

sizeForEffect: result
	^ node sizeForReturn
!

emitForReturn: aStream position: codePosition
	^ node emitForReturn: aStream position: codePosition
!

emitOn: aStream position: codePosition forEffect: result
	^ node emitForReturn: aStream position: codePosition
! !

! SmallTalkReturnNode methodsFor: 'printing' !

printOn: aStream
	aStream nextPutAll: '^ '.
	node printOn: aStream.
! !


Object subclass: 'SmallTalkSymbolTable'
       instanceVariableNames: 'syms tempcount argcount litcount class nilnode lits parser superSeen temps args'
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Compiler' !

! SmallTalkSymbolTable class methodsFor: 'creation' !

new: aClass using: aParser
	^ self new on: aClass using: aParser.
! !

! SmallTalkSymbolTable methodsFor: 'initialize' !

on: aClass using: aParser
    | offset |
    parser <- aParser.
    syms <- Dictionary new.
    class <- aClass.
    temps <- OrderedCollection new.
    args <- OrderedCollection new.

    " Add in builtin objects "
    self addSym: (SmallTalkBuiltinNode new: #self table: self).
    self addSym: (SmallTalkBuiltinNode new: #super table: self).
    self addSym: (SmallTalkBuiltinNode new: #true table: self).
    self addSym: (SmallTalkBuiltinNode new: #false table: self).
    self addSym: (SmallTalkBuiltinNode new: #thisContext table: self).
    nilnode <- (SmallTalkBuiltinNode new: #nil table: self).
    self addSym: nilnode.

    " Add in instance variables "
    class notNil ifTrue: [
         offset <- 0.
         class allInstVarNames do: [ :var |
	    self addSym: (SmallTalkVariableNode new: var
						type: #inst
					        offset: offset
						table: self).
	    offset <- offset + 1.
         ]
    ].
    lits <- OrderedCollection new.
    litcount <- 0.
    tempcount <- 0.
    argcount <- 0.
    superSeen <- false.
! !

! SmallTalkSymbolTable methodsFor: 'symbol table' !

" Add a symbol node "
addSym: aSym 
     | node sym |
     sym <- aSym name asSymbol.
     node <- syms associationAt: sym ifAbsent: [ nil ].
     node isNil 
     	ifFalse: [ ^ parser parseError: ((aSym name) , ' multiply defined'). ].
     syms at: sym put: aSym.
     ^ aSym 
!

" Add a new temp symbol table node. "
addTemp: aSym
     | sym |
     sym <- SmallTalkVariableNode new: aSym
				  type: #temp
				  offset: tempcount
				  table: self.
     tempcount <- tempcount + 1.
     temps add: aSym.
     ^ self addSym: sym.
!

" Add a argument node "
addArg: aSym
     | sym |
     sym <- SmallTalkVariableNode new: aSym
			 	  type: #arg
				  offset: argcount
				  table: self.
     argcount <- argcount + 1.
     args add: aSym.
     ^ self addSym: sym.
!

" add a literal into tree "
addLit: aValue forTerm: aBoolean
    | lit |
    " Check if it is constant value we can emit "
    (aBoolean and: [ aValue class == SmallInteger and: [
		aValue > -127 and: [aValue < 127 ]]]) ifTrue: [
    	     ^ SmallTalkConstantNode new: aValue
				    table: self ].
    lits do: [ :l | l node == aValue ifTrue: [ ^ l ]. ].
    lit <- lits add: (SmallTalkLiteralNode new: aValue
					   offset: litcount 
					   table: self).
    litcount <- litcount + 1.
    ^ lit
!

" Remove a symbol from symbol table "
removeSym: aSym
    | sym |
    sym <- aSym name asSymbol.
    syms removeKey: sym ifAbsent: [ ^ nil ].
!

" Lookup symbol in symbol table. "
findSymbol: aSym
    | var sym name temp |
    name <- aSym asSymbol.
    sym <- syms associationAt: name ifAbsent: [ nil ].

    sym notNil ifTrue: [
	sym value isSuper ifTrue: [ superSeen <- true ].
	 ^ sym value ].

    " See if it is a class variable "
    var <- nil.
    temp <- class.
    [ var isNil and: [ temp notNil ]] whileTrue: [
	(var <- temp classPool) notNil ifTrue: [
	    var <- var associationAt: name ifAbsent: [nil]].
        temp <- temp superclass.	"Walk up class chain "
    ]. 

    " See if it is a pool variable "
     var isNil ifTrue: [
        " See if it is a shared pool "
        class allSharedPools do: [ :pool |
  	  var <- Smalltalk at: pool ifAbsent: [nil].
	  var notNil ifTrue: [
	      var <- var associationAt: name ifAbsent: [ nil ].
	  ] 
	]
    ].

    " If not found try Smalltalk dictionary "
    var isNil ifTrue: [
	 var <-  Smalltalk associationAt: name ifAbsent: [nil]].
    
    " If we found something, add it in "
    var notNil ifTrue: [
	temp <- self addLit: var forTerm: false.
	^ syms at: name put: (SmallTalkVariableNode new: name 
						    type: #var
						    offset: temp
						    table: self).
    ].
    ^ parser parseError: ('Unable to find symbol ' , (name asString)).
! !

! SmallTalkSymbolTable methodsFor: 'accessing' !

tempvars
	^ temps
!

arguments
	^ args
!

nilnode
	^ nilnode
!

litcount
	^ litcount
!

argcount
	^ argcount
!

tempcount
	^ tempcount
!

literals
	superSeen ifTrue: [
		litcount <- litcount + 1.
    		lits add: (SmallTalkLiteralNode new: class superclass 
					        offset: litcount 
						table: self).
		superSeen <- false.
	].
	^ lits
! !

Object subclass: 'SmallTalkParser'
       instanceVariableNames: 'table token class primitive pattern inBlock method error notifier compileString codePosition'
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Compiler' !

! SmallTalkParser class methodsFor: 'creation' !

on: aString forClass: aClass msgpattern: patFlag notify: aBlock
	^ self new on: aString 
		 forClass: aClass
		 msgpattern: patFlag
		 notify: aBlock
! !

! SmallTalkParser methodsFor: 'initialize' !

on: aString forClass: aClass msgpattern: patFlag notify: aBlock
    | tree bytecodes header eheader litcount stack lits |
    table <- SmallTalkSymbolTable new: aClass using: self.
    compileString <- aString.
    pattern <- nil.
    inBlock <- false.
    method <- nil.
    primitive <- 0.
    notifier <- aBlock.
    codePosition <- Dictionary new.

    " Initialize token stream "
    token <- SmallTalkToken on: aString.
    token next.
 
    " Collect the message pattern if we should "
    patFlag ifTrue: [
	 pattern <- self messagePattern.
	 pattern isNil ifTrue: [  ^ self ]
    ].

    " Collect any temporiaries "
    self temporiaries ifFalse: [  ^ self ].

    " Check if primitive method. "
    self parsePrimitive ifFalse: [  ^ self ].

    " Compile the rest of method "
    tree <- SmallTalkMethodNode new: table.
    (self doBody: tree) isNil ifTrue: [  ^ self ].
    token <- nil.


    " Check if we can shortcut this method "
    table tempcount = 0 ifTrue: [
	tree isSetInst ifTrue: [
		method <- CompiledMethod newMethod: 0
				 header: ((tree getInst * 256) + 16r38000000).
	        ^ self ].
	tree isGetInst ifTrue: [ 
		method <- CompiledMethod newMethod: 0
				 header: ((tree getInst * 256) + 16r34000000).
		^ self ]
    ].

    " Compute size of stack required "
    stack <- SmallTalkParseStack new.
    tree stack: stack forEffect: true.
    lits <- table literals.
    litcount <- lits size.
    (primitive > 0 or: [ table argcount > 12 ]) ifTrue: [ 
        header <- litcount + 1 + (table tempcount bitShift: 8) +
		   (stack stacksize bitShift: 16) + 16r3C000000.
	eheader <- primitive + (table argcount bitShift: 16).
    ] ifFalse: [
        header <- litcount + (table tempcount bitShift: 8) + 
		   (stack stacksize bitShift: 16) +
		   (table argcount bitShift: 26).
	eheader <- nil.
    ].

    " Convert code into byte codes. "
    bytecodes <- WriteStream on: (ByteArray new: 0).
    tree emitOn: bytecodes position: codePosition forEffect: patFlag.
    tree <- nil.	" Clean it up since we don't need it anymore "
    bytecodes <- bytecodes contents.

    " Build method "
    method <- CompiledMethod newMethod: bytecodes size header: header.
    1 to: litcount do: [ :i |
	 method objectAt: (i + 1) put: ((lits at: i) node)].
    eheader notNil ifTrue: [ method objectAt: (litcount + 2)
				         put: eheader ].
    " Copy over code "
    1 to: bytecodes size do: [ :i | method byteAt: i put: (bytecodes at: i)].
    ^ self
!

parseError: aMessage
    | pos |
    notifier isNil ifTrue: [ notifier <- SyntaxError ].
    notifier error: aMessage at: token first on: compileString.
    ^ nil
! !

! SmallTalkParser methodsFor: 'access'!

tempvars
    ^ table tempvars
!

arguments
    ^ table arguments
!

codePosition
    ^ codePosition
!

method
    ^ method
!

pattern
    ^ pattern
!

error
    ^ error

! !

! SmallTalkParser methodsFor: 'parsing' !

" Parse the message pattern. "
messagePattern
    | pat |
    token isKeyName ifTrue: [ ^ token valueNext asSymbol ].
    token isKeyKeyword ifTrue: [
	 pat <- token valueNext.
	 [ token isKeyName ] whileTrue: [
		table addArg: token valueNext.
		token isKeyKeyword ifFalse: [ ^ pat asSymbol ].
		pat <- pat , (token valueNext).
	 ].
         ^ self parseError: 'Keyword message pattern not followed by a name'  ].
     token isKeySpecial ifTrue: [
	pat <- token valueNext. 
	token isKeyName 
           ifFalse: [ ^ self parseError: 'Binary not followed by name' ].
	table addArg: token valueNext.
	^ pat asSymbol ].
     ^ self parseError: 'Illegal message selector' 
!

" Parse temporaries.   "
temporiaries
    token isVarSep ifTrue: [
	token next.
	[ token isKeyName ] whileTrue: [ table addTemp: token valueNext ].
	token isVarSep ifFalse: [
	        self parseError: 'Needs to be name or |'.
		^ false ].
	token next.
    ].
    ^ true
!

" Parse a primitive declaration. "
parsePrimitive
    (token isKeySpecial and: [token value = '<']) ifTrue: [
	" Handle Primitive "
	(token next isKeyName and: [token value = 'primitive' ]) ifTrue: [
	    (token next isKeyLiteral and:
			 [ token value class == SmallInteger ]) ifTrue: [
		primitive <- token value.
		(token next isKeySpecial and: [ token value = '>' ]) ifTrue: [
			token next.
			^ true
		]
            ]
        ].
	self parseError: 'Invalid primitive'.
	^ false
    ].
    ^ true
!

" Parse body of definition. "
doBody:	nodes
    | result sawperiod start |
    result <- true.
    [ result isNil ] whileFalse: [
        sawperiod <- false.
	token isKeyReturn ifTrue: [
		start <- token first.
		token next.
		result <- self doExpression.
		result isNil ifTrue: [ 
			^self parseError: 'Return needs expression' ].
		result end: token first.
		nodes add: (SmallTalkReturnNode
				 new: result 
				 table: table
				 start: start
				 end: token first).
		nodes returned
	] ifFalse: [
		result <- self doExpression.
		result isNil ifFalse: [ nodes add: result ]
	].

        token isKeyPeriod ifTrue: [ 
		sawperiod <- true.
		token next
	].

	token isKeyEOS ifTrue: [ ^ nodes ].
	token isKeyRBrack ifTrue: [
	        inBlock ifFalse: [ ^ self parseError: 'Extra ]' ].
		sawperiod ifTrue: [ nodes add: table nilnode ].
   	       ^ nodes 
        ].
   ].
   ^ self parseError: 'Invalid statement ending'. 
!

" Parse Expression. "
doExpression
    | asgname node start |

    token isKeyName ifTrue: [
    	start <- token first.
	node <- token value.
	asgname <- table findSymbol: token valueNext.
	asgname isNil ifTrue: [
		^ self parseError: 'Invalid name before ', node.
	].
	token isKeyAssign ifTrue: [
	    asgname canStore ifFalse: [
            	^ self parseError: 'Invalid assignment name ' ,
							 (asgname name).
	    ].
	    token next.
	    node <- self doExpression.
	    node isNil ifTrue: [ ^ nil ].
	    node <- SmallTalkAssignNode new: asgname 
					expr: node	
					table: table
					start: start
					end: token first.
 	    ^ node
        ] ifFalse: [
	    node <- asgname
	]
    ] ifFalse: [ node <- self doTerm ].
    node isNil ifTrue: [ ^ nil ].
    (token isKeyKeyword or: [ token isKeySpecial or: [ token isKeyName ]])
	ifTrue: [ ^self doContinue: node ]
	ifFalse: [ ^node ]
!

" Parse a term. "
doTerm
    | node start end |

    token isKeyLiteral ifTrue: [  
	  start <- token first.
	  end <- token position.
	  node <- table addLit: token valueNext forTerm: true.
	  ^ SmallTalkTermNode new: node start: start end: end.
	  ].
    token isKeyName ifTrue: [ 
	  start <- token first.
	  end <- token position.
	  node <- table findSymbol: token valueNext.
	  ^ SmallTalkTermNode new: node start: start end: end.
	  ].
    token isKeyLBrack ifTrue: [ ^self doBlock ].
    token isKeyRParen ifTrue: [
	  token next.
          node <- self doExpression.
	  node isNil ifTrue: [ ^ nil ].
	  node end: token first.
	  token isKeyLParen ifFalse: [ ^ self parseError: 'Missing )' ].
	  token next.
	  ^ node
    ].
    ^ nil
!

" Handle rest of expression.
  message expression or
  message expression ; message expression "
doContinue: aNode
   | node other |
    node <- SmallTalkMessageNode new: aNode table: table start: token first.
    node <- self keyContinue: node.
    node isNil ifTrue: [ ^ nil ].
    node <- node node.
    node end: token first.
    [ token isKeyCascade ] whileTrue: [
	token next.
	node canCascade ifFalse: [
		^ self parseError: 'Unable to cascade message' ].
	node <- SmallTalkCascadeNode new: node table: table start: token first.
	node <- self keyContinue: node.
        node isNil ifTrue: [ ^ nil ].
	node <- node node.
	node end: token first
    ].
    ^ node
!

" Handle keyword continuation. "
keyContinue: aNode
    | node arg pat flag |

    node <- self doBinaryContinue: aNode.
    node isNil ifTrue: [ ^ nil ].
    pat <- WriteStream on: (String new: 0).
    flag <- false.
    [ token isKeyKeyword ] whileTrue: [
	flag <- true.
	pat nextPutAll: (token valueNext).
	arg <- self doTerm.
	arg isNil ifTrue: [ ^ nil ].
	arg end: token first.
	arg <- SmallTalkMessageNode new: arg table: table start: token first.
	arg <- self doBinaryContinue: arg.
	node addArg: arg node
    ].
    flag ifTrue: [
	    node selector: pat contents asSymbol.
	    node end: token first.
	    node <- node optimize.
	    node <- SmallTalkMessageNode new: node table: table
			 start: token first
    ].
    node end: token first.
    ^ node
!

" Handle binary continuation "
doBinaryContinue: aNode
    | node arg |

    node <- self doUnaryContinue: aNode.
    node isNil ifTrue: [ ^ nil ].
    node end: token first.
    [ token isKeySpecial ] whileTrue: [
	" Set nodes selector to current token "
	node selector: token valueNext asSymbol.
	" If there is any names following build messages "
	arg <- self doTerm.
	arg isNil ifTrue: [ ^ nil ].
	arg <- SmallTalkMessageNode new: arg table: table start: token first.
	arg <- self doUnaryContinue: arg.
	" Add argument and optimize node. "
	node addArg: arg node.
	node end: token first.
	node <- node optimize.
	" Wrap in new message node "
	node <- SmallTalkMessageNode new: node table: table start: token first
    ].
    node end: token first.
    ^ node
!

" Handle unary continuations. "
doUnaryContinue: aNode
    | node |
 
    aNode isNil ifTrue: [ ^ nil ].
    node <- aNode.
    [ token isKeyName ] whileTrue: [
	node end: token first.
	node selector: token valueNext asSymbol.
	node <- node optimize.
	node <- SmallTalkMessageNode new: node table: table start: token first
    ].
    node end: token first.
    ^ node
!

" Parse a block of code. "
doBlock
    | argc saveInblock node args |
    node <- SmallTalkBlockNode new: table start: token first.

    token next.
    [ token isKeyVariable ] whileTrue: [ 
	node addArg: (table addTemp: token valueNext)
    ].

    argc <- node argcount.

    " Build node block. "
    token isVarSep ifTrue: [
	argc = 0 ifTrue: [ ^ self parseError: 'No arguments defined.' ].
	token next.
    ] ifFalse: [
	argc > 0 ifTrue: [ ^ self parseError: 'Need var seperator' ]
    ].

    " Do body of block "
    saveInblock <- inBlock.
    inBlock <- true.
    (self doBody: node) isNil ifTrue: [ ^ nil ].
    inBlock <- saveInblock.

    " Clean out symbols defined after offset. "
    node cleanSymbols.

    " Make sure we consumed a correct block "
    token isKeyRBrack ifFalse:
		 [ ^ self parseError: 'Block must end with ]' ].
    node end: token first.
    token next.
    ^ node
! !

Object subclass: 'Compiler'
       instanceVariableNames: ''
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Compiler' !

! Compiler class methodsFor: 'creation'!

evaluate: aString
    | comp |
    stderr nextPutAll: aString.
    stderr nl.
    comp <- SmallTalkParser on: aString
			 forClass: Object
			 msgpattern: false
			 notify: nil.
    comp method isNil ifFalse: [ ^ comp method evaluate  ]
	       ifTrue: [ ^ nil ].
!

evaluate: aString forClass: aClass notify: aBlock
    | comp |
    comp <- SmallTalkParser on: aString
			 forClass: aClass
			 msgpattern: false
			 notify: aBlock
    comp method isNil ifFalse: [ ^ comp method evaluate  ]
	       ifTrue: [ ^ nil ].
!

compile: aString forClass: aClass
    ^ self compile: aString forClass: aClass classified: nil notify: nil
!

compile: aString forClass: aClass classified: aCategory
    ^ self compile: aString forClass: aClass classified: aCategory notify: nil
!

compile: aString forClass: aClass classified: aCategory notify: aBlock
    | comp oldmeth oldsource |
    comp <- SmallTalkParser on: aString
			   forClass: aClass
			   msgpattern: true
			   notify: aBlock.
    comp method isNil ifFalse: [
	   " Retrieve old method and see if it is same as current "
	   oldmeth <- aClass compiledMethodAt: comp pattern.
	   
	   " If we got one, compare source and category "
	   oldmeth isNil ifFalse: [
		oldsource <- oldmeth getSource.
		(oldmeth description category = aCategory 
				and: [ oldsource = aString])
			" Different, just clear variable "
			ifFalse: [ oldmeth <- nil ]
	   ].

	   " If it is null, then make new node, otherwise us old one "
	   oldmeth isNil ifTrue: [
 	        comp method description:
		    (MethodInfo sourceCode: aString
			          forClass: aClass
			       forCategory: aCategory)
	   ] ifFalse: [
		comp method description: oldmeth description
	   ].

	   " Update selector "
	   aClass addSelector: comp pattern
       		    withMethod: comp method
       		    classified: aCategory.
    ]
! !

"Object variableSubclass: 'CompiledMethod'
       instanceVariableNames: 'description header'
       classVariableNames: ''
       poolDictionaries: ''
       category: 'Compiled-Methods' "
Object addSubclass: CompiledMethod !

CompiledMethod category: 'Compiled-Methods' !

! CompiledMethod methodsFor: 'evaluation' !

evaluate
	<primitive 100>
	^ self primitiveFailed
! !

! CompiledMethod class methodsFor: 'creation' !

newMethod: size header: aHeader
	<primitive 64>
	^ self primitiveFailed
! !

! CompiledMethod methodsFor: 'accessing' !

objectAt: aIndex
	<primitive 53>
	^ self primitiveFailed
!

byteAt: aIndex
	<primitive 103>
	^ self primitiveFailed
!

header
	^ self objectAt: 1
!

literals
	^ self header bitAnd: 16rFF
!

temporaries
	^ (self header bitShift: -8) bitAnd: 16rFF
!

stacksize
	^ (self header bitShift: -16) bitAnd: 16r3FF
!

flags
	^ (self header bitShift: -26) bitAnd: 16rF
!

primitiveOf
	self flags = 16rF
	     ifTrue: [ ^ (self objectAt: (self literals + 1)) bitAnd: 16r1FF ]
	     ifFalse: [ ^ 0 ]
!
	
argcount
	| temp |
	temp <- self flags.
	temp < 16rD ifTrue: [ ^ temp ].
	temp = 16rF 
	     ifTrue: [ ^ ((self objectAt: (self literals + 1)) 
			bitShift: -16) bitAnd: 16rFF ].
	temp = 16rE ifTrue: [ ^ 1 ].
	^ 0
!

description
	^ description
!

" Returns number of bytecodes in method "
bytecodes
	<primitive 105>
	^ self primitiveFailed
! !

! CompiledMethod methodsFor: 'source access' !

getSource
	^ description sourceCode
! !

! CompiledMethod methodsFor: 'modifying' !

objectAt: aIndex put: aValue
	<primitive 54>
	^ self primitiveFailed
!

byteAt: aIndex put: aValue
	<primitive 104>
	^ self primitiveFailed
!

description: aMethInfo
	^ description <- aMethInfo
! !

! CompiledMethod methodsFor: 'printing' !

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
	basic <- #( jmpl pshtmp rettmp sttmp psharg pshlit pshinst
		    stinst jmpt jmpf jmp sndspc sndspc2 pshint sndlit blk
		    retself rettos rettrue retfalse retnil retblk pop pshvar
		    pshself dup pshtrue pshfalse pshnil sndsup pshctx stvar).
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
				" Variable operate inst or send super"
				(op = 23 or: [op = 32 or: [op = 29 ]]) ifTrue: [
			    		opr <- self byteAt: (byte + 1).
			    		len <- 2.
				] ifFalse: [
					opr <- nil
				]
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
		" Convert short constant "
		(op = 13 and: [opr > 8 and: [ opr < 16 ]]) ifTrue: [
			opr <- opr - 16 ].
		" Convert jump argument to bytecode index "
		(op = 8 or: [ op = 9 or: [ op = 10 or: [ op = 13]]]) ifTrue: [
			opr > 127 ifTrue: [ opr <- opr - 256 ]].
		(op = 0 or: [op = 8 or: [ op = 9 or: [ op = 10 ]]]) ifTrue: [
			opr <- byte + len + opr ].
		aStream nextPutAll: ' Byte '.
		byte printOn: aStream.
		aStream nextPutAll: ':  '.
		(basic at: (op + 1)) printOn: aStream.
		opr notNil ifTrue: [
		    aStream nextPutAll: '  '.
		    opr printOn: aStream.
		    " Handle sends "
		    (op = 11 or: [ op = 14 or: [ op = 29]]) ifTrue: [
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

