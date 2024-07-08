public class GasStationSelector {
    public static List<Gas_Station__c> getStaionsByExternalIds (Set<String> externalIds){
        return [
            SELECT
                Id,
                External_Id__c
            FROM
                Gas_Station__c
            WHERE
                External_Id__c IN: externalIds
        ];
    }

    /*public static List<Gas_Station__c> getStaionsByIds (Set<Id> stationIds){
        return [
            SELECT
                Id,
                External_Id__c
            FROM
                Gas_Station__c
            WHERE
                Id IN: stationIds
        ];
    }*/
}