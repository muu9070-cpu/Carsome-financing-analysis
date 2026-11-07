

import streamlit as st
import pandas as pd
import plotly.express as px

from utils.data_loader import load_loan_slash_data


# ============================================================
# 1. PAGE CONFIGURATION
# ============================================================

st.title("Loan Slash Analysis")


# ============================================================
# 2. HELPER FUNCTIONS
# ============================================================

def number_format(value):

    if pd.isna(value):
        return "N/A"

    return f"{value:,.0f}"


def currency_format(value):

    if pd.isna(value):
        return "N/A"

    return f"RM {value:,.2f}"


def percent_format(value):

    if pd.isna(value):
        return "N/A"

    return f"{value:.2f}%"


# ============================================================
# 3. LOAD AND PREPARE DATA
# ============================================================

def prepare_loan_slash_data():

    loan_df = load_loan_slash_data()

    if loan_df.empty:
        return loan_df

    # Keep valid analysis records only.
    # This dashboard describes confirmed loan slash cases.

    loan_df = loan_df[
        loan_df["final_slash_amount"].notna()
        & loan_df["loan_amount"].gt(0)
        & loan_df["slash_to_loan_ratio_pct"].notna()
    ].copy()

    return loan_df


# ============================================================
# 4. MAIN DASHBOARD
# ============================================================

