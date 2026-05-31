select * from `workspace`.`default`.`bright_car_sales` limit 100;


-- =====================================================
-- SECTION 1: DATA CLEANING & TRANSFORMATION
-- =====================================================

-- QUERY 1: Preview raw data structure
   select * from `workspace`.`default`.`bright_car_sales` limit 100;

-- QUERY 2: Check total records
SELECT COUNT(*) AS total_records from `workspace`.`default`.`bright_car_sales`;

-- QUERY 3: Check for NULL values in key columns
SELECT 
    COUNT(*) AS total_records,
    SUM(CASE WHEN make IS NULL OR make = '' THEN 1 ELSE 0 END) AS null_make,
    SUM(CASE WHEN model IS NULL OR model = '' THEN 1 ELSE 0 END) AS null_model,
    SUM(CASE WHEN sellingprice IS NULL THEN 1 ELSE 0 END) AS null_sellingprice,
    SUM(CASE WHEN mmr IS NULL THEN 1 ELSE 0 END) AS null_mmr,
    SUM(CASE WHEN condition IS NULL THEN 1 ELSE 0 END) AS null_condition,
    SUM(CASE WHEN odometer IS NULL THEN 1 ELSE 0 END) AS null_odometer,
    SUM(CASE WHEN saledate IS NULL OR saledate = '' THEN 1 ELSE 0 END) AS null_saledate,
    SUM(CASE WHEN state IS NULL OR state = '' THEN 1 ELSE 0 END) AS null_state,
    SUM(CASE WHEN color IS NULL OR color = '' THEN 1 ELSE 0 END) AS null_color
from `workspace`.`default`.`bright_car_sales`;

-- QUERY 4: Check for duplicate VINs
SELECT 
    vin,
    COUNT(*) AS duplicate_count
from `workspace`.`default`.`bright_car_sales`
GROUP BY vin
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- QUERY 5: Check unique values in categorical columns
SELECT 
    COUNT(DISTINCT make) AS unique_makes,
    COUNT(DISTINCT model) AS unique_models,
    COUNT(DISTINCT body) AS unique_body_types,
    COUNT(DISTINCT transmission) AS unique_transmissions,
    COUNT(DISTINCT state) AS unique_states,
    COUNT(DISTINCT color) AS unique_colors,
    COUNT(DISTINCT seller) AS unique_sellers
from `workspace`.`default`.`bright_car_sales`;

-- QUERY 6: Data range validation
SELECT 
    MIN(year) AS min_year,
    MAX(year) AS max_year,
    MIN(sellingprice) AS min_price,
    MAX(sellingprice) AS max_price,
    MIN(odometer) AS min_odometer,
    MAX(odometer) AS max_odometer,
    MIN(condition) AS min_condition,
    MAX(condition) AS max_condition
from `workspace`.`default`.`bright_car_sales`;

-- =====================================================
-- SECTION 2: REVENUE ANALYSIS (Case Study Requirement)
-- =====================================================

-- QUERY 7: Total Revenue by Car Make (KEY REQUIREMENT)
SELECT 
    make,
    COUNT(*) AS units_sold,
    ROUND(SUM(sellingprice), 2) AS total_revenue,
    ROUND(AVG(sellingprice), 2) AS avg_selling_price,
    ROUND(SUM(mmr), 2) AS total_mmr,
    ROUND(SUM(sellingprice - mmr), 2) AS total_profit
from `workspace`.`default`.`bright_car_sales`
WHERE sellingprice > 0
GROUP BY make
ORDER BY total_revenue DESC;

-- QUERY 8: Total Revenue by Car Make AND Model (KEY REQUIREMENT)
SELECT 
    make,
    model,
    COUNT(*) AS units_sold,
    ROUND(SUM(sellingprice), 2) AS total_revenue,
    ROUND(AVG(sellingprice), 2) AS avg_selling_price,
    ROUND(SUM(sellingprice - mmr), 2) AS total_profit,
    ROUND(AVG((sellingprice - mmr) / NULLIF(mmr, 0) * 100), 2) AS avg_profit_margin_pct
