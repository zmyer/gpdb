/*-------------------------------------------------------------------------
 *
 * readfast.c
 *	  Binary Reader functions for Postgres tree nodes.
 *
 * Portions Copyright (c) 2005-2010, Greenplum inc
 * Portions Copyright (c) 1996-2008, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * These routines must be exactly the inverse of the routines in
 * outfast.c.
 *
 * For most node types, these routines are identical to the text reader
 * functions, in readfuncs.c. To avoid code duplication and merge hazards
 * (readfast.c is a Greenplum addon), most read routines borrow the source
 * definition from readfuncs.c, we just compile it with different READ_*
 * macros.
 *
 * The way that works is that readfast.c defines all the necessary macros,
 * as well as COMPILING_BINARY_FUNCS, and then #includes readfuncs.c. For
 * those node types where the binary and text functions are different,
 * the function in readfuncs.c is put in a #ifndef COMPILING_BINARY_FUNCS
 * block, and readfast.c provides the binary version of the function.
 * outfast.c and outfuncs.c have a similar relationship.
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include <math.h>

#include "nodes/parsenodes.h"
#include "nodes/plannodes.h"
#include "nodes/readfuncs.h"
#include "nodes/relation.h"
#include "catalog/pg_class.h"
#include "cdb/cdbgang.h"


/*
 * Macros to simplify reading of different kinds of fields.  Use these
 * wherever possible to reduce the chance for silly typos.
 */


#define READ_LOCALS(nodeTypeName) \
	nodeTypeName *local_node = makeNode(nodeTypeName)

/*
 * no difference between READ_LOCALS and READ_LOCALS_NO_FIELDS in readfast.c,
 * but define both for compatibility.
 */
#define READ_LOCALS_NO_FIELDS(nodeTypeName) \
	READ_LOCALS(nodeTypeName)

/* Allocate non-node variable */
#define ALLOCATE_LOCAL(local, typeName, size) \
	local = (typeName *)palloc0(sizeof(typeName) * size)

/* Read an integer field  */
#define READ_INT_FIELD(fldname) \
	memcpy(&local_node->fldname, read_str_ptr, sizeof(int));  read_str_ptr+=sizeof(int)

/* Read an int16 field  */
#define READ_INT16_FIELD(fldname) \
	memcpy(&local_node->fldname, read_str_ptr, sizeof(int16));  read_str_ptr+=sizeof(int16)

/* Read an unsigned integer field) */
#define READ_UINT_FIELD(fldname) \
	memcpy(&local_node->fldname, read_str_ptr, sizeof(int)); read_str_ptr+=sizeof(int)

/* Read an uint64 field) */
#define READ_UINT64_FIELD(fldname) \
	memcpy(&local_node->fldname, read_str_ptr, sizeof(uint64)); read_str_ptr+=sizeof(uint64)

/* Read an OID field (don't hard-wire assumption that OID is same as uint) */
#define READ_OID_FIELD(fldname) \
	memcpy(&local_node->fldname, read_str_ptr, sizeof(Oid)); read_str_ptr+=sizeof(Oid)

/* Read a long-integer field  */
#define READ_LONG_FIELD(fldname) \
	memcpy(&local_node->fldname, read_str_ptr, sizeof(long)); read_str_ptr+=sizeof(long)

/* Read a char field (ie, one ascii character) */
#define READ_CHAR_FIELD(fldname) \
	memcpy(&local_node->fldname, read_str_ptr, 1); read_str_ptr++

/* Read an enumerated-type field that was written as a short integer code */
#define READ_ENUM_FIELD(fldname, enumtype) \
	{ int16 ent; memcpy(&ent, read_str_ptr, sizeof(int16));  read_str_ptr+=sizeof(int16);local_node->fldname = (enumtype) ent; }

/* Read a float field */
#define READ_FLOAT_FIELD(fldname) \
	memcpy(&local_node->fldname, read_str_ptr, sizeof(double)); read_str_ptr+=sizeof(double)

/* Read a boolean field */
#define READ_BOOL_FIELD(fldname) \
	local_node->fldname = read_str_ptr[0] != 0;  Assert(read_str_ptr[0]==1 || read_str_ptr[0]==0); read_str_ptr++

/* Read a character-string field */
#define READ_STRING_FIELD(fldname) \
	{ int slen; char * nn = NULL; \
		memcpy(&slen, read_str_ptr, sizeof(int)); \
		read_str_ptr+=sizeof(int); \
		if (slen>0) { \
		    nn = palloc(slen+1); \
		    memcpy(nn,read_str_ptr,slen); \
		    read_str_ptr+=(slen); nn[slen]='\0'; \
		} \
		local_node->fldname = nn;  }

/* Read a parse location field (and throw away the value, per notes above) */
#define READ_LOCATION_FIELD(fldname) READ_INT_FIELD(fldname)

/* Read a Node field */
#define READ_NODE_FIELD(fldname) \
	local_node->fldname = readNodeBinary()

/* Read a bitmapset field */
#define READ_BITMAPSET_FIELD(fldname) \
	 local_node->fldname = bitmapsetRead()

/* Read in a binary field */
#define READ_BINARY_FIELD(fldname, sz) \
	memcpy(&local_node->fldname, read_str_ptr, (sz)); read_str_ptr += (sz)

/* Read a bytea field */
#define READ_BYTEA_FIELD(fldname) \
	local_node->fldname = DatumGetPointer(readDatum(false))

/* Read a dummy field */
#define READ_DUMMY_FIELD(fldname,fldvalue) \
	{ local_node->fldname = (0); /*read_str_ptr += sizeof(int*);*/ }

/* Routine exit */
#define READ_DONE() \
	return local_node

/* Read an integer array  */
#define READ_INT_ARRAY(fldname, count, Type) \
	if ( count > 0 ) \
	{ \
		int i; \
		local_node->fldname = (Type *)palloc(count * sizeof(Type)); \
		for(i = 0; i < count; i++) \
		{ \
			memcpy(&local_node->fldname[i], read_str_ptr, sizeof(Type)); read_str_ptr+=sizeof(Type); \
		} \
	}

/* Read a bool array  */
#define READ_BOOL_ARRAY(fldname, count) \
	if ( count > 0 ) \
	{ \
		int i; \
		local_node->fldname = (bool *) palloc(count * sizeof(bool)); \
		for(i = 0; i < count; i++) \
		{ \
			local_node->fldname[i] = *read_str_ptr ? true : false; \
			read_str_ptr++; \
		} \
	}

/* Read an Trasnaction ID array  */
#define READ_XID_ARRAY(fldname, count) \
	if ( count > 0 ) \
	{ \
		int i; \
		local_node->fldname = (TransactionId *)palloc(count * sizeof(TransactionId)); \
		for(i = 0; i < count; i++) \
		{ \
			memcpy(&local_node->fldname[i], read_str_ptr, sizeof(TransactionId)); read_str_ptr+=sizeof(TransactionId); \
		} \
	}



/* Read an Oid array  */
#define READ_OID_ARRAY(fldname, count) \
	if ( count > 0 ) \
	{ \
		int i; \
		local_node->fldname = (Oid *)palloc(count * sizeof(Oid)); \
		for(i = 0; i < count; i++) \
		{ \
			memcpy(&local_node->fldname[i], read_str_ptr, sizeof(Oid)); read_str_ptr+=sizeof(Oid); \
		} \
	}


static void *readNodeBinary(void);

static Datum readDatum(bool typbyval);

/*
 * Current position in the message that we are processing. We can keep
 * this in a global variable because readNodeFromBinaryString() is not
 * re-entrant. This is similar to the current position that pg_strtok()
 * keeps, used by the normal stringToNode() function.
 */
static const char *read_str_ptr;

/*
 * For most structs, we reuse the definitions from readfuncs.c. See comment
 * in readfuncs.c.
 */
#define COMPILING_BINARY_FUNCS
#include "readfuncs.c"

/*
 * For some structs, we have to provide a read functions because it differs
 * from the text version (or the text version doesn't exist at all).
 */

/*
 * _readQuery
 */
static Query *
_readQuery(void)
{
	READ_LOCALS(Query);

	READ_ENUM_FIELD(commandType, CmdType); Assert(local_node->commandType <= CMD_NOTHING);
	READ_ENUM_FIELD(querySource, QuerySource); 	Assert(local_node->querySource <= QSRC_PLANNER);
	READ_BOOL_FIELD(canSetTag);
	READ_NODE_FIELD(utilityStmt);
	READ_INT_FIELD(resultRelation);
	READ_NODE_FIELD(intoClause);
	READ_BOOL_FIELD(hasAggs);
	READ_BOOL_FIELD(hasWindFuncs);
	READ_BOOL_FIELD(hasSubLinks);
	READ_BOOL_FIELD(hasDynamicFunctions);
	READ_NODE_FIELD(rtable);
	READ_NODE_FIELD(jointree);
	READ_NODE_FIELD(targetList);
	READ_NODE_FIELD(returningList);
	READ_NODE_FIELD(groupClause);
	READ_NODE_FIELD(havingQual);
	READ_NODE_FIELD(windowClause);
	READ_NODE_FIELD(distinctClause);
	READ_NODE_FIELD(sortClause);
	READ_NODE_FIELD(scatterClause);
	READ_NODE_FIELD(cteList);
	READ_BOOL_FIELD(hasRecursive);
	READ_BOOL_FIELD(hasModifyingCTE);
	READ_NODE_FIELD(limitOffset);
	READ_NODE_FIELD(limitCount);
	READ_NODE_FIELD(rowMarks);
	READ_NODE_FIELD(setOperations);
	/* policy not serialized */

	READ_DONE();
}

/*
 * _readCurrentOfExpr
 */
static CurrentOfExpr *
_readCurrentOfExpr(void)
{
	READ_LOCALS(CurrentOfExpr);

	READ_STRING_FIELD(cursor_name);
	READ_UINT_FIELD(cvarno);
	READ_OID_FIELD(target_relid);

	READ_DONE();
}

static WindowSpec *
_readWindowSpec(void)
{
	READ_LOCALS(WindowSpec);

	READ_STRING_FIELD(name);
	READ_STRING_FIELD(parent);
	READ_NODE_FIELD(partition);
	READ_NODE_FIELD(order);
	READ_NODE_FIELD(frame);
	READ_INT_FIELD(location);
	READ_DONE();
}

static DMLActionExpr *
_readDMLActionExpr(void)
{
	READ_LOCALS(DMLActionExpr);

	READ_DONE();
}

static PartOidExpr *
_readPartOidExpr(void)
{
	READ_LOCALS(PartOidExpr);

	READ_INT_FIELD(level);

	READ_DONE();
}

static PartDefaultExpr *
_readPartDefaultExpr(void)
{
	READ_LOCALS(PartDefaultExpr);

	READ_INT_FIELD(level);

	READ_DONE();
}

static PartBoundExpr *
_readPartBoundExpr(void)
{
	READ_LOCALS(PartBoundExpr);

	READ_INT_FIELD(level);
	READ_OID_FIELD(boundType);
	READ_BOOL_FIELD(isLowerBound);

	READ_DONE();
}

static PartBoundInclusionExpr *
_readPartBoundInclusionExpr(void)
{
	READ_LOCALS(PartBoundInclusionExpr);

	READ_INT_FIELD(level);
	READ_BOOL_FIELD(isLowerBound);

	READ_DONE();
}

static PartBoundOpenExpr *
_readPartBoundOpenExpr(void)
{
	READ_LOCALS(PartBoundOpenExpr);

	READ_INT_FIELD(level);
	READ_BOOL_FIELD(isLowerBound);

	READ_DONE();
}

/*
 *	Stuff from primnodes.h.
 */

static RangeVar *
_readRangeVar(void)
{
	READ_LOCALS(RangeVar);

	local_node->catalogname = NULL;		/* not currently saved in output
										 * format */

	READ_STRING_FIELD(schemaname);
	READ_STRING_FIELD(relname);
	READ_ENUM_FIELD(inhOpt, InhOption); Assert(local_node->inhOpt <= INH_DEFAULT);
	READ_BOOL_FIELD(istemp);
	READ_NODE_FIELD(alias);
    READ_LOCATION_FIELD(location);

	READ_DONE();
}

