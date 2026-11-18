SELECT
    user_pseudo_id,
    
    -- Behavioral Aggregations
    COUNT(DISTINCT session_id) AS total_sessions,
    COUNT(1) AS total_events,
    COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN session_id END) AS purchase_session_count,
    COALESCE(SUM(event_value), 0) AS total_spend_usd,
    
    -- Contextual Attributes (Taking the first/any value for user demographics)
    ANY_VALUE(device_category) AS device_category,
    ANY_VALUE(country) AS country,
    
    -- Machine Learning Target Label: Did the user make a purchase? (1 or 0)
    IF(COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN session_id END) > 0, 1, 0) AS label_made_purchase

FROM {{ ref('stg_ga4_events') }}
GROUP BY user_pseudo_id