/*-------------------------------------------------------------------------
 *
 * parse_func.c
 *		handle function calls in parser
 *
 * Portions Copyright (c) 1996-2008, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  $PostgreSQL: pgsql/src/backend/parser/parse_func.c,v 1.201.2.1 2010/07/30 17:57:07 tgl Exp $
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "access/heapam.h"
#include "access/transam.h"
#include "catalog/pg_aggregate.h"
#include "catalog/pg_attrdef.h"
#include "catalog/pg_constraint.h"
#include "catalog/pg_inherits.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_proc_callback.h"
#include "catalog/pg_type.h"
#include "catalog/pg_window.h"
#include "funcapi.h"
#include "miscadmin.h"
#include "nodes/makefuncs.h"
#include "nodes/nodeFuncs.h"
#include "optimizer/walkers.h"
#include "parser/parse_agg.h"
#include "parser/parse_clause.h"
#include "parser/parse_coerce.h"
#include "parser/parse_expr.h"
#include "parser/parse_func.h"
#include "parser/parse_relation.h"
#include "parser/parse_target.h"
#include "parser/parse_type.h"
#include "parser/parsetree.h"
#include "utils/builtins.h"
#include "utils/fmgroids.h"
#include "utils/lsyscache.h"
#include "utils/syscache.h"


static Oid	FuncNameAsType(List *funcname);
static Node *ParseComplexProjection(ParseState *pstate, char *funcname,
					   Node *first_arg, int location);
static void unknown_attribute(ParseState *pstate, Node *relref, char *attname,
				  int location);
static bool check_pg_get_expr_arg(ParseState *pstate, Node *arg, int netlevelsup);

typedef struct
{
	Node *parent;
} check_table_func_context;

static bool 
checkTableFunctions_walker(Node *node, check_table_func_context *context);

/*
 *	Parse a function call
 *
 *	For historical reasons, Postgres tries to treat the notations tab.col
 *	and col(tab) as equivalent: if a single-argument function call has an
 *	argument of complex type and the (unqualified) function name matches
 *	any attribute of the type, we take it as a column projection.  Conversely
 *	a function of a single complex-type argument can be written like a
 *	column reference, allowing functions to act like computed columns.
 *
 *	Hence, both cases come through here.  The is_column parameter tells us
 *	which syntactic construct is actually being dealt with, but this is
 *	intended to be used only to deliver an appropriate error message,
 *	not to affect the semantics.  When is_column is true, we should have
 *	a single argument (the putative table), unqualified function name
 *	equal to the column name, and no aggregate decoration.
 *
 *	The argument expressions (in fargs) must have been transformed already.
 */
