//+------------------------------------------------------------------+
//|                                                    MarekiEA.mq5  |
//|                    MarekiEA - Kauplemisrobot MetaTrader 5 jaoks   |
//|                  MA Crossover + RSI filter strateegiaga           |
//+------------------------------------------------------------------+
#property copyright "MarekiEA"
#property link      ""
#property version   "1.00"
#property description "MarekiEA – Automaatne kauplemisrobot"
#property description "Strateegia: MA Crossover + RSI filter"
#property description "Sisaldab riskijuhtimist ja trailing stop'i"
#property strict

//+------------------------------------------------------------------+
//| Moodulite sisestamine                                             |
//+------------------------------------------------------------------+
#include "Defines.mqh"
#include "Strategy.mqh"
#include "RiskManager.mqh"
#include "TradeManager.mqh"
#include "InfoPanel.mqh"

//+------------------------------------------------------------------+
//| Sisend-parameetrid                                                |
//+------------------------------------------------------------------+
// === Strateegia seaded ===
input group "══════ Strateegia ══════"
input int               InpFastMA_Period    = 10;            // Kiire MA periood
input int               InpSlowMA_Period    = 50;            // Aeglane MA periood
input ENUM_MA_METHOD    InpMA_Method        = MODE_EMA;      // MA arvutusmeetod
input ENUM_TIMEFRAMES   InpTradingTF        = PERIOD_H1;     // Kauplemise ajakava
input int               InpRSI_Period       = 14;            // RSI periood
input double            InpRSI_Overbought   = 70.0;          // RSI üleostetud tase
input double            InpRSI_Oversold     = 30.0;          // RSI ülemüüdud tase

// === Riskijuhtimine ===
input group "══════ Riskijuhtimine ══════"
input double            InpRiskPercent      = 1.0;           // Risk % kontost tehingu kohta
input double            InpFixedLot         = 0.0;           // Fikseeritud lot (0 = kasuta riski %)
input int               InpStopLoss_Pts    = 500;            // Stop Loss (punktides)
input int               InpTakeProfit_Pts  = 1000;           // Take Profit (punktides)
input double            InpMaxDrawdown      = 10.0;          // Max drawdown % (peatab kauplemise)

// === Trailing Stop ===
input group "══════ Trailing Stop ══════"
input bool              InpUseTrailingStop  = true;          // Kasuta trailing stop'i
input int               InpTrailingStop_Pts = 300;           // Trailing stop (punktides)
input int               InpTrailingStep_Pts = 50;            // Trailing step (punktides)

// === Üldised seaded ===
input group "══════ Üldised ══════"
input ulong             InpMagicNumber      = 202602;        // EA identifikaator (Magic Number)
input string            InpTradeComment     = "MarekiEA";    // Tehingu kommentaar
input int               InpMaxSpread        = 30;            // Max lubatud spread (punktides)
input int               InpSlippage         = 10;            // Max libisemine (punktides)
input bool              InpTradeOnNewBar    = true;          // Kaubelda ainult uue küünla avamisel
input bool              InpShowPanel        = true;          // Kuva info paneel graafikul

//+------------------------------------------------------------------+
//| Globaalsed muutujad                                               |
//+------------------------------------------------------------------+
CStrategy      g_strategy;       // Strateegia objekt
CRiskManager   g_riskManager;    // Riskijuhtimise objekt
CTradeManager  g_tradeManager;   // Orderite halduse objekt
CInfoPanel     g_infoPanel;      // Info paneeli objekt

datetime       g_lastBarTime;    // Viimase töödeldud küünla aeg
bool           g_isNewBar;       // Kas on uus küünal