from `workspace`.`default`.`bright_car_sales`
WHERE sellingprice > 0 AND mmr > 0
GROUP BY make, model
ORDER BY total_revenue DESC
LIMIT 25;

-- =====================================================
-- SECTION 3: PRICE, MILEAGE, YEAR RELATIONSHIP (Case Study Requirement)
-- =====================================================

-- QUERY 9: Relationship between Mileage and Selling Price (KEY REQUIREMENT)
SELECT 
    CASE 
        WHEN odometer >= 100000 THEN '5. High Mileage (100k+)'
        WHEN odometer >= 75000 THEN '4. Above Average (75k-100k)'
        WHEN odometer >= 50000 THEN '3. Average (50k-75k)'
        WHEN odometer >= 25000 THEN '2. Low Mileage (25k-50k)'
        ELSE '1. Very Low Mileage (<25k)'
    END AS mileage_category,
    COUNT(*) AS total_vehicles,
    ROUND(AVG(sellingprice), 2) AS avg_selling_price,
    ROUND(AVG(mmr), 2) AS avg_mmr,
    ROUND(AVG(odometer), 0) AS avg_odometer,
    ROUND(AVG(condition), 2) AS avg_condition
from `workspace`.`default`.`bright_car_sales`
WHERE sellingprice > 0
GROUP BY mileage_category
ORDER BY mileage_category;

-- QUERY 10: Relationship between Year of Manufacture and Price (KEY REQUIREMENT)
SELECT 
    year AS manufacture_year,
    COUNT(*) AS units_sold,
    ROUND(AVG(sellingprice), 2) AS avg_selling_price,
    ROUND(AVG(mmr), 2) AS avg_mmr,
    ROUND(AVG(odometer), 0) AS avg_mileage,
    ROUND(AVG(condition), 2) AS avg_condition,
    ROUND(AVG(sellingprice - mmr), 2) AS avg_profit
from `workspace`.`default`.`bright_car_sales`
WHERE sellingprice > 0
GROUP BY year
ORDER BY year DESC;

-- QUERY 11: Price Depreciation by Vehicle Age at Sale
SELECT 
    (YEAR(TO_DATE(SUBSTRING(saledate, 5, 11), 'MMM dd yyyy')) - year) AS vehicle_age,
    COUNT(*) AS units_sold,
    ROUND(AVG(sellingprice), 2) AS avg_selling_price,
    ROUND(AVG(mmr), 2) AS avg_mmr,
    ROUND(AVG(odometer), 0) AS avg_mileage
FROM `workspace`.`default`.`bright_car_sales`
WHERE sellingprice > 0 
  AND (YEAR(TO_DATE(SUBSTRING(saledate, 5, 11), 'MMM dd yyyy')) - year) BETWEEN 0 AND 20
GROUP BY vehicle_age
ORDER BY vehicle_age;

-- QUERY 12: Condition vs Selling Price Correlation
SELECT 
    CASE 
        WHEN condition >= 4.5 THEN '1. Excellent (4.5+)'
        WHEN condition >= 4.0 THEN '2. Very Good (4.0-4.4)'
        WHEN condition >= 3.0 THEN '3. Good (3.0-3.9)'
        WHEN condition >= 2.0 THEN '4. Fair (2.0-2.9)'
        WHEN condition > 0 THEN '5. Poor (<2.0)'
        ELSE '6. Unknown'
    END AS condition_category,
    COUNT(*) AS total_vehicles,
    ROUND(AVG(sellingprice), 2) AS avg_selling_price,
    ROUND(AVG(mmr), 2) AS avg_mmr,
    ROUND(AVG(odometer), 0) AS avg_mileage
from `workspace`.`default`.`bright_car_sales`
WHERE sellingprice > 0
GROUP BY condition_category
ORDER BY condition_category;

-- =====================================================
-- SECTION 4: REGIONAL PERFORMANCE (Case Study Requirement)
-- =====================================================

-- QUERY 13: Sales Volume and Revenue by State/Region (KEY REQUIREMENT)
SELECT 
    state,
    COUNT(*) AS total_sales,
    ROUND(SUM(sellingprice), 2) AS total_revenue,
    ROUND(AVG(sellingprice), 2) AS avg_selling_price,
    ROUND(SUM(sellingprice - mmr), 2) AS total_profit,
    ROUND(AVG((sellingprice - mmr) / NULLIF(mmr, 0) * 100), 2) AS avg_profit_margin_pct
