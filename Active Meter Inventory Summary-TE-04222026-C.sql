/******************************************************************************
Author: Teo Espero (MCWD, IT ADMINISTRATOR)
Title: Meter Inventory Summary

Description:
------------
This query returns one meter inventory record per lot using lot, account, meter,
and device information from Springbrook. It identifies the best meter for each
lot as of a reporting date, determines the account to display, aligns account
dates correctly, and supports flexible filtering across major reporting fields.

Version History:
----------------
1.0   03/03/2026	Teo Espero		Initial working version
2.0   04/22/2026	Teo Espero		Added meter ranking logic
2.1   04/22/2026	Teo Espero		Added account selection logic
2.2   04/22/2026	Teo Espero		Fixed account/date mismatch issue
2.3   04/22/2026	Teo Espero		Implemented final account date lookup
2.4   04/22/2026	Teo Espero		Added future account logic
2.5   04/22/2026	Teo Espero		Standardized ZIP code
2.6   04/22/2026	Teo Espero		Added active meter flag
2.7   04/22/2026	Teo Espero		Added exclusion rule
2.8   04/22/2026	Teo Espero		Added filtering parameters
2.9   04/22/2026	Teo Espero		Added Lot and Address filters
3.0   04/22/2026	Teo Espero		Added tax_lot to output
3.1   04/22/2026	Teo Espero		Added expanded flexible filters and examples

Purpose:
--------
- Return one best meter per lot
- Show lot, address, account, and meter details in one result
- Support reporting by cost center, boundary, category, address, account,
  and meter size
- Allow filtering by single value, multiple values, wildcard, or ALL
  depending on the field

Business Rules:
---------------
- Cost Center is derived from Boundary:
    FO = Ord Community
    all others = Marina
- Best meter is selected using ranking logic
- Latest account is selected based on status and reporting date
- If the selected account ended on or before @AsOfDate, the query checks for
  a future account and uses that account and its dates when available
- ZIP code is standardized to 5 digits
- Sewer, hydrant, and deleted service addresses are excluded
- tax_lot is included in the final output

Main Output Columns:
--------------------
- Cost Center
- Boundary
- ST Category
- Unit Type
- Additional Category
- Subdivision
- Connection Type
- Lot no
- Tax No
- Service Address
- City
- State
- Zip Code
- First Connection Date
- Latest Account
- Latest Account Start Date
- Latest Account End Date
- Meter Install Date
- Meter Serial Number
- Meter Manufacturer
- Meter Model
- Meter Size
- Meter Type

Filter Behavior:
----------------
- NULL, empty string, or 'ALL' means no filter
- Comma-separated values mean match any listed value
- Wildcard filters support % and * where applicable
- Multiple active filters are combined using AND logic

Available Filters:
------------------
- @FilterCostCenter
    Supports: multiple values or ALL
    Examples:
      'Marina'
      'Ord Community'
      'Marina,Ord Community'
      'ALL'

- @FilterBoundary
    Supports: multiple values, ALL, wildcard
    Examples:
      'FO'
      'FO,MB'
      'F%'
      '*O*'
      'ALL'

- @FilterSTCategory
    Supports: multiple values, ALL, wildcard
    Examples:
      'SFR'
      'SFR,MFR'
      '%RES%'
      'ALL'

- @FilterUnitType
    Supports: multiple values, ALL, wildcard
    Examples:
      'Single Family'
      'Single Family,Condo'
      '%Condo%'
      'ALL'

- @FilterAdditionalCategory
    Supports: multiple values, ALL, wildcard
    Examples:
      'Senior'
      'Senior,Affordable'
      '%Aff%'
      'ALL'

- @FilterSubdivision
    Supports: multiple values, ALL, wildcard
    Examples:
      'Dunes'
      'Dunes,East Garrison'
      '%Beach%'
      'ALL'

- @FilterConnectionType
    Supports: multiple values, ALL, wildcard
    Examples:
      'Water'
      'Water,Irrigation'
      '%Irr%'
      'ALL'

- @FilterLotNo
    Supports: specific value, multiple values, or ALL
    Examples:
      '10001'
      '10001,10002,10003'
      'ALL'

- @FilterServiceAddress
    Supports: wildcard or ALL
    Examples:
      '123 MAIN ST'
      '%CRESCENT%'
      '*BEACH*'
      'ALL'

- @FilterLatestAccount
    Supports: multiple values, ALL, wildcard
    Examples:
      '123456-001'
      '123456-001,123456-002'
      '123456-%'
      'ALL'

- @FilterMeterSize
    Supports: multiple values, ALL, wildcard
    Examples:
      '5/8'
      '5/8,1,2'
      '2%'
      'ALL'

Example Filter Set 1:
---------------------
- Return everything
    SET @FilterCostCenter         = 'ALL';
    SET @FilterBoundary           = 'ALL';
    SET @FilterSTCategory         = 'ALL';
    SET @FilterUnitType           = 'ALL';
    SET @FilterAdditionalCategory = 'ALL';
    SET @FilterSubdivision        = 'ALL';
    SET @FilterConnectionType     = 'ALL';
    SET @FilterLotNo              = 'ALL';
    SET @FilterServiceAddress     = 'ALL';
    SET @FilterLatestAccount      = 'ALL';
    SET @FilterMeterSize          = 'ALL';

Example Filter Set 2:
---------------------
- Marina lots in FO boundary with residential categories
    SET @FilterCostCenter         = 'Marina';
    SET @FilterBoundary           = 'FO';
    SET @FilterSTCategory         = 'SFR,MFR';
    SET @FilterUnitType           = 'ALL';
    SET @FilterAdditionalCategory = 'ALL';
    SET @FilterSubdivision        = 'ALL';
    SET @FilterConnectionType     = 'Water';
    SET @FilterLotNo              = 'ALL';
    SET @FilterServiceAddress     = 'ALL';
    SET @FilterLatestAccount      = 'ALL';
    SET @FilterMeterSize          = 'ALL';

Example Filter Set 3:
---------------------
- Search by partial address and meter size
    SET @FilterCostCenter         = 'ALL';
    SET @FilterBoundary           = 'ALL';
    SET @FilterSTCategory         = 'ALL';
    SET @FilterUnitType           = 'ALL';
    SET @FilterAdditionalCategory = 'ALL';
    SET @FilterSubdivision        = 'ALL';
    SET @FilterConnectionType     = 'ALL';
    SET @FilterLotNo              = 'ALL';
    SET @FilterServiceAddress     = '%CRESCENT%';
    SET @FilterLatestAccount      = 'ALL';
    SET @FilterMeterSize          = '5/8,1';

Example Filter Set 4:
---------------------
- Specific lots and specific accounts
    SET @FilterCostCenter         = 'ALL';
    SET @FilterBoundary           = 'ALL';
    SET @FilterSTCategory         = 'ALL';
    SET @FilterUnitType           = 'ALL';
    SET @FilterAdditionalCategory = 'ALL';
    SET @FilterSubdivision        = 'ALL';
    SET @FilterConnectionType     = 'ALL';
    SET @FilterLotNo              = '10001,10002,10003';
    SET @FilterServiceAddress     = 'ALL';
    SET @FilterLatestAccount      = '123456-001,234567-001';
    SET @FilterMeterSize          = 'ALL';

Important Notes:
----------------
- Because all active filters use AND logic, each returned row must satisfy every
  filter that is turned on
- Wildcard filters can reduce or expand results depending on how the values are entered
- If expected rows are missing, check for spacing, abbreviations, and exact source
  values in Boundary, ST Category, Unit Type, Subdivision, and Meter Size

Data Quality Notes:
---------------------
A few data issues came up during review of the results:

- Some accounts are inactive, but the meter still shows as active, and there
  is no read history. In some cases, the last account end date goes back as
  far as 1996. I spoke with Derrell about this and will share the file with
  him so the records can be reviewed more closely.
- Some meters have duplicate serial numbers.
- Some install dates are missing or incorrect.
- Some meters are in use, but the device record is marked inactive.
- Some lots have multiple meter records that do not match. For example, one
  record says active but has a removal date, while another says inactive but
  has no removal date.
- In some cases, the newest meter record is not the correct one.
- The service address field is not clean. Some records include extra text,
  such as 'IRRIGATION', which makes the value less suitable for mail merge
  output. Some cleanup will be needed.
- In Springbrook, the install date may actually refer to a register changeout
  rather than a true meter installation. To handle this, the logic checks
  whether the same serial number appears on multiple records with different
  install dates. When that happens, the earliest date found for that serial
  number is treated as the first known occurrence of that meter/register
  combination.

Use Considerations:
-------------------
- The query is designed to produce the best available reporting result from the
  current data, but output quality still depends on underlying data quality.
- Some records may still require operational review and cleanup before they are
  used for formal reporting, mail merge, or inventory reconciliation.
******************************************************************************/

