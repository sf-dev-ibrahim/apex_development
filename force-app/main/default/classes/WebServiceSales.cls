@RestResource(urlMapping='/WebService/Sales/*')
global with sharing class WebServiceSales {

    @HttpPost
    global static CalloutResponse createSales() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String requestJSON = req.requestBody.toString();
        System.debug('### Webhook response: '+requestJSON);

        String exceptionMsg = 'Records that failed to insert: \n';
        Boolean isException = false;
        List<Sale__c> salesToInsert = new List<Sale__c>();
        try {
            List<Ec2WebServiceUtil.Sales> sales = (List<Ec2WebServiceUtil.Sales>) Ec2WebServiceUtil.parse(requestJSON).sales;

            for (Ec2WebServiceUtil.Sales sale :sales){
                String externalId = String.valueOf(sale.id);
                String stationIdExternal = String.valueOf(sale.station_id);
            
                salesToInsert.add(new Sale__c(
                    External_Id__c = externalId,
                    Station_Id_External__c = stationIdExternal,
                    Machine_Number__c = sale.machine_number,
                    Item_Date__c = sale.item_date,
                    Cash__c = sale.cash,
                    Credit__c = sale.credit,
                    Amount_After_Op_Hours__c = sale.amount_after_op_hours,
                    Cash_Off_Hours__c = sale.cash_off_hours,
                    Credit_Off_Hours__c = sale.credit_off_hours,
                    External_Created_Date__c = sale.created_at
                ));
            }
        } catch(Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(e.getMessage());
            insert new AWS_Integration_Log__c(
                Error_Message__c = e.getMessage(),
                Object__c = 'Sale',
                Status_Code__c = 500
            );
            return new CalloutResponse(500, e.getMessage());
        }

        // Attempt to insert records with allOrNone set to false
        Database.SaveResult[] results = Database.insert(salesToInsert, false);

        // Iterate through the results to check for errors
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                isException = true;
                // If the insert failed, get the error message
                for (Database.Error error : results[i].getErrors()) {
                    exceptionMsg +='id: ' + salesToInsert[i].External_Id__c+'\n';
                    exceptionMsg +='Error: ' + error.getStatusCode() + ' - ' + error.getMessage()+'\n';
                }
            } else {
                System.debug('Record inserted successfully: ' + salesToInsert[i]);
            }
        }
        // Prepare the response
        if (isException){
            res.statusCode = 417; // Exception_Failed
            insert new AWS_Integration_Log__c(
                Error_Message__c = exceptionMsg,
                Object__c = 'Sale',
                Status_Code__c = 417
            );
        }
        else {res.statusCode = 201;} // Created
        return isException ? new CalloutResponse(417, exceptionMsg)
        : new CalloutResponse(201, 'All Records Created Successfully!');
    }

    global class CalloutResponse {
        @TestVisible
        private Integer statusCode;
        @TestVisible
        private String msg;

        public CalloutResponse (Integer statusCode, String msg){
            this.statusCode = statusCode;
            this.msg = msg;
        }        
    }
}