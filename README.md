Olist E-Commerce Analysis: Star Schema and SQL Analytics

An end-to-end analysis of the Olist Brazilian e-commerce dataset (about 100,000 orders, 2016 to 2018). The project loads nine raw tables into SQLite, checks their data quality, remodels them as a star schema, and answers nine business questions with SQL (CTEs and window functions). All revenue figures are in Brazilian reais (R$).

Status: data quality review, star schema and the nine SQL analyses are complete. Statistical testing is in progress, and a Power BI dashboard is planned.

Business questions
Is the business growing, and which months stand out?
How fast does revenue accumulate, and what is the smoothed trend?
Which product categories drive revenue?
Where do customers receive orders late?
Which sellers are strongest, and which need attention?
Who are the customers, and how much revenue sits with repeat buyers?
How many customers come back, and when?
How do customers pay, and in how many installments?
How much does late delivery hurt review scores?
Data
Source: Brazilian E-Commerce Public Dataset by Olist on Kaggle. See the Kaggle page for the license and terms. The data is not included in this repository.
Nine CSV files: customers, geolocation, order items, order payments, order reviews, orders, products, sellers and category translation.
Analysis window: January 2017 to August 2018 (20 months). Earlier months have 1 to 290 orders and September 2018 has 1 order, so growth rates there are meaningless.
Revenue means the sum of item price (freight excluded), with canceled and unavailable orders removed.
Repository structure
notebooks/   01_data_overview, 02_star_schema, 03_sql_analysis
sql/         01 to 09: one query file per business question, each with a header
src/         config.py, load_data.py (loads CSVs into SQLite and builds a data dictionary and quality report)
docs/        data_quality_notes.md, dimension_tables_explained.docx
How to run
Install the libraries: pip install pandas numpy scipy jupyter fg-data-profiling
Download the dataset from Kaggle and place the nine CSV files in data/raw/.
Run python src/load_data.py. This creates olist.db with the raw tables, a data_dictionary table and a dq_report table.
Open the notebooks in order. The first cell of each notebook sets a file path to the src folder, so change it to your own project folder. Notebook 02_star_schema builds the star schema, and 03_sql_analysis runs the queries in sql/.
Data quality findings
Table	Finding
orders	97.3% of missing delivery dates are explained by order status. Nine orders marked delivered have missing or inconsistent timestamps.
order_items	R$0 freight on 383 rows (0.34%), and 96% of them come from four sellers.
products	610 listings have no category or descriptive fields. 13 products use categories missing from the translation table (translated by hand).
order_reviews	547 orders have more than one review. 768 orders have none.
geolocation	About 1M rows for 19,015 zip codes. 31 coordinates fall outside Brazil. An early filter wrongly flagged Fernando de Noronha, a real Brazilian island, and was corrected. Accent variants of city names exist.
customers	customer_id is one per order (99,441), while customer_unique_id is one per person (96,096).
order_payments	4,446 extra rows come from orders paid with several methods. Three rows have type not_defined and two credit-card rows have 0 installments.
sellers	59.7% of sellers are in São Paulo.

Full notes are in docs/data_quality_notes.md.

Star schema

Fact tables: fact_order_items (112,650 rows, one per item sold), fact_payments (103,886 rows) and fact_reviews (98,673 rows, one per reviewed order). Dimension tables: dim_customer (96,096), dim_seller (3,095), dim_product (32,951), dim_date (800) and dim_geography (19,011).

Design decisions:

Customers are modelled by customer_unique_id, so repeat buyers are counted once.
Payments sit in their own fact table. Joining them directly to order items would count money several times.
Where an order has several reviews, the latest is kept.
dim_geography keeps one row per zip code (average coordinates, most common city and state). Four zips with only invalid coordinates were dropped (1 customer affected), so joins to it use LEFT JOIN.
Every join was validated: zero fact rows without a matching dimension key, and a four-dimension join returns exactly the fact table's 112,650 rows.

Details of how each dimension was built are in docs/dimension_tables_explained.docx.

Analysis and findings
#	Query	Key finding
1	Monthly revenue and month-over-month growth	Orders grew from 787 (Jan 2017) to 7,421 (Nov 2017). November 2017 was the peak at R$1.00M. Revenue plateaued at R$838k to R$994k a month through 2018.
2	Cumulative revenue and 3-month average	R$13.45M over the 20 months. The first 8 months of 2018 earned R$7.34M, against R$6.11M for all of 2017.
3	Revenue by category	74 categories. The top is health_beauty at 9.3%, and 18 categories make up 80% of revenue.
4	Late delivery by state	Overall late rate is 6.8%. Among states with at least 100 orders, Alagoas is highest at 21.4% and Paraná is lowest at 4.1%. Late rate measures promises, not speed: remote states look punctual because their estimates are padded.
5	Seller segments	625 of 3,095 sellers (20%) have at least 30 delivered orders and earn 77.2% of delivered revenue. The 37 unreliable sellers carry 3.4% of that revenue.
6	Customer segments (RFM-style)	Only 3.0% of 94,703 customers ordered more than once. Repeat customers spend about 1.8 times the typical customer.
7	Cohort retention	Month-1 retention is between 0.22% and 0.71% across cohorts, with no improvement in 2018.
8	Payment behaviour	Credit cards lead 75.5% of orders, and 68% of card orders use installments. Payments agree with items plus freight within 0.02%.
9	Late delivery and review scores	Orders on time or early average 4.29 stars and late orders 2.27. The share of 1 to 2 star reviews is about 9% against about 62%.

Every breakdown is reconciled to a control total (for example R$13,449,529.68 of revenue and 94,703 customers).

Limitations
The data ends in August 2018, so customers labelled "lapsed" may have returned later.
Late delivery is associated with low ratings, which does not prove that lateness is the only cause.
Orders without a review are excluded from the review analysis (0.7% of delivered orders).
Hypotheses such as the November 2017 peak being a Black Friday effect have not been tested.
Next steps
Statistical tests of the late-delivery and review-score gap, and the drivers of review scores.
A Power BI dashboard on the star schema.
