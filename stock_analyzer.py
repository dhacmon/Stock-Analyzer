import streamlit as st
import yfinance as yf
import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots
from datetime import datetime, timedelta
import io
import re

# For PDF and Word file reading
try:
    import pdfplumber
    PDF_SUPPORT = True
except ImportError:
    PDF_SUPPORT = False

try:
    from docx import Document
    DOCX_SUPPORT = True
except ImportError:
    DOCX_SUPPORT = False

# Page configuration
st.set_page_config(
    page_title="Stock Analyzer",
    page_icon="📈",
    layout="wide"
)

# Custom CSS for better styling
st.markdown("""
<style>
    .metric-card {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        padding: 20px;
        border-radius: 15px;
        color: white;
        text-align: center;
        box-shadow: 0 4px 15px rgba(0,0,0,0.2);
    }
    .metric-card-green {
        background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
    }
    .metric-card-orange {
        background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
    }
    .metric-value {
        font-size: 2.5rem;
        font-weight: bold;
        margin: 10px 0;
    }
    .metric-label {
        font-size: 1rem;
        opacity: 0.9;
    }
    .stApp {
        background-color: #0e1117;
    }
    h1 {
        text-align: center;
        color: #ffffff;
        padding: 20px 0;
    }
    .above-ma {
        color: #00ff88;
        font-weight: bold;
    }
    .below-ma {
        color: #ff4444;
        font-weight: bold;
    }
</style>
""", unsafe_allow_html=True)

def calculate_atr(df, period=14):
    """Calculate Average True Range (ATR)"""
    high = df['High']
    low = df['Low']
    close = df['Close']

    # Calculate True Range components
    tr1 = high - low
    tr2 = abs(high - close.shift(1))
    tr3 = abs(low - close.shift(1))

    # True Range is the maximum of the three
    tr = pd.concat([tr1, tr2, tr3], axis=1).max(axis=1)

    # ATR is the rolling mean of True Range
    atr = tr.rolling(window=period).mean()

    return atr

def get_stock_data(ticker, days=400):
    """Fetch stock data from Yahoo Finance"""
    end_date = datetime.now()
    # Fetch ~400 calendar days to ensure we have 150+ trading days for MA calculation
    start_date = end_date - timedelta(days=days)

    stock = yf.Ticker(ticker)
    df = stock.history(start=start_date, end=end_date)

    if df.empty:
        return None, None

    # Calculate 150-day Moving Average
    df['MA150'] = df['Close'].rolling(window=150).mean()

    # Calculate ATR (14-day period is standard)
    df['ATR'] = calculate_atr(df, period=14)

    return df, stock.info

def get_stock_summary(ticker):
    """Get summary data for a single ticker (for portfolio table)"""
    try:
        df, info = get_stock_data(ticker)
        if df is None or df.empty:
            return None

        current_price = df['Close'].iloc[-1]
        ma150 = df['MA150'].iloc[-1]
        atr = df['ATR'].iloc[-1]

        # Calculate gap percentage
        if pd.notna(ma150) and ma150 != 0:
            gap_pct = ((current_price - ma150) / ma150) * 100
        else:
            gap_pct = None

        return {
            'Ticker': ticker,
            'Current Price': current_price,
            '150-Day MA': ma150,
            'Gap %': gap_pct,
            'ATR (14)': atr
        }
    except Exception as e:
        return None

def extract_tickers_from_text(text):
    """Extract stock tickers from text content"""
    # Common pattern for stock tickers: 1-5 uppercase letters
    # Filter out common words that might match
    common_words = {'A', 'I', 'AM', 'AN', 'AS', 'AT', 'BE', 'BY', 'DO', 'GO', 'HE', 'IF',
                   'IN', 'IS', 'IT', 'ME', 'MY', 'NO', 'OF', 'OK', 'ON', 'OR', 'SO', 'TO',
                   'UP', 'US', 'WE', 'THE', 'AND', 'FOR', 'ARE', 'BUT', 'NOT', 'YOU', 'ALL',
                   'CAN', 'HAD', 'HER', 'WAS', 'ONE', 'OUR', 'OUT', 'PDF', 'USD', 'EUR'}

    # Find all potential tickers (1-5 uppercase letters)
    potential_tickers = re.findall(r'\b[A-Z]{1,5}\b', text.upper())

    # Filter out common words
    tickers = [t for t in potential_tickers if t not in common_words]

    # Remove duplicates while preserving order
    seen = set()
    unique_tickers = []
    for t in tickers:
        if t not in seen:
            seen.add(t)
            unique_tickers.append(t)

    return unique_tickers