Node *
ParseFuncOrColumn(ParseState *pstate, List *funcname, List *fargs,
                  List *agg_order, bool agg_star, bool agg_distinct, 
                  bool func_variadic, bool is_column, WindowSpec *over,
				  int location, Node *agg_filter)
{
	Oid			rettype = InvalidOid;
	Oid			funcid = InvalidOid;
	ListCell   *l;
	ListCell   *nextl;
	Node	   *first_arg = NULL;
	int			nargs;
	int			nvargs = 0;
	int         nargsplusdefs;
	Oid			actual_arg_types[FUNC_MAX_ARGS];
	Oid		   *declared_arg_types = NULL;
	List       *argdefaults = NULL;
	Node	   *retval = NULL;
	bool		retset = false;
	bool        retstrict = false;
	bool        retordered = false;
	FuncDetailCode fdresult;

	/*
	 * Most of the rest of the parser just assumes that functions do not have
	 * more than FUNC_MAX_ARGS parameters.	We have to test here to protect
	 * against array overruns, etc.  Of course, this may not be a function,
	 * but the test doesn't hurt.
	 */
	if (list_length(fargs) > FUNC_MAX_ARGS)
		ereport(ERROR,
				(errcode(ERRCODE_TOO_MANY_ARGUMENTS),
				 errmsg("cannot pass more than %d arguments to a function",
						FUNC_MAX_ARGS),
				 parser_errposition(pstate, location)));

	/* 
	 * Perform the FILTER -> CASE transform.
	 *    FUNC(expr) FILTER (WHERE cond)  =>  FUNC(CASE WHEN cond THEN expr END)
	 * This must be done for every parameter of the function and special handling
	 * is needed for FUNC(*).  
	 *
	 * For this to be a valid transform we must assume that NULLs passed into
	 * the function will not change the result.  This assumption is not valid
	 * for count(*), which is why we need special processing for this case.  If
	 * it is not a valid assumption for other cases we may need to rethink how
	 * we implement FILTER.
	 */
	if (agg_filter) 
	{
		List *newfargs = NULL;

		if (agg_star || !fargs)
		{
			/*
			 * FUNC(*) => assume that datatype doesn't matter 
			 * By converting agg_star into a conditional constant boolean 
			 * expression we get the correct results for count(*) since it
			 * will then supress the NULLs returned by the CASE statement.
			 */
			CaseExpr  *c = makeNode(CaseExpr);
			CaseWhen  *w = makeNode(CaseWhen);
			A_Const   *a = makeNode(A_Const);
			a->val.type  = T_Integer;
			a->val.val.ival = 1;    /* Actual value shouldn't matter */
			w->expr      = (Expr *) agg_filter;
			w->result    = (Expr *) a;
			c->casetype  = InvalidOid;  /* will analyze in a moment */
			c->arg       = (Expr *) NULL;
			c->defresult = (Expr *) NULL;
			c->args      = list_make1(w);
			newfargs     = list_make1(c);
		
			/* 
			 * Since we haven't checked the compatability of our function with
			 * agg_star we can not clear the local bit yet, otherwise we would
			 * loose track of the fact that this was an agg_star operation prior
			 * to transformation.
			 */
		}
		else
		{
			Assert(fargs && list_length(fargs) > 0);

			foreach(l, fargs)
			{
				CaseExpr  *c = makeNode(CaseExpr);
				CaseWhen  *w = makeNode(CaseWhen);
				w->expr      = (Expr *) agg_filter;
				w->result    = (Expr *) lfirst(l);
				c->casetype  = InvalidOid;  /* will analyze in a moment */
				c->arg       = (Expr *) NULL;
				c->defresult = (Expr *) NULL;
				c->args      = list_make1(w);

				if (newfargs)
					lappend(newfargs, c);
				else
					newfargs = list_make1(c);
			}
		}
		fargs = transformExpressionList(pstate, newfargs);
	}

	/*
	 * Extract arg type info in preparation for function lookup.
	 *
	 * If any arguments are Param markers of type VOID, we discard them from
	 * the parameter list.	This is a hack to allow the JDBC driver to not
	 * have to distinguish "input" and "output" parameter symbols while
	 * parsing function-call constructs.  We can't use foreach() because we
	 * may modify the list ...
	 */
	nargs = 0;
	for (l = list_head(fargs); l != NULL; l = nextl)
	{
		Node	   *arg = lfirst(l);
		Oid			argtype = exprType(arg);

		nextl = lnext(l);

		if (argtype == VOIDOID && IsA(arg, Param) &&!is_column)
		{
			fargs = list_delete_ptr(fargs, arg);
			continue;
		}

		actual_arg_types[nargs++] = argtype;
	}

	if (fargs)
	{
		first_arg = linitial(fargs);
		Assert(first_arg != NULL);
	}

	/*
	 * Check for column projection: if function has one argument, and that
	 * argument is of complex type, and function name is not qualified, then
	 * the "function call" could be a projection.  We also check that there
	 * wasn't any aggregate or variadic decoration.
	 */
	if (nargs == 1 && agg_order == NIL && !agg_star && !agg_distinct &&
		!func_variadic && !agg_filter && list_length(funcname) == 1)
	{
		Oid			argtype = actual_arg_types[0];

		if (argtype == RECORDOID || ISCOMPLEX(argtype))
		{
			retval = ParseComplexProjection(pstate,
											strVal(linitial(funcname)),
											first_arg,
											location);
			if (retval)
				return retval;

			/*
			 * If ParseComplexProjection doesn't recognize it as a projection,
			 * just press on.
			 */
		}
	}

	/*
	 * Okay, it's not a column projection, so it must really be a function.
	 * func_get_detail looks up the function in the catalogs, does
	 * disambiguation for polymorphic functions, handles inheritance, and
	 * returns the funcid and type and set or singleton status of the
	 * function's return value.  it also returns the true argument types to
	 * the function. In the case of a variadic function call, the reported
	 * "true" types aren't really what is in pg_proc: the variadic argument is
	 * replaced by a suitable number of copies of its element type. We'll fix
	 * it up below. We may also have to deal with default arguments.
	 */
	fdresult = func_get_detail(funcname, fargs, nargs,
							   actual_arg_types, !func_variadic, true,
							   &funcid, &rettype, &retset, &retstrict,
							   &retordered, &nvargs,
							   &declared_arg_types, &argdefaults);
	if (fdresult == FUNCDETAIL_COERCION)
	{
		/*
		 * We interpreted it as a type coercion. coerce_type can handle these
		 * cases, so why duplicate code...
		 */
		return coerce_type(pstate, linitial(fargs),
						   actual_arg_types[0], rettype, -1,
						   COERCION_EXPLICIT, COERCE_EXPLICIT_CALL,
						   -1);
	}
	else if (fdresult == FUNCDETAIL_NORMAL)
	{
		/*
		 * Normal function found; was there anything indicating it must be an
		 * aggregate?
		 */
		if (agg_star)
			ereport(ERROR,
					(errcode(ERRCODE_WRONG_OBJECT_TYPE),
					 errmsg("%s(*) specified, but %s is not an aggregate function",
							NameListToString(funcname),
							NameListToString(funcname)),
					 parser_errposition(pstate, location)));
		if (agg_distinct)
			ereport(ERROR,
					(errcode(ERRCODE_WRONG_OBJECT_TYPE),
					 errmsg("DISTINCT specified, but %s is not an aggregate function",
							NameListToString(funcname)),
					 parser_errposition(pstate, location)));
        if (agg_order)
			ereport(ERROR,
					(errcode(ERRCODE_WRONG_OBJECT_TYPE),
					 errmsg("ORDER BY specified, but %s is not an ordered aggregate function",
							NameListToString(funcname)),
					 parser_errposition(pstate, location)));
		if (agg_filter)
		    ereport(ERROR,
					(errcode(ERRCODE_WRONG_OBJECT_TYPE),
					 errmsg("filter clause specified, but "
							"%s is not an aggregate function",
							NameListToString(funcname)),
					 parser_errposition(pstate, location)));
	}
	else if (fdresult != FUNCDETAIL_AGGREGATE)
	{
		/*
		 * Oops.  Time to die.
		 *
		 * If we are dealing with the attribute notation rel.function, give an
		 * error message that is appropriate for that case.
		 */
		if (is_column)
		{
			Assert(nargs == 1);
			Assert(list_length(funcname) == 1);
			unknown_attribute(pstate, first_arg, strVal(linitial(funcname)),
							  location);
		}

		/*
		 * Else generate a detailed complaint for a function
		 */
		if (fdresult == FUNCDETAIL_MULTIPLE)
			ereport(ERROR,
					(errcode(ERRCODE_AMBIGUOUS_FUNCTION),
					 errmsg("function %s is not unique",
							func_signature_string(funcname, nargs,
												  actual_arg_types)),
					 errhint("Could not choose a best candidate function. "
							 "You might need to add explicit type casts."),
					 parser_errposition(pstate, location)));
		else
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_FUNCTION),
					 errmsg("function %s does not exist",
							func_signature_string(funcname, nargs,
												  actual_arg_types)),
					 errhint("No function matches the given name and argument types. "
							 "You might need to add explicit type casts."),
					 parser_errposition(pstate, location)));
	}

	/*
	 * The agg_filter rewrite in the case of agg_star is only valid for count(*)
	 * otherwise we need to throw an error.
	 */
	if (agg_star && agg_filter && funcid != COUNT_ANY_OID)
	{
	    ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_FUNCTION),
				 errmsg("function %s() does not exist",
						NameListToString(funcname)),
				 errhint("No function matches the given name and argument types. "
						 "You might need to add explicit type casts."),
				 parser_errposition(pstate, location)));
	}

	/*
	 * If there are default arguments, we have to include their types in
	 * actual_arg_types for the purpose of checking generic type consistency.
	 * However, we do NOT put them into the generated parse node, because
	 * their actual values might change before the query gets run. The
	 * planner has to insert the up-to-date values at plan time.
	 */
	nargsplusdefs = nargs;
	foreach(l, argdefaults)
	{
		Node    *expr = (Node *) lfirst(l);
		/* probably shouldn't happen ... */
		if (nargsplusdefs >= FUNC_MAX_ARGS)
			ereport(ERROR,
					(errcode(ERRCODE_TOO_MANY_ARGUMENTS),
							 errmsg("cannot pass more than %d arguments to a function",
									 FUNC_MAX_ARGS),
									 parser_errposition(pstate, location)));
		actual_arg_types[nargsplusdefs++] = exprType(expr);
	}

	/*
	 * enforce consistency with polymorphic argument and return types,
	 * possibly adjusting return type or declared_arg_types (which will be
	 * used as the cast destination by make_fn_arguments)
	 */
	rettype = enforce_generic_type_consistency(actual_arg_types,
											   declared_arg_types,
											   nargs,
											   rettype,
											   false);

	/* perform the necessary typecasting of arguments */
	make_fn_arguments(pstate, fargs, actual_arg_types, declared_arg_types);

	/*
	 * If it's a variadic function call, transform the last nvargs arguments
	 * into an array -- unless it's an "any" variadic.
	 */
	if (nvargs > 0 && declared_arg_types[nargs - 1] != ANYOID)
	{
		ArrayExpr	*newa = makeNode(ArrayExpr);
		int     	non_var_args = nargs - nvargs;
		List    	*vargs;

		Assert(non_var_args >= 0);
		vargs = list_copy_tail(fargs, non_var_args);
		fargs = list_truncate(fargs, non_var_args);

		newa->elements = vargs;
		/* assume all the variadic arguments were coerced to the same type */
		newa->element_typeid = exprType((Node *) linitial(vargs));
		newa->array_typeid = get_array_type(newa->element_typeid);

		if (!OidIsValid(newa->array_typeid))
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_OBJECT),
					errmsg("could not find array type for data type %s",
						   format_type_be(newa->element_typeid)),
					parser_errposition(pstate, exprLocation((Node *) vargs))));
		newa->multidims = false;

		fargs = lappend(fargs, newa);
	}

	/* build the appropriate output structure */
	if (fdresult == FUNCDETAIL_NORMAL && over == NULL)
	{
		FuncExpr   *funcexpr = makeNode(FuncExpr);

		funcexpr->funcid = funcid;
		funcexpr->funcresulttype = rettype;
		funcexpr->funcretset = retset;
		funcexpr->funcformat = COERCE_EXPLICIT_CALL;
		funcexpr->args = fargs;
		funcexpr->location = location;

		retval = (Node *) funcexpr;
	}
	else if(over != NULL)
	{
		/* must be a window function call */
		WindowRef  *winref = makeNode(WindowRef);
		HeapTuple	tuple;	
		
		if (retset)
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_FUNCTION_DEFINITION),
					 errmsg("window functions may not return sets"),
					 parser_errposition(pstate, location)));

        if (agg_order)
            ereport(ERROR,
                    (errcode(ERRCODE_WRONG_OBJECT_TYPE),
                     errmsg("aggregate ORDER BY is not implemented for window functions"),
                     parser_errposition(pstate, location)));


        /*
         * If this is a "true" window function, rather than an aggregate
         * derived window function then it will have a tuple in pg_window
         */
		tuple = SearchSysCache1(WINFNOID, ObjectIdGetDatum(funcid));
		if (HeapTupleIsValid(tuple))
		{
			if (agg_filter)
			    ereport(ERROR,
						(errcode(ERRCODE_WRONG_OBJECT_TYPE),
						 errmsg("window function \"%s\" can not be used with a "
								"filter clause",
								NameListToString(funcname)),
						 parser_errposition(pstate, location)));

			/*
			 * We perform more checks – such as whether the window
			 * function requires ordering or permits a frame specification –
			 * later in transformWindowClause(). It's too early at this stage.
			 */

			ReleaseSysCache(tuple);
		}

		winref->winfnoid = funcid;
		winref->restype = rettype;
		winref->args = fargs;

		{
			/*
			 * Find if this "over" clause has already existed. If so,
			 * We let the "winspec" for this WindowRef point to
			 * the existing "over" clause. In this way, we will be able
			 * to determine if two WindowRef nodes are actually equal,
			 * see MPP-4268.
			 */
			int winspec = 0;
			ListCell *over_lc = NULL;
			
			transformWindowSpec(pstate, over);
			
			foreach (over_lc, pstate->p_win_clauses)
			{
				Node *over1 = lfirst(over_lc);
				if (equal(over1, over))
					break;
				winspec++;
			}
				
			if (over_lc == NULL)
				pstate->p_win_clauses = lappend(pstate->p_win_clauses, over);
			winref->winspec = winspec;
		}

		winref->windistinct = agg_distinct;
		winref->location = location;

		transformWindowFuncCall(pstate, winref);
		retval = (Node *) winref;
	}
	else
	{
		/* aggregate function */
		Aggref	   *aggref;

		/*
		 * Reject attempt to call a parameterless aggregate without (*)
		 * syntax.	This is mere pedantry but some folks insisted ...
		 */
		if (fargs == NIL && !agg_star)
			ereport(ERROR,
					(errcode(ERRCODE_WRONG_OBJECT_TYPE),
					 errmsg("%s(*) must be used to call a parameterless aggregate function",
							NameListToString(funcname)),
					 parser_errposition(pstate, location)));

		/* 
		 * We only support FILTER clauses over STRICT aggegation functions.
		 *
		 * All built in aggregations are strict except for int2_sum, 
         * int4_sum, and int8_sum, all of which are logically strict, but are
		 * simply defined as non-strict to bootstrap their calculations.  
		 * Since they are logically strict we will not change their results 
		 * by including extra nulls in the calculation so the rewrite won't 
		 * produce incorrect results.
		 *
		 * For user defined functions we must enforce this restriction since
		 * passing "extra" nulls back to a non-strict function may cause it
		 * to return an incorrect answer, eg: count_null(i) filter (...) 
		 * wouldn't differeniate between data nulls vs filtered values.
		 */
		if (agg_filter && !retstrict && 
			(funcid < SUM_OID_MIN || funcid > SUM_OID_MAX))
		{
		    ereport(ERROR,
					(errcode(ERRCODE_GP_FEATURE_NOT_SUPPORTED),
					 errmsg("function %s is not defined as STRICT",
							func_signature_string(funcname, nargs, 
												  actual_arg_types)),
					 errhint("The filter clause is only supported over functions "
							 "defined as STRICT."),
					 parser_errposition(pstate, location)));
		}

		if (retset)
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_FUNCTION_DEFINITION),
					 errmsg("aggregates cannot return sets"),
					 parser_errposition(pstate, location)));

		/* 
		 * If this is not an ordered aggregate, but it was called with an
		 * aggregate order by specification then we must raise an error.
		 */
		if (!retordered && agg_order != NIL)
		{
			ereport(ERROR,
					(errcode(ERRCODE_WRONG_OBJECT_TYPE),
					 errmsg("ORDER BY specified, but %s is not an ordered aggregate function",
							NameListToString(funcname)),
					 parser_errposition(pstate, location)));			
		}

		/* 
		 * ordered aggregates are not compatible with distinct
		 */
		if (agg_distinct && agg_order != NIL)
		{
			ereport(ERROR,
					(errcode(ERRCODE_GP_FEATURE_NOT_SUPPORTED),
					 errmsg("ORDER BY and DISTINCT are mutually exclusive"),
					 parser_errposition(pstate, location)));
		}
        
        /* 
         * Build the aggregate node and transform it
         *
         * Note: aggorder is handled inside transformAggregateCall()
         */
        aggref = makeNode(Aggref);
		aggref->aggfnoid    = funcid;
		aggref->aggtype     = rettype;
		aggref->args        = fargs;
		aggref->aggstar     = agg_star;
		aggref->aggdistinct = agg_distinct;
		aggref->location = location;

		transformAggregateCall(pstate, aggref, agg_order);

		retval = (Node *) aggref;
	}

	/*
	 * Mark the context if this is a dynamic typed function, if so we mustn't
	 * allow views to be created from this statement because we cannot 
	 * guarantee that the future return type will be the same as the current
	 * return type.
	 */
	if (TypeSupportsDescribe(rettype))
	{
		Oid DescribeFuncOid = lookupProcCallback(funcid, PROMETHOD_DESCRIBE);
		if (OidIsValid(DescribeFuncOid))
		{
			ParseState *state = pstate;

			for (state = pstate; state; state = state->parentParseState)
				state->p_hasDynamicFunction = true;
		}
	}

	/* Hack to protect pg_get_expr() against misuse */
	check_pg_get_expr_args(pstate, funcid, fargs);

	return retval;
}


