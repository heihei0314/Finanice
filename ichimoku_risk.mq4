//+------------------------------------------------------------------+
//|                                                     ichimoku.mq4 |
//|                                                       Eric Yeung |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property strict


   extern double LotsMultiplier = 0.03; // Amount of lots to trade with
   extern double riskRatio = 0.07; // presentage of usd can loss
   extern double rewardRatio = 1; // risk reward ratio
   //extern double TrailingStop=0.30; // precentage of trailling stop (trailing triggle point)
   //extern double takeProfit = 0; // 100 pips for 1 USD in XAUUSD
   extern double Tenkan=9; // Tenkan-sen (highest high + lowest low)/2 
   extern double Kijun=26; // Kijun-sen (highest high + lowest low)/2 
   extern double Kumo=52; // Kumo 
   extern int magic = 9991;
   
   double volume;
   double loss;
   double profit;
   double t_0;
   double t_1;
   double k_1;
   double k_0;
   double a_0;
   double b_0;
   double price;
   double price_1;
   int slippage = MarketInfo(Symbol(),MODE_SPREAD);
   double sl;
   double tp;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
  t_0=iIchimoku(NULL,0,Tenkan,Kijun,Kumo,MODE_TENKANSEN,0);
  t_1=iIchimoku(NULL,0,Tenkan,Kijun,Kumo,MODE_TENKANSEN,1);
  k_0=iIchimoku(NULL,0,Tenkan,Kijun,Kumo,2,0);
  k_1=iIchimoku(NULL,0,Tenkan,Kijun,Kumo,2,1);
  a_0=iIchimoku(NULL,0,Tenkan,Kijun,Kumo,3,0);
  b_0=iIchimoku(NULL,0,Tenkan,Kijun,Kumo,4,0);
  price = Close[0];

  volume = NormalizeDouble(LotsMultiplier*AccountFreeMargin()/1000,2);
  loss = NormalizeDouble(riskRatio*AccountFreeMargin(),2);
  profit = loss*rewardRatio;
  start();
  
  }
  
 //---
 int LastTime = 0; // 檢測蠟燭
 int start()
 {   
    if(LastTime == Time[0])
      return (0);
     //Comment(t_0);
    // action in every candle
    Comment("LotsMultiplier: "+LotsMultiplier+"\n risk: "+riskRatio+"\n reward: "+rewardRatio+"\n loss: "+loss+"\n profit: "+profit+"\n Tenkan: "+Tenkan+"\n Kijun: "+Kijun+"\n Kumo: "+Kumo+"\n magic: "+magic);
    open_signal(); 
    //close_signal();
    trailingStop();
    
    // action in every candle
    
    LastTime = Time[0];
    return (0);
     
 }
 
//--- 開倉
 void open_signal()
 {
   if ( price > k_0 && price > a_0 && price > b_0)  {
      if (t_0>k_0 && t_1<=k_1) {
           open(0);
      }
      else if (price>k_0 && price_1<k_1 && t_0>k_0 && a_0>b_0){
            //open(0);
      }
   }
   if (price < k_0 && price < a_0 && price < b_0)  {
      if (t_0<k_0 && t_1>=k_1) {
           open(1);
      }
      else if (price<k_0 && price_1>k_1 && t_0<k_0 && a_0<b_0){
           // open(1);
      }
   }
 }
 
void open(int BuyOrSell)
{
   int ticket;
   if (BuyOrSell == 0){
      sl = price-loss;
      tp = price+profit;
      ticket=OrderSend(Symbol(),BuyOrSell,volume,Ask,slippage,sl,tp,"My order "+magic,magic,0,clrBlue);
   }
   else{
      sl = price+loss;
      tp = price-profit;
      ticket=OrderSend(Symbol(),BuyOrSell,volume,Bid,slippage,sl,tp,"My order "+magic,magic,0,clrRed);
   }
   if(ticket<0)
     {
      //Comment("OrderSend failed with error #",GetLastError());
     }
   else {
      //Comment(Close[0]+", "+t_0+", "+t_1);
    }
}    
//--- 開倉

//--- 平倉
void close_signal()
 {
   if ( price > k_0 )  {
       close(1);

   }
   if ( price < k_0 )  {
       close(0);
       
   }
 }
 
void close(int BuyOrSell )
{
   bool closed;
   int total = OrdersTotal()-1;
   for (int i = total; i >= 0; i--) {
    OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
    if (OrderType() == BuyOrSell && OrderMagicNumber()==magic) { 
        closed = OrderClose(OrderTicket(),OrderLots(),Bid,slippage,clrYellow);
    }
    if (OrderType() == BuyOrSell && OrderMagicNumber()==magic ) { 
        closed = OrderClose(OrderTicket(),OrderLots(),Ask,slippage,clrGreen);
    }
   }
}    
//--- 平倉

//--- Trailing Stop
void trailingStop()
{
   double n;
   int total = OrdersTotal()-1;
   for (int i = total; i >= 0; i--) {
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if (OrderType() == 0 && OrderMagicNumber()==magic ) { 
         n = (price-OrderOpenPrice())/loss;
         if (n >= 1){       
            sl = OrderOpenPrice()+loss*(n-1);
            tp = OrderOpenPrice()+profit;
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),sl,tp,0,clrPurple);
         }
         
      }
      else if (OrderType() == 1 && OrderMagicNumber()==magic ) { 
         n = (OrderOpenPrice()- price)/loss;
         if (n >= 1){
            sl = OrderOpenPrice()-loss*(n-1);
            tp = OrderOpenPrice()-profit;
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),sl,tp,0,clrPurple);
         }
         
      }
   }
}    
//--- Trailing Stop