def read_excel_tickers(file):
    """Read tickers from Excel file"""
    try:
        df = pd.read_excel(file)
        # Try to find a column with tickers
        tickers = []
        for col in df.columns:
            col_values = df[col].dropna().astype(str).tolist()
            for val in col_values:
                extracted = extract_tickers_from_text(val)
                tickers.extend(extracted)
        return list(dict.fromkeys(tickers))  # Remove duplicates
    except Exception as e:
        st.error(f"Error reading Excel file: {e}")
        return []

def read_pdf_tickers(file):
    """Read tickers from PDF file"""
    if not PDF_SUPPORT:
        st.error("PDF support not available. Install pdfplumber: pip install pdfplumber")
        return []
    try:
        text = ""
        with pdfplumber.open(file) as pdf:
            for page in pdf.pages:
                text += page.extract_text() or ""
        return extract_tickers_from_text(text)
    except Exception as e:
        st.error(f"Error reading PDF file: {e}")
        return []

def read_word_tickers(file):
    """Read tickers from Word file"""
    if not DOCX_SUPPORT:
        st.error("Word support not available. Install python-docx: pip install python-docx")
        return []
    try:
        doc = Document(file)
        text = " ".join([para.text for para in doc.paragraphs])
        # Also check tables
        for table in doc.tables:
            for row in table.rows:
                for cell in row.cells:
                    text += " " + cell.text
        return extract_tickers_from_text(text)
    except Exception as e:
        st.error(f"Error reading Word file: {e}")
        return []

def create_chart(df, ticker):
    """Create an interactive chart with price, MA, and ATR"""
    fig = make_subplots(
        rows=2, cols=1,
        shared_xaxes=True,
        vertical_spacing=0.1,
        row_heights=[0.7, 0.3],
        subplot_titles=(f'{ticker} Price & 150-Day Moving Average', 'ATR (14-Day)')
    )

    # Candlestick chart
    fig.add_trace(
        go.Candlestick(
            x=df.index,
            open=df['Open'],
            high=df['High'],
            low=df['Low'],
            close=df['Close'],
            name='Price',
            increasing_line_color='#00ff88',
            decreasing_line_color='#ff4444'
        ),
        row=1, col=1
    )

    # 150-day Moving Average
    fig.add_trace(
        go.Scatter(
            x=df.index,
            y=df['MA150'],
            mode='lines',
            name='150-Day MA',
            line=dict(color='#ffa500', width=2)
        ),
        row=1, col=1
    )

    # ATR chart
    fig.add_trace(
        go.Scatter(
            x=df.index,
            y=df['ATR'],
            mode='lines',
            name='ATR (14)',
            fill='tozeroy',
            line=dict(color='#667eea', width=2),
            fillcolor='rgba(102, 126, 234, 0.3)'
        ),
        row=2, col=1
    )

    # Update layout
    fig.update_layout(
        height=700,
        template='plotly_dark',
        showlegend=True,
        legend=dict(
            orientation="h",
            yanchor="bottom",
            y=1.02,
            xanchor="right",
            x=1
        ),
        xaxis_rangeslider_visible=False,
        margin=dict(l=50, r=50, t=80, b=50)
    )

    fig.update_xaxes(showgrid=True, gridwidth=1, gridcolor='rgba(128,128,128,0.2)')
    fig.update_yaxes(showgrid=True, gridwidth=1, gridcolor='rgba(128,128,128,0.2)')

    return fig

def style_gap_column(val):
    """Style the gap column with colors"""
    if pd.isna(val):
        return ''
    elif val >= 0:
        return 'color: #00ff88; font-weight: bold'
    else:
        return 'color: #ff4444; font-weight: bold'

# Main app
st.title("📈 Stock Analyzer")
st.markdown("---")

# Create tabs for single stock and portfolio analysis
tab1, tab2 = st.tabs(["📊 Single Stock Analysis", "📁 Portfolio Upload"])

