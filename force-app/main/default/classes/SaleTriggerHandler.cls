/*
 * Author - Ibrahim Ahmed
*/
public class SaleTriggerHandler extends TriggerHandler {
    private Map<Id, Sale__c> newSaleMap;
    private List<Sale__c> newSales;

    public SaleTriggerHandler(){
        this.newSaleMap = (Map<Id, Sale__c>) Trigger.newMap;
        this.newSales = (List<Sale__c>) Trigger.new;
    }

    public override void beforeInsert() {

        Map<Id, List<Sale__c>> salesByStation = new Map<Id, List<Sale__c>>();
        Map<Id, Contract> contractByStation = new Map<Id, Contract>();
        Map<String, Id> stationByExternalId = new Map<String, Id>();
        Map<String, Machine__c> machineByCreditAndCash = new Map<String, Machine__c>();
        Map<String, Machine__c> machineByCredit = new Map<String, Machine__c>();

        List<Sale__c> salesWithNoStaionId = new List<Sale__c>();
        Set<String> externalStationIds = new Set<String>();
        Set<Id> stationIds = new Set<Id>();
        Set<String> machineNumbers = new Set<String>();

        //Logic to prepare SalesByStation Map
        for (Sale__c sale: this.newSales){
            if (sale.Machine_Number__c != null){
                machineNumbers.add(sale.Machine_Number__c);
            }
            if (sale.Gas_Station__c != null){
                stationIds.add(sale.Gas_Station__c);
            }
            else if(sale.Station_Id_External__c != null){
                salesWithNoStaionId.add(sale);
                externalStationIds.add(sale.Station_Id_External__c);
            }
        }

        //Query Gas Stations By External Ids
        Map<Id, Gas_Station__c> gasStationsMap = new Map<Id, Gas_Station__c> (
            GasStationSelector.getStaionsByExternalIds (
                externalStationIds
            )
        );

        //Logic to prepare contractsByStation map
        for (Gas_Station__c station :gasStationsMap.values()){
            stationByExternalId.put(station.External_Id__c, station.Id);
        }

        //Merge all stationIds into single set
        stationIds.addAll(gasStationsMap.keySet());

        // Query Contracts with contractual timing percentages by StationIds
        List<Contract> contracts = ContractSelector.getContractAndTimingsByStationIds (
            stationIds
        );

        //Logic to prepare ContractsByStation Map
        for (Contract contract: contracts){
            contractByStation.put(contract.Gas_Station__c, contract);
        }

        // Query Machines by MachineNumbers
        List<Machine__c> machines = MachineSelector.getMachinesByMachineNumbers(machineNumbers);

        // Logic to prepare machine maps
        for (Machine__c machine :machines){
            if (machine.Cash_and_Credit__c != null){
                machineByCreditAndCash.put(machine.Cash_and_Credit__c, machine);
            }
            if (machine.Credit__c != null){
                machineByCredit.put(machine.Credit__c, machine);
            }
        }

        //Driver Code - Get the right timing percentages, calculate Quarters
        for (Sale__c sale: (List<Sale__c>) Trigger.new){
            System.debug('### Inside Driver Code');
            Id gasStationId;
            if(sale.Gas_Station__c != null){
                gasStationId = sale.Gas_Station__c;
            }else if (sale.Station_Id_External__c != null){
                gasStationId = stationByExternalId.get(sale.Station_Id_External__c);
            }
            System.debug('### StationId: '+gasStationId);
            if (gasStationId != null && contractByStation.get(gasStationId) != null){
                System.debug('### Inside Driver Condition');
                sale.Gas_Station__c = gasStationId;
                for (Contractual_Comission_Timings__c ct :contractByStation.get(gasStationId)
                    .Contractual_Comission_Timings__r
                ){
                    Date startDate = Date.today();
                    Date createdDate = Sale.External_Created_Date__c.date();
                    Integer diffInDays = createdDate.daysBetween(startDate);
                    Timezone tz = Timezone.getTimeZone('GMT-07:00');
                    DateTime dt = Sale.External_Created_Date__c;
                    dt.addSeconds((tz.getOffset(dt)/1000));
                    String timeString = dt.format('HH:mm:ss');

                    // Split the time string into components
                    List<String> timeComponents = timeString.split(':');

                    // Parse the components into integers
                    Integer hours = Integer.valueOf(timeComponents[0]);
                    Integer minutes = Integer.valueOf(timeComponents[1]);
                    Integer seconds = Integer.valueOf(timeComponents[2]);
                    
                    // Create a Time instance
                    Time tm = Time.newInstance(hours, minutes, seconds, 0);
                    if (tm >= ct.Start_Time__c && tm <= ct.End_Time__c){
                        System.debug('### Time Zone - Condition True');
                        sale.Commission_Timing__c = ct.Id;
                        // sale.Cash_By_Percent__c = (sale.Cash__c * ct.Comission_Percentage__c)/100;
                        // sale.Credit_By_Percent__c = (sale.Credit__c * ct.Comission_Percentage__c)/100;
                        sale.Cash_and_Credit_By_Percent__c = ((sale.Cash__c + sale.Credit__c) * ct.Comission_Percentage__c)/100;
                    }
                    if (machineByCreditAndCash.get(sale.Machine_Number__c) != null) {
                        sale.Machine__c = machineByCreditAndCash.get(sale.Machine_Number__c).Id;
                    } else if (machineByCredit.get(sale.Machine_Number__c) != null){
                        sale.Machine__c = machineByCredit.get(sale.Machine_Number__c).Id;
                    }
                    System.debug('### Diff In Days :'+diffInDays);
                    if (diffInDays <= 90){
                        sale.Sale_Quarter__c = 'THIS_QUARTER';
                    } else if (diffInDays <= 180){
                        sale.Sale_Quarter__c = 'PREVIOUS_QUARTER';
                    } else {
                        sale.Sale_Quarter__c = 'OLD';
                    }
                }
            }
        }
    }
}