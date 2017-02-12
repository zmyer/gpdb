create schema temp_t;
CREATE TABLE temp_t.sg_cal_detail_r1 (
     datacenter character varying(32),
     poolname character varying(128),
     machinename character varying(128),
     transactionid character varying(32),
     threadid integer,
     transactionorder integer,
     eventclass character(1),
     eventtime timestamp(2) without time zone,
     eventtype character varying(128),
     eventname character varying(128),
     status character varying(128),
     duration numeric(18,2),
     data character varying(4096)
)
WITH (appendonly=true, compresslevel=5, blocksize=2097152)
DISTRIBUTED BY (transactionid)
PARTITION BY RANGE(eventtime) 
SUBPARTITION BY LIST(datacenter)
SUBPARTITION TEMPLATE
(
SUBPARTITION SMF VALUES ('smf01','smf02'),
SUBPARTITION SJC VALUES ('sjc01','sjc02'),
SUBPARTITION DEN VALUES ('den01','den02'),
SUBPARTITION PHX VALUES ('phx01','phx02'),
DEFAULT SUBPARTITION xdc
)
SUBPARTITION BY LIST(eventtype)
SUBPARTITION TEMPLATE
(
SUBPARTITION ET1 VALUES ('EXEC'),
SUBPARTITION ET2 VALUES ('URL','EXECP','ufb'),
SUBPARTITION ET3 VALUES
('EXECT','V3Rules','SOJ','MEQ','RTM','TL','ActiveRules','RTMe','API',
'Info','BizProcess','APIRequest','_ui','Warning','Consume','XML','DSAPar
serTransform'),
SUBPARTITION ET4 VALUES('InflowHandler',
'TaskType',
'LOG',
'FETCH',
'TD',
'AxisInflowPipeline',
'AxisOutflowPipeline',
'API Security',
'SD_DSBE',
'SD_ExpressSale',
'V4Header',
'V4Footer',
'SOAP_Handler',
'MLR',
'EvictedStmtRemove',
'CT',
'DSATransform',
'APIClient',
'DSAQueryExec',
'processDSA',
'FilterEngine',
'Prefetch',
'AsyncCb',
'MC',
'SQL',
'SD_UInfo',
'TnSPayload',
'Serialization',
'CxtSetup',
'LazyInit',
'Deserialization',
'CleanUp',
'RESTDeserialize',
'RESTSerialize',
'SD_StoreNames',
'Serialize',
'Deserialize',
'SVC_INVOKE',
'SD_TitleAggr',
'eLVIS',
'SD_Promo',
'ServerCalLogId',
'SD_DSA',
'ClientCalLogId',
'NCF Async processor',
'V3Rules_OLAP',
'RTAM',
'SOAP_Handlers',
'SOAP_Ser',
'SOAP_Exec',
'RtmAB',
'RTPromotionOptimizer',
'crypt',
'Error',
'DBGetDataHlp',
'NoEncoding',
'Default',
'PromoAppCenter',
'BES_CONSUMER',
'TitleKeywordsModel',
'SOA_CLIENT',
'SD_UserContent',
'NCF',
'BEGenericPortlet',
'PortletExecution',
'SoaPortlet',
'ICEP',
'LOGIC',
'SYI_Eval_Detail',
'SD_Catalog',
'SignIn_Eval_Detail',
'Elvis Client',
'BES',
'TIMESTAMP',
'TLH',
'TLH-PRE-SYI',
'RFC',
'Offer_Eval_Detail',
'SFE_RunQuery',
'DBGetData',
'TKOItem2',
'Notification',
'XSHModel',
'APIDefinition',
'captcha',
'SD_HalfItem',
'Mail_Transport',
'MODPUT',
'60DAY_OLD_ITEM_FETCHED',
'List',
'RemotePortlet',
'MakeOffer_Eval_Detail',
'60_TO_90_DAY_OLD_ITEM_FETCHED',
'Logic',
'RtmGetContentName',
'BEPortletService',
'SYI_EUP_Rbo',
'SYI_Rbo',
'EOA',
'SEC',
'CCHP',
'TKOItem3',
'TnsFindingModelBucket',
'Mail_Send',
'SignIn_Rbo',
'SignIn=23_elvisEvl',
'TnsFindingModelXSH',
'RtmSvc',
'SWEET_TOOTH_LOCATOR_EXPIRED',
'COOKIE_INFO',
'Database',
'RYI_Eval_Detail',
'TnsFindingModelSNP',
'TitleRiskScoringModel_2_0',
'ClientIPin10',
'TnsFindingModelFraud',
'SignIn_BaseRbo2',
'Offer_EUP_Rbo',
'Offer_Rbo',
'FSA',
'Processing_elvis_events',
'NSS_API',
'MyebayBetaRedirect',
'MOTORS_PARTNER_RECIPIENT_HANDLER',
'ElvisEngine',
'PreSyi_Eval_Detail',
'RADAR',
'Latency',
'SD_TAggrCache',
'MEA',
'SD_TitleAggregatorShopping',
'KEM',
'SD_Batch',
'KG',
'ITEM_VISIBILITY',
'APPLOGIC',
'OOPexecute',
'ERRPAGE',
'FQ_RECIPIENT_HANDLER',
'RADAR_POST_Eval_Detail',
'Captcha',
'V3Rules_Detail',
'FilterEngDetail_AAQBuyerSentPre',
'Task',
'SYI_EUP_Report',
'WRITE_MOVE_FILE',
'KG_SYI',
'BatchRecord',
'SD_TitleDesc',
'B001_RTAM',
'SignIn_Report',
'SD_StoreUrl',
'CACHE_REFRESH',
'TKOItem',
'KG_EXTERNAL_CALL',
'WatchDelSkipped',
'SD_Completed',
'RequestCounts',
'FilterEngDetail_RTQEmail',
'FilterEngDetail_AAQBuyerSentPost',
'RYI_EUP_Rbo',
'RYI_Rbo',
'MF_RECIPIENT_HANDLER',
'SYI_Report',
'LCBT',
'HalfRyiSingle_Eval_Detail',
'FilterEngDetail_AAQBuyerSentEmail',
'ViewAdAbTests',
'MakeOffer_EUP_Rbo',
'MakeOffer_Rbo',
'ShipCalc Url',
'Offer_Report',
'TKOUser',
'RADAR_POST_EUP_Rbo',
'SiteStat_LeftNav',
'SiteStat_UserIsSeller',
'FilterEngDetail_RTQPost',
'INFO',
'Offer_EUP_Report',
'RADAR_POST_Rbo',
'SignIn_EUP_Rbo',
'Mail_XML',
'Processing_item_events',
'GEM',
'Mail',
'ELVIS',
'FilterEngDetail_SYIRYI',
'SD_TitleCach',
'Processing_itemend_events',
'HalfRyiSingle_EUP_Rbo',
'AlertNotify',
'AVSRedirectLog',
'BillerService',
'MENMSG',
'UserSegSvc',
'PRICE_CHANGE_ALERT_RECIPIENT_HANDLER',
'NSSOptP',
'PreSyi_Rbo',
'PreSyi_EUP_Rbo',
'NOTIFICATION.BES.BID_NEW',
'Mail_Connect',
'Mail_Close',
'GEMRECORD',
'McapCommunicatorTx',
'IMGPROC',
'KnownGood',
'FilterEngDetail_RTQPre',
'AUTH',
'BULKAPI',
'AAQBuyerSentPre_Eval_Detail',
'RYI_EUP_Report',
'HalfRyiSingle_Rbo',
'MakeOffer_Report',
'ItemClosureLOGIC',
'MakeOffer_EUP_Report',
'RADAR_POST_Report',
'BidBinStats',
'Iterator',
'RADAR_POST_EUP_Report',
'SessionStats',
'RYI_Report',
'SIBE',
'EOT',
'UsageProcessingTx',
'Processing_itemrevised_events',
'HalfSyiSingle_Eval_Detail',
'SignIn_EUP_Report',
'Referer',
'RTQEmail_Eval_Detail',
'AAQBuyerSentPost_Eval_Detail',
'AAQBuyerSentEmail_Eval_Detail',
'NCFEvent',
'CHKOUT',
'SocketWriter',
'RTQPost_Eval_Detail',
'HalfRyiSingle_Report',
'HalfRyiSingle_EUP_Report',
'DcpConnectRequest',
'SD_CatalogCache',
'PreSyi_Report',
'BotSignIn',
'Total Listing : BE_MAIN',
'Z',
'ItemPopularityScore',
'SD_TitleCacheOverflow',
'UserSegmentationCommand',
'FilterEngDetail_AAQSellerSentPre',
'PreSyi_EUP_Report',
'FilterEngDetail_AAQSellerSentPost',
'FilterEngDetail_BestOffer',
'RS',
'FilterEngDetail_AAQSellerSentEmail',
'HalfSyiSingle_EUP_Rbo',
'Service',
'Total Listing : BE_DE',
'BULK.API.HALF.PUT'),
DEFAULT SUBPARTITION etx
)
(
START ('2008-09-30')
END ('2009-02-28')
EVERY (INTERVAL '1 day')
);
select count(*) from pg_partitions;
drop schema temp_t cascade;
