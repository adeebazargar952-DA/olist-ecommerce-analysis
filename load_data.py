import sqlite3
import pandas as pd
import logging

from config import DATA_RAW_DIR, DB_PATH, RAW_TABLES

logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)s | %(message)s")
logger = logging.getLogger(__name__)

FOREIGN_KEYS = [
    ("orders", "customer_id", "customers", "customer_id"),
    ("order_items", "order_id", "orders", "order_id"),
    ("order_items", "product_id", "products", "product_id"),
    ("order_items", "seller_id", "sellers", "seller_id"),
    ("order_payments", "order_id", "orders", "order_id"),
    ("order_reviews", "order_id", "orders", "order_id"),
    ("products", "product_category_name", "category_translation", "product_category_name"),
]


def load_raw_tables(conn):
    row_counts = {}
    for table_name, filename in RAW_TABLES.items():
        csv_path = DATA_RAW_DIR / filename
        if not csv_path.exists():
            logger.warning(f"Missing file, skipped: {csv_path}")
            continue
        df = pd.read_csv(csv_path)
        df.to_sql(table_name, conn, if_exists="replace", index=False)
        row_counts[table_name] = len(df)
        logger.info(f"Loaded {table_name:22s} {len(df):>7,} rows  {len(df.columns):>2} cols")
    return row_counts


def build_data_dictionary(conn):
    rows = []
    cur = conn.cursor()
    for table_name in RAW_TABLES:
        cur.execute(f"PRAGMA table_info({table_name});")
        for cid, name, dtype, notnull, default, pk in cur.fetchall():
            rows.append({
                "table_name": table_name,
                "column_name": name,
                "data_type": dtype,
                "is_primary_key": bool(pk),
            })
    meta_df = pd.DataFrame(rows)
    fk_lookup = {(t, c): f"{rt}.{rc}" for t, c, rt, rc in FOREIGN_KEYS}
    meta_df["references"] = meta_df.apply(
        lambda r: fk_lookup.get((r.table_name, r.column_name)), axis=1
    )
    meta_df.to_sql("data_dictionary", conn, if_exists="replace", index=False)
    logger.info(f"Built data_dictionary with {len(meta_df)} column entries")
    return meta_df


def run_data_quality_checks(conn):
    results = []
    for table_name in RAW_TABLES:
        try:
            df = pd.read_sql(f"SELECT * FROM {table_name}", conn)
        except pd.errors.DatabaseError:
            continue
        null_pct = (df.isna().sum() / len(df) * 100).round(2)
        dup_count = df.duplicated().sum()
        for col in df.columns:
            results.append({
                "table_name": table_name,
                "column_name": col,
                "null_pct": null_pct[col],
                "duplicate_rows_in_table": dup_count,
                "row_count": len(df),
            })
    dq_df = pd.DataFrame(results)
    dq_df.to_sql("dq_report", conn, if_exists="replace", index=False)
    logger.info(f"Built dq_report — {(dq_df['null_pct'] > 0).sum()} columns have nulls")
    return dq_df


def build_database():
    conn = sqlite3.connect(DB_PATH)
    logger.info(f"Building database at {DB_PATH}")
    load_raw_tables(conn)
    build_data_dictionary(conn)
    run_data_quality_checks(conn)
    conn.commit()
    conn.close()
    logger.info(f"Done. Database saved to {DB_PATH.resolve()}")


if __name__ == "__main__":
    build_database()