/*
 * _readConst
 */
static Const *
_readConst(void)
{
	READ_LOCALS(Const);

	READ_OID_FIELD(consttype);
	READ_INT_FIELD(consttypmod);
	READ_INT_FIELD(constlen);
	READ_BOOL_FIELD(constbyval);
	READ_BOOL_FIELD(constisnull);

	if (local_node->constisnull)
		local_node->constvalue = 0;
	else
		local_node->constvalue = readDatum(local_node->constbyval);

	READ_DONE();
}

static ResTarget *
_readResTarget(void)
{
	READ_LOCALS(ResTarget);

	READ_STRING_FIELD(name);
	READ_NODE_FIELD(indirection);
	READ_NODE_FIELD(val);
	READ_INT_FIELD(location);

	READ_DONE();
}

/*
 * _readConstraint
 */
static Constraint *
_readConstraint(void)
{
	READ_LOCALS(Constraint);

	READ_STRING_FIELD(name);			/* name, or NULL if unnamed */

	READ_ENUM_FIELD(contype,ConstrType);
	Assert(local_node->contype <= CONSTR_ATTR_IMMEDIATE);


	switch (local_node->contype)
	{
		case CONSTR_UNIQUE:
		case CONSTR_PRIMARY:
			READ_NODE_FIELD(keys);
			READ_NODE_FIELD(options);
			READ_STRING_FIELD(indexspace);
		break;

		case CONSTR_CHECK:
		case CONSTR_DEFAULT:
			READ_NODE_FIELD(raw_expr);
			READ_STRING_FIELD(cooked_expr);
		break;

		case CONSTR_NULL:
		case CONSTR_NOTNULL:
		case CONSTR_ATTR_DEFERRABLE:
		case CONSTR_ATTR_NOT_DEFERRABLE:
		case CONSTR_ATTR_DEFERRED:
		case CONSTR_ATTR_IMMEDIATE:
		break;

		default:
			elog(WARNING,"Can't deserialize constraint %d",(int)local_node->contype);
			break;
	}

	READ_DONE();
}

static ReindexStmt *
_readReindexStmt(void)
{
	READ_LOCALS(ReindexStmt);

	READ_ENUM_FIELD(kind,ObjectType); Assert(local_node->kind <= OBJECT_VIEW);
	READ_NODE_FIELD(relation);
	READ_STRING_FIELD(name);
	READ_BOOL_FIELD(do_system);
	READ_BOOL_FIELD(do_user);
	READ_OID_FIELD(relid);

	READ_DONE();
}

static DropStmt *
_readDropStmt(void)
{
	READ_LOCALS(DropStmt);

	READ_NODE_FIELD(objects);
	READ_ENUM_FIELD(removeType,ObjectType);
	READ_ENUM_FIELD(behavior, DropBehavior); Assert(local_node->behavior <= DROP_CASCADE);
	READ_BOOL_FIELD(missing_ok);
	READ_BOOL_FIELD(bAllowPartn);

	READ_DONE();
}

static DropPropertyStmt *
_readDropPropertyStmt(void)
{
	READ_LOCALS(DropPropertyStmt);

	READ_NODE_FIELD(relation);
	READ_STRING_FIELD(property);
	READ_ENUM_FIELD(removeType,ObjectType);
	READ_ENUM_FIELD(behavior, DropBehavior); Assert(local_node->behavior <= DROP_CASCADE);
	READ_BOOL_FIELD(missing_ok);

	READ_DONE();
}

static DropOwnedStmt *
_readDropOwnedStmt(void)
{
	READ_LOCALS(DropOwnedStmt);

	READ_NODE_FIELD(roles);
	READ_ENUM_FIELD(behavior, DropBehavior);

	READ_DONE();
}

static ReassignOwnedStmt *
_readReassignOwnedStmt(void)
{
	READ_LOCALS(ReassignOwnedStmt);

	READ_NODE_FIELD(roles);
	READ_STRING_FIELD(newrole);

	READ_DONE();
}

static TruncateStmt *
_readTruncateStmt(void)
{
	READ_LOCALS(TruncateStmt);

	READ_NODE_FIELD(relations);
	READ_ENUM_FIELD(behavior, DropBehavior);
	Assert(local_node->behavior <= DROP_CASCADE);

	READ_DONE();
}

static AlterTableCmd *
_readAlterTableCmd(void)
{
	READ_LOCALS(AlterTableCmd);

	READ_ENUM_FIELD(subtype, AlterTableType);
	READ_STRING_FIELD(name);
	READ_NODE_FIELD(def);
	READ_NODE_FIELD(transform);
	READ_ENUM_FIELD(behavior, DropBehavior); Assert(local_node->behavior <= DROP_CASCADE);
	READ_BOOL_FIELD(part_expanded);
	READ_NODE_FIELD(partoids);

	READ_DONE();
}

static SetDistributionCmd *
_readSetDistributionCmd(void)
{
	READ_LOCALS(SetDistributionCmd);

	READ_INT_FIELD(backendId);
	READ_NODE_FIELD(relids);
	READ_NODE_FIELD(indexOidMap);
	READ_NODE_FIELD(hiddenTypes);

	READ_DONE();
}

static AlterPartitionCmd *
_readAlterPartitionCmd(void)
{
	READ_LOCALS(AlterPartitionCmd);

	READ_NODE_FIELD(partid);
	READ_NODE_FIELD(arg1);
	READ_NODE_FIELD(arg2);

	READ_DONE();
}

static AlterObjectSchemaStmt *
_readAlterObjectSchemaStmt(void)
{
	READ_LOCALS(AlterObjectSchemaStmt);

	READ_NODE_FIELD(relation);
	READ_NODE_FIELD(object);
	READ_NODE_FIELD(objarg);
	READ_STRING_FIELD(addname);
	READ_STRING_FIELD(newschema);
	READ_ENUM_FIELD(objectType,ObjectType); Assert(local_node->objectType <= OBJECT_VIEW);

	READ_DONE();
}

static AlterOwnerStmt *
_readAlterOwnerStmt(void)
{
	READ_LOCALS(AlterOwnerStmt);

	READ_ENUM_FIELD(objectType,ObjectType); Assert(local_node->objectType <= OBJECT_VIEW);
	READ_NODE_FIELD(relation);
	READ_NODE_FIELD(object);
	READ_NODE_FIELD(objarg);
	READ_STRING_FIELD(addname);
	READ_STRING_FIELD(newowner);

	READ_DONE();
}

static SelectStmt *
_readSelectStmt(void)
{
	READ_LOCALS(SelectStmt);

	READ_NODE_FIELD(distinctClause);
	READ_NODE_FIELD(intoClause);
	READ_NODE_FIELD(targetList);
	READ_NODE_FIELD(fromClause);
	READ_NODE_FIELD(whereClause);
	READ_NODE_FIELD(groupClause);
	READ_NODE_FIELD(havingClause);
	READ_NODE_FIELD(windowClause);
	READ_NODE_FIELD(valuesLists);
	READ_NODE_FIELD(sortClause);
	READ_NODE_FIELD(scatterClause);
	READ_NODE_FIELD(withClause);
	READ_NODE_FIELD(limitOffset);
	READ_NODE_FIELD(limitCount);
	READ_NODE_FIELD(lockingClause);
	READ_ENUM_FIELD(op, SetOperation);
	READ_BOOL_FIELD(all);
	READ_NODE_FIELD(larg);
	READ_NODE_FIELD(rarg);
	READ_NODE_FIELD(distributedBy);
	READ_DONE();
}

static InsertStmt *
_readInsertStmt(void)
{
	READ_LOCALS(InsertStmt);

	READ_NODE_FIELD(relation);
	READ_NODE_FIELD(cols);
	READ_NODE_FIELD(selectStmt);
	READ_NODE_FIELD(returningList);
	READ_DONE();
}

static DeleteStmt *
_readDeleteStmt(void)
{
	READ_LOCALS(DeleteStmt);

	READ_NODE_FIELD(relation);
	READ_NODE_FIELD(usingClause);
	READ_NODE_FIELD(whereClause);
	READ_NODE_FIELD(returningList);
	READ_DONE();
}

static UpdateStmt *
_readUpdateStmt(void)
{
	READ_LOCALS(UpdateStmt);

	READ_NODE_FIELD(relation);
	READ_NODE_FIELD(targetList);
	READ_NODE_FIELD(whereClause);
	READ_NODE_FIELD(returningList);
	READ_DONE();
}

/*
 * _readFuncCall
 *
 * This parsenode is transformed during parse_analyze.
 * It not stored in views = no upgrade implication for changes
 */
static FuncCall *
_readFuncCall(void)
{
	READ_LOCALS(FuncCall);

	READ_NODE_FIELD(funcname);
	READ_NODE_FIELD(args);
    READ_NODE_FIELD(agg_order);
	READ_BOOL_FIELD(agg_star);
	READ_BOOL_FIELD(agg_distinct);
	READ_BOOL_FIELD(func_variadic);
	READ_NODE_FIELD(over);
	READ_INT_FIELD(location);
	READ_NODE_FIELD(agg_filter);
	READ_DONE();
}

static A_Const *
_readAConst(void)
{
	READ_LOCALS(A_Const);

	READ_ENUM_FIELD(val.type, NodeTag);

	switch (local_node->val.type)
	{
		case T_Integer:
			memcpy(&local_node->val.val.ival, read_str_ptr, sizeof(long)); read_str_ptr+=sizeof(long);
			break;
		case T_Float:
		case T_String:
		case T_BitString:
		{
			int slen; char * nn;
			memcpy(&slen, read_str_ptr, sizeof(int));
			read_str_ptr+=sizeof(int);
			nn = palloc(slen+1);
			memcpy(nn,read_str_ptr,slen);
			nn[slen] = '\0';
			local_node->val.val.str = nn; read_str_ptr+=slen;
		}
			break;
	 	case T_Null:
	 	default:
	 		break;
	}

	local_node->typname = NULL;
	READ_NODE_FIELD(typname);
    READ_INT_FIELD(location);   /*CDB*/
	READ_DONE();
}


static A_Indices *
_readA_Indices(void)
{
	READ_LOCALS(A_Indices);
	READ_NODE_FIELD(lidx);
	READ_NODE_FIELD(uidx);
	READ_DONE();
}

static A_Indirection *
_readA_Indirection(void)
{
	READ_LOCALS(A_Indirection);
	READ_NODE_FIELD(arg);
	READ_NODE_FIELD(indirection);
	READ_DONE();
}


static A_Expr *
_readAExpr(void)
{
	READ_LOCALS(A_Expr);

	READ_ENUM_FIELD(kind, A_Expr_Kind);

	Assert(local_node->kind <= AEXPR_IN);

	switch (local_node->kind)
	{
		case AEXPR_OP:

			READ_NODE_FIELD(name);
			break;
		case AEXPR_AND:

			break;
		case AEXPR_OR:

			break;
		case AEXPR_NOT:

			break;
		case AEXPR_OP_ANY:

			READ_NODE_FIELD(name);

			break;
		case AEXPR_OP_ALL:

			READ_NODE_FIELD(name);

			break;
		case AEXPR_DISTINCT:

			READ_NODE_FIELD(name);
			break;
		case AEXPR_NULLIF:

			READ_NODE_FIELD(name);
			break;
		case AEXPR_OF:

			READ_NODE_FIELD(name);
			break;
		case AEXPR_IN:

			READ_NODE_FIELD(name);
			break;
		default:
			elog(ERROR,"Unable to understand A_Expr node ");
			break;
	}

	READ_NODE_FIELD(lexpr);
	READ_NODE_FIELD(rexpr);
	READ_INT_FIELD(location);

	READ_DONE();
}

