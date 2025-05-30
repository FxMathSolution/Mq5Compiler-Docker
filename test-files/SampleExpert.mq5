//+------------------------------------------------------------------+
//|                                              SampleExpert.mq5 |
//|                                  Copyright 2025, Your Company |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Your Company"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "Sample Expert Advisor for testing MQ5 compiler"

//--- input parameters
input double   Lots          = 0.1;     // Lot size
input int      TakeProfit    = 100;     // Take Profit in points
input int      StopLoss      = 50;      // Stop Loss in points
input int      MagicNumber   = 12345;   // Magic number

//--- global variables
int            buyCount = 0;
int            sellCount = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("SampleExpert EA initialized successfully");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("SampleExpert EA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Get current prices
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   // Simple trading logic for demonstration
   if(buyCount == 0 && ask > 0)
   {
      OpenBuyOrder();
   }
   
   if(sellCount == 0 && bid > 0)
   {
      OpenSellOrder();
   }
}

//+------------------------------------------------------------------+
//| Open Buy Order                                                   |
//+------------------------------------------------------------------+
void OpenBuyOrder()
{
   MqlTradeRequest request;
   MqlTradeResult  result;
   
   ZeroMemory(request);
   ZeroMemory(result);
   
   request.action    = TRADE_ACTION_DEAL;
   request.symbol    = _Symbol;
   request.volume    = Lots;
   request.type      = ORDER_TYPE_BUY;
   request.price     = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   request.deviation = 3;
   request.magic     = MagicNumber;
   request.comment   = "Sample Buy Order";
   
   if(TakeProfit > 0)
      request.tp = request.price + TakeProfit * _Point;
   
   if(StopLoss > 0)
      request.sl = request.price - StopLoss * _Point;
   
   if(OrderSend(request, result))
   {
      Print("Buy order opened successfully. Ticket: ", result.order);
      buyCount++;
   }
   else
   {
      Print("Failed to open buy order. Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Open Sell Order                                                  |
//+------------------------------------------------------------------+
void OpenSellOrder()
{
   MqlTradeRequest request;
   MqlTradeResult  result;
   
   ZeroMemory(request);
   ZeroMemory(result);
   
   request.action    = TRADE_ACTION_DEAL;
   request.symbol    = _Symbol;
   request.volume    = Lots;
   request.type      = ORDER_TYPE_SELL;
   request.price     = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   request.deviation = 3;
   request.magic     = MagicNumber;
   request.comment   = "Sample Sell Order";
   
   if(TakeProfit > 0)
      request.tp = request.price - TakeProfit * _Point;
   
   if(StopLoss > 0)
      request.sl = request.price + StopLoss * _Point;
   
   if(OrderSend(request, result))
   {
      Print("Sell order opened successfully. Ticket: ", result.order);
      sellCount++;
   }
   else
   {
      Print("Failed to open sell order. Error: ", GetLastError());
   }
}
