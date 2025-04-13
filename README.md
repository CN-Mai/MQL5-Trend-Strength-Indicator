# MQL5 Trend Strength Meter with Confirmations

A comprehensive MetaTrader 5 Graphical User Interface (GUI) indicator designed to provide an at-a-glance assessment of market trend strength and direction, combining core indicators (RSI, ADX, +DI/-DI) with optional confirmation indicators (MA, MACD, Stochastic). Ideal for traders seeking confluence before making decisions.

## Features

*   **Intuitive GUI Panel:** Displays all information clearly in a draggable on-chart window.
*   **Core Trend Analysis:**
    *   Uses **RSI** for momentum assessment.
    *   Uses **ADX** to gauge trend strength (trending vs. ranging).
    *   Uses **+DI / -DI** to indicate directional pressure dominance.
    *   Calculates a combined **Trend Signal** (Strong Uptrend, Strong Downtrend, Trending/Chop, Ranging/Weak) with dynamic color feedback.
*   **Configurable Thresholds:** Easily adjust ADX and RSI levels via input parameters to suit your strategy.
*   **Change Indication:** Small arrows (↑ ↓ -) show the immediate change in RSI, ADX, and the main Trend Signal since the last update.
*   **Confirmation Indicators:** Optional secondary signals for confluence:
    *   **Moving Average (MA):** Price position relative to a configurable MA.
    *   **MACD:** Signal line crossover detection.
    *   **Stochastic Oscillator:** Crossover detection within configurable Overbought/Oversold levels.
    *   Each confirmation indicator can be enabled/disabled and fully configured via inputs.
*   **User-Friendly Interface:**
    *   **Draggable Panel:** Click and drag the panel background to position it anywhere.
    *   **Toggle Button:** Show or hide the panel with a single click.
    *   **Customizable Colors:** Configure colors for panel background, text, borders, and all trend/confirmation states.
    *   **Optional Dynamic Background:** Panel background can change color based on the main Trend Signal.
*   **Clean & Efficient Code:** Structured using direct MQL5 object functions for reliability, with unique object naming to prevent conflicts.

## Installation

1.  **Download:** Download the `TrendStrengthMeter.mq5` file.
2.  **Open MetaEditor:** In MetaTrader 5, go to `Tools` -> `MetaQuotes Language Editor` (or press `F4`).
3.  **Navigate:** In the MetaEditor's "Navigator" panel (usually on the left), find the `Indicators` folder under your `MQL5` directory (e.g., `MQL5\Indicators\`). You might want to create a subfolder like `MQL5\Indicators\Market\`.
4.  **Place File:** Copy the downloaded `.mq5` file into the desired `Indicators` (sub)folder. You can often just drag and drop the file from your download location into the MetaEditor's Navigator panel folder.
5.  **Compile:** Double-click the file in the Navigator panel to open it. Then, click the `Compile` button in the toolbar (looks like stacked papers, or press `F7`). Check the "Errors" tab at the bottom for any compilation errors (there should be none with the provided code).
6.  **Attach to Chart:** Go back to your MetaTrader 5 chart window. Find the indicator ("TrendStrengthMeter\_Enhanced") in the MT5 "Navigator" window under `Indicators -> Custom` (or the subfolder you used). Drag and drop it onto your chart.
7.  **Configure Inputs:** Adjust the input parameters as needed when prompted (see Configuration section below). Click `OK`.

## Usage

1.  **Main Trend Signal:** Observe the "Trend Signal" text and its color. This is the primary output based on ADX/RSI/DI confluence:
    *   `Strong Uptrend` (Green*): ADX >= Threshold, RSI > Upper, +DI > -DI.
    *   `Strong Downtrend` (Red*): ADX >= Threshold, RSI < Lower, -DI > +DI.
    *   `Trending/Chop` (Orange*): ADX >= Threshold, but RSI/DI signals are neutral or conflicting.
    *   `Ranging/Weak` (Gray*): ADX < Threshold.
    *   (*Default colors, configurable in inputs*)
2.  **Value & Change:** Check the current RSI, ADX, and +DI/-DI values. The arrows next to RSI, ADX, and Trend Signal indicate the change since the last `OnTimer` update.
3.  **Confirmations:** Look at the MA, MACD, and Stochastic signal rows (if enabled):
    *   `Buy` (Green*): Indicates a bullish signal from that indicator.
    *   `Sell` (Red*): Indicates a bearish signal from that indicator.
    *   `Neutral`, `Overbought`, `Oversold` (Gray*): Indicates a neutral state or condition without a crossover signal.
    *   `Wait...`: Indicator is calculating or waiting for sufficient data.
    *   `OFF`: The confirmation indicator is disabled in the inputs.
    *   `Error`: Issue creating the indicator handle (check MetaTrader 5 logs).
4.  **Confluence:** Look for agreement between the main Trend Signal and the confirmation indicators you trust. For example, a `Strong Uptrend` signal is more robust if confirmed by `Buy` signals from MA and MACD. Mixed signals suggest caution.
5.  **Interact:**
    *   Click and drag the panel background to move it.
    *   Click the "Hide"/"Show" button to toggle visibility.

## Configuration (Input Parameters)

