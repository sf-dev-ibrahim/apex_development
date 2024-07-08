@IsTest
public class TestEc2WebServiceUtil {
	
	static testMethod void testParse() {
		String json = '{'+
		'   \"sales\":['+
		'      {'+
		'         \"id\":1,'+
		'         \"station_id\":2,'+
		'         \"machine_number\":\"VJ600020150\",'+
		'         \"item_date\":\"2021-02-07\",'+
		'         \"cash\":13.00,'+
		'         \"credit\":9.00,'+
		'         \"amount_after_op_hours\":23.5,'+
		'         \"cash_off_hours\":0.00,'+
		'         \"credit_off_hours\":0.00,'+
		'         \"created_at\":\"4/26/2021 5:16:15\"'+
		'      },'+
		'      {'+
		'         \"id\":2,'+
		'         \"station_id\":2,'+
		'         \"machine_number\":\"VJ600020150\",'+
		'         \"item_date\":\"2021-02-07\",'+
		'         \"cash\":13.00,'+
		'         \"credit\":9.00,'+
		'         \"amount_after_op_hours\":23.5,'+
		'         \"cash_off_hours\":0.00,'+
		'         \"credit_off_hours\":0.00,'+
		'         \"created_at\":\"4/26/2021 5:16:15\"'+
		'      }'+
		'   ]'+
		'}';
		Ec2WebServiceUtil obj = Ec2WebServiceUtil.parse(json);
		System.assert(obj != null);
	}
}