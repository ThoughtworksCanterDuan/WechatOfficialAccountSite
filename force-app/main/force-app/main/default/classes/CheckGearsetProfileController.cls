public with sharing class CheckGearsetProfileController {
    @AuraEnabled(cacheable=true)
    public static List<Check_Gearset_profile__c> CheckGearsetProfileController() {
        return [SELECT Id, Test_Gearset_Field_Profile__c FROM Check_Gearset_profile__c];
    }
}
