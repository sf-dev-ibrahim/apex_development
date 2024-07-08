@isTest
private class TestWebServiceTransactions {

    @testSetup
    static void setupTestData() {
        // Create Machines for testing
        List<Machine__c> machines = new List<Machine__c>();
        machines.add(new Machine__c(
            Name = 'Machine 1',
            Cash_and_Credit__c = 'Device123',
            Credit__c = 'Credit123'
        ));
        machines.add(new Machine__c(
            Name = 'Machine 2',
            Cash_and_Credit__c = 'Device456',
            Credit__c = 'Credit456'
        ));
        insert machines;
    }

    @isTest
    static void testCreateTransactions_Success() {
        // Define the mock request body
        String requestBody = '{"transactions":[' +
            '{"id": 1, "ref_number": 123, "device_number": "Device123", "transaction_date": "2023-06-30T4:14:00-07:00", "transaction_type": 1, "amount": 100.0},' +
            '{"id": 2, "ref_number": 124, "device_number": "Device456", "transaction_date": "2023-06-30T4:14:00-07:00", "transaction_type": 1, "amount": 200.0}' +
        ']}';

        // Set the mock HTTP request
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/WebService/Transactions/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;

        // Set the mock HTTP response
        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Call the web service method
        WebServiceTransactions.CalloutResponse response = WebServiceTransactions.createTransactions();

        // Assert response status code and message
        System.assertEquals(201, response.statusCode, 'Expected status code is 201');
        System.assertEquals('All Records Created Successfully!', response.msg, 'Expected success message');

        // Verify that the Transaction records were inserted
        List<Transaction__c> transactions = [SELECT Id, External_Id__c FROM Transaction__c WHERE External_Id__c IN ('1', '2')];
        System.assertEquals(2, transactions.size(), 'Expected two Transaction__c records to be inserted');
    }

    @isTest
    static void testCreateTransactions_Exception() {
        // Define the mock request body with invalid data to trigger an exception
        String requestBody = '{"transactions":[' +
            '{"id": "1", "ref_number": "REF123", "device_number": "DEV001", "transaction_date": "Invalid Date", "transaction_type": "SALE", "amount": 100.0}' +
        ']}';

        // Set the mock HTTP request
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/WebService/Transactions/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;

        // Set the mock HTTP response
        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Call the web service method
        WebServiceTransactions.CalloutResponse response;
        response = WebServiceTransactions.createTransactions();
        System.assertEquals(500, response.statusCode, 'Expected status code is 500');
    }

    @isTest
    static void testCreateTransactions_PartialFailure() {
        // Define the mock request body with one valid and one invalid transaction
        String requestBody = '{"transactions":[' +
            '{"id": 1, "ref_number": 123, "device_number": "Device123", "transaction_date": "2023-06-30T4:14:00-07:00", "transaction_type": 1, "amount": 100.0},' +
            '{"id": 2, "ref_number": 124, "device_number": "NonExistent", "transaction_date": "2023-06-30T4:14:00-07:00", "transaction_type": 1, "amount": 200.0}' +
        ']}';

        // Set the mock HTTP request
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/WebService/Transactions/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;

        // Set the mock HTTP response
        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Call the web service method
        WebServiceTransactions.CalloutResponse response = WebServiceTransactions.createTransactions();

        // Assert response status code and message
        System.assertEquals(417, response.statusCode, 'Expected status code is 417');
        System.assert(response.msg.contains('Records that failed to insert:'), 'Expected partial failure message');

        // Verify that the valid Transaction record was inserted
        List<Transaction__c> transactions = [SELECT Id, External_Id__c FROM Transaction__c WHERE External_Id__c = '1'];
        System.assertEquals(1, transactions.size(), 'Expected one Transaction__c record to be inserted');
    }
}