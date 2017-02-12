/*-------------------------------------------------------------------------
 *
 * gp_segment_config.h
 *    a segment configuration table
 *
 * Copyright (c) 2006-2011, Greenplum Inc.
 *
 *-------------------------------------------------------------------------
 */
#ifndef _GP_SEGMENT_CONFIG_H_
#define _GP_SEGMENT_CONFIG_H_

#include "catalog/genbki.h"

/*
 * Defines for gp_segment_config table
 */
#define GpSegmentConfigRelationName		"gp_segment_configuration"

#define MASTER_DBID 1
#define MASTER_CONTENT_ID (-1)
#define InvalidDbid 0

/* ----------------
 *		gp_segment_configuration definition.  cpp turns this into
 *		typedef struct FormData_gp_segment_configuration
 * ----------------
 */
#define GpSegmentConfigRelationId	5036

CATALOG(gp_segment_configuration,5036) BKI_SHARED_RELATION BKI_WITHOUT_OIDS
{
	int2		dbid;				/* up to 32767 segment databases */
	int2		content;			/* up to 32767 contents -- only 16384 usable with mirroring (see dbid) */

	char		role;				
	char		preferred_role;		
	char		mode;				
	char		status;				
	int4		port;				

	text		hostname;			
	text		address;			

	int4		replication_port;	
	int2vector	san_mounts;			/* one or more mount-points used by this segment. */
} FormData_gp_segment_configuration;

/* no foreign keys */

/* ----------------
 *		Form_gp_segment_configuration corresponds to a pointer to a tuple with
 *		the format of gp_segment_configuration relation.
 * ----------------
 */
typedef FormData_gp_segment_configuration *Form_gp_segment_configuration;


/* ----------------
 *		compiler constants for gp_segment_configuration
 * ----------------
 */
#define Natts_gp_segment_configuration					11
#define Anum_gp_segment_configuration_dbid				1
#define Anum_gp_segment_configuration_content			2
#define Anum_gp_segment_configuration_role				3
#define Anum_gp_segment_configuration_preferred_role	4
#define Anum_gp_segment_configuration_mode				5
#define Anum_gp_segment_configuration_status			6
#define Anum_gp_segment_configuration_port				7
#define Anum_gp_segment_configuration_hostname			8
#define Anum_gp_segment_configuration_address			9
#define Anum_gp_segment_configuration_replication_port	10
#define Anum_gp_segment_configuration_san_mounts		11

#endif /*_GP_SEGMENT_CONFIG_H_*/
