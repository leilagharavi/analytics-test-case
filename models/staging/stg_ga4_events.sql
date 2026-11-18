WITH source AS (
    SELECT * FROM {{ source('ga4_raw', 'events') }}
    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),

extracted AS (
    SELECT
        -- Core Event Attributes
        event_date,
        TIMESTAMP_MICROS(event_timestamp) AS event_timestamp,
        LOWER(event_name) AS event_name,
        COALESCE(user_pseudo_id, 'unknown_user') AS user_pseudo_id,
        user_id,
        
        -- Session & Device Attributes
        (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
        device.category AS device_category,
        device.operating_system AS operating_system,
        geo.country AS country,

        -- Raw Traffic Parameters extracted once into clean columns
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'source') AS traffic_source,
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'medium') AS traffic_medium,
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'campaign') AS traffic_campaign,

        -- Ecommerce / Transaction Details
        event_value_in_usd AS event_value,
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'transaction_id') AS transaction_id

    FROM source
),

cleaned AS (
    SELECT
        *,
        -- Cleaned Traffic Source (handling safeframe/googlesyndication noise)
        CASE 
            WHEN traffic_source LIKE '%googlesyndication.com%' OR traffic_source LIKE '%doubleclick.net%' 
                THEN 'googlesyndication.com (Display)'
            WHEN traffic_source IS NULL OR traffic_source = '(direct)' 
                THEN '(direct)'
            ELSE traffic_source
        END AS cleaned_traffic_source,

        -- High-level Channel Grouping
        CASE 
            WHEN traffic_source IS NULL OR traffic_source = '(direct)' THEN 'Direct'
            WHEN traffic_medium LIKE '%organic%' OR traffic_source IN ('google', 'bing', 'yahoo') THEN 'Organic Search'
            WHEN traffic_medium LIKE '%cpc%' OR traffic_medium LIKE '%ppc%' THEN 'Paid Search'
            WHEN traffic_source LIKE '%googlesyndication.com%' OR traffic_medium LIKE '%display%' THEN 'Display / Ads'
            ELSE 'Referral / Other'
        END AS channel_grouping

    FROM extracted
)

SELECT * FROM cleaned