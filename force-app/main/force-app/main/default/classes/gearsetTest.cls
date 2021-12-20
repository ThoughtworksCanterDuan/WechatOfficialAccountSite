public with sharing class gearsetTest {
    public List<Gearset_Test__c> gearsetTest() {
        return [
            SELECT Name, Test__c
            FROM Gearset_Test__c
        ];
    }
}
