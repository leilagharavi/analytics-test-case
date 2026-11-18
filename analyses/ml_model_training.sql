CREATE OR REPLACE MODEL `crystalloids-analytics.ml.purcahse_model`
OPTIONS(
  model_type = 'logistic_reg',
  input_label_cols = ['label_made_purchase'],
  auto_class_weights = TRUE,
  l1_reg = 0.1,
  l2_reg = 1.0
) AS

SELECT
    -- Features used for training
    total_sessions,
    total_events,
    COALESCE(device_category, 'unknown') AS device_category,
    COALESCE(country, 'unknown') AS country,
    
    -- Target Label (1 if they purchased, 0 otherwise)
    label_made_purchase

FROM `crystalloids-analytics.analytics.user_features`;