/*
 * Author - Ibrahim Ahmed
*/
public with sharing class TransactionTriggerHandler extends TriggerHandler {
    
    public override void beforeInsert (){
        Set<String> externalMachineIds = new Set<String>();
        Map<String, Machine__c> machineByCreditAndCash = new Map<String, Machine__c>();
        Map<String, Machine__c> machineByCredit = new Map<String, Machine__c>();

        for (Transaction__c tran: (List<Transaction__c>) Trigger.new){
            if (tran.Machine__c == null){
                externalMachineIds.add(tran.Device_Number__c);
            }
        }
        // Query Machines by MachineNumbers
        List<Machine__c> machines = MachineSelector.getMachinesByMachineNumbers(externalMachineIds);

        // Logic to prepare machine maps
        for (Machine__c machine :machines){
            if (machine.Cash_and_Credit__c != null){
                machineByCreditAndCash.put(machine.Cash_and_Credit__c, machine);
            }
            if (machine.Credit__c != null){
                machineByCredit.put(machine.Credit__c, machine);
            }
        }

        for (Transaction__c tran: (List<Transaction__c>) Trigger.new){
            if (tran.Machine__c == null && tran.Device_Number__c != null){
                if (machineByCreditAndCash.get(tran.Device_Number__c) != null){
                    tran.Machine__c = machineByCreditAndCash.get(tran.Device_Number__c).Id;
                } else if (machineByCredit.get(tran.Device_Number__c) != null){
                    tran.Machine__c = machineByCredit.get(tran.Device_Number__c).Id;
                } 
            }
        }
    }
}