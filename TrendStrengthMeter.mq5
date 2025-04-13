//+------------------------------------------------------------------+
//|                   TrendStrengthMeter.mq5                         |
//|                      Copyright 2023, CN_MAI                      |
//|              Enhanced GUI with Confirmation Indicators           |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Your Name"
#property link      "https://yourfreelanceprofile.com" // Example Link
#property version   "1.20" // Version updated for enhancements
#property description "Enhanced Trend Strength Meter (RSI+ADX+DI) with MA, MACD, Stoch Confirmations"

#property indicator_chart_window // Draw in the main chart window
#property indicator_buffers 0    // No calculation buffers needed
#property indicator_plots   0    // No plot lines needed

// --- Constants ---
#define CN_ARROW_UP   "↑"
#define CN_ARROW_DOWN "↓"
#define CN_ARROW_NONE "-"
#define CN_STATUS_BUY "Buy"
#define CN_STATUS_SELL "Sell"
#define CN_STATUS_NEUTRAL "Neutral"
#define CN_STATUS_WAIT "Wait..."
#define CN_STATUS_ERROR "Error"
#define CN_STATUS_DISABLED "OFF"


//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
// --- Core Trend Settings (RSI + ADX/DI) ---
input group    "Core Trend Settings"
input int      InpRsiPeriod     = 14;        // RSI Period
input int      InpAdxPeriod     = 14;        // ADX/DI Period
input double   InpAdxThreshold  = 25.0;      // ADX Level for Trend >="
input double   InpRsiUpper      = 55.0;      // RSI Level for Uptrend >"
input double   InpRsiLower      = 45.0;      // RSI Level for Downtrend <"

// --- Confirmation: Moving Average ---
input group    "Confirmation: Moving Average"
input bool     InpMA_Enable     = true;     // Enable MA Confirmation
input int      InpMA_Period     = 50;       // MA Period
input ENUM_MA_METHOD InpMA_Method = MODE_SMA; // MA Method
input ENUM_APPLIED_PRICE InpMA_Applied= PRICE_CLOSE; // MA Applied Price

// --- Confirmation: MACD ---
input group    "Confirmation: MACD"
input bool     InpMACD_Enable   = true;     // Enable MACD Confirmation
input int      InpMACD_Fast     = 12;       // MACD Fast EMA Period
input int      InpMACD_Slow     = 26;       // MACD Slow EMA Period
input int      InpMACD_Signal   = 9;        // MACD Signal SMA Period
input ENUM_APPLIED_PRICE InpMACD_Applied= PRICE_CLOSE; // MACD Applied Price

// --- Confirmation: Stochastic ---
input group    "Confirmation: Stochastic"
input bool     InpStoch_Enable  = true;     // Enable Stochastic Confirmation
input int      InpStoch_K       = 14;        // Stochastic %K Period
input int      InpStoch_D       = 3;        // Stochastic %D Period
input int      InpStoch_Slowing = 3;        // Stochastic Slowing
input ENUM_MA_METHOD InpStoch_Method  = MODE_SMA;    // Stochastic MA Method
input ENUM_STO_PRICE InpStoch_PriceField = STO_LOWHIGH; // Stochastic Price Field
input double   InpStoch_LevelUp = 80.0;    // Stochastic Overbought Level >="
input double   InpStoch_LevelDn = 20.0;    // Stochastic Oversold Level <="

// --- Panel Display & Visuals ---
input group    "Panel Display & Visuals"
input int      InpPanelX        = 10;        // Initial Panel X Position
input int      InpPanelY        = 25;        // Initial Panel Y Position
input ENUM_BASE_CORNER InpPanelCorner = CORNER_LEFT_UPPER; // Panel Corner Anchor
input uint     InpUpdateInterval= 1;         // Update Interval (seconds, >= 1)
input bool     InpDynamicBG     = false;     // Change Panel BG with Main Trend?
input int      InpFontSizeVal   = 9;         // Font Size for Values
input int      InpFontSizeLbl   = 8;         // Font Size for Labels

// --- Panel Colors ---
input group    "Panel Colors"
input color    InpPanelColorBG  = clrGainsboro;   // Panel Background
input color    InpColorText     = clrBlack;       // Default Label Text Color
input color    InpColorBorder   = clrGray;        // Panel Border Color
input color    InpColorStrongUp = clrMediumSeaGreen; // Main: Strong Uptrend
input color    InpColorStrongDn = clrIndianRed;     // Main: Strong Downtrend
input color    InpColorChop     = clrDarkOrange;    // Main: Trending/Chop
input color    InpColorRanging  = clrDimGray;     // Main: Ranging/Weak
input color    InpColorConfirmBuy= clrLimeGreen;     // Confirmation: Buy Signal
input color    InpColorConfirmSell= clrRed;         // Confirmation: Sell Signal
input color    InpColorConfirmNeutral= clrGray;    // Confirmation: Neutral


//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
// --- Indicator Handles ---
int      rsiHandle      = INVALID_HANDLE;
int      adxHandle      = INVALID_HANDLE; // Provides Main, +DI, -DI
int      maHandle       = INVALID_HANDLE;
int      macdHandle     = INVALID_HANDLE; // Provides Main, Signal
int      stochHandle    = INVALID_HANDLE; // Provides Main (%K), Signal (%D)

// --- GUI Object Names (Unique prefix) ---
string   objPrefix;
string   panelObjName;
string   titleObjName;
string   rsiLabelObjName, rsiValueObjName, rsiChangeObjName;
string   adxLabelObjName, adxValueObjName, adxChangeObjName;
string   diLabelObjName, diValueObjName;
string   strLabelObjName, strValueObjName, strChangeObjName;
string   maLabelObjName, maValueObjName;
string   macdLabelObjName, macdValueObjName;
string   stochLabelObjName, stochValueObjName;
string   buttonObjName;

// --- GUI Properties & State ---
int      panelWidth       = 185; // Adjusted width for confirmations
int      panelHeight      = 245; // Adjusted height for confirmations
int      labelHeight      = 16;
int      valueWidth       = 55;
int      confirmValueWidth= 65; // Wider status text like "Neutral"
int      changeWidth      = 15;
int      padding          = 5;
bool     panelIsVisible   = true; // Panel visibility state
long     chartWindowID    = 0;
uint     effectiveUpdateInterval = 1; // Validated update speed