/*
 * _readAggref
 */
static Aggref *
_readAggref(void)
{
	READ_LOCALS(Aggref);

	READ_OID_FIELD(aggfnoid);
	READ_OID_FIELD(aggtype);
	READ_NODE_FIELD(args);
	READ_UINT_FIELD(agglevelsup);
	READ_BOOL_FIELD(aggstar);
	READ_BOOL_FIELD(aggdistinct);
	READ_ENUM_FIELD(aggstage, AggStage);
    READ_NODE_FIELD(aggorder);

	READ_DONE();
}

/*
 * _readFuncExpr
 */
static FuncExpr *
_readFuncExpr(void)
{
	READ_LOCALS(FuncExpr);

	READ_OID_FIELD(funcid);
	READ_OID_FIELD(funcresulttype);
	READ_BOOL_FIELD(funcretset);
	READ_ENUM_FIELD(funcformat, CoercionForm);
	READ_NODE_FIELD(args);
	READ_BOOL_FIELD(is_tablefunc);

	READ_DONE();
}

/*
 * _readOpExpr
 */
static OpExpr *
_readOpExpr(void)
{
	READ_LOCALS(OpExpr);

	READ_OID_FIELD(opno);
	READ_OID_FIELD(opfuncid);

	/*
	 * The opfuncid is stored in the textual format primarily for debugging
	 * and documentation reasons.  We want to always read it as zero to force
	 * it to be re-looked-up in the pg_operator entry.	This ensures that
	 * stored rules don't have hidden dependencies on operators' functions.
	 * (We don't currently support an ALTER OPERATOR command, but might
	 * someday.)
	 */
/*	local_node->opfuncid = InvalidOid; */

	READ_OID_FIELD(opresulttype);
	READ_BOOL_FIELD(opretset);
	READ_NODE_FIELD(args);

	READ_DONE();
}

/*
 * _readDistinctExpr
 */
static DistinctExpr *
_readDistinctExpr(void)
{
	READ_LOCALS(DistinctExpr);

	READ_OID_FIELD(opno);
	READ_OID_FIELD(opfuncid);

	READ_OID_FIELD(opresulttype);
	READ_BOOL_FIELD(opretset);
	READ_NODE_FIELD(args);

	READ_DONE();
}

/*
 * _readScalarArrayOpExpr
 */
static ScalarArrayOpExpr *
_readScalarArrayOpExpr(void)
{
	READ_LOCALS(ScalarArrayOpExpr);

	READ_OID_FIELD(opno);
	READ_OID_FIELD(opfuncid);

	READ_BOOL_FIELD(useOr);
	READ_NODE_FIELD(args);

	READ_DONE();
}

/*
 * _readBoolExpr
 */
static BoolExpr *
_readBoolExpr(void)
{
	READ_LOCALS(BoolExpr);

	READ_ENUM_FIELD(boolop, BoolExprType);

	READ_NODE_FIELD(args);

	READ_DONE();
}

/*
 * _readSubLink
 */
static SubLink *
_readSubLink(void)
{
	READ_LOCALS(SubLink);

	READ_ENUM_FIELD(subLinkType, SubLinkType);
	READ_NODE_FIELD(testexpr);
	READ_NODE_FIELD(operName);
	READ_INT_FIELD(location);   /*CDB*/
	READ_NODE_FIELD(subselect);

	READ_DONE();
}

/*
 * _readSubPlan
 */
static SubPlan *
_readSubPlan(void)
{
	READ_LOCALS(SubPlan);

    READ_INT_FIELD(qDispSliceId);   /*CDB*/
	READ_ENUM_FIELD(subLinkType, SubLinkType);
	READ_NODE_FIELD(testexpr);
	READ_NODE_FIELD(paramIds);
	READ_INT_FIELD(plan_id);
	READ_OID_FIELD(firstColType);
	READ_INT_FIELD(firstColTypmod);
	READ_BOOL_FIELD(useHashTable);
	READ_BOOL_FIELD(unknownEqFalse);
	READ_BOOL_FIELD(is_initplan); /*CDB*/
	READ_BOOL_FIELD(is_multirow); /*CDB*/
	READ_NODE_FIELD(setParam);
	READ_NODE_FIELD(parParam);
	READ_NODE_FIELD(args);
	READ_NODE_FIELD(extParam);

	READ_DONE();
}

/*
 * _readNullIfExpr
 */
static NullIfExpr *
_readNullIfExpr(void)
{
	READ_LOCALS(NullIfExpr);

	READ_OID_FIELD(opno);
	READ_OID_FIELD(opfuncid);

	READ_OID_FIELD(opresulttype);
	READ_BOOL_FIELD(opretset);
	READ_NODE_FIELD(args);

	READ_DONE();
}

/*
 * _readJoinExpr
 */
static JoinExpr *
_readJoinExpr(void)
{
	READ_LOCALS(JoinExpr);

	READ_ENUM_FIELD(jointype, JoinType);
	READ_BOOL_FIELD(isNatural);
	READ_NODE_FIELD(larg);
	READ_NODE_FIELD(rarg);
	READ_NODE_FIELD(usingClause);   /*CDB*/
	READ_NODE_FIELD(quals);
	READ_NODE_FIELD(alias);
	READ_INT_FIELD(rtindex);

	READ_DONE();
}

/*
 *	Stuff from parsenodes.h.
 */

/*
 * _readRangeTblEntry
 */
static RangeTblEntry *
_readRangeTblEntry(void)
{
	READ_LOCALS(RangeTblEntry);

	/* put alias + eref first to make dump more legible */
	READ_NODE_FIELD(alias);
	READ_NODE_FIELD(eref);
	READ_ENUM_FIELD(rtekind, RTEKind);

	switch (local_node->rtekind)
	{
		case RTE_RELATION:
		case RTE_SPECIAL:
			READ_OID_FIELD(relid);
			break;
		case RTE_SUBQUERY:
			READ_NODE_FIELD(subquery);
			break;
		case RTE_CTE:
			READ_STRING_FIELD(ctename);
			READ_INT_FIELD(ctelevelsup);
			READ_BOOL_FIELD(self_reference);
			READ_NODE_FIELD(ctecoltypes);
			READ_NODE_FIELD(ctecoltypmods);
			break;
		case RTE_FUNCTION:
			READ_NODE_FIELD(funcexpr);
			READ_NODE_FIELD(funccoltypes);
			READ_NODE_FIELD(funccoltypmods);
			break;
		case RTE_TABLEFUNCTION:
			READ_NODE_FIELD(subquery);
			READ_NODE_FIELD(funcexpr);
			READ_NODE_FIELD(funccoltypes);
			READ_NODE_FIELD(funccoltypmods);
			READ_BYTEA_FIELD(funcuserdata);
			break;
		case RTE_VALUES:
			READ_NODE_FIELD(values_lists);
			break;
		case RTE_JOIN:
			READ_ENUM_FIELD(jointype, JoinType);
			READ_NODE_FIELD(joinaliasvars);
			break;
        case RTE_VOID:                                                  /*CDB*/
            break;
		default:
			elog(ERROR, "unrecognized RTE kind: %d",
				 (int) local_node->rtekind);
			break;
	}

	READ_BOOL_FIELD(inh);
	READ_BOOL_FIELD(inFromCl);
	READ_UINT_FIELD(requiredPerms);
	READ_OID_FIELD(checkAsUser);

	READ_BOOL_FIELD(forceDistRandom);
	/* 'pseudocols' is intentionally missing, see out function */
	READ_DONE();
}

/*
 * Greenplum Database additions for serialization support
 */
#include "nodes/plannodes.h"

static void readPlanInfo(Plan *local_node);
static void readScanInfo(Scan *local_node);
static void readJoinInfo(Join *local_node);
static Bitmapset *bitmapsetRead(void);


static CreateExtensionStmt *
_readCreateExtensionStmt(void)
{
	READ_LOCALS(CreateExtensionStmt);
	READ_STRING_FIELD(extname);
	READ_BOOL_FIELD(if_not_exists);
	READ_NODE_FIELD(options);
	READ_ENUM_FIELD(create_ext_state, CreateExtensionState);

	READ_DONE();
}

static CreateStmt *
_readCreateStmt(void)
{
	READ_LOCALS(CreateStmt);

	READ_NODE_FIELD(relation);
	READ_NODE_FIELD(tableElts);
	READ_NODE_FIELD(inhRelations);
	READ_NODE_FIELD(inhOids);
	READ_INT_FIELD(parentOidCount);
	READ_NODE_FIELD(constraints);

	READ_NODE_FIELD(options);
	READ_ENUM_FIELD(oncommit,OnCommitAction);
	READ_STRING_FIELD(tablespacename);
	READ_NODE_FIELD(distributedBy);
	READ_CHAR_FIELD(relKind);
	READ_CHAR_FIELD(relStorage);
	/* policy omitted */
	/* postCreate - for analysis, QD only */
	/* deferredStmts - for analysis, QD only */
	READ_BOOL_FIELD(is_part_child);
	READ_BOOL_FIELD(is_add_part);
	READ_BOOL_FIELD(is_split_part);
	READ_OID_FIELD(ownerid);
	READ_BOOL_FIELD(buildAoBlkdir);
	READ_NODE_FIELD(attr_encodings);

	local_node->policy = NULL;

	/*
	 * Some extra checks to make sure we didn't get lost
	 * during serialization/deserialization
	 */
	Assert(local_node->relKind == RELKIND_INDEX ||
		   local_node->relKind == RELKIND_RELATION ||
		   local_node->relKind == RELKIND_SEQUENCE ||
		   local_node->relKind == RELKIND_UNCATALOGED ||
		   local_node->relKind == RELKIND_TOASTVALUE ||
		   local_node->relKind == RELKIND_VIEW ||
		   local_node->relKind == RELKIND_COMPOSITE_TYPE ||
		   local_node->relKind == RELKIND_AOSEGMENTS ||
		   local_node->relKind == RELKIND_AOBLOCKDIR ||
		   local_node->relKind == RELKIND_AOVISIMAP);
	Assert(local_node->oncommit <= ONCOMMIT_DROP);

	READ_DONE();
}

static ColumnReferenceStorageDirective *
_readColumnReferenceStorageDirective(void)
{
	READ_LOCALS(ColumnReferenceStorageDirective);

	READ_STRING_FIELD(column);
	READ_BOOL_FIELD(deflt);
	READ_NODE_FIELD(encoding);

	READ_DONE();
}


static PartitionBy *
_readPartitionBy(void)
{
	READ_LOCALS(PartitionBy);

	READ_ENUM_FIELD(partType, PartitionByType);
	READ_NODE_FIELD(keys);
	READ_NODE_FIELD(keyopclass);
	READ_NODE_FIELD(partNum);
	READ_NODE_FIELD(subPart);
	READ_NODE_FIELD(partSpec);
	READ_INT_FIELD(partDepth);
	READ_INT_FIELD(partQuiet);
	READ_INT_FIELD(location);

	READ_DONE();
}

static PartitionSpec *
_readPartitionSpec(void)
{
	READ_LOCALS(PartitionSpec);

	READ_NODE_FIELD(partElem);
	READ_NODE_FIELD(subSpec);
	READ_BOOL_FIELD(istemplate);
	READ_INT_FIELD(location);
	READ_NODE_FIELD(enc_clauses);

	READ_DONE();
}

static PartitionElem *
_readPartitionElem(void)
{
	READ_LOCALS(PartitionElem);

	READ_STRING_FIELD(partName);
	READ_NODE_FIELD(boundSpec);
	READ_NODE_FIELD(subSpec);
	READ_BOOL_FIELD(isDefault);
	READ_NODE_FIELD(storeAttr);
	READ_INT_FIELD(partno);
	READ_LONG_FIELD(rrand);
	READ_NODE_FIELD(colencs);
	READ_INT_FIELD(location);

	READ_DONE();
}