SET NOCOUNT ON;

-------------------------------------------------------------------------------
-- REPORTING DATE
-- This date controls:
-- 1. which meter is considered active/current
-- 2. which account is preferred for display
-- 3. whether future account logic should be used
-------------------------------------------------------------------------------
DECLARE @AsOfDate DATE = '2026-03-31';

-------------------------------------------------------------------------------
-- FILTER PARAMETERS
-- Rules:
-- - Use 'ALL', NULL, or empty string for no filtering
-- - Use comma-separated values for multi-select filters
-- - Use % or * for wildcard-enabled filters
-------------------------------------------------------------------------------
DECLARE @FilterCostCenter         VARCHAR(MAX) = 'ALL';      -- multiple or ALL
DECLARE @FilterBoundary           VARCHAR(MAX) = 'ALL';      -- multiple / ALL / wildcard
DECLARE @FilterSTCategory         VARCHAR(MAX) = 'ALL';      -- multiple / ALL / wildcard
DECLARE @FilterUnitType           VARCHAR(MAX) = 'ALL';      -- multiple / ALL / wildcard
DECLARE @FilterAdditionalCategory VARCHAR(MAX) = 'ALL';      -- multiple / ALL / wildcard
DECLARE @FilterSubdivision        VARCHAR(MAX) = 'ALL';      -- multiple / ALL / wildcard
DECLARE @FilterConnectionType     VARCHAR(MAX) = 'ALL';      -- multiple / ALL / wildcard
DECLARE @FilterLotNo              VARCHAR(MAX) = 'ALL';      -- specific / multiple / ALL
DECLARE @FilterServiceAddress     VARCHAR(MAX) = 'ALL';      -- wildcard / ALL
DECLARE @FilterLatestAccount      VARCHAR(MAX) = 'ALL';  -- multiple / ALL / wildcard
DECLARE @FilterMeterSize          VARCHAR(MAX) = 'ALL';      -- multiple / ALL / wildcard