from `workspace`.`default`.`bright_car_sales`
WHERE sellingprice > 0 AND mmr > 0
GROUP BY state
ORDER BY total_revenue DESC;

-- QUERY 14: Top Performing States by Units Sold
SELECT 
    state,
    COUNT(*) AS units_sold,
    ROUND(SUM(sellingprice), 2) AS total_revenue,
    ROUND(AVG(sellingprice), 2) AS avg_price
from `workspace`.`default`.`bright_car_sales`
WHERE sellingprice > 0
GROUP BY state
ORDER BY units_sold DESC
LIMIT 10;

-- =====================================================
-- SECTION 5: SALES TRENDS OVER TIME (Case Study Requirement)
-- =====================================================

-- QUERY 15: Average Selling Price Trends Over Time - Monthly (KEY REQUIREMENT)
SELECT 
    YEAR(TO_DATE(SUBSTRING(saledate, 5, 11), 'MMM dd yyyy')) AS sale_year,
    MONTH(TO_DATE(SUBSTRING(saledate, 5, 11), 'MMM dd yyyy')) AS sale_month,
    COUNT(*) AS units_sold,
    ROUND(SUM(sellingprice), 2) AS total_revenue,
    ROUND(AVG(sellingprice), 2) AS avg_selling_price,
    ROUND(AVG(mmr), 2) AS avg_mmr
FROM `workspace`.`default`.`bright_car_sales`
WHERE sellingprice > 0
GROUP BY sale_year, sale_month
ORDER BY sale_year, sale_month;

-- QUERY 16: Quarterly Sales Performance
SELECT 
    YEAR(TO_DATE(SUBSTRING(saledate, 5, 11), 'MMM dd yyyy')) AS sale_year,
    QUARTER(TO_DATE(SUBSTRING(saledate, 5, 11), 'MMM dd yyyy')) AS sale_quarter,
    COUNT(*) AS units_sold,
    ROUND(SUM(sellingprice), 2) AS total_revenue,
    ROUND(AVG(sellingprice), 2) AS avg_selling_price,
    ROUND(SUM(sellingprice - mmr), 2) AS total_profit
FROM `workspace`.`default`.`bright_car_sales`
WHERE sellingprice > 0
GROUP BY sale_year, sale_quarter
ORDER BY sale_year, sale_quarter;

-- QUERY 17: Yearly Sales Summary
SELECT 
    YEAR(TO_DATE(SUBSTRING(saledate, 5, 11), 'MMM dd yyyy')) AS sale_year,
    COUNT(*) AS units_sold,
    ROUND(SUM(sellingprice), 2) AS total_revenue,
    ROUND(AVG(sellingprice), 2) AS avg_selling_price,
    ROUND(SUM(sellingprice - mmr), 2) AS total_profit,
    ROUND(AVG((sellingprice - mmr) / NULLIF(mmr, 0) * 100), 2) AS avg_profit_margin_pct
FROM `workspace`.`default`.`bright_car_sales`
WHERE sellingprice > 0 AND mmr > 0
GROUP BY sale_year
ORDER BY sale_year;

-- =====================================================
-- SECTION 6: PROFIT MARGIN ANALYSIS (Case Study Requirement)
-- =====================================================

-- QUERY 18: Profit Margin Calculation & Tiers (KEY REQUIREMENT)
SELECT 
    CASE 
        WHEN ((sellingprice - mmr) / NULLIF(mmr, 0)) * 100 >= 15 THEN '1. High Margin (15%+)'
        WHEN ((sellingprice - mmr) / NULLIF(mmr, 0)) * 100 >= 5 THEN '2. Medium Margin (5-15%)'
        WHEN ((sellingprice - mmr) / NULLIF(mmr, 0)) * 100 >= 0 THEN '3. Low Margin (0-5%)'
        ELSE '4. Negative Margin (Loss)'
    END AS margin_tier,
    COUNT(*) AS total_vehicles,
    ROUND(SUM(sellingprice), 2) AS total_revenue,
    ROUND(AVG(sellingprice), 2) AS avg_selling_price,
    ROUND(SUM(sellingprice - mmr), 2) AS total_profit,
    ROUND(AVG((sellingprice - mmr) / NULLIF(mmr, 0) * 100), 2) AS avg_profit_margin_pct
