/*
 * Author - Ibrahim Ahmed
*/
public class MachineSelector {
    public static List<Machine__c> getMachinesByMachineNumbers (Set<String> machineNumbers){
        return [
            SELECT
                Id,
                Cash_and_Credit__c,
                Credit__c
            FROM
                Machine__c
            WHERE
                Cash_and_Credit__c IN: machineNumbers
                OR
                Credit__c IN: machineNumbers
        ];
    }
}