WITH

-------------------------------------------------------------------------------
-- STEP 0: NORMALIZE FILTER INPUTS
--
-- Purpose:
-- Convert each comma-separated filter parameter into a row set so the final
-- WHERE clause can use EXISTS logic.
--
-- Notes:
-- - Leading/trailing spaces are removed
-- - * is converted to % so users can type either wildcard style
-- - UPPER is used for case-insensitive matching
-------------------------------------------------------------------------------
CostCenterFilter AS (
    SELECT UPPER(LTRIM(RTRIM(value))) AS filter_value
    FROM STRING_SPLIT(COALESCE(@FilterCostCenter, ''), ',')
    WHERE LTRIM(RTRIM(value)) <> ''
),
BoundaryFilter AS (
    SELECT UPPER(REPLACE(LTRIM(RTRIM(value)), '*', '%')) AS filter_value
    FROM STRING_SPLIT(COALESCE(@FilterBoundary, ''), ',')
    WHERE LTRIM(RTRIM(value)) <> ''
),
STCategoryFilter AS (
    SELECT UPPER(REPLACE(LTRIM(RTRIM(value)), '*', '%')) AS filter_value
    FROM STRING_SPLIT(COALESCE(@FilterSTCategory, ''), ',')
    WHERE LTRIM(RTRIM(value)) <> ''
),
UnitTypeFilter AS (
    SELECT UPPER(REPLACE(LTRIM(RTRIM(value)), '*', '%')) AS filter_value
    FROM STRING_SPLIT(COALESCE(@FilterUnitType, ''), ',')
    WHERE LTRIM(RTRIM(value)) <> ''
),
AdditionalCategoryFilter AS (
    SELECT UPPER(REPLACE(LTRIM(RTRIM(value)), '*', '%')) AS filter_value
    FROM STRING_SPLIT(COALESCE(@FilterAdditionalCategory, ''), ',')
    WHERE LTRIM(RTRIM(value)) <> ''
),
SubdivisionFilter AS (
    SELECT UPPER(REPLACE(LTRIM(RTRIM(value)), '*', '%')) AS filter_value
    FROM STRING_SPLIT(COALESCE(@FilterSubdivision, ''), ',')
    WHERE LTRIM(RTRIM(value)) <> ''
),
ConnectionTypeFilter AS (
    SELECT UPPER(REPLACE(LTRIM(RTRIM(value)), '*', '%')) AS filter_value
    FROM STRING_SPLIT(COALESCE(@FilterConnectionType, ''), ',')
    WHERE LTRIM(RTRIM(value)) <> ''
),
LotNoFilter AS (
    SELECT LTRIM(RTRIM(value)) AS filter_value
    FROM STRING_SPLIT(COALESCE(@FilterLotNo, ''), ',')
    WHERE LTRIM(RTRIM(value)) <> ''
),
ServiceAddressFilter AS (
    SELECT UPPER(REPLACE(LTRIM(RTRIM(value)), '*', '%')) AS filter_value
    FROM STRING_SPLIT(COALESCE(@FilterServiceAddress, ''), ',')
    WHERE LTRIM(RTRIM(value)) <> ''
),
LatestAccountFilter AS (
    SELECT UPPER(REPLACE(LTRIM(RTRIM(value)), '*', '%')) AS filter_value
    FROM STRING_SPLIT(COALESCE(@FilterLatestAccount, ''), ',')
    WHERE LTRIM(RTRIM(value)) <> ''
),
MeterSizeFilter AS (
    SELECT UPPER(REPLACE(LTRIM(RTRIM(value)), '*', '%')) AS filter_value
    FROM STRING_SPLIT(COALESCE(@FilterMeterSize, ''), ',')
    WHERE LTRIM(RTRIM(value)) <> ''
),