from `workspace`.`default`.`bright_car_sales`
WHERE sellingprice > 0 AND mmr > 0
GROUP BY margin_tier
ORDER BY margin_tier;

-- QUERY 19: Profit Margin by Make
SELECT 
    make,
    COUNT(*) AS units_sold,
    ROUND(SUM(sellingprice), 2) AS total_revenue,
    ROUND(SUM(sellingprice - mmr), 2) AS total_profit,
    ROUND(AVG((sellingprice - mmr) / NULLIF(mmr, 0) * 100), 2) AS avg_profit_margin_pct
from `workspace`.`default`.`bright_car_sales`
WHERE sellingprice > 0 AND mmr > 0
GROUP BY make
ORDER BY avg_profit_margin_pct DESC;

-- =====================================================
-- SECTION 7: CUSTOMER PREFERENCES (Case Study Requirement)
-- =====================================================

-- QUERY 20: Sales by Body Type (Customer Preference)
SELECT 
    body AS body_type,
    COUNT(*) AS total_sales,
    ROUND(SUM(sellingprice), 2) AS total_revenue,
    ROUND(AVG(sellingprice), 2) AS avg_price,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total_sales
from `workspace`.`default`.`bright_car_sales`
WHERE sellingprice > 0 AND body IS NOT NULL AND body != ''
GROUP BY body
ORDER BY total_sales DESC;

-- QUERY 21: Sales by Transmission Type
SELECT 
    transmission,
    COUNT(*) AS total_sales,
    ROUND(SUM(sellingprice), 2) AS total_revenue,
    ROUND(AVG(sellingprice), 2) AS avg_price,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total_sales
from `workspace`.`default`.`bright_car_sales`
WHERE sellingprice > 0 AND transmission IS NOT NULL
GROUP BY transmission
ORDER BY total_sales DESC;

-- QUERY 22: Color Preferences
SELECT 
    color,
    COUNT(*) AS total_sales,
    ROUND(SUM(sellingprice), 2) AS total_revenue,
    ROUND(AVG(sellingprice), 2) AS avg_price
from `workspace`.`default`.`bright_car_sales`
WHERE sellingprice > 0 AND color IS NOT NULL AND color != '' AND color != '—'
GROUP BY color
ORDER BY total_sales DESC
LIMIT 15;

-- QUERY 23: Price Category Distribution (Customer Segments)
SELECT 
    CASE 
        WHEN sellingprice >= 50000 THEN '1. Luxury ($50k+)'
        WHEN sellingprice >= 30000 THEN '2. Premium ($30k-$50k)'
        WHEN sellingprice >= 20000 THEN '3. Mid-Range ($20k-$30k)'
        WHEN sellingprice >= 10000 THEN '4. Economy ($10k-$20k)'
        ELSE '5. Budget (<$10k)'
    END AS price_segment,
    COUNT(*) AS total_sales,
    ROUND(SUM(sellingprice), 2) AS total_revenue,
    ROUND(AVG(sellingprice), 2) AS avg_price,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total_sales
from `workspace`.`default`.`bright_car_sales`
WHERE sellingprice > 0
GROUP BY price_segment
ORDER BY price_segment;

-- =====================================================
-- SECTION 8: SELLER PERFORMANCE
-- =====================================================

-- QUERY 24: Top Sellers by Revenue
SELECT 
    seller,
    COUNT(*) AS units_sold,
    ROUND(SUM(sellingprice), 2) AS total_revenue,
    ROUND(AVG(sellingprice), 2) AS avg_price,
    ROUND(SUM(sellingprice - mmr), 2) AS total_profit
from `workspace`.`default`.`bright_car_sales`
WHERE sellingprice > 0
GROUP BY seller
ORDER BY total_revenue DESC
LIMIT 20;

-- =====================================================
-- SECTION 9: SUMMARY STATISTICS
-- =====================================================