/* func_match_argtypes()
 *
 * Given a list of candidate functions (having the right name and number
 * of arguments) and an array of input datatype OIDs, produce a shortlist of
 * those candidates that actually accept the input datatypes (either exactly
 * or by coercion), and return the number of such candidates.
 *
 * Note that can_coerce_type will assume that UNKNOWN inputs are coercible to
 * anything, so candidates will not be eliminated on that basis.
 *
 * NB: okay to modify input list structure, as long as we find at least
 * one match.  If no match at all, the list must remain unmodified.
 */
int
func_match_argtypes(int nargs,
					Oid *input_typeids,
					FuncCandidateList raw_candidates,
					FuncCandidateList *candidates)		/* return value */
{
	FuncCandidateList current_candidate;
	FuncCandidateList next_candidate;
	int			ncandidates = 0;

	*candidates = NULL;

	for (current_candidate = raw_candidates;
		 current_candidate != NULL;
		 current_candidate = next_candidate)
	{
		next_candidate = current_candidate->next;
		if (can_coerce_type(nargs, input_typeids, current_candidate->args,
							COERCION_IMPLICIT))
		{
			current_candidate->next = *candidates;
			*candidates = current_candidate;
			ncandidates++;
		}
	}

	return ncandidates;
}	/* func_match_argtypes() */


