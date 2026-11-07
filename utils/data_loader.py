
"""
Centralized data loader for the CARSOME Financing Analysis Portfolio.

All dashboard pages read CSV files from:
    data/processed/

For backward compatibility, the loader also checks the project root.
SQL remains the source of business calculations; this module loads
and validates exported SQL results.
"""

from pathlib import Path

import pandas as pd
import streamlit as st


# ============================================================
# 1. PROJECT PATHS
# ============================================================

PROJECT_ROOT = Path(__file__).resolve().parents[1]
PROCESSED_DATA_DIR = PROJECT_ROOT / "data" / "processed"


# ============================================================
# 2. DATA FILE REGISTRY
# ============================================================

DATA_FILES = {
    "dashboard": "CARSOME_Financing_Dashboard.csv",

    "financier_overall": "financier_overall_performance.csv",
    "financier_store": "financier_store_performance.csv",
    "financier_stage": "financier_stage_conversion.csv",
    "financier_assignment": "financier_assignment_audit.csv",
    "financier_disbursement": "financier_disbursement_conversion.csv",

    "waiting_time": "CARSOME_Waiting_Time_Analysis.csv",
    "loan_slash": "CARSOME_Loan_Slash_Analysis.csv",
    "cancellation": "CARSOME_Cancellation_Recommendations.csv",
}


# ============================================================
# 3. REQUIRED COLUMN DEFINITIONS
# ============================================================

DASHBOARD_REQUIRED_COLUMNS = [
    "order_id",
    "order_status",
    "financing_case_flag",
    "approved_flag",
    "accepted_flag",
    "disbursement_submitted_flag",
    "disbursement_received_flag",
    "completed_flag",
    "final_loan_status",
    "final_loan_type",
    "final_financier",
    "disbursement_submit_date",
    "disbursement_receive_date",
    "disbursement_slip_date",
    "loan_acceptance_date",
]

FINANCIER_REQUIRED_COLUMNS = {
    "overall": [
        "financier",
        "total_orders",
        "financing_cases",
        "approved_cases",
        "accepted_cases",
        "submitted_cases",
        "received_cases",
        "completed_cases",
    ],
    "store": [
        "financier",
        "carsome_store",
        "total_orders",
        "financing_cases",
        "approved_cases",
        "accepted_cases",
        "submitted_cases",
        "received_cases",
    ],
    "stage": [
        "financier",
        "financing_cases",
        "approved_cases",
        "accepted_cases",
        "submitted_cases",
        "received_cases",
    ],
    "assignment": [
        "order_status",
        "financier_field_status",
        "total_orders",
        "financing_cases",
        "approved_cases",
        "accepted_cases",
        "submitted_cases",
        "received_cases",
        "completed_cases",
        "missing_financier_orders",
    ],
    "disbursement": [
        "financier",
        "submitted_cases",
        "received_cases",
        "submitted_not_received_cases",
        "received_conversion_rate_pct",
        "not_received_rate_pct",
    ],
}

WAITING_TIME_REQUIRED_COLUMNS = [
    "financier",
    "submitted_not_received_cases",
    "cases_with_submission_date",
    "cases_missing_submission_date",
    "avg_wait_days",
    "max_wait_days",
    "wait_0_to_7_days",
    "wait_8_to_14_days",
    "wait_15_to_30_days",
    "wait_over_30_days",
]

LOAN_SLASH_REQUIRED_COLUMNS = [
    "order_id",
    "financier",
    "order_status",
    "created_time",
    "store",
    "loan_amount",
    "final_slash_amount",
    "slash_to_loan_ratio_pct",
    "loan_tenure",
    "final_loan_type",
]

CANCELLATION_REQUIRED_COLUMNS = [
    "store",
    "total_orders",
    "cancelled_orders",
    "overall_cancellation_rate_pct",
    "financing_orders",
    "financing_cancelled_orders",
    "financing_cancellation_rate_pct",
    "non_financing_orders",
    "non_financing_cancelled_orders",
    "non_financing_cancellation_rate_pct",
    "cancellation_gap_pp",
    "investigation_priority",
]


# ============================================================
# 4. GENERIC CSV LOADER
# ============================================================

