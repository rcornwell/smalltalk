/*
 * Smalltalk interpreter: Parser.
 *
 * $Id: $
 *
 * $Log: $
 *
 */  

enum code_type {
    Push, Store, Return, Send, Jump, JTrue, JFalse, BlockCopy, Duplicate,
    PopStack, SuperSend, CodeBlock, SendSpec, Break, Nop
};


#define	CODE_LABEL	01	/* Flag to say code element is a label */
/*
 * This structure holds the code chunks as they are built by the compiler.
 */ 
typedef struct _codenode {
    struct _codenode   *next;
    enum code_type      type;
    enum oper_type      oper;
    int                 len;
    int                 offset;
    int                 flags;
    int                 argcount;
    union {
	char               *codeblock;
	struct _codenode   *jump;
        Literalnode	    literal;
        Symbolnode	    symbol;
	int                 operand;
    } u;
} codenode         , *Codenode;

typedef struct _codestate {
    Codenode		code;
    Codenode		last;
    int			maxstack;
    int			curstack;
} codestate, *Codestate;


Codestate	    newCode();
void		    freeCode(Codestate cstate);
Codenode	    genCode(Codestate cstate, enum code_type type, enum oper_type oper, int amount);
void                genStore(Codestate cstate, Symbolnode sym);
void                genPushLit(Codestate cstate, Literalnode lit);
void                genPush(Codestate cstate, Symbolnode sym);
void                genSend(Codestate cstate, Literalnode lit, int argc,
				 int superFlag);
Codenode	    genBlockCopy(Codestate cstate, int argc);
void                genJump(Codestate cstate, Codenode label);
void                setJumpTarget(Codestate cstate, Codenode label);
int                 optimize(Codestate cstate);
void                genblock(Codestate cstate);


/* Generate Empty location */
#define genNop(cstate) genCode(cstate, Nop, Nil, 0)

/* Generate push nil opcode.  */
#define genPushNil(cstate) genCode(cstate, Push, Nil, 1)

/* Generate return nil opcode.  */
#define genReturnNil(cstate) genCode(cstate, Return, Nil, 0)

/* Generate return Top of stack opcode.  */
#define genReturnTOS(cstate) genCode(cstate, Return, Stack, -1)

#define genPopTOS(cstate) genCode(cstate, PopStack, Stack, -1)

#define genDupTOS(cstate) genCode(cstate, Duplicate, Stack, 1)

#define genJumpForw(cstate) genCode(cstate, Jump, Label, 0)

#define genJumpFForw(cstate) genCode(cstate, JFalse, Label, -1)

#define genJumpTForw(cstate) genCode(cstate, JTrue, Label, -1)

#define getCodeLabel(cstate) (cstate->last)