/* func_select_candidate()
 *		Given the input argtype array and more than one candidate
 *		for the function, attempt to resolve the conflict.
 *
 * Returns the selected candidate if the conflict can be resolved,
 * otherwise returns NULL.
 *
 * Note that the caller has already determined that there is no candidate
 * exactly matching the input argtypes, and has pruned away any "candidates"
 * that aren't actually coercion-compatible with the input types.
 *
 * This is also used for resolving ambiguous operator references.  Formerly
 * parse_oper.c had its own, essentially duplicate code for the purpose.
 * The following comments (formerly in parse_oper.c) are kept to record some
 * of the history of these heuristics.
 *
 * OLD COMMENTS:
 *
 * This routine is new code, replacing binary_oper_select_candidate()
 * which dates from v4.2/v1.0.x days. It tries very hard to match up
 * operators with types, including allowing type coercions if necessary.
 * The important thing is that the code do as much as possible,
 * while _never_ doing the wrong thing, where "the wrong thing" would
 * be returning an operator when other better choices are available,
 * or returning an operator which is a non-intuitive possibility.
 * - thomas 1998-05-21
 *
 * The comments below came from binary_oper_select_candidate(), and
 * illustrate the issues and choices which are possible:
 * - thomas 1998-05-20
 *
 * current wisdom holds that the default operator should be one in which
 * both operands have the same type (there will only be one such
 * operator)
 *
 * 7.27.93 - I have decided not to do this; it's too hard to justify, and
 * it's easy enough to typecast explicitly - avi
 * [the rest of this routine was commented out since then - ay]
 *
 * 6/23/95 - I don't complete agree with avi. In particular, casting
 * floats is a pain for users. Whatever the rationale behind not doing
 * this is, I need the following special case to work.
 *
 * In the WHERE clause of a query, if a float is specified without
 * quotes, we treat it as float8. I added the float48* operators so
 * that we can operate on float4 and float8. But now we have more than
 * one matching operator if the right arg is unknown (eg. float
 * specified with quotes). This break some stuff in the regression
 * test where there are floats in quotes not properly casted. Below is
 * the solution. In addition to requiring the operator operates on the
 * same type for both operands [as in the code Avi originally
 * commented out], we also require that the operators be equivalent in
 * some sense. (see equivalentOpersAfterPromotion for details.)
 * - ay 6/95
 */
FuncCandidateList
func_select_candidate(int nargs,
					  Oid *input_typeids,
					  FuncCandidateList candidates)
{
	FuncCandidateList current_candidate;
	FuncCandidateList last_candidate;
	Oid		   *current_typeids;
	Oid			current_type;
	int			i;
	int			ncandidates;
	int			nbestMatch,
				nmatch;
	Oid			input_base_typeids[FUNC_MAX_ARGS];
	CATEGORY	slot_category[FUNC_MAX_ARGS],
				current_category;
	bool		slot_has_preferred_type[FUNC_MAX_ARGS];
	bool		resolved_unknowns;

	/* protect local fixed-size arrays */
	if (nargs > FUNC_MAX_ARGS)
		ereport(ERROR,
				(errcode(ERRCODE_TOO_MANY_ARGUMENTS),
				 errmsg("cannot pass more than %d arguments to a function",
						FUNC_MAX_ARGS)));

	/*
	 * If any input types are domains, reduce them to their base types. This
	 * ensures that we will consider functions on the base type to be "exact
	 * matches" in the exact-match heuristic; it also makes it possible to do
	 * something useful with the type-category heuristics. Note that this
	 * makes it difficult, but not impossible, to use functions declared to
	 * take a domain as an input datatype.	Such a function will be selected
	 * over the base-type function only if it is an exact match at all
	 * argument positions, and so was already chosen by our caller.
	 */
	for (i = 0; i < nargs; i++)
		input_base_typeids[i] = getBaseType(input_typeids[i]);

	/*
	 * Run through all candidates and keep those with the most matches on
	 * exact types. Keep all candidates if none match.
	 */
	ncandidates = 0;
	nbestMatch = 0;
	last_candidate = NULL;
	for (current_candidate = candidates;
		 current_candidate != NULL;
		 current_candidate = current_candidate->next)
	{
		current_typeids = current_candidate->args;
		nmatch = 0;
		for (i = 0; i < nargs; i++)
		{
			if (input_base_typeids[i] != UNKNOWNOID &&
				current_typeids[i] == input_base_typeids[i])
				nmatch++;
		}

		/* take this one as the best choice so far? */
		if ((nmatch > nbestMatch) || (last_candidate == NULL))
		{
			nbestMatch = nmatch;
			candidates = current_candidate;
			last_candidate = current_candidate;
			ncandidates = 1;
		}
		/* no worse than the last choice, so keep this one too? */
		else if (nmatch == nbestMatch)
		{
			last_candidate->next = current_candidate;
			last_candidate = current_candidate;
			ncandidates++;
		}
		/* otherwise, don't bother keeping this one... */
	}

	if (last_candidate)			/* terminate rebuilt list */
		last_candidate->next = NULL;

	if (ncandidates == 1)
		return candidates;

	/*
	 * Still too many candidates? Now look for candidates which have either
	 * exact matches or preferred types at the args that will require
	 * coercion. (Restriction added in 7.4: preferred type must be of same
	 * category as input type; give no preference to cross-category
	 * conversions to preferred types.)  Keep all candidates if none match.
	 */
	for (i = 0; i < nargs; i++) /* avoid multiple lookups */
		slot_category[i] = TypeCategory(input_base_typeids[i]);
	ncandidates = 0;
	nbestMatch = 0;
	last_candidate = NULL;
	for (current_candidate = candidates;
		 current_candidate != NULL;
		 current_candidate = current_candidate->next)
	{
		current_typeids = current_candidate->args;
		nmatch = 0;
		for (i = 0; i < nargs; i++)
		{
			if (input_base_typeids[i] != UNKNOWNOID)
			{
				if (current_typeids[i] == input_base_typeids[i] ||
					IsPreferredType(slot_category[i], current_typeids[i]))
					nmatch++;
			}
		}

		if ((nmatch > nbestMatch) || (last_candidate == NULL))
		{
			nbestMatch = nmatch;
			candidates = current_candidate;
			last_candidate = current_candidate;
			ncandidates = 1;
		}
		else if (nmatch == nbestMatch)
		{
			last_candidate->next = current_candidate;
			last_candidate = current_candidate;
			ncandidates++;
		}
	}

	if (last_candidate)			/* terminate rebuilt list */
		last_candidate->next = NULL;

	if (ncandidates == 1)
		return candidates;

	/*
	 * Still too many candidates? Try assigning types for the unknown columns.
	 *
	 * NOTE: for a binary operator with one unknown and one non-unknown input,
	 * we already tried the heuristic of looking for a candidate with the
	 * known input type on both sides (see binary_oper_exact()). That's
	 * essentially a special case of the general algorithm we try next.
	 *
	 * We do this by examining each unknown argument position to see if we can
	 * determine a "type category" for it.	If any candidate has an input
	 * datatype of STRING category, use STRING category (this bias towards
	 * STRING is appropriate since unknown-type literals look like strings).
	 * Otherwise, if all the candidates agree on the type category of this
	 * argument position, use that category.  Otherwise, fail because we
	 * cannot determine a category.
	 *
	 * If we are able to determine a type category, also notice whether any of
	 * the candidates takes a preferred datatype within the category.
	 *
	 * Having completed this examination, remove candidates that accept the
	 * wrong category at any unknown position.	Also, if at least one
	 * candidate accepted a preferred type at a position, remove candidates
	 * that accept non-preferred types.
	 *
	 * If we are down to one candidate at the end, we win.
	 */
	resolved_unknowns = false;
	for (i = 0; i < nargs; i++)
	{
		bool		have_conflict;

		if (input_base_typeids[i] != UNKNOWNOID)
			continue;
		resolved_unknowns = true;		/* assume we can do it */
		slot_category[i] = INVALID_TYPE;
		slot_has_preferred_type[i] = false;
		have_conflict = false;
		for (current_candidate = candidates;
			 current_candidate != NULL;
			 current_candidate = current_candidate->next)
		{
			current_typeids = current_candidate->args;
			current_type = current_typeids[i];
			current_category = TypeCategory(current_type);
			if (slot_category[i] == INVALID_TYPE)
			{
				/* first candidate */
				slot_category[i] = current_category;
				slot_has_preferred_type[i] =
					IsPreferredType(current_category, current_type);
			}
			else if (current_category == slot_category[i])
			{
				/* more candidates in same category */
				slot_has_preferred_type[i] |=
					IsPreferredType(current_category, current_type);
			}
			else
			{
				/* category conflict! */
				if (current_category == STRING_TYPE)
				{
					/* STRING always wins if available */
					slot_category[i] = current_category;
					slot_has_preferred_type[i] =
						IsPreferredType(current_category, current_type);
				}
				else
				{
					/*
					 * Remember conflict, but keep going (might find STRING)
					 */
					have_conflict = true;
				}
			}
		}
		if (have_conflict && slot_category[i] != STRING_TYPE)
		{
			/* Failed to resolve category conflict at this position */
			resolved_unknowns = false;
			break;
		}
	}

	if (resolved_unknowns)
	{
		/* Strip non-matching candidates */
		ncandidates = 0;
		last_candidate = NULL;
		for (current_candidate = candidates;
			 current_candidate != NULL;
			 current_candidate = current_candidate->next)
		{
			bool		keepit = true;

			current_typeids = current_candidate->args;
			for (i = 0; i < nargs; i++)
			{
				if (input_base_typeids[i] != UNKNOWNOID)
					continue;
				current_type = current_typeids[i];
				current_category = TypeCategory(current_type);
				if (current_category != slot_category[i])
				{
					keepit = false;
					break;
				}
				if (slot_has_preferred_type[i] &&
					!IsPreferredType(current_category, current_type))
				{
					keepit = false;
					break;
				}
			}
			if (keepit)
			{
				/* keep this candidate */
				last_candidate = current_candidate;
				ncandidates++;
			}
			else
			{
				/* forget this candidate */
				if (last_candidate)
					last_candidate->next = current_candidate->next;
				else
					candidates = current_candidate->next;
			}
		}
		if (last_candidate)		/* terminate rebuilt list */
			last_candidate->next = NULL;
	}

	if (ncandidates == 1)
		return candidates;

	return NULL;				/* failed to select a best candidate */
}	/* func_select_candidate() */


