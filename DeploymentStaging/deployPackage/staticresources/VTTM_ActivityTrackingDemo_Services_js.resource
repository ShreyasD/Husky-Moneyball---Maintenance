angular.module('ActivityTrackingApp.services', [])

.factory('GlobalService', function($q) {
  //Setup RemoteTK
  var remoteTKClient = new remotetk.Client();

  //Prvate variables
  var tradesman;

  function getTradesmanInfo() {
    var deferred = $q.defer();

    var query = "Select Id, Name, Tradesman_Status__c, AccountId, Tradesman_Status_Date__c, Current_Work_Order_Activity__c " + 
                "From Contact Where User__c = '" + $User.Id + "'";

    remoteTKClient.query(
      query,
      function(response) {
        tradesman = response.records[0];
        deferred.resolve(tradesman);
      },
      function(error) {
        alert(JSON.stringify(error));
        deferred.fail(error);
      }
    );
    

    return deferred.promise;
  };

  return {
    getCurrentTradesman: function() {
      return getTradesmanInfo();
    },
  };
})

.factory('ActivityService', function($q) {
  //Setup RemoteTK
  var remoteTKClient = new remotetk.Client();


  // Private Variables
  var activities;

  function getAssignedActivities(tradesmanId) {
    var deferred = $q.defer();
    var query = "Select Id, Name, Assigned_Vendor__c, Description__c," + 
                    "Work_Center__c, Assigned_Text__c," + 
                    "Maintenance_Work_Order__r.User_Status_Code__c," + 
                    "Maintenance_Work_Order__r.Work_Order_Priority_Number__c," + 
                    "Maintenance_Work_Order__r.Order_Type__c," + 
                    "Maintenance_Work_Order__r.Name," + 
                    "Maintenance_Work_Order__r.Location__r.Name," + 
                    "Maintenance_Work_Order__r.Plant_Section__c," +
                    "Scheduled_Start_Date__c,Status__c," + 
                    "Status_Reason__c " + 
                    "From Work_Order_Activity__c " + 
                    "Where " + 
                    "Id In (Select Work_Order_Activity__c from Work_Order_Activity_Assignment__c where Rejected__c <> true and Tradesman__c =  '" + tradesmanId + "') " +
                    "Order By Scheduled_Start_Date__c";

    //Call Client with query
    remoteTKClient.query(
      query,
      function(response) {
        activities = response.records;
        deferred.resolve(activities);
      },
      function(error) {
        alert(JSON.stringify(error));
        deferred.fail(error);
      }
    );

    return deferred.promise;
  };

  return {
    getAssignedActivities: function(tradesmanId) {
      return getAssignedActivities(tradesmanId);
    },
    getActivity: function(activityId) {
      for (var i = 0; i < activities.length; i++) {
        if (activities[i].Id.toLowerCase() === activityId.toLowerCase()) {
          console.log(activities[i].Maintenance_Work_Order__r.Order_Type__c);
          return activities[i];
        }
      }
      return null;
    }
  };
})