def get_data_path(file_name: str) -> Path:
    """
    Find a dataset in data/processed first.
    Fall back to project root for files not moved yet.
    """

    candidates = [
        PROCESSED_DATA_DIR / file_name,
        PROJECT_ROOT / file_name,
    ]

    for path in candidates:
        if path.exists():
            return path

    searched_paths = "\n".join(
        str(path) for path in candidates
    )

    raise FileNotFoundError(
        f"Dataset not found: {file_name}\n"
        f"Searched locations:\n{searched_paths}"
    )


@st.cache_data(ttl=300)
def load_csv_dataset(file_name: str) -> pd.DataFrame:
    """
    Load one CSV file and normalize its column names.
    """

    file_path = get_data_path(file_name)

    df = pd.read_csv(file_path)

    df.columns = (
        df.columns
        .astype(str)
        .str.strip()
    )

    return df


def validate_columns(
    df: pd.DataFrame,
    required_columns: list,
    dataset_name: str,
) -> None:
    """
    Raise a clear error when required columns are missing.
    """

    missing = [
        column
        for column in required_columns
        if column not in df.columns
    ]

    if missing:
        raise ValueError(
            f"{dataset_name} is missing required columns: {missing}"
        )


def convert_numeric_columns(
    df: pd.DataFrame,
    columns: list,
) -> pd.DataFrame:
    """
    Safely convert available columns to numeric values.
    """

    df = df.copy()

    for column in columns:
        if column in df.columns:
            df[column] = pd.to_numeric(
                df[column],
                errors="coerce",
            )

    return df


def normalize_text_columns(
    df: pd.DataFrame,
    columns: list,
    missing_label: str = "Missing / Blank",
) -> pd.DataFrame:
    """
    Standardize text fields and blank values.
    """

    df = df.copy()

    for column in columns:
        if column in df.columns:
            df[column] = (
                df[column]
                .astype("string")
                .str.strip()
                .replace("", pd.NA)
                .fillna(missing_label)
            )

    return df


# ============================================================
# 5. DASHBOARD 1 & 2: ORDER-LEVEL DATA
# ============================================================

@st.cache_data(ttl=300)
def load_dashboard_data() -> pd.DataFrame:
    """
    Load the September 2026 order-level financing dataset.

    Source:
        SQL export from carsome_orders_analysis.stg_orders

    File:
        CARSOME_Financing_Dashboard.csv
    """

    df = load_csv_dataset(
        DATA_FILES["dashboard"]
    )

    validate_columns(
        df,
        DASHBOARD_REQUIRED_COLUMNS,
        "CARSOME Financing Dashboard dataset",
    )

    # Normalize flags
    flag_columns = [
        "financing_case_flag",
        "approved_flag",
        "accepted_flag",
        "disbursement_submitted_flag",
        "disbursement_received_flag",
        "completed_flag",
    ]

    df = convert_numeric_columns(
        df,
        flag_columns,
    )

    for column in flag_columns:
        df[column] = (
            df[column]
            .fillna(0)
            .astype(int)
        )

    # Normalize date fields
    date_columns = [
        "created_time",
        "disbursement_submit_date",
        "disbursement_receive_date",
        "disbursement_slip_date",
        "loan_acceptance_date",
    ]

    for column in date_columns:
        if column in df.columns:
            df[column] = pd.to_datetime(
                df[column],
                errors="coerce",
            )

    # Normalize descriptive fields
    text_columns = [
        "order_status",
        "final_loan_status",
        "final_loan_type",
        "final_financier",
    ]

    df = normalize_text_columns(
        df,
        text_columns,
    )

    return df


@st.cache_data(ttl=300)
def load_financing_kpis() -> pd.DataFrame:
    """
    Calculate Executive Overview KPIs from the same order-level CSV.

    This replaces the previous separate MySQL KPI query.
    """

    df = load_dashboard_data()

    flag_columns = {
        "financing_cases": "financing_case_flag",
        "approved_cases": "approved_flag",
        "accepted_cases": "accepted_flag",
        "submitted_cases": "disbursement_submitted_flag",
        "received_cases": "disbursement_received_flag",
        "completed_cases": "completed_flag",
    }

    result = {
        "total_orders": int(len(df)),
    }

    for output_column, source_column in flag_columns.items():
        result[output_column] = int(
            df[source_column].sum()
        )

    return pd.DataFrame([result])


# ============================================================
# 6. DASHBOARD 3: FINANCIER PERFORMANCE
# ============================================================

