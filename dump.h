/*
 * Smalltalk interpreter: Object Dumper.
 *
 * Copyright 1999-2017 Richard P. Cornwell.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the the Artistic License (2.0). You may obtain a copy
 * of the full license at:
 *
 * http://www.perlfoundation.org/artistic_license_2_0
 *
 * Any use, modification, and distribution of the Standard or Modified
 * Versions is governed by this Artistic License. By using, modifying or
 * distributing the Package, you accept this license. Do not use, modify, or
 * distribute the Package, if you do not accept this license.
 *
 * If your Modified Version has been derived from a Modified Version made by
 * someone other than you, you are nevertheless required to ensure that your
 * Modified Version complies with the requirements of this license.
 *
 * This license does not grant you the right to use any trademark, service
 * mark, tradename, or logo of the Copyright Holder.
 *
 * Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
 * AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 * PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
 * YOUR LOCAL LAW.  UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
 * CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
 * CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * $Id: dump.h,v 1.4 2001/02/05 03:44:37 rich Exp rich $
 *
 * $Log: dump.h,v $
 * Revision 1.4  2001/02/05 03:44:37  rich
 * Code cleanup
 *
 * Revision 1.3  2000/03/05 17:25:31  rich
 * Exported dump_class_name
 *
 * Revision 1.2  2000/02/01 18:09:50  rich
 * Error tracing is now controlled via flags.
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */

#undef TRACE_INST
#undef TRACE_SEND
#undef SHOW_EXEC
#undef SHOW_METHODS
#undef SHOW_SOURCE
#undef DUMP_OBJMEM
#undef DUMP_CODETREE

char		   *dump_class_name(Objptr);
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
#else
#define trace_inst(a, b, c, d, e, f)
#define trace_getinst(a, b, c)
#define trace_setinst(a, b, c)
#endif
#ifdef TRACE_SEND
#define trace_send(a, b, c) dump_send(a, b, c)
#define trace_primitive(a, b)	dump_primitive(a, b)
#else
#define trace_send(a, b, c)
#define trace_primitive(a, b)
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
