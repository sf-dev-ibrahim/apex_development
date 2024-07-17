/*
 * Author - Ibrahim Ahmed
*/
@isTest
public class TestTransactionTriggerHandler {
    @testSetup
    static void setupTestData() {
        // Create Machines for testing
        List<Machine__c> machines = new List<Machine__c>();
        machines.add(new Machine__c(
            Cash_and_Credit__c = 'Device123',
            Credit__c = 'Credit123'
        ));
        machines.add(new Machine__c(
            Cash_and_Credit__c = 'Device456',
            Credit__c = 'Credit456'
        ));
        insert machines;
    }

    @isTest
    static void testBeforeInsert() {
        // Create Transactions without Machine__c but with Device_Number__c
        List<Transaction__c> transactions = new List<Transaction__c>();
        transactions.add(new Transaction__c(Device_Number__c = 'Device123'));
        transactions.add(new Transaction__c(Device_Number__c = 'Credit456'));
        insert transactions;
        
        // Query the inserted transactions
        transactions = [SELECT Id, Machine__c, Device_Number__c FROM Transaction__c WHERE Id IN :transactions];
        
        // Verify the Machine__c field is populated correctly
        for (Transaction__c tran : transactions) {
            if (tran.Device_Number__c == 'Device123') {
                Machine__c expectedMachine = [SELECT Id FROM Machine__c WHERE Cash_and_Credit__c = 'Device123' LIMIT 1];
                System.assertEquals(expectedMachine.Id, tran.Machine__c, 'Machine__c should be set to the correct Machine Id for Device123');
            } else if (tran.Device_Number__c == 'Credit456') {
                Machine__c expectedMachine = [SELECT Id FROM Machine__c WHERE Credit__c = 'Credit456' LIMIT 1];
                System.assertEquals(expectedMachine.Id, tran.Machine__c, 'Machine__c should be set to the correct Machine Id for Credit456');
            }
        }
    }

    @isTest
    static void testBeforeInsertWithNoMatchingDeviceNumber() {
         try {
            // Insert a transaction that will cause an exception
            Transaction__c tran = new Transaction__c(Device_Number__c = 'NonExistentDevice');
            insert tran;
            System.assert(false, 'Expected an exception to be thrown due to missing Machine__c');
        } catch (DmlException e) {
            // Assert that the exception is of the expected type and contains the expected message
            System.assert(e.getMessage().contains('REQUIRED_FIELD_MISSING, Required fields are missing: [Machine__c]'), 'Expected a REQUIRED_FIELD_EXCEPTION');
        }
    }
}