/* func_get_detail()
 *
 * Find the named function in the system catalogs.
 *
 * Attempt to find the named function in the system catalogs with
 * arguments exactly as specified, so that the normal case (exact match)
 * is as quick as possible.
 *
 * If an exact match isn't found:
 *	1) check for possible interpretation as a type coercion request
 *	2) get a vector of all possible input arg type arrays constructed
 *	   from the superclasses of the original input arg types
 *	3) get a list of all possible argument type arrays to the function
 *	   with given name and number of arguments
 *	4) for each input arg type array from vector #1:
 *	 a) find how many of the function arg type arrays from list #2
 *		it can be coerced to
 *	 b) if the answer is one, we have our function
 *	 c) if the answer is more than one, attempt to resolve the conflict
 *	 d) if the answer is zero, try the next array from vector #1
 *
 * Note: we rely primarily on nargs/argtypes as the argument description.
 * The actual expression node list is passed in fargs so that we can check
 * for type coercion of a constant.  Some callers pass fargs == NIL
 * indicating they don't want that check made.
 */
FuncDetailCode
func_get_detail(List *funcname,
				List *fargs,
				int nargs,
				Oid *argtypes,
				bool expand_variadic,
				bool expand_defaults,
				Oid *funcid,	/* return value */
				Oid *rettype,	/* return value */
				bool *retset,	/* return value */
				bool *retstrict, /* return value */
				bool *retordered, /* return value */
				int	 *nvargs,	/* return value */
				Oid **true_typeids,		/* return value */
				List **argdefaults)     /* optional return value */
{
	FuncCandidateList raw_candidates;
	FuncCandidateList best_candidate;

	/* Get list of possible candidates from namespace search */
	raw_candidates = FuncnameGetCandidates(funcname, nargs,
										   expand_variadic, expand_defaults);

	/*
	 * Quickly check if there is an exact match to the input datatypes (there
	 * can be only one)
	 */
	for (best_candidate = raw_candidates;
		 best_candidate != NULL;
		 best_candidate = best_candidate->next)
	{
		if (memcmp(argtypes, best_candidate->args, nargs * sizeof(Oid)) == 0)
			break;
	}

	if (best_candidate == NULL)
	{
		/*
		 * If we didn't find an exact match, next consider the possibility
		 * that this is really a type-coercion request: a single-argument
		 * function call where the function name is a type name.  If so, and
		 * if the coercion path is RELABELTYPE or COERCEVIAIO, then go ahead
		 * and treat the "function call" as a coercion.
		 *
		 * This interpretation needs to be given higher priority than
		 * interpretations involving a type coercion followed by a function
		 * call, otherwise we can produce surprising results. For example, we
		 * want "text(varchar)" to be interpreted as a simple coercion, not as
		 * "text(name(varchar))" which the code below this point is entirely
		 * capable of selecting.
		 *
		 * We also treat a coercion of a previously-unknown-type literal
		 * constant to a specific type this way.
		 *
		 * The reason we reject COERCION_PATH_FUNC here is that we expect the
		 * cast implementation function to be named after the target type.
		 * Thus the function will be found by normal lookup if appropriate.
		 *
		 * The reason we reject COERCION_PATH_ARRAYCOERCE is mainly that you
		 * can't write "foo[] (something)" as a function call.  In theory
		 * someone might want to invoke it as "_foo (something)" but we have
		 * never supported that historically, so we can insist that people
		 * write it as a normal cast instead.  Lack of historical support is
		 * also the reason for not considering composite-type casts here.
		 *
		 * NB: it's important that this code does not exceed what coerce_type
		 * can do, because the caller will try to apply coerce_type if we
		 * return FUNCDETAIL_COERCION.	If we return that result for something
		 * coerce_type can't handle, we'll cause infinite recursion between
		 * this module and coerce_type!
		 */
		if (nargs == 1 && fargs != NIL)
		{
			Oid			targetType = FuncNameAsType(funcname);

			if (OidIsValid(targetType))
			{
				Oid			sourceType = argtypes[0];
				Node	   *arg1 = linitial(fargs);
				bool		iscoercion;

				if (sourceType == UNKNOWNOID && IsA(arg1, Const))
				{
					/* always treat typename('literal') as coercion */
					iscoercion = true;
				}
				else
				{
					CoercionPathType cpathtype;
					Oid			cfuncid;

					cpathtype = find_coercion_pathway(targetType, sourceType,
													  COERCION_EXPLICIT,
													  &cfuncid);
					iscoercion = (cpathtype == COERCION_PATH_RELABELTYPE ||
								  cpathtype == COERCION_PATH_COERCEVIAIO);
				}

				if (iscoercion)
				{
					/* Treat it as a type coercion */
					*funcid = InvalidOid;
					*rettype = targetType;
					*retset = false;
					*retstrict = false;
					*retordered = false;
					*nvargs = 0;
					*true_typeids = argtypes;
					return FUNCDETAIL_COERCION;
				}
			}
		}

		/*
		 * didn't find an exact match, so now try to match up candidates...
		 */
		if (raw_candidates != NULL)
		{
			FuncCandidateList current_candidates;
			int			ncandidates;

			ncandidates = func_match_argtypes(nargs,
											  argtypes,
											  raw_candidates,
											  &current_candidates);

			/* one match only? then run with it... */
			if (ncandidates == 1)
				best_candidate = current_candidates;

			/*
			 * multiple candidates? then better decide or throw an error...
			 */
			else if (ncandidates > 1)
			{
				best_candidate = func_select_candidate(nargs,
													   argtypes,
													   current_candidates);

				/*
				 * If we were able to choose a best candidate, we're done.
				 * Otherwise, ambiguous function call.
				 */
				if (!best_candidate)
					return FUNCDETAIL_MULTIPLE;
			}
		}
	}

	if (best_candidate)
	{
		HeapTuple	ftup;
		Form_pg_proc pform;
		bool isagg = false;
		bool isnull;
		Datum datum;
		int pronargdefaults;

		/*
		 * If expanding variadics or defaults, the "best candidate" might
		 * represent multiple equivalently good functions; treat this case
		 * as ambiguous.
		 */
		if (!OidIsValid(best_candidate->oid))
			return FUNCDETAIL_MULTIPLE;

		*funcid = best_candidate->oid;
		*nvargs = best_candidate->nvargs;
		*true_typeids = best_candidate->args;

		ftup = SearchSysCache(PROCOID,
							  ObjectIdGetDatum(best_candidate->oid),
							  0, 0, 0);
		if (!HeapTupleIsValid(ftup))	/* should not happen */
			elog(ERROR, "cache lookup failed for function %u",
				 best_candidate->oid);
		pform = (Form_pg_proc) GETSTRUCT(ftup);
		*rettype = pform->prorettype;
		*retset = pform->proretset;
		*retstrict = pform->proisstrict;
		*retordered = false;

		datum = SysCacheGetAttr(PROCOID, ftup,
							    Anum_pg_proc_pronargdefaults, &isnull);
		pronargdefaults = DatumGetObjectId(datum);

		/* fetch default args if caller wants 'em */
		if (argdefaults)
		{
			if (best_candidate->ndargs > 0)
			{
				Datum       proargdefaults;
				bool        isnull;
				char       *str;
				List       *defaults;
				int         ndelete;

				/* shouldn't happen, FuncnameGetCandidates messed up */
				if (best_candidate->ndargs > pronargdefaults)
					elog(ERROR, "not enough default arguments");

				proargdefaults = SysCacheGetAttr(PROCOID, ftup,
												 Anum_pg_proc_proargdefaults,
												 &isnull);
				Assert(!isnull);
				str = TextDatumGetCString(proargdefaults);
				defaults = (List *) stringToNode(str);
				Assert(IsA(defaults, List));
				pfree(str);
				/* Delete any unused defaults from the returned list */
				ndelete = list_length(defaults) - best_candidate->ndargs;
				while (ndelete-- > 0)
					defaults = list_delete_first(defaults);
				*argdefaults = defaults;
			}
			else
				*argdefaults = NIL;
		}

		isagg = pform->proisagg;

		ReleaseSysCache(ftup);

		/* 
		 * For aggregate functions STRICTness is defined by the 
		 * transition function 
		 */
		if (isagg)
		{
		    Form_pg_aggregate	aggform;
			FmgrInfo			transfn;
			Datum				value;
			bool				isnull;

			ftup = SearchSysCache1(AGGFNOID,
								   ObjectIdGetDatum(best_candidate->oid));
			if (!HeapTupleIsValid(ftup))	/* should not happen */
			    elog(ERROR, "cache lookup failed for aggregate %u",
					 best_candidate->oid);
			aggform = (Form_pg_aggregate) GETSTRUCT(ftup);
			fmgr_info(aggform->aggtransfn, &transfn);
			*retstrict = transfn.fn_strict;

			/* 
			 * Check if this is an ordered aggregate - while aggordered
			 * should never be null it comes after a variable length field
			 * so we must access it via SysCacheGetAttr.
			 */
			value = SysCacheGetAttr(AGGFNOID, ftup,
									Anum_pg_aggregate_aggordered,
									&isnull);
			*retordered = (!isnull) && DatumGetBool(value);

			ReleaseSysCache(ftup);

			return FUNCDETAIL_AGGREGATE;
		}
		return FUNCDETAIL_NORMAL;
	}

	return FUNCDETAIL_NOTFOUND;
}


