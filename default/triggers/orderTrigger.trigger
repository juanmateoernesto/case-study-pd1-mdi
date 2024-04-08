/**
 * @name orderTrigger
 * @description
**/
trigger orderTrigger on Order (after update) {
    if(Trigger.isUpdate){
        if(Trigger.isAfter){
            OrderHelper.AfterUpdate(Trigger.New, Trigger.Old);
        }
    }
    
}