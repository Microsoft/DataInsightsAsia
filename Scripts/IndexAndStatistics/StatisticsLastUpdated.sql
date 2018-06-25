--
--  Author:        Matt Lavery
--  Date:          16/07/2013
--  Purpose:       Reports statistics which are needed to be updated
-- 
--  Version:       0.1.0 
--  Disclaimer:    This script is provided "as is" in accordance with the projects license
--
--  History
--  When        Version     Who         What
--  -----------------------------------------------------------------
--  16/07/2013  0.1.1       mlavery     Initial Coding
--  -----------------------------------------------------------------
--

SELECT DISTINCT SCHEMA_NAME(so.schema_id) AS 'SchemaName'
	, OBJECT_NAME(so.object_id) AS 'TableName'
	, so.object_id AS 'object_id'
	, CASE OBJECTPROPERTY(MAX(so.object_id), 'TableHasClustIndex') 
		WHEN 1 THEN 'Clustered' 
		WHEN 0 THEN 'Heap' 
		ELSE 'Indexed View' 
	END AS 'ClusteredHeap'
	, CASE objectproperty(max(so.object_id), 'TableHasClustIndex') 
		WHEN 0 THEN count(si.index_id) - 1 
		ELSE count(si.index_id) 
	END AS 'IndexCount'
	, MAX(d.ColumnCount) AS 'ColumnCount'
	, MAX(s.StatCount) AS 'StatCount'
	, MAX(dmv.rows) AS 'ApproximateRows'
	, MAX(dmv.rowmodctr) AS 'RowModCtr'
FROM sys.objects so (NOLOCK)
JOIN sys.indexes si (NOLOCK) ON so.object_id = si.object_id AND so.type in (N'U',N'V')
JOIN sysindexes dmv (NOLOCK) ON so.object_id = dmv.id AND si.index_id = dmv.indid
FULL OUTER JOIN (SELECT object_id, count(1) AS ColumnCount FROM sys.columns (NOLOCK) GROUP BY object_id) d ON d.object_id = so.object_id
FULL OUTER JOIN (SELECT object_id, count(1) AS StatCount FROM sys.stats (NOLOCK) GROUP BY object_id) s ON s.object_id = so.object_id
WHERE so.is_ms_shipped = 0
AND so.object_id not in (SELECT major_id FROM sys.extended_properties (NOLOCK) WHERE name = N'microsoft_database_tools_support')
AND indexproperty(so.object_id, si.name, 'IsStatistics') = 0
GROUP BY so.schema_id
	, so.object_id
	, (CASE objectproperty(si.object_id, 'TableHasClustIndex')
		WHEN 1 THEN 'Clustered'
		WHEN 0 THEN 'Heap'
		ELSE 'Indexed View'
	end)
HAVING ( MAX(dmv.rows) > 500 AND MAX(dmv.rowmodctr) > (max(dmv.rows)*0.2 + 500 ))
ORDER BY 1,2

