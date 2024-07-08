@RestResource(urlMapping='/WebService/Transactions/*')
global with sharing class WebServiceTransactions {

    @HttpPost
    global static CalloutResponse createTransactions() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String requestJSON = req.requestBody.toString();
        System.debug('### Webhook response: '+requestJSON);

        String exceptionMsg = 'Records that failed to insert: \n';
        Boolean isException = false;
        List<Transaction__c> transToInsert = new List<Transaction__c>();
        try {
            List<Ec2WebServiceUtil.Transactions> trans = (List<Ec2WebServiceUtil.Transactions>) Ec2WebServiceUtil.parse(requestJSON).transactions;

            for (Ec2WebServiceUtil.Transactions tran :trans){
                String externalId = String.valueOf(tran.id);
                String refNumber = String.valueOf(tran.ref_number);
                String tranType = String.valueOf(tran.transaction_type);
            
                transToInsert.add(new Transaction__c(
                    External_Id__c = externalId,
                    Ref_Number__c = refNumber,
                    Device_Number__c = tran.device_number,
                    Transaction_Date__c = tran.transaction_date,
                    Transaction_Type__c = tranType,
                    Amount__c = tran.amount
                ));
            }
        } catch(Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(e.getMessage());
            insert new AWS_Integration_Log__c(
                Error_Message__c = e.getMessage(),
                Object__c = 'Transaction',
                Status_Code__c = 500
            );
            return new CalloutResponse(500, e.getMessage());
        }

        // Attempt to insert records with allOrNone set to false
        Database.SaveResult[] results = Database.insert(transToInsert, false);

        // Iterate through the results to check for errors
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                isException = true;
                // If the insert failed, get the error message
                for (Database.Error error : results[i].getErrors()) {
                    exceptionMsg +='id: ' + transToInsert[i].External_Id__c+'\n';
                    exceptionMsg +='Error: ' + error.getStatusCode() + ' - ' + error.getMessage()+'\n';
                }
            } else {
                System.debug('Record inserted successfully: ' + transToInsert[i]);
            }
        }
        // Prepare the response
        if (isException){
            res.statusCode = 417; // Exception_Failed
            insert new AWS_Integration_Log__c(
                Error_Message__c = exceptionMsg,
                Object__c = 'Transaction',
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