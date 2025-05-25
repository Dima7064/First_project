/*
Программа делает все те же пункты, что в Pandas. Но теперь решение через PostgreSQL
*/

/*
Пояснения к таблице:

ProductID -> ID товара

ProductName -> Название товара

Category -> Категория товара

Price -> Цена товара

Rating -> Цена товара

NumReviews -> Количество отзывов на товар

StockQuantity -> Количество товара на складе

Discount -> Скидка на товар

Sales -> Количество продаж товара

DataAdded -> Дата добавления товара на склад

City -> Город
*/

/*
Задачи работы:

1. Топ-5 самых дорогих категорий, название самого прибыльного товара в каждой этой категории. Построение графика
2. Средний рейтинг и количество продаж в категории "Books", самая большая цена за книгу
3. Самая многочисленная группа в категории "Electronics". Количество и средняя стоимость этого товара, где рейтинг больше 2.1
4. Топ-3 самых прибыльных месяца в категории "Clothing" в 2023 году. Самый прибыльный товар месяца, количество его продаж, название города. Построение графика
5. Сравнение категории "Bath and body", "Skin care" и "Makeup" по средним параметрам: цена, рейтинг, продажи, выручка
6. Корелляция цены, рейтинга, скидки и продаж в категории "Blankets"
7. Топ-5 товаров по продажам
8. Средний рейтинг и продажи по категориям
9. Вина с высокой ценой, но низкими продажами (потенциальные кандидаты на скидку)
10. Есть ли товары с высоким рейтингом, но низкими продажами, или наоборот?
11. Выводы работы
*/

-- 1. Топ-5 самых дорогих категорий, название самого прибыльного товара в каждой этой категории
/*
UPDATE "Ecommerce"
SET "Cost" = "Price" * "Discount" * "Sales";
*/

SELECT * FROM "Ecommerce"
ORDER BY "ProductID";

WITH top_categories AS (
	-- Топ-5 самых дорогих категорий
	SELECT "Category", SUM("Cost") AS CategoryCost
	FROM "Ecommerce"
	GROUP BY "Category"
	ORDER BY CategoryCost DESC
	LIMIT 5
),
top_product AS(
	-- Название самого прибыльного товара в каждо этой категории
	SELECT e."Category", e."ProductName", e."Cost",
	ROW_NUMBER() OVER (PARTITION BY e."Category" ORDER BY e."Cost" DESC) as rn
	FROM "Ecommerce" e
	JOIN top_categories tc ON e."Category" = tc."Category"
)
SELECT "Category", "ProductName", "Cost"
FROM top_product 
WHERE rn = 1
ORDER BY "Cost" DESC;

-- 2. Средний рейтинг и количество продаж в категории "Books"в категории "Books", самая большая цена за книгу
-- Средний рейтинг и количество продаж в категории "Books"
SELECT 
	ROUND(AVG("Rating"), 2) AS "Среднее количество продаж", 
	ROUND(AVG("Sales"), 2) AS "Средний рейтинг"
FROM "Ecommerce"
WHERE "Category" = 'Books';

SELECT 
	percentile_cont(0.5) WITHIN GROUP (ORDER BY "Rating") AS "Медианный рейтинг",
	percentile_cont(0.5) WITHIN GROUP (ORDER BY "Sales") AS "Медианное количество продаж"
FROM "Ecommerce"
WHERE "Category" = 'Books';

-- Самая большая цена за книгу
SELECT "ProductName", "Price", "Rating", "Sales"
FROM "Ecommerce"
WHERE "Category" = 'Books'
ORDER BY "ProductName", "Price" DESC
LIMIT 1;