static PartitionRangeItem *
_readPartitionRangeItem(void)
{
	READ_LOCALS(PartitionRangeItem);

	READ_NODE_FIELD(partRangeVal);
	READ_ENUM_FIELD(partedge, PartitionEdgeBounding);
	READ_INT_FIELD(location);

	READ_DONE();
}

static PartitionBoundSpec *
_readPartitionBoundSpec(void)
{
	READ_LOCALS(PartitionBoundSpec);

	READ_NODE_FIELD(partStart);
	READ_NODE_FIELD(partEnd);
	READ_NODE_FIELD(partEvery);
	READ_INT_FIELD(location);

	READ_DONE();
}

static PartitionValuesSpec *
_readPartitionValuesSpec(void)
{
	READ_LOCALS(PartitionValuesSpec);

	READ_NODE_FIELD(partValues);
	READ_INT_FIELD(location);

	READ_DONE();
}

static Partition *
_readPartition(void)
{
	READ_LOCALS(Partition);

	READ_OID_FIELD(partid);
	READ_OID_FIELD(parrelid);
	READ_CHAR_FIELD(parkind);
	READ_INT_FIELD(parlevel);
	READ_BOOL_FIELD(paristemplate);
	READ_BINARY_FIELD(parnatts, sizeof(int2));
	READ_INT_ARRAY(paratts, local_node->parnatts, int2);
	READ_OID_ARRAY(parclass, local_node->parnatts);

	READ_DONE();
}

static PartitionRule *
_readPartitionRule(void)
{
	READ_LOCALS(PartitionRule);

	READ_OID_FIELD(parruleid);
	READ_OID_FIELD(paroid);
	READ_OID_FIELD(parchildrelid);
	READ_OID_FIELD(parparentoid);
	READ_BOOL_FIELD(parisdefault);
	READ_STRING_FIELD(parname);
	READ_NODE_FIELD(parrangestart);
	READ_BOOL_FIELD(parrangestartincl);
	READ_NODE_FIELD(parrangeend);
	READ_BOOL_FIELD(parrangeendincl);
	READ_NODE_FIELD(parrangeevery);
	READ_NODE_FIELD(parlistvalues);
	READ_BINARY_FIELD(parruleord, sizeof(int2));
	READ_NODE_FIELD(parreloptions);
	READ_OID_FIELD(partemplatespaceId);
	READ_NODE_FIELD(children);

	READ_DONE();
}

static PartitionNode *
_readPartitionNode(void)
{
	READ_LOCALS(PartitionNode);

	READ_NODE_FIELD(part);
	READ_NODE_FIELD(default_part);
	READ_NODE_FIELD(rules);

	READ_DONE();
}

static CreateExternalStmt *
_readCreateExternalStmt(void)
{
	READ_LOCALS(CreateExternalStmt);

	READ_NODE_FIELD(relation);
	READ_NODE_FIELD(tableElts);
	READ_NODE_FIELD(exttypedesc);
	READ_STRING_FIELD(format);
	READ_NODE_FIELD(formatOpts);
	READ_BOOL_FIELD(isweb);
	READ_BOOL_FIELD(iswritable);
	READ_NODE_FIELD(sreh);
	READ_NODE_FIELD(extOptions);
	READ_NODE_FIELD(encoding);
	READ_NODE_FIELD(distributedBy);

	READ_DONE();
}

static DropPLangStmt *
_readDropPLangStmt(void)
{
	READ_LOCALS(DropPLangStmt);

	READ_STRING_FIELD(plname);
	READ_ENUM_FIELD(behavior, DropBehavior); Assert(local_node->behavior <= DROP_CASCADE);
	READ_BOOL_FIELD(missing_ok);

	READ_DONE();

}

static AlterDomainStmt *
_readAlterDomainStmt(void)
{
	READ_LOCALS(AlterDomainStmt);

	READ_CHAR_FIELD(subtype);
	READ_NODE_FIELD(typname);
	READ_STRING_FIELD(name);
	READ_NODE_FIELD(def);
	READ_ENUM_FIELD(behavior, DropBehavior); Assert(local_node->behavior <= DROP_CASCADE);

	READ_DONE();
}

static RemoveFuncStmt *
_readRemoveFuncStmt(void)
{
	READ_LOCALS(RemoveFuncStmt);
	READ_ENUM_FIELD(kind,ObjectType); Assert(local_node->kind <= OBJECT_VIEW);
	READ_NODE_FIELD(name);
	READ_NODE_FIELD(args);
	READ_ENUM_FIELD(behavior, DropBehavior); Assert(local_node->behavior <= DROP_CASCADE);
	READ_BOOL_FIELD(missing_ok);

	READ_DONE();
}

static DefineStmt *
_readDefineStmt(void)
{
	READ_LOCALS(DefineStmt);
	READ_ENUM_FIELD(kind, ObjectType); Assert(local_node->kind <= OBJECT_VIEW);
	READ_BOOL_FIELD(oldstyle);
	READ_NODE_FIELD(defnames);
	READ_NODE_FIELD(args);
	READ_NODE_FIELD(definition);
	READ_BOOL_FIELD(ordered);   /* CDB */
	READ_BOOL_FIELD(trusted);   /* CDB */

	READ_DONE();

}

static CopyStmt *
_readCopyStmt(void)
{
	READ_LOCALS(CopyStmt);

	READ_NODE_FIELD(relation);
	READ_NODE_FIELD(attlist);
	READ_BOOL_FIELD(is_from);
	READ_BOOL_FIELD(skip_ext_partition);
	READ_STRING_FIELD(filename);
	READ_NODE_FIELD(options);
	READ_NODE_FIELD(sreh);
	READ_NODE_FIELD(partitions);
	READ_NODE_FIELD(ao_segnos);

	READ_DONE();

}
static GrantStmt *
_readGrantStmt(void)
{
	READ_LOCALS(GrantStmt);

	READ_BOOL_FIELD(is_grant);
	READ_ENUM_FIELD(objtype,GrantObjectType);
	READ_NODE_FIELD(objects);
	READ_NODE_FIELD(privileges);
	READ_NODE_FIELD(grantees);
	READ_BOOL_FIELD(grant_option);
	READ_ENUM_FIELD(behavior, DropBehavior); Assert(local_node->behavior <= DROP_CASCADE);
	READ_NODE_FIELD(cooked_privs);

	READ_DONE();
}

static GrantRoleStmt *
_readGrantRoleStmt(void)
{
	READ_LOCALS(GrantRoleStmt);
	READ_NODE_FIELD(granted_roles);
	READ_NODE_FIELD(grantee_roles);
	READ_BOOL_FIELD(is_grant);
	READ_BOOL_FIELD(admin_opt);
	READ_STRING_FIELD(grantor);
	READ_ENUM_FIELD(behavior, DropBehavior); Assert(local_node->behavior <= DROP_CASCADE);

	READ_DONE();
}

static PlannerParamItem *
_readPlannerParamItem(void)
{
	READ_LOCALS(PlannerParamItem);
	READ_NODE_FIELD(item);
	READ_UINT_FIELD(abslevel);

	READ_DONE();
}

/*
 * _readPlannedStmt
 */
static PlannedStmt *
_readPlannedStmt(void)
{
	READ_LOCALS(PlannedStmt);
	READ_ENUM_FIELD(commandType, CmdType);
	READ_ENUM_FIELD(planGen, PlanGenerator);
	READ_BOOL_FIELD(canSetTag);
	READ_BOOL_FIELD(transientPlan);
	READ_NODE_FIELD(planTree);
	READ_NODE_FIELD(rtable);
	READ_NODE_FIELD(resultRelations);
	READ_NODE_FIELD(utilityStmt);
	READ_NODE_FIELD(intoClause);
	READ_NODE_FIELD(subplans);
	READ_BITMAPSET_FIELD(rewindPlanIDs);
	READ_NODE_FIELD(returningLists);
	READ_NODE_FIELD(result_partitions);
	READ_NODE_FIELD(result_aosegnos);
	READ_NODE_FIELD(queryPartOids);
	READ_NODE_FIELD(queryPartsMetadata);
	READ_NODE_FIELD(numSelectorsPerScanId);
	READ_NODE_FIELD(rowMarks);
	READ_NODE_FIELD(relationOids);
	/* invalItems not serialized in outfast.c */
	READ_INT_FIELD(nParamExec);
	READ_INT_FIELD(nMotionNodes);
	READ_INT_FIELD(nInitPlans);
	/* intoPolicy not serialized in outfast.c */

	READ_UINT64_FIELD(query_mem);
	READ_DONE();
}

static QueryDispatchDesc *
_readQueryDispatchDesc(void)
{
	READ_LOCALS(QueryDispatchDesc);

	READ_NODE_FIELD(transientTypeRecords);
	READ_STRING_FIELD(intoTableSpaceName);
	READ_NODE_FIELD(oidAssignments);
	READ_NODE_FIELD(sliceTable);
	READ_NODE_FIELD(cursorPositions);
	READ_DONE();
}

static OidAssignment *
_readOidAssignment(void)
{
	READ_LOCALS(OidAssignment);

	READ_OID_FIELD(catalog);
	READ_STRING_FIELD(objname);
	READ_OID_FIELD(namespaceOid);
	READ_OID_FIELD(keyOid1);
	READ_OID_FIELD(keyOid2);
	READ_OID_FIELD(oid);
	READ_DONE();
}

/*
 * _readPlan
 */
static Plan *
_readPlan(void)
{
	READ_LOCALS(Plan);

	readPlanInfo(local_node);

	READ_DONE();
}

/*
 * _readResult
 */
static Result *
_readResult(void)
{
	READ_LOCALS(Result);

	readPlanInfo((Plan *)local_node);

	READ_NODE_FIELD(resconstantqual);

	READ_BOOL_FIELD(hashFilter);
	READ_NODE_FIELD(hashList);

	READ_DONE();
}

/*
 * _readRepeat
 */
static Repeat *
_readRepeat(void)
{
	READ_LOCALS(Repeat);

	readPlanInfo((Plan *)local_node);

	READ_NODE_FIELD(repeatCountExpr);
	READ_UINT64_FIELD(grouping);

	READ_DONE();
}

/*
 * _readAppend
 */
static Append *
_readAppend(void)
{
	READ_LOCALS(Append);

	readPlanInfo((Plan *)local_node);

	READ_NODE_FIELD(appendplans);
	READ_BOOL_FIELD(isTarget);
	READ_BOOL_FIELD(isZapped);
	READ_BOOL_FIELD(hasXslice);

	READ_DONE();
}

static Sequence *
_readSequence(void)
{
	READ_LOCALS(Sequence);
	readPlanInfo((Plan *)local_node);
	READ_NODE_FIELD(subplans);
	READ_DONE();
}

/*
 * _readBitmapAnd, _readBitmapOr
 */
static BitmapAnd *
_readBitmapAnd(void)
{
	READ_LOCALS(BitmapAnd);

	readPlanInfo((Plan *)local_node);

	READ_NODE_FIELD(bitmapplans);

	READ_DONE();
}

static BitmapOr *
_readBitmapOr(void)
{
    READ_LOCALS(BitmapOr);

    readPlanInfo((Plan *)local_node);

    READ_NODE_FIELD(bitmapplans);

    READ_DONE();
}


/*
 * _readScan
 */
static Scan *
_readScan(void)
{
	READ_LOCALS(Scan);

	readScanInfo(local_node);

	READ_DONE();
}

/*
 * _readSeqScan
 */
static SeqScan *
_readSeqScan(void)
{
	READ_LOCALS(SeqScan);

	readScanInfo((Scan *)local_node);

	READ_DONE();
}

/*
 * _readAppendOnlyScan
 */
static AppendOnlyScan *
_readAppendOnlyScan(void)
{
	READ_LOCALS(AppendOnlyScan);

	readScanInfo((Scan *)local_node);

	READ_DONE();
}

/*
 * _readAOCSScan
 */
static AOCSScan *
_readAOCSScan(void)
{
	READ_LOCALS(AOCSScan);

	readScanInfo((Scan *)local_node);

	READ_DONE();
}

