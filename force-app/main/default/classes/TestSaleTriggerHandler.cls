@isTest
public class TestSaleTriggerHandler {
    @testSetup
    static void setupTestData() {
         // Create a Person Account
        Account testAcnt = new Account (
            Name = 'testAccount'
        );
        insert testAcnt;
        Contact cnt = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            AccountId=testAcnt.Id
        );
        insert cnt;

        // Create Gas Stations
        List<Gas_Station__c> gasStations = new List<Gas_Station__c>();
        for (Integer i = 0; i < 2; i++) {
            gasStations.add(new Gas_Station__c(Name = 'Test Station ' + i, External_Id__c = 'EXT' + i, Station_Owner__c=cnt.Id));
        }
        insert gasStations;

        List<Contract> contracts = new List<Contract>();
        for (Gas_Station__c station : gasStations) {
            contracts.add(new Contract(Gas_Station__c = station.Id, AccountId=testAcnt.Id));
        }
        insert contracts;

        // Create Comission_Timings for each Contract
        List<Contractual_Comission_Timings__c> timings = new List<Contractual_Comission_Timings__c>();
        for (Contract ct :contracts){
            timings.add(new Contractual_Comission_Timings__c (
                Contract__c = ct.Id,
                Start_Time__c = Time.newInstance(0, 0, 0, 0),
                End_Time__c = Time.newInstance(23, 59, 59, 0),
                Comission_Percentage__c = 10
            ));
        }
        insert timings;

        // Create Machines for Each Gas Station
        List<Machine__c> machines = new List<Machine__c>();
        machines.add (new Machine__c (
            External_Id__c = '1',
            Cash_and_Credit__c = 'VJ300106365',
            Credit__c = 'VJ300106365'
        ));
        machines.add (new Machine__c (
            External_Id__c = '2',
            Cash_and_Credit__c = 'VJ300148822',
            Credit__c = 'VJ300148822'
        ));
        insert machines;
    }

    @isTest
    static void testBeforeInsert() {
        // Create test Sales
        List<Sale__c> sales = new List<Sale__c>();
        for (Integer i = 0; i < 2; i++) {
            sales.add(new Sale__c(Machine_Number__c = 'VJ300106365', Cash__c = 100, Credit__c = 50, External_Created_Date__c = DateTime.now().addDays(-i*100), Station_Id_External__c = 'EXT' + i));
        }
        insert sales;

        // Query the inserted sales
        sales = [SELECT Id, Gas_Station__c, Machine__c, Commission_Timing__c, Cash_and_Credit_By_Percent__c, Sale_Quarter__c, External_Created_Date__c FROM Sale__c WHERE Id IN :sales];

        // Verify the results
        for (Sale__c sale : sales) {
            System.assertNotEquals(null, sale.Gas_Station__c, 'Gas_Station__c should be populated');
            System.assertNotEquals(null, sale.Machine__c, 'Machine__c should be populated');
            System.assertNotEquals(null, sale.Commission_Timing__c, 'Commission_Timing__c should be populated');
            System.assertEquals(15, sale.Cash_and_Credit_By_Percent__c, 'Cash_and_Credit_By_Percent__c should be calculated correctly');

            if (sale.External_Created_Date__c.date().daysBetween(Date.today()) <= 90) {
                System.assertEquals('THIS_QUARTER', sale.Sale_Quarter__c, 'Sale_Quarter__c should be THIS_QUARTER');
            } else if (sale.External_Created_Date__c.date().daysBetween(Date.today()) <= 180) {
                System.assertEquals('PREVIOUS_QUARTER', sale.Sale_Quarter__c, 'Sale_Quarter__c should be PREVIOUS_QUARTER');
            } else {
                System.assertEquals('OLD', sale.Sale_Quarter__c, 'Sale_Quarter__c should be OLD');
            }
        }
    }

    @isTest
    static void testBeforeInsertWithNoMatchingGasStation() {
         try {
            // Insert a sale that will cause an exception
            insert new Sale__c(Machine_Number__c = 'VJ300106365', Cash__c = 100, Credit__c = 50, External_Created_Date__c = DateTime.now());
            System.assert(false, 'Expected an exception to be thrown due to missing Gas_Station__c');
        } catch (DmlException e) {
            // Assert that the exception is of the expected type and contains the expected message
            System.assert(e.getMessage().contains('REQUIRED_FIELD_MISSING, Required fields are missing:'), 'Expected a MISSING_FIELD_EXCEPTION');
        }
    }
}