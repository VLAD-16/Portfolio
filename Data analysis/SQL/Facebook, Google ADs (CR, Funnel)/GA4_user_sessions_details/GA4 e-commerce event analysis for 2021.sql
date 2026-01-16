
-- GA4 e-commerce event analysis for 2021
SELECT
    -- convert UNIX timestamp to timestamp format
    timestamp_micros(event_timestamp) as event_timestamp, 
    user_pseudo_id, 
    --UNNEST event_param  ga_session_id
    (select value.int_value from Unnest(event_params) where key='ga_session_id') AS session_id,
    event_name, 
    geo.country as country, 
    device.category as device_category, 
    traffic_source.source as source,
    traffic_source.medium as medium,
    traffic_source.name as campaign
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE 
    event_name IN (
      'session_start','view_item','add_to_cart','begin_checkout','add_shipping_info','add_payment_info','purchase'
    ) AND 
    _table_suffix BETWEEN '20210101' AND '20211231';
    