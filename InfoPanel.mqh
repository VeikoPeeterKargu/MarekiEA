//+------------------------------------------------------------------+
//|                                                   InfoPanel.mqh  |
//|                         MarekiEA - Visuaalne info paneel          |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "MarekiEA"
#property link      ""
#property version   "1.00"

#ifndef INFOPANEL_MQH
#define INFOPANEL_MQH

#include "Defines.mqh"

//+------------------------------------------------------------------+
//| Info paneeli klass                                                |
//+------------------------------------------------------------------+
class CInfoPanel
{
private:
   string            m_prefix;        // Objektide nimetuse prefiks
   bool              m_enabled;       // Kas paneel on lubatud
   int               m_x;            // X positsioon
   int               m_y;            // Y positsioon
   int               m_width;        // Paneeli laius
   int               m_rowCount;     // Ridade arv
   
public:
                     CInfoPanel();
                    ~CInfoPanel();
   
   //--- Initsialiseerimine
   void              Init(bool enabled);
   void              Deinit();
   
   //--- Paneeli uuendamine
   void              Update(string symbol,
                            ENUM_SIGNAL signal,
                            double fastMA, double slowMA, double rsi,
                            double balance, double equity, double freeMargin,
                            int openPositions, double totalProfit,
                            double drawdown,
                            ENUM_EA_STATE eaState);
   
private:
   //--- Graafikaobjektide loomine
   void              CreateBackground();
   void              CreateLabel(string name, int row, string text, color clr = CLR_TEXT_NORMAL);
   void              UpdateLabel(string name, string text, color clr = CLR_TEXT_NORMAL);
   void              DeleteAllObjects();
   
   //--- Abifunktsioonid
   string            SignalToString(ENUM_SIGNAL signal);
   color             SignalToColor(ENUM_SIGNAL signal);
   string            StateToString(ENUM_EA_STATE state);
   color             ProfitColor(double value);
};

//+------------------------------------------------------------------+
//| Konstruktor                                                       |
//+------------------------------------------------------------------+
CInfoPanel::CInfoPanel()
{
   m_prefix   = EA_PREFIX + "Panel_";
   m_enabled  = true;
   m_x        = PANEL_X;
   m_y        = PANEL_Y;
   m_width    = PANEL_WIDTH;
   m_rowCount = 0;
}

//+------------------------------------------------------------------+
//| Destruktor                                                        |
//+------------------------------------------------------------------+
CInfoPanel::~CInfoPanel()
{
   Deinit();
}

