trigger Opportunity_Trg on Opportunity (before insert, after insert, before update, after update) {
    Opportunity_TrgHandler handler = new Opportunity_TrgHandler();
    // if (Trigger.isInsert) {
    //     if (Trigger.isBefore) {
            
    //     } else {

    //     }
    // } else if (Trigger.isUpdate) {
    //     if (Trigger.isBefore) {
            
    //     } else {
    //         handler.onAfterUpdate(Trigger.new, Trigger.oldMap);
    //     }
    // }

    if (Trigger.isUpdate && Trigger.isAfter) {
        handler.onAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}