/*
 * Given two type OIDs, determine whether the first is a complex type
 * (class type) that inherits from the second.
 */
bool
typeInheritsFrom(Oid subclassTypeId, Oid superclassTypeId)
{
	bool		result = false;
	Oid			relid;
	Relation	inhrel;
	List	   *visited,
			   *queue;
	ListCell   *queue_item;

	if (!ISCOMPLEX(subclassTypeId) || !ISCOMPLEX(superclassTypeId))
		return false;
	relid = typeidTypeRelid(subclassTypeId);
	if (relid == InvalidOid)
		return false;

	/*
	 * Begin the search at the relation itself, so add relid to the queue.
	 */
	queue = list_make1_oid(relid);
	visited = NIL;

	inhrel = heap_open(InheritsRelationId, AccessShareLock);

	/*
	 * Use queue to do a breadth-first traversal of the inheritance graph from
	 * the relid supplied up to the root.  Notice that we append to the queue
	 * inside the loop --- this is okay because the foreach() macro doesn't
	 * advance queue_item until the next loop iteration begins.
	 */
	foreach(queue_item, queue)
	{
		Oid			this_relid = lfirst_oid(queue_item);
		ScanKeyData skey;
		HeapScanDesc inhscan;
		HeapTuple	inhtup;

		/* If we've seen this relid already, skip it */
		if (list_member_oid(visited, this_relid))
			continue;

		/*
		 * Okay, this is a not-yet-seen relid. Add it to the list of
		 * already-visited OIDs, then find all the types this relid inherits
		 * from and add them to the queue. The one exception is we don't add
		 * the original relation to 'visited'.
		 */
		if (queue_item != list_head(queue))
			visited = lappend_oid(visited, this_relid);

		ScanKeyInit(&skey,
					Anum_pg_inherits_inhrelid,
					BTEqualStrategyNumber, F_OIDEQ,
					ObjectIdGetDatum(this_relid));

		inhscan = heap_beginscan(inhrel, SnapshotNow, 1, &skey);

		while ((inhtup = heap_getnext(inhscan, ForwardScanDirection)) != NULL)
		{
			Form_pg_inherits inh = (Form_pg_inherits) GETSTRUCT(inhtup);
			Oid			inhparent = inh->inhparent;

			/* If this is the target superclass, we're done */
			if (get_rel_type_id(inhparent) == superclassTypeId)
			{
				result = true;
				break;
			}

			/* Else add to queue */
			queue = lappend_oid(queue, inhparent);
		}

		heap_endscan(inhscan);

		if (result)
			break;
	}

	heap_close(inhrel, AccessShareLock);

	list_free(visited);
	list_free(queue);

	return result;
}


/*
 * make_fn_arguments()
 *
 * Given the actual argument expressions for a function, and the desired
 * input types for the function, add any necessary typecasting to the
 * expression tree.  Caller should already have verified that casting is
 * allowed.
 *
 * Caution: given argument list is modified in-place.
 *
 * As with coerce_type, pstate may be NULL if no special unknown-Param
 * processing is wanted.
 */
void
make_fn_arguments(ParseState *pstate,
				  List *fargs,
				  Oid *actual_arg_types,
				  Oid *declared_arg_types)
{
	ListCell   *current_fargs;
	int			i = 0;

	foreach(current_fargs, fargs)
	{
		/* types don't match? then force coercion using a function call... */
		if (actual_arg_types[i] != declared_arg_types[i])
		{
			lfirst(current_fargs) = coerce_type(pstate,
												lfirst(current_fargs),
												actual_arg_types[i],
												declared_arg_types[i], -1,
												COERCION_IMPLICIT,
												COERCE_IMPLICIT_CAST,
												-1);
		}
		i++;
	}
}

/*
 * FuncNameAsType -
 *	  convenience routine to see if a function name matches a type name
 *
 * Returns the OID of the matching type, or InvalidOid if none.  We ignore
 * shell types and complex types.
 */
static Oid
FuncNameAsType(List *funcname)
{
	Oid			result;
	Type		typtup;

	typtup = LookupTypeName(NULL, makeTypeNameFromNameList(funcname), NULL);
	if (typtup == NULL)
		return InvalidOid;

	if (((Form_pg_type) GETSTRUCT(typtup))->typisdefined &&
		!OidIsValid(typeTypeRelid(typtup)))
		result = typeTypeId(typtup);
	else
		result = InvalidOid;

	ReleaseSysCache(typtup);
	return result;
}

