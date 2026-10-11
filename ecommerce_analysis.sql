-- 1. Проверяем количество строк во всех таблицах

SELECT 'orders' AS table_name, COUNT(*) AS rows_count
FROM orders

UNION ALL

SELECT 'order_items', COUNT(*)
FROM order_items

UNION ALL

SELECT 'customers', COUNT(*)
FROM customers

UNION ALL

SELECT 'products', COUNT(*)
FROM products

UNION ALL

SELECT 'payments', COUNT(*)
FROM payments

UNION ALL

SELECT 'category_translation', COUNT(*)
FROM category_translation;


-- 2. Смотрим заказы вместе с географией клиентов

SELECT
    orders.order_id,
    orders.order_status,
    customers.customer_city,
    customers.customer_state
FROM orders
JOIN customers
    ON orders.customer_id = customers.customer_id
LIMIT 10;


-- 3. Основные показатели по доставленным заказам

SELECT
    COUNT(DISTINCT orders.order_id) AS total_orders,
    ROUND(
        SUM(order_items.price + order_items.freight_value),
        2
    ) AS delivered_order_value,
    ROUND(
        SUM(order_items.price + order_items.freight_value)
        / COUNT(DISTINCT orders.order_id),
        2
    ) AS average_order_value
FROM orders
JOIN order_items
    ON orders.order_id = order_items.order_id
WHERE orders.order_status = 'delivered';


-- 4. Продажи по месяцам:
-- от месяца с самым большим объёмом заказов к самому маленькому

SELECT
    SUBSTR(orders.order_purchase_timestamp, 1, 7) AS month,
    COUNT(DISTINCT orders.order_id) AS total_orders,
    ROUND(
        SUM(order_items.price + order_items.freight_value),
        2
    ) AS order_value
FROM orders
JOIN order_items
    ON orders.order_id = order_items.order_id
WHERE orders.order_status = 'delivered'
GROUP BY SUBSTR(orders.order_purchase_timestamp, 1, 7)
ORDER BY order_value DESC;


-- 5. Продажи по месяцам в хронологическом порядке
-- этот запрос нужен нам для графика

SELECT
    SUBSTR(orders.order_purchase_timestamp, 1, 7) AS month,
    COUNT(DISTINCT orders.order_id) AS total_orders,
    ROUND(
        SUM(order_items.price + order_items.freight_value),
        2
    ) AS order_value
FROM orders
JOIN order_items
    ON orders.order_id = order_items.order_id
WHERE orders.order_status = 'delivered'
GROUP BY SUBSTR(orders.order_purchase_timestamp, 1, 7)
ORDER BY month;

-- 6. Топ-10 категорий по объёму доставленных заказов

SELECT
    ct.product_category_name_english AS category,
    COUNT(DISTINCT oi.order_id) AS orders_count,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS order_value
FROM order_items AS oi
JOIN orders AS o
    ON oi.order_id = o.order_id
JOIN products AS p
    ON oi.product_id = p.product_id
JOIN category_translation AS ct
    ON p.product_category_name = ct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY ct.product_category_name_english
ORDER BY order_value DESC
LIMIT 10;
-- 7. Топ-10 штатов по объёму доставленных заказов

SELECT
    c.customer_state AS state,
    COUNT(DISTINCT o.order_id) AS orders_count,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS order_value,
    ROUND(
        SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
JOIN order_items AS oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY order_value DESC
LIMIT 10;
-- 8. Способы оплаты

SELECT
    payment_type,
    COUNT(DISTINCT order_id) AS orders_count,
    ROUND(SUM(payment_value), 2) AS payment_value,
    ROUND(AVG(payment_value), 2) AS average_payment
FROM payments
GROUP BY payment_type
ORDER BY payment_value DESC;
-- 9. Использование рассрочки

SELECT
    payment_installments,
    COUNT(DISTINCT order_id) AS orders_count,
    ROUND(SUM(payment_value), 2) AS payment_value,
    ROUND(AVG(payment_value), 2) AS average_payment
FROM payments
WHERE payment_type = 'credit_card'
GROUP BY payment_installments
ORDER BY payment_installments;

-- 10. Распределение заказов по статусам

SELECT
    order_status,
    COUNT(*) AS orders_count,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders),
        2
    ) AS share_percent
FROM orders
GROUP BY order_status
ORDER BY orders_count DESC;