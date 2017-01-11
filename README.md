This is a clone of Smalltalk 80 from the Blue book. I have decided
to release this under the "Artistic License". Note this will only run
in 32 bit mode. It would require changes to the object memory system
to run correctly in 64 bit more.

I have made several changes. First I have simplified the VM system,
it now only has a few instructions. This is designed to run 
on either Windows or Xwindows. There is a graphics interface
however the graphics system is not complete. I have decided
to make this available to those who might be interested in 
playing with it. Currently the system will load and self compile.


The system consists of a C level compiler which loads in the
file boot.st. This file is constructed from "basic.st stream.st
collection.st magnitude.st compile.st behavior.st system.st boottail.st".
The last file "boottail.st", will open up "source.st" which is
constructed from all the smalltalk source files. The boot.st file
is compiled using the built in C compiler, the last file is a
program that will load in the full system. The full system includes
a native language Smalltalk compiler and change file support. Debugging
code is generated, however it is untested. Lastly a snapshot is taken 
to create a system image, and the system quits.

  In the current runing system "#newSourceFile:" switches the source
file to the argument and calls "System snapshot" which saves a image.
In the currently running system this returns "#true". When the system
restarts it returns "#false". 

  Some limitations of the system is that arguments can't be modified. 
And there can only be 256 Temps, Literals, Arguments, or Instance variables.

The virtual machine I have implemented:  

 The machine encodes opcodes as follows:   

       (Byte)  
       <High half><Lower half>  
   The <High half> gives the basic opcode. 0 and 0xF are special.  
   The <Lower half> gives the operand. If the Opcode is 0, then
   the <Lower half> gives the opcode and the next byte gives the operand.
   0xF are for instructions that don't require an operand.

   0x1 Push Temp n onto stack.  
   0x2 Return with Temp n.  
   0x3 Store Temp n.
   0x4 Push Argument n.  
   0x5 Push Literal n.
   0x6 Push Instance Variable n.
   0x7 Store Instance Variable n.
   0x8 Jump if top of stack true to n. (relative -127 to 128).
   0x9 Jump if top of stack false to n. (relative -127 to 128).
   0xA Jump to n. (relative -127 to 128).
   0xB&0xC Send special selector n (0-32), argument count c.  
          see init.c for list of selectors.  
   0xD Push interger object n. (-7 to 8) or (-127 to 128).
   0xE Send Literal n with argument count c.

   0x00 is special long jump, which takes next two bytes as 15 bit
     signed offset to branch to.

   0x0F is Block Copy, explained below.

   0xF0 Return self.
   0xF1 Return top of stack.
   0xF2 Return #true.
   0xF3 Return #false.
   0xF4 Return #nil.
   0xF5 Return block.
   0xF6 Pop top of stack.
   0xF7 Push Global variable given by literal n.  
   0xF8 Push self.
   0xF9 Duplicate top of stack.
   0xFA Push #true.
   0xFB Push #false.
   0xFC Push #nil.
   0xFD Send Superclass message n argcount c..
   0xFE Push #thisContext.
   0xFF Store Global variable given by literal n.

Block copy expects the instruction stream to be in a specific
format. Failure to do this will result in crashing system.

   0X0F <Block Copy>
   <Argument Count>  
   Either <0xAn> or <0x0A n> or <0x00 n n> Jump instrution to 
end of block.  
   Block of code.  
<n:> Points here.  

   The jump instructions is never executed, but the program counter is
changed by the BlockCopy Instruction.  

  Note the Bytecode compiler will translate the following structures:

   [ blockc ] whileTrue: [ block ]
   [ blockc ] whileFalse: [ block ]  

   expr ifTrue: [ block ]
   expr ifFalse: [ block ]
   expr ifTrue: [ block ] ifFalse: [ block ]
   expr ifFalse: [ block ] ifTrue: [ block ]

   expr and: [ block ]
   expr or: [ block ]

   If the block can't be skipped with 8 bytes, a full conditional branch
is generated. If the block can't be skip in 128 bytes, the condition is
reversed and a long jump is generated. These blocks are not generated as
blocks unless they have arguments.

   Methods of the type:  

    method  
     ^ instance  

   or  
    method: arg  
      instance <- arg  

  Are compiled into the header and require no new context creation to be
executed. 

 Smalltalk memory is allocated in chunks, and garbage collected within
these chunks. Object pointers are 32 bits, integers have the lower bit
set. The optional argument -o # sets the number of objects in the system
times 1024. The current default is 512k objects. Changing this requires
reloading the system from scratch since the Object table size is saved
in the snapshot. Objects are saved in a byte order neutral format so 
images can be transfered between platforms without any problems.