-- QUERY 25: Overall Summary Statistics
SELECT 
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT vin) AS unique_vehicles,
    COUNT(DISTINCT make) AS unique_makes,
    COUNT(DISTINCT model) AS unique_models,
    COUNT(DISTINCT state) AS unique_states,
    COUNT(DISTINCT seller) AS unique_sellers,
    ROUND(SUM(sellingprice), 2) AS total_revenue,
    ROUND(AVG(sellingprice), 2) AS avg_selling_price,
    ROUND(MIN(sellingprice), 2) AS min_selling_price,
    ROUND(MAX(sellingprice), 2) AS max_selling_price,
    ROUND(SUM(sellingprice - mmr), 2) AS total_profit,
    ROUND(AVG((sellingprice - mmr) / NULLIF(mmr, 0) * 100), 2) AS avg_profit_margin_pct,
    ROUND(AVG(odometer), 0) AS avg_mileage,
    ROUND(AVG(condition), 2) AS avg_condition
from `workspace`.`default`.`bright_car_sales`
WHERE sellingprice > 0 AND mmr > 0;



-- =====================================================
-- FINAL CLEAN TABLE - BRIGHT MOTORS CAR SALES 
-- =====================================================

CREATE OR REPLACE TABLE `workspace`.`default`.`car_sales_processed_final_clean` AS
SELECT 


 -- ORIGINAL FIELDS (CLEANED)
    year AS manufacture_year,
    UPPER(TRIM(a.make)) AS make,
    UPPER(TRIM(a.model)) AS model,
    COALESCE(NULLIF(TRIM(trim), ''), 'Standard') AS trim,
    COALESCE(NULLIF(UPPER(TRIM(body)), ''), 'UNKNOWN') AS body_type,
    COALESCE(NULLIF(UPPER(TRIM(transmission)), ''), 'UNKNOWN') AS transmission,
    vin,
    UPPER(TRIM(state)) AS state,
    COALESCE(condition, 0) AS condition_score,
    COALESCE(odometer, 0) AS odometer,
    COALESCE(NULLIF(UPPER(TRIM(color)), ''), 'UNKNOWN') AS exterior_color,
    COALESCE(NULLIF(UPPER(TRIM(interior)), ''), 'UNKNOWN') AS interior_color,
    TRIM(seller) AS seller,
    COALESCE(mmr, 0) AS mmr,
    COALESCE(sellingprice, 0) AS selling_price,
    
    -- DATE FIELDS (PARSED)
    saledate AS original_saledate,
    TO_DATE(SUBSTRING(saledate, 5, 11), 'MMM dd yyyy') AS sale_date,
    YEAR(TO_DATE(SUBSTRING(saledate, 5, 11), 'MMM dd yyyy')) AS sale_year,
    MONTH(TO_DATE(SUBSTRING(saledate, 5, 11), 'MMM dd yyyy')) AS sale_month,
    QUARTER(TO_DATE(SUBSTRING(saledate, 5, 11), 'MMM dd yyyy')) AS sale_quarter,
    DATE_FORMAT(TO_DATE(SUBSTRING(saledate, 5, 11), 'MMM dd yyyy'), 'EEEE') AS sale_day_name,
    DAYOFWEEK(TO_DATE(SUBSTRING(saledate, 5, 11), 'MMM dd yyyy')) AS sale_day_of_week,
    
    -- FINANCIAL CALCULATIONS
    ROUND(sellingprice - mmr, 2) AS profit,
    ROUND(((sellingprice - mmr) / NULLIF(mmr, 0)) * 100, 2) AS profit_margin_pct,
    
    -- PROFIT MARGIN TIER
    CASE 
        WHEN ((sellingprice - mmr) / NULLIF(mmr, 0)) * 100 >= 15 THEN 'High Margin (15%+)'
        WHEN ((sellingprice - mmr) / NULLIF(mmr, 0)) * 100 >= 5 THEN 'Medium Margin (5-15%)'
        WHEN ((sellingprice - mmr) / NULLIF(mmr, 0)) * 100 >= 0 THEN 'Low Margin (0-5%)'
        ELSE 'Negative Margin (Loss)'
    END AS margin_tier,
    
    -- PRICE CATEGORY
    CASE 
        WHEN sellingprice >= 50000 THEN 'Luxury ($50k+)'
        WHEN sellingprice >= 30000 THEN 'Premium ($30k-$50k)'
        WHEN sellingprice >= 20000 THEN 'Mid-Range ($20k-$30k)'
        WHEN sellingprice >= 10000 THEN 'Economy ($10k-$20k)'
        ELSE 'Budget (<$10k)'
    END AS price_category,
    
    -- MILEAGE CATEGORY
    CASE 
        WHEN odometer >= 100000 THEN 'High Mileage (100k+)'
        WHEN odometer >= 75000 THEN 'Above Average (75k-100k)'
        WHEN odometer >= 50000 THEN 'Average (50k-75k)'
        WHEN odometer >= 25000 THEN 'Low Mileage (25k-50k)'
        ELSE 'Very Low Mileage (<25k)'
    END AS mileage_category,
    
    -- CONDITION CATEGORY
    CASE 
        WHEN condition >= 4.5 THEN 'Excellent (4.5+)'
        WHEN condition >= 4.0 THEN 'Very Good (4.0-4.4)'
        WHEN condition >= 3.0 THEN 'Good (3.0-3.9)'
        WHEN condition >= 2.0 THEN 'Fair (2.0-2.9)'
        WHEN condition > 0 THEN 'Poor (<2.0)'
        ELSE 'Unknown'
    END AS condition_category,
    
    -- VEHICLE AGE
    YEAR(TO_DATE(SUBSTRING(saledate, 5, 11), 'MMM dd yyyy')) - year AS vehicle_age,
    
    CASE 
        WHEN YEAR(TO_DATE(SUBSTRING(saledate, 5, 11), 'MMM dd yyyy')) - year <= 1 THEN 'New (0-1 yrs)'
        WHEN YEAR(TO_DATE(SUBSTRING(saledate, 5, 11), 'MMM dd yyyy')) - year <= 3 THEN 'Nearly New (2-3 yrs)'
        WHEN YEAR(TO_DATE(SUBSTRING(saledate, 5, 11), 'MMM dd yyyy')) - year <= 5 THEN 'Recent (4-5 yrs)'
        WHEN YEAR(TO_DATE(SUBSTRING(saledate, 5, 11), 'MMM dd yyyy')) - year <= 10 THEN 'Used (6-10 yrs)'
        ELSE 'Old (10+ yrs)'
    END AS age_category,
    
    
  -- AGGREGATED SALES SUMMARY (JOINED)
    b.units_sold,
    b.total_revenue,
    b.total_profit,
    b.avg_price,
    b.avg_margin