// --- State Variables ---
bool     panelIsDragging  = false;
int      panelDragStartX  = 0;
int      panelDragStartY  = 0;
int      panelCurrentX    = 0;
int      panelCurrentY    = 0;
double   prevRsiValue     = -1.0; // Store previous values for change indication
double   prevAdxValue     = -1.0;
string   prevStrengthText = "";


//+------------------------------------------------------------------+
//| Indicator Initialization                                         |
//+------------------------------------------------------------------+
int OnInit()
{
   chartWindowID = ChartID();

   // --- Input Validation ---
   if(InpRsiPeriod <= 1 || InpAdxPeriod <= 1 || InpMA_Period <= 1 || InpMACD_Fast <= 0 ||
      InpMACD_Slow <= InpMACD_Fast || InpMACD_Signal <= 0 || InpStoch_K <= 0 || InpStoch_D <= 0 || InpStoch_Slowing <= 0) {
      Print("Error: Invalid indicator period input(s). Check periods are positive and logical."); return(INIT_FAILED);
   }
   if(InpRsiUpper <= InpRsiLower) {
       Print("Error: RSI Upper threshold must be greater than RSI Lower threshold."); return(INIT_FAILED);
   }
    effectiveUpdateInterval = (InpUpdateInterval < 1) ? 1 : InpUpdateInterval; // Ensure >= 1 second
    if(InpUpdateInterval < 1) Print("Warning: Input 'Update Interval' < 1. Using 1 second.");


   // --- Generate Unique Object Name Prefix ---
   objPrefix = MQLInfoString(MQL_PROGRAM_NAME) + "_" + IntegerToString(chartWindowID) + "_";

   // --- Assign Object Names ---
   panelObjName      = objPrefix + "Panel";
   titleObjName      = objPrefix + "Title";
   rsiLabelObjName   = objPrefix + "RsiLabel"; rsiValueObjName = objPrefix + "RsiValue"; rsiChangeObjName = objPrefix + "RsiChange";
   adxLabelObjName   = objPrefix + "AdxLabel"; adxValueObjName = objPrefix + "AdxValue"; adxChangeObjName = objPrefix + "AdxChange";
   diLabelObjName    = objPrefix + "DiLabel";  diValueObjName  = objPrefix + "DiValue";
   strLabelObjName   = objPrefix + "StrLabel"; strValueObjName = objPrefix + "StrValue"; strChangeObjName = objPrefix + "StrChange";
   maLabelObjName    = objPrefix + "MaLabel";  maValueObjName  = objPrefix + "MaValue";
   macdLabelObjName  = objPrefix + "MacdLabel";macdValueObjName= objPrefix + "MacdValue";
   stochLabelObjName = objPrefix + "StochLabel";stochValueObjName= objPrefix + "StochValue";
   buttonObjName     = objPrefix + "Button";

   // --- Get Core Indicator Handles ---
   rsiHandle = iRSI(_Symbol, _Period, InpRsiPeriod, PRICE_CLOSE); // Note: RSI Applied Price isn't standard input
   if(rsiHandle == INVALID_HANDLE) { Print("Error creating RSI handle: ", _LastError); return(INIT_FAILED); }

   adxHandle = iADX(_Symbol, _Period, InpAdxPeriod);
   if(adxHandle == INVALID_HANDLE) { Print("Error creating ADX/DI handle: ", _LastError); IndicatorRelease(rsiHandle); return(INIT_FAILED); }

   // --- Get Confirmation Indicator Handles (if enabled) ---
   if(InpMA_Enable) {
      maHandle = iMA(_Symbol, _Period, InpMA_Period, 0, InpMA_Method, InpMA_Applied);
      if(maHandle == INVALID_HANDLE) { Print("Error creating MA handle: ", _LastError); /*Continue maybe?*/}
   }
   if(InpMACD_Enable) {
      macdHandle = iMACD(_Symbol, _Period, InpMACD_Fast, InpMACD_Slow, InpMACD_Signal, InpMACD_Applied);
      if(macdHandle == INVALID_HANDLE) { Print("Error creating MACD handle: ", _LastError); /*Continue maybe?*/ }
   }
   if(InpStoch_Enable) {
      stochHandle = iStochastic(_Symbol, _Period, InpStoch_K, InpStoch_D, InpStoch_Slowing, InpStoch_Method, InpStoch_PriceField);
      if(stochHandle == INVALID_HANDLE) { Print("Error creating Stochastic handle: ", _LastError); /*Continue maybe?*/ }
   }

   // --- Initialize Panel Position ---
   panelCurrentX = InpPanelX;
   panelCurrentY = InpPanelY;

   // --- Create GUI ---
   if(!CreateGUIPanel()) {
       Print("Failed to create GUI panel.");
       // Clean up any handles created so far
       if(rsiHandle!=INVALID_HANDLE) IndicatorRelease(rsiHandle);
       if(adxHandle!=INVALID_HANDLE) IndicatorRelease(adxHandle);
       if(maHandle!=INVALID_HANDLE) IndicatorRelease(maHandle);
       if(macdHandle!=INVALID_HANDLE) IndicatorRelease(macdHandle);
       if(stochHandle!=INVALID_HANDLE) IndicatorRelease(stochHandle);
       return(INIT_FAILED);
   }

   // --- Set Update Timer ---
   EventSetTimer(effectiveUpdateInterval);

   // --- Initial Data Update & Draw ---
   UpdateGUIContent();
   ChartRedraw(chartWindowID);

   Print(MQLInfoString(MQL_PROGRAM_NAME) + " initialized successfully.");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Indicator Deinitialization                                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print(MQLInfoString(MQL_PROGRAM_NAME) + " deinitializing, reason: ", reason);
   EventKillTimer();
   DeleteGUIPanel(); // Deletes all objects with the unique prefix

   // Release all indicator handles
   if(rsiHandle != INVALID_HANDLE) IndicatorRelease(rsiHandle);
   if(adxHandle != INVALID_HANDLE) IndicatorRelease(adxHandle);
   if(maHandle != INVALID_HANDLE) IndicatorRelease(maHandle);
   if(macdHandle != INVALID_HANDLE) IndicatorRelease(macdHandle);
   if(stochHandle != INVALID_HANDLE) IndicatorRelease(stochHandle);

   ChartRedraw(chartWindowID);
   Print(MQLInfoString(MQL_PROGRAM_NAME) + " deinitialization complete.");
}