def show_loan_slash_analysis():

    st.title("Loan Slash Analysis")

    st.caption(
        "Analysis of human-confirmed loan slash cases, "
        "loan amounts and slash-to-loan ratios."
    )

    # --------------------------------------------------------
    # 1. Load Data from Centralized Data Loader
    # --------------------------------------------------------

    try:

        loan_df = prepare_loan_slash_data()

    except (FileNotFoundError, ValueError) as e:

        st.error(str(e))

        st.info(
            "Please verify that "
            "CARSOME_Loan_Slash_Analysis.csv "
            "is available in data/processed/."
        )

        return

    except Exception as e:

        st.error(
            f"Unable to load loan slash data: {e}"
        )

        return

    if loan_df.empty:

        st.warning(
            "No valid loan slash analysis records available."
        )

        return

    st.caption(
        "Data Source: loan_slash_analysis_20261106 | "
        f"{len(loan_df):,} validated analysis records"
    )

    st.divider()

    # --------------------------------------------------------
    # 2. SIDEBAR FILTERS
    # --------------------------------------------------------

    st.sidebar.header("Loan Slash Filters")

    financier_options = sorted(
        loan_df["financier"]
        .dropna()
        .unique()
        .tolist()
    )

    selected_financiers = st.sidebar.multiselect(
        "Financier",
        financier_options,
        default=financier_options,
        key="loan_slash_financier_filter"
    )

    status_options = sorted(
        loan_df["order_status"]
        .dropna()
        .unique()
        .tolist()
    )

    selected_statuses = st.sidebar.multiselect(
        "Order Status",
        status_options,
        default=status_options,
        key="loan_slash_status_filter"
    )

    loan_type_options = sorted(
        loan_df["final_loan_type"]
        .dropna()
        .unique()
        .tolist()
    )

    selected_loan_types = st.sidebar.multiselect(
        "Loan Type",
        loan_type_options,
        default=loan_type_options,
        key="loan_slash_type_filter"
    )

    filtered_df = loan_df[
        loan_df["financier"].isin(selected_financiers)
        & loan_df["order_status"].isin(selected_statuses)
        & loan_df["final_loan_type"].isin(selected_loan_types)
    ].copy()

    if filtered_df.empty:

        st.warning(
            "No records match the selected filters."
        )

        return

    st.caption(
        f"Filtered Records: {len(filtered_df):,} / "
        f"{len(loan_df):,}"
    )

    st.divider()

    # --------------------------------------------------------
    # 3. OVERALL LOAN SLASH OVERVIEW
    # --------------------------------------------------------

    st.header("1. Overall Loan Slash Overview")

    total_records = len(filtered_df)

    total_slash_amount = (
        filtered_df["final_slash_amount"].sum()
    )

    total_loan_amount = (
        filtered_df["loan_amount"].sum()
    )

    avg_loan_amount = (
        filtered_df["loan_amount"].mean()
    )

    avg_slash_amount = (
        filtered_df["final_slash_amount"].mean()
    )

    avg_slash_ratio = (
        filtered_df["slash_to_loan_ratio_pct"].mean()
    )

    weighted_slash_ratio = (
        total_slash_amount / total_loan_amount * 100
        if total_loan_amount > 0 else 0
    )

    col1, col2, col3 = st.columns(3)

    col1.metric(
        "Confirmed Slash Cases",
        number_format(total_records)
    )

    col2.metric(
        "Total Slash Amount",
        currency_format(total_slash_amount)
    )

    col3.metric(
        "Total Loan Amount",
        currency_format(total_loan_amount)
    )

    col4, col5, col6 = st.columns(3)

    col4.metric(
        "Average Slash Amount",
        currency_format(avg_slash_amount)
    )

    col5.metric(
        "Average Loan Amount",
        currency_format(avg_loan_amount)
    )

    col6.metric(
        "Average Slash Ratio",
        percent_format(avg_slash_ratio)
    )

    st.metric(
        "Weighted Slash-to-Loan Ratio",
        percent_format(weighted_slash_ratio)
    )

    st.caption(
        "Average Slash Ratio = Average of individual order ratios. "
        "Weighted Slash Ratio = Total Slash Amount / "
        "Total Loan Amount × 100%. "
        "These two measures are not interchangeable."
    )

    st.divider()

    # --------------------------------------------------------
    # 4. SLASH AMOUNT DISTRIBUTION
    # --------------------------------------------------------

    st.header("2. Slash Amount Distribution")

    col1, col2 = st.columns(2)

    with col1:

        fig_slash_hist = px.histogram(
            filtered_df,
            x="final_slash_amount",
            nbins=15,
            title="Distribution of Final Slash Amount",
            labels={
                "final_slash_amount": "Slash Amount (RM)",
                "count": "Number of Cases"
            },
            color_discrete_sequence=["#0866C6"]
        )

        fig_slash_hist.update_layout(
            height=420,
            xaxis_title="Slash Amount (RM)",
            yaxis_title="Number of Cases"
        )

        st.plotly_chart(
            fig_slash_hist,
            use_container_width=True
        )

    with col2:

        fig_loan_hist = px.histogram(
            filtered_df,
            x="loan_amount",
            nbins=15,
            title="Distribution of Loan Amount",
            labels={
                "loan_amount": "Loan Amount (RM)",
                "count": "Number of Cases"
            },
            color_discrete_sequence=["#83C9F4"]
        )

        fig_loan_hist.update_layout(
            height=420,
            xaxis_title="Loan Amount (RM)",
            yaxis_title="Number of Cases"
        )

        st.plotly_chart(
            fig_loan_hist,
            use_container_width=True
        )

    st.divider()

    # --------------------------------------------------------
    # 5. SLASH PERFORMANCE BY FINANCIER
    # --------------------------------------------------------

    st.header("3. Slash Performance by Financier")

    financier_summary = (
        filtered_df.groupby(
            "financier",
            dropna=False
        )
        .agg(
            Slash_Cases=("order_id", "nunique"),

            Total_Slash_Amount=(
                "final_slash_amount",
                "sum"
            ),

            Average_Slash_Amount=(
                "final_slash_amount",
                "mean"
            ),

            Average_Loan_Amount=(
                "loan_amount",
                "mean"
            ),

            Average_Slash_Ratio=(
                "slash_to_loan_ratio_pct",
                "mean"
            ),

            Total_Loan_Amount=(
                "loan_amount",
                "sum"
            )
        )
        .reset_index()
    )

    financier_summary["Weighted_Slash_Ratio"] = (
        financier_summary["Total_Slash_Amount"]
        / financier_summary["Total_Loan_Amount"].replace(
            0,
            pd.NA
        )
        * 100
    )

    financier_summary = financier_summary.sort_values(
        "Weighted_Slash_Ratio",
        ascending=False
    )

    fig_financier = px.bar(
        financier_summary,
        x="financier",
        y="Total_Slash_Amount",
        text="Total_Slash_Amount",
        title="Total Slash Amount by Financier",
        labels={
            "financier": "Financier",
            "Total_Slash_Amount": "Total Slash Amount (RM)"
        },
        color_discrete_sequence=["#0866C6"]
    )

    fig_financier.update_traces(
        texttemplate="RM %{y:,.0f}",
        textposition="outside"
    )

    fig_financier.update_layout(
        height=500,
        xaxis_tickangle=-35
    )

    st.plotly_chart(
        fig_financier,
        use_container_width=True
    )

    # Weighted ratio comparison

    fig_weighted = px.bar(
        financier_summary.sort_values(
            "Weighted_Slash_Ratio",
            ascending=True
        ),
        x="Weighted_Slash_Ratio",
        y="financier",
        orientation="h",
        text="Weighted_Slash_Ratio",
        title="Weighted Slash-to-Loan Ratio by Financier",
        labels={
            "financier": "Financier",
            "Weighted_Slash_Ratio": "Weighted Slash Ratio (%)"
        }
    )

    fig_weighted.update_traces(
        texttemplate="%{x:.2f}%",
        textposition="outside",
        marker_color="#0866C6"
    )

    fig_weighted.update_layout(
        height=500
    )

    st.plotly_chart(
        fig_weighted,
        use_container_width=True
    )

    st.subheader("Financier Performance Details")

    financier_display = financier_summary.rename(
        columns={
            "financier": "Financier",
            "Slash_Cases": "Slash Cases",
            "Total_Slash_Amount": "Total Slash Amount (RM)",
            "Average_Slash_Amount": "Average Slash Amount (RM)",
            "Average_Loan_Amount": "Average Loan Amount (RM)",
            "Average_Slash_Ratio": "Average Slash Ratio (%)",
            "Total_Loan_Amount": "Total Loan Amount (RM)",
            "Weighted_Slash_Ratio": "Weighted Slash Ratio (%)"
        }
    )

    st.dataframe(
        financier_display.round(2),
        use_container_width=True,
        hide_index=True
    )

    st.divider()

    # --------------------------------------------------------
    # 6. SLASH-TO-LOAN RATIO ANALYSIS
    # --------------------------------------------------------

    st.header("4. Slash-to-Loan Ratio Analysis")

    ratio_bins = [
        0,
        2,
        5,
        10,
        20,
        float("inf")
    ]

    ratio_labels = [
        "Below 2%",
        "2% - 5%",
        "5% - 10%",
        "10% - 20%",
        "20% and Above"
    ]

    ratio_distribution = filtered_df.copy()

    ratio_distribution["Slash_Ratio_Group"] = pd.cut(
        ratio_distribution["slash_to_loan_ratio_pct"],
        bins=ratio_bins,
        labels=ratio_labels,
        right=False,
        include_lowest=True
    )

    ratio_summary = (
        ratio_distribution.groupby(
            "Slash_Ratio_Group",
            observed=False
        )
        .agg(
            Order_Count=("order_id", "nunique")
        )
        .reindex(
            ratio_labels,
            fill_value=0
        )
        .reset_index()
    )

    ratio_summary["Percentage"] = (
        ratio_summary["Order_Count"]
        / total_records * 100
    )

    fig_ratio = px.bar(
        ratio_summary,
        x="Slash_Ratio_Group",
        y="Order_Count",
        text="Order_Count",
        title="Distribution of Slash-to-Loan Ratio",
        labels={
            "Slash_Ratio_Group": "Slash Ratio Group",
            "Order_Count": "Number of Orders"
        },
        color_discrete_sequence=["#0866C6"]
    )

    fig_ratio.update_traces(
        textposition="outside"
    )

    fig_ratio.update_layout(
        height=450,
        xaxis_title="Slash-to-Loan Ratio",
        yaxis_title="Number of Orders"
    )

    st.plotly_chart(
        fig_ratio,
        use_container_width=True
    )

    st.dataframe(
        ratio_summary.rename(
            columns={
                "Slash_Ratio_Group": "Slash Ratio Group",
                "Order_Count": "Order Count",
                "Percentage": "Percentage (%)"
            }
        ).round(2),
        use_container_width=True,
        hide_index=True
    )

    st.divider()

    # --------------------------------------------------------
    # 7. LOAN AMOUNT VS SLASH AMOUNT RELATIONSHIP
    # --------------------------------------------------------

    st.header("5. Loan Amount vs Slash Amount Relationship")

    fig_scatter = px.scatter(
        filtered_df,
        x="loan_amount",
        y="final_slash_amount",
        color="financier",
        hover_data=[
            "order_id",
            "slash_to_loan_ratio_pct"
        ],
        title="Relationship Between Loan Amount and Slash Amount",
        labels={
            "loan_amount": "Loan Amount (RM)",
            "final_slash_amount": "Slash Amount (RM)",
            "financier": "Financier"
        }
    )

    fig_scatter.update_layout(
        height=550
    )

    st.plotly_chart(
        fig_scatter,
        use_container_width=True
    )

    correlation = filtered_df[
        [
            "loan_amount",
            "final_slash_amount"
        ]
    ].corr(method="pearson").iloc[0, 1]

    if pd.notna(correlation):

        st.metric(
            "Pearson Correlation",
            f"{correlation:.4f}"
        )

        st.caption(
            "Pearson correlation measures the linear association "
            "between loan amount and slash amount. "
            "It does not establish causation."
        )

    st.divider()

    # --------------------------------------------------------
    # 8. LOAN TYPE ANALYSIS
    # --------------------------------------------------------

    st.header("6. Loan Type Analysis")

    loan_type_summary = (
        filtered_df.groupby(
            "final_loan_type",
            dropna=False
        )
        .agg(
            Slash_Cases=("order_id", "nunique"),

            Average_Loan_Amount=(
                "loan_amount",
                "mean"
            ),

            Average_Slash_Amount=(
                "final_slash_amount",
                "mean"
            ),

            Average_Slash_Ratio=(
                "slash_to_loan_ratio_pct",
                "mean"
            )
        )
        .reset_index()
    )

    loan_type_summary["final_loan_type"] = (
        loan_type_summary["final_loan_type"]
        .fillna("Missing / Blank")
    )

    fig_loan_type = px.bar(
        loan_type_summary,
        x="final_loan_type",
        y="Slash_Cases",
        text="Slash_Cases",
        title="Slash Cases by Loan Type",
        labels={
            "final_loan_type": "Loan Type",
            "Slash_Cases": "Number of Cases"
        },
        color_discrete_sequence=["#0866C6"]
    )

    fig_loan_type.update_traces(
        textposition="outside"
    )

    fig_loan_type.update_layout(
        height=450,
        xaxis_tickangle=-25
    )

    st.plotly_chart(
        fig_loan_type,
        use_container_width=True
    )

    st.dataframe(
        loan_type_summary.rename(
            columns={
                "final_loan_type": "Loan Type",
                "Slash_Cases": "Slash Cases",
                "Average_Loan_Amount": "Average Loan Amount (RM)",
                "Average_Slash_Amount": "Average Slash Amount (RM)",
                "Average_Slash_Ratio": "Average Slash Ratio (%)"
            }
        ).round(2),
        use_container_width=True,
        hide_index=True
    )

    st.divider()

    # --------------------------------------------------------
    # 9. LOAN TENURE ANALYSIS
    # --------------------------------------------------------

    st.header("7. Loan Tenure Analysis")

    tenure_df = filtered_df[
        filtered_df["loan_tenure"].notna()
    ].copy()

    if not tenure_df.empty:

        tenure_summary = (
            tenure_df.groupby("loan_tenure")
            .agg(
                Slash_Cases=("order_id", "nunique"),

                Average_Slash_Amount=(
                    "final_slash_amount",
                    "mean"
                ),

                Average_Slash_Ratio=(
                    "slash_to_loan_ratio_pct",
                    "mean"
                )
            )
            .reset_index()
            .sort_values("loan_tenure")
        )

        fig_tenure = px.bar(
            tenure_summary,
            x="loan_tenure",
            y="Slash_Cases",
            text="Slash_Cases",
            title="Slash Cases by Loan Tenure",
            labels={
                "loan_tenure": "Loan Tenure",
                "Slash_Cases": "Number of Cases"
            },
            color_discrete_sequence=["#0866C6"]
        )

        fig_tenure.update_traces(
            textposition="outside"
        )

        fig_tenure.update_layout(
            height=450,
            xaxis_title="Loan Tenure",
            yaxis_title="Number of Cases"
        )

        st.plotly_chart(
            fig_tenure,
            use_container_width=True
        )

        st.dataframe(
            tenure_summary.rename(
                columns={
                    "loan_tenure": "Loan Tenure",
                    "Slash_Cases": "Slash Cases",
                    "Average_Slash_Amount":
                        "Average Slash Amount (RM)",
                    "Average_Slash_Ratio":
                        "Average Slash Ratio (%)"
                }
            ).round(2),
            use_container_width=True,
            hide_index=True
        )

    else:

        st.info(
            "No valid loan tenure information available."
        )

    st.divider()

    # --------------------------------------------------------
    # 10. HIGH SLASH RATIO CASES
    # --------------------------------------------------------

    st.header("8. High Slash Ratio Cases")

    high_ratio_df = filtered_df[
        filtered_df["slash_to_loan_ratio_pct"] >= 20
    ].copy()

    st.metric(
        "Cases with Slash Ratio ≥ 20%",
        f"{len(high_ratio_df):,}"
    )

    if not high_ratio_df.empty:

        high_ratio_df = high_ratio_df.sort_values(
            "slash_to_loan_ratio_pct",
            ascending=False
        )

        high_ratio_display = high_ratio_df[
            [
                "order_id",
                "financier",
                "loan_amount",
                "final_slash_amount",
                "slash_to_loan_ratio_pct",
                "loan_tenure",
                "final_loan_type",
                "order_status"
            ]
        ].rename(
            columns={
                "order_id": "Order ID",
                "financier": "Financier",
                "loan_amount": "Loan Amount (RM)",
                "final_slash_amount": "Slash Amount (RM)",
                "slash_to_loan_ratio_pct": "Slash Ratio (%)",
                "loan_tenure": "Loan Tenure",
                "final_loan_type": "Loan Type",
                "order_status": "Order Status"
            }
        )

        st.dataframe(
            high_ratio_display.round(2),
            use_container_width=True,
            hide_index=True
        )

    else:

        st.info(
            "No cases with a slash-to-loan ratio of 20% or above."
        )

    st.divider()

    # --------------------------------------------------------
    # 11. FINANCIER DETAIL EXPLORER
    # --------------------------------------------------------

    st.header("9. Financier Detail Explorer")

    detail_financiers = sorted(
        filtered_df["financier"]
        .dropna()
        .unique()
        .tolist()
    )

    if detail_financiers:

        selected_financier = st.selectbox(
            "Select a financier",
            detail_financiers,
            key="loan_slash_detail_financier"
        )

        selected_data = filtered_df[
            filtered_df["financier"] == selected_financier
        ].copy()

        detail_cases = len(selected_data)

        detail_total_slash = (
            selected_data["final_slash_amount"].sum()
        )

        detail_total_loan = (
            selected_data["loan_amount"].sum()
        )

        detail_avg_ratio = (
            selected_data["slash_to_loan_ratio_pct"].mean()
        )

        detail_weighted_ratio = (
            detail_total_slash / detail_total_loan * 100
            if detail_total_loan > 0 else 0
        )

        detail_col1, detail_col2 = st.columns(2)

        detail_col1.metric(
            "Slash Cases",
            number_format(detail_cases)
        )

        detail_col2.metric(
            "Total Slash Amount",
            currency_format(detail_total_slash)
        )

        detail_col3, detail_col4 = st.columns(2)

        detail_col3.metric(
            "Average Slash Ratio",
            percent_format(detail_avg_ratio)
        )

        detail_col4.metric(
            "Weighted Slash Ratio",
            percent_format(detail_weighted_ratio)
        )

        fig_detail = px.scatter(
            selected_data,
            x="loan_amount",
            y="final_slash_amount",
            size="slash_to_loan_ratio_pct",
            color="order_status",
            hover_data=["order_id"],
            title=f"{selected_financier} - Loan Slash Cases",
            labels={
                "loan_amount": "Loan Amount (RM)",
                "final_slash_amount": "Slash Amount (RM)",
                "order_status": "Order Status"
            }
        )

        fig_detail.update_layout(
            height=450
        )

        st.plotly_chart(
            fig_detail,
            use_container_width=True
        )

    st.divider()

    # --------------------------------------------------------
    # 12. LOAN SLASH DATA SUMMARY
    # --------------------------------------------------------

    st.header("10. Loan Slash Data Summary")

    summary_columns = [
        "order_id",
        "financier",
        "order_status",
        "loan_amount",
        "final_slash_amount",
        "slash_to_loan_ratio_pct",
        "loan_tenure",
        "final_loan_type",
        "store"
    ]

    summary_df = filtered_df[
        summary_columns
    ].copy()

    summary_df = summary_df.rename(
        columns={
            "order_id": "Order ID",
            "financier": "Financier",
            "order_status": "Order Status",
            "loan_amount": "Loan Amount (RM)",
            "final_slash_amount": "Final Slash Amount (RM)",
            "slash_to_loan_ratio_pct": "Slash Ratio (%)",
            "loan_tenure": "Loan Tenure",
            "final_loan_type": "Loan Type",
            "store": "CARSOME Store"
        }
    )

    st.dataframe(
        summary_df.sort_values(
            "Slash Ratio (%)",
            ascending=False
        ).round(2),
        use_container_width=True,
        hide_index=True
    )

    st.caption(
        "Data Source: loan_slash_analysis_20261106 | "
        f"{total_records:,} filtered records. "
        "Amounts are based on human-confirmed final slash values."
    )

    st.info(
        "Interpretation Note: This dashboard describes confirmed "
        "loan slash cases only. The original 55-record analysis "
        "sample should not be interpreted as the slash rate among "
        "all financing orders, because it does not include all "
        "non-slash orders."
    )

    st.divider()

    # --------------------------------------------------------
    # 13. DOWNLOAD FILTERED DATA
    # --------------------------------------------------------

    st.header("11. Export Filtered Data")

    csv_data = filtered_df.to_csv(
        index=False
    ).encode("utf-8-sig")

    st.download_button(
        label="Download Loan Slash Analysis CSV",
        data=csv_data,
        file_name="CARSOME_Loan_Slash_Analysis_Filtered.csv",
        mime="text/csv"
    )


# ============================================================
# 5. RUN DASHBOARD
# ============================================================

show_loan_slash_analysis()