.factory('CalendarService', function($q) {
  //Setup RemoteTK
  var remoteTKClient = new remotetk.Client();

  //Private Variables
  var activityLogEvents;
  var scheduledActivityEvents;
  var workedActivityIds;

  function getActivityWorkLogEvents(tradesmanId)
  {
    var deferred =$q.defer();
    var query = "SELECT Id, Work_Order_Activity__c," + 
        "Work_Order_Activity__r.Name, Started_New__c, Finished_New__c," + 
        "Work_Order_Activity__r.Status__c," +
        "Work_Order_Activity__r.Finished__c " +
        "FROM Work_Order_Activity_Log__c " +
        "WHERE Tradesman__c = '" + tradesmanId + "' " +
        "AND Date__c = LAST_90_DAYS " +
        "AND Started_New__c <> null " +
        "ORDER BY Date__c DESC " +
        "LIMIT 100";

    //Initialize log events array
    activityLogEvents = [];

    //Call Client with query
    remoteTKClient.query(
      query,
      function(response) {
        var activityLogs = response.records;
        workedActivityIds = [];

        console.log('Total Activity Logs: ' + activityLogs.length);
        for(var i = 0; i < activityLogs.length; i++) {
          var log = activityLogs[i];
          console.log('Name: ' + log.Work_Order_Activity__r.Name + 'Started: ' + log.Started_New__c + ' Finished: ' + log.Finished_New__c);
          var eventProblem = false;
          var today = new Date();
          var startDate = new Date(log.Started_New__c);
          var endDate;

          //Add to being worked on
          workedActivityIds.push(log.Id);

          if(log.Finished__c === undefined) {
            if(startDate.getFullYear() === today.getFullYear() &&
              startDate.getMonth() === today.getMonth() &&
              startDate.getDate() === today.getDate()) {
              endDate = new Date();
            } else {
              endDate = startDate;
              endDate.setHours(endDate.getHours() + 1);
              eventProblem = true;
            }
          } else {
            endDate = new Date(log.Started_New__c);
          }

          if(startDate != null && endDate != null) {
            var clsName = (eventProblem) ? 'event-activitylog-err' : 
              (log.Work_Order_Activity__r.Status__c == 'Completed') ? 'event-activitylog-complete' :
              'event-activitylog';


            activityLogEvents.push({
              title: log.Work_Order_Activity__r.Name,
              start: startDate.toISOString(),
              end: endDate.toISOString(),
              url: "#/ActivityTracking/Activities/" + log.Work_Order_Activity__c,
              allDay: false,
              className: clsName
            });
          }

        }

        deferred.resolve(activityLogEvents);
      },
      function(error) {
        alert(JSON.stringify(error));
        deferred.fail(error);
      }
    );

    return deferred.promise;
  }

  function getScheduledActivities(tradesmanId) {
    var deferred = $q.defer();
    var workedOnActivityIdString = "(";

    for(var i = 0; i < workedActivityIds.length; i++) {
      if(i == workedActivityIds.length - 1){
        workedOnActivityIdString += ("'" + workedActivityIds[i] + "')");
      } else {
        workedOnActivityIdString += ("'" +workedActivityIds[i] + "',");
      }
    }
    console.log("workedOnActivityIdString: " + workedOnActivityIdString);

    var query = "SELECT Id, Name, Scheduled_Start_Date__c, Scheduled_Finish_Date__c " +
        "FROM Work_Order_Activity__c " +
        "WHERE " +
        "Id in (select Work_Order_Activity__c from Work_Order_Activity_Assignment__c where Rejected__c <> true and Tradesman__c = '" + tradesmanId + "') " +
        "AND Scheduled_Start_Date__c >= LAST_N_DAYS:30 " +
        "AND id not in " + workedOnActivityIdString + " " +
        "AND SAP_deleted__c = false "
        "AND Status__c <> 'Completed' "
        "ORDER BY Scheduled_Start_Date__c "
        "LIMIT 100";
    console.log(query);

    scheduledActivityEvents = [];

    remoteTKClient.query(
      query,
      function(response) {
        var scheduledActivities = response.records;

        for(var i=0; i<scheduledActivities.length; i++) {
          var activity = scheduledActivities[i];
          var startDate = new Date(activity.Scheduled_Start_Date__c);
          var endDate;

          if(activity.Scheduled_Finish_Date__c === undefined) {
            endDate = new Date();
          } else {
            endDate = new Date(activity.Scheduled_Finish_Date__c);
          }

          if(startDate != null && endDate != null) {
             scheduledActivityEvents.push({
              title: activity.Name,
              start: startDate.toISOString(),
              end: endDate.toISOString(),
              url: "#/ActivityTracking/Activities/" + activity.Id,
              allDay: false,
              className: 'event-scheduled'
            });
          }
        }

        deferred.resolve(scheduledActivityEvents);
      },
      function(error){
        alert(JSON.stringify(error));
        deferred.fail(error);
      }
    );

    return deferred.promise;
  }

  return {
    getLogEvents: function(tradesmanId) {
      return getActivityWorkLogEvents(tradesmanId);
    },
    getScheduledActivityEvents: function(tradesmanId) {
      return getScheduledActivities(tradesmanId);
    }
  };
});