with tab1:
    # Input section
    col1, col2, col3 = st.columns([1, 2, 1])
    with col2:
        ticker = st.text_input(
            "Enter Stock Ticker Symbol",
            placeholder="e.g., AAPL, MSFT, GOOGL",
            help="Enter a valid stock ticker symbol",
            key="single_ticker"
        ).upper().strip()

    if ticker:
        with st.spinner(f"Fetching data for {ticker}..."):
            df, info = get_stock_data(ticker)

        if df is not None and not df.empty:
            # Get latest values
            current_price = df['Close'].iloc[-1]
            ma150 = df['MA150'].iloc[-1]
            atr = df['ATR'].iloc[-1]

            # Company name
            company_name = info.get('longName', ticker) if info else ticker
            st.markdown(f"### {company_name}")

            # Metric cards
            col1, col2, col3 = st.columns(3)

            with col1:
                price_change = ((current_price - df['Close'].iloc[-2]) / df['Close'].iloc[-2]) * 100
                change_icon = "🟢" if price_change >= 0 else "🔴"
                st.markdown(f"""
                <div class="metric-card">
                    <div class="metric-label">Current Price {change_icon}</div>
                    <div class="metric-value">${current_price:.2f}</div>
                    <div class="metric-label">{price_change:+.2f}% today</div>
                </div>
                """, unsafe_allow_html=True)

            with col2:
                ma_diff = ((current_price - ma150) / ma150) * 100 if pd.notna(ma150) else 0
                trend = "Above" if current_price > ma150 else "Below"
                st.markdown(f"""
                <div class="metric-card metric-card-green">
                    <div class="metric-label">150-Day Moving Average</div>
                    <div class="metric-value">${ma150:.2f}</div>
                    <div class="metric-label">{trend} MA by {abs(ma_diff):.1f}%</div>
                </div>
                """, unsafe_allow_html=True)

            with col3:
                atr_pct = (atr / current_price) * 100 if current_price > 0 else 0
                st.markdown(f"""
                <div class="metric-card metric-card-orange">
                    <div class="metric-label">ATR (14-Day)</div>
                    <div class="metric-value">${atr:.2f}</div>
                    <div class="metric-label">{atr_pct:.2f}% of price</div>
                </div>
                """, unsafe_allow_html=True)

            st.markdown("<br>", unsafe_allow_html=True)

            # Chart
            fig = create_chart(df, ticker)
            st.plotly_chart(fig, use_container_width=True)

            # Additional info
            with st.expander("📊 Key Statistics"):
                col1, col2, col3, col4 = st.columns(4)
                with col1:
                    st.metric("52-Week High", f"${info.get('fiftyTwoWeekHigh', 'N/A'):.2f}" if info and info.get('fiftyTwoWeekHigh') else "N/A")
                with col2:
                    st.metric("52-Week Low", f"${info.get('fiftyTwoWeekLow', 'N/A'):.2f}" if info and info.get('fiftyTwoWeekLow') else "N/A")
                with col3:
                    st.metric("Volume", f"{df['Volume'].iloc[-1]:,.0f}")
                with col4:
                    st.metric("Avg Volume", f"{info.get('averageVolume', 'N/A'):,.0f}" if info and info.get('averageVolume') else "N/A")
        else:
            st.error(f"❌ Could not find data for ticker '{ticker}'. Please check the symbol and try again.")
    else:
        st.info("👆 Enter a stock ticker symbol above to get started!")

        # Show example tickers
        st.markdown("### Popular Tickers")
        example_cols = st.columns(5)
        examples = ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA']
        for col, ex in zip(example_cols, examples):
            with col:
                st.code(ex)

