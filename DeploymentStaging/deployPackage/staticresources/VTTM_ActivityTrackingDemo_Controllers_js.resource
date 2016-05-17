angular.module('ActivityTrackingApp.controllers', [])

.controller('CalendarCtrl', function($scope, GlobalService, CalendarService) {
	//Get Event Data
	GlobalService.getCurrentTradesman().then(function(tradesman){
		$scope.tradesmanId = tradesman.Id;
		CalendarService.getLogEvents($scope.tradesmanId).then(function(logEvents){
			$scope.calendarEvents = logEvents;
			CalendarService.getScheduledActivityEvents($scope.tradesmanId).then(
				function(scheduledActivityEvents) {
					$scope.calendarEvents.concat(scheduledActivityEvents);
					$('#calendar').fullCalendar({
				        theme: false,
				        header: {
				                    left: 'prev,next today',
				                    center: 'title',
				                    right: 'month,agendaWeek,agendaDay'
				                },
				        editable: false,
				        eventLimit: true,
				        events:$scope.calendarEvents
				    });
				}
			)
		});
	});
})

.controller('ActivitiesCtrl', function($scope, GlobalService, ActivityService) {
	GlobalService.getCurrentTradesman().then(function(tradesman){
		$scope.tradesmanId = tradesman.Id;
		ActivityService.getAssignedActivities($scope.tradesmanId).then(function(activities){
			$scope.activities = activities;
		});
	});
})

.controller('ActivityDetailCtrl', function($scope, $stateParams, ActivityService) {
  	$scope.activity = ActivityService.getActivity($stateParams.activityId);
})
