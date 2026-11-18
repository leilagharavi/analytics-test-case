WITH user_traffic AS (
    SELECT
        user_pseudo_id,
        COALESCE(ANY_VALUE(traffic_source), '(direct)') AS traffic_source,
        COALESCE(ANY_VALUE(traffic_medium), '(none)') AS traffic_medium
    FROM `crystalloids-analytics.analytics.stg_ga4_events`
    GROUP BY user_pseudo_id
),

user_metrics AS (
    SELECT
        user_pseudo_id,
        total_sessions,
        total_spend_usd,
        label_made_purchase
    FROM `crystalloids-analytics.analytics.user_features`
)

SELECT
    t.traffic_source,
    t.traffic_medium,
    COUNT(DISTINCT u.user_pseudo_id) AS total_users,
    SUM(u.label_made_purchase) AS purchasing_users,
    ROUND(SAFE_DIVIDE(SUM(u.label_made_purchase), COUNT(DISTINCT u.user_pseudo_id)) * 100, 2) AS conversion_rate_pct,
    ROUND(SUM(u.total_spend_usd), 2) AS total_revenue_usd

FROM user_traffic t
JOIN user_metrics u ON t.user_pseudo_id = u.user_pseudo_id
GROUP BY 1, 2
ORDER BY total_revenue_usd DESC