static TableScan *
_readTableScan(void)
{
	READ_LOCALS(TableScan);
	readScanInfo((Scan *)local_node);
	READ_DONE();
}

static DynamicTableScan *
_readDynamicTableScan(void)
{
	READ_LOCALS(DynamicTableScan);
	readScanInfo((Scan *)local_node);
	READ_INT_FIELD(partIndex);
	READ_INT_FIELD(partIndexPrintable);
	READ_DONE();
}

/*
 * _readExternalScan
 */
static ExternalScan *
_readExternalScan(void)
{
	READ_LOCALS(ExternalScan);

	readScanInfo((Scan *)local_node);

	READ_NODE_FIELD(uriList);
	READ_NODE_FIELD(fmtOpts);
	READ_CHAR_FIELD(fmtType);
	READ_BOOL_FIELD(isMasterOnly);
	READ_INT_FIELD(rejLimit);
	READ_BOOL_FIELD(rejLimitInRows);
	READ_OID_FIELD(fmterrtbl);
	READ_INT_FIELD(encoding);
	READ_INT_FIELD(scancounter);

	READ_DONE();
}

static void
readLogicalIndexInfo(LogicalIndexInfo *local_node)
{
	READ_OID_FIELD(logicalIndexOid);
	READ_INT_FIELD(nColumns);
	READ_INT_ARRAY(indexKeys, local_node->nColumns, AttrNumber);
	READ_NODE_FIELD(indPred);
	READ_NODE_FIELD(indExprs);
	READ_BOOL_FIELD(indIsUnique);
	READ_ENUM_FIELD(indType, LogicalIndexType);
	READ_NODE_FIELD(partCons);
	READ_NODE_FIELD(defaultLevels);
}

static void
readIndexScanFields(IndexScan *local_node)
{
	readScanInfo((Scan *)local_node);

	READ_OID_FIELD(indexid);
	READ_NODE_FIELD(indexqual);
	READ_NODE_FIELD(indexqualorig);
	READ_NODE_FIELD(indexstrategy);
	READ_NODE_FIELD(indexsubtype);
	READ_ENUM_FIELD(indexorderdir, ScanDirection);

	if (isDynamicScan(&local_node->scan))
	{
		ALLOCATE_LOCAL(local_node->logicalIndexInfo, LogicalIndexInfo, 1 /* single node allocation  */);
		readLogicalIndexInfo(local_node->logicalIndexInfo);
	}
}

/*
 * _readIndexScan
 */
static IndexScan *
_readIndexScan(void)
{
	READ_LOCALS(IndexScan);

	readIndexScanFields(local_node);

	READ_DONE();
}

static DynamicIndexScan *
_readDynamicIndexScan(void)
{
	READ_LOCALS(DynamicIndexScan);

	/* DynamicIndexScan has some content from IndexScan. */
	readIndexScanFields((IndexScan *)local_node);

	READ_DONE();
}

static BitmapIndexScan *
_readBitmapIndexScan(void)
{
	READ_LOCALS(BitmapIndexScan);

	/* BitmapIndexScan has some content from IndexScan. */
	readIndexScanFields((IndexScan *)local_node);

	READ_DONE();
}

static BitmapHeapScan *
_readBitmapHeapScan(void)
{
	READ_LOCALS(BitmapHeapScan);

	readScanInfo((Scan *)local_node);

	READ_NODE_FIELD(bitmapqualorig);

	READ_DONE();
}

static BitmapAppendOnlyScan *
_readBitmapAppendOnlyScan(void)
{
	READ_LOCALS(BitmapAppendOnlyScan);

	readScanInfo((Scan *)local_node);

	READ_NODE_FIELD(bitmapqualorig);
	READ_BOOL_FIELD(isAORow);

	READ_DONE();
}

static BitmapTableScan *
_readBitmapTableScan(void)
{
	READ_LOCALS(BitmapTableScan);

	readScanInfo((Scan *)local_node);

	READ_NODE_FIELD(bitmapqualorig);

	READ_DONE();
}

/*
 * _readTidScan
 */
static TidScan *
_readTidScan(void)
{
	READ_LOCALS(TidScan);

	readScanInfo((Scan *)local_node);

	READ_NODE_FIELD(tidquals);

	READ_DONE();
}

/*
 * _readSubqueryScan
 */
static SubqueryScan *
_readSubqueryScan(void)
{
	READ_LOCALS(SubqueryScan);

	readScanInfo((Scan *)local_node);

	READ_NODE_FIELD(subplan);
	/* Planner-only: subrtable -- don't serialize. */

	READ_DONE();
}

/*
 * _readFunctionScan
 */
static FunctionScan *
_readFunctionScan(void)
{
	READ_LOCALS(FunctionScan);

	readScanInfo((Scan *)local_node);

	READ_NODE_FIELD(funcexpr);
	READ_NODE_FIELD(funccolnames);
	READ_NODE_FIELD(funccoltypes);
	READ_NODE_FIELD(funccoltypmods);

	READ_DONE();
}

/*
 * _readValuesScan
 */
static ValuesScan *
_readValuesScan(void)
{
	READ_LOCALS(ValuesScan);

	readScanInfo((Scan *)local_node);

	READ_NODE_FIELD(values_lists);

	READ_DONE();
}

/*
 * _readJoin
 */
static Join *
_readJoin(void)
{
	READ_LOCALS(Join);

	readJoinInfo((Join *)local_node);

	READ_DONE();
}

/*
 * _readNestLoop
 */
static NestLoop *
_readNestLoop(void)
{
	READ_LOCALS(NestLoop);

	readJoinInfo((Join *)local_node);

    READ_BOOL_FIELD(outernotreferencedbyinner); /*CDB*/
	READ_BOOL_FIELD(shared_outer);
	READ_BOOL_FIELD(singleton_outer); /*CDB-OLAP*/

    READ_DONE();
}

/*
 * _readMergeJoin
 */
static MergeJoin *
_readMergeJoin(void)
{
	int		numCols;
	READ_LOCALS(MergeJoin);

	readJoinInfo((Join *)local_node);

	READ_NODE_FIELD(mergeclauses);
	numCols = list_length(local_node->mergeclauses);
	READ_OID_ARRAY(mergeFamilies, numCols);
	READ_INT_ARRAY(mergeStrategies, numCols, int);
	READ_BOOL_ARRAY(mergeNullsFirst, numCols);
	READ_BOOL_FIELD(unique_outer);

	READ_DONE();
}

/*
 * _readHashJoin
 */
static HashJoin *
_readHashJoin(void)
{
	READ_LOCALS(HashJoin);

	readJoinInfo((Join *)local_node);

	READ_NODE_FIELD(hashclauses);
	READ_NODE_FIELD(hashqualclauses);

	READ_DONE();
}

/*
 * _readAgg
 */
static Agg *
_readAgg(void)
{
	READ_LOCALS(Agg);

	readPlanInfo((Plan *)local_node);

	READ_ENUM_FIELD(aggstrategy, AggStrategy);
	READ_INT_FIELD(numCols);
	READ_INT_ARRAY(grpColIdx, local_node->numCols, AttrNumber);
	READ_OID_ARRAY(grpOperators, local_node->numCols);
	READ_LONG_FIELD(numGroups);
	READ_INT_FIELD(transSpace);
	READ_INT_FIELD(numNullCols);
	READ_UINT64_FIELD(inputGrouping);
	READ_UINT64_FIELD(grouping);
	READ_BOOL_FIELD(inputHasGrouping);
	READ_INT_FIELD(rollupGSTimes);
	READ_BOOL_FIELD(lastAgg);
	READ_BOOL_FIELD(streaming);

	READ_DONE();
}

/*
 * _readWindowKey
 */
static WindowKey *
_readWindowKey(void)
{
	READ_LOCALS(WindowKey);

	READ_INT_FIELD(numSortCols);
	READ_INT_ARRAY(sortColIdx, local_node->numSortCols, AttrNumber);
	READ_OID_ARRAY(sortOperators, local_node->numSortCols);
	READ_NODE_FIELD(frame);

	READ_DONE();
}

/*
 * _readWindow
 */
static Window *
_readWindow(void)
{
	READ_LOCALS(Window);

	readPlanInfo((Plan *)local_node);

	READ_INT_FIELD(numPartCols);
	READ_INT_ARRAY(partColIdx, local_node->numPartCols, AttrNumber);
	READ_OID_ARRAY(partOperators, local_node->numPartCols);
	READ_NODE_FIELD(windowKeys);

	READ_DONE();
}

/*
 * _readTableFunctionScan
 */
static TableFunctionScan *
_readTableFunctionScan(void)
{
	READ_LOCALS(TableFunctionScan);

	readScanInfo((Scan *)local_node);

	READ_DONE();
}

/*
 * _readMaterial
 */
static Material *
_readMaterial(void)
{
	READ_LOCALS(Material);

    READ_BOOL_FIELD(cdb_strict);

	READ_ENUM_FIELD(share_type, ShareType);
	READ_INT_FIELD(share_id);
	READ_INT_FIELD(driver_slice);
	READ_INT_FIELD(nsharer);
	READ_INT_FIELD(nsharer_xslice);

    readPlanInfo((Plan *)local_node);

	READ_DONE();
}

/*
 * _readShareInputScan
 */
static ShareInputScan *
_readShareInputScan(void)
{
	READ_LOCALS(ShareInputScan);

	READ_ENUM_FIELD(share_type, ShareType);
	READ_INT_FIELD(share_id);
	READ_INT_FIELD(driver_slice);

	readPlanInfo((Plan *)local_node);

	READ_DONE();
}


/*
 * _readSort
 */
static Sort *
_readSort(void)
{

	READ_LOCALS(Sort);

	readPlanInfo((Plan *)local_node);

	READ_INT_FIELD(numCols);
	READ_INT_ARRAY(sortColIdx, local_node->numCols, AttrNumber);
	READ_OID_ARRAY(sortOperators, local_node->numCols);
	READ_BOOL_ARRAY(nullsFirst, local_node->numCols);

    /* CDB */
	READ_BOOL_FIELD(noduplicates);

	READ_ENUM_FIELD(share_type, ShareType);
	READ_INT_FIELD(share_id);
	READ_INT_FIELD(driver_slice);
	READ_INT_FIELD(nsharer);
	READ_INT_FIELD(nsharer_xslice);

	READ_DONE();
}

/*
 * _readUnique
 */
static Unique *
_readUnique(void)
{
	READ_LOCALS(Unique);

	readPlanInfo((Plan *)local_node);

	READ_INT_FIELD(numCols);
	READ_INT_ARRAY(uniqColIdx, local_node->numCols, AttrNumber);
	READ_OID_ARRAY(uniqOperators, local_node->numCols);

	READ_DONE();
}

/*
 * _readSetOp
 */
static SetOp *
_readSetOp(void)
{
	READ_LOCALS(SetOp);

	readPlanInfo((Plan *)local_node);

	READ_ENUM_FIELD(cmd, SetOpCmd);
	READ_INT_FIELD(numCols);
	READ_INT_ARRAY(dupColIdx, local_node->numCols, AttrNumber);
	READ_OID_ARRAY(dupOperators, local_node->numCols);

	READ_INT_FIELD(flagColIdx);

	READ_DONE();
}

/*
 * _readLimit
 */
static Limit *
_readLimit(void)
{
	READ_LOCALS(Limit);

	readPlanInfo((Plan *)local_node);

	READ_NODE_FIELD(limitOffset);
	READ_NODE_FIELD(limitCount);

	READ_DONE();
}

/*
 * _readHash
 */
static Hash *
_readHash(void)
{
	READ_LOCALS(Hash);

	readPlanInfo((Plan *)local_node);
    READ_BOOL_FIELD(rescannable);           /*CDB*/

	READ_DONE();
}

/*
 * _readFlow
 */