FROM `workspace`.`default`.`bright_car_sales` a

LEFT JOIN (
    SELECT
        make,
        model,
        YEAR(TO_DATE(SUBSTRING(saledate, 5, 11), 'MMM dd yyyy')) AS sale_year,

        COUNT(*) AS units_sold,
        SUM(sellingprice) AS total_revenue,
        SUM(sellingprice - mmr) AS total_profit,
        AVG(sellingprice) AS avg_price,
        AVG(((sellingprice - mmr) / NULLIF(mmr, 0)) * 100) AS avg_margin

    FROM `workspace`.`default`.`bright_car_sales`
    WHERE 
        sellingprice > 0 
        AND mmr > 0
        AND year >= 1990
        AND odometer >= 0
        AND saledate IS NOT NULL
        AND saledate != ''
        
    GROUP BY make, model, YEAR(TO_DATE(SUBSTRING(saledate, 5, 11), 'MMM dd yyyy'))
    
) b
ON a.make = b.make 
AND a.model = b.model 
AND YEAR(TO_DATE(SUBSTRING(a.saledate, 5, 11), 'MMM dd yyyy')) = b.sale_year

WHERE 
    sellingprice > 0 
    AND mmr > 0
    AND year >= 1990
    AND odometer >= 0
    AND saledate IS NOT NULL
    AND saledate != '';


    SELECT * FROM `workspace`.`default`.`car_sales_processed_final_clean` LIMIT 10000; 
