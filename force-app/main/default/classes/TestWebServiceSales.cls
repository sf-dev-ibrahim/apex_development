@isTest
private class TestWebServiceSales {

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
        for (Integer i = 1; i <=2; i++) {
            gasStations.add(new Gas_Station__c(Name = 'Test Station ' + i, External_Id__c =''+i, Station_Owner__c=cnt.Id));
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
    static void testCreateSales_Success() {
        // Define the mock request body
        String requestBody = '{"sales":[' +
            '{"id": "1", "station_id": 1, "machine_number": "VJ300106365", "item_date": "2023-06-30", "cash": 100.0, "credit": 50.0, "amount_after_op_hours": 10.0, "cash_off_hours": 5.0, "credit_off_hours": 2.0, "created_at": "2023-06-30T12:00:00-07:00"},' +
            '{"id": "2", "station_id": 2, "machine_number": "VJ300106365", "item_date": "2023-06-30", "cash": 200.0, "credit": 150.0, "amount_after_op_hours": 20.0, "cash_off_hours": 10.0, "credit_off_hours": 5.0, "created_at": "2023-06-30T13:00:00-07:00"}' +
        ']}';

        // Set the mock HTTP request
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/WebService/Sales/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;

        // Set the mock HTTP response
        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Call the web service method
        WebServiceSales.CalloutResponse response = WebServiceSales.createSales();
        
        // Assert response status code and message
        System.debug(response.msg);
        System.assertEquals(201, response.statusCode, 'Expected status code is 201');
        System.assertEquals('All Records Created Successfully!', response.msg, 'Expected success message');

        // Verify that the Sales records were inserted
        List<Sale__c> sales = [SELECT Id, External_Id__c FROM Sale__c WHERE External_Id__c IN ('1', '2')];
        System.assertEquals(2, sales.size(), 'Expected two Sale__c records to be inserted');
    }

    @isTest
    static void testCreateSales_Exception() {
        // Define the mock request body with invalid data to trigger an exception
        String requestBody = '{"sales":[' +
            '{"id": "1", "station_id": "S1", "machine_number": "M1", "item_date": "Invalid Date", "cash": 100.0, "credit": 50.0, "amount_after_op_hours": 10.0, "cash_off_hours": 5.0, "credit_off_hours": 2.0, "created_at": "2023-06-30T12:00:00-07:00"}' +
        ']}';

        // Set the mock HTTP request
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/WebService/Sales/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;

        // Set the mock HTTP response
        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Call the web service method
        WebServiceSales.CalloutResponse response;
        response = WebServiceSales.createSales();
        System.assertEquals(500, response.statusCode, 'Expected status code is 500');
    }
    
    @isTest
    static void testCreateSales_PartialFailure() {
        // Define the mock request body with one valid and one invalid sale
        String requestBody = '{"sales":[' +
            '{"id": 1, "station_id": 1, "machine_number": "VJ300106365", "item_date": "2023-06-30", "cash": 100.0, "credit": 50.0, "amount_after_op_hours": 10.0, "cash_off_hours": 5.0, "credit_off_hours": 2.0, "created_at": "2023-06-30T12:00:00-07:00"},' +
            '{"id": 2, "station_id": 0, "machine_number": "VJ300106365", "item_date": "2023-06-30", "cash": 200.0, "credit": 150.0, "amount_after_op_hours": 20.0, "cash_off_hours": 10.0, "credit_off_hours": 5.0, "created_at": "2023-06-30T13:00:00-07:00"}' +
        ']}';

        // Set the mock HTTP request
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/WebService/Sales/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;

        // Set the mock HTTP response
        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Call the web service method
        WebServiceSales.CalloutResponse response = WebServiceSales.createSales();
        
        // Assert response status code and message
        System.assertEquals(417, response.statusCode, 'Expected status code is 417');
        System.assert(response.msg.contains('Records that failed to insert'), 'Expected partial failure message');

        // Verify that the valid Sales record was inserted and invalid one was not
        List<Sale__c> sales = [SELECT Id, External_Id__c FROM Sale__c WHERE External_Id__c = '1'];
        System.assertEquals(1, sales.size(), 'Expected one Sale__c record to be inserted');
        
        sales = [SELECT Id, External_Id__c FROM Sale__c WHERE External_Id__c = '2'];
        System.assertEquals(0, sales.size(), 'Expected no Sale__c records to be inserted for invalid data');
    }
}
