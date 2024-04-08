public without sharing class ChartHelper {
    @AuraEnabled
    public static List<chartData> GetInventory(){
        //  And return a list of chartData
        List<chartData> cht = new List<chartData>();
        //ToDo: Perform a calculation that aggregates active Products that have a positive Quantity_Remaining__c

        List<AggregateResult> arList = [SELECT Family, SUM(Quantity_Remaining__c) sumqnt FROM Product2 
                                    WHERE Quantity_Remaining__c>0
                                        AND IsActive = true
                                             GROUP BY Family]; 
        //  Where the name is the Product Family and the Qty is the sum of the Quantity_Remaining__c
        for (AggregateResult ar : arList) {
            cht.add(new ChartData(String.ValueOf(ar.get('Family')), Integer.ValueOf(ar.get('sumqnt'))));
        }
        return cht;
    }

    public class ChartData {
        public String name {get;set;}
        public Decimal val {get;set;}

        public ChartData(String nameData, Decimal valData){
            this.name = nameData;
            this.val = valData;
        }
    }

}