-------------------------------------------------------------------------------
-- STEP 1: LOT / ADDRESS DATA
--
-- Purpose:
-- Pull the base lot-level information used throughout the query.
--
-- Includes:
-- - Boundary, ST Category, Subdivision, Unit Type
-- - Additional Category, Connection Type
-- - tax_lot
-- - constructed service address
-- - normalized ZIP code
--
-- Notes:
-- - service_address is built from street components and addr_2
-- - ZIP is standardized to a 5-digit format
-------------------------------------------------------------------------------
AddressMatch AS (
    SELECT
        l.lot_no,
        l.tax_lot,
        l.misc_1  AS Boundary,
        l.misc_2  AS st_category,
        l.misc_5  AS Subdivision,
        l.misc_14 AS UnitType,
        l.misc_15 AS Additional_Category,
        l.misc_16 AS ConnectionType,
        LTRIM(RTRIM(
            COALESCE(CAST(l.street_number AS VARCHAR(20)), '') + ' ' +
            COALESCE(l.street_directional, '') + ' ' +
            COALESCE(l.street_name, '') +
            CASE
                WHEN l.addr_2 IS NOT NULL AND LTRIM(RTRIM(l.addr_2)) <> ''
                    THEN ' ' + l.addr_2
                ELSE ''
            END
        )) AS service_address,
        l.city,
        l.state,
        CASE
            WHEN l.zip IS NULL OR LTRIM(RTRIM(CAST(l.zip AS VARCHAR(20)))) = '' THEN NULL
            ELSE RIGHT(
                '00000' +
                LEFT(
                    REPLACE(REPLACE(LTRIM(RTRIM(CAST(l.zip AS VARCHAR(20)))), '-', ''), ' ', ''),
                    5
                ),
            5)
        END AS zip
    FROM Springbrook0.dbo.lot l
),

-------------------------------------------------------------------------------
-- STEP 2: FIRST CONNECTION DATE
--
-- Purpose:
-- Find the earliest known connect_date for each lot in ub_master.
--
-- Business Use:
-- This gives the first connection date shown in the final report.
-------------------------------------------------------------------------------
FirstConnection AS (
    SELECT
        um.lot_no,
        MIN(um.connect_date) AS first_connection_date
    FROM Springbrook0.dbo.ub_master um
    WHERE um.lot_no IS NOT NULL
    GROUP BY um.lot_no
),