-- 3. Самая многочисленная группа в категории "Electronics". Количество и средняя стоимость этого товара, где рейтинг больше 2.1
WITH top_category AS(
	-- Самая многочисленная группа в категории "Electronics". Количество
	SELECT "ProductName", COUNT(*) as c
	FROM "Ecommerce"
	WHERE "Category" = 'Electronics'
	GROUP BY "ProductName"
	ORDER BY c DESC
	LIMIT 1
)
-- Средняя стоимость этого товара, где рейтинг больше 2.1
SELECT ROUND(AVG(e."Price"), 2) AS "Средняя стоимость"
FROM top_category tc
JOIN "Ecommerce" e ON tc."ProductName" = e."ProductName" AND e."Rating" > 2.1;

-- 4. Топ-3 самых прибыльных товара в категории "Clothing" в 2023 году. Самый прибыльный месяц, количество продаж этого месяца.
-- Топ-3 самых прибыльных товара в категории "Clothing" в 2023 году
SELECT "ProductName", SUM("Cost") as sum_cost
FROM "Ecommerce"
WHERE "Category" = 'Clothing' AND EXTRACT(YEAR FROM "DateAdded") = 2023
GROUP BY "ProductName"
ORDER BY sum_cost DESC
LIMIT 3;

-- Самый прибыльный месяц, количество продаж этого месяца.
SELECT EXTRACT(MONTH FROM "DateAdded") AS "Месяц", Sum("Cost")
FROM "Ecommerce"
WHERE "Category" = 'Clothing' AND EXTRACT(YEAR FROM "DateAdded") = 2023
GROUP BY "Месяц"
ORDER BY Sum("Cost") DESC
LIMIT 1;

-- 5. Сравнение категории "Bath and body", "Skin care" и "Makeup" по средним параметрам: цена, рейтинг, скидка, продажи, выручка.
WITH category AS(
	SELECT 
		"Category", 
		ROUND(AVG("Price"), 2) AS avg_price, 
		ROUND(AVG("Rating"), 2) AS avg_rating, 
		ROUND(AVG("Discount"), 2) AS avg_discount, 
		ROUND(AVG("Sales"), 2) AS avg_sales,
		ROUND(AVG("Cost"), 2) AS avg_cost
	FROM "Ecommerce"
	WHERE "Category" = 'Bath and body' OR "Category" = 'Skin care' OR "Category" = 'Makeup'
	GROUP BY "Category"
)
SELECT
	MAX(avg_price) AS "Макисмальная цена", 
	MAX(avg_rating) AS "Макисмальный рейтинг", 
	MAX(avg_discount) AS "Макисмальная скидка", 
	MAX(avg_sales) AS "Макисмальные продажи", 
	MAX(avg_cost) AS "Макисмальная стоимость",

	MIN(avg_price) AS "Минимальная цена", 
	MIN(avg_rating) AS "Минимальный рейтиг", 
	MIN(avg_discount) AS "Минимальная скидка", 
	MIN(avg_sales) AS "Минимальные продажи", 
	MIN(avg_cost) AS "Минимальная стоимость"
FROM category c
JOIN "Ecommerce" e ON c."Category" = e."Category";

-- 6. Корелляция цены, рейтинга, скидки и продаж в категории "Blankets"
SELECT 
    ROUND(CORR("Price", "Rating")::numeric, 4) AS price_rating_corr,
    ROUND(CORR("Price", "Discount")::numeric, 4) AS price_discount_corr,
    ROUND(CORR("Price", "Sales")::numeric, 4) AS price_sales_corr,
    ROUND(CORR("Rating", "Discount")::numeric, 4) AS rating_discount_corr,
    ROUND(CORR("Rating", "Sales")::numeric, 4) AS rating_sales_corr,
    ROUND(CORR("Discount", "Sales")::numeric, 4) AS discount_sales_corr
FROM "Ecommerce"
WHERE "Category" = 'Blankets';

-- 7. Топ-5 товаров по продажам
SELECT "ProductName", "Sales"
FROM "Ecommerce"
ORDER BY "Sales" DESC
LIMIT 5;

-- 8. Средний рейтинг и продажи по категориям
SELECT "Category", ROUND(AVG("Rating"), 2), ROUND(AVG("Sales"), 2)
FROM "Ecommerce"
GROUP BY "Category"
ORDER BY SUM("Sales") DESC;

