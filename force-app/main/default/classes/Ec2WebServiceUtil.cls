/*
 * Author - Ibrahim Ahmed
*/
public class Ec2WebServiceUtil {

	public class Sales {
		public Integer id;
		public Integer station_id;
		public String machine_number;
		public Date item_date;
		public Double cash;
		public Double credit;
		public Double amount_after_op_hours;
		public Double cash_off_hours;
		public Double credit_off_hours;
		public DateTime created_at;
	}

	public class Transactions {
		public Integer id;
		public String device_number;
		public Integer ref_number;
		public Integer transaction_type;
		public DateTime transaction_date;
		public Double amount;
	}

	public List<Sales> sales;
	public List<Transactions> transactions;
	
	public static Ec2WebServiceUtil parse(String json) {
		return (Ec2WebServiceUtil) System.JSON.deserialize(json, Ec2WebServiceUtil.class);
	}
}