static Flow *
_readFlow(void)
{
	READ_LOCALS(Flow);

	READ_ENUM_FIELD(flotype, FlowType);
	READ_ENUM_FIELD(req_move, Movement);
	READ_ENUM_FIELD(locustype, CdbLocusType);
	READ_INT_FIELD(segindex);

	READ_INT_FIELD(numSortCols);
	READ_INT_ARRAY(sortColIdx, local_node->numSortCols, AttrNumber);
	READ_OID_ARRAY(sortOperators, local_node->numSortCols);
	READ_BOOL_ARRAY(nullsFirst, local_node->numSortCols);

	READ_INT_FIELD(numOrderbyCols);

	READ_NODE_FIELD(hashExpr);
	READ_NODE_FIELD(flow_before_req_move);

	READ_DONE();
}

/*
 * _readMotion
 */
static Motion *
_readMotion(void)
{
	READ_LOCALS(Motion);

	READ_INT_FIELD(motionID);
	READ_ENUM_FIELD(motionType, MotionType);

	Assert(local_node->motionType == MOTIONTYPE_FIXED || local_node->motionType == MOTIONTYPE_HASH || local_node->motionType == MOTIONTYPE_EXPLICIT);

	READ_BOOL_FIELD(sendSorted);

	READ_NODE_FIELD(hashExpr);
	READ_NODE_FIELD(hashDataTypes);

	READ_INT_FIELD(numOutputSegs);
	READ_INT_ARRAY(outputSegIdx, local_node->numOutputSegs, int);

	READ_INT_FIELD(numSortCols);
	READ_INT_ARRAY(sortColIdx, local_node->numSortCols, AttrNumber);
	READ_OID_ARRAY(sortOperators, local_node->numSortCols);
	READ_BOOL_ARRAY(nullsFirst, local_node->numSortCols);

	READ_INT_FIELD(segidColIdx);

	readPlanInfo((Plan *)local_node);

	READ_DONE();
}

/*
 * _readDML
 */
static DML *
_readDML(void)
{
	READ_LOCALS(DML);

	READ_UINT_FIELD(scanrelid);
	READ_INT_FIELD(oidColIdx);
	READ_INT_FIELD(actionColIdx);
	READ_INT_FIELD(ctidColIdx);
	READ_INT_FIELD(tupleoidColIdx);

	readPlanInfo((Plan *)local_node);

	READ_DONE();
}

/*
 * _readSplitUpdate
 */
static SplitUpdate *
_readSplitUpdate(void)
{
	READ_LOCALS(SplitUpdate);

	READ_INT_FIELD(actionColIdx);
	READ_INT_FIELD(ctidColIdx);
	READ_INT_FIELD(tupleoidColIdx);
	READ_NODE_FIELD(insertColIdx);
	READ_NODE_FIELD(deleteColIdx);

	readPlanInfo((Plan *)local_node);

	READ_DONE();
}

/*
 * _readRowTrigger
 */
static RowTrigger *
_readRowTrigger(void)
{
	READ_LOCALS(RowTrigger);

	READ_INT_FIELD(relid);
	READ_INT_FIELD(eventFlags);
	READ_NODE_FIELD(oldValuesColIdx);
	READ_NODE_FIELD(newValuesColIdx);

	readPlanInfo((Plan *)local_node);

	READ_DONE();
}

/*
 * _readAssertOp
 */
static AssertOp *
_readAssertOp(void)
{
	READ_LOCALS(AssertOp);

	READ_NODE_FIELD(errmessage);
	READ_INT_FIELD(errcode);

	readPlanInfo((Plan *)local_node);

	READ_DONE();
}

/*
 * _readPartitionSelector
 */
static PartitionSelector *
_readPartitionSelector(void)
{
	READ_LOCALS(PartitionSelector);

	READ_INT_FIELD(relid);
	READ_INT_FIELD(nLevels);
	READ_INT_FIELD(scanId);
	READ_INT_FIELD(selectorId);
	READ_NODE_FIELD(levelEqExpressions);
	READ_NODE_FIELD(levelExpressions);
	READ_NODE_FIELD(residualPredicate);
	READ_NODE_FIELD(propagationExpression);
	READ_NODE_FIELD(printablePredicate);
	READ_BOOL_FIELD(staticSelection);
	READ_NODE_FIELD(staticPartOids);
	READ_NODE_FIELD(staticScanIds);

	readPlanInfo((Plan *)local_node);

	READ_DONE();
}

static Slice *
_readSlice(void)
{
	READ_LOCALS(Slice);

	READ_INT_FIELD(sliceIndex);
	READ_INT_FIELD(rootIndex);
	READ_ENUM_FIELD(gangType, GangType);
	Assert(local_node->gangType <= GANGTYPE_PRIMARY_WRITER);
	READ_INT_FIELD(gangSize);
	READ_INT_FIELD(numGangMembersToBeActive);
	READ_BOOL_FIELD(directDispatch.isDirectDispatch);
	READ_NODE_FIELD(directDispatch.contentIds); /* List of int index */
	READ_DUMMY_FIELD(primaryGang, NULL);
	READ_INT_FIELD(parentIndex); /* List of int index */
	READ_NODE_FIELD(children); /* List of int index */
	READ_NODE_FIELD(primaryProcesses); /* List of (CDBProcess *) */

	READ_DONE();
}

void readScanInfo(Scan *local_node)
{
	readPlanInfo((Plan *)local_node);

	READ_UINT_FIELD(scanrelid);

	READ_INT_FIELD(partIndex);
	READ_INT_FIELD(partIndexPrintable);
}

void readPlanInfo(Plan *local_node)
{
	READ_INT_FIELD(plan_node_id);
	READ_INT_FIELD(plan_parent_node_id);
	READ_FLOAT_FIELD(startup_cost);
	READ_FLOAT_FIELD(total_cost);
	READ_FLOAT_FIELD(plan_rows);
	READ_INT_FIELD(plan_width);
	READ_NODE_FIELD(targetlist);
	READ_NODE_FIELD(qual);
	READ_BITMAPSET_FIELD(extParam);
	READ_BITMAPSET_FIELD(allParam);

	READ_NODE_FIELD(flow);
	READ_INT_FIELD(dispatch);
	READ_BOOL_FIELD(directDispatch.isDirectDispatch);
	READ_NODE_FIELD(directDispatch.contentIds);

	READ_INT_FIELD(nMotionNodes);
	READ_INT_FIELD(nInitPlans);
	READ_NODE_FIELD(sliceTable);

    READ_NODE_FIELD(lefttree);
    READ_NODE_FIELD(righttree);
    READ_NODE_FIELD(initPlan);

    READ_UINT64_FIELD(operatorMemKB);
}

void readJoinInfo(Join *local_node)
{
	readPlanInfo((Plan *) local_node);

	READ_BOOL_FIELD(prefetch_inner);

	READ_ENUM_FIELD(jointype, JoinType);
	READ_NODE_FIELD(joinqual);
}

Bitmapset  *
bitmapsetRead(void)
{


	Bitmapset *bms = NULL;
	int nwords;
	int i;

	memcpy(&nwords, read_str_ptr, sizeof(int)); read_str_ptr+=sizeof(int);
	if (nwords==0)
		return bms;

	bms = palloc(sizeof(int)+nwords*sizeof(bitmapword));
	bms->nwords = nwords;
	for (i = 0; i < nwords; i++)
	{
		memcpy(&bms->words[i], read_str_ptr, sizeof(bitmapword)); read_str_ptr+=sizeof(bitmapword);
	}




	return bms;
}

static CreateTrigStmt *
_readCreateTrigStmt(void)
{
	READ_LOCALS(CreateTrigStmt);

	READ_STRING_FIELD(trigname);
	READ_NODE_FIELD(relation);
	READ_NODE_FIELD(funcname);
	READ_NODE_FIELD(args);
	READ_BOOL_FIELD(before);
	READ_BOOL_FIELD(row);
	{ int slen;
		memcpy(&slen, read_str_ptr, sizeof(int));
		read_str_ptr+=sizeof(int);
		memcpy(local_node->actions,read_str_ptr,slen);
		read_str_ptr+=slen; }
	READ_BOOL_FIELD(isconstraint);
	READ_BOOL_FIELD(deferrable);
	READ_BOOL_FIELD(initdeferred);
	READ_NODE_FIELD(constrrel);
	READ_OID_FIELD(trigOid);

	READ_DONE();

}

static CreateFileSpaceStmt *
_readCreateFileSpaceStmt(void)
{
	READ_LOCALS(CreateFileSpaceStmt);

	READ_STRING_FIELD(filespacename);
	READ_STRING_FIELD(owner);
	READ_NODE_FIELD(locations);

	READ_DONE();
}


static FileSpaceEntry *
_readFileSpaceEntry(void)
{
	READ_LOCALS(FileSpaceEntry);

	READ_INT_FIELD(dbid);
	READ_INT_FIELD(contentid);
	READ_STRING_FIELD(location);
	READ_STRING_FIELD(hostname);

	READ_DONE();
}


static CreateTableSpaceStmt *
_readCreateTableSpaceStmt(void)
{
	READ_LOCALS(CreateTableSpaceStmt);

	READ_STRING_FIELD(tablespacename);
	READ_STRING_FIELD(owner);
	READ_STRING_FIELD(filespacename);

	READ_DONE();
}


static CreateQueueStmt *
_readCreateQueueStmt(void)
{
	READ_LOCALS(CreateQueueStmt);

	READ_STRING_FIELD(queue);
	READ_NODE_FIELD(options);

	READ_DONE();
}
static AlterQueueStmt *
_readAlterQueueStmt(void)
{
	READ_LOCALS(AlterQueueStmt);

	READ_STRING_FIELD(queue);
	READ_NODE_FIELD(options);

	READ_DONE();
}
static DropQueueStmt *
_readDropQueueStmt(void)
{
	READ_LOCALS(DropQueueStmt);

	READ_STRING_FIELD(queue);

	READ_DONE();
}

static CommentStmt *
_readCommentStmt(void)
{
	READ_LOCALS(CommentStmt);

	READ_ENUM_FIELD(objtype, ObjectType);
	READ_NODE_FIELD(objname);
	READ_NODE_FIELD(objargs);
	READ_STRING_FIELD(comment);

	READ_DONE();
}

static TupleDescNode *
_readTupleDescNode(void)
{
	READ_LOCALS(TupleDescNode);

	READ_INT_FIELD(natts);

	local_node->tuple = CreateTemplateTupleDesc(local_node->natts, false);

	READ_INT_FIELD(tuple->natts);
	if (local_node->tuple->natts > 0)
	{
		int i = 0;
		for (; i < local_node->tuple->natts; i++)
		{
			memcpy(local_node->tuple->attrs[i], read_str_ptr, ATTRIBUTE_FIXED_PART_SIZE);
			read_str_ptr+=ATTRIBUTE_FIXED_PART_SIZE;
		}
	}

	READ_OID_FIELD(tuple->tdtypeid);
	READ_INT_FIELD(tuple->tdtypmod);
	READ_INT_FIELD(tuple->tdqdtypmod);
	READ_BOOL_FIELD(tuple->tdhasoid);
	READ_INT_FIELD(tuple->tdrefcount);

	// Transient type don't have constraint.
	local_node->tuple->constr = NULL;

	Assert(local_node->tuple->tdtypeid == RECORDOID);

	READ_DONE();
}

static AlterExtensionStmt *
_readAlterExtensionStmt(void)
{
	READ_LOCALS(AlterExtensionStmt);
	READ_STRING_FIELD(extname);
	READ_NODE_FIELD(options);

	READ_DONE();
}

static AlterExtensionContentsStmt *
_readAlterExtensionContentsStmt(void)
{
	READ_LOCALS(AlterExtensionContentsStmt);

	READ_STRING_FIELD(extname);
	READ_INT_FIELD(action);
	READ_ENUM_FIELD(objtype, ObjectType);
	READ_NODE_FIELD(objname);
	READ_NODE_FIELD(objargs);

	READ_DONE();
}

