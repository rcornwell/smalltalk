/*
 * Smalltalk interpreter: Object Dumper.
 *
 * $Id: dump.h,v 1.1 1999/09/02 15:57:59 rich Exp rich $
 *
 * $Log: dump.h,v $
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */

#undef TRACE_INST
#undef SHOW_EXEC
#undef SHOW_METHODS
#undef TRACE_SEND
#undef SHOW_SOURCE
#undef DUMP_OBJMEM
#undef DUMP_CODETREE

char		   *dump_object_value(Objptr);
void                dump_otable();
void                dump_object(int);
void                dump_objects();
void		    dump_method(Objptr);
void                dump_token(int, void *);
void		    dump_inst(Objptr, int, int, int, Objptr, int);
void		    dump_setinst(Objptr, int, Objptr);
void		    dump_getinst(Objptr, int, Objptr);
void		    dump_primitive(int, int);
void		    dump_send(Objptr, Objptr, Objptr);
void		    dump_str(char *, Objptr);
void		    dump_code(void *);
#ifdef SHOW_SOURCE
#define show_source(a)		dump_string(a)
#else
#define show_source(a)
#endif
#ifdef SHOW_METHODS
#define show_method(a)		dump_method(a)
#else
#define show_method(a)
#endif
#ifdef SHOW_EXEC
#define show_exec(a)		dump_method(a)
#else
#define show_exec(a)
#endif
#ifdef SHOW_TOKEN
#define show_token(a, b)	dump_token(a, b)
#else
#define show_token(a)
#endif
#ifdef TRACE_INST
#define trace_inst(a, b, c, d, e, f) dump_inst(a, b, c, d, e, f)
#define trace_getinst(a, b, c)	dump_getinst(a, b, c)
#define trace_setinst(a, b, c)	dump_setinst(a, b, c)
#define trace_primitive(a, b)	dump_primitive(a, b)
#else
#define trace_inst(a, b, c, d, e, f)
#define trace_getinst(a, b, c)
#define trace_setinst(a, b, c)
#define trace_primitive(a, b)
#endif
#ifdef TRACE_SEND
#define trace_send(a, b, c) dump_send(a, b, c)
#else
#define trace_send(a, b, c)
#endif
#ifdef DUMP_OBJMEM
#define dump_objstring(a)	dump_string(a)
#else
#define dump_objstring(a)
#endif
#ifdef DUMP_CODETREE
#define show_code(a)		dump_code(a)
#else
#define show_code(a)
#endif
