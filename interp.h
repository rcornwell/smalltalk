
/*
 * Smalltalk interpreter: Main byte code interpriter.
 *
 * $Id: interp.h,v 1.8 2002/01/29 16:40:38 rich Exp rich $
 *
 * $Log: interp.h,v $
 * Revision 1.8  2002/01/29 16:40:38  rich
 * Increased size of event queue.
 *
 * Revision 1.7  2001/08/18 16:17:01  rich
 * Fixed bugs in process management functions.
 * Added queue functions to improve communication from system to image.
 *
 * Revision 1.6  2001/08/01 16:42:31  rich
 * Added Pshint instruction.
 * Moved sendsuper to group 2.
 * Added psh context instruction.
 *
 * Revision 1.5  2001/07/31 14:09:48  rich
 * Reorganized instructions.
 *
 * Revision 1.4  2001/01/17 01:46:03  rich
 * Added routine to send error message.
 *
 * Revision 1.3  2000/02/23 00:14:39  rich
 * Moved Dump_stack here.
 *
 * Revision 1.2  2000/02/01 18:09:53  rich
 * Added stack checking to push and pop.
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */

/* Byte codes are as follows */
#define LONGOP			0x00
#define PSHTMP			0x10
#define RETTMP			0x20
#define STRTMP			0x30
#define PSHARG			0x40
#define PSHLIT			0x50
#define PSHINST			0x60
#define STRINST			0x70
#define JMPT			0x80
#define JMPF			0x90
#define JMP			0xA0
#define SNDSPC1			0xB0
#define SNDSPC2			0xC0
#define PSHINT			0xD0
#define SNDLIT			0xE0
#define GRP2			0xF0
#define JMPLNG			0x00
#define BLKCPY			0x0F

/* Group two opers */
#define RETSELF			0xF0
#define RETTOS			0xF1
#define RETTRUE			0xF2
#define RETFALS			0xF3
#define RETNIL			0xF4
#define RETBLK			0xF5
#define POPSTK			0xF6
#define PSHVAR			0xF7
#define PSHSELF			0xF8
#define DUPTOS			0xF9
#define PSHTRUE			0xFA
#define PSHFALS			0xFB
#define PSHNIL			0xFC
#define SNDSUP			0xFD
#define PSHCTX			0xFE
#define STRVAR			0xFF

typedef struct _method_Cache {
    Objptr              select;
    Objptr              class;
    Objptr              method;
    Objptr              header;
} method_Cache     , *Method_Cache;

typedef struct _queue {
    Objptr		data[1024];
    Objptr		*rdptr;
    Objptr		*wrptr;
    Objptr		*top;
} event_queue	   , *Event_queue;

#define Push(obj) { if (stack_pointer == BLOCK_STACK)  {	  \
			int tstack = stack_pointer;		  \
			SendError(InterpStackFault, &tstack);     \
			stack_pointer = tstack;			  \
		    } else  					  \
		        Set_object(current_context, --stack_pointer, obj); \
		  }

#define TopStack() get_pointer(current_context, stack_pointer)

#define GetInteger(off) as_integer(get_pointer(current_context, off))

#define Literal(off) (((Objptr *)methodPointer)[METH_LITSTART + off])

#define PopStack() { if (stack_pointer == stack_top) {	 	  \
			int tstack = stack_pointer;		  \
			SendError(InterpStackFault, &tstack);     \
			stack_pointer = tstack;			  \
		      } else  					  \
			Set_object(current_context, stack_pointer++, NilPtr); \
		    }

#define SendMethod(selector, stack, args) \
    SendToClass((selector), (stack), (args), \
	    class_of(get_pointer(current_context, *(stack) + (args))))


extern Objptr       current_context;
extern int          running;
extern int          compiling;
extern int          newContextFlag;

extern int          newProcessWaiting;
extern Objptr       newProcess;
extern event_queue  asyncsigs;

#define isEmptyList(aList) (get_pointer(aList, LINK_FIRST) == NilPtr)

#define asynchronusSignal(aSemaphore) \
	 add_event(&asyncsigs, aSemaphore)

#define schedulerPointer SchedulerAssociationPointer

#define activeProcess (newProcessWaiting? newProcess: \
		 get_pointer(schedulerPointer, SCHED_INDEX))

#define sleep(aProcess)  addLinkLast(get_pointer(\
			    get_pointer(schedulerPointer, SCHED_LIST), \
			    as_integer(get_pointer(aProcess, PROC_PRIO))-1), \
			    aProcess)

#define transferTo(aProcess) \
	newProcess = (aProcess); \
	rootObjects[NEWPROC] = newProcess; \
	newProcessWaiting = 1;  

#define suspendActive transferTo(wakeHighestPriority())

#define is_empty(queue) (queue)->rdptr == (queue)->wrptr

void		    execute(Objptr, Objptr);
void		    SendToClass(Objptr, int *, int, Objptr);
void		    dump_stack(Objptr);
void                interp();
void                synchronusSignal(Objptr);
void                checkProcessSwitch();
Objptr              removeFirstLinkOf(Objptr);
void                addLinkLast(Objptr, Objptr);
Objptr              wakeHighestPriority();
void                resume(Objptr);
void                wait(Objptr);
void                signal_console(Objptr);
void                wait_console(Objptr);
void		    SendError(Objptr, int *);
void		    flushMethod(Objptr);
void		    flushCache(Objptr);
void		    init_event(Event_queue);
void		    add_event(Event_queue, Objptr);
Objptr		    nxt_event(Event_queue);