static AlterTSConfigurationStmt *
_readAlterTSConfigurationStmt(void)
{
	READ_LOCALS(AlterTSConfigurationStmt);

	READ_NODE_FIELD(cfgname);
	READ_NODE_FIELD(tokentype);
	READ_NODE_FIELD(dicts);
	READ_BOOL_FIELD(override);
	READ_BOOL_FIELD(replace);
	READ_BOOL_FIELD(missing_ok);

	READ_DONE();
}

static AlterTSDictionaryStmt *
_readAlterTSDictionaryStmt(void)
{
	READ_LOCALS(AlterTSDictionaryStmt);

	READ_NODE_FIELD(dictname);
	READ_NODE_FIELD(options);

	READ_DONE();
}

static Node *
_readValue(NodeTag nt)
{
	Node * result = NULL;
	if (nt == T_Integer)
	{
		long ival;
		memcpy(&ival, read_str_ptr, sizeof(long)); read_str_ptr+=sizeof(long);
		result = (Node *) makeInteger(ival);
	}
	else if (nt == T_Null)
	{
		Value *val = makeNode(Value);
		val->type = T_Null;
		result = (Node *)val;
	}
	else
	{
		int slen;
		char * nn = NULL;
		memcpy(&slen, read_str_ptr, sizeof(int));
		read_str_ptr+=sizeof(int);

		/*
		 * For the String case we want to create an empty string if slen is
		 * equal to zero, since otherwise we'll set the string to NULL, which
		 * has a different meaning and the NULL case is handed above.
		 */
		if (slen > 0 || nt == T_String)
		{
		    nn = palloc(slen + 1);

			if (slen > 0)
			    memcpy(nn, read_str_ptr, slen);

		    read_str_ptr += (slen);
			nn[slen] = '\0';
		}

		if (nt == T_Float)
			result = (Node *) makeFloat(nn);
		else if (nt == T_String)
			result = (Node *) makeString(nn);
		else if (nt == T_BitString)
			result = (Node *) makeBitString(nn);
		else
			elog(ERROR, "unknown Value node type %i", nt);
	}

	return result;

}