//+------------------------------------------------------------------+
//| Timer Event Handler                                              |
//+------------------------------------------------------------------+
void OnTimer()
{
   // Don't update if panel is hidden or being dragged
   if(!panelIsVisible || panelIsDragging)
      return;

   // Update content; only redraw if something changed visually
   if(UpdateGUIContent()) {
       ChartRedraw(chartWindowID);
   }
}

//+------------------------------------------------------------------+
//| Chart Event Handler (Clicks, Drags)                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   // --- Button Click ---
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == buttonObjName) {
       TogglePanelVisibility();
       panelIsDragging = false; // Ensure dragging stops
       return;
   }

   // --- Panel Drag Start/Ongoing ---
   if(id == CHARTEVENT_OBJECT_DRAG && sparam == panelObjName) {
       if(!panelIsDragging) { // First event of a drag sequence
           panelIsDragging = true;
           // Calculate mouse offset from the panel's top-left corner
           panelDragStartX = (int)lparam - panelCurrentX;
           panelDragStartY = (int)dparam - panelCurrentY;
           // PrintFormat("Drag Start: Mouse(%d,%d) Panel(%d,%d) Offset(%d,%d)", lparam, dparam, panelCurrentX, panelCurrentY, panelDragStartX, panelDragStartY); // Debug
       }

       // Calculate new desired panel corner position based on current mouse position and starting offset
       int newPanelX = (int)lparam - panelDragStartX;
       int newPanelY = (int)dparam - panelDragStartY;

       // Optional: Add boundary checks to keep panel on screen
       long chartWidthPx=ChartGetInteger(chartWindowID, CHART_WIDTH_IN_PIXELS);
       long chartHeightPx=ChartGetInteger(chartWindowID, CHART_HEIGHT_IN_PIXELS);
       newPanelX = MathMax(0, MathMin(newPanelX, (int)chartWidthPx - panelWidth));   // Clamp X
       newPanelY = MathMax(0, MathMin(newPanelY, (int)chartHeightPx - panelHeight)); // Clamp Y

       // If the position actually changes, move the panel and its contents
       if(newPanelX != panelCurrentX || newPanelY != panelCurrentY) {
           MovePanel(newPanelX, newPanelY); // MovePanel updates panelCurrentX/Y internally
           ChartRedraw(chartWindowID);
       }
       return; // Event handled
   }

   // --- Panel Drag End (implied by CLICK event on the panel while dragging) ---
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == panelObjName) {
       if(panelIsDragging) {
          panelIsDragging = false;
          // Print("Drag End"); // Debug
          return; // Event handled
       }
   }

   // Note: A mouse button release *without* a final click on the object doesn't generate a specific chart event.
   // The 'panelIsDragging' flag handles this state.
}

