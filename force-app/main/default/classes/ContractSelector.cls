/*
 * Author - Ibrahim Ahmed
*/
public class ContractSelector {
    public static List<Contract> getContractAndTimingsByStationIds(Set<Id> stationIds){
        return [
            SELECT
                Id,
                Gas_Station__c,
                (
                    SELECT
                        Id,
                        Start_Time__c,
                        End_Time__c,
                        Comission_Percentage__c
                    FROM
                        Contractual_Comission_Timings__r
                )
            FROM
                Contract
            WHERE
            Gas_Station__c IN :stationIds
        ];
    }
}