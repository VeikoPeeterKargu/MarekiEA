//+------------------------------------------------------------------+
//|                                                TradeManager.mqh  |
//|                         MarekiEA - Orderite haldamise moodul     |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "MarekiEA"
#property link      ""
#property version   "1.00"

#ifndef TRADEMANAGER_MQH
#define TRADEMANAGER_MQH

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include "Defines.mqh"

//+------------------------------------------------------------------+
//| Orderite haldamise klass                                          |
//+------------------------------------------------------------------+
class CTradeManager
{
private:
   CTrade            m_trade;           // MQL5 kauplemisklass
   CPositionInfo     m_position;        // Positsioonide info klass
   
   string            m_symbol;          // Kauplemissümbol
   ulong             m_magicNumber;     // Unikaalne EA ID
   int               m_slippage;        // Max libisemine
   int               m_maxSpread;       // Max lubatud spread
   
   //--- Trailing Stop parameetrid
   bool              m_useTrailingStop; // Kas kasutada trailing stop'i
   int               m_trailingPoints;  // Trailing stop punktides
   int               m_trailingStep;    // Trailing step punktides
   
public:
                     CTradeManager();
                    ~CTradeManager();
   
   //--- Initsialiseerimine
   bool              Init(string symbol, ulong magic, int slippage, int maxSpread,
                          bool useTrailing, int trailingPts, int trailingStep);
   
   //--- Tehingute avamine
   bool              OpenBuy(double lot, double sl, double tp, string comment = "");
   bool              OpenSell(double lot, double sl, double tp, string comment = "");
   
   //--- Tehingute sulgemine
   bool              CloseAll();
   bool              CloseBuys();
   bool              CloseSells();
   
   //--- Trailing Stop
   void              ManageTrailingStop();
   
   //--- Kontrollid
   bool              HasOpenPosition();
   bool              HasOpenBuy();
   bool              HasOpenSell();
   int               CountPositions();
   double            GetTotalProfit();
   bool              IsSpreadOK();
   
   //--- Getterid
   ulong             GetMagicNumber() const { return m_magicNumber; }
   
private:
   //--- Abifunktsioonid
   bool              SelectPositionByMagic();
};

//+------------------------------------------------------------------+
//| Konstruktor                                                       |
//+------------------------------------------------------------------+
CTradeManager::CTradeManager()
{
   m_magicNumber     = 12345;
   m_slippage        = 10;
   m_maxSpread       = 30;
   m_useTrailingStop = false;
   m_trailingPoints  = 300;
   m_trailingStep    = 50;
}

//+------------------------------------------------------------------+
//| Destruktor                                                        |
//+------------------------------------------------------------------+
CTradeManager::~CTradeManager() {}

//+------------------------------------------------------------------+
//| Initsialiseerimine                                                |
//+------------------------------------------------------------------+
bool CTradeManager::Init(string symbol, ulong magic, int slippage, int maxSpread,
                         bool useTrailing, int trailingPts, int trailingStep)
{
   m_symbol          = symbol;
   m_magicNumber     = magic;
   m_slippage        = slippage;
   m_maxSpread       = maxSpread;
   m_useTrailingStop = useTrailing;
   m_trailingPoints  = trailingPts;
   m_trailingStep    = trailingStep;
   
   //--- Seadista CTrade klass
   m_trade.SetExpertMagicNumber(magic);
   m_trade.SetDeviationInPoints(slippage);
   m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   m_trade.SetMarginMode();
   m_trade.LogLevel(LOG_LEVEL_ERRORS);
   
   PrintFormat("[TradeManager] Initsialiseerimine: Sümbol=%s | Magic=%d | Slippage=%d | MaxSpread=%d | Trailing=%s",
               m_symbol, magic, slippage, maxSpread, useTrailing ? "JAH" : "EI");
   
   return true;
}