//+------------------------------------------------------------------+
//| Create GUI Panel and Elements                                    |
//+------------------------------------------------------------------+
bool CreateGUIPanel()
{
   DeleteGUIPanel(); // Ensure clean slate

   // Create Background Panel (Selectable for Dragging)
   if(!ObjectCreate(chartWindowID, panelObjName, OBJ_RECTANGLE_LABEL, 0, 0, 0)) return(false);
   ObjectSetInteger(chartWindowID, panelObjName, OBJPROP_XDISTANCE, panelCurrentX);
   ObjectSetInteger(chartWindowID, panelObjName, OBJPROP_YDISTANCE, panelCurrentY);
   ObjectSetInteger(chartWindowID, panelObjName, OBJPROP_XSIZE, panelWidth);
   ObjectSetInteger(chartWindowID, panelObjName, OBJPROP_YSIZE, panelHeight);
   ObjectSetInteger(chartWindowID, panelObjName, OBJPROP_BGCOLOR, InpPanelColorBG);
   ObjectSetInteger(chartWindowID, panelObjName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(chartWindowID, panelObjName, OBJPROP_COLOR, InpColorBorder);
   ObjectSetInteger(chartWindowID, panelObjName, OBJPROP_CORNER, InpPanelCorner);
   ObjectSetInteger(chartWindowID, panelObjName, OBJPROP_BACK, true);
   ObjectSetInteger(chartWindowID, panelObjName, OBJPROP_SELECTABLE, true); // Enable dragging
   ObjectSetInteger(chartWindowID, panelObjName, OBJPROP_ZORDER, 0); // Base layer
   ObjectSetInteger(chartWindowID, panelObjName, OBJPROP_HIDDEN, !panelIsVisible);


   // --- Create Labels using Relative Positions ---
   int yPos = padding; // Y position relative to panel top
   int xLab = padding; // X position for labels
   int xVal = panelWidth - valueWidth - changeWidth - padding; // X for core values
   int xChg = panelWidth - changeWidth - padding + 2; // X for change arrows
   int xConfirmVal = panelWidth - confirmValueWidth - padding; // X for confirmation status


   CreateLabel(titleObjName, "Trend Meter v", xLab, yPos, panelWidth - 2 * padding, labelHeight, clrDimGray, InpFontSizeLbl+1, true, ALIGN_CENTER);
   yPos += labelHeight + padding + 2; // Extra spacing after title

   // --- RSI Row ---
   CreateLabel(rsiLabelObjName, "RSI (" + (string)InpRsiPeriod + "):", xLab, yPos, panelWidth - valueWidth - changeWidth - 2 * padding, labelHeight, InpColorText, InpFontSizeLbl, false, ALIGN_LEFT);
   CreateLabel(rsiValueObjName, CN_STATUS_WAIT, xVal, yPos, valueWidth, labelHeight, InpColorText, InpFontSizeVal, true, ALIGN_RIGHT);
   CreateLabel(rsiChangeObjName, CN_ARROW_NONE, xChg, yPos, changeWidth, labelHeight, InpColorText, InpFontSizeVal, true, ALIGN_CENTER);
   yPos += labelHeight + padding;

   // --- ADX Row ---
   CreateLabel(adxLabelObjName, "ADX (" + (string)InpAdxPeriod + "):", xLab, yPos, panelWidth - valueWidth - changeWidth - 2 * padding, labelHeight, InpColorText, InpFontSizeLbl, false, ALIGN_LEFT);
   CreateLabel(adxValueObjName, CN_STATUS_WAIT, xVal, yPos, valueWidth, labelHeight, InpColorText, InpFontSizeVal, true, ALIGN_RIGHT);
   CreateLabel(adxChangeObjName, CN_ARROW_NONE, xChg, yPos, changeWidth, labelHeight, InpColorText, InpFontSizeVal, true, ALIGN_CENTER);
   yPos += labelHeight + padding;

   // --- +/- DI Row ---
   CreateLabel(diLabelObjName, "+DI / -DI:", xLab, yPos, panelWidth - valueWidth - changeWidth - 2* padding, labelHeight, InpColorText, InpFontSizeLbl, false, ALIGN_LEFT);
   CreateLabel(diValueObjName, "--.--/--.--", xVal, yPos, valueWidth + changeWidth, labelHeight, InpColorText, InpFontSizeVal-1, true, ALIGN_RIGHT); // Uses full value+change width space
   yPos += labelHeight + padding;

   // --- Core Strength Row ---
   CreateLabel(strLabelObjName, "Trend Signal:", xLab, yPos, panelWidth - valueWidth - changeWidth - 2*padding, labelHeight, InpColorText, InpFontSizeLbl, false, ALIGN_LEFT);
   // Value spans most of the width, below the label
   CreateLabel(strValueObjName, "Calculating...", xLab, yPos + labelHeight -2 , panelWidth - 2*padding - changeWidth, labelHeight, clrGray, InpFontSizeVal +1, true, ALIGN_CENTER);
   CreateLabel(strChangeObjName, CN_ARROW_NONE, xChg, yPos + labelHeight -2, changeWidth, labelHeight, InpColorText, InpFontSizeVal, true, ALIGN_CENTER);
   yPos += (labelHeight*2) + padding + 2; // Spacing after strength


    // --- Confirmation Separator (Optional Visual) ---
    CreateLabel(objPrefix+"Separator", "--- Confirmations ---", xLab, yPos, panelWidth - 2 * padding, labelHeight, clrGray, InpFontSizeLbl-1, false, ALIGN_CENTER);
    yPos += labelHeight; // Less padding after separator


   // --- MA Confirmation Row ---
   CreateLabel(maLabelObjName, "MA ("+ (string)InpMA_Period +") Signal:", xLab, yPos, panelWidth - confirmValueWidth - padding*2, labelHeight, InpColorText, InpFontSizeLbl, false, ALIGN_LEFT);
   CreateLabel(maValueObjName, InpMA_Enable ? CN_STATUS_WAIT : CN_STATUS_DISABLED, xConfirmVal, yPos, confirmValueWidth, labelHeight, InpColorConfirmNeutral, InpFontSizeVal, true, ALIGN_RIGHT);
   yPos += labelHeight + padding;

   // --- MACD Confirmation Row ---
   CreateLabel(macdLabelObjName, "MACD Signal:", xLab, yPos, panelWidth - confirmValueWidth - padding*2, labelHeight, InpColorText, InpFontSizeLbl, false, ALIGN_LEFT);
   CreateLabel(macdValueObjName, InpMACD_Enable ? CN_STATUS_WAIT : CN_STATUS_DISABLED, xConfirmVal, yPos, confirmValueWidth, labelHeight, InpColorConfirmNeutral, InpFontSizeVal, true, ALIGN_RIGHT);
   yPos += labelHeight + padding;

   // --- Stochastic Confirmation Row ---
   CreateLabel(stochLabelObjName, "Stoch Signal:", xLab, yPos, panelWidth - confirmValueWidth - padding*2, labelHeight, InpColorText, InpFontSizeLbl, false, ALIGN_LEFT);
   CreateLabel(stochValueObjName, InpStoch_Enable ? CN_STATUS_WAIT : CN_STATUS_DISABLED, xConfirmVal, yPos, confirmValueWidth, labelHeight, InpColorConfirmNeutral, InpFontSizeVal, true, ALIGN_RIGHT);
   yPos += labelHeight + padding + 5; // Extra spacing before button

   // --- Toggle Button ---
   int btnWidth = 60;
   int btnHeight = 20;
   int btnRelX = (panelWidth - btnWidth) / 2; // Center button relative to panel
   ObjectCreate(chartWindowID, buttonObjName, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(chartWindowID, buttonObjName, OBJPROP_XDISTANCE, panelCurrentX + btnRelX); // Absolute X
   ObjectSetInteger(chartWindowID, buttonObjName, OBJPROP_YDISTANCE, panelCurrentY + yPos);    // Absolute Y
   ObjectSetInteger(chartWindowID, buttonObjName, OBJPROP_XSIZE, btnWidth);
   ObjectSetInteger(chartWindowID, buttonObjName, OBJPROP_YSIZE, btnHeight);
   ObjectSetInteger(chartWindowID, buttonObjName, OBJPROP_CORNER, InpPanelCorner);
   ObjectSetInteger(chartWindowID, buttonObjName, OBJPROP_BGCOLOR, clrGray);
   ObjectSetInteger(chartWindowID, buttonObjName, OBJPROP_COLOR, clrWhite);
   ObjectSetString(chartWindowID, buttonObjName, OBJPROP_TEXT, panelIsVisible ? "Hide" : "Show");
   ObjectSetInteger(chartWindowID, buttonObjName, OBJPROP_STATE, false);
   ObjectSetInteger(chartWindowID, buttonObjName, OBJPROP_SELECTABLE, true); // Clickable
   ObjectSetInteger(chartWindowID, buttonObjName, OBJPROP_ZORDER, 1);     // Above background
   ObjectSetInteger(chartWindowID, buttonObjName, OBJPROP_HIDDEN, !panelIsVisible);

    return true; // Successfully created basic elements
}

//+------------------------------------------------------------------+
//| Helper: Create a Text Label at Absolute Position                 |
//+------------------------------------------------------------------+
void CreateLabel(const string objName, const string text, int relX, int relY, int objWidth, int objHeight, color textColor, int fontSize = 8, bool isBold = false, ENUM_ALIGN_MODE alignment = ALIGN_LEFT)
{
   ObjectCreate(chartWindowID, objName, OBJ_LABEL, 0, 0, 0);
   ObjectSetString(chartWindowID, objName, OBJPROP_TEXT, text);
   ObjectSetInteger(chartWindowID, objName, OBJPROP_XDISTANCE, panelCurrentX + relX); // Use panelCurrentX/Y
   ObjectSetInteger(chartWindowID, objName, OBJPROP_YDISTANCE, panelCurrentY + relY); // Use panelCurrentX/Y
   ObjectSetInteger(chartWindowID, objName, OBJPROP_COLOR, textColor);
   ObjectSetString(chartWindowID, objName, OBJPROP_FONT, "Calibri"); // Consider alternatives like "Segoe UI" if available
   ObjectSetInteger(chartWindowID, objName, OBJPROP_FONTSIZE, fontSize);
   // MQL5 font weight flags are less reliable for OBJ_LABEL; choose bold fonts if needed.
   ObjectSetInteger(chartWindowID, objName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER); // Reference point for distances
   ObjectSetInteger(chartWindowID, objName, OBJPROP_ALIGN, alignment);         // Text alignment within its theoretical box
   ObjectSetInteger(chartWindowID, objName, OBJPROP_CORNER, InpPanelCorner); // Corner of chart for panel placement
   ObjectSetInteger(chartWindowID, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chartWindowID, objName, OBJPROP_ZORDER, 1);           // Above panel background
   ObjectSetInteger(chartWindowID, objName, OBJPROP_HIDDEN, !panelIsVisible); // Initial visibility
}


//+------------------------------------------------------------------+
//| Delete All GUI Objects for this Indicator Instance               |
//+------------------------------------------------------------------+
void DeleteGUIPanel()
{
    int deletedCount = ObjectsDeleteAll(chartWindowID, objPrefix);
    panelIsDragging = false; // Reset state
    // PrintFormat("Deleted %d objects with prefix '%s'", deletedCount, objPrefix); // Debug
}

//+------------------------------------------------------------------+
//| Move Panel and All Child Elements                                |
//+------------------------------------------------------------------+
void MovePanel(int newX, int newY)
{
    // Update the global position state *first*
    panelCurrentX = newX;
    panelCurrentY = newY;

    // Move the main panel background object
    ObjectSetInteger(chartWindowID, panelObjName, OBJPROP_XDISTANCE, panelCurrentX);
    ObjectSetInteger(chartWindowID, panelObjName, OBJPROP_YDISTANCE, panelCurrentY);

    // --- Calculate Relative Positions (consistent with CreateGUIPanel) ---
    int yPos = padding;
    int xLab = padding;
    int xVal = panelWidth - valueWidth - changeWidth - padding;
    int xChg = panelWidth - changeWidth - padding + 2;
    int xConfirmVal = panelWidth - confirmValueWidth - padding;

    // --- Update Absolute Positions for ALL Labels & Button ---
    // Title
    ObjectMove(chartWindowID, titleObjName, 0, panelCurrentX + xLab, panelCurrentY + yPos);
    yPos += labelHeight + padding + 2;
    // RSI
    ObjectMove(chartWindowID, rsiLabelObjName, 0, panelCurrentX + xLab, panelCurrentY + yPos);
    ObjectMove(chartWindowID, rsiValueObjName, 0, panelCurrentX + xVal, panelCurrentY + yPos);
    ObjectMove(chartWindowID, rsiChangeObjName,0, panelCurrentX + xChg, panelCurrentY + yPos);
    yPos += labelHeight + padding;
    // ADX
    ObjectMove(chartWindowID, adxLabelObjName, 0, panelCurrentX + xLab, panelCurrentY + yPos);
    ObjectMove(chartWindowID, adxValueObjName, 0, panelCurrentX + xVal, panelCurrentY + yPos);
    ObjectMove(chartWindowID, adxChangeObjName,0, panelCurrentX + xChg, panelCurrentY + yPos);
    yPos += labelHeight + padding;
    // DI
    ObjectMove(chartWindowID, diLabelObjName,  0, panelCurrentX + xLab, panelCurrentY + yPos);
    ObjectMove(chartWindowID, diValueObjName,  0, panelCurrentX + xVal, panelCurrentY + yPos); // Uses combined width
    yPos += labelHeight + padding;
    // Strength
    ObjectMove(chartWindowID, strLabelObjName, 0, panelCurrentX + xLab, panelCurrentY + yPos);
    ObjectMove(chartWindowID, strValueObjName, 0, panelCurrentX + xLab, panelCurrentY + yPos + labelHeight - 2);
    ObjectMove(chartWindowID, strChangeObjName,0, panelCurrentX + xChg, panelCurrentY + yPos + labelHeight - 2);
    yPos += (labelHeight*2) + padding + 2;
    // Separator
    ObjectMove(chartWindowID, objPrefix+"Separator", 0, panelCurrentX + xLab, panelCurrentY + yPos);
    yPos += labelHeight;
    // MA
    ObjectMove(chartWindowID, maLabelObjName, 0, panelCurrentX + xLab, panelCurrentY + yPos);
    ObjectMove(chartWindowID, maValueObjName, 0, panelCurrentX + xConfirmVal, panelCurrentY + yPos);
    yPos += labelHeight + padding;
    // MACD
    ObjectMove(chartWindowID, macdLabelObjName, 0, panelCurrentX + xLab, panelCurrentY + yPos);
    ObjectMove(chartWindowID, macdValueObjName, 0, panelCurrentX + xConfirmVal, panelCurrentY + yPos);
    yPos += labelHeight + padding;
    // Stochastic
    ObjectMove(chartWindowID, stochLabelObjName, 0, panelCurrentX + xLab, panelCurrentY + yPos);
    ObjectMove(chartWindowID, stochValueObjName, 0, panelCurrentX + xConfirmVal, panelCurrentY + yPos);
    yPos += labelHeight + padding + 5;
    // Button
    int btnWidth = 60;
    int btnRelX = (panelWidth - btnWidth) / 2;
    ObjectMove(chartWindowID, buttonObjName, 0, panelCurrentX + btnRelX, panelCurrentY + yPos);
}


//+------------------------------------------------------------------+
//| Update Indicator Values and GUI Content                          |
//| Returns: true if GUI elements were changed, false otherwise.    |
//+------------------------------------------------------------------+
bool UpdateGUIContent()
{
   bool visualChangesMade = false; // Track if redraw is needed

   // --- Buffers for Indicator Data ---
   double rsiBuffer[], adxBuffer[], pdiBuffer[], ndiBuffer[];         // Core
   double maBuffer[];                                                  // MA
   double macdMainBuffer[], macdSignalBuffer[];                        // MACD
   double stochKBuffer[], stochDBuffer[];                            // Stochastic
   double priceBuffer[];                                               // For MA applied price comparison

   // --- Data Retrieval - Get data for the last *completed* bar (index 1) ---
   // Request 2 or 3 bars to ensure data for index 1 is valid
   int barsToCopy = 3; // Need bar 1 and 2 for some signal confirmations
   int rsiCopied = CopyBuffer(rsiHandle, 0, 1, barsToCopy, rsiBuffer);
   int adxCopied = CopyBuffer(adxHandle, 0, 1, barsToCopy, adxBuffer); // ADX Main Line
   int pdiCopied = CopyBuffer(adxHandle, 1, 1, barsToCopy, pdiBuffer); // +DI Line
   int ndiCopied = CopyBuffer(adxHandle, 2, 1, barsToCopy, ndiBuffer); // -DI Line

   // Copy confirmation data only if enabled and handle is valid
   int priceCopied=0, maCopied=0, macdMainCopied=0, macdSignalCopied=0, stochKCopied=0, stochDCopied=0;

   if(InpMA_Enable && maHandle != INVALID_HANDLE) {
       // Need price corresponding to MA applied price
       if(!CopyPrice(_Symbol, _Period, InpMA_Applied, 1, barsToCopy, priceBuffer)) {
            priceCopied = 0; // Failed to get price data
       } else {
           priceCopied = ArraySize(priceBuffer);
       }
       maCopied = CopyBuffer(maHandle, 0, 1, barsToCopy, maBuffer);
   }
    if(InpMACD_Enable && macdHandle != INVALID_HANDLE) {
        macdMainCopied   = CopyBuffer(macdHandle, 0, 1, barsToCopy, macdMainBuffer);   // MACD Main Line
        macdSignalCopied = CopyBuffer(macdHandle, 1, 1, barsToCopy, macdSignalBuffer); // MACD Signal Line
    }
    if(InpStoch_Enable && stochHandle != INVALID_HANDLE) {
        stochKCopied = CopyBuffer(stochHandle, 0, 1, barsToCopy, stochKBuffer);  // Stochastic %K (Main)
        stochDCopied = CopyBuffer(stochHandle, 1, 1, barsToCopy, stochDBuffer); // Stochastic %D (Signal)
    }

   // --- Default Values for GUI ---
   string rsiText = CN_STATUS_WAIT; string rsiChangeText = CN_ARROW_NONE;
   string adxText = CN_STATUS_WAIT; string adxChangeText = CN_ARROW_NONE;
   string diText = "--.--/--.--";
   string trendStrengthText = "Calculating..."; string trendChangeText = CN_ARROW_NONE;
   color trendStrengthColor = InpColorRanging;
   color panelBgColor = InpPanelColorBG; // Use default unless dynamic BG is on
   string maStatusText = CN_STATUS_DISABLED; color maStatusColor = InpColorConfirmNeutral;
   string macdStatusText = CN_STATUS_DISABLED; color macdStatusColor = InpColorConfirmNeutral;
   string stochStatusText = CN_STATUS_DISABLED; color stochStatusColor = InpColorConfirmNeutral;

   // --- Calculate Core Trend Strength ---
   // Check if core data is available (focus on the required bar, index 0 of buffer = bar 1)
   if(rsiCopied > 0 && adxCopied > 0 && pdiCopied > 0 && ndiCopied > 0)
   {
      double rsiCurrentValue = rsiBuffer[0];
      double adxCurrentValue = adxBuffer[0];
      double pdiCurrentValue = pdiBuffer[0];
      double ndiCurrentValue = ndiBuffer[0];

      rsiText = StringFormat("%.2f", rsiCurrentValue);
      adxText = StringFormat("%.2f", adxCurrentValue);
      diText  = StringFormat("%.1f", pdiCurrentValue) + "/" + StringFormat("%.1f", ndiCurrentValue); // Display DI slightly differently

      // --- Calculate Change Direction Arrows ---
      if(prevRsiValue >= 0) { // Check if previous value exists and is valid
         if(rsiCurrentValue > prevRsiValue + 0.001) rsiChangeText = CN_ARROW_UP;
         else if(rsiCurrentValue < prevRsiValue - 0.001) rsiChangeText = CN_ARROW_DOWN;
         else rsiChangeText = CN_ARROW_NONE;
      }
      if(prevAdxValue >= 0) {
         if(adxCurrentValue > prevAdxValue + 0.001) adxChangeText = CN_ARROW_UP;
         else if(adxCurrentValue < prevAdxValue - 0.001) adxChangeText = CN_ARROW_DOWN;
         else adxChangeText = CN_ARROW_NONE;
      }

      // --- Determine Core Trend Strength ---
      if(adxCurrentValue >= InpAdxThreshold) // Trending market?
      {
         if(rsiCurrentValue > InpRsiUpper && pdiCurrentValue > ndiCurrentValue) { // RSI confirms Uptrend, +DI dominant
            trendStrengthText = "Strong Uptrend";
            trendStrengthColor = InpColorStrongUp;
         } else if(rsiCurrentValue < InpRsiLower && ndiCurrentValue > pdiCurrentValue) { // RSI confirms Downtrend, -DI dominant
            trendStrengthText = "Strong Downtrend";
            trendStrengthColor = InpColorStrongDn;
         } else { // ADX high, but RSI neutral or DI crossing - indicates potential chop
            trendStrengthText = "Trending/Chop";
            trendStrengthColor = InpColorChop;
         }
      } else { // ADX below threshold - Ranging or Weak Trend
         trendStrengthText = "Ranging/Weak";
         trendStrengthColor = InpColorRanging;
      }

      // Determine strength change (basic - did the text change?)
      if(prevStrengthText != "" && prevStrengthText != "Calculating..." && prevStrengthText != "Waiting Data...") {
           if(trendStrengthText != prevStrengthText) {
              trendChangeText = "?"; // Indication of change, direction more complex
           } else {
              trendChangeText = CN_ARROW_NONE;
           }
       } else {
          trendChangeText = CN_ARROW_NONE; // No previous state to compare
       }


      // --- Store current values for next comparison ---
      prevRsiValue = rsiCurrentValue;
      prevAdxValue = adxCurrentValue;
      prevStrengthText = trendStrengthText; // Store the calculated strength text

   } else { // Core data unavailable
      trendStrengthText = "Waiting Data...";
      trendStrengthColor = clrGray;
      prevRsiValue = -1.0; // Reset history
      prevAdxValue = -1.0;
      prevStrengthText = "";
   }

    // --- Dynamic Background Color (Optional) ---
    if(InpDynamicBG) {
       // Use the calculated trend color, but maybe lighten it slightly for background?
       panelBgColor = trendStrengthColor;
       // Example: panelBgColor = ColorToARGB(trendStrengthColor, 200); // Make slightly transparent
    }


   // --- Calculate Confirmation Signals (only if enabled and data available) ---

   // -- MA Confirmation --
   if(InpMA_Enable) {
        if(maHandle != INVALID_HANDLE && maCopied > 0 && priceCopied > 0) {
            double priceCurrent = priceBuffer[0]; // Price for bar 1
            double maCurrent    = maBuffer[0];    // MA value for bar 1

            if(priceCurrent > maCurrent) {
                maStatusText = CN_STATUS_BUY; maStatusColor = InpColorConfirmBuy;
            } else if(priceCurrent < maCurrent) {
                maStatusText = CN_STATUS_SELL; maStatusColor = InpColorConfirmSell;
            } else {
                maStatusText = CN_STATUS_NEUTRAL; maStatusColor = InpColorConfirmNeutral;
            }
        } else { maStatusText = (maHandle==INVALID_HANDLE)? CN_STATUS_ERROR : CN_STATUS_WAIT; maStatusColor = clrOrange; } // Wait or Error
   } // else remains "OFF"

   // -- MACD Confirmation --
   if(InpMACD_Enable) {
        // Need current (0) and previous (1) bar's data for crossover check
        if(macdHandle != INVALID_HANDLE && macdMainCopied > 1 && macdSignalCopied > 1) {
            double macdMainCurr = macdMainBuffer[0]; double macdMainPrev = macdMainBuffer[1];
            double macdSigCurr  = macdSignalBuffer[0]; double macdSigPrev  = macdSignalBuffer[1];

            // Check for bullish crossover: Main crosses Signal from below
            if(macdMainPrev < macdSigPrev && macdMainCurr > macdSigCurr) {
                macdStatusText = CN_STATUS_BUY; macdStatusColor = InpColorConfirmBuy;
            }
            // Check for bearish crossover: Main crosses Signal from above
            else if(macdMainPrev > macdSigPrev && macdMainCurr < macdSigCurr) {
                macdStatusText = CN_STATUS_SELL; macdStatusColor = InpColorConfirmSell;
            }
            // No crossover, check position relative to zero line (optional context)
            // else if (macdMainCurr > 0 && macdSigCurr > 0) { ... }
            else {
                 macdStatusText = CN_STATUS_NEUTRAL; macdStatusColor = InpColorConfirmNeutral; // No cross this bar
            }
        } else { macdStatusText = (macdHandle==INVALID_HANDLE)? CN_STATUS_ERROR : CN_STATUS_WAIT; macdStatusColor = clrOrange; } // Wait or Error
   } // else remains "OFF"

   // -- Stochastic Confirmation --
   if(InpStoch_Enable) {
        // Need current (0) and previous (1) bar's data for crossover check
       if(stochHandle != INVALID_HANDLE && stochKCopied > 1 && stochDCopied > 1) {
           double kCurr = stochKBuffer[0]; double kPrev = stochKBuffer[1];
           double dCurr = stochDBuffer[0]; double dPrev = stochDBuffer[1];

            // Bullish signal: %K crosses %D from below, within the oversold zone
            if(kPrev < dPrev && kCurr > dCurr && kCurr <= InpStoch_LevelDn) { // Simplified: k just needs to be below level
                stochStatusText = CN_STATUS_BUY; stochStatusColor = InpColorConfirmBuy;
            }
            // Bearish signal: %K crosses %D from above, within the overbought zone
            else if(kPrev > dPrev && kCurr < dCurr && kCurr >= InpStoch_LevelUp) { // Simplified: k just needs to be above level
                 stochStatusText = CN_STATUS_SELL; stochStatusColor = InpColorConfirmSell;
            }
            // Check zones without crossover
            else if(kCurr < InpStoch_LevelDn && dCurr < InpStoch_LevelDn){
                 stochStatusText = "Oversold"; stochStatusColor = InpColorConfirmNeutral;
            }
             else if(kCurr > InpStoch_LevelUp && dCurr > InpStoch_LevelUp){
                 stochStatusText = "Overbought"; stochStatusColor = InpColorConfirmNeutral;
            }
            else {
                stochStatusText = CN_STATUS_NEUTRAL; stochStatusColor = InpColorConfirmNeutral; // In middle or no valid signal
            }
       } else { stochStatusText = (stochHandle==INVALID_HANDLE)? CN_STATUS_ERROR : CN_STATUS_WAIT; stochStatusColor = clrOrange; } // Wait or Error
   } // else remains "OFF"


   // --- Update GUI Object Properties (Only if Value/Color Changed) ---
   visualChangesMade |= UpdateLabelText(rsiValueObjName, rsiText);
   visualChangesMade |= UpdateLabelText(rsiChangeObjName, rsiChangeText);
   visualChangesMade |= UpdateLabelText(adxValueObjName, adxText);
   visualChangesMade |= UpdateLabelText(adxChangeObjName, adxChangeText);
   visualChangesMade |= UpdateLabelText(diValueObjName, diText);
   visualChangesMade |= UpdateLabelText(strValueObjName, trendStrengthText);
   visualChangesMade |= UpdateLabelColor(strValueObjName, trendStrengthColor);
   visualChangesMade |= UpdateLabelText(strChangeObjName, trendChangeText);
   visualChangesMade |= UpdateLabelColor(panelObjName, panelBgColor, OBJPROP_BGCOLOR); // Update BG Color

   // Update confirmation labels
   visualChangesMade |= UpdateLabelText(maValueObjName, maStatusText);
   visualChangesMade |= UpdateLabelColor(maValueObjName, maStatusColor);
   visualChangesMade |= UpdateLabelText(macdValueObjName, macdStatusText);
   visualChangesMade |= UpdateLabelColor(macdValueObjName, macdStatusColor);
   visualChangesMade |= UpdateLabelText(stochValueObjName, stochStatusText);
   visualChangesMade |= UpdateLabelColor(stochValueObjName, stochStatusColor);

   return visualChangesMade; // Indicate if a redraw is needed
}


//+------------------------------------------------------------------+
//| Helper: Update Label Text Only if Changed                       |
//+------------------------------------------------------------------+
bool UpdateLabelText(const string objName, const string newText)
{
    if(ObjectGetString(chartWindowID, objName, OBJPROP_TEXT) != newText) {
        ObjectSetString(chartWindowID, objName, OBJPROP_TEXT, newText);
        return true; // Changed
    }
    return false; // Not changed
}

//+------------------------------------------------------------------+
//| Helper: Update Object Color Only if Changed                      |
//| Default property is OBJPROP_COLOR (text color)                   |
//+------------------------------------------------------------------+
bool UpdateLabelColor(const string objName, const color newColor, const ENUM_OBJECT_PROPERTY_INTEGER prop=OBJPROP_COLOR)
{
    if(ObjectGetInteger(chartWindowID, objName, prop) != newColor) {
        ObjectSetInteger(chartWindowID, objName, prop, newColor);
        return true; // Changed
    }
    return false; // Not changed
}

//+------------------------------------------------------------------+
//| Toggle Panel Visibility                                          |
//+------------------------------------------------------------------+
void TogglePanelVisibility()
{
   panelIsVisible = !panelIsVisible; // Flip state
   bool shouldHide = !panelIsVisible;

   // Iterate through ALL objects created by this indicator and hide/show them
   int totalObjects = ObjectsTotal(chartWindowID);
   for(int i = totalObjects - 1; i >= 0; i--) // Loop backwards safely
   {
       string currentObjName = ObjectName(chartWindowID, i);
       if(StringFind(currentObjName, objPrefix) == 0) // Belongs to this instance?
       {
          ObjectSetInteger(chartWindowID, currentObjName, OBJPROP_HIDDEN, shouldHide);
       }
   }

   // Update button text explicitly (ensure it wasn't missed)
   if(ObjectFind(chartWindowID, buttonObjName) >= 0) {
       ObjectSetString(chartWindowID, buttonObjName, OBJPROP_TEXT, panelIsVisible ? "Hide" : "Show");
   }

   // Force update content immediately when showing panel
   if(panelIsVisible) {
        if(UpdateGUIContent()) { // Update and check if visuals changed
            ChartRedraw(chartWindowID); // Redraw only if needed after update
            return; // Already redrawn
        }
   }

   ChartRedraw(chartWindowID); // Redraw to reflect visibility changes
}


//+------------------------------------------------------------------+
//| Core Indicator Calculation Function (Minimal)                    |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[],
                const double &open[], const double &high[], const double &low[], const double &close[],
                const long &tick_volume[], const long &volume[], const int &spread[])
{
   // Main logic driven by OnTimer for GUI updates.
   // This function keeps the indicator alive and handles basic context.
   return(rates_total);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Helper function to get price data safely                         |
//+------------------------------------------------------------------+
bool CopyPrice(const string symbol, const ENUM_TIMEFRAMES timeframe, const ENUM_APPLIED_PRICE applied_price,
              const int start_pos, const int count, double &price_data[])
{
   if(count <= 0) return false; // Nothing to copy

   // We always need the MqlRates structure
   MqlRates rates[];

   // Copy the required bar data structures
   int copied_count = CopyRates(symbol, timeframe, start_pos, count, rates);

   // Check if we got enough data
   if(copied_count < count) // Or <=0 depending on strictness needed
   {
      // PrintFormat("CopyPrice Error: Could not copy %d rates for %s %s. Copied only %d.", count, symbol, EnumToString(timeframe), copied_count); // Debug
      return false;
   }

   // Ensure the output array has the correct size
   if(ArraySize(price_data) != copied_count) {
        ArrayResize(price_data, copied_count);
   }

   // Extract the required price based on applied_price
   for(int i = 0; i < copied_count; i++)
   {
      switch(applied_price)
      {
         case PRICE_CLOSE:
            price_data[i] = rates[i].close;
            break;
         case PRICE_OPEN:
            price_data[i] = rates[i].open;
            break;
         case PRICE_HIGH:
            price_data[i] = rates[i].high;
            break;
         case PRICE_LOW:
            price_data[i] = rates[i].low;
            break;
         case PRICE_MEDIAN:    // (H+L)/2
            price_data[i] = (rates[i].high + rates[i].low) / 2.0;
            break;
         case PRICE_TYPICAL:   // (H+L+C)/3
            price_data[i] = (rates[i].high + rates[i].low + rates[i].close) / 3.0;
            break;
         case PRICE_WEIGHTED:  // (H+L+C+C)/4
            price_data[i] = (rates[i].high + rates[i].low + rates[i].close + rates[i].close) / 4.0;
            break;
         default:
             // Should not happen if input ENUM_APPLIED_PRICE is used correctly
             PrintFormat("CopyPrice Error: Unsupported applied_price %s", EnumToString(applied_price));
             return false; // Indicate failure for unsupported type
      }
   }

   // Data is typically needed as a series (latest value at index 0)
   ArraySetAsSeries(price_data, true);

   return true; // Successfully copied and processed
}
//+------------------------------------------------------------------+
