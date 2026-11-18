WITH source AS (
    SELECT * FROM {{ source('ga4_raw', 'events') }}
    -- Filter date range to optimize performance during development and analysis
    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),

renamed AS (
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

        -- Traffic Source Parameters (Extracted from event_params)
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'source') AS traffic_source,
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'medium') AS traffic_medium,
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'campaign') AS traffic_campaign,

        -- Ecommerce / Transaction Details
        event_value_in_usd AS event_value,
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'transaction_id') AS transaction_id

    FROM source
)

SELECT * FROM renamed