@st.cache_data(ttl=300)
def load_financier_performance_data() -> dict:
    """
    Load the five SQL-exported datasets used by Dashboard 3.
    """

    file_mapping = {
        "overall": DATA_FILES["financier_overall"],
        "store": DATA_FILES["financier_store"],
        "stage": DATA_FILES["financier_stage"],
        "assignment": DATA_FILES["financier_assignment"],
        "disbursement": DATA_FILES["financier_disbursement"],
    }

    datasets = {}

    for key, file_name in file_mapping.items():

        df = load_csv_dataset(file_name)

        # SQL output aliases may differ from the dashboard names.
        if key == "overall":
            df = df.rename(
                columns={
                    "disbursement_submitted_cases": "submitted_cases",
                    "disbursement_received_cases": "received_cases",
                }
            )

        validate_columns(
            df,
            FINANCIER_REQUIRED_COLUMNS[key],
            f"Financier Performance - {key}",
        )

        datasets[key] = df

    # Convert numeric fields
    numeric_columns = [
        "total_orders",
        "financing_cases",
        "approved_cases",
        "accepted_cases",
        "submitted_cases",
        "received_cases",
        "completed_cases",
        "missing_financier_orders",
        "financing_to_approval_pct",
        "approval_to_acceptance_pct",
        "acceptance_to_submission_pct",
        "submission_to_received_pct",
        "received_conversion_rate_pct",
        "not_received_rate_pct",
    ]

    for key, df in datasets.items():
        datasets[key] = convert_numeric_columns(
            df,
            numeric_columns,
        )

    # Normalize financier labels where applicable
    for key in ["overall", "store", "stage", "disbursement"]:
        datasets[key] = normalize_text_columns(
            datasets[key],
            ["financier"],
        )

    datasets["assignment"] = normalize_text_columns(
        datasets["assignment"],
        ["order_status", "financier_field_status"],
    )

    return datasets


# ============================================================
# 7. DASHBOARD 4: WAITING TIME ANALYSIS
# ============================================================

@st.cache_data(ttl=300)
def load_waiting_time_data() -> pd.DataFrame:

    df = load_csv_dataset(
        DATA_FILES["waiting_time"]
    )

    validate_columns(
        df,
        WAITING_TIME_REQUIRED_COLUMNS,
        "Waiting Time Analysis",
    )

    numeric_columns = [
        column
        for column in WAITING_TIME_REQUIRED_COLUMNS
        if column != "financier"
    ]

    df = convert_numeric_columns(
        df,
        numeric_columns,
    )

    df = normalize_text_columns(
        df,
        ["financier"],
    )

    return df


# ============================================================
# 8. DASHBOARD 5: LOAN SLASH ANALYSIS
# ============================================================

@st.cache_data(ttl=300)
def load_loan_slash_data() -> pd.DataFrame:

    df = load_csv_dataset(
        DATA_FILES["loan_slash"]
    )

    validate_columns(
        df,
        LOAN_SLASH_REQUIRED_COLUMNS,
        "Loan Slash Analysis",
    )

    numeric_columns = [
        "loan_amount",
        "final_slash_amount",
        "slash_to_loan_ratio_pct",
        "loan_tenure",
    ]

    df = convert_numeric_columns(
        df,
        numeric_columns,
    )

    df["created_time"] = pd.to_datetime(
        df["created_time"],
        errors="coerce",
    )

    text_columns = [
        "financier",
        "order_status",
        "store",
        "final_loan_type",
    ]

    df = normalize_text_columns(
        df,
        text_columns,
    )

    return df


# ============================================================
# 9. DASHBOARD 6: CANCELLATION RECOMMENDATIONS
# ============================================================

@st.cache_data(ttl=300)
def load_cancellation_data() -> pd.DataFrame:

    df = load_csv_dataset(
        DATA_FILES["cancellation"]
    )

    validate_columns(
        df,
        CANCELLATION_REQUIRED_COLUMNS,
        "Cancellation Recommendations",
    )

    numeric_columns = [
        "total_orders",
        "cancelled_orders",
        "overall_cancellation_rate_pct",
        "financing_orders",
        "financing_cancelled_orders",
        "financing_cancellation_rate_pct",
        "non_financing_orders",
        "non_financing_cancelled_orders",
        "non_financing_cancellation_rate_pct",
        "cancellation_gap_pp",
    ]

    df = convert_numeric_columns(
        df,
        numeric_columns,
    )

    df = normalize_text_columns(
        df,
        ["store", "investigation_priority"],
    )

    return df