with tab2:
    st.markdown("### 📁 Upload Your Portfolio")
    st.markdown("Upload a file containing your stock tickers (Excel, Word, or PDF)")

    uploaded_file = st.file_uploader(
        "Choose a file",
        type=['xlsx', 'xls', 'docx', 'pdf'],
        help="Supported formats: Excel (.xlsx, .xls), Word (.docx), PDF (.pdf)"
    )

    if uploaded_file is not None:
        file_type = uploaded_file.name.split('.')[-1].lower()

        # Extract tickers based on file type
        with st.spinner("Extracting tickers from file..."):
            if file_type in ['xlsx', 'xls']:
                tickers = read_excel_tickers(uploaded_file)
            elif file_type == 'docx':
                tickers = read_word_tickers(uploaded_file)
            elif file_type == 'pdf':
                tickers = read_pdf_tickers(uploaded_file)
            else:
                tickers = []
                st.error("Unsupported file format")

        if tickers:
            st.success(f"Found {len(tickers)} potential tickers: {', '.join(tickers)}")

            # Allow user to edit the ticker list
            edited_tickers = st.text_area(
                "Edit tickers (one per line or comma-separated)",
                value=", ".join(tickers),
                help="Remove any false positives or add missing tickers"
            )

            # Parse edited tickers
            if ',' in edited_tickers:
                final_tickers = [t.strip().upper() for t in edited_tickers.split(',') if t.strip()]
            else:
                final_tickers = [t.strip().upper() for t in edited_tickers.split('\n') if t.strip()]

            if st.button("🔍 Analyze Portfolio", type="primary"):
                if final_tickers:
                    st.markdown("### 📊 Portfolio Analysis")

                    # Progress bar
                    progress_bar = st.progress(0)
                    status_text = st.empty()

                    # Fetch data for all tickers
                    results = []
                    failed_tickers = []

                    for i, ticker in enumerate(final_tickers):
                        status_text.text(f"Fetching data for {ticker}...")
                        progress_bar.progress((i + 1) / len(final_tickers))

                        result = get_stock_summary(ticker)
                        if result:
                            results.append(result)
                        else:
                            failed_tickers.append(ticker)

                    status_text.empty()
                    progress_bar.empty()

                    if failed_tickers:
                        st.warning(f"⚠️ Could not fetch data for: {', '.join(failed_tickers)}")

                    if results:
                        # Create DataFrame
                        df_results = pd.DataFrame(results)

                        # Format the dataframe for display
                        df_display = df_results.copy()
                        df_display['Current Price'] = df_display['Current Price'].apply(lambda x: f"${x:.2f}" if pd.notna(x) else "N/A")
                        df_display['150-Day MA'] = df_display['150-Day MA'].apply(lambda x: f"${x:.2f}" if pd.notna(x) else "N/A")
                        df_display['ATR (14)'] = df_display['ATR (14)'].apply(lambda x: f"${x:.2f}" if pd.notna(x) else "N/A")

                        # Create a styled version for the Gap % column
                        def color_gap(val):
                            if val == "N/A":
                                return val
                            num = float(val.replace('%', '').replace('+', ''))
                            if num >= 0:
                                return f"🟢 +{abs(num):.2f}%"
                            else:
                                return f"🔴 {num:.2f}%"

                        df_display['Gap %'] = df_results['Gap %'].apply(
                            lambda x: color_gap(f"{x:.2f}%") if pd.notna(x) else "N/A"
                        )

                        # Display the table
                        st.dataframe(
                            df_display,
                            use_container_width=True,
                            hide_index=True,
                            column_config={
                                "Ticker": st.column_config.TextColumn("Ticker", width="small"),
                                "Current Price": st.column_config.TextColumn("Current Price", width="medium"),
                                "150-Day MA": st.column_config.TextColumn("150-Day MA", width="medium"),
                                "Gap %": st.column_config.TextColumn("Gap % (vs MA)", width="medium"),
                                "ATR (14)": st.column_config.TextColumn("ATR (14-Day)", width="medium"),
                            }
                        )

                        # Summary statistics
                        st.markdown("### 📈 Summary")
                        col1, col2, col3 = st.columns(3)

                        valid_gaps = df_results['Gap %'].dropna()

                        with col1:
                            above_ma = (valid_gaps > 0).sum()
                            st.metric("Stocks Above 150-MA", f"{above_ma} / {len(valid_gaps)}")

                        with col2:
                            below_ma = (valid_gaps < 0).sum()
                            st.metric("Stocks Below 150-MA", f"{below_ma} / {len(valid_gaps)}")

                        with col3:
                            avg_gap = valid_gaps.mean()
                            st.metric("Average Gap %", f"{avg_gap:+.2f}%")

                        # Download button for results
                        csv = df_results.to_csv(index=False)
                        st.download_button(
                            label="📥 Download Results as CSV",
                            data=csv,
                            file_name="portfolio_analysis.csv",
                            mime="text/csv"
                        )
                    else:
                        st.error("❌ Could not fetch data for any of the tickers.")
                else:
                    st.warning("Please enter at least one ticker symbol.")
        else:
            st.warning("No tickers found in the file. Please check the file content.")
    else:
        st.info("👆 Upload a file containing your stock tickers to analyze your portfolio.")

        st.markdown("#### Supported Formats:")
        st.markdown("""
        - **Excel (.xlsx, .xls)**: Tickers can be in any column
        - **Word (.docx)**: Tickers extracted from paragraphs and tables
        - **PDF (.pdf)**: Tickers extracted from text content
        """)

# Footer
st.markdown("---")
st.markdown(
    "<p style='text-align: center; color: #666;'>Data provided by Yahoo Finance | ATR = Average True Range (14-day)</p>",
    unsafe_allow_html=True
)