-- 9. Вина с высокой ценой, но низкими продажами (потенциальные кандидаты на скидку)
WITH stats AS (
    SELECT 
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY "Price") AS price_75pct,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "Sales") AS sales_median
    FROM "Ecommerce"
	WHERE "Category" = 'Wine'
)

SELECT *
FROM "Ecommerce", stats
WHERE 
	"Price" > stats.price_75pct 
	AND "Sales" < stats.sales_median
	AND "Category" = 'Wine';

-- 10. Есть ли товары с высоким рейтингом, но низкими продажами, или наоборот?
-- # Максимальный рейтинг = 5
-- Выводит суммарные продажи за одинаковые товары, так что Sales на выходе может быть > 500
SELECT "ProductName", SUM("Sales") AS sum_sales
FROM "Ecommerce"
WHERE "Rating" > 4 AND "Sales" < 500
GROUP BY "ProductName"
ORDER BY "ProductName";

-- Есть ли товары с низким рейтингом, но высокими продажами
SELECT "ProductName", SUM("Sales") AS sum_sales
FROM "Ecommerce"
WHERE "Rating" < 2 AND "Sales" > 1000
GROUP BY "ProductName"
ORDER BY "ProductName";

-- 11. Выводы работы (то же самое, что и в файле с Pandas)
/*
1. Мы узнали 5 самых прибыльных товаров (Silk Sheets, Wool Socks, Nail Clippers, Cleanser, Grill Pan). 
Их развитие (новые материалы, цвета, состав) может увеличить ассортимент категории, привлечь новых клиентов, увеличить выручку.

2. Рейтинг самой дорогой книги равен 3.1, в то время, пока средний рейтинг абсолютно всех книг равен 3.07, а медианный - 2.95. 
Это говорит о том, что существуют книги, чей рейтинг выше 3.1, но чья цена меньше, чем у книги с рейтингом 3.1. 
Следовательно, нет гарантии, что, чем выше рейтинг книги, тем дороже она стоит. Также известно, что количество продаж книги (74) значительно меньше, 
чем средние продажи книг (1030). Если на книгу маленький спрос (как в этом случае), то цена должна быть маленькой. В нашем случае всё наоборот. 
Стоит снизить цену или провести исследование: возможно, книга — редкое коллекционное издание, и цена оправдана.

3. Самый прибыльный месяц в категории "Одежда" стал Декабрь. Скорее всего, причиной тому являются предстоящие новогодние праздники, покупки себе и знакомым. 
И в число таких покупок входит и одежда. В таком случае стоит увеличить запасы зимних товаров к ноябрю и запустить предпраздничные акции.

4. В девятом пункте были взяты все вина, чья цена входит в топ-25%, но чьи продажи меньше медианы. 
Такое сочетание говорит о том, что увеличение скидки потенциально может повысить продажи данных вин. При увеличении скидки нужно учитывать, 
что выручка с одной бутылки уменьшится, но за счёт сниженной цены больше человек сможет себе позволить купить такое вино, что увеличит суммарную выручку. 
Но, если скидка не приведёт к росту спроса, то выручка упадёт. Поэтому с принятием об увеличении скидки нужно вести себя осторожно. 
Также, помимо увеличения скидки, есть вариант провести маркетинговую кампанию (что тоже потребует дополнительных затрат).

5. В последнем пункте мы нашли товары с большим рейтингом, но маленькими продажами. Такое соотношение означает, что товары качетсвенные, но далее нужно выяснить, 
в чём причина маленьких продаж: либо маленький спрос, либо плохой маркетинг, либо цена для такого товара слишком завышена. 
Следует рассмотреть все эти факторы, сравнить их с конкурентами и общим состоянием рынка для этих товаров.

    Также мы нашли товары с маленьким рейтингом, но большими продажами. Такое соотношение говорит о том, что спрос на товар большой независимо от качества.
*/