-------------------------------------------------------------------------------
-- STEP 3: RANK METERS
--
-- Purpose:
-- Evaluate all meter connections for each lot and assign a ranking so the query
-- can choose one best meter record per lot.
--
-- Ranking Logic:
-- 1 = active meter installed by @AsOfDate and not removed by @AsOfDate
-- 2 = active meter not meeting the first condition
-- 3 = not active, but still not removed as of @AsOfDate
-- 4 = all others
--
-- Notes:
-- - Only meters installed on or before @AsOfDate are considered
-- - Meters removed on or before @AsOfDate are excluded
-- - Sewer serials ending in -S are excluded
-- - Hydrant-related serial patterns are excluded
-------------------------------------------------------------------------------
RankedMeters AS (
    SELECT
        mc.lot_no,
        mc.ub_meter_con_id,
        mc.ub_device_id,
        mc.install_date,
        mc.remove_date,
        mc.con_status,
        mc.location,
        mc.service_point,
        CASE
            WHEN mc.install_date <= @AsOfDate
                 AND (mc.remove_date IS NULL OR mc.remove_date > @AsOfDate)
                 AND mc.con_status = 'Active' THEN 1
            WHEN mc.con_status = 'Active' THEN 2
            WHEN mc.remove_date IS NULL OR mc.remove_date > @AsOfDate THEN 3
            ELSE 4
        END AS meter_rank,
        ROW_NUMBER() OVER (
            PARTITION BY mc.lot_no
            ORDER BY
                CASE
                    WHEN mc.install_date <= @AsOfDate
                         AND (mc.remove_date IS NULL OR mc.remove_date > @AsOfDate)
                         AND mc.con_status = 'Active' THEN 1
                    WHEN mc.con_status = 'Active' THEN 2
                    WHEN mc.remove_date IS NULL OR mc.remove_date > @AsOfDate THEN 3
                    ELSE 4
                END,
                mc.ub_meter_con_id DESC
        ) AS rn
    FROM Springbrook0.dbo.ub_meter_con mc
    INNER JOIN Springbrook0.dbo.ub_device ud
        ON mc.ub_device_id = ud.ub_device_id
    WHERE mc.lot_no IS NOT NULL
      AND mc.ub_meter_con_id IS NOT NULL
      AND mc.install_date <= @AsOfDate
      AND (mc.remove_date IS NULL OR mc.remove_date > @AsOfDate)
      AND ISNULL(ud.serial_no, '') NOT LIKE '%-S%'
      AND UPPER(ISNULL(ud.serial_no, '')) NOT LIKE '%HYDRANT%'
),

-------------------------------------------------------------------------------
-- STEP 4: BEST METER PER LOT
--
-- Purpose:
-- Keep only the top-ranked meter for each lot.
--
-- Output:
-- - one meter row per lot
-- - includes is_active_meter flag for reporting/debugging use
-------------------------------------------------------------------------------
LatestMeter AS (
    SELECT
        rm.lot_no,
        rm.ub_meter_con_id,
        rm.ub_device_id,
        rm.install_date,
        rm.location,
        rm.service_point,
        rm.meter_rank,
        rm.con_status,
        CASE
            WHEN rm.con_status = 'Active'
             AND rm.install_date <= @AsOfDate
             AND (rm.remove_date IS NULL OR rm.remove_date > @AsOfDate)
            THEN 1 ELSE 0
        END AS is_active_meter
    FROM RankedMeters rm
    WHERE rm.rn = 1
),

-------------------------------------------------------------------------------
-- STEP 5: DETERMINE THE ACCOUNT TO DISPLAY
--
-- Purpose:
-- Select the displayed account number for each lot.
--
-- Selection Priority:
-- 1. Active account as of @AsOfDate
-- 2. If none exists, latest account connected on or before @AsOfDate
--
-- Notes:
-- - display_account_no is formatted as xxxxxx-xxx
-------------------------------------------------------------------------------
SelectedAccount AS (
    SELECT
        am.lot_no,
        sel.display_account_no
    FROM AddressMatch am
    OUTER APPLY (
        SELECT TOP 1
            chosen.display_account_no
        FROM (
            SELECT
                RIGHT('000000' + CAST(um.cust_no AS VARCHAR(6)), 6) + '-' +
                RIGHT('000' + CAST(um.cust_sequence AS VARCHAR(3)), 3) AS display_account_no,
                1 AS priority_order,
                um.ub_master_id
            FROM Springbrook0.dbo.ub_master um
            WHERE um.lot_no = am.lot_no
              AND UPPER(LTRIM(RTRIM(um.acct_status))) = 'ACTIVE'
              AND um.connect_date <= @AsOfDate
              AND (
                    um.final_date IS NULL
                    OR um.final_date > @AsOfDate
                  )

            UNION ALL

            SELECT
                RIGHT('000000' + CAST(um.cust_no AS VARCHAR(6)), 6) + '-' +
                RIGHT('000' + CAST(um.cust_sequence AS VARCHAR(3)), 3) AS display_account_no,
                2 AS priority_order,
                um.ub_master_id
            FROM Springbrook0.dbo.ub_master um
            WHERE um.lot_no = am.lot_no
              AND um.connect_date <= @AsOfDate
        ) chosen
        ORDER BY
            chosen.priority_order,
            chosen.ub_master_id DESC
    ) sel
),