//+------------------------------------------------------------------+
//| Avab ostu-positsiooni                                             |
//+------------------------------------------------------------------+
bool CTradeManager::OpenBuy(double lot, double sl, double tp, string comment)
{
   if(!IsSpreadOK())
   {
      PrintFormat("[TradeManager] OSTU ebaõnnestumine: Spread(%.0f) > Max(%d)",
                  SymbolInfoInteger(m_symbol, SYMBOL_SPREAD), m_maxSpread);
      return false;
   }
   
   double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
   
   if(comment == "")
      comment = "MarekiEA BUY";
   
   bool result = m_trade.Buy(lot, m_symbol, ask, sl, tp, comment);
   
   if(result)
   {
      PrintFormat("[TradeManager] >>> OST avatud: Lot=%.2f | Hind=%.5f | SL=%.5f | TP=%.5f",
                  lot, ask, sl, tp);
   }
   else
   {
      PrintFormat("[TradeManager] VIGA ostu avamisel! Kood: %d | Kirjeldus: %s",
                  m_trade.ResultRetcode(), m_trade.ResultComment());
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| Avab müügi-positsiooni                                            |
//+------------------------------------------------------------------+
bool CTradeManager::OpenSell(double lot, double sl, double tp, string comment)
{
   if(!IsSpreadOK())
   {
      PrintFormat("[TradeManager] MÜÜGI ebaõnnestumine: Spread(%.0f) > Max(%d)",
                  SymbolInfoInteger(m_symbol, SYMBOL_SPREAD), m_maxSpread);
      return false;
   }
   
   double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   
   if(comment == "")
      comment = "MarekiEA SELL";
   
   bool result = m_trade.Sell(lot, m_symbol, bid, sl, tp, comment);
   
   if(result)
   {
      PrintFormat("[TradeManager] >>> MÜÜK avatud: Lot=%.2f | Hind=%.5f | SL=%.5f | TP=%.5f",
                  lot, bid, sl, tp);
   }
   else
   {
      PrintFormat("[TradeManager] VIGA müügi avamisel! Kood: %d | Kirjeldus: %s",
                  m_trade.ResultRetcode(), m_trade.ResultComment());
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| Sulgeb kõik EA positsioonid                                       |
//+------------------------------------------------------------------+
bool CTradeManager::CloseAll()
{
   bool allClosed = true;
   int total = PositionsTotal();
   
   for(int i = total - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      
      if(PositionGetString(POSITION_SYMBOL) != m_symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != (long)m_magicNumber) continue;
      
      if(!m_trade.PositionClose(ticket))
      {
         PrintFormat("[TradeManager] Positsiooni sulgemine ebaõnnestus! Pilet: %d | Kood: %d",
                     ticket, m_trade.ResultRetcode());
         allClosed = false;
      }
      else
      {
         PrintFormat("[TradeManager] Positsioon suletud: Pilet=%d", ticket);
      }
   }
   
   return allClosed;
}

//+------------------------------------------------------------------+
//| Sulgeb kõik ostu-positsioonid                                     |
//+------------------------------------------------------------------+
bool CTradeManager::CloseBuys()
{
   bool allClosed = true;
   int total = PositionsTotal();
   
   for(int i = total - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      
      if(PositionGetString(POSITION_SYMBOL) != m_symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)  != (long)m_magicNumber) continue;
      if(PositionGetInteger(POSITION_TYPE)   != POSITION_TYPE_BUY) continue;
      
      if(!m_trade.PositionClose(ticket))
         allClosed = false;
      else
         PrintFormat("[TradeManager] Ostu positsioon suletud: Pilet=%d", ticket);
   }
   
   return allClosed;
}

//+------------------------------------------------------------------+
//| Sulgeb kõik müügi-positsioonid                                    |
//+------------------------------------------------------------------+
bool CTradeManager::CloseSells()
{
   bool allClosed = true;
   int total = PositionsTotal();
   
   for(int i = total - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      
      if(PositionGetString(POSITION_SYMBOL) != m_symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)  != (long)m_magicNumber) continue;
      if(PositionGetInteger(POSITION_TYPE)   != POSITION_TYPE_SELL) continue;
      
      if(!m_trade.PositionClose(ticket))
         allClosed = false;
      else
         PrintFormat("[TradeManager] Müügi positsioon suletud: Pilet=%d", ticket);
   }
   
   return allClosed;
}

//+------------------------------------------------------------------+
//| Haldab trailing stop'i kõigil avatud positsioonidel                |
//+------------------------------------------------------------------+
void CTradeManager::ManageTrailingStop()
{
   if(!m_useTrailingStop)
      return;
   
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   int    digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
   int    total = PositionsTotal();
   
   for(int i = total - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      
      if(PositionGetString(POSITION_SYMBOL) != m_symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != (long)m_magicNumber) continue;
      
      double openPrice   = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL   = PositionGetDouble(POSITION_SL);
      double currentTP   = PositionGetDouble(POSITION_TP);
      long   posType     = PositionGetInteger(POSITION_TYPE);
      
      double trailingDist = m_trailingPoints * point;
      double trailingStep = m_trailingStep * point;
      
      if(posType == POSITION_TYPE_BUY)
      {
         double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
         double newSL = NormalizeDouble(bid - trailingDist, digits);
         
         // Kontrolli, kas hind on piisavalt kaugel (kasumis)
         if(bid - openPrice > trailingDist)
         {
            // Liiguta SL ainult üles ja ainult kui samm on piisav
            if(newSL > currentSL + trailingStep || currentSL == 0)
            {
               if(m_trade.PositionModify(ticket, newSL, currentTP))
               {
                  PrintFormat("[TradeManager] Trailing Stop uuendatud (OST): Pilet=%d | Uus SL=%.5f",
                              ticket, newSL);
               }
            }
         }
      }
      else if(posType == POSITION_TYPE_SELL)
      {
         double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
         double newSL = NormalizeDouble(ask + trailingDist, digits);
         
         // Kontrolli, kas hind on piisavalt kaugel (kasumis)
         if(openPrice - ask > trailingDist)
         {
            // Liiguta SL ainult alla ja ainult kui samm on piisav
            if(newSL < currentSL - trailingStep || currentSL == 0)
            {
               if(m_trade.PositionModify(ticket, newSL, currentTP))
               {
                  PrintFormat("[TradeManager] Trailing Stop uuendatud (MÜÜK): Pilet=%d | Uus SL=%.5f",
                              ticket, newSL);
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Kontrollib, kas EA-l on avatud positsioon                         |
//+------------------------------------------------------------------+
bool CTradeManager::HasOpenPosition()
{
   return (CountPositions() > 0);
}

//+------------------------------------------------------------------+
//| Kontrollib, kas EA-l on avatud ostu positsioon                    |
//+------------------------------------------------------------------+
bool CTradeManager::HasOpenBuy()
{
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != m_symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != (long)m_magicNumber) continue;
      if(PositionGetInteger(POSITION_TYPE)  == POSITION_TYPE_BUY)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Kontrollib, kas EA-l on avatud müügi positsioon                   |
//+------------------------------------------------------------------+
bool CTradeManager::HasOpenSell()
{
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != m_symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != (long)m_magicNumber) continue;
      if(PositionGetInteger(POSITION_TYPE)  == POSITION_TYPE_SELL)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Loendab EA avatud positsioonide arvu                              |
//+------------------------------------------------------------------+
int CTradeManager::CountPositions()
{
   int count = 0;
   int total = PositionsTotal();
   
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != m_symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != (long)m_magicNumber) continue;
      count++;
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Arvutab EA avatud positsioonide kogukasum/kahjum                  |
//+------------------------------------------------------------------+
double CTradeManager::GetTotalProfit()
{
   double profit = 0;
   int total = PositionsTotal();
   
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != m_symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != (long)m_magicNumber) continue;
      profit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
   }
   
   return profit;
}

//+------------------------------------------------------------------+
//| Kontrollib, kas praegune spread on lubatud piirides                |
//+------------------------------------------------------------------+
bool CTradeManager::IsSpreadOK()
{
   long spread = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD);
   return (spread <= m_maxSpread);
}

#endif // TRADEMANAGER_MQH
//+------------------------------------------------------------------+
