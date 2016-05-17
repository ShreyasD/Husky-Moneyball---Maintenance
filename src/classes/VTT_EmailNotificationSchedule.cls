global class VTT_EmailNotificationSchedule implements Schedulable {

    public static String Sched1 = '0 0 10 ? * MON-FRI';  //Every Day at 10AM 
    public static String Sched2 = '0 0 14 ? * MON-FRI';  //Every Day at 2PM     
	public static String Sched3 = '0 0 17 ? * MON-FRI';  //Every Day at 5PM    
	public static String Sched4 = '0 0 18 ? * MON-FRI';  //Every Day at 6PM    	
	public static String Sched5 = '0 0 19 ? * MON-FRI';  //Every Day at 7PM
    public static String Sched6 = '0 0 20 ? * MON-FRI';  //Every Day at 8PM
    public static String Sched7 = '0 0 21 ? * MON-FRI';  //Every Day at 9PM
    public static String Sched8 = '0 0 22 ? * MON-FRI';  //Every Day at 10PM
    public static String Sched9 = '0 0 23 ? * MON-FRI';  //Every Day at 11PM
    public static String Sched10 = '0 0 0 ? * MON-FRI';  //Every Day at 12PM
    public static String Sched11 = '0 0 1 ? * MON-SUN'; //Every Day including weekends at 1 AM
    
    public String NotificationType {get; private set;}

    public VTT_EmailNotificationSchedule(String pNotificationType)
    {
    	this.NotificationType = pNotificationType;
    }

    global static void scheduleThisJob() {

        VTT_EmailNotificationSchedule SJ1 = new VTT_EmailNotificationSchedule(VTT_EmailNotifications.NOTIFICATIONTYPE_MISSINGTRADESMAN); 
        System.schedule('VTT Email Notification to Vendor - Missing Tradesman - 10 AM', Sched1, SJ1);
		System.schedule('VTT Email Notification to Vendor - Missing Tradesman - 2 PM', Sched2, SJ1);  

        VTT_EmailNotificationSchedule SJ2 = new VTT_EmailNotificationSchedule(VTT_EmailNotifications.NOTIFICATIONTYPE_MISSINGVENDOR); 
        System.schedule('VTT Email Notification to Field Scheduler - Missing Vendor - 10 AM', Sched1, SJ2);
		System.schedule('VTT Email Notification to Field Scheduler - Missing Vendor - 2 PM', Sched2, SJ2);  

        VTT_EmailNotificationSchedule SJ3 = new VTT_EmailNotificationSchedule(VTT_EmailNotifications.NOTIFICATIONTYPE_MISSINGTRADESMAN_FIELDSCHEDULER); 
        System.schedule('VTT Email Notification to Field Scheduler - Missing Tradesman - 10 AM', Sched1, SJ3);
		System.schedule('VTT Email Notification to Field Scheduler - Missing Tradesman - 2 PM', Sched2, SJ3); 		

        VTT_EmailNotificationSchedule SJ4 = new VTT_EmailNotificationSchedule(VTT_EmailNotifications.NOTIFICATIONTYPE_ACTIVITYINPROGRESS); 
        System.schedule('VTT Email Notification - Activity In Progress - 5 PM', Sched3, SJ4);
		System.schedule('VTT Email Notification - Activity In Progress - 6 PM', Sched4, SJ4); 		
		System.schedule('VTT Email Notification - Activity In Progress - 7 PM', Sched5, SJ4);
        System.schedule('VTT Email Notification - Activity In Progress - 8 PM', Sched6, SJ4);
        System.schedule('VTT Email Notification - Activity In Progress - 9 PM', Sched7, SJ4);       
        System.schedule('VTT Email Notification - Activity In Progress - 10 PM', Sched8, SJ4);
        System.schedule('VTT Email Notification - Activity In Progress - 11 PM', Sched9, SJ4);
        System.schedule('VTT Email Notification - Activity In Progress - Midnight', Sched10, SJ4);			

        VTT_EmailNotificationSchedule SJ5 = new VTT_EmailNotificationSchedule(VTT_EmailNotifications.NOTIFICATIONTYPE_ACTIVITYASSIGNMENT_TRADESMAN);
        System.schedule('VTT Email Notification - Activity Assignment - 1 AM', Sched11, SJ5);
    }

	global void execute(SchedulableContext sc) {
		VTT_EmailNotifications vendorNotificationsBatch 
			= new VTT_EmailNotifications(NotificationType);
		database.executebatch(vendorNotificationsBatch, 200);
	}
}