/*
 * ParseComplexProjection -
 *	  handles function calls with a single argument that is of complex type.
 *	  If the function call is actually a column projection, return a suitably
 *	  transformed expression tree.	If not, return NULL.
 */
static Node *
ParseComplexProjection(ParseState *pstate, char *funcname, Node *first_arg,
					   int location)
{
	TupleDesc	tupdesc;
	int			i;

	/*
	 * Special case for whole-row Vars so that we can resolve (foo.*).bar even
	 * when foo is a reference to a subselect, join, or RECORD function. A
	 * bonus is that we avoid generating an unnecessary FieldSelect; our
	 * result can omit the whole-row Var and just be a Var for the selected
	 * field.
	 *
	 * This case could be handled by expandRecordVariable, but it's more
	 * efficient to do it this way when possible.
	 */
	if (IsA(first_arg, Var) &&
		((Var *) first_arg)->varattno == InvalidAttrNumber)
	{
		RangeTblEntry *rte;

		rte = GetRTEByRangeTablePosn(pstate,
									 ((Var *) first_arg)->varno,
									 ((Var *) first_arg)->varlevelsup);
		/* Return a Var if funcname matches a column, else NULL */
		return scanRTEForColumn(pstate, rte, funcname, location);
	}

	/*
	 * Else do it the hard way with get_expr_result_type().
	 *
	 * If it's a Var of type RECORD, we have to work even harder: we have to
	 * find what the Var refers to, and pass that to get_expr_result_type.
	 * That task is handled by expandRecordVariable().
	 */
	if (IsA(first_arg, Var) &&
		((Var *) first_arg)->vartype == RECORDOID)
		tupdesc = expandRecordVariable(pstate, (Var *) first_arg, 0);
	else if (get_expr_result_type(first_arg, NULL, &tupdesc) != TYPEFUNC_COMPOSITE)
		return NULL;			/* unresolvable RECORD type */
	Assert(tupdesc);

	for (i = 0; i < tupdesc->natts; i++)
	{
		Form_pg_attribute att = tupdesc->attrs[i];

		if (strcmp(funcname, NameStr(att->attname)) == 0 &&
			!att->attisdropped)
		{
			/* Success, so generate a FieldSelect expression */
			FieldSelect *fselect = makeNode(FieldSelect);

			fselect->arg = (Expr *) first_arg;
			fselect->fieldnum = i + 1;
			fselect->resulttype = att->atttypid;
			fselect->resulttypmod = att->atttypmod;
			return (Node *) fselect;
		}
	}

	return NULL;				/* funcname does not match any column */
}

/*
 * helper routine for delivering "column does not exist" error message
 */
static void
unknown_attribute(ParseState *pstate, Node *relref, char *attname,
				  int location)
{
	RangeTblEntry *rte;

	if (IsA(relref, Var) &&
		((Var *) relref)->varattno == InvalidAttrNumber)
	{
		/* Reference the RTE by alias not by actual table name */
		rte = GetRTEByRangeTablePosn(pstate,
									 ((Var *) relref)->varno,
									 ((Var *) relref)->varlevelsup);
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_COLUMN),
				 errmsg("column %s.%s does not exist",
						rte->eref->aliasname, attname),
				 parser_errposition(pstate, location)));
	}
	else
	{
		/* Have to do it by reference to the type of the expression */
		Oid			relTypeId = exprType(relref);

		if (ISCOMPLEX(relTypeId))
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_COLUMN),
					 errmsg("column \"%s\" not found in data type %s",
							attname, format_type_be(relTypeId)),
					 parser_errposition(pstate, location)));
		else if (relTypeId == RECORDOID)
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_COLUMN),
			   errmsg("could not identify column \"%s\" in record data type",
					  attname),
					 parser_errposition(pstate, location)));
		else
			ereport(ERROR,
					(errcode(ERRCODE_WRONG_OBJECT_TYPE),
					 errmsg("column notation .%s applied to type %s, "
							"which is not a composite type",
							attname, format_type_be(relTypeId)),
					 parser_errposition(pstate, location)));
	}
}

/*
 * funcname_signature_string
 *		Build a string representing a function name, including arg types.
 *		The result is something like "foo(integer)".
 *
 * This is typically used in the construction of function-not-found error
 * messages.
 */
const char *
funcname_signature_string(const char *funcname,
						  int nargs, const Oid *argtypes)
{
	StringInfoData argbuf;
	int			i;

	initStringInfo(&argbuf);

	appendStringInfo(&argbuf, "%s(", funcname);

	for (i = 0; i < nargs; i++)
	{
		if (i)
			appendStringInfoString(&argbuf, ", ");
		appendStringInfoString(&argbuf, format_type_be(argtypes[i]));
	}

	appendStringInfoChar(&argbuf, ')');

	return argbuf.data;			/* return palloc'd string buffer */
}

/*
 * func_signature_string
 *		As above, but function name is passed as a qualified name list.
 */
const char *
func_signature_string(List *funcname, int nargs, const Oid *argtypes)
{
	return funcname_signature_string(NameListToString(funcname),
									 nargs, argtypes);
}

/*
 * LookupFuncName
 *		Given a possibly-qualified function name and a set of argument types,
 *		look up the function.
 *
 * If the function name is not schema-qualified, it is sought in the current
 * namespace search path.
 *
 * If the function is not found, we return InvalidOid if noError is true,
 * else raise an error.
 */
Oid
LookupFuncName(List *funcname, int nargs, const Oid *argtypes, bool noError)
{
	FuncCandidateList clist;

	clist = FuncnameGetCandidates(funcname, nargs, false, false);

	while (clist)
	{
		if (memcmp(argtypes, clist->args, nargs * sizeof(Oid)) == 0)
			return clist->oid;
		clist = clist->next;
	}

	if (!noError)
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_FUNCTION),
				 errmsg("function %s does not exist",
						func_signature_string(funcname, nargs, argtypes))));

	return InvalidOid;
}

/*
 * LookupTypeNameOid
 *		Convenience routine to look up a type, silently accepting shell types
 */
static Oid
LookupTypeNameOid(const TypeName *typename)
{
	Oid			result;
	Type		typtup;

	typtup = LookupTypeName(NULL, typename, NULL);
	if (typtup == NULL)
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
				 errmsg("type \"%s\" does not exist",
						TypeNameToString(typename))));
	result = typeTypeId(typtup);
	ReleaseSysCache(typtup);
	return result;
}

/*
 * LookupFuncNameTypeNames
 *		Like LookupFuncName, but the argument types are specified by a
 *		list of TypeName nodes.
 */
Oid
LookupFuncNameTypeNames(List *funcname, List *argtypes, bool noError)
{
	Oid			argoids[FUNC_MAX_ARGS];
	int			argcount;
	int			i;
	ListCell   *args_item;

	argcount = list_length(argtypes);
	if (argcount > FUNC_MAX_ARGS)
		ereport(ERROR,
				(errcode(ERRCODE_TOO_MANY_ARGUMENTS),
				 errmsg("functions cannot have more than %d arguments",
						FUNC_MAX_ARGS)));

	args_item = list_head(argtypes);
	for (i = 0; i < argcount; i++)
	{
		TypeName   *t = (TypeName *) lfirst(args_item);

		argoids[i] = LookupTypeNameOid(t);
		args_item = lnext(args_item);
	}

	return LookupFuncName(funcname, argcount, argoids, noError);
}

/*
 * LookupAggNameTypeNames
 *		Find an aggregate function given a name and list of TypeName nodes.
 *
 * This is almost like LookupFuncNameTypeNames, but the error messages refer
 * to aggregates rather than plain functions, and we verify that the found
 * function really is an aggregate.
 */
