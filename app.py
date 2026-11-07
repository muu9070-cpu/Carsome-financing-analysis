import streamlit as st

st.set_page_config(
    page_title="CARSOME Financing Analysis",
    page_icon="🚗",
    layout="wide",
    initial_sidebar_state="expanded"
)

st.title("CARSOME Financing Analysis")

st.sidebar.title("Navigation")
st.sidebar.caption("Financing Performance Dashboard")

st.markdown("""
### Welcome to CARSOME Financing Analysis

This dashboard provides an overview of financing performance,
financing funnel conversion, financier performance,
waiting time, loan slash and cancellation analysis.
""")