static void *
readNodeBinary(void)
{
	void	   *return_value;
	NodeTag 	nt;
	int16       ntt;

	memcpy(&ntt, read_str_ptr,sizeof(int16));
	read_str_ptr+=sizeof(int16);
	nt = (NodeTag) ntt;

	if (nt==0)
		return NULL;

	if (nt == T_List || nt == T_IntList || nt == T_OidList)
	{
		List	   *l = NIL;
		int listsize = 0;
		int i;

		memcpy(&listsize,read_str_ptr,sizeof(int));
		read_str_ptr+=sizeof(int);

		if (nt == T_IntList)
		{
			int val;
			for (i = 0; i < listsize; i++)
			{
				memcpy(&val,read_str_ptr,sizeof(int));
				read_str_ptr+=sizeof(int);
				l = lappend_int(l, val);
			}
		}
		else if (nt == T_OidList)
		{
			Oid val;
			for (i = 0; i < listsize; i++)
			{
				memcpy(&val,read_str_ptr,sizeof(Oid));
				read_str_ptr+=sizeof(Oid);
				l = lappend_oid(l, val);
			}
		}
		else
		{

			for (i = 0; i < listsize; i++)
			{
				l = lappend(l, readNodeBinary());
			}
		}
		Assert(l->length==listsize);

		return l;
	}

	if (nt == T_Integer || nt == T_Float || nt == T_String ||
	   	nt == T_BitString || nt == T_Null)
	{
		return _readValue(nt);
	}

	switch(nt)
	{
			case T_PlannedStmt:
				return_value = _readPlannedStmt();
				break;
			case T_QueryDispatchDesc:
				return_value = _readQueryDispatchDesc();
				break;
			case T_OidAssignment:
				return_value = _readOidAssignment();
				break;
			case T_Plan:
					return_value = _readPlan();
					break;
			case T_PlannerParamItem:
				return_value = _readPlannerParamItem();
				break;
			case T_Result:
				return_value = _readResult();
				break;
			case T_Repeat:
				return_value = _readRepeat();
				break;
			case T_Append:
				return_value = _readAppend();
				break;
			case T_Sequence:
				return_value = _readSequence();
				break;
			case T_BitmapAnd:
				return_value = _readBitmapAnd();
				break;
			case T_BitmapOr:
				return_value = _readBitmapOr();
				break;
			case T_Scan:
				return_value = _readScan();
				break;
			case T_SeqScan:
				return_value = _readSeqScan();
				break;
			case T_AppendOnlyScan:
				return_value = _readAppendOnlyScan();
				break;
			case T_AOCSScan:
				return_value = _readAOCSScan();
				break;
			case T_TableScan:
				return_value = _readTableScan();
				break;
			case T_DynamicTableScan:
				return_value = _readDynamicTableScan();
				break;
			case T_ExternalScan:
				return_value = _readExternalScan();
				break;
			case T_IndexScan:
				return_value = _readIndexScan();
				break;
			case T_DynamicIndexScan:
				return_value = _readDynamicIndexScan();
				break;
			case T_BitmapIndexScan:
				return_value = _readBitmapIndexScan();
				break;
			case T_BitmapHeapScan:
				return_value = _readBitmapHeapScan();
				break;
			case T_BitmapAppendOnlyScan:
				return_value = _readBitmapAppendOnlyScan();
				break;
			case T_BitmapTableScan:
				return_value = _readBitmapTableScan();
				break;
			case T_TidScan:
				return_value = _readTidScan();
				break;
			case T_SubqueryScan:
				return_value = _readSubqueryScan();
				break;
			case T_FunctionScan:
				return_value = _readFunctionScan();
				break;
			case T_ValuesScan:
				return_value = _readValuesScan();
				break;
			case T_Join:
				return_value = _readJoin();
				break;
			case T_NestLoop:
				return_value = _readNestLoop();
				break;
			case T_MergeJoin:
				return_value = _readMergeJoin();
				break;
			case T_HashJoin:
				return_value = _readHashJoin();
				break;
			case T_Agg:
				return_value = _readAgg();
				break;
			case T_WindowKey:
				return_value = _readWindowKey();
				break;
			case T_Window:
				return_value = _readWindow();
				break;
			case T_TableFunctionScan:
				return_value = _readTableFunctionScan();
				break;
			case T_Material:
				return_value = _readMaterial();
				break;
			case T_ShareInputScan:
				return_value = _readShareInputScan();
				break;
			case T_Sort:
				return_value = _readSort();
				break;
			case T_Unique:
				return_value = _readUnique();
				break;
			case T_SetOp:
				return_value = _readSetOp();
				break;
			case T_Limit:
				return_value = _readLimit();
				break;
			case T_Hash:
				return_value = _readHash();
				break;
			case T_Motion:
				return_value = _readMotion();
				break;
			case T_DML:
				return_value = _readDML();
				break;
			case T_SplitUpdate:
				return_value = _readSplitUpdate();
				break;
			case T_RowTrigger:
				return_value = _readRowTrigger();
				break;
			case T_AssertOp:
				return_value = _readAssertOp();
				break;
			case T_PartitionSelector:
				return_value = _readPartitionSelector();
				break;
			case T_Alias:
				return_value = _readAlias();
				break;
			case T_RangeVar:
				return_value = _readRangeVar();
				break;
			case T_IntoClause:
				return_value = _readIntoClause();
				break;
			case T_Var:
				return_value = _readVar();
				break;
			case T_Const:
				return_value = _readConst();
				break;
			case T_Param:
				return_value = _readParam();
				break;
			case T_Aggref:
				return_value = _readAggref();
				break;
			case T_AggOrder:
				return_value = _readAggOrder();
				break;
			case T_WindowRef:
				return_value = _readWindowRef();
				break;
			case T_ArrayRef:
				return_value = _readArrayRef();
				break;
			case T_FuncExpr:
				return_value = _readFuncExpr();
				break;
			case T_OpExpr:
				return_value = _readOpExpr();
				break;
			case T_DistinctExpr:
				return_value = _readDistinctExpr();
				break;
			case T_ScalarArrayOpExpr:
				return_value = _readScalarArrayOpExpr();
				break;
			case T_BoolExpr:
				return_value = _readBoolExpr();
				break;
			case T_SubLink:
				return_value = _readSubLink();
				break;
			case T_SubPlan:
				return_value = _readSubPlan();
				break;
			case T_FieldSelect:
				return_value = _readFieldSelect();
				break;
			case T_FieldStore:
				return_value = _readFieldStore();
				break;
			case T_RelabelType:
				return_value = _readRelabelType();
				break;
			case T_CoerceViaIO:
				return_value = _readCoerceViaIO();
				break;
			case T_ArrayCoerceExpr:
				return_value = _readArrayCoerceExpr();
				break;
			case T_ConvertRowtypeExpr:
				return_value = _readConvertRowtypeExpr();
				break;
			case T_CaseExpr:
				return_value = _readCaseExpr();
				break;
			case T_CaseWhen:
				return_value = _readCaseWhen();
				break;
			case T_CaseTestExpr:
				return_value = _readCaseTestExpr();
				break;
			case T_ArrayExpr:
				return_value = _readArrayExpr();
				break;
			case T_A_ArrayExpr:
				return_value = _readA_ArrayExpr();
				break;
			case T_RowExpr:
				return_value = _readRowExpr();
				break;
			case T_RowCompareExpr:
				return_value = _readRowCompareExpr();
				break;
			case T_CoalesceExpr:
				return_value = _readCoalesceExpr();
				break;
			case T_MinMaxExpr:
				return_value = _readMinMaxExpr();
				break;
			case T_NullIfExpr:
				return_value = _readNullIfExpr();
				break;
			case T_NullTest:
				return_value = _readNullTest();
				break;
			case T_BooleanTest:
				return_value = _readBooleanTest();
				break;
			case T_XmlExpr:
				return_value = _readXmlExpr();
				break;
			case T_CoerceToDomain:
				return_value = _readCoerceToDomain();
				break;
			case T_CoerceToDomainValue:
				return_value = _readCoerceToDomainValue();
				break;
			case T_SetToDefault:
				return_value = _readSetToDefault();
				break;
			case T_CurrentOfExpr:
				return_value = _readCurrentOfExpr();
				break;
			case T_TargetEntry:
				return_value = _readTargetEntry();
				break;
			case T_RangeTblRef:
				return_value = _readRangeTblRef();
				break;
			case T_JoinExpr:
				return_value = _readJoinExpr();
				break;
			case T_FromExpr:
				return_value = _readFromExpr();
				break;
			case T_Flow:
				return_value = _readFlow();
				break;
			case T_GrantStmt:
				return_value = _readGrantStmt();
				break;
			case T_PrivGrantee:
				return_value = _readPrivGrantee();
				break;
			case T_FuncWithArgs:
				return_value = _readFuncWithArgs();
				break;
			case T_GrantRoleStmt:
				return_value = _readGrantRoleStmt();
				break;
			case T_LockStmt:
				return_value = _readLockStmt();
				break;

			case T_CreateStmt:
				return_value = _readCreateStmt();
				break;
			case T_ColumnReferenceStorageDirective:
				return_value = _readColumnReferenceStorageDirective();
				break;
			case T_PartitionBy:
				return_value = _readPartitionBy();
				break;
			case T_PartitionElem:
				return_value = _readPartitionElem();
				break;
			case T_PartitionRangeItem:
				return_value = _readPartitionRangeItem();
				break;
			case T_PartitionBoundSpec:
				return_value = _readPartitionBoundSpec();
				break;
			case T_PartitionSpec:
				return_value = _readPartitionSpec();
				break;
			case T_PartitionValuesSpec:
				return_value = _readPartitionValuesSpec();
				break;
			case T_Partition:
				return_value = _readPartition();
				break;
			case T_PartitionNode:
				return_value = _readPartitionNode();
				break;
			case T_PgPartRule:
				return_value = _readPgPartRule();
				break;
			case T_PartitionRule:
				return_value = _readPartitionRule();
				break;
			case T_SegfileMapNode:
				return_value = _readSegfileMapNode();
				break;
			case T_ExtTableTypeDesc:
				return_value = _readExtTableTypeDesc();
				break;
			case T_CreateExternalStmt:
				return_value = _readCreateExternalStmt();
				break;
			case T_CreateExtensionStmt:
				return_value = _readCreateExtensionStmt();
				break;
			case T_IndexStmt:
				return_value = _readIndexStmt();
				break;
			case T_ReindexStmt:
				return_value = _readReindexStmt();
				break;

			case T_ConstraintsSetStmt:
				return_value = _readConstraintsSetStmt();
				break;

			case T_CreateFunctionStmt:
				return_value = _readCreateFunctionStmt();
				break;
			case T_FunctionParameter:
				return_value = _readFunctionParameter();
				break;
			case T_RemoveFuncStmt:
				return_value = _readRemoveFuncStmt();
				break;
			case T_AlterFunctionStmt:
				return_value = _readAlterFunctionStmt();
				break;

			case T_DefineStmt:
				return_value = _readDefineStmt();
				break;

			case T_CompositeTypeStmt:
				return_value = _readCompositeTypeStmt();
				break;
			case T_CreateEnumStmt:
				return_value = _readCreateEnumStmt();
				break;
			case T_CreateCastStmt:
				return_value = _readCreateCastStmt();
				break;
			case T_DropCastStmt:
				return_value = _readDropCastStmt();
				break;
			case T_CreateOpClassStmt:
				return_value = _readCreateOpClassStmt();
				break;
			case T_CreateOpClassItem:
				return_value = _readCreateOpClassItem();
				break;
			case T_CreateOpFamilyStmt:
				return_value = _readCreateOpFamilyStmt();
				break;
			case T_AlterOpFamilyStmt:
				return_value = _readAlterOpFamilyStmt();
				break;
			case T_RemoveOpClassStmt:
				return_value = _readRemoveOpClassStmt();
				break;
			case T_RemoveOpFamilyStmt:
				return_value = _readRemoveOpFamilyStmt();
				break;
			case T_CreateConversionStmt:
				return_value = _readCreateConversionStmt();
				break;


			case T_ViewStmt:
				return_value = _readViewStmt();
				break;
			case T_RuleStmt:
				return_value = _readRuleStmt();
				break;
			case T_DropStmt:
				return_value = _readDropStmt();
				break;
			case T_DropPropertyStmt:
				return_value = _readDropPropertyStmt();
				break;

			case T_DropOwnedStmt:
				return_value = _readDropOwnedStmt();
				break;
			case T_ReassignOwnedStmt:
				return_value = _readReassignOwnedStmt();
				break;

			case T_TruncateStmt:
				return_value = _readTruncateStmt();
				break;

			case T_AlterTableStmt:
				return_value = _readAlterTableStmt();
				break;
			case T_AlterTableCmd:
				return_value = _readAlterTableCmd();
				break;
			case T_SetDistributionCmd:
				return_value = _readSetDistributionCmd();
				break;
			case T_InheritPartitionCmd:
				return_value = _readInheritPartitionCmd();
				break;
			case T_AlterPartitionCmd:
				return_value = _readAlterPartitionCmd();
				break;
			case T_AlterPartitionId:
				return_value = _readAlterPartitionId();
				break;

			case T_CreateRoleStmt:
				return_value = _readCreateRoleStmt();
				break;
			case T_DropRoleStmt:
				return_value = _readDropRoleStmt();
				break;
			case T_AlterRoleStmt:
				return_value = _readAlterRoleStmt();
				break;
			case T_AlterRoleSetStmt:
				return_value = _readAlterRoleSetStmt();
				break;

			case T_AlterObjectSchemaStmt:
				return_value = _readAlterObjectSchemaStmt();
				break;

			case T_AlterOwnerStmt:
				return_value = _readAlterOwnerStmt();
				break;

			case T_RenameStmt:
				return_value = _readRenameStmt();
				break;

			case T_CreateSeqStmt:
				return_value = _readCreateSeqStmt();
				break;
			case T_AlterSeqStmt:
				return_value = _readAlterSeqStmt();
				break;
			case T_ClusterStmt:
				return_value = _readClusterStmt();
				break;
			case T_CreatedbStmt:
				return_value = _readCreatedbStmt();
				break;
			case T_DropdbStmt:
				return_value = _readDropdbStmt();
				break;
			case T_CreateDomainStmt:
				return_value = _readCreateDomainStmt();
				break;
			case T_AlterDomainStmt:
				return_value = _readAlterDomainStmt();
				break;

			case T_NotifyStmt:
				return_value = _readNotifyStmt();
				break;
			case T_DeclareCursorStmt:
				return_value = _readDeclareCursorStmt();
				break;

			case T_SingleRowErrorDesc:
				return_value = _readSingleRowErrorDesc();
				break;
			case T_CopyStmt:
				return_value = _readCopyStmt();
				break;
			case T_SelectStmt:
				return_value = _readSelectStmt();
				break;
			case T_InsertStmt:
				return_value = _readInsertStmt();
				break;
			case T_DeleteStmt:
				return_value = _readDeleteStmt();
				break;
			case T_UpdateStmt:
				return_value = _readUpdateStmt();
				break;
			case T_ColumnDef:
				return_value = _readColumnDef();
				break;
			case T_TypeName:
				return_value = _readTypeName();
				break;
			case T_SortBy:
				return_value = _readSortBy();
				break;
			case T_TypeCast:
				return_value = _readTypeCast();
				break;
			case T_IndexElem:
				return_value = _readIndexElem();
				break;
			case T_Query:
				return_value = _readQuery();
				break;
			case T_SortClause:
				return_value = _readSortClause();
				break;
			case T_GroupClause:
				return_value = _readGroupClause();
				break;
			case T_GroupingClause:
				return_value = _readGroupingClause();
				break;
			case T_GroupingFunc:
				return_value = _readGroupingFunc();
				break;
			case T_Grouping:
				return_value = _readGrouping();
				break;
			case T_GroupId:
				return_value = _readGroupId();
				break;
			case T_WindowSpecParse:
				return_value = _readWindowSpecParse();
				break;
			case T_WindowSpec:
				return_value = _readWindowSpec();
				break;
			case T_WindowFrame:
				return_value = _readWindowFrame();
				break;
			case T_WindowFrameEdge:
				return_value = _readWindowFrameEdge();
				break;
			case T_PercentileExpr:
				return_value = _readPercentileExpr();
				break;
			case T_DMLActionExpr:
				return_value = _readDMLActionExpr();
				break;
			case T_PartOidExpr:
				return_value = _readPartOidExpr();
				break;
			case T_PartDefaultExpr:
				return_value = _readPartDefaultExpr();
				break;
			case T_PartBoundExpr:
				return_value = _readPartBoundExpr();
				break;
			case T_PartBoundInclusionExpr:
				return_value = _readPartBoundInclusionExpr();
				break;
			case T_PartBoundOpenExpr:
				return_value = _readPartBoundOpenExpr();
				break;
			case T_RowMarkClause:
				return_value = _readRowMarkClause();
				break;
			case T_WithClause:
				return_value = _readWithClause();
				break;
			case T_CommonTableExpr:
				return_value = _readCommonTableExpr();
				break;
			case T_SetOperationStmt:
				return_value = _readSetOperationStmt();
				break;
			case T_RangeTblEntry:
				return_value = _readRangeTblEntry();
				break;
			case T_A_Expr:
				return_value = _readAExpr();
				break;
			case T_ColumnRef:
				return_value = _readColumnRef();
				break;
			case T_A_Const:
				return_value = _readAConst();
				break;
			case T_A_Indices:
				return_value = _readA_Indices();
				break;
			case T_A_Indirection:
				return_value = _readA_Indirection();
				break;
			case T_ResTarget:
				return_value = _readResTarget();
				break;
			case T_Constraint:
				return_value = _readConstraint();
				break;
			case T_FkConstraint:
				return_value = _readFkConstraint();
				break;
			case T_FuncCall:
				return_value = _readFuncCall();
				break;
			case T_DefElem:
				return_value = _readDefElem();
				break;
			case T_CreateSchemaStmt:
				return_value = _readCreateSchemaStmt();
				break;
			case T_CreatePLangStmt:
				return_value = _readCreatePLangStmt();
				break;
			case T_DropPLangStmt:
				return_value = _readDropPLangStmt();
				break;
			case T_VacuumStmt:
				return_value = _readVacuumStmt();
				break;
			case T_CdbProcess:
				return_value = _readCdbProcess();
				break;
			case T_Slice:
				return_value = _readSlice();
				break;
			case T_SliceTable:
				return_value = _readSliceTable();
				break;
			case T_CursorPosInfo:
				return_value = _readCursorPosInfo();
				break;
			case T_VariableSetStmt:
				return_value = _readVariableSetStmt();
				break;
			case T_CreateTrigStmt:
				return_value = _readCreateTrigStmt();
				break;

			case T_CreateFileSpaceStmt:
				return_value = _readCreateFileSpaceStmt();
				break;

			case T_FileSpaceEntry:
				return_value = _readFileSpaceEntry();
				break;

			case T_CreateTableSpaceStmt:
				return_value = _readCreateTableSpaceStmt();
				break;

			case T_CreateQueueStmt:
				return_value = _readCreateQueueStmt();
				break;
			case T_AlterQueueStmt:
				return_value = _readAlterQueueStmt();
				break;
			case T_DropQueueStmt:
				return_value = _readDropQueueStmt();
				break;

			case T_CommentStmt:
				return_value = _readCommentStmt();
				break;
			case T_DenyLoginInterval:
				return_value = _readDenyLoginInterval();
				break;
			case T_DenyLoginPoint:
				return_value = _readDenyLoginPoint();
				break;

			case T_TableValueExpr:
				return_value = _readTableValueExpr();
				break;

			case T_AlterTypeStmt:
				return_value = _readAlterTypeStmt();
				break;
			case T_AlterExtensionStmt:
				return_value = _readAlterExtensionStmt();
				break;
			case T_AlterExtensionContentsStmt:
				return_value = _readAlterExtensionContentsStmt();
				break;
			case T_TupleDescNode:
				return_value = _readTupleDescNode();
				break;

			case T_AlterTSConfigurationStmt:
				return_value = _readAlterTSConfigurationStmt();
				break;
			case T_AlterTSDictionaryStmt:
				return_value = _readAlterTSDictionaryStmt();
				break;

			default:
				return_value = NULL; /* keep the compiler silent */
				elog(ERROR, "could not deserialize unrecognized node type: %d",
						 (int) nt);
				break;
	}

	return (Node *)return_value;
}

Node *
readNodeFromBinaryString(const char *str_arg, int len __attribute__((unused)))
{
	Node	   *node;
	int16		tg;

	read_str_ptr = str_arg;

	node = readNodeBinary();

	memcpy(&tg, read_str_ptr, sizeof(int16));
	if (tg != (int16)0xDEAD)
		elog(ERROR,"Deserialization lost sync.");

	return node;

}
/*
 * readDatum
 *
 * Given a binary string representation of a constant, recreate the appropriate
 * Datum.  The string representation embeds length info, but not byValue,
 * so we must be told that.
 */
static Datum
readDatum(bool typbyval)
{
	Size		length;

	Datum		res;
	char	   *s;

	if (typbyval)
	{
		memcpy(&res, read_str_ptr, sizeof(Datum)); read_str_ptr+=sizeof(Datum);
	}
	else
	{
		memcpy(&length, read_str_ptr, sizeof(Size)); read_str_ptr+=sizeof(Size);
	  	if (length <= 0)
			res = 0;
		else
		{
			s = (char *) palloc(length+1);
			memcpy(s, read_str_ptr, length); read_str_ptr+=length;
			s[length]='\0';
			res = PointerGetDatum(s);
		}

	}

	return res;
}
