#ifndef Debug_hh_
#define Debug_hh_

#ifdef IML_DEBUG

#include "AssertionFailedException.hh"

/**
 * DBGWRAP(static LogAdapter LOG);
 * DBGWRAP(HogeHogeClass::LOG = LogAdaptor("HogeHogeClass"));
 * DBGWRAP(int i = 0);
 * DBGWRAP(cost char* method = "getValue");
 * DBGWRAP(LOG.enter(method));
 * DBGWRAP((statementA, statementB, statementC));
 */
#define DBGWRAP(statement) statement

/**
 * {
 *     // DEBUG óLå¯éûÇ… LOG.exit(method) ÇçsÇ¢ÇΩÇ¢
 *     RETURN(LOG.exit(method), int, getValue());
 * }
 */
#define RETURN(statement, type, expression) \
{ type value__ = expression; statement; return value__; }

static bool _assertionFailed_ = false;

#ifdef __STDC__
#define ASSERT(e) \
{ if (e) {} else {_assertionFailed_ = true; throw AssertionFailedException(__FILE__, __LINE__, #e); } }
#else   /* PCC */
#define ASSERT(e) \
{ if (e) {} else {_assertionFailed_ = true; throw AssertionFailedException(__FILE__, __LINE__, "e"); } }
#endif

#else

#define DBGWRAP(statement)

#define RETURN(statement, type, expression) \
return expression

#define ASSERT(e)

#endif /* IML_DEBUG */

#endif /* Debug_hh_ */