//+------------------------------------------------------------------+
//| Expert Advisor initsialiseerimine                                  |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("═══════════════════════════════════════════════════");
   Print("        MarekiEA v1.00 - Käivitamine...");
   Print("═══════════════════════════════════════════════════");
   
   //--- Kontrolli parameetrite kehtivust
   if(InpFastMA_Period >= InpSlowMA_Period)
   {
      PrintFormat("[EA] VIGA: Kiire MA (%d) peab olema väiksem kui aeglane MA (%d)!",
                  InpFastMA_Period, InpSlowMA_Period);
      return INIT_PARAMETERS_INCORRECT;
   }
   
   if(InpRSI_Oversold >= InpRSI_Overbought)
   {
      PrintFormat("[EA] VIGA: RSI ülemüüdud (%.0f) peab olema väiksem kui üleostetud (%.0f)!",
                  InpRSI_Oversold, InpRSI_Overbought);
      return INIT_PARAMETERS_INCORRECT;
   }
   
   //--- Kontrolli kauplemise lubamist
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
   {
      Print("[EA] HOIATUS: Automaatne kauplemine ei ole terminalis lubatud!");
   }
   
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
   {
      Print("[EA] HOIATUS: Automaatne kauplemine ei ole selle EA jaoks lubatud!");
   }
   
   //--- Initsialiseeri strateegia
   if(!g_strategy.Init(_Symbol, InpTradingTF,
                       InpFastMA_Period, InpSlowMA_Period, InpMA_Method,
                       InpRSI_Period, InpRSI_Overbought, InpRSI_Oversold))
   {
      Print("[EA] VIGA: Strateegia initsialiseerimine ebaõnnestus!");
      return INIT_FAILED;
   }
   
   //--- Initsialiseeri riskijuhtimine
   if(!g_riskManager.Init(_Symbol,
                          InpRiskPercent, InpFixedLot,
                          InpStopLoss_Pts, InpTakeProfit_Pts,
                          InpMaxDrawdown))
   {
      Print("[EA] VIGA: Riskijuhtimise initsialiseerimine ebaõnnestus!");
      return INIT_FAILED;
   }
   
   //--- Initsialiseeri orderite haldus
   if(!g_tradeManager.Init(_Symbol, InpMagicNumber, InpSlippage, InpMaxSpread,
                           InpUseTrailingStop, InpTrailingStop_Pts, InpTrailingStep_Pts))
   {
      Print("[EA] VIGA: Orderite halduse initsialiseerimine ebaõnnestus!");
      return INIT_FAILED;
   }
   
   //--- Initsialiseeri info paneel
   g_infoPanel.Init(InpShowPanel);
   
   //--- Sea alg-küünla aeg
   g_lastBarTime = 0;
   g_isNewBar    = false;
   
   Print("═══════════════════════════════════════════════════");
   PrintFormat("  Sümbol: %s | Ajakava: %s", _Symbol, EnumToString(InpTradingTF));
   PrintFormat("  Strateegia: EMA(%d/%d) + RSI(%d)", InpFastMA_Period, InpSlowMA_Period, InpRSI_Period);
   PrintFormat("  Risk: %.1f%% | SL: %d pts | TP: %d pts", InpRiskPercent, InpStopLoss_Pts, InpTakeProfit_Pts);
   PrintFormat("  Magic: %d | Trailing: %s", InpMagicNumber, InpUseTrailingStop ? "JAH" : "EI");
   Print("  Olek: AKTIIVNE – valmis kauplema!");
   Print("═══════════════════════════════════════════════════");
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert Advisor deinitsialiseerimine                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Vabasta moodulid
   g_strategy.Deinit();
   g_infoPanel.Deinit();
   
   //--- Logi sulgemise põhjus
   string reasonText;
   switch(reason)
   {
      case REASON_PROGRAM:     reasonText = "Programm suleti";    break;
      case REASON_REMOVE:      reasonText = "EA eemaldatud";      break;
      case REASON_RECOMPILE:   reasonText = "Ümberkompileerimine"; break;
      case REASON_CHARTCHANGE: reasonText = "Graafik muudetud";   break;
      case REASON_CHARTCLOSE:  reasonText = "Graafik suletud";    break;
      case REASON_PARAMETERS:  reasonText = "Parameetrid muudetud"; break;
      case REASON_ACCOUNT:     reasonText = "Konto muudetud";     break;
      default:                 reasonText = "Tundmatu põhjus";    break;
   }
   
   PrintFormat("[EA] MarekiEA peatatud. Põhjus: %s (kood: %d)", reasonText, reason);
}