The indicator's behavior can be tailored through its input parameters:

### Core Trend Settings

*   **`InpRsiPeriod`** (Default: `14`): The calculation period for the Relative Strength Index (RSI).
*   **`InpAdxPeriod`** (Default: `14`): The calculation period for the Average Directional Index (ADX) and Directional Movement (+DI/-DI).
*   **`InpAdxThreshold`** (Default: `25.0`): The ADX value above which the market is considered trending.
*   **`InpRsiUpper`** (Default: `55.0`): The RSI value above which bullish momentum is considered strong (used in trending markets).
*   **`InpRsiLower`** (Default: `45.0`): The RSI value below which bearish momentum is considered strong (used in trending markets).

### Confirmation: Moving Average

*   **`InpMA_Enable`** (Default: `true`): Enable or disable the Moving Average confirmation signal.
*   **`InpMA_Period`** (Default: `50`): The calculation period for the MA.
*   **`InpMA_Method`** (Default: `MODE_SMA`): The MA calculation method (SMA, EMA, SMMA, LWMA).
*   **`InpMA_Applied`** (Default: `PRICE_CLOSE`): The price data the MA is applied to.

### Confirmation: MACD

*   **`InpMACD_Enable`** (Default: `true`): Enable or disable the MACD confirmation signal.
*   **`InpMACD_Fast`** (Default: `12`): The period for the Fast Exponential Moving Average.
*   **`InpMACD_Slow`** (Default: `26`): The period for the Slow Exponential Moving Average.
*   **`InpMACD_Signal`** (Default: `9`): The period for the Signal Line Simple Moving Average.
*   **`InpMACD_Applied`** (Default: `PRICE_CLOSE`): The price data the MACD is applied to.

### Confirmation: Stochastic

*   **`InpStoch_Enable`** (Default: `true`): Enable or disable the Stochastic confirmation signal.
*   **`InpStoch_K`** (Default: `14`): The %K period.
*   **`InpStoch_D`** (Default: `3`): The %D (Signal Line) period.
*   **`InpStoch_Slowing`** (Default: `3`): The slowing period.
*   **`InpStoch_Method`** (Default: `MODE_SMA`): The MA method used for smoothing.
*   **`InpStoch_PriceField`** (Default: `STO_LOWHIGH`): The price field used (Low/High or Close/Close).
*   **`InpStoch_LevelUp`** (Default: `80.0`): The Overbought level threshold.
*   **`InpStoch_LevelDn`** (Default: `20.0`): The Oversold level threshold.

### Panel Display & Visuals

*   **`InpPanelX`** (Default: `10`): Initial horizontal position of the panel's anchor corner (pixels from chart edge).
*   **`InpPanelY`** (Default: `25`): Initial vertical position of the panel's anchor corner (pixels from chart edge).
*   **`InpPanelCorner`** (Default: `CORNER_LEFT_UPPER`): The chart corner the X/Y distances are measured from.
*   **`InpUpdateInterval`** (Default: `1`): How often the indicator values refresh, in seconds (minimum 1).
*   **`InpDynamicBG`** (Default: `false`): If `true`, the panel background changes color based on the main Trend Signal.
*   **`InpFontSizeVal`** (Default: `9`): Font size used for indicator values and statuses.
*   **`InpFontSizeLbl`** (Default: `8`): Font size used for labels (like "RSI:", "Strength:", etc.).

### Panel Colors

*   **`InpPanelColorBG`**: Background color of the panel.
*   **`InpColorText`**: Default text color for labels.
*   **`InpColorBorder`**: Border color of the panel.
*   **`InpColorStrongUp`**: Color for the "Strong Uptrend" signal text (and dynamic background, if enabled).
*   **`InpColorStrongDn`**: Color for the "Strong Downtrend" signal text (and dynamic background, if enabled).
*   **`InpColorChop`**: Color for the "Trending/Chop" signal text (and dynamic background, if enabled).
*   **`InpColorRanging`**: Color for the "Ranging/Weak" signal text (and dynamic background, if enabled).
*   **`InpColorConfirmBuy`**: Color for "Buy" status text in the confirmation section.
*   **`InpColorConfirmSell`**: Color for "Sell" status text in the confirmation section.
*   **`InpColorConfirmNeutral`**: Color for "Neutral", "Wait", "OFF", etc., status text in the confirmation section.

## How it Works (Briefly)

*   **Core Trend:** ADX determines if the market is trending (`>= InpAdxThreshold`). If trending, RSI levels (`> InpRsiUpper` or `< InpRsiLower`) combined with DI dominance (`+DI > -DI` or `-DI > +DI`) define the strong up/down direction. If ADX is low, it's considered ranging/weak. If ADX is high but RSI/DI are inconclusive, it's flagged as trending/chop.
*   **MA Confirmation:** Simple check if the applied price is above (Buy) or below (Sell) the calculated MA value.
*   **MACD Confirmation:** Checks if the MACD Main Line crossed the Signal Line on the *last completed bar*.
*   **Stochastic Confirmation:** Checks if the %K line crossed the %D line on the *last completed bar* while within the Overbought/Oversold zones defined by the input levels.

## License
MIT License

Copyright (c) [2025] [CN-MAI]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
