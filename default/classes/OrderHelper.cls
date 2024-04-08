public without sharing class OrderHelper {
    
    /**
* @name AfterUpdate
* @description 
* @param List<Order> newList
* @param List<Order> oldList
* @return void
**/
    public static void AfterUpdate(List<Order> newList, List<Order> oldList){
        Set<Id> orderIds = new Set<Id>();
        for ( Integer i=0; i<newList.size(); i++ ){
            if ( newList[i].Status == Constants.ACTIVATED_ORDER_STATUS && oldList[i].Status == Constants.DRAFT_ORDER_STATUS ){
                orderIds.add(newList[i].Id);
            }
        }
        RollUpOrderItems(orderIds);
    }
    
    /**
* @name RollUpOrderItems
* @description Given a set of Activated Order ids, query the child Order Items and related Products to calculate Inventory levels
* @param Set<Id> activatedOrderIds
* @return void
**/
    public static void RollUpOrderItems(Set<Id> activatedOrderIds){
        //ToDo: Declare a Map named "productMap" of Ids to Product2 records
        Map<Id, Product2> prodMap = new Map<Id, Product2>();
        
        //ToDo: Loop through a query of OrderItems related to the activatedOrderIds
        List<OrderItem> orderItemList = [SELECT Id, Product2Id, Product2.Quantity_Ordered__c, Quantity, Order.ActivatedDate
                                         FROM OrderItem WHERE OrderId IN : activatedOrderIds];
        for(OrderItem item : orderItemList){
            //ToDo: Populate the map with the Id of the related Product2 as the key and Product2 record as the value
            
            if(!prodMap.containsKey(item.Product2Id)){
                prodMap.put(item.Product2Id, new Product2(Id = item.Product2Id, Quantity_Ordered__c = 0));
            }
            
        }
        
        
        //ToDo: Loop through a query that aggregates the OrderItems related to the Products in the ProductMap keyset	
        List<AggregateResult> aggList = [SELECT Product2Id, Sum(Quantity) sumqnt FROM OrderItem WHERE Product2Id IN : prodMap.keySet() GROUP BY Product2Id];
        for(AggregateResult agg : aggList){
            Id prodId = (Id)agg.get('Product2Id');
            Product2 prod = prodMap.get(prodId);
            prod.Quantity_Ordered__c = (Decimal)agg.get('sumqnt');
            prodMap.put(prodId, prod);   
        }
        //ToDo: Perform an update on the records in the productMap
        if(!prodMap.isEmpty()){
             update prodMap.values();
        }
        
    }
    
}