public class Product2Helper {

    /**
     * @name COLLABORATION_GROUP
     * @description List of CollaborationGroup used in both business and test logic
    **/
    static List<CollaborationGroup> COLLABORATION_GROUP = [
        SELECT Id
        FROM CollaborationGroup
        WHERE Name = :Constants.INVENTORY_ANNOUNCEMENTS 
        OR Name = :('TEST'+Constants.INVENTORY_ANNOUNCEMENTS)
        LIMIT 1
    ];

    /**
     * @name afterUpdate
     * @description called by product2 Trigger on After Update
     * @param List<Product2> newList
     * @param List<Product2> oldList
    **/
    public static void AfterUpdate(List<Product2> newList){
//        public static void AfterUpdate(List<Product2> newList, List<Product2> oldList){
        
        List<Product2> needsAnnouncement = new List<Product2>();
        
        Map<String, Inventory_Setting__mdt> records = 
            new Map<String, Inventory_Setting__mdt>();

        List<Inventory_Setting__mdt> inventorySettings = [SELECT Label, Low_Quantity_Alert__c FROM Inventory_Setting__mdt];
        for(Inventory_Setting__mdt inventorySetting:inventorySettings){
            records.put(inventorySetting.Label,inventorySetting);
        }
        
        for(Integer i=0;i<newList.size();i++){
            //get the low inventory limit for the family type
            Inventory_Setting__mdt inventorySetting = 
                    (Inventory_Setting__mdt)records.get(newList[i].Family);
            Integer alertQuantity = (Integer)inventorySetting.Low_Quantity_Alert__c;
            
            if( newList[i].Quantity_Remaining__c <= alertQuantity ){
                //if quantity of product is equal or lower than the set low quantity limit, add the product to the list
                   needsAnnouncement.add(newList[i]);
               }
            
            /*(if( newList[i].Quantity_Remaining__c <= alertQuantity && 
               oldList[i].Quantity_Remaining__c > alertQuantity){
                   needsAnnouncement.add(newList[i]);
               }*/
        }
        //call postalert method
        PostAlerts(needsAnnouncement);
    }


    /**
     * @name postAlerts
     * @description called by product2 Trigger on After Update
     * @param List<Product2> productList
    **/
    public static void PostAlerts(List<Product2> productList){
        List<ConnectApi.AnnouncementInput> toPost = new List<ConnectApi.AnnouncementInput>();
        for ( Product2 p : productList ){
            // ToDo: Construct a new AnnouncementInput for the Chatter Group so that it:
            // expires in a day
            // does not notify users via email.
            // and has a text body that includes the name of the product followed by the INVENTORY_LEVEL_LOW constant
            ConnectApi.MessageBodyInput msgBody = new ConnectApi.MessageBodyInput();
            ConnectApi.AnnouncementInput tempPost = new ConnectApi.AnnouncementInput();
            ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
            textSegment.text = p.Name +'  '+ Constants.INVENTORY_LEVEL_LOW;
            msgBody.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            msgBody.messageSegments.add(textSegment);
            
            tempPost.body = msgBody;
            tempPost.expirationDate = DateTime.Now().AddDays(1);
            tempPost.parentId = COLLABORATION_GROUP[0].id;
            tempPost.sendEmails = false;
            toPost.add(tempPost);
         }
    
        // ToDo: Create and enqueue an instance of the announcementQueuable class with the list of Products
        AnnouncementQueueable annQue = new AnnouncementQueueable(toPost);
        //annQue.toPost = toPost;
        //system.enqueueJob(annQue);
        Id jobId = System.enqueueJob(annQue);
    }
}