//+------------------------------------------------------------------+
//| Initsialiseerimine                                                |
//+------------------------------------------------------------------+
void CInfoPanel::Init(bool enabled)
{
   m_enabled = enabled;
   
   if(!m_enabled) return;
   
   DeleteAllObjects();
   CreateBackground();
   
   //--- Loo staatilised sildid
   int row = 0;
   CreateLabel("Header",    row++, "═══ MarekiEA ═══", CLR_TEXT_HEADER);
   CreateLabel("Separator1",row++, "─────────────────────────────", CLR_PANEL_BORDER);
   CreateLabel("State",     row++, "Olek: ---");
   CreateLabel("Signal",    row++, "Signaal: ---");
   CreateLabel("Separator2",row++, "─────────────────────────────", CLR_PANEL_BORDER);
   CreateLabel("FastMA",    row++, "Kiire MA: ---");
   CreateLabel("SlowMA",    row++, "Aeglane MA: ---");
   CreateLabel("RSI",       row++, "RSI: ---");
   CreateLabel("Separator3",row++, "─────────────────────────────", CLR_PANEL_BORDER);
   CreateLabel("Balance",   row++, "Saldo: ---");
   CreateLabel("Equity",    row++, "Equity: ---");
   CreateLabel("FreeMargin",row++, "Vaba marginaal: ---");
   CreateLabel("Drawdown",  row++, "Drawdown: ---");
   CreateLabel("Separator4",row++, "─────────────────────────────", CLR_PANEL_BORDER);
   CreateLabel("Positions", row++, "Positsioonid: ---");
   CreateLabel("Profit",    row++, "Kasum/Kahjum: ---");
   CreateLabel("Spread",    row++, "Spread: ---");
   
   m_rowCount = row;
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Deinitsialiseerimine – kustutab kõik paneeli objektid              |
//+------------------------------------------------------------------+
void CInfoPanel::Deinit()
{
   DeleteAllObjects();
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Uuendab paneeli andmeid                                           |
//+------------------------------------------------------------------+
void CInfoPanel::Update(string symbol,
                        ENUM_SIGNAL signal,
                        double fastMA, double slowMA, double rsi,
                        double balance, double equity, double freeMargin,
                        int openPositions, double totalProfit,
                        double drawdown,
                        ENUM_EA_STATE eaState)
{
   if(!m_enabled) return;
   
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   long spread = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
   
   //--- Uuenda oleku ja signaali
   UpdateLabel("State",  "Olek: " + StateToString(eaState),
               eaState == EA_STATE_ACTIVE ? CLR_TEXT_PROFIT : CLR_TEXT_LOSS);
   UpdateLabel("Signal", "Signaal: " + SignalToString(signal), SignalToColor(signal));
   
   //--- Uuenda indikaatorid
   UpdateLabel("FastMA",  StringFormat("Kiire MA: %." + IntegerToString(digits) + "f", fastMA));
   UpdateLabel("SlowMA",  StringFormat("Aeglane MA: %." + IntegerToString(digits) + "f", slowMA));
   UpdateLabel("RSI",     StringFormat("RSI: %.1f", rsi));
   
   //--- Uuenda konto info
   UpdateLabel("Balance",    StringFormat("Saldo: %.2f", balance));
   UpdateLabel("Equity",     StringFormat("Equity: %.2f", equity), ProfitColor(equity - balance));
   UpdateLabel("FreeMargin", StringFormat("Vaba marginaal: %.2f", freeMargin));
   UpdateLabel("Drawdown",   StringFormat("Drawdown: %.1f%%", drawdown),
               drawdown > 5 ? CLR_TEXT_LOSS : CLR_TEXT_NORMAL);
   
   //--- Uuenda positsioonide info
   UpdateLabel("Positions", StringFormat("Positsioonid: %d", openPositions));
   UpdateLabel("Profit",    StringFormat("Kasum/Kahjum: %.2f", totalProfit), ProfitColor(totalProfit));
   UpdateLabel("Spread",    StringFormat("Spread: %d pts", spread),
               spread > 20 ? CLR_TEXT_LOSS : CLR_TEXT_NORMAL);
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Loob taustaobjekti                                                |
//+------------------------------------------------------------------+
void CInfoPanel::CreateBackground()
{
   string name = m_prefix + "BG";
   
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, m_x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, m_y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, m_width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, 17 * PANEL_ROW_HEIGHT + 10);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, CLR_PANEL_BG);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, CLR_PANEL_BORDER);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Loob uue tekstisildi                                              |
//+------------------------------------------------------------------+
void CInfoPanel::CreateLabel(string name, int row, string text, color clr)
{
   string objName = m_prefix + name;
   
   ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, m_x + 8);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, m_y + 5 + row * PANEL_ROW_HEIGHT);
   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetString(0, objName, OBJPROP_FONT, PANEL_FONT_NAME);
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, PANEL_FONT_SIZE);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Uuendab olemasolevat silti                                        |
//+------------------------------------------------------------------+
void CInfoPanel::UpdateLabel(string name, string text, color clr)
{
   string objName = m_prefix + name;
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
}

//+------------------------------------------------------------------+
//| Kustutab kõik paneeli objektid                                    |
//+------------------------------------------------------------------+
void CInfoPanel::DeleteAllObjects()
{
   int total = ObjectsTotal(0);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, m_prefix) == 0)
         ObjectDelete(0, name);
   }
}

//+------------------------------------------------------------------+
//| Teisendab signaali tekstiks                                       |
//+------------------------------------------------------------------+
string CInfoPanel::SignalToString(ENUM_SIGNAL signal)
{
   switch(signal)
   {
      case SIGNAL_BUY:  return "▲ OST";
      case SIGNAL_SELL: return "▼ MÜÜK";
      default:          return "● OOTA";
   }
}

//+------------------------------------------------------------------+
//| Tagastab signaali värvi                                           |
//+------------------------------------------------------------------+
color CInfoPanel::SignalToColor(ENUM_SIGNAL signal)
{
   switch(signal)
   {
      case SIGNAL_BUY:  return CLR_SIGNAL_BUY;
      case SIGNAL_SELL: return CLR_SIGNAL_SELL;
      default:          return CLR_SIGNAL_NONE;
   }
}

//+------------------------------------------------------------------+
//| Teisendab EA oleku tekstiks                                       |
//+------------------------------------------------------------------+
string CInfoPanel::StateToString(ENUM_EA_STATE state)
{
   switch(state)
   {
      case EA_STATE_ACTIVE: return "AKTIIVNE";
      case EA_STATE_PAUSED: return "PEATATUD";
      case EA_STATE_ERROR:  return "VIGA";
      default:              return "TEADMATA";
   }
}

//+------------------------------------------------------------------+
//| Tagastab kasumi/kahjumi värvi                                     |
//+------------------------------------------------------------------+
color CInfoPanel::ProfitColor(double value)
{
   if(value > 0)  return CLR_TEXT_PROFIT;
   if(value < 0)  return CLR_TEXT_LOSS;
   return CLR_TEXT_NORMAL;
}

#endif // INFOPANEL_MQH
//+------------------------------------------------------------------+