-------------------------------------------------------------------------------
-- STEP 6: FINAL SHAPED RESULT BEFORE FILTERING
--
-- Purpose:
-- Assemble the final reportable row before filters are applied.
--
-- Includes:
-- - cost center derivation
-- - first connection date
-- - displayed account
-- - aligned account start/end dates
-- - future account replacement logic
-- - meter details
--
-- Important Account Logic:
-- If the selected displayed account ended on or before @AsOfDate, the query
-- checks for a future account and uses that future account and its dates if found.
-------------------------------------------------------------------------------
FinalData AS (
    SELECT
        CASE
            WHEN UPPER(ISNULL(am.Boundary, '')) LIKE '%FO%' THEN 'Ord Community'
            ELSE 'Marina'
        END AS [Cost Center],

        am.Boundary AS [Boundary],
        am.st_category AS [ST Category],
        am.UnitType AS [Unit Type],
        am.Additional_Category AS [Additional Category],
        am.Subdivision AS [Subdivision],
        am.ConnectionType AS [Connection Type],
        am.lot_no AS [Lot no],
        am.tax_lot AS [Tax No],
        am.service_address AS [Service Address],
        am.city AS [City],
        am.state AS [State],
        am.zip AS [Zip Code],
        CONVERT(VARCHAR(10), fc.first_connection_date, 101) AS [First Connection Date],

        CASE
            WHEN acct_dates.final_date IS NOT NULL
                 AND acct_dates.final_date <= @AsOfDate
                 AND future_acct.future_account_no IS NOT NULL
                THEN future_acct.future_account_no
            ELSE sa.display_account_no
        END AS [Latest Account],

        CONVERT(VARCHAR(10),
            CASE
                WHEN acct_dates.final_date IS NOT NULL
                     AND acct_dates.final_date <= @AsOfDate
                     AND future_acct.future_connect_date IS NOT NULL
                    THEN future_acct.future_connect_date
                ELSE acct_dates.connect_date
            END
        , 101) AS [Latest Account Start Date],

        CONVERT(VARCHAR(10),
            CASE
                WHEN acct_dates.final_date IS NOT NULL
                     AND acct_dates.final_date <= @AsOfDate
                     AND future_acct.future_connect_date IS NOT NULL
                    THEN future_acct.future_final_date
                ELSE acct_dates.final_date
            END
        , 101) AS [Latest Account End Date],

        CONVERT(VARCHAR(10), lm.install_date, 101) AS [Meter Install Date],
        ud.serial_no AS [Meter Serial Number],
        udt.manufacturer AS [Meter Manufacturer],
        udt.model_no AS [Meter Model],
        udt.device_size AS [Meter Size],
        udt.meter_type AS [Meter Type]

    FROM AddressMatch am
    INNER JOIN LatestMeter lm
        ON am.lot_no = lm.lot_no
    LEFT JOIN SelectedAccount sa
        ON am.lot_no = sa.lot_no

    ----------------------------------------------------------------------------
    -- Get the dates for the selected displayed account
    -- This prevents account/date mismatch by retrieving dates from the same
    -- displayed account actually chosen in SelectedAccount
    ----------------------------------------------------------------------------
    OUTER APPLY (
        SELECT TOP 1
            um.connect_date,
            um.final_date,
            um.ub_master_id
        FROM Springbrook0.dbo.ub_master um
        WHERE RIGHT('000000' + CAST(um.cust_no AS VARCHAR(6)), 6) + '-' +
              RIGHT('000' + CAST(um.cust_sequence AS VARCHAR(3)), 3) = sa.display_account_no
          AND um.lot_no = am.lot_no
        ORDER BY um.ub_master_id DESC
    ) acct_dates

    ----------------------------------------------------------------------------
    -- If the selected displayed account already ended by @AsOfDate,
    -- look for the latest future account for the lot
    ----------------------------------------------------------------------------
    OUTER APPLY (
        SELECT TOP 1
            RIGHT('000000' + CAST(um.cust_no AS VARCHAR(6)), 6) + '-' +
            RIGHT('000' + CAST(um.cust_sequence AS VARCHAR(3)), 3) AS future_account_no,
            um.connect_date AS future_connect_date,
            um.final_date AS future_final_date,
            um.ub_master_id
        FROM Springbrook0.dbo.ub_master um
        WHERE um.lot_no = am.lot_no
          AND um.connect_date > @AsOfDate
        ORDER BY um.ub_master_id DESC
    ) future_acct

    LEFT JOIN FirstConnection fc
        ON am.lot_no = fc.lot_no
    LEFT JOIN Springbrook0.dbo.ub_device ud
        ON lm.ub_device_id = ud.ub_device_id
    LEFT JOIN Springbrook0.dbo.ub_device_type udt
        ON ud.ub_device_type_id = udt.ub_device_type_id

    ----------------------------------------------------------------------------
    -- Exclusion rules
    -- These remove obvious non-reportable or non-customer service-address rows
    ----------------------------------------------------------------------------
    WHERE
        UPPER(ISNULL(am.service_address, '')) NOT LIKE '%SEWER%'
        AND UPPER(ISNULL(am.service_address, '')) NOT LIKE '%HYDRANT%'
        AND UPPER(ISNULL(am.service_address, '')) NOT LIKE '%DELETED%'
)