//+------------------------------------------------------------------+
//| Expert Advisor OnTick – peamine tsükkel                           |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- 1. Kontrolli uut küünalt (kui vajalik)
   g_isNewBar = IsNewBar();
   
   //--- 2. Haldab trailing stop'i igal tikil
   g_tradeManager.ManageTrailingStop();
   
   //--- 3. Uuenda info paneeli
   UpdatePanel();
   
   //--- 4. Kui ainult uuel küünlal kaupleme ja ei ole uus küünal, lõpeta
   if(InpTradeOnNewBar && !g_isNewBar)
      return;
   
   //--- 5. Kontrolli drawdown'i
   if(!g_riskManager.CheckDrawdown())
   {
      // Drawdown on üle piiri – sulge kõik positsioonid turvalisuse jaoks
      if(g_tradeManager.HasOpenPosition())
      {
         Print("[EA] Max drawdown saavutatud! Sulen kõik positsioonid...");
         g_tradeManager.CloseAll();
      }
      return;
   }
   
   //--- 6. Kontrolli, kas kauplemine on lubatud
   if(!IsTradeAllowed())
      return;
   
   //--- 7. Kontrolli spread'i
   if(!g_tradeManager.IsSpreadOK())
      return;
   
   //--- 8. Genereeri signaalid
   ENUM_SIGNAL signal = g_strategy.CheckSignal();
   
   //--- 9. Töötle signaalid
   ProcessSignal(signal);
}

//+------------------------------------------------------------------+
//| Töötleb kauplemissignaali                                         |
//+------------------------------------------------------------------+
void ProcessSignal(ENUM_SIGNAL signal)
{
   if(signal == SIGNAL_NONE)
      return;
   
   //--- Kui signaal on OST
   if(signal == SIGNAL_BUY)
   {
      //--- Sulge vastupidised positsioonid (müügid)
      if(g_tradeManager.HasOpenSell())
      {
         Print("[EA] Sulen müügi-positsioonid (vastupidine signaal)...");
         g_tradeManager.CloseSells();
      }
      
      //--- Kui ostupositsioon juba avatud, ära ava uut
      if(g_tradeManager.HasOpenBuy())
      {
         Print("[EA] Ostu positsioon juba avatud, jätan vahele.");
         return;
      }
      
      //--- Arvuta SL ja TP
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double sl  = g_riskManager.GetStopLoss(SIGNAL_BUY, ask);
      double tp  = g_riskManager.GetTakeProfit(SIGNAL_BUY, ask);
      
      //--- Arvuta lot-suurus
      double lot = g_riskManager.CalculateLotSize(ask, sl);
      
      //--- Ava ostu-positsioon
      g_tradeManager.OpenBuy(lot, sl, tp, InpTradeComment);
   }
   //--- Kui signaal on MÜÜK
   else if(signal == SIGNAL_SELL)
   {
      //--- Sulge vastupidised positsioonid (ostud)
      if(g_tradeManager.HasOpenBuy())
      {
         Print("[EA] Sulen ostu-positsioonid (vastupidine signaal)...");
         g_tradeManager.CloseBuys();
      }
      
      //--- Kui müügipositsioon juba avatud, ära ava uut
      if(g_tradeManager.HasOpenSell())
      {
         Print("[EA] Müügi positsioon juba avatud, jätan vahele.");
         return;
      }
      
      //--- Arvuta SL ja TP
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double sl  = g_riskManager.GetStopLoss(SIGNAL_SELL, bid);
      double tp  = g_riskManager.GetTakeProfit(SIGNAL_SELL, bid);
      
      //--- Arvuta lot-suurus
      double lot = g_riskManager.CalculateLotSize(bid, sl);
      
      //--- Ava müügi-positsioon
      g_tradeManager.OpenSell(lot, sl, tp, InpTradeComment);
   }
}

//+------------------------------------------------------------------+
//| Kontrollib, kas on uus küünal                                     |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime currentBarTime = iTime(_Symbol, InpTradingTF, 0);
   
   if(currentBarTime == 0)
      return false;
   
   if(currentBarTime != g_lastBarTime)
   {
      g_lastBarTime = currentBarTime;
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Kontrollib, kas automaatne kauplemine on lubatud                   |
//+------------------------------------------------------------------+
bool IsTradeAllowed()
{
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
      return false;
   
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
      return false;
   
   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Uuendab info paneeli                                              |
//+------------------------------------------------------------------+
void UpdatePanel()
{
   double balance    = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity     = AccountInfoDouble(ACCOUNT_EQUITY);
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   int    positions  = g_tradeManager.CountPositions();
   double profit     = g_tradeManager.GetTotalProfit();
   double drawdown   = g_riskManager.GetCurrentDrawdown();
   
   g_infoPanel.Update(_Symbol,
                      g_strategy.GetLastSignal(),
                      g_strategy.GetFastMA(1),
                      g_strategy.GetSlowMA(1),
                      g_strategy.GetRSI(1),
                      balance, equity, freeMargin,
                      positions, profit,
                      drawdown,
                      g_riskManager.GetState());
}
//+------------------------------------------------------------------+