Oid
LookupAggNameTypeNames(List *aggname, List *argtypes, bool noError)
{
	Oid			argoids[FUNC_MAX_ARGS];
	int			argcount;
	int			i;
	ListCell   *lc;
	Oid			oid;
	HeapTuple	ftup;
	Form_pg_proc pform;
	bool		 proisagg;

	argcount = list_length(argtypes);
	if (argcount > FUNC_MAX_ARGS)
		ereport(ERROR,
				(errcode(ERRCODE_TOO_MANY_ARGUMENTS),
				 errmsg("functions cannot have more than %d arguments",
						FUNC_MAX_ARGS)));

	i = 0;
	foreach(lc, argtypes)
	{
		TypeName   *t = (TypeName *) lfirst(lc);

		argoids[i] = LookupTypeNameOid(t);
		i++;
	}

	oid = LookupFuncName(aggname, argcount, argoids, true);

	if (!OidIsValid(oid))
	{
		if (noError)
			return InvalidOid;
		if (argcount == 0)
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_FUNCTION),
					 errmsg("aggregate %s(*) does not exist",
							NameListToString(aggname))));
		else
			ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_FUNCTION),
					 errmsg("aggregate %s does not exist",
							func_signature_string(aggname,
												  argcount, argoids))));
	}

	/* Make sure it's an aggregate */
	/* SELECT proisagg FROM pg_proc */

	ftup = SearchSysCache1(PROCOID, ObjectIdGetDatum(oid));
	if (!HeapTupleIsValid(ftup))	/* should not happen */
		elog(ERROR, "cache lookup failed for function %u", oid);
	pform = (Form_pg_proc) GETSTRUCT(ftup);

	proisagg = pform->proisagg;

	ReleaseSysCache(ftup);

	if (!proisagg)
	{
		if (noError)
			return InvalidOid;
		/* we do not use the (*) notation for functions... */
		ereport(ERROR,
				(errcode(ERRCODE_WRONG_OBJECT_TYPE),
				 errmsg("function %s is not an aggregate",
						func_signature_string(aggname,
											  argcount, argoids))));
	}

	return oid;
}


/*
 * parseCheckTableFunctions
 *
 *	Check for TableValueExpr where they shouldn't be.  Currently the only
 *  valid location for a TableValueExpr is within a call to a table function.
 *  In the full SQL Standard they can exist anywhere a multiset is supported.
 */
void 
parseCheckTableFunctions(ParseState *pstate, Query *qry)
{
	check_table_func_context context;
	context.parent = NULL;
	query_tree_walker(qry, 
					  checkTableFunctions_walker,
					  (void *) &context, 0);
}

static bool 
checkTableFunctions_walker(Node *node, check_table_func_context *context)
{
	if (node == NULL)
		return false;

	/* 
	 * TABLE() value expressions are currently only permited as parameters
	 * to table functions called in the FROM clause.
	 */
	if (IsA(node, TableValueExpr))
	{
		if (context->parent && IsA(context->parent, FuncExpr))
		{ 
			FuncExpr *parent = (FuncExpr *) context->parent;

			/*
			 * This flag is set in addRangeTableEntryForFunction for functions
			 * called as range table entries having TABLE value expressions
			 * as arguments.
			 */
			if (parent->is_tablefunc)
				return false;

			/* Error message could be improved */
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("table functions must be invoked in FROM clause")));
		}
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("invalid use of TABLE value expression")));
		return true;  /* not possible, but keeps compiler happy */
	}

	context->parent = node;
	if (IsA(node, Query))
	{
		return query_tree_walker((Query *) node, 
								 checkTableFunctions_walker,
								 (void *) context, 0);
	}
	else
	{
		return expression_tree_walker(node, 
									  checkTableFunctions_walker, 
									  (void *) context);
	}
}

/*
 * pg_get_expr() is a system function that exposes the expression
 * deparsing functionality in ruleutils.c to users. Very handy, but it was
 * later realized that the functions in ruleutils.c don't check the input
 * rigorously, assuming it to come from system catalogs and to therefore
 * be valid. That makes it easy for a user to crash the backend by passing
 * a maliciously crafted string representation of an expression to
 * pg_get_expr().
 *
 * There's a lot of code in ruleutils.c, so it's not feasible to add
 * water-proof input checking after the fact. Even if we did it once, it
 * would need to be taken into account in any future patches too.
 *
 * Instead, we restrict pg_rule_expr() to only allow input from system
 * catalogs. This is a hack, but it's the most robust and easiest
 * to backpatch way of plugging the vulnerability.
 *
 * This is transparent to the typical usage pattern of
 * "pg_get_expr(systemcolumn, ...)", but will break "pg_get_expr('foo',
 * ...)", even if 'foo' is a valid expression fetched earlier from a
 * system catalog. Hopefully there aren't many clients doing that out there.
 */
void
check_pg_get_expr_args(ParseState *pstate, Oid fnoid, List *args)
{
	Node	   *arg;

	/* if not being called for pg_get_expr, do nothing */
	if (fnoid != F_PG_GET_EXPR && fnoid != F_PG_GET_EXPR_EXT)
		return;

	/* superusers are allowed to call it anyway (dubious) */
	if (superuser())
		return;

	/*
	 * The first argument must be a Var referencing one of the allowed
	 * system-catalog columns.  It could be a join alias Var or subquery
	 * reference Var, though, so we need a recursive subroutine to chase
	 * through those possibilities.
	 */
	Assert(list_length(args) > 1);
	arg = (Node *) linitial(args);

	if (!check_pg_get_expr_arg(pstate, arg, 0))
		ereport(ERROR,
				(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
				 errmsg("argument to pg_get_expr() must come from system catalogs")));
}

static bool
check_pg_get_expr_arg(ParseState *pstate, Node *arg, int netlevelsup)
{
	if (arg && IsA(arg, Var))
	{
		Var		   *var = (Var *) arg;
		RangeTblEntry *rte;
		AttrNumber	attnum;

		netlevelsup += var->varlevelsup;
		rte = GetRTEByRangeTablePosn(pstate, var->varno, netlevelsup);
		attnum = var->varattno;

		if (rte->rtekind == RTE_JOIN)
		{
			/* Recursively examine join alias variable */
			if (attnum > 0 &&
				attnum <= list_length(rte->joinaliasvars))
			{
				arg = (Node *) list_nth(rte->joinaliasvars, attnum - 1);
				return check_pg_get_expr_arg(pstate, arg, netlevelsup);
			}
		}
		else if (rte->rtekind == RTE_SUBQUERY)
		{
			/* Subselect-in-FROM: examine sub-select's output expr */
			TargetEntry *ste = get_tle_by_resno(rte->subquery->targetList,
												attnum);
			ParseState	mypstate;

			if (ste == NULL || ste->resjunk)
				elog(ERROR, "subquery %s does not have attribute %d",
					 rte->eref->aliasname, attnum);
			arg = (Node *) ste->expr;

			/*
			 * Recurse into the sub-select to see what its expr refers to.
			 * We have to build an additional level of ParseState to keep in
			 * step with varlevelsup in the subselect.
			 */
			MemSet(&mypstate, 0, sizeof(mypstate));
			mypstate.parentParseState = pstate;
			mypstate.p_rtable = rte->subquery->rtable;
			/* don't bother filling the rest of the fake pstate */

			return check_pg_get_expr_arg(&mypstate, arg, 0);
		}
		else if (rte->rtekind == RTE_RELATION)
		{
			switch (rte->relid)
			{
				case IndexRelationId:
					if (attnum == Anum_pg_index_indexprs ||
						attnum == Anum_pg_index_indpred)
						return true;
					break;

				case AttrDefaultRelationId:
					if (attnum == Anum_pg_attrdef_adbin)
						return true;
					break;

				case ConstraintRelationId:
					if (attnum == Anum_pg_constraint_conbin)
						return true;
					break;

				case TypeRelationId:
					if (attnum == Anum_pg_type_typdefaultbin)
						return true;
					break;
			}
		}
	}

	return false;
}