-------------------------------------------------------------------------------
-- FINAL RESULT WITH FLEXIBLE FILTERS
--
-- Filtering Model:
-- - Each filter block is optional
-- - ALL / NULL / empty string means no restriction
-- - EXISTS allows multi-value matching from the normalized filter CTEs
-- - All active filters are combined using AND logic
-------------------------------------------------------------------------------
SELECT *
FROM FinalData fd
WHERE
    ----------------------------------------------------------------------------
    -- COST CENTER
    -- Exact match against one or more selected cost centers
    ----------------------------------------------------------------------------
    (
        @FilterCostCenter IS NULL
        OR LTRIM(RTRIM(@FilterCostCenter)) = ''
        OR UPPER(LTRIM(RTRIM(@FilterCostCenter))) = 'ALL'
        OR EXISTS (
            SELECT 1
            FROM CostCenterFilter f
            WHERE UPPER(ISNULL(fd.[Cost Center], '')) = f.filter_value
        )
    )

    ----------------------------------------------------------------------------
    -- BOUNDARY
    -- Supports exact or wildcard matching
    ----------------------------------------------------------------------------
    AND (
        @FilterBoundary IS NULL
        OR LTRIM(RTRIM(@FilterBoundary)) = ''
        OR UPPER(LTRIM(RTRIM(@FilterBoundary))) = 'ALL'
        OR EXISTS (
            SELECT 1
            FROM BoundaryFilter f
            WHERE UPPER(ISNULL(fd.[Boundary], '')) LIKE f.filter_value
        )
    )

    ----------------------------------------------------------------------------
    -- ST CATEGORY
    -- Supports exact or wildcard matching
    ----------------------------------------------------------------------------
    AND (
        @FilterSTCategory IS NULL
        OR LTRIM(RTRIM(@FilterSTCategory)) = ''
        OR UPPER(LTRIM(RTRIM(@FilterSTCategory))) = 'ALL'
        OR EXISTS (
            SELECT 1
            FROM STCategoryFilter f
            WHERE UPPER(ISNULL(fd.[ST Category], '')) LIKE f.filter_value
        )
    )

    ----------------------------------------------------------------------------
    -- UNIT TYPE
    -- Supports exact or wildcard matching
    ----------------------------------------------------------------------------
    AND (
        @FilterUnitType IS NULL
        OR LTRIM(RTRIM(@FilterUnitType)) = ''
        OR UPPER(LTRIM(RTRIM(@FilterUnitType))) = 'ALL'
        OR EXISTS (
            SELECT 1
            FROM UnitTypeFilter f
            WHERE UPPER(ISNULL(fd.[Unit Type], '')) LIKE f.filter_value
        )
    )

    ----------------------------------------------------------------------------
    -- ADDITIONAL CATEGORY
    -- Supports exact or wildcard matching
    ----------------------------------------------------------------------------
    AND (
        @FilterAdditionalCategory IS NULL
        OR LTRIM(RTRIM(@FilterAdditionalCategory)) = ''
        OR UPPER(LTRIM(RTRIM(@FilterAdditionalCategory))) = 'ALL'
        OR EXISTS (
            SELECT 1
            FROM AdditionalCategoryFilter f
            WHERE UPPER(ISNULL(fd.[Additional Category], '')) LIKE f.filter_value
        )
    )

    ----------------------------------------------------------------------------
    -- SUBDIVISION
    -- Supports exact or wildcard matching
    ----------------------------------------------------------------------------
    AND (
        @FilterSubdivision IS NULL
        OR LTRIM(RTRIM(@FilterSubdivision)) = ''
        OR UPPER(LTRIM(RTRIM(@FilterSubdivision))) = 'ALL'
        OR EXISTS (
            SELECT 1
            FROM SubdivisionFilter f
            WHERE UPPER(ISNULL(fd.[Subdivision], '')) LIKE f.filter_value
        )
    )

    ----------------------------------------------------------------------------
    -- CONNECTION TYPE
    -- Supports exact or wildcard matching
    ----------------------------------------------------------------------------
    AND (
        @FilterConnectionType IS NULL
        OR LTRIM(RTRIM(@FilterConnectionType)) = ''
        OR UPPER(LTRIM(RTRIM(@FilterConnectionType))) = 'ALL'
        OR EXISTS (
            SELECT 1
            FROM ConnectionTypeFilter f
            WHERE UPPER(ISNULL(fd.[Connection Type], '')) LIKE f.filter_value
        )
    )

    ----------------------------------------------------------------------------
    -- LOT NO
    -- Exact match only, but supports multiple comma-separated values
    ----------------------------------------------------------------------------
    AND (
        @FilterLotNo IS NULL
        OR LTRIM(RTRIM(@FilterLotNo)) = ''
        OR UPPER(LTRIM(RTRIM(@FilterLotNo))) = 'ALL'
        OR EXISTS (
            SELECT 1
            FROM LotNoFilter f
            WHERE CAST(fd.[Lot no] AS VARCHAR(100)) = f.filter_value
        )
    )

    ----------------------------------------------------------------------------
    -- SERVICE ADDRESS
    -- Supports wildcard matching
    ----------------------------------------------------------------------------
    AND (
        @FilterServiceAddress IS NULL
        OR LTRIM(RTRIM(@FilterServiceAddress)) = ''
        OR UPPER(LTRIM(RTRIM(@FilterServiceAddress))) = 'ALL'
        OR EXISTS (
            SELECT 1
            FROM ServiceAddressFilter f
            WHERE UPPER(ISNULL(fd.[Service Address], '')) LIKE f.filter_value
        )
    )

    ----------------------------------------------------------------------------
    -- LATEST ACCOUNT
    -- Supports exact, multi-value, or wildcard matching
    ----------------------------------------------------------------------------
    AND (
        @FilterLatestAccount IS NULL
        OR LTRIM(RTRIM(@FilterLatestAccount)) = ''
        OR UPPER(LTRIM(RTRIM(@FilterLatestAccount))) = 'ALL'
        OR EXISTS (
            SELECT 1
            FROM LatestAccountFilter f
            WHERE UPPER(ISNULL(fd.[Latest Account], '')) LIKE f.filter_value
        )
    )

    ----------------------------------------------------------------------------
    -- METER SIZE
    -- Supports exact, multi-value, or wildcard matching
    ----------------------------------------------------------------------------
    AND (
        @FilterMeterSize IS NULL
        OR LTRIM(RTRIM(@FilterMeterSize)) = ''
        OR UPPER(LTRIM(RTRIM(@FilterMeterSize))) = 'ALL'
        OR EXISTS (
            SELECT 1
            FROM MeterSizeFilter f
            WHERE UPPER(ISNULL(CAST(fd.[Meter Size] AS VARCHAR(100)), '')) LIKE f.filter_value
        )
    )

ORDER BY
    [Cost Center],
    [ST Category],
    [Lot no],
    [Service Address];
/****
EOF

This is fun until you realize your code is technically correct, the data you 
have is technically messy, and somehow both are now your problem. :)
****/