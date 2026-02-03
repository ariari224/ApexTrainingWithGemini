trigger Opportunity_Trg on Opportunity (before insert, after insert, before update, after update, after delete, after undelete) {
    if (Trigger.isInsert && Trigger.isAfter) {
        Opportunity_TrgHandler.onAfterInsert(Trigger.new);
    }

    if (Trigger.isUpdate && Trigger.isAfter) {
        Opportunity_TrgHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isDelete && Trigger.isAfter) {
        Opportunity_TrgHandler.onAfterDelete(Trigger.old);
    }

    if (Trigger.isUndelete && Trigger.isAfter) {
        Opportunity_TrgHandler.onAfterUndelete(Trigger.new);
    }
}